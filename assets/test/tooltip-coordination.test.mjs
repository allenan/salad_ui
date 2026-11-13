import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import "../salad_ui/components/tooltip.js";
import { registry } from "../salad_ui/core/factory.js";
import { installDom, setRect, uninstallDom, wait } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

const created = [];
afterEach(() => {
  created.splice(0).forEach((c) => c.destroy());
  document.body.innerHTML = "";
});

const hookContext = {
  pushEventTo: () => {},
  liveSocket: { execJS: () => {} },
};

function tooltipMarkup(id) {
  return `
    <div id="${id}" data-component="tooltip" data-state="closed"
         data-options='{"openDelay":5,"closeDelay":5}' data-part="root">
      <button type="button" data-part="trigger" id="${id}-trigger">Help</button>
      <div data-part="content" hidden>Tip ${id}</div>
    </div>`;
}

function mount(id) {
  const el = document.getElementById(id);
  const trigger = el.querySelector('[data-part="trigger"]');
  const content = el.querySelector('[data-part="content"]');
  setRect(trigger, {
    top: 10,
    right: 60,
    bottom: 30,
    left: 10,
    width: 50,
    height: 20,
  });
  setRect(content, { width: 80, height: 40 });
  const component = registry.create("tooltip", el, hookContext);
  created.push(component);
  return { el, trigger, content, component };
}

function fire(type, target, init = {}) {
  const Ctor = type.startsWith("pointer")
    ? window.PointerEvent || window.MouseEvent
    : type.startsWith("mouse")
      ? window.MouseEvent
      : type === "keydown"
        ? window.KeyboardEvent
        : window.Event;
  target.dispatchEvent(
    new Ctor(type, { bubbles: true, cancelable: true, ...init }),
  );
}

test("leaving the trigger before the open delay ends never opens it", async () => {
  document.body.innerHTML = tooltipMarkup("t1") + '<div id="away"></div>';
  const { trigger, component } = mount("t1");

  fire("mouseover", trigger);
  fire("mouseout", trigger, { relatedTarget: document.getElementById("away") });
  await wait(20);

  assert.equal(component.state, "closed");
});

test("opening a tooltip closes the one already open", async () => {
  document.body.innerHTML = tooltipMarkup("t1") + tooltipMarkup("t2");
  const a = mount("t1");
  const b = mount("t2");

  fire("mouseover", a.trigger);
  await wait(15);
  assert.equal(a.component.state, "open");

  fire("mouseover", b.trigger);
  await wait(15);
  assert.equal(b.component.state, "open");
  assert.equal(a.component.state, "closed");
});

test("pressing the trigger closes the tooltip", async () => {
  document.body.innerHTML = tooltipMarkup("t1");
  const { trigger, component } = mount("t1");

  fire("mouseover", trigger);
  await wait(15);
  assert.equal(component.state, "open");

  fire("pointerdown", trigger);
  assert.equal(component.state, "closed");
});

test("Escape closes it", async () => {
  document.body.innerHTML = tooltipMarkup("t1");
  const { trigger, component } = mount("t1");

  fire("mouseover", trigger);
  await wait(15);
  fire("keydown", document.body, { key: "Escape" });

  assert.equal(component.state, "closed");
});

test("scrolling a container around the trigger closes it", async () => {
  document.body.innerHTML = `<div id="scroller">${tooltipMarkup("t1")}</div>`;
  const { trigger, component } = mount("t1");

  fire("mouseover", trigger);
  await wait(15);
  document.getElementById("scroller").dispatchEvent(new window.Event("scroll"));

  assert.equal(component.state, "closed");
});

test("a pointer that is elsewhere closes a tooltip whose mouseout was missed", async () => {
  document.body.innerHTML = tooltipMarkup("t1") + '<div id="away"></div>';
  const { trigger, component } = mount("t1");

  fire("mouseover", trigger);
  await wait(15);
  fire("pointermove", document.getElementById("away"), {
    pointerType: "mouse",
  });
  await wait(15);

  assert.equal(component.state, "closed");
});

test("focus that follows a click does not open it; keyboard focus does", async () => {
  document.body.innerHTML = tooltipMarkup("t1");
  const { trigger, component } = mount("t1");

  fire("pointerdown", document.body);
  fire("focusin", trigger);
  await wait(15);
  assert.equal(component.state, "closed");

  fire("keydown", document.body, { key: "Tab" });
  fire("focusin", trigger);
  await wait(15);
  assert.equal(component.state, "open");
});

test("an open popup blocks tooltips outside its content, not inside", async () => {
  document.body.innerHTML = `
    ${tooltipMarkup("outside")}
    <div data-component="popover" data-state="open">
      <div data-slot="popover-content" data-state="open">${tooltipMarkup("inside")}</div>
    </div>`;
  const outside = mount("outside");
  const inside = mount("inside");

  fire("mouseover", outside.trigger);
  await wait(15);
  assert.equal(outside.component.state, "closed");

  fire("mouseover", inside.trigger);
  await wait(15);
  assert.equal(inside.component.state, "open");
});
