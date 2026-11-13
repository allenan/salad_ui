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
   * Controlled (the server renders `value` or a form field): the server's
   * state is the truth, as with Radix's `pressed` prop. Uncontrolled
   * (`default-value` only): the pressed state lives on the client.
   */
  isControlled() {
    return this.options?.controlled === true;
  }

  /**
   * A LiveView patch reverts data-state, aria-pressed and the checkbox to what
   * the server rendered. Uncontrolled, while that is still what it rendered
   * last time (an unrelated re-render), keep this instance and re-apply the
   * current state. Controlled, take the server's state, even when it is the
   * one it rendered before. A new server state rebuilds from the server.
   */
  skipReinitialize(el) {
    if (el !== this.el) return false;
    if (el.getAttribute("data-options") !== this._optionsRaw) return false;
    if (el.getAttribute("data-event-mappings") !== this._eventMappingsRaw) {
      return false;
    }
    const serverState = el.getAttribute("data-state");
    if (serverState !== this._serverState) return false;

    this.setStateQuietly(this.isControlled() ? serverState : this.state);
    return true;
  }

  /** Show `state` without pushing an event or firing the form events. */
  setStateQuietly(state) {
    if (state !== "on" && state !== "off") return;
    this.stateMachine.state = state;
    this.updateUI();
    const input = this.getInput();
    if (input) input.checked = state === "on";
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

    // A controlled toggle whose server answers without changing its state
    // gets no patch; once the server has handled the event, show its state
    // again (a patch with a new state has been applied by then).
    const onReply = this.isControlled()
      ? () => {
          if (!this.destroyed) this.setStateQuietly(this._serverState);
        }
      : undefined;
    this.pushEvent("pressed-changed", { pressed }, undefined, onReply);
  }
}

SaladUI.register("toggle", ToggleComponent);

export default ToggleComponent;
