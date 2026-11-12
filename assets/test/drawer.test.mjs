import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import "../salad_ui/components/drawer.js";
import { registry } from "../salad_ui/core/factory.js";
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

const realNow = Date.now;
let now = 0;

before(() => installDom());
after(() => uninstallDom());
afterEach(async () => {
  Date.now = realNow;
  document.body.innerHTML = "";
  await releaseClickGuard();
});

// A drag swallows the click that ends it, until the next macrotask.
const releaseClickGuard = () =>
  new Promise((resolve) => setTimeout(resolve, 0));

// Drag velocity is distance over Date.now() time; pin the clock so a test
// decides whether a gesture is a slow drag or a flick.
function useClock(start = 1000) {
  now = start;
  Date.now = () => now;
}

function buildDrawer({
  id = "drawer-1",
  open = false,
  direction,
  snapPoints,
  activeSnapPoint,
  dismissible = true,
  handleOnly = false,
  animations,
  size = { width: 300, height: 400 },
  extraPanelHtml = "",
} = {}) {
  const options = JSON.stringify({
    direction,
    snapPoints,
    activeSnapPoint,
    dismissible,
    handleOnly,
    closeOnEscape: dismissible,
    closeOnOutsideClick: dismissible,
    ...(animations ? { animations } : {}),
  });

  document.body.innerHTML = `
    <div id="${id}" data-component="drawer" data-open="${open}"
         data-options='${options}'
         data-event-mappings='{"open":"open","close":"close","snap-point-change":"snap"}'
         data-part="root">
      <button data-part="trigger" data-action="open" type="button">Open</button>
      <div data-part="content" hidden>
        <div data-part="overlay"></div>
        <div data-part="content-panel">
          <div data-part="handle"></div>
          <h2 data-part="title">Move Goal</h2>
          <p data-part="description">Set your daily activity goal.</p>
          <div id="body">Body</div>
          <input id="field" />
          <div id="no-drag" data-vaul-no-drag>Static</div>
          <button id="action" type="button">Action</button>
          <div data-part="close" data-action="close">
            <button id="cancel" type="button">Cancel</button>
          </div>
          ${extraPanelHtml}
        </div>
      </div>
    </div>
  `;

  const el = document.getElementById(id);
  const panel = el.querySelector('[data-part="content-panel"]');
  panel.getBoundingClientRect = () => ({
    ...size,
    top: 0,
    left: 0,
    right: size.width,
    bottom: size.height,
  });

  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  return {
    component: registry.create("drawer", el, hookContext),
    el,
    panel,
    content: el.querySelector('[data-part="content"]'),
    overlay: el.querySelector('[data-part="overlay"]'),
    handle: el.querySelector('[data-part="handle"]'),
    trigger: el.querySelector('[data-part="trigger"]'),
    pushed,
  };
}

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
}

function pointer(el, type, x, y) {
  el.dispatchEvent(
    new window.PointerEvent(type, {
      bubbles: true,
      cancelable: true,
      clientX: x,
      clientY: y,
      pointerId: 1,
      button: 0,
    }),
  );
}

// Press on `el`, move through `points` (each [x, y, ms elapsed]), release.
function drag(el, from, points) {
  pointer(el, "pointerdown", from[0], from[1]);
  let last = from;
  for (const [x, y, ms = 100] of points) {
    now += ms;
    pointer(el, "pointermove", x, y);
    last = [x, y];
  }
  pointer(el, "pointerup", last[0], last[1]);
}

test("stamps the direction and applies dialog ARIA", () => {
  const { component, el, panel, content, handle, trigger } = buildDrawer({
    direction: "right",
  });

  assert.equal(panel.getAttribute("data-vaul-drawer-direction"), "right");
  assert.equal(content.getAttribute("data-vaul-drawer-direction"), "right");
  assert.equal(el.getAttribute("data-vaul-drawer-direction"), "right");
  assert.equal(handle.getAttribute("aria-hidden"), "true");

  click(trigger);
  assert.equal(component.state, "open");
  assert.equal(content.hidden, false);
  assert.equal(panel.getAttribute("role"), "dialog");
  assert.equal(panel.getAttribute("aria-modal"), "true");
  assert.equal(panel.getAttribute("aria-labelledby"), "drawer-1-title");
  assert.equal(panel.getAttribute("aria-describedby"), "drawer-1-description");

  component.destroy();
});

test("defaults to bottom for a missing or unknown direction", () => {
  const { component, panel } = buildDrawer({ direction: "sideways" });
  assert.equal(panel.getAttribute("data-vaul-drawer-direction"), "bottom");
  component.destroy();
});

test("follows the pointer and settles back after a short drag", () => {
  useClock();
  const { component, panel, overlay } = buildDrawer({ open: true });
  assert.equal(component.state, "open");

  const body = document.getElementById("body");
  pointer(body, "pointerdown", 100, 100);
  now += 100;
  pointer(body, "pointermove", 100, 140);
  assert.equal(panel.style.transform, "translateY(40px)");
  assert.equal(overlay.style.opacity, String(1 - 40 / 400));

  now += 200;
  pointer(body, "pointerup", 100, 150);

  assert.equal(component.state, "open");
  assert.equal(panel.style.transform, "");
  assert.match(panel.style.transition, /transform/);
  component.destroy();
});

test("dismisses when dragged past a quarter of its height", () => {
  useClock();
  const { component, panel, content, pushed } = buildDrawer({ open: true });

  drag(document.getElementById("body"), [100, 100], [[100, 250, 500]]);

  assert.equal(component.state, "closed");
  assert.equal(content.hidden, true);
  assert.equal(pushed.at(-1).event, "close");
  // Inline drag styles are cleared once the drawer is closed.
  assert.equal(panel.style.transform, "");
  component.destroy();
});

test("a quick flick dismisses even a short drag", () => {
  useClock();
  const { component } = buildDrawer({ open: true });

  drag(document.getElementById("body"), [100, 100], [[100, 160, 50]]);

  assert.equal(component.state, "closed");
  component.destroy();
});

test("keeps the drag offset during an animated exit", async () => {
  useClock();
  const { component, panel, content } = buildDrawer({
    open: true,
    animations: { open_to_closed: { duration: 30, target_part: "content" } },
  });

  drag(document.getElementById("body"), [100, 100], [[100, 300, 500]]);

  assert.equal(component.state, "closed");
  assert.equal(panel.style.transform, "translateY(200px)");
  Date.now = realNow;
  await waitFor(() => content.hidden);
  assert.equal(panel.style.transform, "");
  component.destroy();
});

test("drags along x for right drawers and ignores the other axis", () => {
  useClock();
  const right = buildDrawer({ open: true, direction: "right" });
  const body = document.getElementById("body");

  pointer(body, "pointerdown", 100, 100);
  now += 100;
  pointer(body, "pointermove", 100, 200);
  assert.equal(right.panel.style.transform, "");
  pointer(body, "pointerup", 100, 200);

  drag(body, [100, 100], [[250, 100, 500]]);
  assert.equal(right.component.state, "closed");
  right.component.destroy();
});

test("top and left drawers dismiss toward their own edge", () => {
  useClock();
  const top = buildDrawer({ open: true, direction: "top" });
  drag(document.getElementById("body"), [100, 300], [[100, 280, 500]]);
  assert.equal(top.panel.style.transform, "");
  drag(document.getElementById("body"), [100, 300], [[100, 150, 500]]);
  assert.equal(top.component.state, "closed");
  top.component.destroy();

  const left = buildDrawer({ open: true, direction: "left" });
  drag(document.getElementById("body"), [250, 100], [[100, 100, 500]]);
  assert.equal(left.component.state, "closed");
  left.component.destroy();
});

test("a drag does not click what is under the pointer", async () => {
  useClock();
  const { component } = buildDrawer({ open: true });
  const action = document.getElementById("action");
  let clicks = 0;
  action.addEventListener("click", () => clicks++);

  drag(action, [100, 100], [[100, 120, 200]]);
  click(action);
  assert.equal(clicks, 0);
  assert.equal(component.state, "open");

  // The guard only covers the click that ends the drag.
  await releaseClickGuard();
  click(action);
  assert.equal(clicks, 1);
  component.destroy();
});

test("taps still reach buttons and the close wrapper", () => {
  useClock();
  const { component, pushed } = buildDrawer({ open: true });
  const cancel = document.getElementById("cancel");

  pointer(cancel, "pointerdown", 100, 100);
  pointer(cancel, "pointerup", 101, 102);
  click(cancel);

  assert.equal(component.state, "closed");
  assert.equal(pushed.at(-1).event, "close");
  component.destroy();
});

test("form fields and data-vaul-no-drag never start a drag", () => {
  useClock();
  const { component, panel } = buildDrawer({ open: true });

  drag(document.getElementById("field"), [100, 100], [[100, 300, 500]]);
  assert.equal(component.state, "open");
  drag(document.getElementById("no-drag"), [100, 100], [[100, 300, 500]]);
  assert.equal(component.state, "open");
  assert.equal(panel.style.transform, "");
  component.destroy();
});

test("scrolled content scrolls instead of dragging", () => {
  useClock();
  const { component } = buildDrawer({
    open: true,
    extraPanelHtml: `<div id="scroller"><p id="line">Line</p></div>`,
  });
  const scroller = document.getElementById("scroller");
  Object.defineProperty(scroller, "scrollHeight", { value: 1000 });
  Object.defineProperty(scroller, "clientHeight", { value: 200 });
  scroller.scrollTop = 50;

  drag(document.getElementById("line"), [100, 100], [[100, 300, 500]]);
  assert.equal(component.state, "open");

  scroller.scrollTop = 0;
  drag(document.getElementById("line"), [100, 100], [[100, 300, 500]]);
  assert.equal(component.state, "closed");
  component.destroy();
});

test("non-dismissible drawers resist and ignore Escape", () => {
  useClock();
  const { component, el, panel } = buildDrawer({
    open: true,
    dismissible: false,
  });
  const body = document.getElementById("body");

  pointer(body, "pointerdown", 100, 100);
  now += 500;
  pointer(body, "pointermove", 100, 400);
  const offset = parseFloat(panel.style.transform.match(/-?[\d.]+/)[0]);
  assert.ok(offset > 0 && offset < 300, `dampened offset, got ${offset}`);
  pointer(body, "pointerup", 100, 400);

  assert.equal(component.state, "open");
  assert.equal(panel.style.transform, "");

  el.dispatchEvent(
    new window.KeyboardEvent("keydown", { key: "Escape", bubbles: true }),
  );
  assert.equal(component.state, "open");
  component.destroy();
});

test("handleOnly drags from the handle alone", () => {
  useClock();
  const { component, handle } = buildDrawer({ open: true, handleOnly: true });

  drag(document.getElementById("body"), [100, 100], [[100, 300, 500]]);
  assert.equal(component.state, "open");

  drag(handle, [100, 100], [[100, 300, 500]]);
  assert.equal(component.state, "closed");
  component.destroy();
});

test("opens at the active snap point and settles at the nearest one", async () => {
  useClock();
  // jsdom's viewport is 768px tall; the panel is 400px.
  const { component, panel, trigger, pushed } = buildDrawer({
    snapPoints: ["100px", "250px", 1],
    activeSnapPoint: "250px",
  });

  click(trigger);
  assert.equal(panel.style.transform, "translateY(150px)");

  // Drag up 130px slowly: 20px from the 400px (offset 0) snap point.
  drag(document.getElementById("body"), [100, 300], [[100, 170, 1000]]);
  assert.equal(component.state, "open");
  assert.equal(panel.style.transform, "");
  assert.deepEqual(pushed.at(-1), {
    target: component.el,
    event: "snap",
    payload: {
      index: 2,
      snapPoint: 1,
      componentId: "drawer-1",
      component: "drawer",
    },
  });

  // A flick down moves one snap point at a time.
  drag(document.getElementById("body"), [100, 100], [[100, 140, 20]]);
  assert.equal(panel.style.transform, "translateY(150px)");
  assert.equal(pushed.at(-1).payload.index, 1);

  // Past the lowest snap point by a quarter of the remaining travel closes.
  drag(document.getElementById("body"), [100, 100], [[100, 400, 1000]]);
  assert.equal(component.state, "closed");

  // Reopening starts from the configured snap point again.
  await releaseClickGuard();
  click(trigger);
  assert.equal(panel.style.transform, "translateY(150px)");
  component.destroy();
});

test("fractional snap points and the snap_to command", () => {
  const { component, panel, trigger, pushed } = buildDrawer({
    snapPoints: [0.25, 0.5],
    size: { width: 300, height: 768 },
  });

  click(trigger);
  // First snap point by default: 25% of 768px visible.
  assert.equal(panel.style.transform, "translateY(576px)");

  component.handleCommand("snap_to", { index: 1 });
  assert.equal(panel.style.transform, "translateY(384px)");
  assert.equal(pushed.at(-1).payload.snapPoint, 0.5);

  component.handleCommand("snap_to", { snap_point: 0.25 });
  assert.equal(panel.style.transform, "translateY(576px)");

  component.handleCommand("close");
  assert.equal(component.state, "closed");
  component.destroy();
});

test("removes document listeners on destroy mid-drag", () => {
  useClock();
  const { component, panel } = buildDrawer({ open: true });
  const body = document.getElementById("body");

  pointer(body, "pointerdown", 100, 100);
  now += 100;
  pointer(body, "pointermove", 100, 140);
  component.destroy();

  // A stray move after destroy must not throw or move the panel.
  pointer(document.body, "pointermove", 100, 300);
  assert.equal(panel.style.transform, "translateY(40px)");
});
