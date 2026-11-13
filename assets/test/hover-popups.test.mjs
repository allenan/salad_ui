import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import "../salad_ui/components/tooltip.js";
import "../salad_ui/components/hover-card.js";
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

const tooltip = (id) => `
  <div id="${id}" data-component="tooltip" data-state="closed"
       data-options='{"openDelay":5,"closeDelay":5}' data-part="root">
    <button type="button" data-part="trigger">Help</button>
    <div data-part="content" hidden>Tip</div>
  </div>`;

const hoverCard = (id, inner = "Profile") => `
  <div id="${id}" data-component="hover-card" data-state="closed"
       data-options='{"openDelay":5,"closeDelay":5}' data-part="root">
    <span data-part="trigger">@${id}</span>
    <div data-part="content" data-slot="hover-card-content" hidden>${inner}</div>
  </div>`;

function mount(id, type) {
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
  const component = registry.create(type, el, hookContext);
  created.push(component);
  return { el, trigger, content, component };
}

function fire(type, target, init = {}) {
  const Ctor = type.startsWith("pointer")
    ? window.PointerEvent || window.MouseEvent
    : type.startsWith("mouse")
      ? window.MouseEvent
      : window.Event;
  const bubbles = !["mouseenter", "mouseleave"].includes(type);
  target.dispatchEvent(new Ctor(type, { bubbles, cancelable: true, ...init }));
}

test("a hover card left before its open delay ends never opens", async () => {
  document.body.innerHTML = hoverCard("maya");
  const card = mount("maya", "hover-card");

  fire("mouseenter", card.trigger);
  fire("mouseleave", card.trigger);
  await wait(20);

  assert.equal(card.component.state, "closed");
});

test("opening a hover card closes the one already open", async () => {
  document.body.innerHTML = hoverCard("maya") + hoverCard("kai");
  const maya = mount("maya", "hover-card");
  const kai = mount("kai", "hover-card");

  fire("mouseenter", maya.trigger);
  await wait(15);
  assert.equal(maya.component.state, "open");

  fire("mouseenter", kai.trigger);
  await wait(15);
  assert.equal(kai.component.state, "open");
  assert.equal(maya.component.state, "closed");
});

test("a tooltip inside an open hover card keeps the card open", async () => {
  document.body.innerHTML = hoverCard("maya", tooltip("inner"));
  const card = mount("maya", "hover-card");
  const tip = mount("inner", "tooltip");

  fire("mouseenter", card.trigger);
  await wait(15);
  fire("mouseenter", card.content);
  fire("mouseover", tip.trigger);
  await wait(15);

  assert.equal(tip.component.state, "open");
  assert.equal(card.component.state, "open");
});

test("a tooltip elsewhere closes an open hover card", async () => {
  document.body.innerHTML = hoverCard("maya") + tooltip("outer");
  const card = mount("maya", "hover-card");
  const tip = mount("outer", "tooltip");

  fire("mouseenter", card.trigger);
  await wait(15);
  fire("mouseover", tip.trigger);
  await wait(15);

  assert.equal(tip.component.state, "open");
  assert.equal(card.component.state, "closed");
});

test("a hover card closes when the pointer is seen elsewhere or the page scrolls", async () => {
  document.body.innerHTML = `<div id="list">${hoverCard("maya")}</div><div id="away"></div>`;
  const card = mount("maya", "hover-card");

  fire("mouseenter", card.trigger);
  await wait(15);
  fire("pointermove", document.getElementById("away"), {
    pointerType: "mouse",
  });
  await wait(15);
  assert.equal(card.component.state, "closed");

  fire("mouseenter", card.trigger);
  await wait(15);
  document.getElementById("list").dispatchEvent(new window.Event("scroll"));
  assert.equal(card.component.state, "closed");
});

test("no hover card opens while a menu is open", async () => {
  document.body.innerHTML =
    hoverCard("maya") +
    '<div data-component="dropdown-menu" data-state="open"></div>';
  const card = mount("maya", "hover-card");

  fire("mouseenter", card.trigger);
  await wait(15);

  assert.equal(card.component.state, "closed");
});
