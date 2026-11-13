// saladui/index.js
import Component from "./core/component.js";
import { registry } from "./core/factory.js";
import { SaladUIHook } from "./core/hook.js";
import { getDirection } from "./core/direction.js";

function register(type, ComponentClass) {
  registry.register(type, ComponentClass);
}

const SaladUI = {
  Component,
  register,
  SaladUIHook,
  // The counterpart of shadcn's useDirection(): "ltr" or "rtl" for an element.
  getDirection,
};

export default SaladUI;
