// saladui/components/input_group.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

// Clicks on these (inside an addon) keep their own focus behaviour.
const INTERACTIVE =
  "button, a[href], input, select, textarea, label, [contenteditable], [tabindex]";

const CONTROL = '[data-slot="input-group-control"]';

/**
 * Input group: clicking an addon focuses the group's control, mirroring
 * shadcn's InputGroupAddon onClick. Clicks on buttons, links, labels or other
 * focusable elements inside an addon are left alone.
 */
class InputGroupComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });
    this.onClick = this.onClick.bind(this);
  }

  getComponentConfig() {
    return {
      ariaConfig: {
        root: { all: { role: "group" } },
        addon: { all: { role: "group" } },
      },
    };
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    this.el.addEventListener("click", this.onClick);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.el.removeEventListener("click", this.onClick);
  }

  // The click listener resolves the addon and control at click time, so a
  // LiveView patch of the group's children needs no re-initialisation.
  skipReinitialize() {
    return true;
  }

  onClick(event) {
    const target = event.target;
    if (!(target instanceof Element)) return;

    const addon = target.closest('[data-slot="input-group-addon"]');
    if (!addon || !this.el.contains(addon)) return;
    if (addon.closest('[data-slot="input-group"]') !== this.el) return;

    const interactive = target.closest(INTERACTIVE);
    if (interactive && addon.contains(interactive)) return;

    this.getControl()?.focus();
  }

  getControl() {
    const controls = [
      ...this.el.querySelectorAll(`${CONTROL}, input, textarea`),
    ].filter(
      (control) =>
        control.closest('[data-slot="input-group"]') === this.el &&
        !control.closest('[data-slot="input-group-addon"]') &&
        control.type !== "hidden",
    );

    return controls.find((control) => control.matches(CONTROL)) || controls[0];
  }
}

SaladUI.register("input-group", InputGroupComponent);

export default InputGroupComponent;
