import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import {
  moveDate,
  parseISODate,
  toISODate,
} from "../salad_ui/components/calendar.js";
import "../salad_ui/components/popover.js";
import { SaladUIHook } from "../salad_ui/core/hook.js";
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  document.body.innerHTML = "";
});

const iso = (y, m, d) =>
  `${y}-${String(m).padStart(2, "0")}-${String(d).padStart(2, "0")}`;

// A server-rendered June 2025 grid (Sunday first): June 1st is a Sunday,
// June 30th a Monday, so the last row holds July 1-5 as outside days.
function monthGrid({ tabDate = "2025-06-12", disabled = [] } = {}) {
  const cells = [];
  for (let d = 1; d <= 30; d++) cells.push([iso(2025, 6, d), false]);
  for (let d = 1; d <= 5; d++) cells.push([iso(2025, 7, d), true]);

  const rows = [];
  for (let i = 0; i < cells.length; i += 7) {
    const tds = cells
      .slice(i, i + 7)
      .map(
        ([day, outside]) => `
        <td role="gridcell" data-day="${day}" ${outside ? 'data-outside="true"' : ""}>
          <button type="button" data-slot="calendar-day-button" data-day="${day}"
            tabindex="${day === tabDate ? "0" : "-1"}"
            ${disabled.includes(day) ? "disabled" : ""}>${Number(day.slice(8))}</button>
        </td>`,
      )
      .join("");
    rows.push(`<tr>${tds}</tr>`);
  }
  return `<table role="grid" data-part="grid"><tbody>${rows.join("")}</tbody></table>`;
}

function buildCalendar({
  value = null,
  options = {},
  mappings = {},
  grid = {},
  dir = null,
  inPopover = false,
} = {}) {
  const opts = JSON.stringify({
    mode: "single",
    weekStartsOn: 0,
    closeOnSelect: false,
    min: null,
    max: null,
    inputs: "cal-value",
    ...options,
  });

  const calendar = `
    <div id="cal" data-component="calendar" data-part="root" data-state="idle"
         data-value='${JSON.stringify(value)}' data-selection-seq="0"
         data-options='${opts}'
         data-event-mappings='${JSON.stringify(mappings)}'>
      <select data-part="month-select" data-index="0" data-year="2025">
        <option value="5">May</option><option value="6" selected>Jun</option>
      </select>
      <select data-part="year-select" data-index="0" data-month="6">
        <option value="2024">2024</option><option value="2025" selected>2025</option>
      </select>
      ${monthGrid(grid)}
      <div id="cal-value" hidden><input type="text" hidden name="date" value="${value || ""}"></div>
    </div>`;

  const inner = inPopover
    ? `<div id="pop" data-component="popover" data-state="open" data-part="root">
         <button data-part="trigger" data-action="toggle" type="button">Open</button>
         <div data-part="positioner"><div data-part="content">${calendar}</div></div>
       </div>`
    : calendar;

  document.body.innerHTML = `
    <div id="owner" ${dir ? `dir="${dir}"` : ""}>
      <div data-phx-component="1" id="component-root">${inner}</div>
    </div>`;

  const el = document.getElementById("cal");
  const pushed = [];
  const executed = [];
  const hook = {
    ...SaladUIHook,
    el,
    pushEventTo: (target, event, payload, onReply) => {
      replies.push(onReply);
      pushed.push({ target, event, payload });
    },
    handleEvent() {},
    liveSocket: { execJS: (target, js) => executed.push({ target, js }) },
  };
  const replies = [];
  hook.mounted();

  return { el, hook, pushed, executed, replies };
}

function button(el, day) {
  return el.querySelector(`button[data-day="${day}"]`);
}

function key(target, keyName, extra = {}) {
  const event = new window.KeyboardEvent("keydown", {
    key: keyName,
    bubbles: true,
    cancelable: true,
    ...extra,
  });
  target.dispatchEvent(event);
  return event;
}

function click(target) {
  target.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
}

// Stands in for the server's re-render after a LiveView event: swap the
// calendar markup, then run the hook's update cycle. `picked` is a re-render
// after a pick by the user, which bumps data-selection-seq.
function patch(hook, { value, tabDate, grid = {}, picked = false }) {
  const el = hook.el;
  hook.beforeUpdate();
  el.setAttribute("data-value", JSON.stringify(value));
  if (picked) {
    const seq = Number(el.getAttribute("data-selection-seq")) + 1;
    el.setAttribute("data-selection-seq", String(seq));
  }
  el.querySelector("table").outerHTML = monthGrid({ tabDate, ...grid });
  el.querySelector("#cal-value input").value = value || "";
  hook.updated();
}

test("date helpers move like react-day-picker", () => {
  const d = parseISODate("2025-01-31");

  assert.equal(toISODate(moveDate(d, "day", 1)), "2025-02-01");
  assert.equal(toISODate(moveDate(d, "week", -1)), "2025-01-24");
  assert.equal(toISODate(moveDate(d, "month", 1)), "2025-02-28");
  assert.equal(toISODate(moveDate(d, "year", -1)), "2024-01-31");
  // Friday Jan 31st 2025: the week runs Sun 26 - Sat Feb 1, or Mon 27 - Sun 2.
  assert.equal(toISODate(moveDate(d, "startOfWeek", -1)), "2025-01-26");
  assert.equal(toISODate(moveDate(d, "endOfWeek", 1)), "2025-02-01");
  assert.equal(toISODate(moveDate(d, "startOfWeek", -1, 1)), "2025-01-27");
  assert.equal(toISODate(moveDate(d, "endOfWeek", 1, 1)), "2025-02-02");
  assert.equal(parseISODate("nope"), null);
});

test("arrow keys move focus and the roving tabindex", () => {
  const { el, hook } = buildCalendar();
  const start = button(el, "2025-06-12");
  start.focus();

  key(start, "ArrowRight");
  const next = button(el, "2025-06-13");
  assert.equal(document.activeElement, next);
  assert.equal(next.getAttribute("tabindex"), "0");
  assert.equal(start.getAttribute("tabindex"), "-1");
  assert.equal(next.parentElement.getAttribute("data-focused"), "true");
  assert.equal(start.parentElement.hasAttribute("data-focused"), false);

  key(next, "ArrowDown");
  assert.equal(document.activeElement, button(el, "2025-06-20"));

  key(document.activeElement, "Home");
  assert.equal(document.activeElement, button(el, "2025-06-15"));

  key(document.activeElement, "End");
  assert.equal(document.activeElement, button(el, "2025-06-21"));

  hook.destroyed();
});

test("disabled days are skipped", () => {
  const { el, hook } = buildCalendar({
    grid: { disabled: ["2025-06-13", "2025-06-14"] },
  });
  button(el, "2025-06-12").focus();

  key(document.activeElement, "ArrowRight");
  assert.equal(document.activeElement, button(el, "2025-06-15"));

  hook.destroyed();
});

test("left and right are mirrored in rtl", () => {
  const { el, hook } = buildCalendar({ dir: "rtl" });
  button(el, "2025-06-12").focus();

  key(document.activeElement, "ArrowLeft");
  assert.equal(document.activeElement, button(el, "2025-06-13"));

  hook.destroyed();
});

test("leaving the visible month asks the server and focuses its answer", () => {
  const { el, hook, pushed, replies } = buildCalendar();
  button(el, "2025-06-30").focus();

  // July 1st is rendered, but as an outside day: it does not count.
  const event = key(document.activeElement, "ArrowRight");
  assert.equal(event.defaultPrevented, true);
  assert.deepEqual(pushed, [
    { target: el, event: "focus", payload: { date: "2025-07-01", dir: 1 } },
  ]);

  // The server answers with the next month and July 1st as the tab stop;
  // the fixture reuses June's markup, so stand in with June 2nd. LiveView
  // calls the reply callback once the patch is in.
  patch(hook, { value: null, tabDate: "2025-06-02" });
  replies.at(-1)();
  assert.equal(document.activeElement, button(el, "2025-06-02"));

  key(document.activeElement, "PageUp");
  assert.deepEqual(pushed.at(-1).payload, { date: "2025-05-02", dir: -1 });

  key(document.activeElement, "PageDown", { shiftKey: true });
  assert.deepEqual(pushed.at(-1).payload, { date: "2026-06-02", dir: 1 });

  hook.destroyed();
});

test("a focus reply without a patch, or after focus left, keeps focus put", () => {
  const { el, hook, replies } = buildCalendar();
  const outside = document.createElement("button");
  document.body.appendChild(outside);

  // The server could not show the month (e.g. past end-month): no patch.
  button(el, "2025-06-30").focus();
  key(document.activeElement, "ArrowRight");
  replies.at(-1)();
  assert.equal(document.activeElement, button(el, "2025-06-30"));

  // The user tabbed away before the answer arrived.
  key(document.activeElement, "PageDown");
  outside.focus();
  patch(hook, { value: null, tabDate: "2025-06-02" });
  replies.at(-1)();
  assert.equal(document.activeElement, outside);

  hook.destroyed();
});

test("a patch keeps the roving tabindex and focus ring on the focused day", () => {
  const { el, hook } = buildCalendar();
  const focused = button(el, "2025-06-13");
  focused.focus();

  // An unrelated re-render morphs the day attributes back to the server's
  // view (the 12th is the tab stop, no day is data-focused); the focused
  // element itself stays in place.
  hook.beforeUpdate();
  focused.setAttribute("tabindex", "-1");
  focused.parentElement.removeAttribute("data-focused");
  button(el, "2025-06-12").setAttribute("tabindex", "0");
  hook.updated();
  assert.equal(focused.getAttribute("tabindex"), "0");
  assert.equal(button(el, "2025-06-12").getAttribute("tabindex"), "-1");
  assert.equal(focused.parentElement.getAttribute("data-focused"), "true");

  hook.destroyed();
});

test("focus moves stop at min and max", () => {
  const { el, hook, pushed } = buildCalendar({
    options: { min: "2025-06-10" },
  });
  button(el, "2025-06-10").focus();

  key(document.activeElement, "ArrowLeft");
  assert.equal(document.activeElement, button(el, "2025-06-10"));
  assert.deepEqual(pushed, []);

  hook.destroyed();
});

test("a user selection notifies the form, the parent and the popover", async () => {
  const { el, hook, pushed } = buildCalendar({
    mappings: { select: "date_picked" },
    options: { closeOnSelect: true },
    inPopover: true,
  });
  const popover = document.getElementById("pop");
  const popoverHook = {
    ...SaladUIHook,
    el: popover,
    pushEventTo() {},
    handleEvent() {},
  };
  popoverHook.mounted();
  assert.equal(popoverHook.component.state, "open");

  const inputEvents = [];
  document.addEventListener("input", (e) => inputEvents.push(e.target));

  click(button(el, "2025-06-03"));
  // phx-click goes to the server, which re-renders with the new value.
  patch(hook, { value: "2025-06-03", tabDate: "2025-06-03", picked: true });

  assert.equal(inputEvents.length, 1);
  assert.equal(inputEvents[0].name, "date");
  assert.deepEqual(pushed, [
    {
      target: document.getElementById("owner"),
      event: "date_picked",
      payload: { id: "cal", value: "2025-06-03" },
    },
  ]);
  await waitFor(() => popoverHook.component.state === "closed");

  popoverHook.destroyed();
  hook.destroyed();
});

test("server-driven value changes and no-op picks do not notify", () => {
  const { el, hook, pushed } = buildCalendar({
    value: "2025-06-03",
    mappings: { select: "date_picked" },
  });

  patch(hook, { value: "2025-06-09", tabDate: "2025-06-09" });
  assert.deepEqual(pushed, []);

  // A pick that leaves the value as it was (e.g. `required`).
  click(button(el, "2025-06-09"));
  patch(hook, { value: "2025-06-09", tabDate: "2025-06-09", picked: true });
  assert.deepEqual(pushed, []);

  // That pick must not leave anything pending for the parent's next value.
  patch(hook, { value: "2025-06-20", tabDate: "2025-06-20" });
  assert.deepEqual(pushed, []);

  hook.destroyed();
});

test("JS command handlers run against the parent", () => {
  const command = [["push", { event: "picked" }]];
  const { el, hook, executed } = buildCalendar({
    options: { mode: "range" },
    mappings: { select: command },
  });

  click(button(el, "2025-06-03"));
  patch(hook, {
    value: { from: "2025-06-03", to: "2025-06-03" },
    tabDate: "2025-06-03",
    picked: true,
  });

  assert.deepEqual(executed, [
    { target: document.getElementById("owner"), js: JSON.stringify(command) },
  ]);

  hook.destroyed();
});

test("range close-on-select waits for a range of two days or more", async () => {
  const { el, hook } = buildCalendar({
    options: { mode: "range", closeOnSelect: true },
    inPopover: true,
  });
  const popover = document.getElementById("pop");
  const commands = [];
  popover.addEventListener("salad_ui:command", (e) => commands.push(e.detail));

  click(button(el, "2025-06-03"));
  patch(hook, {
    value: { from: "2025-06-03", to: "2025-06-03" },
    tabDate: "2025-06-03",
    picked: true,
  });
  assert.deepEqual(commands, []);

  click(button(el, "2025-06-08"));
  patch(hook, {
    value: { from: "2025-06-03", to: "2025-06-08" },
    tabDate: "2025-06-08",
    picked: true,
  });
  assert.deepEqual(commands, [{ command: "close", target: "pop" }]);

  hook.destroyed();
});

test("caption dropdowns navigate without reaching a surrounding form", () => {
  const { el, hook, pushed } = buildCalendar();
  const seen = [];
  document.addEventListener("change", (e) => seen.push(e.type));
  document.addEventListener("input", (e) => seen.push(e.type));

  const month = el.querySelector('[data-part="month-select"]');
  month.value = "5";
  month.dispatchEvent(new window.Event("input", { bubbles: true }));
  month.dispatchEvent(new window.Event("change", { bubbles: true }));

  const year = el.querySelector('[data-part="year-select"]');
  year.value = "2024";
  year.dispatchEvent(new window.Event("change", { bubbles: true }));

  assert.deepEqual(seen, []);
  assert.deepEqual(
    pushed.map((p) => [p.event, p.payload]),
    [
      ["goto", { month: "2025-05-01", index: 0 }],
      ["goto", { month: "2024-06-01", index: 0 }],
    ],
  );

  hook.destroyed();
});
