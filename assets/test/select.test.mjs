import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
// Self-registers "select".
import { itemAlignedPosition } from "../salad_ui/components/select.js";
import {
  hookFor,
  installDom,
  setRect,
  simulatePatch,
  uninstallDom,
  waitFor,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function itemMarkup({
  value,
  label = value,
  disabled = false,
  ariaDisabled = false,
  dataDisabled,
  textValue,
}) {
  const textValueAttr =
    textValue !== undefined ? `data-text-value="${textValue}"` : "";
  const dataDisabledAttr =
    dataDisabled !== undefined
      ? `data-disabled="${dataDisabled}"`
      : disabled
        ? 'data-disabled="true"'
        : "";
  return `
    <div data-part="item" data-value="${value}" ${dataDisabledAttr} ${textValueAttr}${ariaDisabled ? 'aria-disabled="true"' : ""} tabindex="${disabled ? "-1" : "0"}">
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
  triggerDisabled = disabled,
  optionsDisabled = false,
  contentAttrs = "",
  tracker = null,
  scrollable = false,
  eventMappings = { "value-changed": "value_changed" },
  usePortal = false,
} = {}) {
  const options = {
    name,
    multiple,
    value,
    defaultValue,
    disabled: optionsDisabled,
    usePortal,
  };
  // What select.ex renders as the root's first child when a name is set.
  const trackerMarkup = tracker
    ? `<input type="text" hidden name="${tracker.name}" value="" ${tracker.disabled ? "disabled" : ""} data-salad-ui-select-tracker="true">`
    : "";
  const root = `
    <div id="${id}" data-component="select" data-state="closed"
         data-disabled="${disabled}"
         ${invalid ? 'data-invalid="true"' : ""}
         data-options='${JSON.stringify(options)}'
         data-event-mappings='${JSON.stringify(eventMappings)}'
         data-part="root">
      ${trackerMarkup}
      <button type="button" data-part="trigger" ${triggerDisabled ? "disabled" : ""} ${triggerAttrs}>
        <span data-part="value" data-placeholder="Choose one">Choose one</span>
      </button>
      <div data-part="content" ${contentAttrs} hidden>
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

const TYPEAHEAD_ITEMS = [
  { value: "apple", label: "Apple" },
  { value: "banana", label: "Banana" },
  { value: "blueberry", label: "Blueberry" },
  { value: "blackberry", label: "Blackberry", disabled: true },
  { value: "brown-pear", label: "Brown Pear" },
  { value: "cherry", label: "★ Cherry", textValue: "Cherry" },
];

function keydownWith(el, key, init) {
  const event = new window.KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
    ...init,
  });
  el.dispatchEvent(event);
  return event;
}

const focusedValue = () => document.activeElement?.getAttribute("data-value");

test("typing in the open list highlights the matching item", () => {
  const { component, trigger } = buildSelect({ items: TYPEAHEAD_ITEMS });

  click(trigger);
  assert.equal(focusedValue(), "apple");

  keydown(document.activeElement, "b");
  assert.equal(focusedValue(), "banana");
  keydown(document.activeElement, "l");
  assert.equal(focusedValue(), "blueberry");
  assert.equal(component.state, "open", "highlighting does not select");
  assert.equal(component.selection.getValue(), null);

  component.destroy();
});

test("a repeated letter cycles through the open list, skipping disabled items", () => {
  const { component, trigger } = buildSelect({ items: TYPEAHEAD_ITEMS });

  click(trigger);
  const seen = [];
  for (let i = 0; i < 4; i++) {
    keydown(document.activeElement, "b");
    seen.push(focusedValue());
  }
  assert.deepEqual(seen, ["banana", "blueberry", "brown-pear", "banana"]);

  component.destroy();
});

test("typeahead matches data-text-value and ignores Ctrl/Alt/Meta", () => {
  const { component, trigger } = buildSelect({ items: TYPEAHEAD_ITEMS });

  click(trigger);
  keydownWith(document.activeElement, "c", { metaKey: true });
  keydownWith(document.activeElement, "c", { ctrlKey: true });
  keydownWith(document.activeElement, "c", { altKey: true });
  assert.equal(focusedValue(), "apple");
  assert.equal(component.typeahead.isSearching, false);

  keydown(document.activeElement, "c");
  assert.equal(focusedValue(), "cherry");

  component.destroy();
});

test("the open-list search clears 1s after the last key", async () => {
  const { component, trigger } = buildSelect({ items: TYPEAHEAD_ITEMS });

  click(trigger);
  keydown(document.activeElement, "b");
  keydown(document.activeElement, "c");
  assert.equal(focusedValue(), "banana", '"bc" matches nothing');

  await waitFor(() => !component.typeahead.isSearching, { timeout: 3000 });

  keydown(document.activeElement, "c");
  assert.equal(focusedValue(), "cherry");

  component.destroy();
});

test("Space mid-search types a space instead of selecting", () => {
  const { component, pushed, trigger } = buildSelect({
    items: TYPEAHEAD_ITEMS,
  });

  click(trigger);
  for (const key of ["b", "r", "o", "w", "n", " ", "p"]) {
    keydown(document.activeElement, key);
  }
  assert.equal(focusedValue(), "brown-pear");
  assert.equal(component.typeahead.search, "brown p");
  assert.equal(component.state, "open");
  assert.equal(
    pushed.some(({ event }) => event === "value_changed"),
    false,
  );

  component.destroy();
});

test("typing on the focused closed trigger selects the matching item", () => {
  const { component, hiddenInputs, pushed, trigger, valueDisplay } =
    buildSelect({ items: TYPEAHEAD_ITEMS });

  trigger.focus();
  keydown(trigger, "b");
  assert.equal(component.state, "closed", "stays closed");
  assert.equal(component.selection.getValue(), "banana");
  assert.equal(valueDisplay.textContent, "Banana");
  assert.equal(hiddenInputs()[0].value, "banana");
  assert.deepEqual(pushed.at(-1).payload.value, "banana");
  assert.equal(pushed.at(-1).event, "value_changed");

  // Repeated letters cycle from the selected item, skipping disabled ones.
  keydown(trigger, "b");
  assert.equal(component.selection.getValue(), "blueberry");
  keydown(trigger, "b");
  assert.equal(component.selection.getValue(), "brown-pear");

  component.destroy();
});

test("a closed-trigger search survives the rebuild its value-changed patch causes", () => {
  const { component, el, trigger } = buildSelect({ items: TYPEAHEAD_ITEMS });

  trigger.focus();
  keydown(trigger, "b");
  assert.equal(component.selection.getValue(), "banana");

  // The server echoes the value back and the hook rebuilds the component.
  const options = JSON.parse(el.dataset.options);
  el.dataset.options = JSON.stringify({ ...options, value: "banana" });
  component.destroy();
  const rebuilt = registry.create("select", el, {
    pushEventTo: () => {},
    liveSocket: { execJS: () => {} },
  });

  // "bl" moves on to Blueberry; a fresh "l" would match nothing.
  keydown(trigger, "l");
  assert.equal(rebuilt.selection.getValue(), "blueberry");

  rebuilt.destroy();
});

test("Space on the closed trigger mid-search does not open; after the timeout it does", async () => {
  const { component, trigger } = buildSelect({ items: TYPEAHEAD_ITEMS });

  trigger.focus();
  keydown(trigger, "b");
  keydown(trigger, "r");
  const space = keydown(trigger, " ");
  assert.equal(space.defaultPrevented, true);
  assert.equal(component.state, "closed");
  keydown(trigger, "p");
  assert.equal(component.selection.getValue(), "brown-pear");

  await waitFor(() => !component.triggerTypeahead.isSearching, {
    timeout: 3000,
  });

  keydown(trigger, " ");
  assert.equal(component.state, "open");

  component.destroy();
});

test("closed-trigger typeahead leaves disabled and multiple selects alone", () => {
  const disabled = buildSelect({ items: TYPEAHEAD_ITEMS, disabled: true });
  keydown(disabled.trigger, "b");
  assert.equal(disabled.component.selection.getValue(), null);
  disabled.component.destroy();

  const multiple = buildSelect({ items: TYPEAHEAD_ITEMS, multiple: true });
  keydown(multiple.trigger, "b");
  assert.deepEqual(multiple.component.selection.getValue(true), []);
  assert.equal(multiple.component.state, "closed");
  multiple.component.destroy();
});

const OPEN_MAPPINGS = {
  "value-changed": "value_changed",
  open: "opened",
  close: "closed",
};

// The select's server-rendered markup: closed, nothing selected, and no
// hook-managed hidden inputs.
function patch(el, options) {
  simulatePatch(el, {
    hidden: ['[data-part="content"]', '[data-part="item-indicator"]'],
    remove: ['input[data-salad-ui-select-input="true"]'],
  });
  el.dataset.state = "closed";
  const display = el.querySelector('[data-part="value"]');
  display.textContent = "Choose one";
  display.removeAttribute("data-content");
  if (options) el.dataset.options = JSON.stringify(options);
}

const count = (pushed, name) =>
  pushed.filter(({ event }) => event === name).length;

test("a LiveView patch keeps an open select open with its selection", () => {
  const { component, el, trigger, content, item, valueDisplay, pushed } =
    buildSelect({ defaultValue: "banana", eventMappings: OPEN_MAPPINGS });
  const hook = hookFor(el, component);
  click(trigger);
  assert.equal(component.state, "open");

  hook.beforeUpdate();
  patch(el);
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(component.state, "open");
  assert.equal(el.dataset.state, "open");
  assert.equal(content.hidden, false);
  assert.equal(content.style.position, "fixed");
  assert.equal(trigger.getAttribute("aria-expanded"), "true");
  assert.equal(content.getAttribute("role"), "listbox");
  assert.equal(item("banana").getAttribute("aria-selected"), "true");
  assert.equal(
    item("banana").querySelector('[data-part="item-indicator"]').hidden,
    false,
  );
  assert.equal(valueDisplay.textContent, "Banana");
  assert.equal(
    el.querySelector('input[data-salad-ui-select-input="true"]').value,
    "banana",
  );
  assert.equal(count(pushed, "opened"), 1);

  // Still interactive.
  keydown(content, "ArrowDown");
  assert.equal(document.activeElement, item("orange"));
  click(item("orange"));
  assert.equal(component.state, "closed");
  assert.equal(valueDisplay.textContent, "Orange");
  component.destroy();
});

test("a multiple select stays open while the form round-trips its value", () => {
  const { component, el, trigger, item, valueDisplay, pushed } = buildSelect({
    multiple: true,
    value: [],
    inForm: true,
    eventMappings: OPEN_MAPPINGS,
  });
  const hook = hookFor(el, component);
  click(trigger);
  click(item("apple"));
  assert.equal(component.state, "open");

  // phx-change: the server re-renders the controlled value it received.
  hook.beforeUpdate();
  patch(el, {
    name: "fruit",
    multiple: true,
    value: ["apple"],
    defaultValue: null,
    disabled: false,
    usePortal: false,
  });
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(component.state, "open");
  assert.equal(item("apple").getAttribute("aria-selected"), "true");
  assert.equal(valueDisplay.textContent, "Apple");
  assert.equal(count(pushed, "value_changed"), 1);
  assert.equal(count(pushed, "opened"), 1);
  component.destroy();
});

test("a new server value is selected in place without value-changed", () => {
  const { component, el, item, valueDisplay, pushed } = buildSelect({
    value: "apple",
  });
  const hook = hookFor(el, component);

  patch(el, {
    name: "fruit",
    multiple: false,
    value: "orange",
    defaultValue: null,
    disabled: false,
    usePortal: false,
  });
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(item("orange").getAttribute("aria-selected"), "true");
  assert.equal(item("apple").getAttribute("aria-selected"), "false");
  assert.equal(valueDisplay.textContent, "Orange");
  assert.equal(pushed.length, 0);
  component.destroy();
});

test("new items from the server keep the selection and the open state", () => {
  const { component, el, trigger, content, item, valueDisplay } = buildSelect({
    defaultValue: "banana",
  });
  const hook = hookFor(el, component);
  click(trigger);

  hook.beforeUpdate();
  patch(el);
  content.insertAdjacentHTML(
    "beforeend",
    `<div data-part="item" data-value="kiwi" tabindex="0">
       <span data-part="item-indicator" hidden></span>
       <span data-part="item-text">Kiwi</span>
     </div>`,
  );
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(component.state, "open");
  assert.equal(item("banana").getAttribute("aria-selected"), "true");
  assert.equal(valueDisplay.textContent, "Banana");

  click(item("kiwi"));
  assert.equal(valueDisplay.textContent, "Kiwi");
  component.destroy();
});

test("changed select options rebuild it", () => {
  const { component, el } = buildSelect();
  const hook = hookFor(el, component);

  patch(el, { name: "fruit", multiple: true, value: null });
  hook.updated();

  assert.notEqual(hook.component, component);
  assert.equal(component.destroyed, true);
  hook.destroyed();
});

test("portaled content is handed back for the patch and portaled again", () => {
  const { component, el, trigger, content, item } = buildSelect({
    defaultValue: "banana",
    usePortal: true,
  });
  const hook = hookFor(el, component);
  const orange = item("orange");
  click(trigger);
  keydown(content, "ArrowDown");
  assert.equal(document.activeElement, orange);
  assert.equal(el.contains(content), false);

  hook.beforeUpdate();
  // LiveView patches the content inside the root.
  assert.equal(el.contains(content), true);
  patch(el);
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(component.state, "open");
  assert.equal(el.contains(content), false);
  assert.equal(content.hidden, false);
  assert.equal(document.activeElement, orange);

  component.destroy();
});

// --- disabled -------------------------------------------------------------

test("a disabled select ignores open and toggle commands", () => {
  const { component, content } = buildSelect({ disabled: true });

  component.handleCommand("open");
  assert.equal(component.state, "closed");
  component.handleCommand("toggle");
  assert.equal(component.state, "closed");
  assert.equal(content.hidden, true);

  component.destroy();
});

test("disabled disables the trigger, the hidden inputs and the tracker", () => {
  const { component, form, hiddenInputs, trigger } = buildSelect({
    optionsDisabled: true,
    triggerDisabled: false,
    value: "banana",
    inForm: true,
    tracker: { name: "fruit" },
  });

  assert.equal(component.disabled, true);
  assert.equal(trigger.disabled, true);
  assert.equal(trigger.hasAttribute("data-disabled"), true);
  assert.equal(hiddenInputs().length, 1);
  assert.equal(hiddenInputs()[0].disabled, true);
  // Like a disabled native select, nothing is submitted.
  assert.deepEqual([...new window.FormData(form).entries()], []);

  click(trigger);
  assert.equal(component.state, "closed");

  component.destroy();
});

test("enabling the select on a patch removes the mirrored disabled", () => {
  const { component, el, trigger } = buildSelect({
    disabled: true,
    triggerDisabled: false,
  });
  assert.equal(trigger.disabled, true);

  el.setAttribute("data-disabled", "false");
  const rebuilt = rebuild(component, el);

  assert.equal(trigger.disabled, false);
  assert.equal(trigger.hasAttribute("data-disabled"), false);
  assert.equal(trigger.hasAttribute("data-disabled-synced"), false);

  rebuilt.destroy();
});

test("an explicit trigger disabled survives a patch that enables the select", () => {
  const { component, el, trigger } = buildSelect({ disabled: true });

  el.setAttribute("data-disabled", "false");
  const rebuilt = rebuild(component, el);

  assert.equal(trigger.disabled, true);

  rebuilt.destroy();
});

// --- multiple select tracking input --------------------------------------

test("an empty multiple select submits name= and switches to name[] once filled", () => {
  const { component, form, item, el } = buildSelect({
    multiple: true,
    inForm: true,
    tracker: { name: "fruit" },
  });
  const tracker = el.querySelector("[data-salad-ui-select-tracker]");
  const entries = () => [...new window.FormData(form).entries()];

  assert.deepEqual(entries(), [["fruit", ""]]);

  click(item("banana"));
  assert.equal(tracker.name, "fruit[]");
  assert.equal(tracker.disabled, true);
  assert.deepEqual(entries(), [["fruit[]", "banana"]]);

  click(item("banana"));
  assert.equal(tracker.name, "fruit");
  assert.equal(tracker.disabled, false);
  assert.deepEqual(entries(), [["fruit", ""]]);

  component.destroy();
});

test("a preselected multiple select keeps the tracker disabled as name[]", () => {
  const { component, el } = buildSelect({
    multiple: true,
    value: ["banana"],
    tracker: { name: "fruit[]", disabled: true },
  });
  const tracker = el.querySelector("[data-salad-ui-select-tracker]");

  assert.equal(tracker.name, "fruit[]");
  assert.equal(tracker.disabled, true);

  component.destroy();
});

// --- position="item-aligned" math ----------------------------------------

const WINDOW = { windowWidth: 1024, windowHeight: 768 };
const TRIGGER = { top: 300, height: 36, left: 100, right: 280, width: 180 };
const VALUE = { left: 112, right: 250 };

test("item-aligned: the selected item's middle lands on the trigger's middle", () => {
  const position = itemAlignedPosition({
    ...WINDOW,
    trigger: TRIGGER,
    value: VALUE,
    contentWidth: 150,
    contentHeight: 120,
    itemTextOffset: 33,
    itemMiddle: 52,
    viewportTop: 1,
    scrollHeight: 110,
    clientHeight: 110,
  });

  // 318 (trigger middle) - 1 (viewport top) - 52 (item middle)
  assert.equal(position.y, 265);
  assert.equal(position.scrollTop, 0);
  // The item text starts where the value text does...
  assert.equal(position.x, VALUE.left - 33);
  // ...and the panel is wide enough to cover the trigger.
  assert.equal(position.minWidth, TRIGGER.right - position.x);
});

test("item-aligned: a long list is scrolled to bring the item into line", () => {
  const position = itemAlignedPosition({
    ...WINDOW,
    trigger: TRIGGER,
    value: VALUE,
    contentWidth: 150,
    contentHeight: 400,
    itemTextOffset: 33,
    itemMiddle: 600,
    viewportTop: 1,
    scrollHeight: 900,
    clientHeight: 380,
  });

  assert.equal(position.y, 10);
  assert.equal(position.scrollTop, 293);
  assert.equal(position.y + 1 + 600 - position.scrollTop, 318);
});

test("item-aligned: returns null (popper fallback) near the window edges", () => {
  const near = (top) =>
    itemAlignedPosition({
      ...WINDOW,
      trigger: { ...TRIGGER, top },
      value: VALUE,
      contentWidth: 150,
      contentHeight: 120,
      itemTextOffset: 33,
      itemMiddle: 52,
      viewportTop: 1,
      scrollHeight: 110,
      clientHeight: 110,
    });

  assert.equal(near(5), null);
  assert.equal(near(700), null);
  assert.notEqual(near(300), null);
});

test("item-aligned: the panel is kept inside the window horizontally", () => {
  const position = itemAlignedPosition({
    ...WINDOW,
    trigger: { ...TRIGGER, left: 5, right: 185 },
    value: { left: 17, right: 160 },
    contentWidth: 150,
    contentHeight: 120,
    itemTextOffset: 33,
    itemMiddle: 52,
  });

  assert.equal(position.x, 10);
});

test("item-aligned: right-to-left lines up the right edges", () => {
  const position = itemAlignedPosition({
    ...WINDOW,
    trigger: { top: 300, height: 36, left: 700, right: 880, width: 180 },
    value: { left: 730, right: 868 },
    contentWidth: 250,
    contentHeight: 120,
    itemTextOffset: 33,
    itemMiddle: 52,
    dir: "rtl",
  });

  // The panel's right edge sits 33px past the value text's right edge.
  assert.equal(position.x + 250, 868 + 33);
  assert.equal(position.minWidth, 868 + 33 - 700);
});

// --- positioning in the component ----------------------------------------

function layOutItemAligned(
  { el, trigger, valueDisplay, content, viewport, item },
  triggerTop,
) {
  setRect(el, {
    top: triggerTop,
    bottom: triggerTop + 36,
    height: 36,
    left: 100,
    right: 280,
    width: 180,
  });
  setRect(trigger, {
    top: triggerTop,
    bottom: triggerTop + 36,
    height: 36,
    left: 100,
    right: 280,
    width: 180,
  });
  setRect(valueDisplay, { left: 112, right: 250, top: triggerTop + 8 });
  setRect(content, {
    top: 0,
    left: 0,
    right: 150,
    bottom: 120,
    width: 150,
    height: 120,
  });
  setRect(viewport, { top: 1, left: 1 });
  setRect(item("banana"), { top: 37, height: 32, left: 5 });
  setRect(item("banana").querySelector('[data-part="item-text"]'), {
    left: 33,
  });
}

test("item-aligned content opens over the trigger with the selected item in line", () => {
  const parts = buildSelect({
    value: "banana",
    scrollable: true,
    contentAttrs:
      'data-position="item-aligned" data-side="bottom" data-align="start"',
  });
  layOutItemAligned(parts, 300);

  click(parts.trigger);

  assert.equal(parts.component.state, "open");
  assert.equal(parts.content.style.top, "265px");
  assert.equal(parts.content.style.left, "79px");
  assert.equal(parts.content.style.minWidth, "201px");
  assert.equal(parts.content.hasAttribute("data-side"), false);

  parts.component.destroy();
});

test("item-aligned content falls back to popper placement near the window edge", () => {
  const parts = buildSelect({
    value: "banana",
    scrollable: true,
    contentAttrs:
      'data-position="item-aligned" data-side="bottom" data-align="start"',
  });
  layOutItemAligned(parts, 5);

  click(parts.trigger);

  assert.equal(parts.content.getAttribute("data-side"), "bottom");
  // Below the trigger (5 + 36), 4px off it.
  assert.equal(parts.content.style.top, "45px");
  assert.equal(parts.content.style.left, "100px");
  assert.equal(parts.content.style.minWidth, "var(--salad-reference-width)");

  parts.component.destroy();
});

test("popper content takes side and align and the trigger size variables", () => {
  const { component, el, trigger, content } = buildSelect({
    contentAttrs:
      'data-position="popper" data-side="right" data-align="center"',
  });
  const rect = {
    top: 100,
    bottom: 136,
    height: 36,
    left: 50,
    right: 250,
    width: 200,
  };
  setRect(el, rect);
  setRect(trigger, rect);

  click(trigger);

  assert.equal(content.getAttribute("data-side"), "right");
  // No sideOffset: shadcn's data-[side=right]:translate-x-1 adds the gap.
  assert.equal(content.style.left, "250px");
  assert.equal(content.style.top, "118px");
  assert.equal(
    content.style.getPropertyValue("--salad-select-trigger-width"),
    "200px",
  );
  assert.equal(
    content.style.getPropertyValue("--salad-select-trigger-height"),
    "36px",
  );
  // Centred beside the trigger, the cap is twice the room to the nearer
  // window edge from the trigger's middle.
  assert.equal(
    content.style.getPropertyValue(AVAILABLE_HEIGHT),
    `${2 * 118 - 12}px`,
  );

  component.destroy();
});

// --- select deltas across LiveView patches --------------------------------

test("a patch keeps a disabled select's trigger disabled", () => {
  const { component, el, trigger } = buildSelect({
    disabled: true,
    triggerDisabled: false,
  });
  const hook = hookFor(el, component);

  hook.beforeUpdate();
  patch(el);
  // morphdom drops the hook-set attributes the server did not render.
  ["disabled", "data-disabled", "data-disabled-synced"].forEach((name) =>
    trigger.removeAttribute(name),
  );
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(trigger.disabled, true);
  click(trigger);
  assert.equal(component.state, "closed");
  component.destroy();
});

test("a patch re-places an open item-aligned select, and follows a new position", () => {
  const parts = buildSelect({
    value: "banana",
    scrollable: true,
    contentAttrs:
      'data-position="item-aligned" data-side="bottom" data-align="start"',
  });
  const { component, el, trigger, content } = parts;
  const hook = hookFor(el, component);
  layOutItemAligned(parts, 300);
  click(trigger);
  assert.equal(content.style.top, "265px");

  hook.beforeUpdate();
  patch(el);
  content.setAttribute("data-side", "bottom");
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(component.state, "open");
  assert.equal(content.style.top, "265px");
  assert.equal(content.style.minWidth, "201px");
  assert.equal(content.hasAttribute("data-side"), false);

  // The server switches the content to popper placement.
  hook.beforeUpdate();
  patch(el);
  content.setAttribute("data-position", "popper");
  content.setAttribute("data-side", "bottom");
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(component.state, "open");
  assert.equal(content.getAttribute("data-side"), "bottom");
  // Below the trigger (300 + 36), with no sideOffset in popper mode.
  assert.equal(content.style.top, "336px");
  component.destroy();
});
