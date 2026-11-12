import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import InputOTPComponent from "../salad_ui/components/input_otp.js";
import { installDom, setRect, uninstallDom } from "./helpers/dom.mjs";

let current = null;

before(() => installDom());
after(() => {
  current?.destroy();
  uninstallDom();
});

function slotHtml(index) {
  return `
    <div data-slot="input-otp-slot" data-part="slot" data-index="${index}" data-active="false">
      <span data-part="slot-char"></span>
      <div data-part="caret" hidden><div></div></div>
    </div>`;
}

function build({
  maxLength = 6,
  value = "",
  pattern = null,
  disabled = false,
} = {}) {
  current?.destroy();
  current = null;
  const slots = Array.from({ length: maxLength }, (_, i) => slotHtml(i));
  document.body.innerHTML = `
    <form id="form">
      <div
        id="otp"
        data-component="input-otp"
        data-part="root"
        data-state="idle"
        data-options='${JSON.stringify({ maxLength, pattern, disabled })}'
        data-event-mappings='{"value-changed":"otp_changed","complete":"otp_complete"}'
      >
        <div data-slot="input-otp-group">${slots.join("")}</div>
        <div>
          <input type="text" id="otp-input" name="code" value="${value}"
            maxlength="${maxLength}" data-part="input" data-slot="input-otp"
            ${disabled ? "disabled" : ""} />
        </div>
      </div>
    </form>
  `;

  const el = document.getElementById("otp");
  const input = el.querySelector('[data-part="input"]');
  const pushed = [];
  const hookContext = {
    pushEventTo(_el, event, payload) {
      pushed.push({ event, payload });
    },
  };

  const otp = new InputOTPComponent(el, hookContext);
  otp.setupEvents();
  otp.afterMount();
  current = otp;

  const slotEls = [...el.querySelectorAll('[data-part="slot"]')];
  return { el, input, otp, pushed, slotEls };
}

const chars = (slotEls) =>
  slotEls
    .map((s) => s.querySelector('[data-part="slot-char"]').textContent)
    .join("|");
const active = (slotEls) =>
  slotEls.map((s) => s.getAttribute("data-active") === "true");
const carets = (slotEls) =>
  slotEls.map((s) => !s.querySelector('[data-part="caret"]').hidden);

// Simulate the browser inserting text at the caret, then firing `input`.
function type(input, text) {
  const v = input.value;
  const start = input.selectionStart ?? v.length;
  const end = input.selectionEnd ?? v.length;
  const next = v.slice(0, start) + text + v.slice(end);
  if (next.length > input.maxLength) return; // native maxlength blocks it
  input.value = next;
  input.setSelectionRange(start + text.length, start + text.length);
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
}

function paste(input, text) {
  const event = new window.Event("paste", { bubbles: true, cancelable: true });
  event.clipboardData = { getData: () => text };
  input.dispatchEvent(event);
  return event;
}

test("renders slot characters from the real input's value", () => {
  const { slotEls, el } = build({ value: "12" });

  assert.equal(chars(slotEls), "1|2||||");
  assert.deepEqual(active(slotEls), [false, false, false, false, false, false]);
  assert.equal(slotEls[0].getAttribute("aria-hidden"), "true");
  assert.equal(el.getAttribute("data-state"), "idle");
});

test("focus activates the next empty slot and shows the fake caret", () => {
  const { input, slotEls, el } = build({ value: "12" });

  input.focus();

  assert.equal(el.getAttribute("data-state"), "focused");
  assert.deepEqual(active(slotEls), [false, false, true, false, false, false]);
  assert.deepEqual(carets(slotEls), [false, false, true, false, false, false]);

  input.blur();
  assert.equal(el.getAttribute("data-state"), "idle");
  assert.deepEqual(carets(slotEls), [false, false, false, false, false, false]);
});

test("focusing a full input selects the last character", () => {
  const { input, slotEls } = build({ value: "123456" });

  input.focus();

  assert.equal(input.selectionStart, 5);
  assert.equal(input.selectionEnd, 6);
  assert.deepEqual(active(slotEls), [false, false, false, false, false, true]);
  assert.deepEqual(carets(slotEls), [false, false, false, false, false, false]);
});

test("typing fills slots, pushes value-changed and complete once", () => {
  const { input, slotEls, pushed } = build({ maxLength: 4 });
  input.focus();

  for (const ch of "1234") type(input, ch);

  assert.equal(chars(slotEls), "1|2|3|4");
  assert.deepEqual(
    pushed.map((p) => [p.event, p.payload.value]),
    [
      ["otp_changed", "1"],
      ["otp_changed", "12"],
      ["otp_changed", "123"],
      ["otp_changed", "1234"],
      ["otp_complete", "1234"],
    ],
  );
  // Once full, the last character is selected so typing replaces it.
  assert.equal(input.selectionStart, 3);
  assert.equal(input.selectionEnd, 4);
  assert.deepEqual(active(slotEls), [false, false, false, true]);

  type(input, "9");
  assert.equal(input.value, "1239");
  assert.equal(pushed.filter((p) => p.event === "otp_complete").length, 1);
});

test("a caret before a character selects it so typing replaces it", () => {
  const { input, slotEls } = build({ value: "1234" });
  input.focus();

  input.setSelectionRange(1, 1);
  document.dispatchEvent(new window.Event("selectionchange"));

  assert.equal(input.selectionStart, 1);
  assert.equal(input.selectionEnd, 2);
  assert.deepEqual(active(slotEls), [false, true, false, false, false, false]);

  type(input, "9");
  assert.equal(input.value, "1934");
});

test("pattern rejects invalid input and hides it from phx-change", () => {
  const { input, slotEls, pushed } = build({ pattern: "^\\d+$", value: "1" });
  const formInputs = [];
  document
    .getElementById("form")
    .addEventListener("input", () => formInputs.push(input.value));
  input.focus();

  type(input, "a");

  assert.equal(input.value, "1");
  assert.equal(chars(slotEls), "1|||||");
  assert.deepEqual(pushed, []);
  assert.deepEqual(formInputs, []);

  type(input, "2");
  assert.equal(input.value, "12");
  assert.deepEqual(formInputs, ["12"]);
});

test("paste fills from the caret, strips whitespace and truncates", () => {
  const { input, slotEls, pushed } = build({ pattern: "^\\d+$" });
  const formInputs = [];
  document
    .getElementById("form")
    .addEventListener("input", () => formInputs.push(input.value));
  input.focus();

  const event = paste(input, " 123 4567 ");

  assert.equal(event.defaultPrevented, true);
  assert.equal(input.value, "123456");
  assert.equal(chars(slotEls), "1|2|3|4|5|6");
  assert.deepEqual(formInputs, ["123456"]);
  assert.deepEqual(
    pushed.map((p) => p.event),
    ["otp_changed", "otp_complete"],
  );
});

test("paste that fails the pattern is ignored", () => {
  const { input, pushed } = build({ pattern: "^\\d+$", value: "12" });
  input.focus();

  const event = paste(input, "ab");

  assert.equal(event.defaultPrevented, true);
  assert.equal(input.value, "12");
  assert.deepEqual(pushed, []);
});

test("clicking a filled slot selects its character", () => {
  const { input, slotEls } = build({ value: "1234" });
  slotEls.forEach((slot, i) =>
    setRect(slot, { left: i * 40, right: i * 40 + 36, width: 36 }),
  );
  input.focus();

  input.dispatchEvent(new window.MouseEvent("mouseup", { clientX: 45 }));
  assert.equal(input.selectionStart, 1);
  assert.equal(input.selectionEnd, 2);
  assert.deepEqual(active(slotEls), [false, true, false, false, false, false]);

  // An empty slot puts the caret after the last character.
  input.dispatchEvent(new window.MouseEvent("mouseup", { clientX: 210 }));
  assert.equal(input.selectionStart, 4);
  assert.equal(input.selectionEnd, 4);
  assert.deepEqual(active(slotEls), [false, false, false, false, true, false]);
});

test("setValue and clear commands update slots without pushing", () => {
  const { otp, input, slotEls, pushed } = build();

  otp.handleCommand("setValue", { value: "98765" });
  assert.equal(input.value, "98765");
  assert.equal(chars(slotEls), "9|8|7|6|5|");

  otp.handleCommand("clear");
  assert.equal(input.value, "");
  assert.equal(chars(slotEls), "|||||");
  assert.deepEqual(pushed, []);
});

test("rebuilding while focused keeps the active slot", () => {
  const { el, input, otp, pushed } = build({ value: "12" });
  input.focus();
  otp.destroy();

  const rebuilt = new InputOTPComponent(el, {
    pushEventTo: (_el, event) => pushed.push(event),
  });
  rebuilt.setupEvents();
  rebuilt.afterMount();
  current = rebuilt;

  const slotEls = [...el.querySelectorAll('[data-part="slot"]')];
  assert.equal(el.getAttribute("data-state"), "focused");
  assert.deepEqual(active(slotEls), [false, false, true, false, false, false]);
});

test("destroy removes listeners", () => {
  const { input, otp, slotEls } = build();
  otp.destroy();

  input.focus();
  input.value = "1";
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
  document.dispatchEvent(new window.Event("selectionchange"));

  assert.equal(chars(slotEls), "|||||");
});
