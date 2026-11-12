import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import CommandComponent from "../salad_ui/components/command.js";
import {
  hookFor,
  installDom,
  simulatePatch,
  uninstallDom,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function buildCommand({ includeInput = true, includeEmpty = true } = {}) {
  document.body.innerHTML = `
    <div id="command" data-component="command" data-part="root">
      ${includeInput ? '<input data-part="input" />' : ""}
      ${includeEmpty ? '<div data-part="empty" data-visible="false">No results</div>' : ""}
      <div data-part="list" role="listbox">
        <div data-part="group">
          <button data-part="item">Calendar</button>
          <button data-part="item" disabled>Disabled</button>
        </div>
      </div>
    </div>
  `;

  const el = document.getElementById("command");
  const component = new CommandComponent(el, null);
  component.setupEvents();

  return {
    component,
    el,
    input: el.querySelector('[data-part="input"]'),
    empty: el.querySelector('[data-part="empty"]'),
    items: [...el.querySelectorAll('[data-part="item"]')],
  };
}

test("constructor tolerates missing optional input and empty parts", () => {
  const { component, items } = buildCommand({
    includeInput: false,
    includeEmpty: false,
  });

  assert.equal(items[0].getAttribute("data-selected"), "true");

  component.destroy();
});

test("search clears selection when no enabled item matches", () => {
  const { component, el, input, empty, items } = buildCommand();
  let clicks = 0;
  items[0].addEventListener("click", () => clicks++);

  input.value = "missing";
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
  const event = new window.KeyboardEvent("keydown", {
    key: "Enter",
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);

  assert.equal(component.currentItemIdx, -1);
  assert.equal(items[0].getAttribute("data-selected"), "false");
  assert.equal(empty.getAttribute("data-visible"), "true");
  assert.equal(clicks, 0);
  assert.equal(event.defaultPrevented, true);

  component.destroy();
});

test("Enter selects current item and prevents parent form submit", () => {
  const { component, el, items } = buildCommand();
  let clicks = 0;
  items[0].addEventListener("click", () => clicks++);

  const event = new window.KeyboardEvent("keydown", {
    key: "Enter",
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);

  assert.equal(clicks, 1);
  assert.equal(event.defaultPrevented, true);

  component.destroy();
});

test("separators hide while a search query is active", () => {
  document.body.innerHTML = `
    <div id="command" data-component="command" data-part="root">
      <input data-part="input" />
      <div data-part="list" role="listbox">
        <div data-part="group"><button data-part="item">Calendar</button></div>
        <div data-part="separator" id="sep"></div>
        <div data-part="separator" id="sep-always" data-always-render="true"></div>
        <div data-part="group"><button data-part="item">Profile</button></div>
      </div>
    </div>
  `;
  const el = document.getElementById("command");
  const component = new CommandComponent(el, null);
  component.setupEvents();
  const input = el.querySelector('[data-part="input"]');
  const sep = document.getElementById("sep");
  const always = document.getElementById("sep-always");

  assert.equal(sep.getAttribute("data-visible"), "true");

  input.value = "cal";
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
  assert.equal(sep.getAttribute("data-visible"), "false");
  assert.equal(always.getAttribute("data-visible"), "true");

  input.value = "";
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
  assert.equal(sep.getAttribute("data-visible"), "true");

  component.destroy();
});

test("a LiveView patch keeps the filter and the highlighted item", () => {
  document.body.innerHTML = `
    <div id="palette" data-component="command" data-part="root"
         data-event-mappings="{}">
      <input data-part="input" />
      <div data-part="empty" data-visible="false">No results</div>
      <div data-part="list">
        <div data-part="group" id="suggestions">
          <button data-part="item">Calendar</button>
          <button data-part="item">Calculator</button>
          <button data-part="item">Search Emoji</button>
        </div>
        <div data-part="separator"></div>
        <div data-part="group" id="settings">
          <button data-part="item">Profile</button>
        </div>
      </div>
    </div>
  `;
  const el = document.getElementById("palette");
  const component = new CommandComponent(el, null);
  component.setupEvents();
  const hook = hookFor(el, component);
  const input = el.querySelector('[data-part="input"]');
  const [calendar, calculator, emoji, profile] =
    el.querySelectorAll('[data-part="item"]');

  input.value = "calc";
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
  input.value = "ca";
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
  el.dispatchEvent(
    new window.KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }),
  );
  assert.equal(calculator.dataset.selected, "true");

  // The server markup has every item visible and none selected; LiveView
  // leaves the focused input's value alone and may add items.
  simulatePatch(el, { keepIds: ["palette", "suggestions", "settings"] });
  el.querySelectorAll("[data-visible]").forEach((node) => {
    node.dataset.visible = "true";
  });
  el.querySelectorAll('[data-part="item"]').forEach((item) => {
    item.dataset.selected = "false";
  });
  el.querySelector('[data-part="empty"]').dataset.visible = "false";
  document
    .getElementById("suggestions")
    .insertAdjacentHTML(
      "afterbegin",
      '<button data-part="item" id="cart">Cart</button>',
    );
  hook.updated();

  const cart = document.getElementById("cart");
  assert.equal(hook.component, component);
  assert.equal(emoji.dataset.visible, "false");
  assert.equal(profile.dataset.visible, "false");
  assert.equal(document.getElementById("settings").dataset.visible, "false");
  assert.equal(
    el.querySelector('[data-part="separator"]').dataset.visible,
    "false",
  );
  assert.equal(cart.dataset.visible, "true");
  assert.equal(calculator.dataset.selected, "true");
  assert.equal(calendar.dataset.selected, "false");

  // The new item takes part in navigation and filtering.
  el.dispatchEvent(
    new window.KeyboardEvent("keydown", { key: "ArrowUp", bubbles: true }),
  );
  assert.equal(calendar.dataset.selected, "true");
  input.value = "cart";
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
  assert.equal(cart.dataset.selected, "true");
  assert.equal(calendar.dataset.visible, "false");

  component.destroy();
});

test("changed command options rebuild it", () => {
  const { component, el } = buildCommand();
  const hook = hookFor(el, component);

  el.dataset.options = JSON.stringify({ loop: true });
  hook.updated();

  assert.notEqual(hook.component, component);
  assert.equal(component.destroyed, true);
  hook.destroyed();
});
