import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import SaladUI from "../salad_ui/index.js";
import {
  getDirection,
  isRtl,
  mirrorAlignment,
} from "../salad_ui/core/direction.js";
import { registry } from "../salad_ui/core/factory.js";
import Portal from "../salad_ui/core/portal.js";
import Positioner from "../salad_ui/core/positioner.js";
import PositionedElement from "../salad_ui/core/positioned-element.js";
import SliderComponent from "../salad_ui/components/slider.js";
import "../salad_ui/components/tabs.js";
import "../salad_ui/components/radio_group.js";
import { installDom, setRect, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

const hookContext = () => ({
  pushEventTo: () => {},
  liveSocket: { execJS: () => {} },
});

function keydown(el, key) {
  const event = new window.KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);
  return event;
}

// ---------------------------------------------------------------------------
// getDirection / helpers
// ---------------------------------------------------------------------------

test("getDirection(): nearest dir attribute wins, defaulting to ltr", () => {
  document.body.innerHTML = `
    <div id="none"></div>
    <div dir="rtl">
      <span id="rtl"></span>
      <div dir="ltr"><span id="nested-ltr"></span></div>
      <div dir="RTL"><span id="upper"></span></div>
    </div>
  `;
  const $ = (id) => document.getElementById(id);

  assert.equal(getDirection($("none")), "ltr");
  assert.equal(getDirection($("rtl")), "rtl");
  assert.equal(getDirection($("nested-ltr")), "ltr");
  assert.equal(getDirection($("upper")), "rtl");
  assert.equal(isRtl($("rtl")), true);
  assert.equal(isRtl($("none")), false);
});

test("getDirection(): missing elements and dir=auto fall back safely", () => {
  document.body.innerHTML = `<div dir="auto"><span id="auto"></span></div>`;

  assert.equal(getDirection(null), "ltr");
  assert.equal(getDirection(undefined), "ltr");
  assert.equal(getDirection({}), "ltr");
  // jsdom computes no direction for dir=auto: treated as ltr.
  assert.equal(getDirection(document.getElementById("auto")), "ltr");
});

test("getDirection(): follows a dir attribute toggled after the fact", () => {
  document.body.innerHTML = `<div id="host"><span id="child"></span></div>`;
  const child = document.getElementById("child");

  assert.equal(getDirection(child), "ltr");
  document.getElementById("host").setAttribute("dir", "rtl");
  assert.equal(getDirection(child), "rtl");
});

test("SaladUI.getDirection is exported (useDirection counterpart)", () => {
  document.body.innerHTML = `<div dir="rtl"><i id="x"></i></div>`;
  assert.equal(SaladUI.getDirection(document.getElementById("x")), "rtl");
});

test("mirrorAlignment() only changes under rtl", () => {
  assert.equal(mirrorAlignment("start", "ltr"), "start");
  assert.equal(mirrorAlignment("start", "rtl"), "end");
  assert.equal(mirrorAlignment("end", "rtl"), "start");
  assert.equal(mirrorAlignment("center", "rtl"), "center");
});

// ---------------------------------------------------------------------------
// Positioner / PositionedElement
// ---------------------------------------------------------------------------

function positionFixture() {
  document.body.innerHTML = "";
  const element = document.createElement("div");
  const reference = document.createElement("div");
  document.body.append(element, reference);
  setRect(reference, {
    top: 100,
    bottom: 140,
    left: 200,
    right: 300,
    width: 100,
    height: 40,
  });
  setRect(element, { width: 50, height: 20 });
  return { element, reference };
}

test("Positioner: rtl mirrors start/end alignment for top/bottom sides", () => {
  const { element, reference } = positionFixture();
  const at = (options) =>
    Positioner.calculate(element, reference, { dir: "rtl", ...options });

  // `start` lines up with the reference's right edge, `end` with its left.
  assert.equal(at({ placement: "bottom", alignment: "start" }).x, 250);
  assert.equal(at({ placement: "bottom", alignment: "end" }).x, 200);
  assert.equal(at({ placement: "top", alignment: "start" }).x, 250);
  assert.equal(at({ placement: "bottom", alignment: "center" }).x, 225);
  // A positive alignOffset moves away from the start edge, i.e. leftwards.
  assert.equal(
    at({ placement: "bottom", alignment: "start", alignOffset: 10 }).x,
    240,
  );
});

test("Positioner: left/right sides stay physical under rtl", () => {
  const { element, reference } = positionFixture();

  const ltr = Positioner.calculate(element, reference, {
    placement: "left",
    alignment: "start",
  });
  const rtl = Positioner.calculate(element, reference, {
    placement: "left",
    alignment: "start",
    dir: "rtl",
  });

  assert.deepEqual(rtl, ltr);
  assert.equal(rtl.placement, "left");
  assert.equal(rtl.x, 200 - 50 - 8);
  assert.equal(rtl.y, 100);
});

test("PositionedElement: reads the reference's direction, or an explicit dir", () => {
  document.body.innerHTML = `
    <div dir="rtl">
      <button id="reference">ref</button>
      <div id="positioned">content</div>
    </div>
  `;
  const reference = document.getElementById("reference");
  const element = document.getElementById("positioned");
  setRect(reference, {
    top: 100,
    bottom: 140,
    left: 200,
    right: 300,
    width: 100,
    height: 40,
  });
  setRect(element, { width: 50, height: 20 });

  const pe = new PositionedElement(element, reference, {
    placement: "bottom",
    alignment: "start",
  });
  pe.activate();
  assert.equal(pe.direction(), "rtl");
  assert.equal(element.style.left, "250px");

  pe.updateOptions({ dir: "ltr" });
  assert.equal(pe.direction(), "ltr");
  assert.equal(element.style.left, "200px");
  pe.destroy();
});

// ---------------------------------------------------------------------------
// Portal
// ---------------------------------------------------------------------------

test("Portal.move(): carries an inherited rtl direction out, and drops it on restore", () => {
  document.body.innerHTML = `<div dir="rtl" id="scope"><div id="content"></div></div>`;
  const content = document.getElementById("content");

  Portal.move(content, document.body);
  assert.equal(content.parentElement, document.body);
  assert.equal(content.getAttribute("dir"), "rtl");

  Portal.restore(content);
  assert.equal(content.parentElement.id, "scope");
  assert.equal(content.hasAttribute("dir"), false);
});

test("Portal.move(): leaves dir alone when nothing changes or it is explicit", () => {
  document.body.innerHTML = `
    <div id="plain"><div id="ltr-content"></div></div>
    <div dir="rtl"><div id="own" dir="ltr"></div></div>
  `;
  const ltrContent = document.getElementById("ltr-content");
  const own = document.getElementById("own");

  Portal.move(ltrContent, document.body);
  assert.equal(ltrContent.hasAttribute("dir"), false);
  Portal.restore(ltrContent);

  Portal.move(own, document.body);
  assert.equal(own.getAttribute("dir"), "ltr");
  Portal.restore(own);
  assert.equal(own.getAttribute("dir"), "ltr");
});

// ---------------------------------------------------------------------------
// Keyboard: tabs, radio group
// ---------------------------------------------------------------------------

function buildTabs({ dir = "rtl", orientation } = {}) {
  const triggers = ["one", "two", "three"]
    .map(
      (v) =>
        `<button type="button" data-part="trigger" data-value="${v}" data-state="inactive" data-disabled="false">${v}</button>`,
    )
    .join("");
  const contents = ["one", "two", "three"]
    .map(
      (v) =>
        `<div data-part="content" data-value="${v}" data-state="inactive" hidden>${v}</div>`,
    )
    .join("");

  document.body.innerHTML = `
    <div dir="${dir}">
      <div id="tabs" data-component="tabs" data-state="idle"
           data-options='${JSON.stringify({ defaultValue: "two", orientation })}'
           data-event-mappings='{}' data-part="root">
        <div data-part="list">${triggers}</div>
        ${contents}
      </div>
    </div>
  `;
  const el = document.getElementById("tabs");
  const component = registry.create("tabs", el, hookContext());
  const trigger = (v) =>
    el.querySelector(`[data-part="trigger"][data-value="${v}"]`);
  return { component, trigger };
}

test("tabs: horizontal arrow keys follow the reading direction under rtl", () => {
  const { component, trigger } = buildTabs();
  assert.equal(component.isRtl(), true);

  trigger("two").focus();
  keydown(trigger("two"), "ArrowLeft");
  assert.equal(document.activeElement, trigger("three"));
  assert.equal(trigger("three").getAttribute("data-state"), "active");

  keydown(trigger("three"), "ArrowRight");
  keydown(trigger("two"), "ArrowRight");
  assert.equal(document.activeElement, trigger("one"));
});

test("tabs: vertical tabs ignore direction", () => {
  const { trigger } = buildTabs({ orientation: "vertical" });

  trigger("two").focus();
  keydown(trigger("two"), "ArrowDown");
  assert.equal(document.activeElement, trigger("three"));
});

test("radio group: ArrowLeft moves to the next item under rtl", () => {
  document.body.innerHTML = `
    <div dir="rtl">
      <div id="plan" data-component="radio-group" data-state="idle"
           data-options='${JSON.stringify({ name: "plan", initialValue: "a" })}'
           data-event-mappings='{}' data-part="root">
        ${["a", "b", "c"]
          .map(
            (v) => `
          <div data-part="item" data-value="${v}" data-state="unchecked" data-disabled="false" tabindex="-1">
            <input type="radio" id="${v}" value="${v}" class="sr-only" tabindex="-1" />
          </div>`,
          )
          .join("")}
      </div>
    </div>
  `;
  const el = document.getElementById("plan");
  registry.create("radio-group", el, hookContext());
  const item = (v) => el.querySelector(`[data-part="item"][data-value="${v}"]`);

  item("a").focus();
  keydown(item("a"), "ArrowLeft");
  assert.equal(item("b").getAttribute("data-state"), "checked");

  keydown(item("b"), "ArrowRight");
  assert.equal(item("a").getAttribute("data-state"), "checked");

  // Up/Down are not mirrored.
  keydown(item("a"), "ArrowDown");
  assert.equal(item("b").getAttribute("data-state"), "checked");
});

// ---------------------------------------------------------------------------
// Slider
// ---------------------------------------------------------------------------

function buildSlider({ wrapperDir = "rtl", dir } = {}) {
  document.body.innerHTML = `
    <div id="wrapper" dir="${wrapperDir}">
      <div id="slider" data-component="slider" data-state="idle" data-value="50"
           data-options='${JSON.stringify({ min: 0, max: 100, step: 1, dir: dir ?? null })}'
           data-event-mappings='{}' data-part="root">
        <span data-part="track"><span data-part="range"></span></span>
        <span data-part="thumb" data-index="0" role="slider" tabindex="0"></span>
        <input type="hidden" data-index="0" name="v" value="50" />
      </div>
    </div>
  `;
  const el = document.getElementById("slider");
  setRect(el.querySelector('[data-part="track"]'), {
    left: 0,
    right: 100,
    width: 100,
    height: 6,
  });
  const thumb = el.querySelector('[data-part="thumb"]');
  setRect(thumb, { width: 20, height: 20 });
  const slider = new SliderComponent(el, hookContext());
  slider.setupEvents();
  return { slider, thumb };
}

test("slider: inherits rtl from an ancestor when no dir option is set", () => {
  const { slider, thumb } = buildSlider();

  assert.equal(slider.dir, "rtl");
  assert.equal(slider.startEdge, "right");
  // Placed with logical insets, which the browser resolves to the right.
  assert.equal(
    thumb.style.getPropertyValue("inset-inline-start"),
    "calc(50% - 10px)",
  );
  assert.equal(thumb.style.right, "");

  keydown(thumb, "ArrowLeft");
  assert.equal(slider.value, 51);
});

test("slider: its own dir option wins over the inherited direction", () => {
  const { slider, thumb } = buildSlider({ dir: "ltr" });

  assert.equal(slider.dir, "ltr");
  keydown(thumb, "ArrowLeft");
  assert.equal(slider.value, 49);
});

test("slider: picks up a direction change on the next update", () => {
  const { slider, thumb } = buildSlider({ wrapperDir: "ltr" });
  assert.equal(slider.startEdge, "left");

  document.getElementById("wrapper").setAttribute("dir", "rtl");
  slider.updatePosition();
  assert.equal(slider.startEdge, "right");
  // The styles are logical either way; only keys and pointer math flip.
  assert.equal(
    thumb.style.getPropertyValue("inset-inline-start"),
    "calc(50% - 10px)",
  );
  assert.equal(thumb.style.left, "");
  keydown(thumb, "ArrowLeft");
  assert.equal(slider.value, 51);
});
