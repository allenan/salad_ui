// saladui/components/toggle_group.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

const ITEM_SELECTOR = '[data-part="item"]';

/**
 * A set of two-state buttons (Radix ToggleGroup).
 *
 * - `type: "single"` items behave like radios (role="radio", aria-checked),
 *   pressing one releases the others and pressing the pressed one releases it;
 *   `type: "multiple"` items toggle independently (aria-pressed).
 * - Roving tabindex: the group is a single tab stop. The arrow keys on the
 *   group's axis move focus (Left/Right are mirrored under RTL), Home/End jump
 *   to the ends, and focus wraps around unless `loop` is false. Moving focus
 *   does not toggle; Space/Enter do, through the native button click.
 */
class ToggleGroupComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.config.preventDefaultKeys = [
      "ArrowLeft",
      "ArrowRight",
      "ArrowUp",
      "ArrowDown",
      "Home",
      "End",
    ];

    // What the server rendered, and what the user has pressed since (see
    // skipReinitialize).
    this._serverState = this.readServerState();
    this.serverPressed = this.readPressed();
    this.pressedValues = new Set(this.serverPressed);

    this.initTabStop();
  }

  /** The values of the items pressed in the DOM right now. */
  readPressed() {
    return new Set(
      this.getItems()
        .filter((item) => this.isPressed(item))
        .map((item) => item.getAttribute("data-value")),
    );
  }

  /**
   * Controlled (the server renders `value` or a form field): the server's
   * value is the truth, as with Radix's `value` prop. Uncontrolled
   * (`default-value` only): the pressed items live on the client.
   */
  isControlled() {
    return this.options?.controlled === true;
  }

  /** Press exactly the items the server rendered pressed. */
  applyServerPressed() {
    this.getItems().forEach((item) =>
      this.setItemPressed(
        item,
        this.serverPressed.has(item.getAttribute("data-value")),
      ),
    );
  }

  /** The pressed state of every item, as currently in the DOM. */
  readServerState() {
    return JSON.stringify(
      this.getItems().map((item) => [
        item.getAttribute("data-value"),
        item.getAttribute("data-state"),
      ]),
    );
  }

  /**
   * A LiveView patch reverts every item to the pressed state the server
   * rendered (data-state, aria-*, the hidden inputs) and drops the roving
   * tabindex. With unchanged options, keep this instance:
   *
   * - controlled: take what the server rendered, even when it is the value
   *   it rendered before (e.g. it refused to let a single group be emptied);
   * - uncontrolled: while the server still renders what it rendered last
   *   time (an unrelated re-render), re-apply the user's choice. A new server
   *   value rebuilds from the server.
   */
  skipReinitialize(el) {
    if (el !== this.el) return false;
    if (el.getAttribute("data-options") !== this._optionsRaw) return false;
    if (el.getAttribute("data-event-mappings") !== this._eventMappingsRaw) {
      return false;
    }

    if (this.isControlled()) {
      this._serverState = this.readServerState();
      this.serverPressed = this.readPressed();
      this.applyServerPressed();
    } else {
      if (this.readServerState() !== this._serverState) return false;

      this.getItems().forEach((item) =>
        this.setItemPressed(
          item,
          this.pressedValues.has(item.getAttribute("data-value")),
        ),
      );
    }

    const tabStop = this.getItems().find(
      (item) => item === this.tabStopItem && !this.isItemDisabled(item),
    );
    if (tabStop) this.setTabStop(tabStop);
    else this.initTabStop();

    return true;
  }

  getType() {
    return this.options?.type === "multiple" ? "multiple" : "single";
  }

  /**
   * Read from options because getComponentConfig() runs inside the base
   * constructor, before any subclass fields exist.
   */
  getOrientation() {
    return this.options?.orientation === "vertical" ? "vertical" : "horizontal";
  }

  shouldLoop() {
    return this.options?.loop !== false;
  }

  getComponentConfig() {
    // Like Radix's roving focus group, only the arrow keys on the group's
    // axis move focus; horizontal groups follow the reading direction.
    const keyMap =
      this.getOrientation() === "vertical"
        ? {
            ArrowUp: (event) => this.moveFocus(event, "prev"),
            ArrowDown: (event) => this.moveFocus(event, "next"),
          }
        : {
            ArrowLeft: (event) =>
              this.moveFocus(event, this.isRtl() ? "next" : "prev"),
            ArrowRight: (event) =>
              this.moveFocus(event, this.isRtl() ? "prev" : "next"),
          };

    return {
      stateMachine: {
        idle: { transitions: {} },
      },
      events: {
        idle: {
          keyMap: {
            ...keyMap,
            Home: (event) => this.moveFocus(event, "first"),
            End: (event) => this.moveFocus(event, "last"),
          },
        },
      },
      ariaConfig: {
        root: {
          all: { role: "group" },
        },
      },
    };
  }

  setupComponentEvents() {
    super.setupComponentEvents();

    this.handleClick = this.handleClick.bind(this);
    this.handleFocusIn = this.handleFocusIn.bind(this);
    this.el.addEventListener("click", this.handleClick);
    this.el.addEventListener("focusin", this.handleFocusIn);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();

    this.el?.removeEventListener("click", this.handleClick);
    this.el?.removeEventListener("focusin", this.handleFocusIn);
  }

  /** This group's items, skipping those of a nested toggle group. */
  getItems() {
    return Array.from(this.el.querySelectorAll(ITEM_SELECTOR)).filter(
      (item) => item.closest('[data-component="toggle-group"]') === this.el,
    );
  }

  getEnabledItems() {
    return this.getItems().filter((item) => !this.isItemDisabled(item));
  }

  isItemDisabled(item) {
    return item.disabled || item.hasAttribute("data-disabled");
  }

  isPressed(item) {
    return item.getAttribute("data-state") === "on";
  }

  itemFromEvent(event) {
    const item = event.target?.closest?.(ITEM_SELECTOR);
    return item && this.getItems().includes(item) ? item : null;
  }

  /** `""`/the pressed value for single groups, a list for multiple groups. */
  getValue() {
    const values = this.getItems()
      .filter((item) => this.isPressed(item))
      .map((item) => item.getAttribute("data-value"));

    return this.getType() === "multiple" ? values : (values[0] ?? "");
  }

  initTabStop() {
    const enabled = this.getEnabledItems();
    const target = enabled.find((item) => this.isPressed(item)) || enabled[0];
    this.setTabStop(target);
  }

  setTabStop(target) {
    this.tabStopItem = target;
    this.getItems().forEach((item) => {
      item.tabIndex = item === target ? 0 : -1;
    });
  }

  handleFocusIn(event) {
    const item = this.itemFromEvent(event);
    if (item && !this.isItemDisabled(item)) this.setTabStop(item);
  }

  handleClick(event) {
    const item = this.itemFromEvent(event);
    if (!item || this.isItemDisabled(item)) return;

    this.toggleItem(item);
    this.setTabStop(item);
  }

  toggleItem(item) {
    const pressed = !this.isPressed(item);

    if (pressed && this.getType() === "single") {
      this.getItems()
        .filter((other) => other !== item && this.isPressed(other))
        .forEach((other) => this.setItemPressed(other, false));
    }

    this.setItemPressed(item, pressed);

    const input = item.querySelector("input");
    if (input) {
      input.dispatchEvent(new Event("input", { bubbles: true }));
      input.dispatchEvent(new Event("change", { bubbles: true }));
    }

    // A controlled group whose server answers without changing its value
    // gets no patch; once the server has handled the event, show its value
    // again (a patch with a new value has been applied by then).
    const onReply = this.isControlled()
      ? () => {
          if (!this.destroyed) this.applyServerPressed();
        }
      : undefined;
    this.pushEvent(
      "value-changed",
      { value: this.getValue() },
      undefined,
      onReply,
    );
  }

  setItemPressed(item, pressed) {
    item.setAttribute("data-state", pressed ? "on" : "off");

    if (this.getType() === "single") {
      item.setAttribute("aria-checked", String(pressed));
    } else {
      item.setAttribute("aria-pressed", String(pressed));
    }

    const value = item.getAttribute("data-value");
    if (pressed) this.pressedValues?.add(value);
    else this.pressedValues?.delete(value);

    const input = item.querySelector("input");
    if (input) input.checked = pressed;
  }

  moveFocus(event, direction) {
    const items = this.getEnabledItems();
    if (items.length === 0) return;

    // Keys from anything but one of this group's items (e.g. an item of a
    // nested toggle group, whose keydown bubbles up here) are not ours.
    const index = items.indexOf(this.itemFromEvent(event));
    if (index === -1) return;
    const last = items.length - 1;
    let next = null;

    switch (direction) {
      case "first":
        next = items[0];
        break;
      case "last":
        next = items[last];
        break;
      case "next":
        if (index < last) next = items[index + 1];
        else if (this.shouldLoop()) next = items[0];
        break;
      case "prev":
        if (index > 0) next = items[index - 1];
        else if (this.shouldLoop()) next = items[last];
        break;
    }

    if (!next) return;
    this.setTabStop(next);
    next.focus();
  }
}

SaladUI.register("toggle-group", ToggleGroupComponent);

export default ToggleGroupComponent;
