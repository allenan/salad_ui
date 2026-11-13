import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/toggle.js";
import { installDom, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function buildToggle({ pressed = false, disabled = false } = {}) {
  document.body.innerHTML = `
    <form>
      <button id="toggle-1" type="button" data-component="toggle" data-part="root"
              data-state="${pressed ? "on" : "off"}" aria-pressed="${pressed}"
              data-event-mappings='${JSON.stringify({ "pressed-changed": "bold_changed" })}'
              ${disabled ? "disabled data-disabled" : ""}>
        <input type="hidden" name="bold" value="false">
        <input type="checkbox" class="hidden" name="bold" value="true"${pressed ? " checked" : ""} tabindex="-1">
        B
      </button>
    </form>
  `;

  const el = document.getElementById("toggle-1");
  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const component = registry.create("toggle", el, hookContext);
  const input = el.querySelector('input[type="checkbox"]');

  return { component, el, input, pushed };
}

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
}

test("mounts in the server-rendered state", () => {
  const { el, component } = buildToggle({ pressed: true });

  assert.equal(component.state, "on");
  assert.equal(el.getAttribute("data-state"), "on");
  assert.equal(el.getAttribute("aria-pressed"), "true");
});

test("click toggles data-state, aria-pressed and the checkbox", () => {
  const { el, input, pushed } = buildToggle();
  let changes = 0;
  el.closest("form").addEventListener("change", () => changes++);

  click(el);

  assert.equal(el.getAttribute("data-state"), "on");
  assert.equal(el.getAttribute("aria-pressed"), "true");
  assert.equal(input.checked, true);
  assert.equal(changes, 1);
  assert.deepEqual(pushed.at(-1), {
    target: el,
    event: "bold_changed",
    payload: { pressed: true, componentId: "toggle-1", component: "toggle" },
  });

  click(el);

  assert.equal(el.getAttribute("data-state"), "off");
  assert.equal(el.getAttribute("aria-pressed"), "false");
  assert.equal(input.checked, false);
  assert.equal(pushed.at(-1).payload.pressed, false);
});

test("disabled toggles ignore clicks", () => {
  const { el, pushed } = buildToggle({ disabled: true });

  click(el);

  assert.equal(el.getAttribute("data-state"), "off");
  assert.equal(pushed.length, 0);
});

test("on/off/toggle commands", () => {
  const { el, component } = buildToggle();

  component.handleCommand("on");
  assert.equal(el.getAttribute("data-state"), "on");

  component.handleCommand("on");
  assert.equal(el.getAttribute("data-state"), "on");

  component.handleCommand("toggle");
  assert.equal(el.getAttribute("data-state"), "off");
});

test("destroy removes the click listener", () => {
  const { el, component } = buildToggle();

  component.destroy();
  click(el);

  assert.equal(el.getAttribute("data-state"), "off");
});

// What a LiveView patch does to the toggle: it re-applies the server render.
function patchFromServer(el, pressed) {
  el.setAttribute("data-state", pressed ? "on" : "off");
  el.setAttribute("aria-pressed", String(pressed));
  el.querySelector('input[type="checkbox"]').checked = pressed;
}

test("a patch that re-renders the same server state keeps the user's click", () => {
  const { el, input, component } = buildToggle();

  click(el);
  patchFromServer(el, false);

  assert.equal(component.skipReinitialize(el), true);
  assert.equal(el.getAttribute("data-state"), "on");
  assert.equal(el.getAttribute("aria-pressed"), "true");
  assert.equal(input.checked, true);
});

test("a patch with a new server state rebuilds the toggle", () => {
  const { el, component } = buildToggle();

  patchFromServer(el, true);

  assert.equal(component.skipReinitialize(el), false);
});
