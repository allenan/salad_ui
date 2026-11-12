import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/select.js"; // self-registers "select"
import { installDom, setRect, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function itemMarkup({
  value,
  label = value,
  disabled = false,
  ariaDisabled = false,
  dataDisabled,
}) {
  const dataDisabledAttr =
    dataDisabled !== undefined
      ? `data-disabled="${dataDisabled}"`
      : disabled
        ? 'data-disabled="true"'
        : "";
  return `
    <div data-part="item" data-value="${value}" ${dataDisabledAttr} ${ariaDisabled ? 'aria-disabled="true"' : ""} tabindex="${disabled ? "-1" : "0"}">
      <span data-part="item-indicator" hidden></span>
      <span data-part="item-text">${label}</span>
    </div>
  `;
}

function buildSelect({
  id = "select-1",
  name = "fruit",
  multiple = false,
  value = null,
  defaultValue = null,
  items = [
    { value: "apple", label: "Apple" },
    { value: "banana", label: "Banana" },
    { value: "orange", label: "Orange" },
  ],
  inForm = false,
  extraHidden = false,
  disabled = false,
  invalid = false,
  triggerAttrs = "",
  scrollable = false,
} = {}) {
  const options = { name, multiple, value, defaultValue, usePortal: false };
  const root = `
    <div id="${id}" data-component="select" data-state="closed"
         data-disabled="${disabled}"
         ${invalid ? 'data-invalid="true"' : ""}
         data-options='${JSON.stringify(options)}'
         data-event-mappings='{"value-changed":"value_changed"}'
         data-part="root">
      <button type="button" data-part="trigger" ${disabled ? "disabled" : ""} ${triggerAttrs}>
        <span data-part="value" data-placeholder="Choose one">Choose one</span>
      </button>
      <div data-part="content" hidden>
        ${
          scrollable
            ? `<div data-part="scroll-up-button" aria-hidden="true" hidden></div>
               <div data-part="viewport">${items.map(itemMarkup).join("")}</div>
               <div data-part="scroll-down-button" aria-hidden="true" hidden></div>`
            : items.map(itemMarkup).join("")
        }
      </div>
      ${extraHidden ? '<input type="hidden" name="csrf_token" value="keep-me">' : ""}
    </div>
  `;

  document.body.innerHTML = inForm ? `<form id="form">${root}</form>` : root;

  const el = document.getElementById(id);
  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const component = registry.create("select", el, hookContext);

  return {
    component,
    el,
    form: document.getElementById("form"),
    pushed,
    trigger: el.querySelector('[data-part="trigger"]'),
    content: el.querySelector('[data-part="content"]'),
    viewport: el.querySelector('[data-part="viewport"]'),
    scrollUp: el.querySelector('[data-part="scroll-up-button"]'),
    scrollDown: el.querySelector('[data-part="scroll-down-button"]'),
    valueDisplay: el.querySelector('[data-part="value"]'),
    item: (value) =>
      el.querySelector(`[data-part="item"][data-value="${value}"]`),
    hiddenInputs: () =>
      Array.from(
        el.querySelectorAll(
          'input[type="hidden"][data-salad-ui-select-input="true"]',
        ),
      ),
  };
}

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
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

test("root data-invalid is mirrored onto the trigger as aria-invalid", () => {
  const { trigger } = buildSelect({ invalid: true });

  assert.equal(trigger.getAttribute("aria-invalid"), "true");
});

test("trigger has no aria-invalid when the root is not invalid", () => {
  const { trigger } = buildSelect();

  assert.equal(trigger.hasAttribute("aria-invalid"), false);
});

test("an explicit trigger aria-invalid wins over root data-invalid", () => {
  const { trigger } = buildSelect({
    invalid: true,
    triggerAttrs: 'aria-invalid="false"',
  });

  assert.equal(trigger.getAttribute("aria-invalid"), "false");
});

function rebuild(component, el) {
  // Simulates SaladUIHook.updated(): destroy, then rebuild on the same element.
  component.destroy();
  return registry.create("select", el, {
    pushEventTo: () => {},
    liveSocket: { execJS: () => {} },
  });
}

test("invalid -> valid on a patch removes the mirrored aria-invalid", () => {
  const { component, el, trigger } = buildSelect({ invalid: true });
  assert.equal(trigger.getAttribute("aria-invalid"), "true");

  // The patch drops the root's data-invalid but leaves the JS-added trigger
  // attributes in place.
  el.removeAttribute("data-invalid");
  rebuild(component, el);

  assert.equal(trigger.hasAttribute("aria-invalid"), false);
  assert.equal(trigger.hasAttribute("data-invalid-synced"), false);
});

test("valid -> invalid on a patch adds the mirrored aria-invalid", () => {
  const { component, el, trigger } = buildSelect();

  el.setAttribute("data-invalid", "true");
  rebuild(component, el);

  assert.equal(trigger.getAttribute("aria-invalid"), "true");
});

test("an explicit trigger aria-invalid survives a patch to a valid field", () => {
  const { component, el, trigger } = buildSelect({
    triggerAttrs: 'aria-invalid="true"',
  });

  rebuild(component, el);

  assert.equal(trigger.getAttribute("aria-invalid"), "true");
});

test("trigger carries data-placeholder only while nothing is selected", () => {
  const { trigger, item } = buildSelect();
  assert.equal(trigger.hasAttribute("data-placeholder"), true);

  click(trigger);
  click(item("banana"));

  assert.equal(trigger.hasAttribute("data-placeholder"), false);
});

test("trigger has no data-placeholder when a value is preselected", () => {
  const { trigger } = buildSelect({ value: "banana" });

  assert.equal(trigger.hasAttribute("data-placeholder"), false);
});

test("trigger keyboard opens select and focuses the selected item", () => {
  const { content, item, trigger } = buildSelect({ value: "banana" });

  keydown(trigger, "ArrowDown");

  assert.equal(content.hidden, false);
  assert.equal(document.activeElement, item("banana"));
});

test("trigger click toggles an open select closed and restores trigger focus", () => {
  const { content, trigger } = buildSelect();

  click(trigger);
  assert.equal(content.hidden, false);

  click(trigger);
  assert.equal(content.hidden, true);
  assert.equal(document.activeElement, trigger);
});

test("trigger click does nothing when select is disabled", () => {
  const { content, hiddenInputs, pushed, trigger, valueDisplay } = buildSelect({
    disabled: true,
  });

  const hiddenBefore = hiddenInputs().map((input) => [input.name, input.value]);

  click(trigger);

  assert.equal(content.hidden, true);
  assert.equal(valueDisplay.textContent, "Choose one");
  assert.deepEqual(
    hiddenInputs().map((input) => [input.name, input.value]),
    hiddenBefore,
  );
  assert.deepEqual(pushed, []);
});

test("trigger keydown does nothing when select is disabled", () => {
  const { content, trigger } = buildSelect({ disabled: true });

  keydown(trigger, "ArrowDown");

  assert.equal(content.hidden, true);
});

test("items with aria-disabled=true cannot be selected", () => {
  const { content, item, pushed, trigger, valueDisplay } = buildSelect({
    items: [
      { value: "apple", label: "Apple" },
      { value: "banana", label: "Banana", ariaDisabled: true },
      { value: "orange", label: "Orange" },
    ],
  });

  click(trigger);
  assert.equal(content.hidden, false);

  click(item("banana"));

  assert.equal(content.hidden, false);
  assert.equal(valueDisplay.textContent, "Choose one");
  assert.deepEqual(pushed, []);
});

test('items with data-disabled="false" behave as enabled', () => {
  const { item, trigger, valueDisplay } = buildSelect({
    items: [
      { value: "apple", label: "Apple" },
      { value: "banana", label: "Banana", dataDisabled: "false" },
      { value: "orange", label: "Orange" },
    ],
  });

  click(trigger);
  click(item("banana"));

  assert.equal(valueDisplay.textContent, "Banana");
});

test("arrow keys navigate and prevent page scroll when open trigger keeps focus", () => {
  const { content, item, trigger } = buildSelect();
  document.body.insertAdjacentHTML("afterbegin", '<input id="before-select">');
  const before = document.getElementById("before-select");

  before.focus();
  click(trigger);
  trigger.focus();

  const event = keydown(trigger, "ArrowDown");

  assert.equal(content.hidden, false);
  assert.equal(event.defaultPrevented, true);
  assert.equal(document.activeElement, item("banana"));
});

test("selecting an item updates readable text, hidden input, and LiveView form events", () => {
  const { form, hiddenInputs, item, pushed, valueDisplay } = buildSelect({
    inForm: true,
  });
  const events = [];
  const targets = [];
  form.addEventListener("change", (event) => {
    events.push("change");
    targets.push(event.target);
  });

  click(item("banana"));

  assert.equal(valueDisplay.textContent, "Banana");
  assert.deepEqual(
    hiddenInputs().map((input) => [input.name, input.value]),
    [["fruit", "banana"]],
  );
  assert.deepEqual(events, ["change"]);
  // LiveView only forwards phx-change when the event target is form-associated
  // (input/select/textarea/button) — dispatching from the component root breaks it.
  assert.deepEqual(targets, hiddenInputs());
  assert.equal(pushed.at(-1).event, "value_changed");
  assert.equal(pushed.at(-1).payload.value, "banana");
});

test("form change is dispatched from the server-rendered tracking input when present", () => {
  const { el, form, hiddenInputs, item } = buildSelect({ inForm: true });
  // select.ex renders this as the root's first child when a name is set.
  el.insertAdjacentHTML(
    "afterbegin",
    '<input type="text" hidden name="fruit" value="" data-salad-ui-select-tracker="true">',
  );
  const tracker = el.querySelector("[data-salad-ui-select-tracker]");
  const targets = [];
  form.addEventListener("change", (event) => targets.push(event.target));

  click(item("banana"));

  assert.deepEqual(targets, [tracker]);
  // The tracker comes first, so the selected value wins when the form is
  // serialised (Plug keeps the last value for a repeated key).
  const entries = [...new window.FormData(form).entries()];
  assert.deepEqual(entries, [
    ["fruit", ""],
    ["fruit", "banana"],
  ]);
  assert.deepEqual(
    hiddenInputs().map((input) => input.value),
    ["banana"],
  );
});

test("multiple select dispatches form change from a hidden input", () => {
  const { form, hiddenInputs, item } = buildSelect({
    inForm: true,
    multiple: true,
  });
  const targets = [];
  form.addEventListener("change", (event) => targets.push(event.target));

  click(item("banana"));

  assert.deepEqual(targets, hiddenInputs());
  assert.deepEqual(
    hiddenInputs().map((input) => [input.name, input.value]),
    [["fruit[]", "banana"]],
  );
});

test("multiple select normalizes hidden input names and highlights first selected value", () => {
  const { hiddenInputs, item, trigger } = buildSelect({
    name: "skills",
    multiple: true,
    value: ["banana", "orange"],
  });

  assert.deepEqual(
    hiddenInputs().map((input) => [input.name, input.value]),
    [
      ["skills[]", "banana"],
      ["skills[]", "orange"],
    ],
  );

  keydown(trigger, "ArrowDown");
  assert.equal(document.activeElement, item("banana"));
});

test("multiple select preserves an already-bracketed name without doubling it", () => {
  const { hiddenInputs } = buildSelect({
    name: "skills[]",
    multiple: true,
    value: ["banana", "orange"],
  });

  assert.deepEqual(
    hiddenInputs().map((input) => [input.name, input.value]),
    [
      ["skills[]", "banana"],
      ["skills[]", "orange"],
    ],
  );
});

test("hidden input sync only replaces select-owned inputs", () => {
  const { el, item } = buildSelect({ extraHidden: true });

  click(item("orange"));

  const csrf = el.querySelector('input[name="csrf_token"]');
  assert.equal(csrf?.value, "keep-me");
});

// jsdom has no layout: give the viewport a fixed scrollable box.
function makeScrollable(viewport, { scrollHeight = 300, clientHeight = 100 }) {
  Object.defineProperty(viewport, "scrollHeight", {
    value: scrollHeight,
    configurable: true,
  });
  Object.defineProperty(viewport, "clientHeight", {
    value: clientHeight,
    configurable: true,
  });
}

function pointer(el, type) {
  el.dispatchEvent(new window.Event(type, { bubbles: true }));
}

test("scroll buttons show only while the viewport can scroll that way", () => {
  const { component, trigger, viewport, scrollUp, scrollDown } = buildSelect({
    scrollable: true,
  });
  makeScrollable(viewport, { scrollHeight: 300, clientHeight: 100 });

  click(trigger);
  assert.equal(scrollUp.hidden, true);
  assert.equal(scrollDown.hidden, false);

  viewport.scrollTop = 100;
  viewport.dispatchEvent(new window.Event("scroll"));
  assert.equal(scrollUp.hidden, false);
  assert.equal(scrollDown.hidden, false);

  viewport.scrollTop = 200;
  viewport.dispatchEvent(new window.Event("scroll"));
  assert.equal(scrollUp.hidden, false);
  assert.equal(scrollDown.hidden, true);

  component.destroy();
});

test("scroll buttons stay hidden when the items fit", () => {
  const { component, trigger, viewport, scrollUp, scrollDown } = buildSelect({
    scrollable: true,
  });
  makeScrollable(viewport, { scrollHeight: 100, clientHeight: 100 });

  click(trigger);
  assert.equal(scrollUp.hidden, true);
  assert.equal(scrollDown.hidden, true);

  component.destroy();
});

test("pointing at the scroll-down button scrolls until the end, then stops", async () => {
  const { component, trigger, viewport, scrollUp, scrollDown } = buildSelect({
    scrollable: true,
  });
  makeScrollable(viewport, { scrollHeight: 300, clientHeight: 100 });

  click(trigger);
  pointer(scrollDown, "pointermove");

  // jsdom clamps nothing, so the interval must stop itself at the end.
  await waitFor(() => viewport.scrollTop >= 200);
  await waitFor(() => component.autoScrollTimer === null);
  assert.equal(scrollDown.hidden, true);
  assert.equal(scrollUp.hidden, false);

  component.destroy();
});

test("leaving a scroll button stops auto-scrolling", async () => {
  const { component, trigger, viewport, scrollUp } = buildSelect({
    scrollable: true,
  });
  makeScrollable(viewport, { scrollHeight: 300, clientHeight: 100 });

  click(trigger);
  viewport.scrollTop = 200;
  viewport.dispatchEvent(new window.Event("scroll"));

  pointer(scrollUp, "pointerdown");
  assert.notEqual(component.autoScrollTimer, null);
  pointer(scrollUp, "pointerleave");
  assert.equal(component.autoScrollTimer, null);

  component.destroy();
});

test("closing the select stops auto-scrolling", () => {
  const { component, trigger, viewport, scrollDown } = buildSelect({
    scrollable: true,
  });
  makeScrollable(viewport, { scrollHeight: 300, clientHeight: 100 });

  click(trigger);
  pointer(scrollDown, "pointerenter");
  pointer(scrollDown, "pointermove");
  assert.notEqual(component.autoScrollTimer, null);

  keydown(trigger, "Escape");
  assert.equal(component.state, "closed");
  assert.equal(component.autoScrollTimer, null);

  component.destroy();
});

const AVAILABLE_HEIGHT = "--salad-select-content-available-height";

test("content is capped at the room left on the roomier side of the trigger", () => {
  const { component, el, trigger, content } = buildSelect({
    scrollable: true,
  });
  const windowHeight = window.innerHeight;

  // Trigger near the top: the room below wins.
  setRect(el, { top: 100, bottom: 136, height: 36, left: 0, width: 200 });
  click(trigger);
  assert.equal(component.state, "open");
  assert.equal(
    content.style.getPropertyValue(AVAILABLE_HEIGHT),
    `${windowHeight - 136 - 12}px`,
  );
  keydown(trigger, "Escape");
  assert.equal(component.state, "closed");

  // Trigger near the bottom: the room above wins.
  const top = windowHeight - 60;
  setRect(el, { top, bottom: top + 36, height: 36, left: 0, width: 200 });
  click(trigger);
  assert.equal(
    content.style.getPropertyValue(AVAILABLE_HEIGHT),
    `${top - 12}px`,
  );

  component.destroy();
});

test("the cap follows the trigger when the content is repositioned", () => {
  const { component, el, trigger, content } = buildSelect({
    scrollable: true,
  });

  setRect(el, { top: 100, bottom: 136, height: 36, left: 0, width: 200 });
  click(trigger);

  // e.g. the page scrolled: ScrollManager calls update() on the element.
  const top = window.innerHeight - 200;
  setRect(el, { top, bottom: top + 36, height: 36, left: 0, width: 200 });
  component.positionedElement.update();

  assert.equal(
    content.style.getPropertyValue(AVAILABLE_HEIGHT),
    `${top - 12}px`,
  );

  component.destroy();
});
