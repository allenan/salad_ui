import assert from "node:assert/strict";
import { after, before, beforeEach, test } from "node:test";

import Positioner from "../salad_ui/core/positioner.js";
import { installDom, setRect, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

let element;
let reference;

beforeEach(() => {
  document.body.innerHTML = "";
  element = document.createElement("div");
  reference = document.createElement("div");
  document.body.append(element, reference);
});

test("calculate(): bottom/center placement sits below and centered on the reference", () => {
  setRect(reference, {
    top: 100,
    bottom: 140,
    left: 200,
    right: 300,
    width: 100,
  });
  setRect(element, { width: 50, height: 20 });

  const position = Positioner.calculate(element, reference, {
    placement: "bottom",
    alignment: "center",
  });

  assert.deepEqual(position, { x: 225, y: 148, placement: "bottom" });
});

test("calculate(): start/end alignment position against the reference edges", () => {
  setRect(reference, {
    top: 100,
    bottom: 140,
    left: 200,
    right: 300,
    width: 100,
  });
  setRect(element, { width: 50, height: 20 });

  const start = Positioner.calculate(element, reference, {
    placement: "bottom",
    alignment: "start",
  });
  const end = Positioner.calculate(element, reference, {
    placement: "bottom",
    alignment: "end",
  });

  assert.equal(start.x, 200);
  assert.equal(end.x, 250);
});

test("calculate(): right/left placement offsets horizontally and centers vertically", () => {
  setRect(reference, {
    top: 100,
    bottom: 140,
    left: 200,
    right: 300,
    height: 40,
  });
  setRect(element, { width: 50, height: 20 });

  const right = Positioner.calculate(element, reference, {
    placement: "right",
    alignment: "center",
  });
  const left = Positioner.calculate(element, reference, {
    placement: "left",
    alignment: "center",
  });

  assert.deepEqual(right, { x: 308, y: 110, placement: "right" });
  assert.deepEqual(left, { x: 142, y: 110, placement: "left" });
});

test("calculate(): flips top to bottom when the element would overflow above the viewport", () => {
  setRect(reference, { top: 5, bottom: 45, left: 200, right: 300, width: 100 });
  setRect(element, { width: 50, height: 20 });

  const position = Positioner.calculate(element, reference, {
    placement: "top",
    alignment: "center",
  });

  assert.equal(position.placement, "bottom");
  assert.equal(position.y, 53);
});

test("calculate(): flip: false keeps the requested placement even when it overflows", () => {
  setRect(reference, { top: 5, bottom: 45, left: 200, right: 300, width: 100 });
  setRect(element, { width: 50, height: 20 });

  const position = Positioner.calculate(element, reference, {
    placement: "top",
    alignment: "center",
    flip: false,
  });

  assert.equal(position.placement, "top");
  assert.equal(position.y, -23);
});

test("calculate(): shifts start-aligned content back inside the viewport", () => {
  const right = window.innerWidth;
  setRect(reference, {
    top: 300,
    bottom: 330,
    left: right - 40,
    right: right - 10,
    width: 30,
  });
  setRect(element, { width: 256, height: 100 });

  const position = Positioner.calculate(element, reference, {
    placement: "top",
    alignment: "start",
  });

  assert.equal(position.x, right - 256, "flush with the right edge");
  assert.equal(position.y, 192);
});

test("calculate(): shift never detaches content from the trigger", () => {
  setRect(reference, {
    top: 300,
    bottom: 330,
    left: -100,
    right: -60,
    width: 40,
  });
  setRect(element, { width: 50, height: 20 });

  const position = Positioner.calculate(element, reference, {
    placement: "bottom",
    alignment: "start",
  });

  assert.equal(position.x, -60, "stops at the trigger's far edge");
});

test("calculate(): shift: false keeps the aligned position", () => {
  const right = window.innerWidth;
  setRect(reference, {
    top: 300,
    bottom: 330,
    left: right - 40,
    right: right - 10,
    width: 30,
  });
  setRect(element, { width: 256, height: 100 });

  const position = Positioner.calculate(element, reference, {
    placement: "top",
    alignment: "start",
    shift: false,
  });

  assert.equal(position.x, right - 40);
});

test("applyPosition(): sets fixed positioning at the given coordinates", () => {
  Positioner.applyPosition(element, 12, 34);

  assert.equal(element.style.position, "fixed");
  assert.equal(element.style.top, "34px");
  assert.equal(element.style.left, "12px");
  assert.equal(element.style.margin, "0px"); // jsdom normalizes the "0" shorthand
});

test("findScrollableParents(): collects only overflow-scrollable ancestors, plus window", () => {
  document.body.innerHTML = `
    <div id="scrollable-outer" style="overflow-y: auto;">
      <div id="static-middle">
        <div id="scrollable-inner" style="overflow-x: scroll;">
          <span id="leaf"></span>
        </div>
      </div>
    </div>
  `;
  const leaf = document.getElementById("leaf");

  const parents = Positioner.findScrollableParents(leaf);

  assert.deepEqual(
    parents.slice(0, -1).map((el) => el.id),
    ["scrollable-inner", "scrollable-outer"],
  );
  assert.equal(parents[parents.length - 1], window);
});

test("calculate(): collisionPadding keeps shifted content off the viewport edge", () => {
  const right = window.innerWidth;
  setRect(reference, {
    top: 300,
    bottom: 330,
    left: right - 40,
    right: right - 10,
    width: 30,
  });
  setRect(element, { width: 256, height: 100 });

  const position = Positioner.calculate(element, reference, {
    placement: "top",
    alignment: "start",
    collisionPadding: 8,
  });
  assert.equal(position.x, right - 256 - 8);

  // Read from data-collision-padding when no option is given.
  element.setAttribute("data-collision-padding", "12");
  const fromAttr = Positioner.calculate(element, reference, {
    placement: "top",
    alignment: "start",
  });
  assert.equal(fromAttr.x, right - 256 - 12);

  element.setAttribute("data-collision-padding", "0");
  const none = Positioner.calculate(element, reference, {
    placement: "top",
    alignment: "start",
  });
  assert.equal(none.x, right - 256, "0 (Radix's default) is flush");
});

test("calculate(): collisionPadding counts for flipping", () => {
  setRect(reference, {
    top: 50,
    bottom: 70,
    left: 100,
    right: 200,
    width: 100,
  });
  setRect(element, { width: 50, height: 40 });

  const options = { placement: "top", alignment: "center", sideOffset: 4 };
  // 50 - 40 - 4 = 6px of room above: fits without padding.
  assert.equal(
    Positioner.calculate(element, reference, options).placement,
    "top",
  );
  assert.equal(
    Positioner.calculate(element, reference, {
      ...options,
      collisionPadding: 10,
    }).placement,
    "bottom",
  );
});
