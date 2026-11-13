import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { attachFiles } from "../salad_ui/components/drop_zone.js";
import { registry } from "../salad_ui/core/factory.js";
import { installDom, setRect, uninstallDom } from "./helpers/dom.mjs";

const mounted = [];

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  mounted.splice(0).forEach((component) => component.destroy());
  document.body.innerHTML = "";
});

function buildDropZone({ forSelector = "#region", input = "#upload" } = {}) {
  document.body.innerHTML = `
    <div id="region"><p id="inside">Chat</p>
      <div id="drop" data-component="drop-zone" data-part="root" data-state="idle"
           data-options='${JSON.stringify({ for: forSelector, input })}'
           aria-hidden="true" hidden></div>
    </div>
    <p id="outside">Sidebar</p>
    <input id="upload" type="file" />
  `;
  const el = document.getElementById("drop");
  setRect(document.getElementById("region"), {
    top: 10,
    left: 20,
    width: 300,
    height: 200,
  });
  const component = registry.create("drop-zone", el, {});
  mounted.push(component);
  return { el, component, input: document.getElementById("upload") };
}

function drag(type, target, { files = [], types = ["Files"] } = {}) {
  const event = new window.Event(type, { bubbles: true, cancelable: true });
  event.dataTransfer = { types, files, dropEffect: "none" };
  document.getElementById(target).dispatchEvent(event);
  return event;
}

const file = (name) => new window.File(["x"], name, { type: "text/plain" });

test("starts hidden and idle", () => {
  const { el, component } = buildDropZone();
  assert.equal(component.state, "idle");
  assert.equal(el.hidden, true);
});

test("dragging files over the region shows the overlay over it", () => {
  const { el } = buildDropZone();

  drag("dragenter", "inside");
  assert.equal(el.hidden, false);
  assert.equal(el.dataset.state, "active");
  assert.equal(el.style.left, "20px");
  assert.equal(el.style.top, "10px");
  assert.equal(el.style.width, "300px");
  assert.equal(el.style.height, "200px");

  const over = drag("dragover", "inside");
  assert.equal(over.defaultPrevented, true, "allows the drop");
  assert.equal(over.dataTransfer.dropEffect, "copy");
});

test("nested enter/leave pairs keep it shown until the drag leaves", () => {
  const { el } = buildDropZone();

  drag("dragenter", "region");
  drag("dragenter", "inside");
  drag("dragleave", "region");
  assert.equal(el.hidden, false);
  drag("dragleave", "inside");
  assert.equal(el.hidden, true);
  assert.equal(el.dataset.state, "idle");
});

test("ignores drags outside the region and drags without files", () => {
  const { el } = buildDropZone();

  drag("dragenter", "outside");
  assert.equal(el.hidden, true);
  drag("dragenter", "inside", { types: ["text/plain"] });
  assert.equal(el.hidden, true);
  assert.equal(drag("dragover", "outside").defaultPrevented, false);
});

test("a drop hands the files to the upload input and announces them", () => {
  const { el, input } = buildDropZone();
  const tracked = [];
  const announced = [];
  input.addEventListener("track-uploads", (e) => tracked.push(e.detail.files));
  document.addEventListener("drop-zone:files", (e) =>
    announced.push(e.detail.files),
  );

  const files = [file("a.txt"), file("b.txt")];
  drag("dragenter", "inside");
  const drop = drag("drop", "inside", { files });

  assert.equal(drop.defaultPrevented, true);
  assert.equal(el.hidden, true);
  assert.deepEqual(tracked, [files]);
  assert.deepEqual(announced, [files]);
});

test("the region defaults to the overlay's parent", () => {
  const { el } = buildDropZone({ forSelector: null });
  drag("dragenter", "inside");
  assert.equal(el.hidden, false);
});

test("a drag that ends elsewhere hides it", () => {
  const { el } = buildDropZone();
  drag("dragenter", "inside");
  window.dispatchEvent(new window.Event("dragend"));
  assert.equal(el.hidden, true);
});

test("destroy removes the document listeners", () => {
  const { el, component } = buildDropZone();
  component.destroy();
  mounted.length = 0;
  drag("dragenter", "inside");
  assert.equal(el.hidden, true);
});

test("a patch with the same options keeps the instance and its state", () => {
  const { el, component } = buildDropZone();
  drag("dragenter", "inside");
  el.hidden = true;
  el.removeAttribute("data-state");

  assert.equal(component.skipReinitialize(el), true);
  assert.equal(el.hidden, false);
  assert.equal(el.dataset.state, "active");

  el.setAttribute("data-options", '{"for":"#other"}');
  assert.equal(component.skipReinitialize(el), false);
});

test("attachFiles hands files to an input and skips anything else", () => {
  const input = document.createElement("input");
  const seen = [];
  input.addEventListener("track-uploads", (e) => seen.push(e.detail.files));

  assert.equal(attachFiles(input, [file("a.txt"), "not a file"]), true);
  assert.equal(seen[0].length, 1);
  assert.equal(attachFiles(input, []), false);
  assert.equal(attachFiles(null, [file("a.txt")]), false);
});
