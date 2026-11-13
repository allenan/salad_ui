import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/toggle_group.js";
import { installDom, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function itemMarkup({ value, pressed = false, disabled = false }, type) {
  const aria =
    type === "single"
      ? `role="radio" aria-checked="${pressed}"`
      : `aria-pressed="${pressed}"`;
  const input = type === "single" ? "radio" : "checkbox";

  return `<button type="button" data-part="item" data-slot="toggle-group-item" data-value="${value}" data-state="${pressed ? "on" : "off"}" ${aria}${disabled ? " disabled data-disabled" : ""}>
    <input type="${input}" class="hidden" name="style" value="${value}"${pressed ? " checked" : ""} tabindex="-1">${value}
  </button>`;
}

function buildGroup({
  id = "group-1",
  type = "single",
  orientation = "horizontal",
  loop = true,
  dir,
  items = [{ value: "bold" }, { value: "italic" }, { value: "underline" }],
} = {}) {
  const options = { type, orientation, loop, disabled: false };
  const eventMappings = { "value-changed": "style_changed" };

  document.body.innerHTML = `
    <div ${dir ? `dir="${dir}"` : ""}>
      <div id="${id}" role="group" data-component="toggle-group" data-part="root" data-state="idle"
           data-orientation="${orientation}"
           data-options='${JSON.stringify(options)}'
           data-event-mappings='${JSON.stringify(eventMappings)}'>
        ${items.map((item) => itemMarkup(item, type)).join("")}
      </div>
    </div>
  `;

  const el = document.getElementById(id);
  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const component = registry.create("toggle-group", el, hookContext);
  const getItem = (value) =>
    el.querySelector(`[data-part="item"][data-value="${value}"]`);

  return { component, el, pushed, getItem };
}

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
}

function keydown(el, key) {
  const event = new window.KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);
  return event;
}

function tabIndexes(el) {
  return Array.from(el.querySelectorAll('[data-part="item"]')).map(
    (item) => item.tabIndex,
  );
}

test("the first pressed item is the tab stop", () => {
  const { el } = buildGroup({
    items: [{ value: "bold" }, { value: "italic", pressed: true }],
  });

  assert.deepEqual(tabIndexes(el), [-1, 0]);
});

test("the first enabled item is the tab stop when none is pressed", () => {
  const { el } = buildGroup({
    items: [{ value: "bold", disabled: true }, { value: "italic" }],
  });

  assert.deepEqual(tabIndexes(el), [-1, 0]);
});

test("single: clicking presses one item and releases the others", () => {
  const { getItem, pushed } = buildGroup({
    items: [{ value: "bold", pressed: true }, { value: "italic" }],
  });

  click(getItem("italic"));

  assert.equal(getItem("italic").getAttribute("data-state"), "on");
  assert.equal(getItem("italic").getAttribute("aria-checked"), "true");
  assert.equal(getItem("italic").querySelector("input").checked, true);
  assert.equal(getItem("bold").getAttribute("data-state"), "off");
  assert.equal(getItem("bold").getAttribute("aria-checked"), "false");
  assert.equal(getItem("bold").querySelector("input").checked, false);
  assert.deepEqual(pushed.at(-1).payload.value, "italic");
  assert.equal(pushed.at(-1).event, "style_changed");
});

test("single: clicking the pressed item releases it", () => {
  const { getItem, pushed } = buildGroup({
    items: [{ value: "bold", pressed: true }, { value: "italic" }],
  });

  click(getItem("bold"));

  assert.equal(getItem("bold").getAttribute("data-state"), "off");
  assert.equal(pushed.at(-1).payload.value, "");
});

test("multiple: items toggle independently with aria-pressed", () => {
  const { getItem, pushed } = buildGroup({ type: "multiple" });

  click(getItem("bold"));
  click(getItem("underline"));

  assert.equal(getItem("bold").getAttribute("aria-pressed"), "true");
  assert.equal(getItem("underline").getAttribute("aria-pressed"), "true");
  assert.equal(getItem("italic").getAttribute("aria-pressed"), "false");
  assert.deepEqual(pushed.at(-1).payload.value, ["bold", "underline"]);

  click(getItem("bold"));
  assert.equal(getItem("bold").getAttribute("data-state"), "off");
  assert.equal(getItem("bold").querySelector("input").checked, false);
  assert.deepEqual(pushed.at(-1).payload.value, ["underline"]);
});

test("clicking an item fires a bubbling change event for forms", () => {
  const { el, getItem } = buildGroup({ type: "multiple" });
  let changes = 0;
  el.parentElement.addEventListener("change", () => changes++);

  click(getItem("italic"));

  assert.equal(changes, 1);
});

test("disabled items ignore clicks", () => {
  const { getItem, pushed } = buildGroup({
    type: "multiple",
    items: [{ value: "bold", disabled: true }, { value: "italic" }],
  });

  click(getItem("bold"));

  assert.equal(getItem("bold").getAttribute("data-state"), "off");
  assert.equal(pushed.length, 0);
});

test("horizontal: ArrowRight/ArrowLeft move focus and the tab stop without toggling", () => {
  const { el, getItem } = buildGroup();
  getItem("bold").focus();

  const event = keydown(getItem("bold"), "ArrowRight");
  assert.equal(event.defaultPrevented, true);
  assert.equal(document.activeElement, getItem("italic"));
  assert.deepEqual(tabIndexes(el), [-1, 0, -1]);
  assert.equal(getItem("italic").getAttribute("data-state"), "off");

  keydown(getItem("italic"), "ArrowLeft");
  assert.equal(document.activeElement, getItem("bold"));
});

test("horizontal: ArrowUp/ArrowDown do nothing", () => {
  const { getItem } = buildGroup();
  getItem("bold").focus();

  const event = keydown(getItem("bold"), "ArrowDown");

  assert.equal(event.defaultPrevented, false);
  assert.equal(document.activeElement, getItem("bold"));
});

test("focus loops around by default", () => {
  const { getItem } = buildGroup();
  getItem("underline").focus();

  keydown(getItem("underline"), "ArrowRight");
  assert.equal(document.activeElement, getItem("bold"));

  keydown(getItem("bold"), "ArrowLeft");
  assert.equal(document.activeElement, getItem("underline"));
});

test("loop: false stops at the ends", () => {
  const { getItem } = buildGroup({ loop: false });
  getItem("underline").focus();

  keydown(getItem("underline"), "ArrowRight");
  assert.equal(document.activeElement, getItem("underline"));

  getItem("bold").focus();
  keydown(getItem("bold"), "ArrowLeft");
  assert.equal(document.activeElement, getItem("bold"));
});

test("Home/End jump to the first and last enabled items", () => {
  const { getItem } = buildGroup({
    items: [
      { value: "bold" },
      { value: "italic" },
      { value: "underline", disabled: true },
    ],
  });
  getItem("bold").focus();

  keydown(getItem("bold"), "End");
  assert.equal(document.activeElement, getItem("italic"));

  keydown(getItem("italic"), "Home");
  assert.equal(document.activeElement, getItem("bold"));
});

test("arrow keys skip disabled items", () => {
  const { getItem } = buildGroup({
    items: [
      { value: "bold" },
      { value: "italic", disabled: true },
      { value: "underline" },
    ],
  });
  getItem("bold").focus();

  keydown(getItem("bold"), "ArrowRight");

  assert.equal(document.activeElement, getItem("underline"));
});

test("RTL mirrors ArrowLeft/ArrowRight", () => {
  const { getItem } = buildGroup({ dir: "rtl" });
  getItem("bold").focus();

  keydown(getItem("bold"), "ArrowLeft");
  assert.equal(document.activeElement, getItem("italic"));

  keydown(getItem("italic"), "ArrowRight");
  assert.equal(document.activeElement, getItem("bold"));
});

test("vertical: ArrowDown/ArrowUp move focus, ArrowLeft/ArrowRight do nothing", () => {
  const { getItem } = buildGroup({ orientation: "vertical" });
  getItem("bold").focus();

  keydown(getItem("bold"), "ArrowDown");
  assert.equal(document.activeElement, getItem("italic"));

  keydown(getItem("italic"), "ArrowUp");
  assert.equal(document.activeElement, getItem("bold"));

  const event = keydown(getItem("bold"), "ArrowRight");
  assert.equal(event.defaultPrevented, false);
  assert.equal(document.activeElement, getItem("bold"));
});

test("focusing an item makes it the tab stop", () => {
  const { el, getItem } = buildGroup();

  getItem("underline").focus();

  assert.deepEqual(tabIndexes(el), [-1, -1, 0]);
});

test("ignores items of a nested toggle group", () => {
  const { component } = buildGroup();
  const nested = document.createElement("div");
  nested.setAttribute("data-component", "toggle-group");
  nested.innerHTML = '<button data-part="item" data-value="x"></button>';
  component.el.appendChild(nested);

  assert.equal(component.getItems().length, 3);
});

test("destroy removes the click listener", () => {
  const { component, getItem, pushed } = buildGroup();
  const item = getItem("bold");

  component.destroy();
  click(item);

  assert.equal(item.getAttribute("data-state"), "off");
  assert.equal(pushed.length, 0);
});

// What a LiveView patch does to the items: it re-applies the server render
// (pressed state, aria, inputs) and drops the client-only tabindex.
function patchFromServer(el, pressedValues, type = "single") {
  el.querySelectorAll('[data-part="item"]').forEach((item) => {
    const pressed = pressedValues.includes(item.getAttribute("data-value"));
    item.setAttribute("data-state", pressed ? "on" : "off");
    item.setAttribute(
      type === "single" ? "aria-checked" : "aria-pressed",
      String(pressed),
    );
    item.querySelector("input").checked = pressed;
    item.removeAttribute("tabindex");
  });
}

test("a patch that re-renders the same server value keeps the user's choice", () => {
  const { el, component, getItem } = buildGroup({
    type: "multiple",
    items: [{ value: "bold", pressed: true }, { value: "italic" }],
  });

  click(getItem("italic"));
  patchFromServer(el, ["bold"], "multiple");

  assert.equal(component.skipReinitialize(el), true);
  assert.equal(getItem("italic").getAttribute("data-state"), "on");
  assert.equal(getItem("italic").getAttribute("aria-pressed"), "true");
  assert.equal(getItem("italic").querySelector("input").checked, true);
  assert.equal(getItem("bold").getAttribute("data-state"), "on");
  assert.deepEqual(tabIndexes(el), [-1, 0]);
});

test("a single group keeps a released item released across a patch", () => {
  const { el, component, getItem } = buildGroup({
    items: [{ value: "bold", pressed: true }, { value: "italic" }],
  });

  click(getItem("bold"));
  patchFromServer(el, ["bold"]);

  assert.equal(component.skipReinitialize(el), true);
  assert.equal(getItem("bold").getAttribute("data-state"), "off");
  assert.equal(getItem("bold").getAttribute("aria-checked"), "false");
  assert.equal(getItem("bold").querySelector("input").checked, false);
});

test("a patch with a new server value rebuilds from the server", () => {
  const { el, component, getItem } = buildGroup();

  click(getItem("bold"));
  patchFromServer(el, ["italic"]);

  assert.equal(component.skipReinitialize(el), false);
});

test("a patch with new options rebuilds even if the value is the same", () => {
  const { el, component } = buildGroup();

  el.setAttribute(
    "data-options",
    JSON.stringify({ type: "single", orientation: "vertical", loop: true }),
  );

  assert.equal(component.skipReinitialize(el), false);
});

test("arrow keys from a nested toggle group do not move the outer focus", () => {
  const { el } = buildGroup();
  const nested = document.createElement("div");
  nested.id = "nested";
  nested.setAttribute("data-component", "toggle-group");
  nested.setAttribute("data-part", "root");
  nested.setAttribute("data-state", "idle");
  nested.setAttribute(
    "data-options",
    JSON.stringify({ type: "single", orientation: "horizontal", loop: true }),
  );
  nested.innerHTML = `
    <button type="button" data-part="item" data-value="x" data-state="off">x</button>
    <button type="button" data-part="item" data-value="y" data-state="off">y</button>`;
  el.appendChild(nested);
  registry.create("toggle-group", nested, {});

  const x = nested.querySelector('[data-value="x"]');
  const y = nested.querySelector('[data-value="y"]');
  x.focus();
  keydown(x, "ArrowRight");

  assert.equal(document.activeElement, y);
  assert.deepEqual(tabIndexes(el).slice(0, 3), [0, -1, -1]);
});
