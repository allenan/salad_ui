// saladui/components/menu.js
import Component, { assignId } from "../core/component.js";
import { isRtl } from "../core/direction.js";
import { CollectionRegistry, RovingFocus } from "../core/collection.js";
import PositionedElement from "../core/positioned-element.js";
import { getTextValue, typeaheadFor } from "../core/typeahead.js";

// Parts that are navigable menu items, and parts that are menu panels.
const ITEM_SELECTOR = [
  "[data-part='item']",
  "[data-part='checkbox-item']",
  "[data-part='radio-item']",
  "[data-part='sub-trigger']",
].join(", ");
const MENU_SELECTOR = "[data-part='content'], [data-part='sub-content']";

// How long the pointer may take to travel from a sub-trigger to its sub-menu.
const POINTER_GRACE_MS = 300;

let subMenuCounter = 0;

// Clicks an item already handled. A checkable item binds its click handler
// once per state, so toggling in the first would run the second too; the
// click itself must keep bubbling (see notifyActivation).
const activations = new WeakSet();

function isPointInPolygon({ x, y }, polygon) {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const a = polygon[i];
    const b = polygon[j];
    if (
      a.y > y !== b.y > y &&
      x < ((b.x - a.x) * (y - a.y)) / (b.y - a.y) + a.x
    )
      inside = !inside;
  }
  return inside;
}

function readItemValue(itemElement) {
  return (
    itemElement.value ||
    itemElement.getAttribute("data-value") ||
    itemElement.textContent.trim()
  );
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
              mousemove: "handleMouseEnter",
              mouseleave: "handleMouseLeave",
            },
          },
          keyMap: {
            " ": "handleSpaceKey",
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

    this.closeMenuOnSelect();
  }

  // Picking any item (checkbox and radio items too) closes the menu, as in
  // Radix. `data-close-on-select="false"` (the components'
  // `close-on-select={false}`) keeps it open instead, like calling
  // `event.preventDefault()` in a Radix `onSelect`.
  get closeOnSelect() {
    return this.el.getAttribute("data-close-on-select") !== "false";
  }

  closeMenuOnSelect() {
    if (this.closeOnSelect) this.parent.selectItem(this);
  }

  // While a typeahead search is in progress, Space types a space (handled by
  // the panel) instead of activating the item.
  handleSpaceKey(event) {
    if (this.parent.typeahead?.isSearching) return;

    this.handleActivation(event);
  }

  // Shared activation bookkeeping: guards, prevents the native action, and
  // notifies the server. Returns whether activation should proceed, so
  // subclasses (e.g. MenuCheckboxItem) can update their own state before
  // closeMenuOnSelect().
  //
  // A click is left to bubble, as Radix's item `onClick` does, so LiveView's
  // own click handling (on the window) runs an item's `phx-click`. Enter and
  // Space become a click on the item, as in Radix, so `phx-click` fires from
  // the keyboard too; that click does the activation.
  notifyActivation(event) {
    if (event && event.type !== "click") {
      // The key is spent here (the panel's typeahead must not see Space).
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation();
      if (!this.disabled) this.el.click();
      return false;
    }

    if (event) {
      if (activations.has(event)) return false;
      activations.add(event);
      if (!this.isNativeLinkItem()) event.preventDefault();
    }

    if (this.disabled) {
      // A disabled item does nothing, not even its phx-click.
      event?.stopPropagation();
      return false;
    }

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

  // Pointer moves focus to the hovered item (mousemove too, so an item
  // skipped during a sub-menu's pointer grace is focused once it ends).
  // Hovering a disabled item un-highlights the menu, as leaving one does.
  handleMouseEnter(event) {
    if (this.disabled) {
      this.parent.handleItemLeave(event);
      return;
    }
    if (this.parent.isPointerMovingToSubmenu(event)) return;

    this.parent.handleItemFocus(this);
  }

  handleMouseLeave(event) {
    this.parent.handleItemLeave(event);
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
        mousemove: "handleMouseEnter",
        mouseleave: "handleMouseLeave",
      },
    },
    keyMap: {
      " ": "handleSpaceKey",
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

  // Toggles and fires `checked-change` before the menu closes.
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

    this.closeMenuOnSelect();
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
 * Radio item: one checked item per `radio-group`. Picking one checks it, then
 * closes the menu like any item (unless `data-close-on-select="false"`).
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
    this.closeMenuOnSelect();
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

    if (this.content) {
      const prefix = `${parentComponent.rootEl?.id || "salad-menu"}-sub`;
      const n = ++subMenuCounter;
      assignId(this.content, `${prefix}-content-${n}`);
      this.content.setAttribute(
        "aria-labelledby",
        assignId(itemElement, `${prefix}-trigger-${n}`),
      );
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
          mousemove: "handleMouseEnter",
          mouseleave: "handleMouseLeave",
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
            " ": "handleSpaceKey",
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

  handleMouseEnter(event) {
    this.lastPointerX = event?.clientX;
    if (this.disabled) {
      this.parent.handleItemLeave(event);
      return;
    }
    if (this.parent.isPointerMovingToSubmenu(event)) return;

    this.parent.handleItemFocus(this);
    // Coming back from the sub-menu, the parent's roving focus already points
    // here, so focus the trigger explicitly.
    if (document.activeElement !== this.el) this.el.focus();
    this.open();
  }

  // Leaving toward the open sub-menu: give the pointer a grace area (the
  // polygon between the exit point and the sub-menu's near edge) in which
  // sibling items don't steal focus and close it. Leaving while moving away
  // from it (Radix tracks the pointer direction too) un-highlights it like
  // any item, which closes the sub-menu.
  handleMouseLeave(event) {
    const rect =
      this.state === "open" ? this.content?.getBoundingClientRect() : null;
    const toRight = rect && rect.left + rect.width / 2 > event.clientX;
    const lastX = this.lastPointerX;
    const movingAway =
      lastX !== undefined &&
      (toRight ? event.clientX < lastX : event.clientX > lastX);

    if (rect?.width && rect?.height && !movingAway) {
      const near = toRight ? rect.left : rect.right;
      const far = toRight ? rect.right : rect.left;

      this.parent.setPointerGrace([
        { x: event.clientX + (toRight ? -5 : 5), y: event.clientY },
        { x: near, y: rect.top },
        { x: far, y: rect.top },
        { x: far, y: rect.bottom },
        { x: near, y: rect.bottom },
      ]);
    } else {
      this.parent.pointerGrace = null;
    }

    super.handleMouseLeave(event);
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
    // Per panel, so a sub-menu searches only its own items; kept on the
    // element so a search survives the rebuild a LiveView patch causes.
    this.typeahead = typeaheadFor(el);

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

  setupComponentEvents() {
    super.setupComponentEvents();
    this.el.addEventListener("keydown", this.handleTypeaheadKeydown);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.el.removeEventListener("keydown", this.handleTypeaheadKeydown);
  }

  // Typing moves focus to the next enabled item whose text starts with what
  // was typed (Radix menu typeahead).
  handleTypeaheadKeydown = (event) => {
    // A nested sub-menu's keys bubble through this panel; it has its own.
    if (event.target?.closest?.(MENU_SELECTOR) !== this.el) return;
    if (!this.menuItems) return;

    const items = this.menuItems.filter((item) => !item.disabled);
    const active = document.activeElement;
    this.typeahead.handleKey(event, {
      items,
      current: items.find((item) => item.el === active) || null,
      getText: (item) => getTextValue(item.el),
      onMatch: (item) => {
        this.handleItemFocus(item);
        if (document.activeElement !== item.el) item.el.focus();
      },
    });
  };

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
          // A group rendered without a value adopts the item rendered
          // `checked` (the dead-render hint); otherwise the group's value is
          // the source of truth, not a stale data-state.
          if (
            group?.value === null &&
            element.getAttribute("data-state") === "checked"
          ) {
            group.value = readItemValue(element);
          }
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

  // Forget the roving-focus pointer without moving focus, so the next
  // ArrowDown starts from the first item (ArrowUp from the last).
  // Also drops any typeahead search, so a reopened menu starts afresh.
  reset() {
    this.typeahead.reset();
    if (this.rovingFocus.focusedItem) {
      this.rovingFocus.focusedItem.focused = false;
      this.rovingFocus.reset();
    }
  }

  // Whether ArrowDown/ArrowUp wrap around (`data-loop="true"`, the content's
  // `loop` attr). Off by default, as in Radix: ArrowDown on the last item
  // stays put.
  get loop() {
    return this.el.getAttribute("data-loop") === "true";
  }

  // Activate menu, focus the first (or last) item
  activate(direction = "first") {
    // Forget the previously focused item so reopening focuses the first item
    // again instead of no-oping on a stale roving-focus pointer.
    this.reset();

    const item = this.registry.getItem(direction);
    if (item) {
      this.rovingFocus.focus(item);
    }
  }

  selectItem(item) {
    if (item.disabled) return;
    this.onItemSelect(item);
  }

  setPointerGrace(area) {
    this.pointerGrace = { area, until: Date.now() + POINTER_GRACE_MS };
  }

  isPointerMovingToSubmenu(event) {
    const grace = this.pointerGrace;
    if (!grace || event?.clientX === undefined) return false;

    const inside =
      Date.now() <= grace.until &&
      isPointInPolygon({ x: event.clientX, y: event.clientY }, grace.area);
    if (!inside) this.pointerGrace = null;
    return inside;
  }

  openSubTrigger() {
    return (
      this.menuItems?.find(
        (item) => item instanceof MenuSubTrigger && item.state === "open",
      ) || null
    );
  }

  // Which sub-menus are open (outermost first) and which item has focus, so
  // a menu rebuilt after a LiveView patch can pick up where this one was.
  snapshot() {
    const openSubTriggers = [];
    for (
      let sub = this.openSubTrigger();
      sub;
      sub = sub.subMenu?.openSubTrigger()
    )
      openSubTriggers.push(sub.el);

    const active = document.activeElement;
    return {
      openSubTriggers,
      focused: active && this.el.contains(active) ? active : null,
    };
  }

  restore({ openSubTriggers = [], focused = null } = {}) {
    const menus = [this];
    for (const el of openSubTriggers) {
      const menu = menus.at(-1);
      const sub = menu.menuItems.find(
        (item) => item instanceof MenuSubTrigger && item.el === el,
      );
      if (!sub?.subMenu) break;

      // The parent's roving focus points at an open sub-menu's trigger.
      menu.handleItemFocus(sub);
      sub.open();
      menus.push(sub.subMenu);
    }

    for (const menu of menus.reverse()) {
      const item = menu.menuItems.find((candidate) => candidate.el === focused);
      if (item && !item.disabled) {
        menu.handleItemFocus(item);
        return;
      }
    }

    if (menus.length === 1) this.activate();
  }

  handleItemFocus(item) {
    const collectionItem = this.registry.getItemByInstance(item);
    if (!collectionItem) return;

    this.rovingFocus.focus(collectionItem);
  }

  // The pointer leaving an item (or resting on a disabled one) takes the
  // highlight off it: focus moves to the panel itself, as in Radix, and an
  // open sub-menu closes. Not while the pointer is heading into that
  // sub-menu, nor when focus is elsewhere (a keyboard user's highlight in a
  // nested sub-menu, or outside the menu).
  handleItemLeave(event) {
    if (!this.rovingFocus || this.isPointerMovingToSubmenu(event)) return;

    const focused = this.rovingFocus.focusedItem;
    if (!focused || document.activeElement !== focused.instance.el) return;

    focused.focused = false;
    focused.instance.handleEvent?.("blur");
    this.rovingFocus.reset();
    this.el.focus({ preventScroll: true });
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
    const targetItem = this.registry.getItem(direction, currentItem, this.loop);

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
