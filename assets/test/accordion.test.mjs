import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/accordion.js"; // self-registers "accordion"
import {
  hookFor,
  installDom,
  simulatePatch,
  uninstallDom,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function itemMarkup({ value, disabled = false }) {
  return `
    <div data-part="item" data-value="${value}" data-disabled="${disabled}" data-state="closed" tabindex="-1">
      <button type="button" data-part="item-trigger" tabindex="-1" aria-expanded="false">
        <span>${value} trigger</span>
      </button>
      <div data-part="item-content" data-state="closed" hidden>
        <div>${value} content</div>
      </div>
    </div>
  `;
}

function buildAccordion({
  id = "acc-1",
  type = "single",
  value = null,
  defaultValue = null,
  disabled = false,
  animations = null,
  items = [{ value: "item-1" }, { value: "item-2" }, { value: "item-3" }],
} = {}) {
  const options = { type, value, defaultValue, disabled };
  if (animations) options.animations = animations;

  const eventMappings = { "value-changed": "handle_value_changed" };

  document.body.innerHTML = `
    <div id="${id}" data-component="accordion" data-state="idle"
         data-options='${JSON.stringify(options)}'
         data-event-mappings='${JSON.stringify(eventMappings)}'
         data-part="root">
      ${items.map(itemMarkup).join("")}
    </div>
  `;

  const el = document.getElementById(id);
  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const component = registry.create("accordion", el, hookContext);

  const getItemEls = (itemValue) => {
    const item = el.querySelector(
      `[data-part="item"][data-value="${itemValue}"]`,
    );
    return {
      item,
      trigger: item.querySelector('[data-part="item-trigger"]'),
      content: item.querySelector('[data-part="item-content"]'),
    };
  };

  return { component, el, pushed, getItemEls };
}

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
}

function keydown(el, key) {
  el.dispatchEvent(new window.KeyboardEvent("keydown", { key, bubbles: true }));
}

test("all items start closed when no value/defaultValue is provided", () => {
  const { getItemEls } = buildAccordion();

  for (const value of ["item-1", "item-2", "item-3"]) {
    const { item, content, trigger } = getItemEls(value);
    assert.equal(item.getAttribute("data-state"), "closed");
    assert.equal(content.hidden, true);
    assert.equal(trigger.getAttribute("aria-expanded"), "false");
  }
});

test("defaultValue opens the matching item immediately, synchronously, without going through an animated transition (regression)", () => {
  const { getItemEls } = buildAccordion({
    defaultValue: "item-2",
    // If the forced-select transition from Selection.initializeItem() were
    // still firing (the pre-fix behavior), this animation would delay
    // updatePartsVisibility() until its promise resolves, and the
    // assertions below (checked synchronously) would fail.
    animations: {
      closed_to_open: { animation: [[], [], []], duration: 1000 },
    },
  });

  const open = getItemEls("item-2");
  assert.equal(open.item.getAttribute("data-state"), "open");
  assert.equal(open.content.hidden, false);
  assert.equal(open.trigger.getAttribute("aria-expanded"), "true");

  const closed = getItemEls("item-1");
  assert.equal(closed.item.getAttribute("data-state"), "closed");
  assert.equal(closed.content.hidden, true);
});

test("aria-controls/aria-labelledby reference each other's real, non-empty ids for every item (regression)", () => {
  const { getItemEls } = buildAccordion({ defaultValue: "item-1" });

  for (const value of ["item-1", "item-2", "item-3"]) {
    const { trigger, content } = getItemEls(value);
    assert.ok(trigger.id, `${value} trigger should have an id`);
    assert.ok(content.id, `${value} content should have an id`);
    assert.equal(trigger.getAttribute("aria-controls"), content.id);
    assert.equal(content.getAttribute("aria-labelledby"), trigger.id);
  }
});

test("single type: clicking a trigger opens it, closes the previously open item, and pushes value-changed", () => {
  const { getItemEls, pushed } = buildAccordion({ type: "single" });

  click(getItemEls("item-1").trigger);
  assert.equal(getItemEls("item-1").item.getAttribute("data-state"), "open");
  assert.deepEqual(pushed.at(-1).payload.value, "item-1");

  click(getItemEls("item-2").trigger);
  assert.equal(getItemEls("item-1").item.getAttribute("data-state"), "closed");
  assert.equal(getItemEls("item-2").item.getAttribute("data-state"), "open");
  assert.deepEqual(pushed.at(-1).payload.value, "item-2");
});

test("single type is not collapsible: clicking the already-open item's trigger keeps it open", () => {
  const { getItemEls } = buildAccordion({
    type: "single",
    defaultValue: "item-1",
  });

  click(getItemEls("item-1").trigger);

  assert.equal(getItemEls("item-1").item.getAttribute("data-state"), "open");
});

test("multiple type: several items can be open independently and value accumulates", () => {
  const { getItemEls, pushed } = buildAccordion({ type: "multiple" });

  click(getItemEls("item-1").trigger);
  click(getItemEls("item-3").trigger);

  assert.equal(getItemEls("item-1").item.getAttribute("data-state"), "open");
  assert.equal(getItemEls("item-2").item.getAttribute("data-state"), "closed");
  assert.equal(getItemEls("item-3").item.getAttribute("data-state"), "open");
  assert.deepEqual(pushed.at(-1).payload.value.sort(), ["item-1", "item-3"]);
});

test("multiple type: pressing Enter/Space on a trigger toggles it on, not on-then-immediately-off (regression)", () => {
  // AccordionItem's "closed" and "open" states register identical
  // click/keydown handling for the trigger, so a single keypress can hit
  // both state-guarded listeners in one dispatch once the first listener's
  // synchronous transition makes the second listener's guard match too.
  const { getItemEls, pushed } = buildAccordion({ type: "multiple" });

  keydown(getItemEls("item-1").trigger, "Enter");
  assert.equal(getItemEls("item-1").item.getAttribute("data-state"), "open");
  assert.deepEqual(pushed.at(-1).payload.value, ["item-1"]);

  keydown(getItemEls("item-2").trigger, " ");
  assert.equal(getItemEls("item-2").item.getAttribute("data-state"), "open");
  assert.deepEqual(pushed.at(-1).payload.value.sort(), ["item-1", "item-2"]);
});

test("disabled item ignores clicks and keeps a non-focusable trigger", () => {
  const { getItemEls } = buildAccordion({
    items: [{ value: "item-1", disabled: true }, { value: "item-2" }],
  });

  const { trigger } = getItemEls("item-1");
  assert.equal(trigger.getAttribute("tabindex"), "-1");

  click(trigger);

  assert.equal(getItemEls("item-1").item.getAttribute("data-state"), "closed");
});

test("disabled accordion ignores clicks on every item", () => {
  const { getItemEls } = buildAccordion({ disabled: true });

  click(getItemEls("item-1").trigger);

  assert.equal(getItemEls("item-1").item.getAttribute("data-state"), "closed");
});

test("keyboard navigation: ArrowDown/ArrowUp/Home/End move focus across triggers, skipping disabled items", () => {
  const { getItemEls, el } = buildAccordion({
    items: [
      { value: "item-1" },
      { value: "item-2", disabled: true },
      { value: "item-3" },
    ],
  });

  getItemEls("item-1").trigger.focus();

  keydown(el, "ArrowDown");
  assert.equal(document.activeElement, getItemEls("item-3").trigger);

  keydown(el, "ArrowDown");
  assert.equal(document.activeElement, getItemEls("item-1").trigger);

  keydown(el, "ArrowUp");
  assert.equal(document.activeElement, getItemEls("item-3").trigger);

  keydown(el, "Home");
  assert.equal(document.activeElement, getItemEls("item-1").trigger);

  keydown(el, "End");
  assert.equal(document.activeElement, getItemEls("item-3").trigger);
});

// Items, triggers and contents get client-assigned ids, so morphdom swaps the
// items for fresh server-rendered copies on a patch.
function patch(el, options) {
  simulatePatch(el, {
    hidden: ['[data-part="item-content"]'],
    replace: ['[data-part="item"]'],
  });
  if (options) el.dataset.options = JSON.stringify(options);
}

test("a LiveView patch keeps the items opened on the client open", () => {
  const { component, el, getItemEls, pushed } = buildAccordion({
    type: "multiple",
  });
  const hook = hookFor(el, component);
  click(getItemEls("item-1").trigger);
  click(getItemEls("item-3").trigger);
  getItemEls("item-3").trigger.focus();

  hook.beforeUpdate();
  patch(el);
  hook.updated();

  assert.equal(hook.component, component);
  for (const [value, open] of [
    ["item-1", true],
    ["item-2", false],
    ["item-3", true],
  ]) {
    const { item, trigger, content } = getItemEls(value);
    assert.equal(item.dataset.state, open ? "open" : "closed", value);
    assert.equal(content.hidden, !open, value);
    assert.equal(trigger.getAttribute("aria-expanded"), String(open), value);
    assert.equal(trigger.getAttribute("aria-controls"), content.id, value);
    assert.ok(content.id, value);
  }
  // Focus moves to the replacement trigger.
  assert.equal(document.activeElement, getItemEls("item-3").trigger);
  assert.equal(pushed.length, 2);

  // The new items are wired up and report the kept values.
  click(getItemEls("item-2").trigger);
  assert.equal(getItemEls("item-2").content.hidden, false);
  assert.deepEqual(pushed.at(-1).payload.value, ["item-1", "item-3", "item-2"]);
  component.destroy();
});

test("a new server value opens exactly those items in place", () => {
  const { component, el, getItemEls, pushed } = buildAccordion({
    value: "item-1",
  });
  const hook = hookFor(el, component);

  patch(el, {
    type: "single",
    value: "item-2",
    defaultValue: null,
    disabled: false,
  });
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(getItemEls("item-1").content.hidden, true);
  assert.equal(getItemEls("item-2").content.hidden, false);
  assert.equal(pushed.length, 0);
  component.destroy();
});

test("changed accordion options rebuild it", () => {
  const { component, el } = buildAccordion();
  const hook = hookFor(el, component);

  patch(el, { type: "multiple", value: null, defaultValue: null });
  hook.updated();

  assert.notEqual(hook.component, component);
  assert.equal(component.destroyed, true);
  hook.destroyed();
});
