import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/tabs.js";
import {
  hookFor,
  installDom,
  simulatePatch,
  uninstallDom,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function triggerMarkup({ value, disabled = false }) {
  return `<button type="button" data-part="trigger" data-value="${value}" data-state="inactive" data-disabled="${disabled}"${disabled ? " disabled" : ""}>${value}</button>`;
}

function contentMarkup({ value }) {
  return `<div data-part="content" data-value="${value}" data-state="inactive" hidden>${value} content</div>`;
}

function buildTabs({
  id = "tabs-1",
  value = null,
  defaultValue = null,
  items = [{ value: "account" }, { value: "password" }, { value: "billing" }],
  orientation,
} = {}) {
  const options = { value, defaultValue, orientation };
  const eventMappings = { "tab-changed": "tab_changed" };

  document.body.innerHTML = `
    <div id="${id}" data-component="tabs" data-state="idle"
         data-options='${JSON.stringify(options)}'
         data-event-mappings='${JSON.stringify(eventMappings)}'
         data-part="root">
      <div data-part="list">
        ${items.map(triggerMarkup).join("")}
      </div>
      ${items.map(contentMarkup).join("")}
    </div>
  `;

  const el = document.getElementById(id);
  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const component = registry.create("tabs", el, hookContext);

  const getTrigger = (itemValue) =>
    el.querySelector(`[data-part="trigger"][data-value="${itemValue}"]`);
  const getContent = (itemValue) =>
    el.querySelector(`[data-part="content"][data-value="${itemValue}"]`);

  const list = el.querySelector('[data-part="list"]');

  return { component, el, list, pushed, getTrigger, getContent };
}

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
}

function keydown(el, key) {
  el.dispatchEvent(new window.KeyboardEvent("keydown", { key, bubbles: true }));
}

test("defaultValue selects matching tab on mount", () => {
  const { getTrigger, getContent } = buildTabs({ defaultValue: "password" });

  assert.equal(getTrigger("password").getAttribute("data-state"), "active");
  assert.equal(getTrigger("password").getAttribute("aria-selected"), "true");
  assert.equal(getTrigger("password").tabIndex, 0);
  assert.equal(getContent("password").hidden, false);

  assert.equal(getTrigger("account").getAttribute("data-state"), "inactive");
  assert.equal(getContent("account").hidden, true);
});

test("controlled value wins over defaultValue on mount", () => {
  const { getTrigger, getContent } = buildTabs({
    value: "billing",
    defaultValue: "account",
  });

  assert.equal(getTrigger("billing").getAttribute("data-state"), "active");
  assert.equal(getContent("billing").hidden, false);
  assert.equal(getTrigger("account").getAttribute("data-state"), "inactive");
});

test("invalid or disabled selected value falls back to first enabled tab", () => {
  const { getTrigger, getContent } = buildTabs({
    value: "missing",
    items: [
      { value: "disabled", disabled: true },
      { value: "account" },
      { value: "password" },
    ],
  });

  assert.equal(getTrigger("disabled").getAttribute("data-state"), "inactive");
  assert.equal(getTrigger("disabled").tabIndex, -1);
  assert.equal(getContent("disabled").hidden, true);

  assert.equal(getTrigger("account").getAttribute("data-state"), "active");
  assert.equal(getTrigger("account").tabIndex, 0);
  assert.equal(getContent("account").hidden, false);
});

test("clicking a trigger selects it and pushes tab-changed", () => {
  const { getTrigger, getContent, pushed } = buildTabs({
    defaultValue: "account",
  });

  click(getTrigger("password"));

  assert.equal(getTrigger("password").getAttribute("data-state"), "active");
  assert.equal(getContent("password").hidden, false);
  assert.equal(getTrigger("account").getAttribute("data-state"), "inactive");

  assert.equal(pushed.at(-1).event, "tab_changed");
  assert.deepEqual(pushed.at(-1).payload, {
    value: "password",
    tab: "password",
    componentId: "tabs-1",
    component: "tabs",
  });
});

test("keyboard navigation selects next enabled tab and skips disabled tabs", () => {
  const { getTrigger, getContent } = buildTabs({
    defaultValue: "account",
    items: [
      { value: "account" },
      { value: "disabled", disabled: true },
      { value: "password" },
    ],
  });

  getTrigger("account").focus();
  keydown(getTrigger("account"), "ArrowRight");

  assert.equal(document.activeElement, getTrigger("password"));
  assert.equal(getTrigger("password").getAttribute("data-state"), "active");
  assert.equal(getContent("password").hidden, false);
});

test("horizontal tabs use Left/Right and ignore Up/Down", () => {
  const { list, getTrigger } = buildTabs({ defaultValue: "account" });

  assert.equal(list.getAttribute("aria-orientation"), "horizontal");

  getTrigger("account").focus();
  keydown(getTrigger("account"), "ArrowDown");
  assert.equal(getTrigger("account").getAttribute("data-state"), "active");

  keydown(getTrigger("account"), "ArrowRight");
  assert.equal(getTrigger("password").getAttribute("data-state"), "active");
});

test("vertical tabs use Up/Down, ignore Left/Right and set aria-orientation", () => {
  const { list, getTrigger, getContent } = buildTabs({
    defaultValue: "account",
    orientation: "vertical",
  });

  assert.equal(list.getAttribute("aria-orientation"), "vertical");

  getTrigger("account").focus();
  const ignored = new window.KeyboardEvent("keydown", {
    key: "ArrowRight",
    bubbles: true,
    cancelable: true,
  });
  getTrigger("account").dispatchEvent(ignored);
  assert.equal(ignored.defaultPrevented, false);
  assert.equal(getTrigger("account").getAttribute("data-state"), "active");

  const down = new window.KeyboardEvent("keydown", {
    key: "ArrowDown",
    bubbles: true,
    cancelable: true,
  });
  getTrigger("account").dispatchEvent(down);
  assert.equal(down.defaultPrevented, true);
  assert.equal(document.activeElement, getTrigger("password"));
  assert.equal(getContent("password").hidden, false);

  keydown(getTrigger("password"), "ArrowUp");
  assert.equal(document.activeElement, getTrigger("account"));
  assert.equal(getTrigger("account").getAttribute("data-state"), "active");
});

// Triggers and panels get client-assigned ids, so morphdom swaps them for
// fresh server-rendered copies on a patch.
function patch(el, options) {
  simulatePatch(el, {
    hidden: ['[data-part="content"]'],
    replace: ['[data-part="trigger"]', '[data-part="content"]'],
  });
  if (options) el.dataset.options = JSON.stringify(options);
}

test("a LiveView patch keeps the tab chosen on the client", () => {
  const { component, el, getTrigger, getContent, pushed } = buildTabs({
    defaultValue: "account",
  });
  const hook = hookFor(el, component);
  click(getTrigger("password"));
  assert.equal(document.activeElement, getTrigger("password"));

  hook.beforeUpdate();
  patch(el);
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(getTrigger("password").getAttribute("data-state"), "active");
  assert.equal(getTrigger("password").getAttribute("aria-selected"), "true");
  assert.equal(getTrigger("password").getAttribute("role"), "tab");
  assert.equal(getTrigger("password").id, "tabs-1-trigger-password");
  assert.equal(getContent("password").hidden, false);
  assert.equal(getContent("account").hidden, true);
  assert.equal(
    getContent("password").getAttribute("aria-labelledby"),
    "tabs-1-trigger-password",
  );
  // Focus moves to the replacement trigger.
  assert.equal(document.activeElement, getTrigger("password"));
  assert.equal(pushed.length, 1);

  // The new triggers are wired up.
  click(getTrigger("billing"));
  assert.equal(getContent("billing").hidden, false);
  keydown(el.querySelector('[data-part="list"]'), "Home");
  assert.equal(getContent("account").hidden, false);
  component.destroy();
});

test("a new server value selects that tab in place", () => {
  const { component, el, getContent, pushed } = buildTabs({
    value: "account",
  });
  const hook = hookFor(el, component);

  patch(el, { value: "billing", defaultValue: null });
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(getContent("billing").hidden, false);
  assert.equal(getContent("account").hidden, true);
  assert.equal(pushed.length, 0);
  component.destroy();
});

test("changed tabs options rebuild them", () => {
  const { component, el } = buildTabs();
  const hook = hookFor(el, component);

  patch(el, { value: null, defaultValue: null, orientation: "vertical" });
  hook.updated();

  assert.notEqual(hook.component, component);
  assert.equal(component.destroyed, true);
  hook.destroyed();
});
