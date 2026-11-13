import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import SaladUI, { command } from "../salad_ui/index.js";
import "../salad_ui/components/toggle.js";
import { registry } from "../salad_ui/core/factory.js";
import { installDom, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function mountToggle() {
  document.body.innerHTML = `
    <div id="wrapper">
      <button id="bold" type="button" data-component="toggle" data-part="root"
              data-state="off" aria-pressed="false">B</button>
    </div>`;
  const el = document.getElementById("bold");
  const component = registry.create("toggle", el, {
    pushEventTo() {},
    liveSocket: { execJS() {} },
  });
  return { el, component };
}

test("SaladUI.command runs a command on a component by selector or element", () => {
  const { el, component } = mountToggle();
  assert.equal(SaladUI.command, command);

  assert.equal(SaladUI.command("#bold", "toggle"), true);
  assert.equal(component.state, "on");
  assert.equal(SaladUI.command(el, "off"), true);
  assert.equal(component.state, "off");
  component.destroy();
});

test("SaladUI.command dispatches a non-bubbling salad_ui:command with params", () => {
  document.body.innerHTML = `<div id="outer"><div id="target"></div></div>`;
  const seen = [];
  const outer = [];
  document
    .getElementById("target")
    .addEventListener("salad_ui:command", (event) => seen.push(event.detail));
  document
    .getElementById("outer")
    .addEventListener("salad_ui:command", (event) => outer.push(event.detail));

  SaladUI.command("#target", "collapse", { panel: "side" });

  assert.deepEqual(seen, [{ command: "collapse", params: { panel: "side" } }]);
  assert.deepEqual(outer, []);
});

test("SaladUI.command returns false when nothing matches", () => {
  document.body.innerHTML = "";
  assert.equal(SaladUI.command("#missing", "open"), false);
  assert.equal(SaladUI.command(null, "open"), false);
});
