import assert from "node:assert/strict";
import { after, before, beforeEach, test } from "node:test";

import QuestionnaireComponent from "../salad_ui/components/questionnaire.js";
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

let current = null;
// Stands in for LiveView's window-level submit listener: records every
// submission the component lets through.
let submissions = [];

before(() => {
  installDom();
  window.addEventListener("submit", (event) => {
    const form = event.target;
    const data = new window.FormData(form);
    if (event.submitter?.name) {
      data.append(event.submitter.name, event.submitter.value);
    }
    submissions.push({ action: event.submitter?.value ?? null, data });
    event.preventDefault();
  });
});

after(() => {
  current?.destroy();
  uninstallDom();
});

beforeEach(() => {
  submissions = [];
});

function choiceHtml(name, value, { multiple = false, checked = false } = {}) {
  const type = multiple ? "checkbox" : "radio";
  return `
    <label data-part="choice" data-type="${type}">
      <input type="${type}" data-part="choice-input" name="${name}[]" value="${value}" ${checked ? "checked" : ""} />
      <span data-part="choice-label">${value}</span>
      <span data-part="choice-shortcut" aria-hidden="true" hidden></span>
    </label>`;
}

function itemHtml({
  name,
  required = false,
  multiple = false,
  disabled = false,
  choices = [],
  checked = [],
  input = false,
  inputValue = "",
  status = "unanswered",
  invalid = false,
}) {
  const flags = [
    required && "data-required",
    multiple && "data-multiple",
    disabled && "data-disabled disabled",
    invalid && "data-invalid",
  ]
    .filter(Boolean)
    .join(" ");
  return `
    <fieldset id="q-${name}" data-part="item" data-name="${name}" data-status="${status}" tabindex="-1" ${flags}>
      <legend data-part="title">${name}?</legend>
      <p id="q-${name}-description" data-part="description">About ${name}</p>
      <div data-part="choices">
        ${choices.map((value) => choiceHtml(name, value, { multiple, checked: checked.includes(value) })).join("")}
        ${input ? `<input type="text" data-part="input" data-name="${name}[]" name="${name}[]" value="${inputValue}" aria-label="Other" />` : ""}
      </div>
      <p id="q-${name}-error" data-part="error" hidden>Choose an answer</p>
    </fieldset>`;
}

const DEFAULT_ITEMS = [
  { name: "direction", required: true, choices: ["a", "b"], input: true },
  { name: "signals", multiple: true, choices: ["x", "y", "z"] },
  { name: "timing", required: true, choices: ["now", "later"] },
];

function build({
  items = DEFAULT_ITEMS,
  item = null,
  serverDriven = false,
  shortcuts = null,
  progress = '<div data-part="progress" data-default-label></div>',
  skipped = [],
} = {}) {
  current?.destroy();
  current = null;

  const options = JSON.stringify({ item, serverDriven, shortcuts });
  document.body.innerHTML = `
    <form id="q" data-component="questionnaire" data-part="root"
      data-options='${options}'
      data-event-mappings='{"item-change":"item_changed","status-change":"status_changed"}'>
      <button type="submit" name="_questionnaire[action]" value="continue" data-part="default-action"></button>
      <input type="hidden" name="_questionnaire[item]" value="${item ?? ""}" data-part="active-input" />
      ${skipped.map((name) => `<input type="hidden" name="_questionnaire[skipped][]" value="${name}" data-part="skipped-input" />`).join("")}
      ${progress}
      ${items.map(itemHtml).join("")}
      <div>
        <button type="submit" name="_questionnaire[action]" value="previous" data-part="previous">Previous</button>
        <button type="submit" name="_questionnaire[action]" value="skip" data-part="skip">Skip</button>
        <button type="submit" name="_questionnaire[action]" value="next" data-part="next">Next</button>
        <button type="submit" name="_questionnaire[action]" value="submit" data-part="submit">Submit</button>
      </div>
    </form>`;

  return mount();
}

function mount() {
  current?.destroy();
  const el = document.getElementById("q");
  const pushed = [];
  const hookContext = {
    pushEventTo(_el, event, payload) {
      pushed.push({ event, payload });
    },
  };
  const q = new QuestionnaireComponent(el, hookContext);
  q.setupEvents();
  q.afterMount();
  current = q;

  const item = (name) => el.querySelector(`[data-name="${name}"]`);
  const button = (part) => el.querySelector(`[data-part="${part}"]`);
  const choice = (name, value) =>
    item(name).querySelector(`input[value="${value}"]`);
  return { el, q, pushed, item, button, choice };
}

function pick(input) {
  input.click();
}

function type(input, value) {
  input.value = value;
  input.dispatchEvent(new Event("input", { bubbles: true }));
}

function key(target, keyName, init = {}) {
  const event = new KeyboardEvent("keydown", {
    key: keyName,
    bubbles: true,
    cancelable: true,
    ...init,
  });
  target.dispatchEvent(event);
  return event;
}

const visible = (el) => !el.hidden;

test("renders the first enabled item, progress and actions", () => {
  const { el, item, button } = build();

  assert.equal(el.dataset.current, "1");
  assert.equal(el.dataset.total, "3");
  assert.ok(el.hasAttribute("data-first"));
  assert.ok(el.hasAttribute("data-required"));
  assert.equal(el.dataset.status, "unanswered");

  assert.ok(visible(item("direction")));
  assert.ok(item("direction").hasAttribute("data-active"));
  assert.ok(!visible(item("signals")));
  assert.ok(item("signals").hasAttribute("inert"));

  const progress = el.querySelector('[data-part="progress"]');
  assert.equal(progress.textContent, "Question 1 of 3");
  assert.equal(progress.getAttribute("aria-valuenow"), "1");
  assert.equal(progress.getAttribute("aria-valuemax"), "3");
  assert.equal(progress.getAttribute("role"), "progressbar");

  assert.ok(!visible(button("previous")));
  assert.ok(!visible(button("skip")), "required item has no Skip");
  assert.ok(visible(button("next")));
  assert.equal(button("next").getAttribute("aria-keyshortcuts"), "Enter");
  assert.ok(!visible(button("submit")));

  assert.equal(
    item("direction").getAttribute("aria-describedby"),
    "q-direction-description",
  );
  assert.equal(
    el.querySelector('[data-part="active-input"]').value,
    "direction",
  );
});

test("Next on an unanswered required item shows the error and stays", () => {
  const { item, button, pushed } = build();

  button("next").click();

  assert.equal(submissions.length, 0, "navigation never reaches the server");
  assert.ok(visible(item("direction")));
  assert.ok(item("direction").hasAttribute("data-invalid"));
  assert.equal(item("direction").getAttribute("aria-invalid"), "true");
  const error = item("direction").querySelector('[data-part="error"]');
  assert.ok(visible(error));
  assert.equal(error.getAttribute("role"), "alert");
  assert.match(
    item("direction").getAttribute("aria-describedby"),
    /q-direction-error/,
  );
  assert.equal(
    document.activeElement,
    item("direction").querySelector("input"),
  );
  assert.equal(pushed.length, 0);
});

test("answering clears the error; Next moves on and reports it", () => {
  const { el, item, button, choice, pushed } = build();

  button("next").click();
  pick(choice("direction", "b"));

  assert.ok(!item("direction").hasAttribute("data-invalid"));
  assert.equal(item("direction").dataset.status, "answered");
  assert.ok(
    choice("direction", "b").closest("label").hasAttribute("data-checked"),
  );
  assert.deepEqual(pushed.at(-1), {
    event: "status_changed",
    payload: {
      item: "direction",
      status: "answered",
      componentId: "q",
      component: "questionnaire",
    },
  });

  button("next").click();

  assert.ok(!visible(item("direction")));
  assert.ok(visible(item("signals")));
  assert.equal(document.activeElement, item("signals"));
  assert.equal(el.dataset.current, "2");
  assert.ok(visible(button("previous")));
  assert.ok(visible(button("skip")), "optional item can be skipped");
  assert.equal(el.querySelector('[data-part="active-input"]').value, "signals");
  assert.ok(
    pushed.some(
      (p) => p.event === "item_changed" && p.payload.item === "signals",
    ),
  );
  assert.equal(submissions.length, 0);
});

test("Skip clears the answers, records the skip and moves on", () => {
  const { el, item, button, choice, q } = build();

  pick(choice("direction", "a"));
  button("next").click();
  pick(choice("signals", "x"));
  button("skip").click();

  assert.equal(choice("signals", "x").checked, false);
  assert.equal(item("signals").dataset.status, "skipped");
  assert.ok(visible(item("timing")));
  const skippedInputs = el.querySelectorAll('[data-part="skipped-input"]');
  assert.deepEqual(
    Array.from(skippedInputs).map((input) => input.value),
    ["signals"],
  );
  assert.ok(el.hasAttribute("data-last"));
  assert.ok(visible(button("submit")));
  assert.ok(!visible(button("next")));

  // Answering a skipped item un-skips it.
  q.setActive("signals");
  pick(choice("signals", "y"));
  assert.equal(item("signals").dataset.status, "answered");
  assert.equal(el.querySelectorAll('[data-part="skipped-input"]').length, 0);
});

test("Previous moves back without validating", () => {
  const { item, button, choice } = build();

  pick(choice("direction", "a"));
  button("next").click();
  button("previous").click();

  assert.ok(visible(item("direction")));
  assert.equal(submissions.length, 0);
});

test("Submit validates every item and opens the first invalid one", () => {
  const { item, button, choice, q } = build();

  q.setActive("timing");
  pick(choice("timing", "now"));
  button("submit").click();

  assert.equal(submissions.length, 0);
  assert.ok(visible(item("direction")));
  assert.ok(item("direction").hasAttribute("data-invalid"));
  assert.equal(document.activeElement, choice("direction", "a"));
});

test("an unanswered optional item blocks submit until skipped", () => {
  const { item, button, choice, q } = build();

  pick(choice("direction", "a"));
  q.setActive("timing");
  pick(choice("timing", "now"));
  button("submit").click();

  assert.equal(submissions.length, 0);
  assert.ok(visible(item("signals")));
  assert.ok(item("signals").hasAttribute("data-invalid"));

  button("skip").click();
  button("submit").click();

  assert.equal(submissions.length, 1);
  const { action, data } = submissions[0];
  assert.equal(action, "submit");
  assert.deepEqual(data.getAll("direction[]"), ["a"]);
  assert.deepEqual(data.getAll("signals[]"), []);
  assert.deepEqual(data.getAll("_questionnaire[skipped][]"), ["signals"]);
  assert.equal(data.get("timing[]"), "now");
  assert.equal(data.get("_questionnaire[item]"), "timing");
});

test("Skip on the last item submits", () => {
  const items = [
    { name: "scope", required: true, choices: ["a"] },
    { name: "notes", choices: ["x"] },
  ];
  const { button, choice } = build({ items });

  pick(choice("scope", "a"));
  button("next").click();
  button("skip").click();

  assert.equal(submissions.length, 1);
  assert.equal(submissions[0].action, "skip");
  assert.deepEqual(submissions[0].data.getAll("_questionnaire[skipped][]"), [
    "notes",
  ]);
});

test("freeform text and a fixed choice replace each other in a single item", () => {
  const { item, choice, el } = build();
  const input = item("direction").querySelector('[data-part="input"]');

  assert.equal(
    input.hasAttribute("name"),
    false,
    "empty input is not an answer",
  );

  pick(choice("direction", "a"));
  type(input, "Something else");

  assert.equal(choice("direction", "a").checked, false);
  assert.equal(input.getAttribute("name"), "direction[]");
  assert.ok(input.hasAttribute("data-filled"));
  assert.deepEqual(new window.FormData(el).getAll("direction[]"), [
    "Something else",
  ]);

  pick(choice("direction", "b"));

  assert.equal(input.hasAttribute("name"), false);
  assert.equal(input.value, "Something else", "text stays visible");
  assert.deepEqual(new window.FormData(el).getAll("direction[]"), ["b"]);
});

test("a server-rendered freeform answer is kept", () => {
  const items = [
    {
      name: "direction",
      required: true,
      choices: ["a"],
      input: true,
      inputValue: "Mine",
      status: "answered",
    },
  ];
  const { item } = build({ items });
  const input = item("direction").querySelector('[data-part="input"]');
  assert.equal(input.getAttribute("name"), "direction[]");
  assert.equal(item("direction").dataset.status, "answered");
});

test("letter shortcuts select answers in the active item", () => {
  const { item, choice } = build({ shortcuts: "letters" });
  const labels = item("direction").querySelectorAll('[data-part="choice"]');

  assert.equal(labels[0].dataset.shortcut, "A");
  assert.equal(labels[1].dataset.shortcut, "B");
  const hint = labels[1].querySelector('[data-part="choice-shortcut"]');
  assert.equal(hint.textContent, "B");
  assert.ok(visible(hint));
  assert.equal(choice("direction", "b").getAttribute("aria-keyshortcuts"), "B");

  const event = key(item("direction"), "b");

  assert.ok(event.defaultPrevented);
  assert.equal(choice("direction", "b").checked, true);
  assert.equal(document.activeElement, choice("direction", "b"));
  assert.equal(
    choice("direction", "b").getAttribute("aria-keyshortcuts"),
    "B Enter",
  );
});

test("shortcuts pause while typing", () => {
  const { item, choice } = build({ shortcuts: "letters" });
  const input = item("direction").querySelector('[data-part="input"]');

  const event = key(input, "a");

  assert.equal(event.defaultPrevented, false);
  assert.equal(choice("direction", "a").checked, false);
});

test("Enter on a selected answer continues; Cmd+Enter validates", () => {
  const { item, choice } = build();

  key(item("direction"), "Enter", { metaKey: true });
  assert.ok(item("direction").hasAttribute("data-invalid"));

  pick(choice("direction", "a"));
  const event = key(choice("direction", "a"), "Enter");

  assert.ok(event.defaultPrevented);
  assert.ok(visible(item("signals")));
});

test("ArrowDown/ArrowUp move between answers; arrows left/right move items", () => {
  const { item, choice } = build();
  const input = item("direction").querySelector('[data-part="input"]');

  key(item("direction"), "ArrowDown");
  assert.equal(document.activeElement, choice("direction", "a"));
  assert.equal(
    choice("direction", "a").checked,
    true,
    "radios select on focus",
  );

  // Between radios the browser's own arrow handling applies.
  const between = key(choice("direction", "a"), "ArrowDown");
  assert.equal(between.defaultPrevented, false);

  // From an empty freeform input, ArrowUp moves to the previous answer.
  input.focus();
  key(input, "ArrowUp");
  assert.equal(document.activeElement, choice("direction", "b"));
  assert.equal(choice("direction", "b").checked, true);

  // ArrowRight from the fieldset once answered.
  item("direction").focus();
  key(item("direction"), "ArrowRight");
  assert.ok(visible(item("signals")));

  key(item("signals"), "ArrowLeft");
  assert.ok(visible(item("direction")));
});

test("under rtl ArrowLeft goes forward and ArrowRight goes back", () => {
  document.documentElement.setAttribute("dir", "rtl");
  try {
    const { item, choice } = build();
    choice("direction", "a").click();
    item("direction").focus();
    assert.equal(
      item("direction").getAttribute("aria-keyshortcuts"),
      "Meta+Enter Control+Enter ArrowUp ArrowDown ArrowLeft",
    );

    key(item("direction"), "ArrowRight");
    assert.ok(visible(item("direction")), "ArrowRight is back under rtl");

    key(item("direction"), "ArrowLeft");
    assert.ok(visible(item("signals")));
    assert.match(
      item("signals").getAttribute("aria-keyshortcuts"),
      / ArrowRight/,
    );

    key(item("signals"), "ArrowRight");
    assert.ok(visible(item("direction")));
  } finally {
    document.documentElement.removeAttribute("dir");
  }
});

test("ArrowRight does nothing while the item is unanswered", () => {
  const { item } = build();
  key(item("direction"), "ArrowRight");
  assert.ok(visible(item("direction")));
  assert.ok(!item("direction").hasAttribute("data-invalid"));
});

test("disabled items are left out of progress and navigation", () => {
  const items = [
    { name: "runtime", required: true, choices: ["local", "remote"] },
    { name: "region", required: true, disabled: true, choices: ["us"] },
    { name: "approval", required: true, choices: ["ask"] },
  ];
  const { el, item, button, choice } = build({ items });

  assert.equal(el.dataset.total, "2");
  pick(choice("runtime", "local"));
  button("next").click();
  assert.ok(visible(item("approval")));
  assert.ok(!visible(item("region")));
  assert.equal(el.dataset.current, "2");
});

test("custom progress content is kept and its markers are updated", () => {
  const progress = `
    <div data-part="progress">
      <span data-progress-step="1"></span><span data-progress-step="2"></span><span data-progress-step="3"></span>
      Checkpoint <span data-progress-current>1</span> of <span data-progress-total>3</span>
    </div>`;
  const { el, button, choice } = build({ progress });

  pick(choice("direction", "a"));
  button("next").click();

  const node = el.querySelector('[data-part="progress"]');
  assert.equal(node.querySelector("[data-progress-current]").textContent, "2");
  assert.equal(node.querySelector("[data-progress-total]").textContent, "3");
  const steps = node.querySelectorAll("[data-progress-step]");
  assert.deepEqual(
    Array.from(steps).map((s) => s.hasAttribute("data-complete")),
    [true, true, false],
  );
  assert.match(node.textContent, /Checkpoint/);
});

test("client state survives a rebuild (LiveView patch)", () => {
  const { button, choice } = build();

  pick(choice("direction", "a"));
  button("next").click();
  button("skip").click();

  const { item } = mount();

  assert.ok(visible(item("timing")));
  assert.equal(item("signals").dataset.status, "skipped");
});

test("form reset restores the initial item, defaults and skips", async () => {
  const { el, item, button, choice } = build({ item: "direction" });

  pick(choice("direction", "a"));
  button("next").click();
  button("skip").click();
  assert.ok(visible(item("timing")));

  el.reset();

  await waitFor(() => visible(item("direction")));
  assert.equal(choice("direction", "a").checked, false);
  assert.equal(item("signals").dataset.status, "unanswered");
  assert.equal(el.querySelectorAll('[data-part="skipped-input"]').length, 0);
});

test("form reset restores server-rendered skips and errors, even after a rebuild", async () => {
  const { el, item, choice } = build({
    item: "signals",
    items: [
      DEFAULT_ITEMS[0],
      { ...DEFAULT_ITEMS[1], status: "skipped" },
      { ...DEFAULT_ITEMS[2], invalid: true },
    ],
    skipped: ["signals"],
  });

  pick(choice("signals", "x"));
  assert.equal(item("signals").dataset.status, "answered");
  pick(choice("timing", "now"));
  assert.ok(!item("timing").hasAttribute("data-invalid"));

  // a LiveView patch rebuilds the component from the mutated DOM
  mount();
  el.reset();

  await waitFor(() => item("signals").dataset.status === "skipped");
  assert.equal(choice("signals", "x").checked, false);
  assert.ok(item("timing").hasAttribute("data-invalid"));
  assert.deepEqual(
    Array.from(el.querySelectorAll('[data-part="skipped-input"]')).map(
      (input) => input.value,
    ),
    ["signals"],
  );
});

test("descriptions and errors without ids are still linked to the item", () => {
  const { el, item, button } = build({ item: "direction" });
  const fieldset = item("direction");
  fieldset
    .querySelectorAll('[data-part="description"], [data-part="error"]')
    .forEach((node) => {
      node.removeAttribute("id");
    });

  button("next").click();

  const description = fieldset.querySelector('[data-part="description"]');
  const error = fieldset.querySelector('[data-part="error"]');
  assert.ok(description.id && error.id);
  assert.equal(
    fieldset.getAttribute("aria-describedby"),
    `${description.id} ${error.id}`,
  );
  assert.equal(el.querySelectorAll(`#${description.id}`).length, 1);
});

test("server-driven: validates the active item, then lets the server move", () => {
  const { item, button, choice, el } = build({
    item: "direction",
    serverDriven: true,
  });

  button("next").click();
  assert.equal(submissions.length, 0);
  assert.ok(item("direction").hasAttribute("data-invalid"));

  pick(choice("direction", "a"));
  button("next").click();

  assert.equal(submissions.length, 1);
  assert.equal(submissions[0].action, "next");
  assert.equal(submissions[0].data.get("_questionnaire[action]"), "next");
  assert.equal(submissions[0].data.get("_questionnaire[item]"), "direction");
  assert.ok(visible(item("direction")), "the server decides the next item");

  // The server answers with the next item active: the rebuilt component
  // focuses it.
  el.setAttribute(
    "data-options",
    JSON.stringify({ item: "signals", serverDriven: true }),
  );
  const rebuilt = mount();
  assert.ok(visible(rebuilt.item("signals")));
  assert.equal(document.activeElement, rebuilt.item("signals"));
});

test("server-driven: Previous and Skip go straight to the server", () => {
  const { button } = build({ item: "signals", serverDriven: true });

  button("skip").click();
  button("previous").click();

  assert.deepEqual(
    submissions.map((s) => s.action),
    ["skip", "previous"],
  );
});

test("server-driven: keyboard navigation submits the matching action", () => {
  const { item, choice } = build({ item: "direction", serverDriven: true });

  pick(choice("direction", "a"));
  key(choice("direction", "a"), "Enter");

  assert.equal(submissions.length, 1);
  assert.equal(submissions[0].data.get("_questionnaire[action]"), "continue");
  assert.equal(
    document.querySelector('[data-part="default-action"]').value,
    "continue",
  );
  assert.ok(visible(item("direction")));
});

test("server-driven: server-rendered skips and errors are kept", () => {
  const items = [
    { name: "direction", required: true, choices: ["a"], invalid: true },
    { name: "signals", multiple: true, choices: ["x"], status: "skipped" },
  ];
  const { item, el } = build({
    items,
    item: "direction",
    serverDriven: true,
    skipped: ["signals"],
  });

  assert.ok(item("direction").hasAttribute("data-invalid"));
  assert.equal(item("signals").dataset.status, "skipped");
  assert.equal(el.querySelectorAll('[data-part="skipped-input"]').length, 1);
});

test("commands drive navigation", () => {
  const { item, choice, el } = build();

  pick(choice("direction", "a"));
  el.dispatchEvent(
    new CustomEvent("salad_ui:command", { detail: { command: "next" } }),
  );
  assert.ok(visible(item("signals")));

  el.dispatchEvent(
    new CustomEvent("salad_ui:command", {
      detail: { command: "goto", params: { item: "timing" } },
    }),
  );
  assert.ok(visible(item("timing")));

  el.dispatchEvent(
    new CustomEvent("salad_ui:command", { detail: { command: "previous" } }),
  );
  assert.ok(visible(item("signals")));
});

test("a server-rendered error on an answered item holds until it changes", () => {
  const items = [
    {
      name: "detail",
      required: true,
      choices: ["summary", "complete"],
      checked: ["summary"],
      status: "answered",
      invalid: true,
    },
    { name: "audience", required: true, choices: ["team", "public"] },
  ];
  const { item, button, choice } = build({
    items,
    item: "detail",
    serverDriven: true,
  });

  assert.ok(item("detail").hasAttribute("data-invalid"));
  assert.ok(visible(item("detail").querySelector('[data-part="error"]')));

  button("next").click();
  assert.equal(submissions.length, 0, "still invalid: no round trip");

  pick(choice("detail", "complete"));
  assert.ok(!item("detail").hasAttribute("data-invalid"));

  button("next").click();
  assert.equal(submissions.length, 1);
});
