// saladui/components/menu.js
import Component from "../core/component.js";
import { CollectionRegistry, RovingFocus } from "../core/collection.js";
import PositionedElement from "../core/positioned-element.js";

// Parts that are navigable menu items, and parts that are menu panels.
const ITEM_SELECTOR = [
  "[data-part='item']",
  "[data-part='checkbox-item']",
  "[data-part='radio-item']",
  "[data-part='sub-trigger']",
].join(", ");
const MENU_SELECTOR = "[data-part='content'], [data-part='sub-content']";

let subContentCounter = 0;

function readItemValue(itemElement) {
  return (
    itemElement.value ||
    itemElement.getAttribute("data-value") ||
    itemElement.textContent.trim()
  );
}

function isRtl(el) {
  return el?.closest("[dir]")?.getAttribute("dir") === "rtl";
}

/**
 * Base class for dropdown menu items that provides common functionality
 */
class MenuItemBase extends Component {
  constructor(itemElement, parentComponent, options) {
    super(itemElement, {
      ...options,
      initialState: options?.initialState || "idle",
      ignoreItems: false,
    });

    this.parent = parentComponent;
    // share the same hook context with the parent
    this.hook = this.parent.hook;
    this.value = readItemValue(itemElement);
    this.disabled = this.isElementDisabled(itemElement);
    // The base constructor applied ARIA before `disabled` was known.
    this.updateUI();
    this.config.preventDefaultKeys = [" ", "Enter"];
    this.setupEvents();
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
        idle: {},
      },
      events: {
        idle: {
          mouseMap: {
            item: {
              click: "handleActivation",
              mouseenter: "handleMouseEnter",
            },
          },
          keyMap: {
            " ": "handleActivation",
            Enter: "handleActivation",
          },
        },
      },
      ariaConfig: {
        item: {
          all: {
            role: "menuitem",
            disabled: () => (this.disabled ? "true" : null),
          },
        },
      },
    };
  }

  handleEvent(eventType) {
    switch (eventType) {
      case "focus":
        if (!this.disabled) {
          this.el.focus();
        }
        return true;
      case "blur":
        return true;
    }
  }

  handleActivation(event) {
    if (!this.notifyActivation(event)) return;

    this.parent.selectItem(this);
  }

  // Shared activation bookkeeping: guards, prevents the native action, and
  // notifies the server. Returns whether activation should proceed, so
  // subclasses (e.g. MenuCheckboxItem) can opt out of parent.selectItem()
  // (which closes the menu) while still getting this behavior.
  notifyActivation(event) {
    const shouldPreserveNativeClick =
      event?.type === "click" && this.isNativeLinkItem();

    if (event && !shouldPreserveNativeClick) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
    }

    if (this.disabled) return false;

    this.pushEvent(
      "select",
      {
        value: this.value,
      },
      this.parent.rootEl || this.parent.el,
    );

    return true;
  }

  isNativeLinkItem() {
    return this.el.matches("a[href]");
  }

  handleMouseEnter() {
    if (!this.disabled) {
      this.parent.handleItemFocus(this);
    }
  }
}

/**
 * Regular dropdown menu item implementation
 */
class MenuItem extends MenuItemBase {
  constructor(itemElement, parentComponent, options) {
    super(itemElement, parentComponent, options);
  }
}

/**
 * Builds the config shared by two-state (checked/unchecked) items.
 */
function checkableConfig(component, part, role) {
  const events = {
    mouseMap: {
      [part]: {
        click: "handleActivation",
        mouseenter: "handleMouseEnter",
      },
    },
    keyMap: {
      " ": "handleActivation",
      Enter: "handleActivation",
    },
  };

  return {
    stateMachine: {
      checked: {
        transitions: {
          toggle: "unchecked",
          uncheck: "unchecked",
        },
      },
      unchecked: {
        transitions: {
          toggle: "checked",
          check: "checked",
        },
      },
    },
    events: {
      checked: events,
      unchecked: events,
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
      [part]: {
        all: {
          role,
          disabled: () => (component.disabled ? "true" : null),
          checked: () => (component.state == "checked" ? "true" : "false"),
        },
      },
    },
  };
}

/**
 * Checkbox item implementation that can toggle between checked states
 */
class MenuCheckboxItem extends MenuItemBase {
  constructor(itemElement, parentComponent, options) {
    super(itemElement, parentComponent, options);
  }

  getComponentConfig() {
    return checkableConfig(this, "checkbox-item", "menuitemcheckbox");
  }

  // Overridden (not calling super.handleActivation()) so toggling a
  // checkbox item does not call parent.selectItem(), which would close the
  // menu: checkbox items stay open on toggle.
  handleActivation(event) {
    if (!this.notifyActivation(event)) return;

    this.transition("toggle");

    this.pushEvent(
      "checked-change",
      {
        value: this.value,
        checked: this.state == "checked",
      },
      this.parent.rootEl || this.parent.el,
    );
  }
}

/**
 * Owns the selected value of a `radio-group` part and fires `value-changed`
 * (mapped from the group's `on-value-changed`) when it changes.
 */
class MenuRadioGroup extends Component {
  constructor(el, { hookContext, rootEl }) {
    super(el, { hookContext });
    this.rootEl = rootEl;
    this.value = el.getAttribute("data-value");
    this.items = [];
  }

  getComponentConfig() {
    return { stateMachine: { idle: {} } };
  }

  // The group has no visual state of its own; don't stamp data-state on it.
  updateUI() {}

  isValueChecked(value) {
    return this.value !== null && this.value === value;
  }

  register(item) {
    this.items.push(item);
  }

  select(item) {
    if (this.isValueChecked(item.value)) return false;

    this.value = item.value;
    this.el.setAttribute("data-value", item.value);
    this.items.forEach((radio) =>
      radio.transition(radio === item ? "check" : "uncheck"),
    );

    this.pushEvent("value-changed", { value: item.value }, this.rootEl);
    return true;
  }

  beforeDestroy() {
    this.items = null;
  }
}

/**
 * Radio item: one checked item per `radio-group`. Like checkbox items,
 * picking one keeps the menu open.
 */
class MenuRadioItem extends MenuItemBase {
  constructor(itemElement, parentComponent, options) {
    super(itemElement, parentComponent, options);
    this.group = options.group || null;
    this.group?.register(this);
  }

  getComponentConfig() {
    return checkableConfig(this, "radio-item", "menuitemradio");
  }

  handleActivation(event) {
    if (!this.notifyActivation(event)) return;

    this.group?.select(this);
  }
}

/**
 * Sub-menu trigger. A menu item in its parent menu that owns the sibling
 * `sub-positioner`/`sub-content` and a nested Menu for the sub-content's
 * items.
 */
class MenuSubTrigger extends MenuItemBase {
  constructor(itemElement, parentComponent, options) {
    super(itemElement, parentComponent, {
      ...options,
      initialState: "closed",
    });

    const subEl = itemElement.closest("[data-part='sub']");
    this.positioner = subEl?.querySelector(
      ":scope > [data-part='sub-positioner']",
    );
    this.content = this.positioner?.querySelector(
      ":scope > [data-part='sub-content']",
    );

    if (this.content && !this.content.id) {
      const prefix = parentComponent.rootEl?.id || "salad-menu";
      this.content.id = `${prefix}-sub-content-${++subContentCounter}`;
    }

    this.subMenu = this.content
      ? new Menu(this.content, {
          hookContext: parentComponent.hook,
          rootEl: parentComponent.rootEl,
          onItemSelect: parentComponent.onItemSelect,
          subTrigger: this,
        })
      : null;

    // Never start open: a sub-menu only opens through user interaction.
    if (this.state !== "closed") this.transition("close");
    this.updateUI();
  }

  getComponentConfig() {
    const events = {
      mouseMap: {
        "sub-trigger": {
          click: "handleActivation",
          mouseenter: "handleMouseEnter",
        },
      },
    };

    return {
      stateMachine: {
        closed: {
          enter: "onClosedEnter",
          transitions: { open: "open" },
        },
        open: {
          enter: "onOpenEnter",
          transitions: { close: "closed" },
        },
      },
      events: {
        _all: {
          keyMap: {
            " ": "handleActivation",
            Enter: "handleActivation",
            ArrowRight: "handleHorizontalKey",
            ArrowLeft: "handleHorizontalKey",
          },
        },
        closed: events,
        open: events,
      },
      ariaConfig: {
        "sub-trigger": {
          all: {
            role: "menuitem",
            haspopup: "menu",
            disabled: () => (this.disabled ? "true" : null),
            controls: () => this.content?.id || null,
          },
          open: { expanded: "true" },
          closed: { expanded: "false" },
        },
      },
    };
  }

  get openKey() {
    return isRtl(this.el) ? "ArrowLeft" : "ArrowRight";
  }

  handleEvent(eventType) {
    // Focus moving to a sibling item in the parent menu closes this sub-menu.
    if (eventType === "blur") {
      this.close();
      return true;
    }

    return super.handleEvent(eventType);
  }

  handleActivation(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
    }

    // Keyboard activation moves focus into the sub-menu; a click leaves it on
    // the trigger, like hover.
    this.open({ focusFirst: event?.type !== "click" });
  }

  handleHorizontalKey(event) {
    if (event.key !== this.openKey) return;

    event.preventDefault();
    event.stopPropagation();
    this.open({ focusFirst: true });
  }

  handleMouseEnter() {
    if (this.disabled) return;

    this.parent.handleItemFocus(this);
    // Coming back from the sub-menu, the parent's roving focus already points
    // here, so focus the trigger explicitly.
    if (document.activeElement !== this.el) this.el.focus();
    this.open();
  }

  open({ focusFirst = false } = {}) {
    if (this.disabled || !this.content) return;

    if (this.state !== "open") {
      this.parent.closeSubmenus(this);
      this.transition("open");
    }

    if (focusFirst) this.subMenu?.activate();
  }

  close({ restoreFocus = false } = {}) {
    if (this.state !== "open") return;

    this.transition("close", { restoreFocus });
  }

  initializePositionedElement() {
    if (this.positionedElement || !this.positioner) return;

    const rtl = isRtl(this.el);
    let side = this.positioner.getAttribute("data-side") || "right";
    if (rtl) side = side === "left" ? "right" : "left";

    this.positionedElement = new PositionedElement(this.positioner, this.el, {
      placement: side,
      alignment: this.positioner.getAttribute("data-align") || "start",
      sideOffset: parseInt(
        this.positioner.getAttribute("data-side-offset") || "0",
        10,
      ),
      alignOffset: parseInt(
        this.positioner.getAttribute("data-align-offset") || "0",
        10,
      ),
      flip: true,
      trapFocus: false,
      onPosition: ({ placement }) =>
        this.content?.setAttribute("data-side", placement),
    });
  }

  onOpenEnter() {
    if (!this.positioner) return;

    this.positioner.hidden = false;
    this.content.setAttribute("data-state", "open");
    this.initializePositionedElement();
    this.positionedElement.activate();

    // While the parent panel runs its enter animation it has a transform, so
    // it is the containing block of this fixed-position panel; re-measure
    // once that animation finishes.
    this.panel = this.el.closest(MENU_SELECTOR);
    this.panel?.addEventListener("animationend", this.handlePanelAnimationEnd);
  }

  handlePanelAnimationEnd = (event) => {
    if (event.target === this.panel) this.positionedElement?.update();
  };

  stopWatchingPanel() {
    this.panel?.removeEventListener(
      "animationend",
      this.handlePanelAnimationEnd,
    );
    this.panel = null;
  }

  onClosedEnter({ restoreFocus = false } = {}) {
    if (!this.positioner) return;

    this.subMenu?.closeSubmenus();
    this.stopWatchingPanel();
    this.positionedElement?.deactivate();
    this.content.setAttribute("data-state", "closed");
    this.positioner.hidden = true;

    if (restoreFocus) this.el.focus();
  }

  beforeDestroy() {
    this.stopWatchingPanel();
    this.subMenu?.destroy();
    this.subMenu = null;
    this.positionedElement?.destroy();
    this.positionedElement = null;
  }
}

/**
 * Menu manages the items of one menu panel (`content` or `sub-content`):
 * roving focus, arrow-key navigation and item activation. Items inside a
 * nested sub-menu belong to that sub-menu's own Menu.
 */
class Menu extends Component {
  constructor(el, { hookContext, onItemSelect, rootEl, subTrigger = null }) {
    super(el, { hookContext });

    // callback for item selection
    this.onItemSelect = onItemSelect || (() => {});
    this.rootEl = rootEl;
    this.subTrigger = subTrigger;
    this.menuItems = [];
    this.radioGroups = new Map();

    // Set keyboard navigation defaults
    this.config.preventDefaultKeys = ["ArrowDown", "ArrowUp", "Home", "End"];

    // Initialize items and collection
    this.initializeItems();
    this.initializeCollection();
    this.setupEvents();
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: {
          transitions: {},
        },
      },
      events: {
        _all: {
          keyMap: {
            ArrowDown: (event) => this.handleNavigationKey(event, "next"),
            ArrowUp: (event) => this.handleNavigationKey(event, "prev"),
            Home: (event) => this.handleNavigationKey(event, "first"),
            End: (event) => this.handleNavigationKey(event, "last"),
            ArrowLeft: "handleCloseKey",
            ArrowRight: "handleCloseKey",
          },
        },
      },
      ariaConfig: {},
    };
  }

  // The panel's data-state is owned by whoever opens it (the dropdown root
  // or a sub-trigger), so the menu itself never stamps one.
  updateUI() {}

  initializeItems() {
    // Only this panel's own items, in DOM order; nested sub-menu items are
    // handled by the sub-trigger's own Menu.
    const allItemElements = Array.from(
      this.el.querySelectorAll(ITEM_SELECTOR),
    ).filter((element) => element.closest(MENU_SELECTOR) === this.el);

    this.menuItems = allItemElements.map((element) => {
      const itemType = element.getAttribute("data-part");

      switch (itemType) {
        case "checkbox-item":
          return new MenuCheckboxItem(element, this, {
            initialState:
              element.dataset.state ||
              (element.dataset.checked === "true" ? "checked" : "unchecked"),
          });
        case "radio-item": {
          const group = this.radioGroupFor(element);
          // The group's value is the source of truth, not a stale data-state.
          element.removeAttribute("data-state");
          return new MenuRadioItem(element, this, {
            group,
            initialState: group?.isValueChecked(readItemValue(element))
              ? "checked"
              : "unchecked",
          });
        }
        case "sub-trigger":
          return new MenuSubTrigger(element, this, {});
        default: // Regular item
          return new MenuItem(element, this, {
            initialState: "idle",
          });
      }
    });
  }

  radioGroupFor(itemElement) {
    const groupEl = itemElement.closest("[data-part='radio-group']");
    if (!groupEl || !this.el.contains(groupEl)) return null;

    if (!this.radioGroups.has(groupEl)) {
      this.radioGroups.set(
        groupEl,
        new MenuRadioGroup(groupEl, {
          hookContext: this.hook,
          rootEl: this.rootEl,
        }),
      );
    }

    return this.radioGroups.get(groupEl);
  }

  initializeCollection() {
    // Initialize registry and focus manager for navigation
    this.registry = new CollectionRegistry({
      type: "single",
      getItemValue: (item) => item.value,
      isItemDisabled: (item) => item.disabled,
    });
    this.rovingFocus = new RovingFocus(this.registry);

    // Register items with the registry
    this.menuItems.forEach((item) => {
      this.registry.add(item);
    });
  }

  // Activate menu, focus the first item
  activate() {
    // Forget the previously focused item so reopening focuses the first item
    // again instead of no-oping on a stale roving-focus pointer.
    if (this.rovingFocus.focusedItem) {
      this.rovingFocus.focusedItem.focused = false;
      this.rovingFocus.reset();
    }

    const firstItem = this.registry.getItem("first");
    if (firstItem) {
      this.rovingFocus.focus(firstItem);
    }
  }

  selectItem(item) {
    if (item.disabled) return;
    this.onItemSelect(item);
  }

  handleItemFocus(item) {
    const collectionItem = this.registry.getItemByInstance(item);
    if (!collectionItem) return;

    this.rovingFocus.focus(collectionItem);
  }

  handleNavigationKey(event, direction) {
    // Keys handled here must not also reach an enclosing menu panel.
    event.stopPropagation();
    this.navigateItem(direction);
  }

  // ArrowLeft (ArrowRight under RTL) inside a sub-menu closes it and returns
  // focus to its trigger.
  handleCloseKey(event) {
    if (!this.subTrigger) return;

    const closeKey = isRtl(this.el) ? "ArrowRight" : "ArrowLeft";
    if (event.key !== closeKey) return;

    event.preventDefault();
    event.stopPropagation();
    this.subTrigger.close({ restoreFocus: true });
  }

  // Close every open sub-menu of this panel, except `keep`.
  closeSubmenus(keep = null) {
    this.menuItems?.forEach((item) => {
      if (item instanceof MenuSubTrigger && item !== keep) item.close();
    });
  }

  navigateItem(direction) {
    // Check if we have an active focused item
    let currentItem = this.rovingFocus.focusedItem;

    // Get target item using registry navigation methods
    const targetItem = this.registry.getItem(direction, currentItem);

    if (targetItem) {
      this.rovingFocus.focus(targetItem);
    }
  }

  beforeDestroy() {
    // Clean up menu items
    if (this.menuItems) {
      this.menuItems.forEach((item) => {
        if (typeof item.destroy === "function") {
          item.destroy();
        }
      });
      this.menuItems = null;
    }

    this.radioGroups?.forEach((group) => group.destroy());
    this.radioGroups = null;

    // Clean up registry and focus manager
    this.registry = null;
    this.rovingFocus = null;
  }
}

export default Menu;
