import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import "../salad_ui/components/popover.js";
import { registry } from "../salad_ui/core/factory.js";
import { SaladUIHook } from "../salad_ui/core/hook.js";
import { installDom, setRect, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  document.body.innerHTML = "";
});

function buildPopover({
  state = "closed",
  usePortal = false,
  withAnchor = false,
} = {}) {
  const options = JSON.stringify({
    portalContainer: "#portal",
    usePortal,
  });

  document.body.innerHTML = `
    <div id="portal"></div>
    <div id="popover-1" data-component="popover" data-state="${state}"
         data-options='${options}'
         data-event-mappings='{"open":"opened","close":"closed"}'
         data-part="root">
      ${withAnchor ? '<div data-part="anchor">Anchor</div>' : ""}
      <button data-part="trigger" data-action="toggle" type="button">Open</button>
      <div data-part="positioner" data-side="bottom" data-align="center"
           data-side-offset="8" data-align-offset="0" hidden>
        <div data-part="content"><button type="button">Content action</button></div>
      </div>
    </div>
  `;

  const el = document.getElementById("popover-1");
  const trigger = el.querySelector('[data-part="trigger"]');
  const positioner = el.querySelector('[data-part="positioner"]');
  const content = el.querySelector('[data-part="content"]');
  const anchor = el.querySelector('[data-part="anchor"]');
  if (anchor) {
    setRect(anchor, {
      top: 300,
      right: 500,
      bottom: 320,
      left: 300,
      width: 200,
      height: 20,
    });
  }
  setRect(trigger, {
    top: 100,
    right: 200,
    bottom: 140,
    left: 100,
    width: 100,
    height: 40,
  });
  setRect(positioner, { width: 120, height: 80 });

  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  return { el, trigger, anchor, positioner, content, pushed, hookContext };
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

test("SSR-open popover activates positioning without an open event", () => {
  const { el, positioner, content, pushed, hookContext } = buildPopover({
    state: "open",
  });
  const component = registry.create("popover", el, hookContext);

  assert.equal(component.state, "open");
  assert.equal(component.positionedElement.active, true);
  assert.equal(positioner.parentElement, el);
  assert.equal(positioner.hidden, false);
  assert.equal(content.getAttribute("role"), "dialog");
  assert.deepEqual(pushed, []);

  component.destroy();
});

test("Escape from portaled content closes popover", () => {
  const { el, trigger, positioner, content, hookContext } = buildPopover({
    usePortal: true,
  });
  const component = registry.create("popover", el, hookContext);

  click(trigger);
  assert.equal(positioner.parentElement.id, "portal");

  const event = new window.KeyboardEvent("keydown", {
    key: "Escape",
    bubbles: true,
    cancelable: true,
  });
  content.dispatchEvent(event);

  assert.equal(component.state, "closed");
  assert.equal(event.defaultPrevented, true);
  assert.equal(positioner.parentElement, el);
  component.destroy();
});

test("position callback synchronizes content side with flipped placement", () => {
  const { el, trigger, content, hookContext } = buildPopover();
  const component = registry.create("popover", el, hookContext);

  click(trigger);
  component.positionedElement.options.onPosition({ placement: "top" });

  assert.equal(content.dataset.side, "top");
  component.destroy();
});

test("LiveView pre-update restores portaled content before component recreation", () => {
  const { el, trigger, positioner } = buildPopover({ usePortal: true });
  const hook = createHookInstance(el);
  hook.mounted();

  click(trigger);
  assert.equal(positioner.parentElement.id, "portal");

  hook.beforeUpdate();
  assert.equal(positioner.parentElement, el);

  // Simulate LiveView replacing root children during its DOM patch.
  el.innerHTML = `
    <button data-part="trigger" data-action="toggle" type="button">Open</button>
    <div data-part="positioner" data-side="bottom" data-align="center"
         data-side-offset="8" data-align-offset="0" hidden>
      <div data-part="content"><button type="button">Content action</button></div>
    </div>
  `;
  const patchedTrigger = el.querySelector('[data-part="trigger"]');
  const patchedPositioner = el.querySelector('[data-part="positioner"]');
  setRect(patchedTrigger, {
    top: 100,
    right: 200,
    bottom: 140,
    left: 100,
    width: 100,
    height: 40,
  });
  setRect(patchedPositioner, { width: 120, height: 80 });

  const original = hook.component;
  hook.updated();

  assert.equal(original.destroyed, true);
  assert.notEqual(hook.component, original);
  assert.equal(document.querySelectorAll('[data-part="positioner"]').length, 1);
  assert.equal(patchedPositioner.parentElement.id, "portal");
  hook.destroyed();
});

test("popover positions against the anchor instead of the trigger", () => {
  const { el, trigger, anchor, hookContext } = buildPopover({
    withAnchor: true,
  });
  const component = registry.create("popover", el, hookContext);

  click(trigger);

  assert.equal(component.state, "open");
  assert.equal(component.positionedElement.reference, anchor);
  component.destroy();
});

test("with an anchor, clicking the trigger again closes the popover", () => {
  const { el, trigger, hookContext } = buildPopover({ withAnchor: true });
  const component = registry.create("popover", el, hookContext);

  click(trigger);
  assert.equal(component.state, "open");

  click(trigger);
  assert.equal(component.state, "closed");
  component.destroy();
});

test("with an anchor, clicking outside closes the popover", () => {
  const { el, trigger, hookContext } = buildPopover({ withAnchor: true });
  const component = registry.create("popover", el, hookContext);

  click(trigger);
  click(document.body);

  assert.equal(component.state, "closed");
  component.destroy();
});

// A hook on LiveView >= 1.1, which can ignore attributes during patches.
function createPatchSafeHook(el, ignored) {
  return {
    ...createHookInstance(el),
    js: () => ({
      ignoreAttributes: (target, attrs) => ignored.set(target, attrs),
    }),
  };
}

test("open state is kept across LiveView patches", () => {
  const { el, trigger, positioner, content } = buildPopover();
  const ignored = new Map();
  const hook = createPatchSafeHook(el, ignored);
  hook.mounted();

  assert.deepEqual(ignored.get(el), ["data-state"]);
  assert.deepEqual(ignored.get(trigger), ["data-state", "aria-expanded"]);
  assert.deepEqual(ignored.get(positioner), ["data-state", "hidden", "style"]);
  assert.deepEqual(ignored.get(content), ["data-state", "data-side"]);

  click(trigger);
  const original = hook.component;
  const positioned = original.positionedElement;
  assert.equal(positioned.active, true);

  // A patch that only changed the content's children keeps everything live.
  hook.beforeUpdate();
  content.innerHTML = "<button type='button'>Re-rendered</button>";
  hook.updated();

  assert.equal(hook.component, original);
  assert.equal(original.state, "open");
  assert.equal(positioned.active, true);
  assert.equal(positioner.hidden, false);
  hook.destroyed();
});

test("a patch that replaces the parts rebuilds the popover in its open state", () => {
  const { el, trigger } = buildPopover();
  const hook = createPatchSafeHook(el, new Map());
  hook.mounted();
  click(trigger);

  const original = hook.component;
  hook.beforeUpdate();
  // LiveView kept the root's (ignored) data-state="open" but swapped children.
  el.innerHTML = `
    <button data-part="trigger" data-action="toggle" type="button">Open</button>
    <div data-part="positioner" data-side="bottom" data-align="center" hidden>
      <div data-part="content">New</div>
    </div>
  `;
  hook.updated();

  assert.notEqual(hook.component, original);
  assert.equal(original.destroyed, true);
  assert.equal(hook.component.state, "open");
  assert.equal(el.querySelector('[data-part="positioner"]').hidden, false);
  hook.destroyed();
});
