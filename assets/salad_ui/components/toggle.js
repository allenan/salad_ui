// saladui/components/toggle.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

/**
 * A two-state button (Radix Toggle). The server renders `data-state="on|off"`
 * and `aria-pressed`; this keeps both, and the hidden checkbox that submits
 * the value, in sync when the button is clicked.
 */
class ToggleComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext, initialState: "off" });

    // The state the server rendered (see skipReinitialize).
    this._serverState = this.el.getAttribute("data-state");
  }

  /**
   * A LiveView patch reverts data-state, aria-pressed and the checkbox to what
   * the server rendered. When that is still what it rendered last time (it
   * never stored the user's click, e.g. a static `value` and an unrelated
   * re-render), keep this instance and re-apply the current state. A new
   * server state rebuilds the toggle from the server.
   */
  skipReinitialize(el) {
    if (el !== this.el) return false;
    if (el.getAttribute("data-options") !== this._optionsRaw) return false;
    if (el.getAttribute("data-event-mappings") !== this._eventMappingsRaw) {
      return false;
    }
    if (el.getAttribute("data-state") !== this._serverState) return false;

    this.updateUI();
    const input = this.getInput();
    if (input) input.checked = this.state === "on";
    return true;
  }

  getInput() {
    return this.el.querySelector('input[type="checkbox"]');
  }

  getComponentConfig() {
    return {
      stateMachine: {
        on: {
          enter: "onPressedChange",
          transitions: { toggle: "off", off: "off" },
        },
        off: {
          enter: "onPressedChange",
          transitions: { toggle: "on", on: "on" },
        },
      },
      ariaConfig: {
        root: {
          on: { pressed: "true" },
          off: { pressed: "false" },
        },
      },
    };
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    this.handleClick = this.handleClick.bind(this);
    this.el.addEventListener("click", this.handleClick);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.el?.removeEventListener("click", this.handleClick);
  }

  handleClick() {
    if (this.el.disabled || this.el.hasAttribute("data-disabled")) return;
    this.transition("toggle");
  }

  onPressedChange() {
    const pressed = this.state === "on";
    const input = this.getInput();
    if (input && input.checked !== pressed) {
      input.checked = pressed;
      input.dispatchEvent(new Event("input", { bubbles: true }));
      input.dispatchEvent(new Event("change", { bubbles: true }));
    }

    this.pushEvent("pressed-changed", { pressed });
  }
}

SaladUI.register("toggle", ToggleComponent);

export default ToggleComponent;
