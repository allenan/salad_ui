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
    const input = this.el.querySelector('input[type="checkbox"]');
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
