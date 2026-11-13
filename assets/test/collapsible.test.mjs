import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/collapsible.js"; // self-registers "collapsible"
import {
  hookFor,
  installDom,
  simulatePatch,
  uninstallDom,
  waitFor,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function buildCollapsible({
  id = "collapsible-1",
  open = false,
  animations = null,
  eventMappings = { open: "handle_open", close: "handle_close" },
} = {}) {
  const options = { open };
  if (animations) options.animations = animations;

  document.body.innerHTML = `
    <div id="${id}" data-component="collapsible" data-state="${open ? "open" : "closed"}"
         data-options='${JSON.stringify(options)}'
         data-event-mappings='${JSON.stringify(eventMappings)}'
         data-part="root">
      <div data-part="trigger" data-action="toggle" role="button" tabindex="0">
        <span>Toggle</span>
      </div>
      <div data-part="content"${open ? "" : " hidden"}>
        <p>Content</p>
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

  const component = registry.create("collapsible", el, hookContext);

  return {
    component,
    el,
    pushed,
    trigger: el.querySelector('[data-part="trigger"]'),
    content: el.querySelector('[data-part="content"]'),
  };
}

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
}

function keydown(el, key) {
  el.dispatchEvent(new window.KeyboardEvent("keydown", { key, bubbles: true }));
}

test("starts closed by default: content hidden, aria-expanded false, data-state closed", () => {
  const { el, trigger, content } = buildCollapsible();

  assert.equal(el.getAttribute("data-state"), "closed");
  assert.equal(content.hidden, true);
  assert.equal(trigger.getAttribute("aria-expanded"), "false");
});

test("starts open when options/data-state say so: content visible, aria-expanded true", () => {
  const { el, trigger, content } = buildCollapsible({ open: true });

  assert.equal(el.getAttribute("data-state"), "open");
  assert.equal(content.hidden, false);
  assert.equal(trigger.getAttribute("aria-expanded"), "true");
});

test("aria-controls/aria-labelledby reference each other's real, non-empty ids", () => {
  const { trigger, content } = buildCollapsible();

  assert.ok(trigger.id, "trigger should have an id");
  assert.ok(content.id, "content should have an id");
  assert.equal(trigger.getAttribute("aria-controls"), content.id);
  assert.equal(content.getAttribute("aria-labelledby"), trigger.id);
  assert.equal(content.getAttribute("role"), "region");
});

test("clicking the trigger opens a closed collapsible and pushes the mapped 'open' event", () => {
  const { el, trigger, content, pushed } = buildCollapsible();

  click(trigger);

  assert.equal(el.getAttribute("data-state"), "open");
  assert.equal(content.hidden, false);
  assert.equal(trigger.getAttribute("aria-expanded"), "true");
  assert.equal(pushed.length, 1);
  assert.equal(pushed[0].event, "handle_open");
  assert.equal(pushed[0].payload.componentId, el.id);
});

test("clicking the trigger closes an open collapsible and pushes the mapped 'close' event", () => {
  const { el, trigger, content, pushed } = buildCollapsible({ open: true });

  click(trigger);

  assert.equal(el.getAttribute("data-state"), "closed");
  assert.equal(content.hidden, true);
  assert.equal(trigger.getAttribute("aria-expanded"), "false");
  assert.equal(pushed.length, 1);
  assert.equal(pushed[0].event, "handle_close");
});

test("Enter and Space on the trigger toggle the collapsible open then closed", () => {
  const { el, trigger } = buildCollapsible();

  keydown(trigger, "Enter");
  assert.equal(el.getAttribute("data-state"), "open");

  keydown(trigger, " ");
  assert.equal(el.getAttribute("data-state"), "closed");
});

test("Space/Enter bubbling up from inside the content do not toggle the collapsible (regression)", () => {
  // The trigger's Enter/Space handling is scoped via keyEventTarget: "trigger".
  // Before that fix, the keydown listener sat on the root element, so any
  // keypress bubbling from content (e.g. a nested textarea/button the user is
  // interacting with) would also be caught and would toggle the panel shut.
  const { el, content, pushed } = buildCollapsible({ open: true });

  keydown(content, " ");
  assert.equal(el.getAttribute("data-state"), "open");

  keydown(content, "Enter");
  assert.equal(el.getAttribute("data-state"), "open");

  assert.equal(pushed.length, 0);
});

test("open_to_closed animation hides content only after the transition finishes", async () => {
  const { el, content } = buildCollapsible({
    open: true,
    animations: {
      open_to_closed: {
        animation: ["ease-out", "opacity-100", "opacity-0"],
        duration: 20,
        target_part: "content",
      },
    },
  });

  el.dispatchEvent(
    new window.CustomEvent("salad_ui:command", {
      detail: { command: "close" },
    }),
  );

  // data-state flips synchronously, ahead of the animation completing.
  assert.equal(el.getAttribute("data-state"), "closed");
  assert.equal(content.hidden, false);

  // Hidden, then animation classes cleaned up, once the transition settles.
  await waitFor(
    () =>
      content.hidden === true &&
      !content.classList.contains("opacity-0") &&
      !content.classList.contains("opacity-100"),
  );
  assert.equal(content.hidden, true);
  assert.equal(content.classList.contains("opacity-0"), false);
  assert.equal(content.classList.contains("opacity-100"), false);
});

// Re-render from the server markup, which renders no ids below the root.
// `replace` swaps the matched elements for fresh copies, as when the server
// re-renders them under new keys.
function patch(el, { open = false, replace = [] } = {}) {
  simulatePatch(el, {
    hidden: open ? [] : ['[data-part="content"]'],
    replace,
  });
  el.dataset.state = open ? "open" : "closed";
}

test("a LiveView patch keeps a client-opened collapsible open", () => {
  const { component, el, trigger, pushed } = buildCollapsible();
  const hook = hookFor(el, component);
  click(trigger);
  const content = el.querySelector('[data-part="content"]');
  const field = document.createElement("input");
  content.append(field);
  field.focus();

  // e.g. the phx-change round trip of a form in the content.
  hook.beforeUpdate();
  patch(el);
  hook.updated();

  assert.equal(hook.component, component);
  // The client ids were dropped before the patch, so the trigger and
  // content were patched in place, keeping the focused field.
  assert.equal(el.querySelector('[data-part="trigger"]'), trigger);
  assert.equal(el.querySelector('[data-part="content"]'), content);
  assert.equal(document.activeElement, field);
  assert.equal(component.state, "open");
  assert.equal(content.hidden, false);
  assert.equal(trigger.getAttribute("aria-controls"), content.id);
  assert.equal(content.getAttribute("aria-labelledby"), trigger.id);
  assert.equal(pushed.filter(({ event }) => event === "handle_open").length, 1);
  component.destroy();
});

test("a collapsible keeps its state when the server replaces its parts", () => {
  const { component, el, trigger, pushed } = buildCollapsible();
  const hook = hookFor(el, component);
  click(trigger);

  hook.beforeUpdate();
  patch(el, {
    replace: ['[data-part="trigger"]', '[data-part="content"]'],
  });
  hook.updated();

  const newTrigger = el.querySelector('[data-part="trigger"]');
  const newContent = el.querySelector('[data-part="content"]');
  assert.notEqual(newTrigger, trigger);
  assert.equal(hook.component, component);
  assert.equal(component.state, "open");
  assert.equal(el.dataset.state, "open");
  assert.equal(newContent.hidden, false);
  assert.equal(newContent.dataset.state, "open");
  assert.equal(newTrigger.getAttribute("aria-expanded"), "true");
  assert.equal(newTrigger.getAttribute("aria-controls"), newContent.id);
  assert.equal(pushed.filter(({ event }) => event === "handle_open").length, 1);

  // The replaced trigger still toggles, by click and by keyboard.
  keydown(newTrigger, "Enter");
  assert.equal(component.state, "closed");
  assert.equal(newContent.hidden, true);
  click(newTrigger);
  assert.equal(component.state, "open");
  component.destroy();
});

test("a new server open value opens and closes the live collapsible", () => {
  const { component, el } = buildCollapsible();
  const hook = hookFor(el, component);

  hook.beforeUpdate();
  patch(el, { open: true });
  el.dataset.options = JSON.stringify({ open: true });
  hook.updated();
  assert.equal(hook.component, component);
  assert.equal(component.state, "open");

  hook.beforeUpdate();
  patch(el);
  el.dataset.options = JSON.stringify({ open: false });
  hook.updated();
  assert.equal(hook.component, component);
  assert.equal(component.state, "closed");
  assert.equal(el.querySelector('[data-part="content"]').hidden, true);
  component.destroy();
});

test("changed collapsible options rebuild it", () => {
  const { component, el } = buildCollapsible();
  const hook = hookFor(el, component);

  el.dataset.options = JSON.stringify({ open: false, animations: {} });
  hook.updated();
  assert.notEqual(hook.component, component);
  assert.equal(component.destroyed, true);
  hook.destroyed();
});
