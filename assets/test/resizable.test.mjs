import assert from "node:assert/strict";
import { after, before, beforeEach, test } from "node:test";

import ResizableComponent, {
  adjustLayout,
  resizePanel,
  validateLayout,
} from "../salad_ui/components/resizable.js";
import { installDom, setRect, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
beforeEach(() => window.localStorage.clear());

function panel({ id, size, min, max, collapsible, collapsedSize } = {}) {
  const attrs = [
    id ? `id="${id}"` : "",
    size !== undefined ? `data-default-size="${size}"` : "",
    min !== undefined ? `data-min-size="${min}"` : "",
    max !== undefined ? `data-max-size="${max}"` : "",
    collapsible ? 'data-collapsible="true"' : "",
    collapsedSize !== undefined ? `data-collapsed-size="${collapsedSize}"` : "",
  ].join(" ");
  return `<div data-part="panel" ${attrs}>panel</div>`;
}

const handle = (extra = "") =>
  `<div data-part="handle" role="separator" tabindex="0" ${extra}></div>`;

function mount(inner, { id = "group", options = {}, wrap = (s) => s } = {}) {
  document.body.innerHTML = wrap(`
    <div
      id="${id}"
      data-component="resizable"
      data-part="root"
      data-state="idle"
      phx-hook="SaladUI"
      data-options='${JSON.stringify({ orientation: "horizontal", ...options })}'
      data-event-mappings='{"layout-change":"layout_changed"}'
    >${inner}</div>
  `);
  return build(document.getElementById(id));
}

function build(el) {
  const pushed = [];
  const hookContext = {
    pushEventTo(_el, event, payload) {
      pushed.push({ event, payload });
    },
  };
  const component = new ResizableComponent(el, hookContext);
  component.setupEvents();
  return { el, component, pushed };
}

const key = (target, k, opts = {}) =>
  target.dispatchEvent(
    new window.KeyboardEvent("keydown", { key: k, bubbles: true, ...opts }),
  );

const pointer = (target, type, init) =>
  target.dispatchEvent(
    new window.MouseEvent(type, { bubbles: true, button: 0, ...init }),
  );

const panelsOf = (el) => [
  ...el.querySelectorAll(':scope > [data-part="panel"]'),
];
const handlesOf = (el) => [
  ...el.querySelectorAll(':scope > [data-part="handle"]'),
];

test("validateLayout clamps to constraints and keeps a 100% total", () => {
  const constraints = [
    { min: 10, max: 30 },
    { min: 0, max: 100 },
  ];
  assert.deepEqual(validateLayout([50, 50], constraints), [30, 70]);
  assert.deepEqual(validateLayout([5, 50], constraints), [10, 90]);
});

test("adjustLayout cascades through neighbours and respects min/max", () => {
  const constraints = [
    { min: 0, max: 100 },
    { min: 10, max: 100 },
    { min: 20, max: 100 },
  ];
  // Growing panel 0 shrinks panel 1 to its min, then takes from panel 2.
  assert.deepEqual(
    adjustLayout([20, 40, 40], constraints, 0, 40),
    [60, 10, 30],
  );
  // Cannot shrink beyond every min on the far side.
  assert.deepEqual(
    adjustLayout([20, 40, 40], constraints, 0, 90),
    [70, 10, 20],
  );
  // Max on the growing side limits the move.
  const capped = [
    { min: 0, max: 30 },
    { min: 0, max: 100 },
  ];
  assert.deepEqual(adjustLayout([25, 75], capped, 0, 20), [30, 70]);
});

test("initial layout uses default sizes and splits the rest evenly", () => {
  const { el, component } = mount(
    panel({ id: "a", size: 50 }) + handle() + panel() + handle() + panel(),
  );

  assert.deepEqual(component.layout, [50, 25, 25]);
  const [a, b] = panelsOf(el);
  assert.equal(a.style.flexGrow, "50");
  assert.equal(b.style.flexGrow, "25");
  assert.equal(a.style.overflow, "clip");

  // Only the separators carry aria-orientation (the group has no role).
  assert.equal(el.hasAttribute("aria-orientation"), false);
  const [first, second] = handlesOf(el);
  assert.equal(first.getAttribute("role"), "separator");
  assert.equal(first.getAttribute("aria-orientation"), "vertical");
  assert.equal(first.getAttribute("aria-valuenow"), "50");
  assert.equal(first.getAttribute("aria-valuemin"), "0");
  assert.equal(first.getAttribute("aria-valuemax"), "100");
  assert.equal(first.getAttribute("aria-controls"), "a");
  assert.equal(second.getAttribute("aria-valuenow"), "25");
  assert.equal(second.hasAttribute("aria-controls"), false);
});

test("arrow keys resize by the keyboard step and fire layout-change", () => {
  const { el, component, pushed } = mount(
    panel({ size: 50, min: 30, max: 70 }) + handle() + panel({ size: 50 }),
  );
  const [h] = handlesOf(el);

  key(h, "ArrowRight");
  assert.deepEqual(component.layout, [60, 40]);
  assert.equal(h.getAttribute("aria-valuenow"), "60");
  assert.deepEqual(pushed.at(-1), {
    event: "layout_changed",
    payload: { layout: [60, 40], componentId: "group", component: "resizable" },
  });

  key(h, "ArrowRight");
  key(h, "ArrowRight");
  assert.deepEqual(component.layout, [70, 30], "stops at max-size");

  key(h, "Home");
  assert.deepEqual(component.layout, [30, 70], "Home shrinks to min-size");
  key(h, "End");
  assert.deepEqual(component.layout, [70, 30], "End grows to max-size");

  const count = pushed.length;
  key(h, "End");
  assert.equal(pushed.length, count, "no event when nothing changed");

  key(h, "ArrowUp");
  assert.deepEqual(component.layout, [70, 30], "cross-axis keys are ignored");
});

test("vertical groups resize with ArrowUp/ArrowDown and a custom step", () => {
  const { el, component } = mount(
    panel({ size: 25 }) + handle() + panel({ size: 75 }),
    {
      options: { orientation: "vertical", keyboardResizeBy: 5 },
    },
  );
  const [h] = handlesOf(el);

  assert.equal(el.hasAttribute("aria-orientation"), false);
  assert.equal(h.getAttribute("aria-orientation"), "horizontal");

  key(h, "ArrowDown");
  assert.deepEqual(component.layout, [30, 70]);
  key(h, "ArrowUp");
  key(h, "ArrowUp");
  assert.deepEqual(component.layout, [20, 80]);
  key(h, "ArrowRight");
  assert.deepEqual(component.layout, [20, 80]);
});

test("pointer drag resizes relative to the group size", () => {
  const { el, component, pushed } = mount(
    panel({ size: 50 }) + handle() + panel({ size: 50 }),
  );
  const [h] = handlesOf(el);
  setRect(el, { width: 200, height: 100 });
  setRect(h, { width: 0 });

  pointer(h, "pointerdown", { clientX: 100 });
  assert.equal(el.getAttribute("data-state"), "dragging");
  assert.equal(h.getAttribute("data-separator"), "active");
  assert.equal(document.body.style.cursor, "col-resize");

  pointer(document, "pointermove", { clientX: 140 });
  assert.deepEqual(component.layout, [70, 30]);
  pointer(document, "pointermove", { clientX: 80 });
  assert.deepEqual(
    component.layout,
    [40, 60],
    "deltas are from the drag start",
  );
  assert.equal(pushed.length, 0, "no server event mid-drag");

  pointer(document, "pointerup", { clientX: 80 });
  assert.equal(el.getAttribute("data-state"), "idle");
  assert.equal(h.hasAttribute("data-separator"), false);
  assert.equal(document.body.style.cursor, "");
  assert.deepEqual(pushed.at(-1).payload.layout, [40, 60]);

  pointer(document, "pointermove", { clientX: 200 });
  assert.deepEqual(component.layout, [40, 60], "listeners removed after drag");
});

test("drag direction is mirrored in RTL", () => {
  const { el, component } = mount(
    panel({ size: 50 }) + handle() + panel({ size: 50 }),
    {
      wrap: (s) => `<div dir="rtl">${s}</div>`,
    },
  );
  const [h] = handlesOf(el);
  setRect(el, { width: 100 });

  pointer(h, "pointerdown", { clientX: 50 });
  pointer(document, "pointermove", { clientX: 60 });
  pointer(document, "pointerup", {});
  assert.deepEqual(component.layout, [40, 60]);

  key(h, "ArrowLeft");
  assert.deepEqual(component.layout, [50, 50]);
});

test("disabled groups and handles ignore input", () => {
  const { el, component } = mount(
    panel({ size: 50 }) +
      handle("data-disabled") +
      panel({ size: 25 }) +
      handle() +
      panel(),
  );
  const [disabled, enabled] = handlesOf(el);
  assert.equal(disabled.getAttribute("aria-disabled"), "true");
  assert.equal(enabled.hasAttribute("aria-disabled"), false);

  key(disabled, "ArrowRight");
  assert.deepEqual(component.layout, [50, 25, 25]);
  key(enabled, "ArrowRight");
  assert.deepEqual(component.layout, [50, 35, 15]);

  const group = mount(panel({ size: 50 }) + handle() + panel(), {
    id: "disabled-group",
    options: { disabled: true },
  });
  const [h] = handlesOf(group.el);
  assert.equal(h.getAttribute("aria-disabled"), "true");
  key(h, "ArrowRight");
  assert.deepEqual(group.component.layout, [50, 50]);
});

test("auto-save-id persists the layout to localStorage and restores it", () => {
  const markup = panel({ size: 50 }) + handle() + panel({ size: 50 });
  const options = { autoSaveId: "editor" };
  const first = mount(markup, { options });
  key(handlesOf(first.el)[0], "ArrowLeft");
  assert.equal(
    window.localStorage.getItem("salad-ui:resizable:editor"),
    JSON.stringify([40, 60]),
  );
  first.component.destroy();

  const second = mount(markup, { options });
  assert.deepEqual(second.component.layout, [40, 60]);

  // A stored layout for a different panel count is ignored.
  window.localStorage.setItem("salad-ui:resizable:editor", "[10,20,70]");
  const third = mount(markup, { options });
  assert.deepEqual(third.component.layout, [50, 50]);
});

test("layout survives re-initialisation after a LiveView patch", () => {
  const { el, component } = mount(
    panel({ size: 50 }) + handle() + panel({ size: 50 }),
  );
  key(handlesOf(el)[0], "ArrowRight");
  component.destroy();

  // A patch resets the server-rendered styles, then the hook rebuilds.
  panelsOf(el).forEach((p) => p.setAttribute("style", "flex: 50 1 0px"));
  const rebuilt = build(el);
  assert.deepEqual(rebuilt.component.layout, [60, 40]);
  assert.equal(panelsOf(el)[0].style.flexGrow, "60");
});

test("an unrelated LiveView patch keeps the instance and an active drag", () => {
  const { el, component, pushed } = mount(
    panel({ id: "a", size: 50 }) + handle() + panel({ size: 50 }),
  );
  const [h] = handlesOf(el);
  setRect(el, { width: 200 });
  setRect(h, { width: 0 });

  pointer(h, "pointerdown", { clientX: 100 });
  pointer(document, "pointermove", { clientX: 120 });
  assert.deepEqual(component.layout, [60, 40]);

  // The patch restores the server-rendered attributes mid-drag.
  el.setAttribute("data-state", "idle");
  panelsOf(el).forEach((p) => p.setAttribute("style", "flex: 50 1 0px"));
  ["aria-valuenow", "aria-orientation", "data-separator"].forEach((a) =>
    h.removeAttribute(a),
  );

  assert.equal(component.skipReinitialize(el), true);
  assert.equal(panelsOf(el)[0].style.flexGrow, "60");
  assert.equal(h.getAttribute("aria-valuenow"), "60");
  assert.equal(h.getAttribute("aria-orientation"), "vertical");
  assert.equal(h.getAttribute("data-separator"), "active");
  assert.equal(el.getAttribute("data-state"), "dragging");

  pointer(document, "pointermove", { clientX: 140 });
  pointer(document, "pointerup", {});
  assert.deepEqual(component.layout, [70, 30], "drag continued after patch");
  assert.deepEqual(pushed.at(-1).payload.layout, [70, 30]);
});

test("a structural patch rebuilds the component", () => {
  const { el, component } = mount(
    panel({ size: 50 }) + handle() + panel({ size: 50 }),
  );
  const [first] = panelsOf(el);

  first.setAttribute("data-min-size", "60");
  assert.equal(component.skipReinitialize(el), false, "constraints changed");
  first.removeAttribute("data-min-size");

  el.insertAdjacentHTML("beforeend", handle() + panel());
  assert.equal(component.skipReinitialize(el), false, "panel added");
  [...el.children].slice(-2).forEach((child) => child.remove());

  el.setAttribute("data-options", JSON.stringify({ orientation: "vertical" }));
  assert.equal(component.skipReinitialize(el), false, "options changed");
});

test("nested groups are independent", () => {
  const inner = `
    <div id="inner" data-component="resizable" data-part="root" phx-hook="SaladUI"
      data-options='{"orientation":"vertical"}'>
      ${panel({ size: 25 })}${handle()}${panel({ size: 75 })}
    </div>`;
  const { el, component } = mount(
    panel({ size: 50 }) +
      handle() +
      `<div data-part="panel" data-default-size="50">${inner}</div>`,
  );
  const innerEl = document.getElementById("inner");
  const innerGroup = build(innerEl);

  assert.equal(component.panels.length, 2);
  assert.equal(component.handles.length, 1);
  assert.deepEqual(innerGroup.component.layout, [25, 75]);

  key(handlesOf(innerEl)[0], "ArrowDown");
  assert.deepEqual(innerGroup.component.layout, [35, 65]);
  assert.deepEqual(component.layout, [50, 50]);

  key(handlesOf(el)[0], "ArrowLeft");
  assert.deepEqual(component.layout, [40, 60]);
  assert.deepEqual(innerGroup.component.layout, [35, 65]);
});

test("F6 cycles focus between handles", () => {
  const { el } = mount(panel() + handle() + panel() + handle() + panel());
  const [a, b] = handlesOf(el);
  a.focus();
  key(a, "F6");
  assert.equal(document.activeElement, b);
  key(b, "F6");
  assert.equal(document.activeElement, a);
  key(a, "F6", { shiftKey: true });
  assert.equal(document.activeElement, b);
});

test("setLayout command validates and applies a layout", () => {
  const { el, component } = mount(
    panel({ size: 50, max: 60 }) + handle() + panel({ size: 50 }),
  );
  el.dispatchEvent(
    new window.CustomEvent("salad_ui:command", {
      detail: { command: "setLayout", params: { layout: [80, 20] } },
    }),
  );
  assert.deepEqual(component.layout, [60, 40]);

  component.handleCommand("setLayout", { layout: [1, 2, 3] });
  assert.deepEqual(component.layout, [60, 40], "wrong length is ignored");
});

const collapsible = { min: 20, max: 100, collapsible: true, collapsedSize: 0 };
const free = { min: 0, max: 100 };

test("resizePanel snaps a collapsible panel at the halfway point", () => {
  assert.equal(resizePanel(collapsible, 15), 20);
  assert.equal(resizePanel(collapsible, 10), 20);
  assert.equal(resizePanel(collapsible, 9), 0);
  assert.equal(resizePanel({ min: 20, max: 100 }, 5), 20);
  assert.equal(resizePanel(collapsible, 120), 100);
});

test("adjustLayout collapses past halfway and opens at min, like react-resizable-panels", () => {
  const constraints = [collapsible, free];
  // Dragged from 30 to 15: above halfway, it stops at its min.
  assert.deepEqual(adjustLayout([30, 70], constraints, 0, -15), [20, 80]);
  // Dragged to 9: below halfway, it collapses.
  assert.deepEqual(adjustLayout([30, 70], constraints, 0, -21), [0, 100]);
  // A collapsed panel opens once the drag reaches its min.
  assert.deepEqual(adjustLayout([0, 100], constraints, 0, 12), [0, 100]);
  assert.deepEqual(adjustLayout([0, 100], constraints, 0, 25), [25, 75]);
  // The keyboard expands a collapsed panel to its min, and collapses a panel
  // at its min, in one step.
  const keyboard = { trigger: "keyboard" };
  assert.deepEqual(
    adjustLayout([0, 100], constraints, 0, 10, keyboard),
    [20, 80],
  );
  assert.deepEqual(
    adjustLayout([20, 80], constraints, 0, -10, keyboard),
    [0, 100],
  );
});

test("validateLayout snaps collapsible panels", () => {
  assert.deepEqual(validateLayout([5, 95], [collapsible, free]), [0, 100]);
  assert.deepEqual(validateLayout([15, 85], [collapsible, free]), [20, 80]);
});

test("collapse and expand commands resize a collapsible panel by id", () => {
  const { el, component, pushed } = mount(
    panel({ id: "main", size: 70 }) +
      handle() +
      panel({ id: "side", size: 30, min: 20, collapsible: true }),
    { options: { autoSaveId: "collapse-test" } },
  );
  const [, side] = panelsOf(el);

  assert.equal(side.hasAttribute("data-collapsed"), false);
  component.handleCommand("collapse", { panel: "side" });
  assert.deepEqual(component.layout, [100, 0]);
  assert.equal(side.hasAttribute("data-collapsed"), true);
  assert.deepEqual(pushed.at(-1).payload.layout, [100, 0]);
  assert.equal(
    window.localStorage.getItem("salad-ui:resizable:collapse-test"),
    "[100,0]",
  );

  // Expand restores the size it had before collapsing.
  component.handleCommand("expand", { panel: "side" });
  assert.deepEqual(component.layout, [70, 30]);
  assert.equal(side.hasAttribute("data-collapsed"), false);

  assert.equal(component.handleCommand("expand", { panel: "side" }), false);
  assert.equal(component.handleCommand("collapse", { panel: "main" }), false);
  assert.equal(component.handleCommand("collapse", { panel: "nope" }), false);
});

test("expand without a remembered size opens to the min size", () => {
  const { component } = mount(
    panel({ id: "nav", size: 0, min: 15, collapsible: true }) +
      handle() +
      panel({ size: 100 }),
  );
  assert.deepEqual(component.layout, [0, 100]);
  component.handleCommand("expand", { panel: 0 });
  assert.deepEqual(component.layout, [15, 85]);
});

test("Enter on a handle collapses and expands the panel before it", () => {
  const { el, component, pushed } = mount(
    panel({ size: 40, min: 25, collapsible: true }) +
      handle() +
      panel({ size: 60 }),
  );
  const [h] = handlesOf(el);

  key(h, "Enter");
  assert.deepEqual(component.layout, [0, 100]);
  assert.equal(h.getAttribute("aria-valuenow"), "0");
  assert.equal(h.getAttribute("aria-valuemin"), "0");
  assert.deepEqual(pushed.at(-1).payload.layout, [0, 100]);

  key(h, "Enter");
  assert.deepEqual(component.layout, [25, 75]);

  // Not collapsible: Enter does nothing.
  const other = mount(panel({ size: 40, min: 25 }) + handle() + panel());
  key(handlesOf(other.el)[0], "Enter");
  assert.deepEqual(other.component.layout, [40, 60]);
});

test("dragging a collapsible panel past halfway collapses it", () => {
  const { el, component } = mount(
    panel({ size: 30, min: 20, collapsible: true }) +
      handle() +
      panel({ size: 70 }),
  );
  const [h] = handlesOf(el);
  setRect(el, { width: 100, height: 100 });
  setRect(h, { width: 0 });

  pointer(h, "pointerdown", { clientX: 30 });
  pointer(document, "pointermove", { clientX: 15 });
  assert.deepEqual(component.layout, [20, 80]);
  pointer(document, "pointermove", { clientX: 8 });
  assert.deepEqual(component.layout, [0, 100]);
  pointer(document, "pointerup", { clientX: 8 });
});
