// saladui/components/select.js
import Component from "../core/component.js";
import SaladUI from "../index.js";
import {
  CollectionRegistry,
  RovingFocus,
  Selection,
} from "../core/collection.js";
import PositionedElement from "../core/positioned-element.js";
import { getTextValue, typeaheadFor } from "../core/typeahead.js";

// Matches the `max-h-[min(24rem,var(...))]` class on select_content.
const AVAILABLE_HEIGHT_VAR = "--salad-select-content-available-height";
// sideOffset (4px) plus a little breathing room from the window edge.
const SELECT_COLLISION_MARGIN = 12;
// Parts that listeners or the positioned element are bound to: a patch that
// replaces one rebuilds the select (see skipReinitialize).
const STABLE_PARTS = [
  "trigger",
  "value",
  "content",
  "viewport",
  "scroll-up-button",
  "scroll-down-button",
];

/**
 * SelectItem class to manage individual select options
 * Handles state transitions and events for a single select item
 */
class SelectItem extends Component {
  constructor(itemElement, parentComponent, options) {
    const { initialState = "normal" } = options || {};
    super(itemElement, { initialState, ignoreItems: false });

    this.parent = parentComponent;
    this.value = itemElement.dataset.value;
    this.disabled = this.isElementDisabled(itemElement);
    this.label = itemElement.textContent.trim();

    this.setupEvents();
  }

  // Re-apply the selected state after a LiveView patch kept this element.
  resync() {
    this.disabled = this.isElementDisabled(this.el);
    this.label = this.el.textContent.trim();
    this.refreshParts();
    this.reapplyState();
  }

  isElementDisabled(itemElement) {
    const dataDisabled = itemElement.getAttribute("data-disabled");

    return (
      itemElement.hasAttribute("disabled") ||
      itemElement.getAttribute("aria-disabled") === "true" ||
      (dataDisabled !== null && dataDisabled !== "false")
    );
  }

  getComponentConfig() {
    return {
      stateMachine: {
        unchecked: {
          transitions: {
            check: "checked",
          },
        },
        checked: {
          transitions: {
            uncheck: "unchecked",
          },
        },
      },
      events: {
        unchecked: {
          mouseMap: {
            item: {
              click: "handleActivation",
              mouseenter: "handleMouseEnter",
              mouseleave: "handleMouseLeave",
            },
          },
          keyMap: {
            Enter: "handleActivation",
            " ": "handleSpaceKey",
          },
        },
        checked: {
          mouseMap: {
            item: {
              click: "handleActivation",
              mouseenter: "handleMouseEnter",
              mouseleave: "handleMouseLeave",
            },
          },
          keyMap: {
            Enter: "handleActivation",
            " ": "handleSpaceKey",
          },
        },
      },
      hiddenConfig: {
        checked: {
          "item-indicator": false,
        },
        unchecked: {
          "item-indicator": true,
        },
      },
      ariaConfig: {
        item: {
          all: {
            role: "option",
          },
          checked: {
            selected: "true",
          },
          unchecked: {
            selected: "false",
          },
        },
      },
    };
  }

  handleEvent(eventType) {
    switch (eventType) {
      case "select":
        return this.transition("check");
      case "unselect":
        return this.transition("uncheck");
      case "focus":
        if (!this.disabled) {
          // Just mark as highlighted without direct focus
          this.el.focus();
        }
        return true;
      case "blur":
        return true;
    }
  }

  handleActivation(event) {
    event.preventDefault();
    event.stopImmediatePropagation();
    if (!this.disabled) {
      this.parent.selectValue(this.value);
    }
  }

  // While a typeahead search is in progress, Space types a space (handled by
  // the content) instead of selecting the item.
  handleSpaceKey(event) {
    if (this.parent.typeahead?.isSearching) return;

    this.handleActivation(event);
  }

  handleMouseEnter() {
    if (!this.disabled) {
      this.parent.handleItemFocus(this);
    }
  }
}

/**
 * SelectComponent class for SaladUI framework
 * Manages a collection of select items with state transitions
 */
class SelectComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    // Initialize core properties
    this.trigger = this.getPart("trigger");
    this.valueDisplay = this.getPart("value");
    this.content = this.getPart("content");
    this.viewport = this.getPart("viewport");
    this.scrollUpButton = this.getPart("scroll-up-button");
    this.scrollDownButton = this.getPart("scroll-down-button");
    this.autoScrollTimer = null;
    this.disabled = this.el.dataset.disabled === "true";
    this.handleTriggerClick = this.handleTriggerClick.bind(this);
    this.handleTriggerKeydown = this.handleTriggerKeydown.bind(this);
    this.handleContentKeydown = this.handleContentKeydown.bind(this);
    this.updateScrollButtons = this.updateScrollButtons.bind(this);
    this.scrollButtonHandlers = new Map();
    // Radix keeps separate searches for the open list and the closed trigger.
    // Both live on their elements so a search survives a LiveView patch.
    this.typeahead = typeaheadFor(this.content);
    this.triggerTypeahead = typeaheadFor(this.trigger);

    // Get configuration from options
    this.multiple = this.options.multiple || false;
    this.usePortal = Object.hasOwn(this.options, "usePortal")
      ? this.options.usePortal
      : false;
    this.portalContainer = this.options.portalContainer || null;

    // Initialize item registry, focus manager, and selection state
    this.registry = new CollectionRegistry({
      getItemValue: (item) => item.value,
      isItemDisabled: (item) => item.disabled || this.disabled,
    });
    this.rovingFocus = new RovingFocus(this.registry);
    this.selection = new Selection(this.registry, {
      type: this.multiple ? "multiple" : "single",
      defaultValue: this.options.defaultValue,
      value: this.options.value,
    });

    // Set keyboard navigation defaults
    this.config.preventDefaultKeys = [
      "ArrowUp",
      "ArrowDown",
      "Home",
      "End",
      "Enter",
      " ",
      "Escape",
    ];

    // Initialize select items
    this.initializeItems();
    this.initializePlaceholder();
    this.syncInvalidState();
  }

  /**
   * Mirror the root's `data-invalid` (set server-side when a form field has
   * errors) onto the trigger as `aria-invalid`, so assistive tech announces
   * the error. An `aria-invalid` passed explicitly to the trigger wins.
   * Re-run on every LiveView patch (see skipReinitialize); the
   * `data-invalid-synced` marker tells our own attribute apart from an
   * explicit one, so it is removed again once the field becomes valid.
   */
  syncInvalidState() {
    if (!this.trigger) return;

    const synced = this.trigger.hasAttribute("data-invalid-synced");
    if (this.trigger.hasAttribute("aria-invalid") && !synced) return;

    if (this.el.dataset.invalid === "true") {
      this.trigger.setAttribute("aria-invalid", "true");
      this.trigger.setAttribute("data-invalid-synced", "");
    } else if (synced) {
      this.trigger.removeAttribute("aria-invalid");
      this.trigger.removeAttribute("data-invalid-synced");
    }
  }

  /**
   * Portaled content must be back inside the root for LiveView to patch it,
   * and the patch drops its inline position anyway: take it down here and
   * put it back up in skipReinitialize().
   */
  beforeUpdate() {
    // Moving portaled content back blurs the highlighted item.
    const active = document.activeElement;
    this.focusBeforePatch =
      active && this.content?.contains(active) ? active : null;
    this.suspendedForPatch = !!this.positionedElement?.active;
    this.positionedElement?.deactivate();
  }

  /**
   * A LiveView patch (a phx-change on the surrounding form, a flash) puts back
   * the server-rendered markup: the content `hidden` and closed, the items
   * unselected, the hook-managed hidden inputs gone. Rebuilding would close
   * an open dropdown. Keep the instance and re-apply its state, unless the
   * options or event mappings changed; a new server `value` is selected in
   * place, without firing `value-changed`.
   */
  skipReinitialize(el) {
    if (!this.sameConfig(el, ["value"])) return false;
    if (!this.refreshParts(STABLE_PARTS)) return false;

    const changed = this.adoptOptions(el, ["value"]);
    this.disabled = el.dataset.disabled === "true";

    const itemElements = Array.from(el.querySelectorAll("[data-part='item']"));
    const sameItems =
      itemElements.length === this.registry.items.length &&
      itemElements.every(
        (element, index) => this.registry.items[index].instance.el === element,
      );

    if (changed.includes("value")) {
      this.selection.values = this.selection.normalizeValues(
        this.options.value,
      );
    }

    if (sameItems) {
      this.registry.each((item) => item.resync());
      this.selection.updateSelectedStates();
      this.updateValueDisplay();
      this.syncHiddenInputs();
    } else {
      const highlighted = this.rovingFocus.focusedItem?.value;
      this.destroyItems();
      // Re-reads the selection onto the new items and syncs the display.
      this.initializeItems();
      const item = this.registry.getItemByValue(highlighted);
      if (item && this.state === "open") this.rovingFocus.focus(item);
    }

    this.initializePlaceholder();
    this.syncInvalidState();
    this.reapplyState();

    const resume = this.suspendedForPatch || this.positionedElement?.active;
    this.suspendedForPatch = false;
    if (this.state === "open" && resume) {
      this.positionedElement.deactivate();
      this.positionedElement.activate();
      this.updateScrollButtons();
    }

    const focused = this.focusBeforePatch;
    this.focusBeforePatch = null;
    if (
      this.state === "open" &&
      focused?.isConnected &&
      this.content.contains(focused) &&
      document.activeElement !== focused
    ) {
      focused.focus({ preventScroll: true });
    }

    return true;
  }

  destroyItems() {
    this.registry.each((item) => item.destroy());
    this.registry.clear();
    this.rovingFocus.reset();
  }

  getComponentConfig() {
    return {
      stateMachine: {
        closed: {
          enter: "onClosedEnter",
          transitions: {
            open: "open",
            toggle: "open",
          },
        },
        open: {
          enter: "onOpenEnter",
          exit: "onOpenExit",
          transitions: {
            close: "closed",
            toggle: "closed",
            select: "closed",
          },
        },
      },
      events: {
        closed: {
          keyEventTarget: "trigger",
          keyMap: {
            ArrowDown: () => this.openIfEnabled(),
            ArrowUp: () => this.openIfEnabled(),
            Enter: () => this.openIfEnabled(),
            // Mid-search, Space is part of the search (see
            // handleTriggerKeydown), not an open key.
            " ": () => {
              if (!this.triggerTypeahead.isSearching) this.openIfEnabled();
            },
          },
        },
        open: {
          keyEventTarget: "content",
          keyMap: {
            Escape: "close",
            ArrowUp: () => this.navigateItem("prev"),
            ArrowDown: () => this.navigateItem("next"),
            Home: () => this.navigateItem("first"),
            End: () => this.navigateItem("last"),
          },
        },
      },
      hiddenConfig: {
        closed: {
          content: true,
        },
        open: {
          content: false,
        },
      },
      ariaConfig: {
        trigger: {
          all: {
            haspopup: "listbox",
          },
          open: {
            expanded: "true",
          },
          closed: {
            expanded: "false",
          },
        },
        content: {
          all: {
            role: "listbox",
          },
        },
      },
    };
  }

  setupComponentEvents() {
    super.setupComponentEvents();

    this.trigger?.addEventListener("click", this.handleTriggerClick);
    this.trigger?.addEventListener("keydown", this.handleTriggerKeydown);
    this.content?.addEventListener("keydown", this.handleContentKeydown);
    this.setupScrollButtons();
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();

    this.trigger?.removeEventListener("click", this.handleTriggerClick);
    this.trigger?.removeEventListener("keydown", this.handleTriggerKeydown);
    this.content?.removeEventListener("keydown", this.handleContentKeydown);
    this.teardownScrollButtons();
  }

  // Scroll buttons (shadcn's SelectScrollUpButton / SelectScrollDownButton).
  // Like Radix, each one is shown only while the viewport can scroll in its
  // direction, and pointing at it scrolls the viewport one item per tick.
  setupScrollButtons() {
    if (!this.viewport) return;

    this.viewport.addEventListener("scroll", this.updateScrollButtons, {
      passive: true,
    });

    [
      [this.scrollUpButton, -1],
      [this.scrollDownButton, 1],
    ].forEach(([button, direction]) => {
      if (!button) return;

      const start = () => this.startAutoScroll(direction);
      const stop = () => this.stopAutoScroll();
      const handlers = {
        pointerdown: start,
        pointermove: start,
        pointerleave: stop,
      };
      Object.entries(handlers).forEach(([type, handler]) =>
        button.addEventListener(type, handler),
      );
      this.scrollButtonHandlers.set(button, handlers);
    });
  }

  teardownScrollButtons() {
    this.stopAutoScroll();
    this.viewport?.removeEventListener("scroll", this.updateScrollButtons);
    this.scrollButtonHandlers.forEach((handlers, button) => {
      Object.entries(handlers).forEach(([type, handler]) =>
        button.removeEventListener(type, handler),
      );
    });
    this.scrollButtonHandlers.clear();
  }

  updateScrollButtons() {
    if (!this.viewport) return;

    const { scrollTop, scrollHeight, clientHeight } = this.viewport;
    const canScrollUp = scrollTop > 0;
    const canScrollDown = Math.ceil(scrollTop) < scrollHeight - clientHeight;

    if (this.scrollUpButton) this.scrollUpButton.hidden = !canScrollUp;
    if (this.scrollDownButton) this.scrollDownButton.hidden = !canScrollDown;

    // Stop once the button under the pointer disappears at either end.
    if (
      this.autoScrollTimer !== null &&
      ((this.autoScrollDirection < 0 && !canScrollUp) ||
        (this.autoScrollDirection > 0 && !canScrollDown))
    ) {
      this.stopAutoScroll();
    }
  }

  startAutoScroll(direction) {
    if (this.autoScrollTimer !== null || !this.viewport) return;

    this.autoScrollDirection = direction;
    this.autoScrollTimer = window.setInterval(() => {
      if (this.destroyed || !this.viewport) return this.stopAutoScroll();

      const item = this.viewport.querySelector("[data-part='item']");
      const step = item?.offsetHeight || 32;
      this.viewport.scrollTop += direction * step;
      this.updateScrollButtons();
    }, 50);
  }

  stopAutoScroll() {
    if (this.autoScrollTimer === null) return;

    window.clearInterval(this.autoScrollTimer);
    this.autoScrollTimer = null;
  }

  handleTriggerClick() {
    if (this.disabled) return;

    this.transition(this.state === "open" ? "close" : "open");
  }

  openIfEnabled() {
    if (this.disabled) return;

    this.transition("open");
  }

  handleTriggerKeydown(event) {
    if (this.disabled) return;
    if (this.state !== "open") {
      this.handleTriggerTypeahead(event);
      return;
    }
    if (event.defaultPrevented || this.handleListTypeahead(event)) return;

    const keyActions = {
      ArrowUp: () => this.navigateItem("prev"),
      ArrowDown: () => this.navigateItem("next"),
      Home: () => this.navigateItem("first"),
      End: () => this.navigateItem("last"),
      Escape: () => this.transition("close"),
      Enter: () => this.transition("close"),
      " ": () => this.transition("close"),
    };
    const action = keyActions[event.key];
    if (!action) return;

    event.preventDefault();
    event.stopPropagation();
    action();
  }

  handleContentKeydown(event) {
    if (this.state === "open") this.handleListTypeahead(event);
  }

  // Typing while open highlights the next enabled item whose text starts with
  // what was typed (Radix select typeahead).
  handleListTypeahead(event) {
    const items = this.registry.enabledItems();
    const active = document.activeElement;
    return this.typeahead.handleKey(event, {
      items,
      current: items.find((item) => item.instance.el === active) || null,
      getText: (item) => getTextValue(item.instance.el),
      onMatch: (item) => this.rovingFocus.focus(item),
    });
  }

  // Typing on the focused, closed trigger selects the matching item without
  // opening, as Radix does. Radix's select is single-value, so a multiple
  // select leaves its selection alone.
  handleTriggerTypeahead(event) {
    if (this.multiple) return false;

    const items = this.registry.enabledItems();
    const selected = this.selection.getValue(true)[0];
    return this.triggerTypeahead.handleKey(event, {
      items,
      current: items.find((item) => item.value === selected) || null,
      getText: (item) => getTextValue(item.instance.el),
      onMatch: (item) => this.selectValue(item.value, { close: false }),
    });
  }

  initializeItems() {
    const itemElements = Array.from(
      this.el.querySelectorAll("[data-part='item']"),
    );

    itemElements.forEach((element) => {
      // Create a SelectItem instance for each item
      const value = element.dataset.value;

      // Check if this item is initially selected
      const isSelected = this.selection.isValueSelected(value);
      const initialState = isSelected ? "checked" : "unchecked";

      const item = new SelectItem(element, this, { initialState });
      const collectionItem = this.registry.add(item);
      this.selection.initializeItem(collectionItem);
    });

    // Update value display based on initial selection
    this.updateValueDisplay();
    this.syncHiddenInputs();
  }

  initializePlaceholder() {
    if (!this.valueDisplay) return;

    const placeholder =
      this.valueDisplay.getAttribute("data-placeholder") || "Select an option";

    // If no selection, display the placeholder
    if (this.selection.getValue(true).length === 0) {
      this.valueDisplay.setAttribute("data-content", placeholder);
    }
  }

  initializePositionedElement() {
    if (this.content && this.trigger && !this.positionedElement) {
      // Extract position config from content attributes
      const side = this.content.getAttribute("data-side") || "bottom";

      // Get portal container if specified
      let portalContainer = null;
      if (this.portalContainer) {
        portalContainer = document.querySelector(this.portalContainer);
      }

      // Create positioned element with modular architecture
      this.positionedElement = new PositionedElement(this.content, this.el, {
        placement: side,
        alignment: "start",
        sideOffset: 4,
        flip: true,
        usePortal: this.usePortal,
        portalContainer: portalContainer || document.body,
        trapFocus: false,
        onOutsideClick: () => this.transition("close"),
        onPosition: () => this.updateAvailableHeight(),
      });
    }
  }

  /**
   * Like Radix's --radix-select-content-available-height: cap the content at
   * the room left in the window on the roomier side of the trigger, so a long
   * list scrolls in its viewport instead of running off-screen (the content
   * is position: fixed, so off-screen items could not be reached). It is the
   * larger of the two sides rather than the placed side, so capping cannot
   * flip the placement back and forth.
   */
  updateAvailableHeight() {
    if (!this.content || !this.el || typeof window === "undefined") return;

    const rect = this.el.getBoundingClientRect();
    const room = Math.max(rect.top, window.innerHeight - rect.bottom);
    const available = Math.max(0, Math.floor(room - SELECT_COLLISION_MARGIN));
    const value = `${available}px`;

    if (this.content.style.getPropertyValue(AVAILABLE_HEIGHT_VAR) !== value) {
      this.content.style.setProperty(AVAILABLE_HEIGHT_VAR, value);
    }
  }

  // State machine handlers
  onClosedEnter() {
    // Update hidden input(s)
    this.syncHiddenInputs();
    this.pushEvent("close");
  }

  onOpenEnter() {
    this.triggerTypeahead.reset();

    // Initialize positioned element
    this.initializePositionedElement();
    // Before the first position pass, so it measures the capped height.
    this.updateAvailableHeight();

    // Activate positioned element
    if (this.positionedElement) {
      this.positionedElement.activate();
    }

    // Highlight first selected item or first item
    this.highlightFirstSelectedOrFirstItem();
    this.updateScrollButtons();
    window.requestAnimationFrame(() => {
      if (this.destroyed || typeof document === "undefined") return;

      if (
        this.state === "open" &&
        !this.content?.contains(document.activeElement)
      ) {
        this.highlightFirstSelectedOrFirstItem();
      }
      if (this.state === "open") this.updateScrollButtons();
    });

    this.pushEvent("open");
  }

  onOpenExit() {
    this.stopAutoScroll();
    this.typeahead.reset();

    // Deactivate positioned element
    if (this.positionedElement) {
      this.positionedElement.deactivate();
    }

    this.trigger?.focus({ preventScroll: true });
  }

  // Item management
  selectValue(value, { close = true } = {}) {
    const collectionItem = this.registry.getItemByValue(value);
    if (!collectionItem) return;

    // Toggle item selection
    this.selection.select(collectionItem);

    // Update value display
    this.updateValueDisplay();

    // Keep forms in sync immediately, not only after close
    this.syncHiddenInputs();
    this.dispatchFormEvents();

    // Close dropdown if single select
    if (!this.multiple && close) {
      this.transition("select");
    }

    // Emit event with current value
    const selectedValue = this.selection.getValue();
    this.pushEvent("value-changed", { value: selectedValue });
  }

  handleItemFocus(item) {
    const collectionItem = this.registry.getItemByInstance(item);
    if (!collectionItem) return;

    this.rovingFocus.focus(collectionItem);
  }

  updateValueDisplay() {
    const selectedValues = this.selection.getValue(true);

    // Like Radix, flag the trigger while it shows the placeholder so
    // `data-[placeholder]:text-muted-foreground` can mute it.
    this.trigger?.toggleAttribute(
      "data-placeholder",
      selectedValues.length === 0,
    );

    if (!this.valueDisplay) return;

    const placeholder =
      this.valueDisplay.getAttribute("data-placeholder") || "Select an option";

    if (selectedValues.length === 0) {
      // No selection, show placeholder
      this.setValueDisplayText(placeholder);
    } else if (this.multiple) {
      // Multiple selection
      if (selectedValues.length === 1) {
        // Get the label from the selected item
        const selectedItem = this.registry.getItemByValue(selectedValues[0]);
        this.setValueDisplayText(
          selectedItem?.instance.label || selectedValues[0],
        );
      } else {
        // Show count for multiple selections
        this.setValueDisplayText(`${selectedValues.length} items selected`);
      }
    } else {
      // Single selection - get label from the selected item
      const selectedItem = this.registry.getItemByValue(selectedValues[0]);
      this.setValueDisplayText(
        selectedItem?.instance.label || selectedValues[0],
      );
    }
  }

  setValueDisplayText(text) {
    if (!this.valueDisplay) return;

    const value = text || "";
    this.valueDisplay.textContent = value;
    this.valueDisplay.setAttribute("data-content", value);
  }

  // Navigation methods
  navigateItem(direction) {
    // Check if we have an active highlighted item
    let currentItem = this.rovingFocus.focusedItem;

    // If not, use the first selected item or null
    if (!currentItem) {
      currentItem =
        this.selection.getValue(true).length > 0
          ? this.registry.getItemByValue(this.selection.getValue(true)[0])
          : null;
    }

    // Get target item using registry navigation methods
    const targetItem = this.registry.getItem(direction, currentItem);

    if (targetItem) {
      this.rovingFocus.focus(targetItem);
    }
  }

  highlightFirstSelectedOrFirstItem() {
    // Try to highlight the first selected item
    const selectedValue = this.selection.getValue(true)[0];

    const selectedItem =
      this.registry.getItemByValue(selectedValue) ||
      this.registry.getItem("first");
    if (selectedItem) {
      this.rovingFocus.focus(selectedItem);
    }
  }

  // Form integration
  syncHiddenInputs() {
    // Get the selected values
    const values = this.selection.getValue(true);
    const name = this.getInputName();

    // Remove existing hidden inputs
    const existingInputs = this.el.querySelectorAll(
      "input[type='hidden'][data-salad-ui-select-input='true']",
    );
    existingInputs.forEach((input) => input.remove());

    if (!name) return;

    // Create new hidden inputs
    if (this.multiple) {
      values.forEach((value) => {
        this.el.appendChild(this.createHiddenInput(name, value));
      });
    } else if (values.length > 0) {
      // Single select - create one input
      this.el.appendChild(this.createHiddenInput(name, values[0]));
    }
  }

  getInputName() {
    const name = this.options.name || "";
    if (!this.multiple || !name || name.endsWith("[]")) return name;

    return `${name}[]`;
  }

  createHiddenInput(name, value) {
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    input.dataset.saladUiSelectInput = "true";
    return input;
  }

  dispatchFormEvents() {
    if (!this.el.closest("form")) return;

    // Prefer the server-rendered tracking input: LiveView marks the input an
    // event comes from as used, and unlike the hidden value inputs (re-created
    // on every sync) it survives patches, so the select stays "used".
    const tracker = this.el.querySelector(
      "input[data-salad-ui-select-tracker='true']",
    );
    const hiddenInput = this.el.querySelector(
      "input[type='hidden'][data-salad-ui-select-input='true']",
    );
    const target = tracker || hiddenInput || this.el;
    target.dispatchEvent(new Event("change", { bubbles: true }));
  }

  // Cleanup
  beforeDestroy() {
    if (this.positionedElement) {
      this.positionedElement.destroy();
      this.positionedElement = null;
    }

    this.destroyItems();

    this.registry = null;
    this.rovingFocus = null;
    this.selection = null;
  }
}

// Register the component
SaladUI.register("select", SelectComponent);

export default SelectComponent;
