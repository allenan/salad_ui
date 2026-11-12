import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/combobox.js"; // self-registers "combobox"
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

const FRAMEWORKS = ["Next.js", "SvelteKit", "Nuxt.js", "Remix", "Astro"];

function itemMarkup(item) {
  const {
    value,
    label,
    text = label ?? value,
    disabled = false,
  } = typeof item === "string" ? { value: item } : item;
  return `
    <div data-part="item" role="option" data-value="${value}"
         ${label ? `data-label="${label}"` : ""}
         ${disabled ? 'data-disabled="true" aria-disabled="true"' : ""}>
      ${text}
      <span data-part="item-indicator" hidden></span>
    </div>`;
}

function listMarkup({ items, groups }) {
  if (groups) {
    return groups
      .map(
        (group, index) => `
        <div data-part="group" role="group">
          <div data-part="label">${group.label}</div>
          ${group.items.map(itemMarkup).join("")}
          ${index < groups.length - 1 ? '<div data-part="separator"></div>' : ""}
        </div>`,
      )
      .join("");
  }
  return items.map(itemMarkup).join("");
}

const inputGroupMarkup = ({
  showClear = false,
  inputAttrs = "",
  disabled = false,
}) => `
  <div data-slot="input-group" role="group">
    <input data-part="input" data-slot="input-group-control" role="combobox"
           aria-expanded="false" ${disabled ? "disabled" : ""} ${inputAttrs} />
    <div data-slot="input-group-addon" data-part="addon">
      <button type="button" data-part="trigger" tabindex="-1" aria-label="Open"></button>
      ${showClear ? '<button type="button" data-part="clear" tabindex="-1" hidden></button>' : ""}
    </div>
  </div>`;

const chipsMarkup = () => `
  <div data-part="chips">
    <template data-part="chip-template">
      <div data-part="chip" data-value="">
        <span data-part="chip-label"></span>
        <button type="button" data-part="chip-remove" tabindex="-1"></button>
      </div>
    </template>
    <input data-part="input" role="combobox" aria-expanded="false" />
  </div>`;

const popupTriggerMarkup = () => `
  <button type="button" data-part="trigger" aria-haspopup="listbox">
    <span data-part="value" data-placeholder="Select a country">Select a country</span>
  </button>`;

function buildCombobox({
  id = "cb",
  name = "framework",
  multiple = false,
  value = null,
  autoHighlight = false,
  filter = true,
  disabled = false,
  invalid = false,
  mode = "input",
  showClear = false,
  inputAttrs = "",
  items = FRAMEWORKS,
  groups = null,
  inForm = false,
} = {}) {
  const options = {
    name,
    multiple,
    value,
    autoHighlight,
    filter,
    disabled,
  };

  const control =
    mode === "chips"
      ? chipsMarkup()
      : mode === "popup"
        ? popupTriggerMarkup()
        : inputGroupMarkup({ showClear, inputAttrs, disabled });

  const contentInput =
    mode === "popup"
      ? `<div data-slot="input-group"><input data-part="input" role="combobox" /></div>`
      : "";

  const root = `
    <div id="${id}" data-component="combobox" data-part="root" data-state="closed"
         ${invalid ? 'data-invalid="true"' : ""}
         data-options='${JSON.stringify(options)}'
         data-event-mappings='{"value-changed":"changed","open":"opened","close":"closed"}'>
      ${name ? `<input type="text" hidden name="${multiple ? `${name}[]` : name}" value="" ${multiple ? "disabled" : ""} data-salad-ui-combobox-tracker="true" />` : ""}
      ${control}
      <div data-part="content" data-side="bottom" data-align="start" hidden>
        ${contentInput}
        <div data-part="empty">No items found.</div>
        <div data-part="list" role="listbox">
          ${listMarkup({ items, groups })}
        </div>
      </div>
    </div>
    <button id="outside" type="button">outside</button>`;

  document.body.innerHTML = inForm ? `<form id="form">${root}</form>` : root;

  const el = document.getElementById(id);
  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const component = registry.create("combobox", el, hookContext);
  const content = el.querySelector('[data-part="content"]');

  return {
    component,
    el,
    pushed,
    content,
    form: document.getElementById("form"),
    input: el.querySelector('[data-part="input"]'),
    contentInput: content.querySelector('[data-part="input"]'),
    list: el.querySelector('[data-part="list"]'),
    trigger: el.querySelector('[data-part="trigger"]'),
    clear: el.querySelector('[data-part="clear"]'),
    chips: el.querySelector('[data-part="chips"]'),
    valueDisplay: el.querySelector('[data-part="value"]'),
    item: (value) =>
      el.querySelector(`[data-part="item"][data-value="${value}"]`),
    visibleValues: () =>
      Array.from(el.querySelectorAll('[data-part="item"]'))
        .filter((item) => !item.hidden)
        .map((item) => item.dataset.value),
    highlighted: () =>
      el.querySelector('[data-part="item"][data-highlighted]')?.dataset.value ??
      null,
    chipValues: () =>
      Array.from(el.querySelectorAll('[data-part="chips"] [data-part="chip"]'))
        .filter((chip) => !chip.closest("template"))
        .map((chip) => chip.dataset.value),
    hiddenValues: () =>
      Array.from(
        el.querySelectorAll('input[data-salad-ui-combobox-input="true"]'),
      ).map((input) => [input.name, input.value]),
  };
}

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("mousedown", { bubbles: true, cancelable: true }),
  );
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

function type(input, text) {
  input.value = text;
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
}

const isOpen = (c) => c.component.state === "open" && !c.content.hidden;
const isClosed = (c) => c.component.state === "closed" && c.content.hidden;

test("wires up the combobox ARIA pattern", () => {
  const c = buildCombobox();

  assert.equal(c.input.getAttribute("role"), "combobox");
  assert.equal(c.input.getAttribute("aria-autocomplete"), "list");
  assert.equal(c.input.getAttribute("aria-expanded"), "false");
  assert.equal(c.list.getAttribute("role"), "listbox");
  assert.equal(c.list.id, "cb-list");
  assert.equal(c.input.getAttribute("aria-controls"), "cb-list");
  assert.ok(c.item("Remix").id, "options get ids for aria-activedescendant");
  assert.equal(c.item("Remix").getAttribute("aria-selected"), "false");
  assert.ok(c.content.hidden);
});

test("clicking the input opens the list; Escape closes it", async () => {
  const c = buildCombobox();

  click(c.input);
  assert.ok(isOpen(c));
  assert.equal(c.input.getAttribute("aria-expanded"), "true");
  assert.ok(c.pushed.some((p) => p.event === "opened"));

  const event = keydown(c.input, "Escape");
  assert.ok(event.defaultPrevented);
  await waitFor(() => isClosed(c));
  assert.equal(c.input.getAttribute("aria-expanded"), "false");
  await waitFor(() => c.pushed.some((p) => p.event === "closed"));
});

test("typing filters the items and shows the empty state", () => {
  const c = buildCombobox();

  type(c.input, "nu");
  assert.ok(isOpen(c), "typing opens the list");
  assert.deepEqual(c.visibleValues(), ["Nuxt.js"]);
  assert.ok(!c.content.hasAttribute("data-empty"));
  assert.equal(c.highlighted(), null, "no highlight without auto-highlight");

  type(c.input, "zzz");
  assert.deepEqual(c.visibleValues(), []);
  assert.ok(c.content.hasAttribute("data-empty"));
  assert.ok(c.list.hasAttribute("data-empty"));

  type(c.input, "");
  assert.equal(c.visibleValues().length, FRAMEWORKS.length);
  assert.ok(!c.content.hasAttribute("data-empty"));
});

test("arrow keys move the highlight and Enter selects it", async () => {
  const c = buildCombobox({ inForm: true });
  const changes = [];
  c.form.addEventListener("change", (e) => changes.push(e.target));

  keydown(c.input, "ArrowDown");
  assert.ok(isOpen(c));
  assert.equal(c.highlighted(), "Next.js");
  assert.equal(
    c.input.getAttribute("aria-activedescendant"),
    c.item("Next.js").id,
  );

  keydown(c.input, "ArrowDown");
  assert.equal(c.highlighted(), "SvelteKit");
  keydown(c.input, "ArrowUp");
  keydown(c.input, "ArrowUp");
  assert.equal(c.highlighted(), "Astro", "wraps around");

  const enter = keydown(c.input, "Enter");
  assert.ok(enter.defaultPrevented, "Enter does not submit the form");
  await waitFor(() => isClosed(c));

  assert.equal(c.input.value, "Astro");
  assert.deepEqual(c.hiddenValues(), [["framework", "Astro"]]);
  assert.equal(c.item("Astro").getAttribute("aria-selected"), "true");
  assert.ok(
    !c.item("Astro").querySelector('[data-part="item-indicator"]').hidden,
  );
  assert.deepEqual(
    c.pushed.find((p) => p.event === "changed").payload.value,
    "Astro",
  );
  assert.equal(changes.length, 1);
  assert.equal(changes[0].dataset.saladUiComboboxTracker, "true");
  assert.equal(c.input.hasAttribute("aria-activedescendant"), false);
});

test("Alt+ArrowDown opens without a highlight; Alt+ArrowUp closes", async () => {
  const c = buildCombobox();

  const altKey = (key) =>
    c.input.dispatchEvent(
      new window.KeyboardEvent("keydown", {
        key,
        altKey: true,
        bubbles: true,
        cancelable: true,
      }),
    );

  altKey("ArrowDown");
  assert.ok(isOpen(c));
  assert.equal(c.highlighted(), null);

  altKey("ArrowUp");
  await waitFor(() => isClosed(c));
});

test("picking the selected item again only closes the list", async () => {
  const c = buildCombobox({ value: "Remix", inForm: true });
  let changes = 0;
  c.form.addEventListener("change", () => (changes += 1));

  keydown(c.input, "ArrowDown");
  assert.equal(c.highlighted(), "Remix");
  keydown(c.input, "Enter");
  await waitFor(() => isClosed(c));
  assert.equal(c.input.value, "Remix");
  assert.equal(changes, 0);
  assert.equal(c.pushed.filter((p) => p.event === "changed").length, 0);
});

test("Enter while composing text does not select", () => {
  const c = buildCombobox();

  keydown(c.input, "ArrowDown");
  const event = new window.KeyboardEvent("keydown", {
    key: "Enter",
    isComposing: true,
    bubbles: true,
    cancelable: true,
  });
  c.input.dispatchEvent(event);
  assert.ok(isOpen(c));
  assert.deepEqual(c.hiddenValues(), []);
});

test("reopening shows every item and highlights the selection", () => {
  const c = buildCombobox({ value: "Remix" });
  assert.equal(c.input.value, "Remix", "input shows the selected label");

  keydown(c.input, "ArrowDown");
  assert.equal(c.visibleValues().length, FRAMEWORKS.length);
  assert.equal(c.highlighted(), "Remix");
});

test("closing without picking restores the selected label", async () => {
  const c = buildCombobox({ value: "Remix" });

  type(c.input, "ast");
  assert.deepEqual(c.visibleValues(), ["Astro"]);
  keydown(c.input, "Escape");
  await waitFor(() => isClosed(c));
  assert.equal(c.input.value, "Remix");
});

test("auto-highlight highlights the first match while typing", () => {
  const c = buildCombobox({ autoHighlight: true });

  type(c.input, "s");
  assert.deepEqual(c.visibleValues(), [
    "Next.js",
    "SvelteKit",
    "Nuxt.js",
    "Astro",
  ]);
  assert.equal(c.highlighted(), "Next.js");

  type(c.input, "sv");
  assert.equal(c.highlighted(), "SvelteKit");
});

test("mouse: hovering highlights, clicking selects", async () => {
  const c = buildCombobox();

  click(c.input);
  c.item("Nuxt.js").dispatchEvent(
    new window.MouseEvent("mousemove", { bubbles: true }),
  );
  assert.equal(c.highlighted(), "Nuxt.js");

  const down = new window.MouseEvent("mousedown", {
    bubbles: true,
    cancelable: true,
  });
  c.item("Nuxt.js").dispatchEvent(down);
  assert.ok(down.defaultPrevented, "the input keeps focus");

  click(c.item("Nuxt.js"));
  await waitFor(() => isClosed(c));
  assert.equal(c.input.value, "Nuxt.js");
});

test("disabled items are skipped and cannot be selected", () => {
  const c = buildCombobox({
    items: ["a", { value: "b", disabled: true }, "c"],
  });

  keydown(c.input, "ArrowDown");
  keydown(c.input, "ArrowDown");
  assert.equal(c.highlighted(), "c");

  click(c.item("b"));
  assert.ok(isOpen(c));
  assert.deepEqual(c.hiddenValues(), []);
});

test("the trigger toggles the list", async () => {
  const c = buildCombobox();

  click(c.trigger);
  assert.ok(isOpen(c));
  click(c.trigger);
  await waitFor(() => isClosed(c));
});

test("clicking outside closes the list", async () => {
  const c = buildCombobox();

  click(c.input);
  assert.ok(isOpen(c));
  click(document.getElementById("outside"));
  await waitFor(() => isClosed(c));
});

test("groups and separators hide when nothing in them matches", () => {
  const c = buildCombobox({
    groups: [
      { label: "Americas", items: ["New York", "Chicago"] },
      { label: "Europe", items: ["London", "Paris"] },
      { label: "Asia", items: ["Tokyo", "Seoul"] },
    ],
  });
  const groups = Array.from(c.el.querySelectorAll('[data-part="group"]'));
  const separators = Array.from(
    c.el.querySelectorAll('[data-part="separator"]'),
  );

  assert.ok(groups.every((g) => !g.hidden));
  assert.ok(separators.every((s) => !s.hidden));
  assert.ok(groups[0].getAttribute("aria-labelledby"));

  type(c.input, "o");
  // New York, Chicago, London, Tokyo, Seoul: every group still matches.
  assert.ok(groups.every((g) => !g.hidden));

  type(c.input, "lon");
  assert.deepEqual(
    groups.map((g) => g.hidden),
    [true, false, true],
  );
  assert.ok(
    separators.every((s) => s.hidden),
    "no separator without visible items on both sides",
  );
});

test("labels: items match and display their label", async () => {
  const c = buildCombobox({
    items: [
      {
        value: "ar",
        label: "Argentina",
        text: "<b>Argentina</b> South America",
      },
      { value: "br", label: "Brazil", text: "<b>Brazil</b> South America" },
    ],
  });

  type(c.input, "south");
  assert.deepEqual(c.visibleValues(), [], "matches the label, not the text");

  type(c.input, "bra");
  assert.deepEqual(c.visibleValues(), ["br"]);
  keydown(c.input, "ArrowDown");
  keydown(c.input, "Enter");
  await waitFor(() => isClosed(c));
  assert.equal(c.input.value, "Brazil");
  assert.deepEqual(c.hiddenValues(), [["framework", "br"]]);
});

test("show-clear: the clear button appears with a value and clears it", () => {
  const c = buildCombobox({ value: "Astro", showClear: true });

  assert.equal(c.clear.hidden, false);
  click(c.clear);
  assert.equal(c.input.value, "");
  assert.deepEqual(c.hiddenValues(), []);
  assert.equal(c.clear.hidden, true);
  assert.equal(c.pushed.find((p) => p.event === "changed").payload.value, null);
});

test("multiple: chips follow the selection and the list stays open", () => {
  const c = buildCombobox({
    mode: "chips",
    multiple: true,
    value: ["Next.js"],
  });

  assert.deepEqual(c.chipValues(), ["Next.js"]);
  assert.equal(
    c.chips.querySelector('[data-part="chip-label"]').textContent,
    "Next.js",
  );
  assert.deepEqual(c.hiddenValues(), [["framework[]", "Next.js"]]);
  assert.equal(c.list.getAttribute("aria-multiselectable"), "true");

  type(c.input, "rem");
  keydown(c.input, "ArrowDown");
  keydown(c.input, "Enter");

  assert.ok(isOpen(c), "stays open");
  assert.equal(c.input.value, "", "the query is cleared");
  assert.deepEqual(c.chipValues(), ["Next.js", "Remix"]);
  assert.deepEqual(c.hiddenValues(), [
    ["framework[]", "Next.js"],
    ["framework[]", "Remix"],
  ]);
  assert.deepEqual(
    c.pushed.findLast((p) => p.event === "changed").payload.value,
    ["Next.js", "Remix"],
  );

  // The chips sit in front of the input.
  assert.equal(c.chips.lastElementChild, c.input);

  // Picking a selected item again deselects it.
  click(c.item("Next.js"));
  assert.deepEqual(c.chipValues(), ["Remix"]);
});

test("multiple: chip remove buttons and Backspace remove values", () => {
  const c = buildCombobox({
    mode: "chips",
    multiple: true,
    value: ["Next.js", "Remix", "Astro"],
  });

  const remove = c.chips.querySelector(
    '[data-part="chip"][data-value="Remix"] [data-part="chip-remove"]',
  );
  assert.equal(remove.getAttribute("aria-label"), "Remove Remix");
  click(remove);
  assert.deepEqual(c.chipValues(), ["Next.js", "Astro"]);
  assert.ok(isClosed(c), "removing a chip does not open the list");

  keydown(c.input, "Backspace");
  assert.deepEqual(c.chipValues(), ["Next.js"]);
  assert.deepEqual(c.hiddenValues(), [["framework[]", "Next.js"]]);
});

test("multiple: the arrow keys move between chips; Backspace/Delete remove one", () => {
  const c = buildCombobox({
    mode: "chips",
    multiple: true,
    value: ["Next.js", "Remix", "Astro"],
  });
  const chip = (value) =>
    c.chips.querySelector(`[data-part="chip"][data-value="${value}"]`);

  c.input.focus();
  type(c.input, "ab");
  c.input.setSelectionRange(1, 1);
  keydown(c.input, "ArrowLeft");
  assert.equal(document.activeElement, c.input, "not at the start of the text");

  type(c.input, "");
  c.input.focus();
  const event = keydown(c.input, "ArrowLeft");
  assert.ok(event.defaultPrevented);
  assert.equal(document.activeElement, chip("Astro"));
  assert.equal(chip("Astro").getAttribute("tabindex"), "-1");

  keydown(chip("Astro"), "ArrowLeft");
  assert.equal(document.activeElement, chip("Remix"));
  keydown(chip("Remix"), "ArrowLeft");
  keydown(chip("Next.js"), "ArrowLeft");
  assert.equal(document.activeElement, chip("Next.js"), "stops at the first");
  keydown(chip("Next.js"), "ArrowRight");
  assert.equal(document.activeElement, chip("Remix"));

  keydown(chip("Remix"), "Backspace");
  assert.deepEqual(c.chipValues(), ["Next.js", "Astro"]);
  assert.deepEqual(c.hiddenValues(), [
    ["framework[]", "Next.js"],
    ["framework[]", "Astro"],
  ]);
  assert.equal(document.activeElement, chip("Next.js"), "focus moves back");

  keydown(chip("Next.js"), "Delete");
  assert.deepEqual(c.chipValues(), ["Astro"]);
  assert.equal(document.activeElement, chip("Astro"), "focus moves forward");

  keydown(chip("Astro"), "ArrowRight");
  assert.equal(document.activeElement, c.input, "past the last chip");

  keydown(c.input, "ArrowLeft");
  keydown(chip("Astro"), "Delete");
  assert.deepEqual(c.chipValues(), []);
  assert.equal(document.activeElement, c.input);
  assert.deepEqual(
    c.pushed.findLast((p) => p.event === "changed").payload.value,
    [],
  );
});

test("multiple: Escape or typing on a chip returns to the input", () => {
  const c = buildCombobox({
    mode: "chips",
    multiple: true,
    value: ["Next.js"],
  });
  const chip = c.chips.querySelector('[data-part="chip"]');

  click(c.input);
  c.input.focus();
  keydown(c.input, "ArrowLeft");
  assert.equal(document.activeElement, chip);
  assert.ok(isOpen(c), "moving onto a chip keeps the list open");

  keydown(chip, "x");
  assert.equal(document.activeElement, c.input);

  keydown(c.input, "ArrowLeft");
  keydown(chip, "Escape");
  assert.equal(document.activeElement, c.input);
  assert.equal(c.component.state, "closed");
});

test("multiple: the content is anchored to the chips", () => {
  const c = buildCombobox({ mode: "chips", multiple: true });

  click(c.input);
  assert.equal(c.content.getAttribute("data-chips"), "true");
  assert.equal(c.component.positionedElement.reference, c.chips);
});

test("popup mode: the trigger opens the content and focuses its input", async () => {
  const c = buildCombobox({ mode: "popup", value: "SvelteKit" });

  assert.equal(c.valueDisplay.textContent, "SvelteKit");
  assert.equal(c.trigger.getAttribute("aria-controls"), "cb-list");

  click(c.trigger);
  assert.ok(isOpen(c));
  assert.equal(document.activeElement, c.contentInput);
  assert.equal(c.trigger.getAttribute("aria-expanded"), "true");

  type(c.contentInput, "rem");
  assert.deepEqual(c.visibleValues(), ["Remix"]);
  keydown(c.contentInput, "ArrowDown");
  keydown(c.contentInput, "Enter");

  await waitFor(() => isClosed(c));
  assert.equal(c.valueDisplay.textContent, "Remix");
  assert.equal(c.contentInput.value, "", "the search is reset");
  assert.equal(document.activeElement, c.trigger);
});

test("popup mode: the placeholder shows without a value", () => {
  const c = buildCombobox({ mode: "popup" });

  assert.equal(c.valueDisplay.textContent, "Select a country");
  assert.ok(c.trigger.hasAttribute("data-placeholder"));
});

test("disabled: the list does not open", () => {
  const c = buildCombobox({ disabled: true });

  click(c.input);
  keydown(c.input, "ArrowDown");
  type(c.input, "a");
  assert.ok(isClosed(c));
});

test("invalid: mirrors the field error onto the input", () => {
  const c = buildCombobox({ invalid: true });
  assert.equal(c.input.getAttribute("aria-invalid"), "true");

  const explicit = buildCombobox({
    invalid: true,
    inputAttrs: 'aria-invalid="false"',
  });
  assert.equal(explicit.input.getAttribute("aria-invalid"), "false");
});

test("server commands open, close and clear", async () => {
  const c = buildCombobox({ value: "Astro" });

  c.component.handleCommand("open");
  assert.ok(isOpen(c));
  c.component.handleCommand("close");
  await waitFor(() => isClosed(c));
  c.component.handleCommand("clear");
  assert.deepEqual(c.hiddenValues(), []);
  assert.equal(c.input.value, "");
});

// Simulates a LiveView patch: the server re-renders the list (and resets the
// attributes the component wrote), then the hook asks the component whether
// to rebuild.
function patch(c, { items, options } = {}) {
  if (items) c.list.innerHTML = items.map(itemMarkup).join("");
  c.el.setAttribute("data-state", "closed");
  c.content.hidden = true;
  c.content.removeAttribute("style");
  c.el
    .querySelectorAll('input[data-salad-ui-combobox-input="true"]')
    .forEach((input) => input.remove());
  if (options) c.el.setAttribute("data-options", JSON.stringify(options));
  return c.component.skipReinitialize(c.el);
}

test("server filtering: items are left alone and survive a patch", async () => {
  const c = buildCombobox({ filter: false, autoHighlight: true });
  const queries = [];
  c.el.addEventListener("input", (e) => queries.push(e.target.value));

  type(c.input, "re");
  assert.ok(isOpen(c));
  assert.equal(c.visibleValues().length, FRAMEWORKS.length, "no client filter");

  // The server answers with the matching items.
  assert.equal(patch(c, { items: ["Remix"] }), true);
  assert.ok(isOpen(c), "still open after the patch");
  assert.equal(c.input.getAttribute("aria-expanded"), "true");
  assert.equal(c.highlighted(), "Remix", "auto-highlight applies to new items");

  patch(c, { items: [] });
  assert.ok(c.content.hasAttribute("data-empty"));

  patch(c, { items: ["Remix", "Astro"] });
  keydown(c.input, "ArrowDown");
  keydown(c.input, "Enter");
  await waitFor(() => isClosed(c));
  assert.deepEqual(c.hiddenValues(), [["framework", "Astro"]]);
  assert.equal(c.input.value, "Astro");

  // The selected item's label is remembered after the server drops it.
  patch(c, { items: ["Next.js"] });
  assert.deepEqual(c.hiddenValues(), [["framework", "Astro"]]);
  assert.equal(c.input.value, "Astro");
  assert.deepEqual(queries, ["re"]);
});

test("server filtering: clearing the query notifies the server", () => {
  const c = buildCombobox({
    filter: false,
    mode: "chips",
    multiple: true,
  });
  const queries = [];
  c.el.addEventListener("input", (e) => queries.push(e.target.value));

  type(c.input, "ne");
  keydown(c.input, "ArrowDown");
  keydown(c.input, "Enter");
  assert.deepEqual(queries, ["ne", ""]);
  assert.ok(isOpen(c), "the dispatched input event does not re-open or close");
});

test("a new server value replaces the selection", () => {
  const c = buildCombobox({ value: "Astro" });

  patch(c, {
    options: { name: "framework", value: "Remix", filter: true },
  });
  assert.deepEqual(c.hiddenValues(), [["framework", "Remix"]]);
  assert.equal(c.input.value, "Remix");

  // An unrelated patch with the same options keeps the client selection.
  keydown(c.input, "ArrowDown");
  click(c.item("Nuxt.js"));
  patch(c);
  assert.deepEqual(c.hiddenValues(), [["framework", "Nuxt.js"]]);
});

test("destroy removes listeners", () => {
  const c = buildCombobox();
  c.component.destroy();

  click(c.input);
  assert.ok(c.content.hidden);
});
