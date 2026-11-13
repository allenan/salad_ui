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

function triggerMarkup({ value, disabled = false, id }) {
  return `<button type="button"${id ? ` id="${id}"` : ""} data-part="trigger" data-value="${value}" data-state="inactive" data-disabled="${disabled}"${disabled ? " disabled" : ""}>${value}</button>`;
}

function contentMarkup({ value, contentId }) {
  return `<div${contentId ? ` id="${contentId}"` : ""} data-part="content" data-value="${value}" data-state="inactive" hidden>${value} content</div>`;
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

// Re-render from the server markup, which renders no ids below the root.
// `replace` swaps the matched elements for fresh copies, as when the server
// re-renders them under new keys.
function patch(el, options, { replace = [] } = {}) {
  simulatePatch(el, { hidden: ['[data-part="content"]'], replace });
  if (options) el.dataset.options = JSON.stringify(options);
}

test("a LiveView patch keeps the tab chosen on the client", () => {
  const { component, el, getTrigger, getContent, pushed } = buildTabs({
    defaultValue: "account",
  });
  const hook = hookFor(el, component);
  click(getTrigger("password"));
  const trigger = getTrigger("password");
  const panel = getContent("password");
  assert.equal(document.activeElement, trigger);

  hook.beforeUpdate();
  patch(el);
  hook.updated();

  assert.equal(hook.component, component);
  // The client ids were dropped before the patch, so the triggers and
  // panels were patched in place rather than replaced.
  assert.equal(getTrigger("password"), trigger);
  assert.equal(getContent("password"), panel);
  assert.equal(trigger.getAttribute("data-state"), "active");
  assert.equal(trigger.getAttribute("aria-selected"), "true");
  assert.equal(trigger.getAttribute("role"), "tab");
  assert.equal(trigger.id, "tabs-1-trigger-password");
  assert.equal(trigger.getAttribute("aria-controls"), panel.id);
  assert.equal(panel.getAttribute("aria-labelledby"), trigger.id);
  assert.equal(panel.hidden, false);
  assert.equal(getContent("account").hidden, true);
  assert.equal(document.activeElement, trigger);
  assert.equal(pushed.length, 1);

  // Still wired up.
  click(getTrigger("billing"));
  assert.equal(getContent("billing").hidden, false);
  keydown(el.querySelector('[data-part="list"]'), "Home");
  assert.equal(getContent("account").hidden, false);
  component.destroy();
});

test("a field focused in a tab panel keeps focus across a patch", () => {
  const { component, el, getContent } = buildTabs({ defaultValue: "account" });
  const hook = hookFor(el, component);
  const field = document.createElement("input");
  getContent("account").append(field);
  field.focus();

  // e.g. the phx-change round trip of a form in the panel.
  hook.beforeUpdate();
  patch(el);
  hook.updated();

  assert.equal(field.isConnected, true);
  assert.equal(document.activeElement, field);
  assert.equal(getContent("account").hidden, false);
  component.destroy();
});

test("server-rendered tab ids are kept and linked", () => {
  const { component, getTrigger, getContent } = buildTabs({
    defaultValue: "account",
    items: [{ value: "account", id: "acct-tab", contentId: "acct-panel" }],
  });

  assert.equal(getTrigger("account").id, "acct-tab");
  assert.equal(
    getTrigger("account").getAttribute("aria-controls"),
    "acct-panel",
  );
  assert.equal(
    getContent("account").getAttribute("aria-labelledby"),
    "acct-tab",
  );
  component.destroy();
});

test("a trigger the server replaces gets the state and keeps focus", () => {
  const { component, el, getTrigger, getContent } = buildTabs({
    defaultValue: "account",
  });
  const hook = hookFor(el, component);
  click(getTrigger("password"));
  const trigger = getTrigger("password");

  hook.beforeUpdate();
  patch(el, null, { replace: ['[data-part="trigger"]'] });
  hook.updated();

  assert.notEqual(getTrigger("password"), trigger);
  assert.equal(getTrigger("password").getAttribute("aria-selected"), "true");
  assert.equal(getContent("password").hidden, false);
  assert.equal(document.activeElement, getTrigger("password"));
  // The replacement triggers are wired up.
  click(getTrigger("billing"));
  assert.equal(getContent("billing").hidden, false);
  component.destroy();
});

test("a new server value selects that tab in place", () => {
  const { component, el, getContent, pushed } = buildTabs({
    value: "account",
  });
  const hook = hookFor(el, component);

  hook.beforeUpdate();
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
