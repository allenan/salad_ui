// saladui/components/checkbox.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

/**
 * Native checkbox helper. `indeterminate` is a DOM property with no HTML
 * attribute, so the server renders `data-indeterminate` and this component
 * copies it onto the input whenever LiveView mounts or patches it. Browsers
 * then match `:indeterminate` (the dash styling) and expose the checkbox to
 * assistive technology as "mixed".
 *
 * Clicking the input clears `indeterminate` natively, as in any browser; the
 * server's next render decides the new value.
 */
class CheckboxComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });
  }

  getComponentConfig() {
    return { stateMachine: { idle: {} } };
  }

  // The native input owns `checked`; only sync `indeterminate`, and don't
  // stamp a `data-state` that would fight the server-rendered markup.
  updateUI() {
    this.el.indeterminate = this.el.dataset.indeterminate === "true";
  }
}

SaladUI.register("checkbox", CheckboxComponent);

export default CheckboxComponent;
