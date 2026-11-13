import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import "../salad_ui/components/dialog.js";
import { registry } from "../salad_ui/core/factory.js";
import { SaladUIHook } from "../salad_ui/core/hook.js";
import {
  hookFor,
  installDom,
  simulatePatch,
  uninstallDom,
  wait,
  waitFor,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  document.body.innerHTML = "";
});

function buildDialog({
  id = "dialog-1",
  open = false,
  state,
  closeOnOutsideClick = true,
  closeOnEscape = true,
  animations,
  extraPanelHtml = "",
} = {}) {
  const initialState =
    state === undefined ? `data-open="${open}"` : `data-state="${state}"`;

  const options = JSON.stringify({
    closeOnOutsideClick,
    closeOnEscape,
    ...(animations ? { animations } : {}),
  });

  document.body.innerHTML = `
    <button id="outside-trigger" type="button">Launch</button>
    <div id="${id}" data-component="dialog" ${initialState}
         data-options='${options}'
         data-event-mappings='{"open":"open","close":"close"}'
         data-part="root">
      <button data-part="trigger" data-action="open" type="button">Open</button>
      <div data-part="content" hidden>
        <div data-part="overlay"></div>
        <div data-part="content-panel">
          <h2 data-part="title">Dialog title</h2>
          <p data-part="description">Dialog description</p>
          <button data-part="close-trigger" data-action="close" type="button">Close</button>
          <button id="dialog-action" type="button">Action</button>
          ${extraPanelHtml}
        </div>
      </div>
    </div>
  `;

  const el = document.getElementById(id);
  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  return {
    component: registry.create("dialog", el, hookContext),
    el,
    content: el.querySelector('[data-part="content"]'),
    panel: el.querySelector('[data-part="content-panel"]'),
    trigger: el.querySelector('[data-part="trigger"]'),
    overlay: el.querySelector('[data-part="overlay"]'),
    closeTrigger: el.querySelector('[data-part="close-trigger"]'),
    outsideTrigger: document.getElementById("outside-trigger"),
    pushed,
    hookContext,
  };
}

// Re-render from the server markup, which renders only these ids.
function patch(el) {
  simulatePatch(el, {
    hidden: ['[data-part="content"]'],
    keepIds: [el.id, "dialog-action", "field"],
  });
}

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
}

function createHookInstance(el) {
  return {
    ...SaladUIHook,
    el,
    pushEventTo() {},
    handleEvent() {},
  };
}

test("opens from trigger and closes from close trigger", () => {
  const { component, content, panel, trigger, closeTrigger, pushed } =
    buildDialog();

  click(trigger);
  assert.equal(component.state, "open");
  assert.equal(content.hidden, false);
  assert.equal(panel.getAttribute("aria-modal"), "true");
  assert.equal(panel.getAttribute("aria-labelledby"), "dialog-1-title");
  assert.equal(panel.getAttribute("aria-describedby"), "dialog-1-description");
  assert.equal(pushed.at(-1).event, "open");

  click(closeTrigger);
  assert.equal(component.state, "closed");
  assert.equal(content.hidden, true);
  assert.equal(panel.getAttribute("role"), "dialog");
  assert.equal(panel.hasAttribute("aria-modal"), false);
  assert.equal(panel.hasAttribute("aria-labelledby"), false);
  assert.equal(panel.hasAttribute("aria-describedby"), false);
  assert.equal(pushed.at(-1).event, "close");

  component.destroy();
});

test("dialog_close wrapper closes from a nested element and keeps its label", () => {
  const { component, trigger, el, pushed } = buildDialog({
    extraPanelHtml: `
      <div data-slot="dialog-close" data-part="close" data-action="close">
        <button id="custom-close" type="button">Cancel</button>
      </div>
    `,
  });

  click(trigger);
  assert.equal(component.state, "open");

  const wrapper = el.querySelector('[data-part="close"]');
  // Only the built-in corner button gets the generic "Close dialog" label.
  assert.equal(wrapper.hasAttribute("aria-label"), false);

  click(document.getElementById("custom-close"));
  assert.equal(component.state, "closed");
  assert.equal(pushed.at(-1).event, "close");

  component.destroy();
});

test("Escape closes dialog and prevents browser default", () => {
  const { component, el, trigger } = buildDialog();
  click(trigger);

  const event = new window.KeyboardEvent("keydown", {
    key: "Escape",
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);

  assert.equal(component.state, "closed");
  assert.equal(event.defaultPrevented, true);
  component.destroy();
});

test("Escape does not close dialogs that disable closeOnEscape", () => {
  const { component, el, trigger } = buildDialog({ closeOnEscape: false });
  click(trigger);

  const event = new window.KeyboardEvent("keydown", {
    key: "Escape",
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);

  assert.equal(component.state, "open");
  assert.equal(event.defaultPrevented, false);
  component.destroy();
});

test("notifies close before an animated exit completes", () => {
  const { component, content, trigger, closeTrigger, pushed } = buildDialog({
    animations: {
      open_to_closed: { duration: 50, target_part: "content" },
    },
  });
  click(trigger);
  pushed.length = 0;

  click(closeTrigger);

  assert.equal(component.state, "closed");
  assert.equal(content.hidden, false);
  assert.equal(pushed.at(-1).event, "close");
  component.destroy();
});

test("overlay closes only when outside-click dismissal is enabled", () => {
  const enabled = buildDialog({ closeOnOutsideClick: true });
  click(enabled.trigger);
  click(enabled.overlay);
  assert.equal(enabled.component.state, "closed");
  enabled.component.destroy();

  const disabled = buildDialog({ closeOnOutsideClick: false });
  click(disabled.trigger);
  click(disabled.overlay);
  assert.equal(disabled.component.state, "open");
  disabled.component.destroy();
});

test("focuses first dialog control and restores prior focus on close", async () => {
  const { component, trigger, closeTrigger, outsideTrigger } = buildDialog();
  outsideTrigger.focus();
  click(trigger);

  await waitFor(() => document.activeElement === closeTrigger);

  component.transition("close");
  await waitFor(() => document.activeElement === outsideTrigger);
  component.destroy();
});

test("SSR-open state initializes dialog without emitting open on remount", async () => {
  const { component, content, panel, el, hookContext, pushed } = buildDialog({
    state: "open",
  });

  await wait(60);
  assert.equal(component.state, "open");
  assert.equal(content.hidden, false);
  assert.equal(panel.getAttribute("role"), "dialog");
  assert.equal(panel.getAttribute("aria-modal"), "true");
  assert.equal(panel.getAttribute("aria-labelledby"), "dialog-1-title");
  assert.equal(panel.getAttribute("aria-describedby"), "dialog-1-description");
  assert.equal(pushed.filter(({ event }) => event === "open").length, 0);
  component.destroy();

  const remounted = registry.create("dialog", el, hookContext);
  await wait(60);

  assert.equal(remounted.state, "open");
  assert.equal(pushed.filter(({ event }) => event === "open").length, 0);
  remounted.destroy();
});

test("a LiveView patch keeps a client-opened dialog open", () => {
  const { component, el, content, panel, trigger, pushed } = buildDialog({
    extraPanelHtml: '<input id="field" />',
  });
  const hook = hookFor(el, component);
  click(trigger);
  const field = document.getElementById("field");
  field.focus();
  const title = el.querySelector('[data-part="title"]');
  assert.equal(panel.getAttribute("aria-labelledby"), title.id);

  // A phx-change on a form in the dialog re-renders it from the server,
  // which still says closed.
  hook.beforeUpdate();
  patch(el);
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(component.state, "open");
  assert.equal(content.hidden, false);
  assert.equal(panel.getAttribute("data-state"), "open");
  assert.equal(panel.getAttribute("role"), "dialog");
  assert.equal(panel.getAttribute("aria-modal"), "true");
  assert.equal(panel.getAttribute("aria-labelledby"), "dialog-1-title");
  // The title's client id was dropped before the patch, so it was patched
  // in place rather than replaced, and got its id back.
  assert.equal(document.getElementById("dialog-1-title"), title);
  assert.equal(document.activeElement, field);
  assert.equal(pushed.filter(({ event }) => event === "open").length, 1);

  // Still interactive.
  content.dispatchEvent(
    new window.KeyboardEvent("keydown", { key: "Escape", bubbles: true }),
  );
  assert.equal(component.state, "closed");
  assert.equal(content.hidden, true);
  component.destroy();
});

test("a LiveView patch keeps a client-opened sheet (data-state root) open", () => {
  const { component, el, content, trigger } = buildDialog({
    state: "closed",
  });
  const hook = hookFor(el, component);
  click(trigger);

  hook.beforeUpdate();
  patch(el);
  el.dataset.state = "closed";
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(component.state, "open");
  assert.equal(content.hidden, false);
  assert.equal(el.dataset.state, "open");
  component.destroy();
});

test("changed dialog options rebuild it from the server-rendered state", () => {
  const { component, el, content, trigger } = buildDialog();
  const hook = hookFor(el, component);
  click(trigger);

  hook.beforeUpdate();
  patch(el);
  el.setAttribute("data-options", JSON.stringify({ closeOnEscape: false }));
  hook.updated();

  assert.notEqual(hook.component, component);
  assert.equal(component.destroyed, true);
  assert.equal(hook.component.state, "closed");
  assert.equal(content.hidden, true);
  hook.destroyed();
});

test("LiveView hook updates honor changed server dialog state", () => {
  const { el } = buildDialog({ open: true });
  const hook = createHookInstance(el);
  hook.mounted();

  const original = hook.component;
  el.dataset.open = "false";
  hook.updated();

  assert.equal(hook.component, original);
  assert.equal(hook.component.state, "closed");
  assert.equal(el.querySelector('[data-part="content"]').hidden, true);
  hook.destroyed();
});

test("Escape in a nested dialog closes only the inner one", () => {
  const options = JSON.stringify({ closeOnEscape: true });
  document.body.innerHTML = `
    <div id="outer" data-component="dialog" data-open="false"
         data-options='${options}' data-part="root">
      <button data-part="trigger" data-action="open" type="button">Open</button>
      <div data-part="content" hidden>
        <div data-part="content-panel">
          <div id="inner" data-component="dialog" data-open="false"
               data-options='${options}' data-part="root" phx-hook="SaladUI">
            <button data-part="trigger" data-action="open" type="button">Inner</button>
            <div data-part="content" hidden>
              <div data-part="content-panel">
                <button id="inner-action" type="button">Action</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  const hookContext = { pushEventTo() {}, liveSocket: { execJS() {} } };
  const outer = registry.create(
    "dialog",
    document.getElementById("outer"),
    hookContext,
  );
  const inner = registry.create(
    "dialog",
    document.getElementById("inner"),
    hookContext,
  );
  outer.transition("open");
  inner.transition("open");

  const event = new window.KeyboardEvent("keydown", {
    key: "Escape",
    bubbles: true,
    cancelable: true,
  });
  document.getElementById("inner-action").dispatchEvent(event);

  assert.equal(inner.state, "closed");
  assert.equal(outer.state, "open");

  inner.destroy();
  outer.destroy();
});

test("a key a nested component already handled (defaultPrevented) is ignored", () => {
  const { component, el, trigger } = buildDialog();
  click(trigger);

  const event = new window.KeyboardEvent("keydown", {
    key: "Escape",
    bubbles: true,
    cancelable: true,
  });
  event.preventDefault();
  el.dispatchEvent(event);

  assert.equal(component.state, "open");
  component.destroy();
});

test("a dialog opened with nothing focused returns focus to its trigger", async () => {
  const { component, trigger, closeTrigger } = buildDialog();
  document.activeElement?.blur();
  assert.equal(document.activeElement, document.body);

  // Opened by the server: the user never focused the trigger.
  component.transition("open");
  await waitFor(() => document.activeElement === closeTrigger);

  component.transition("close");
  await waitFor(() => document.activeElement === trigger);
  component.destroy();
});

test("the trigger fallback focuses the button inside a <div> trigger", async () => {
  const { component, el, closeTrigger } = buildDialog();
  const trigger = el.querySelector('[data-part="trigger"]');
  const wrapper = document.createElement("div");
  wrapper.dataset.part = "trigger";
  trigger.replaceWith(wrapper);
  trigger.removeAttribute("data-part");
  wrapper.appendChild(trigger);
  document.activeElement?.blur();

  component.transition("open");
  await waitFor(() => document.activeElement === closeTrigger);

  component.transition("close");
  await waitFor(() => document.activeElement === trigger);
  component.destroy();
});
