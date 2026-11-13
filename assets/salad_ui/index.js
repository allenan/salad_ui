// saladui/index.js
import Component from "./core/component.js";
import { registry } from "./core/factory.js";
import { SaladUIHook } from "./core/hook.js";
import { getDirection } from "./core/direction.js";

function register(type, ComponentClass) {
  registry.register(type, ComponentClass);
}

/**
 * Run a command on a component from plain JS, e.g.
 * `SaladUI.command("#settings-dialog", "open")` or
 * `SaladUI.command(panelGroup, "collapse", { panel: "side-pane" })`.
 *
 * `target` is the component's root element or a selector for it. This
 * dispatches the same non-bubbling `salad_ui:command` event as
 * `SaladUI.JS.dispatch_command/3`, so it reaches the commands
 * `SaladUI.LiveView.send_command/4` reaches. Returns false when no element
 * matches.
 */
function command(target, name, params = {}) {
  const el =
    typeof target === "string" ? document.querySelector(target) : target;
  if (!el || typeof el.dispatchEvent !== "function") return false;

  el.dispatchEvent(
    new CustomEvent("salad_ui:command", {
      detail: { command: name, params: params ?? {} },
      bubbles: false,
    }),
  );
  return true;
}

const SaladUI = {
  Component,
  register,
  SaladUIHook,
  command,
  // The counterpart of shadcn's useDirection(): "ltr" or "rtl" for an element.
  getDirection,
};

export { command };
export default SaladUI;
