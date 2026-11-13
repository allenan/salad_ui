import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import CodeBlockCopyButtonComponent from "../salad_ui/components/code_block.js";
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

const originalNavigator = Object.getOwnPropertyDescriptor(
  globalThis,
  "navigator",
);

before(() => installDom());
after(() => {
  uninstallDom();
  if (originalNavigator) {
    Object.defineProperty(globalThis, "navigator", originalNavigator);
  }
});

let components = [];
afterEach(() => {
  components.forEach((component) => component.destroy());
  components = [];
});

function stubClipboard({ fail = false } = {}) {
  const writes = [];
  Object.defineProperty(globalThis, "navigator", {
    configurable: true,
    value: {
      clipboard: {
        writeText(text) {
          writes.push(text);
          return fail ? Promise.reject(new Error("denied")) : Promise.resolve();
        },
      },
    },
  });
  return writes;
}

function build({ value, content = "", resetDelay = 30 } = {}) {
  const options = JSON.stringify({ value: value ?? null, resetDelay });

  document.body.innerHTML = `
    <div data-slot="code-block">
      <div data-slot="code-block-actions">
        <button
          id="copy"
          type="button"
          data-slot="code-block-copy-button"
          data-component="code-block-copy-button"
          data-part="root"
          data-state="idle"
          data-options='${options}'
          data-event-mappings='{"copy":"copied"}'
          aria-label="Copy"
        ></button>
        <span data-slot="code-block-copy-status" aria-live="polite"></span>
      </div>
      <pre data-slot="code-block-content"><code data-slot="code-block-code">${content}</code></pre>
    </div>
  `;

  const el = document.getElementById("copy");
  const pushed = [];
  const hookContext = {
    pushEventTo(target, event, payload) {
      pushed.push({ target, event, payload });
    },
    liveSocket: { execJS: () => {} },
  };

  const component = new CodeBlockCopyButtonComponent(el, hookContext);
  component.setupEvents();
  components.push(component);

  return {
    component,
    el,
    pushed,
    status: el.nextElementSibling,
  };
}

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
}

test("starts idle with a Copy label and an empty live region", () => {
  stubClipboard();
  const { el, status } = build({ value: "mix deps.get" });

  assert.equal(el.getAttribute("data-state"), "idle");
  assert.equal(el.getAttribute("aria-label"), "Copy");
  assert.equal(el.hasAttribute("data-copied"), false);
  assert.equal(status.textContent, "");
});

test("click copies value, announces Copied and pushes the copy event", async () => {
  const writes = stubClipboard();
  const { el, status, pushed } = build({ value: "mix deps.get" });

  click(el);
  await waitFor(() => el.getAttribute("data-state") === "copied");

  assert.deepEqual(writes, ["mix deps.get"]);
  assert.equal(el.getAttribute("aria-label"), "Copied");
  assert.equal(el.hasAttribute("data-copied"), true);
  assert.equal(status.textContent, "Copied");
  assert.deepEqual(pushed, [
    {
      target: el,
      event: "copied",
      payload: {
        value: "mix deps.get",
        componentId: "copy",
        component: "code-block-copy-button",
      },
    },
  ]);
});

test("resets to idle after the reset delay", async () => {
  stubClipboard();
  const { el, status } = build({ value: "x", resetDelay: 10 });

  click(el);
  await waitFor(() => el.getAttribute("data-state") === "copied");
  await waitFor(() => el.getAttribute("data-state") === "idle");

  assert.equal(el.getAttribute("aria-label"), "Copy");
  assert.equal(el.hasAttribute("data-copied"), false);
  assert.equal(status.textContent, "");
});

test("without a value, copies the content lines and keeps blank lines", async () => {
  const writes = stubClipboard();
  const line = (text) =>
    `<span data-slot="code-block-line"><span data-slot="code-block-line-content">${text}</span></span>`;
  const { el } = build({
    content: `${line("def a, do: 1")}\n  ${line("\n")}${line("def b, do: 2")}`,
  });

  click(el);
  await waitFor(() => writes.length === 1);

  assert.equal(writes[0], "def a, do: 1\n\ndef b, do: 2");
});

test("without a value or lines, copies the content text", async () => {
  const writes = stubClipboard();
  const { el } = build({ content: "$ npm test\nok" });

  click(el);
  await waitFor(() => writes.length === 1);

  assert.equal(writes[0], "$ npm test\nok");
});

test("a failed clipboard write stays idle", async () => {
  const writes = stubClipboard({ fail: true });
  const { el, status, pushed } = build({ value: "secret" });

  click(el);
  await waitFor(() => writes.length === 1);
  await Promise.resolve();
  await Promise.resolve();

  assert.equal(el.getAttribute("data-state"), "idle");
  assert.equal(status.textContent, "");
  assert.equal(pushed.length, 0);
});

test("destroy clears the pending reset", async () => {
  stubClipboard();
  const { el, component } = build({ value: "x", resetDelay: 10 });

  click(el);
  await waitFor(() => el.getAttribute("data-state") === "copied");
  assert.notEqual(component.resetTimer, null);

  component.destroy();
  components = [];

  assert.equal(component.resetTimer, null);
});

// Mimics a LiveView patch: morphdom puts back the server-rendered attributes
// of the button; the phx-update="ignore" live region keeps its text.
function patchFromServer(el, { options } = {}) {
  el.setAttribute("data-state", "idle");
  el.setAttribute("aria-label", "Copy");
  el.removeAttribute("data-copied");
  if (options) el.setAttribute("data-options", options);
}

test("a patch with unchanged options keeps the copied state and timer", async () => {
  stubClipboard();
  const { el, component, status } = build({ value: "x", resetDelay: 40 });

  click(el);
  await waitFor(() => el.getAttribute("data-state") === "copied");

  patchFromServer(el);
  assert.equal(component.skipReinitialize(el), true);

  assert.equal(el.getAttribute("data-state"), "copied");
  assert.equal(el.getAttribute("aria-label"), "Copied");
  assert.equal(el.hasAttribute("data-copied"), true);
  assert.equal(status.textContent, "Copied");

  await waitFor(() => el.getAttribute("data-state") === "idle");
  assert.equal(el.getAttribute("aria-label"), "Copy");
  assert.equal(status.textContent, "");
});

test("a patch with a new value rebuilds idle and clears the announcement", async () => {
  stubClipboard();
  const { el, component, status } = build({ value: "x", resetDelay: 1000 });

  click(el);
  await waitFor(() => el.getAttribute("data-state") === "copied");

  patchFromServer(el, { options: JSON.stringify({ value: "y" }) });
  assert.equal(component.skipReinitialize(el), false);

  component.destroy();
  components = [];
  const rebuilt = new CodeBlockCopyButtonComponent(el, {
    pushEventTo() {},
    liveSocket: { execJS: () => {} },
  });
  rebuilt.setupEvents();
  components.push(rebuilt);

  assert.equal(rebuilt.state, "idle");
  assert.equal(el.hasAttribute("data-copied"), false);
  assert.equal(status.textContent, "");
});

test("a disabled button does not copy", async () => {
  const writes = stubClipboard();
  const { el, pushed } = build({ value: "x" });
  el.disabled = true;

  click(el);
  await Promise.resolve();
  await Promise.resolve();

  assert.deepEqual(writes, []);
  assert.equal(el.getAttribute("data-state"), "idle");
  assert.equal(pushed.length, 0);
});

test("without the clipboard API the button stays idle", async () => {
  Object.defineProperty(globalThis, "navigator", {
    configurable: true,
    value: {},
  });
  const { el, status, pushed } = build({ value: "x" });

  click(el);
  await Promise.resolve();
  await Promise.resolve();

  assert.equal(el.getAttribute("data-state"), "idle");
  assert.equal(status.textContent, "");
  assert.equal(pushed.length, 0);
});

test("copying again while copied restarts the reset delay", async () => {
  const writes = stubClipboard();
  const { el, component, pushed } = build({ value: "x", resetDelay: 60 });

  click(el);
  await waitFor(() => el.getAttribute("data-state") === "copied");
  const firstTimer = component.resetTimer;

  click(el);
  await waitFor(() => writes.length === 2);
  await waitFor(() => component.resetTimer !== firstTimer);

  assert.equal(el.getAttribute("data-state"), "copied");
  assert.equal(pushed.length, 2);
  await waitFor(() => el.getAttribute("data-state") === "idle");
});
