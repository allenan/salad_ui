import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import InputGroupComponent from "../salad_ui/components/input_group.js";
import { registry } from "../salad_ui/core/factory.js";
import { installDom, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function mount(html) {
  document.body.innerHTML = html;
  const el = document.querySelector('[data-component="input-group"]');
  const component = new InputGroupComponent(el, {
    pushEventTo() {},
    liveSocket: { execJS: () => {} },
  });
  component.setupEvents();
  return { el, component };
}

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
}

const BASIC = `
  <div id="g" data-component="input-group" data-slot="input-group" data-part="root" role="group">
    <input data-slot="input-group-control" id="control" />
    <div data-slot="input-group-addon" data-part="addon" data-align="inline-start" role="group">
      <span id="icon">@</span>
    </div>
    <div data-slot="input-group-addon" data-part="addon" data-align="inline-end" role="group">
      <span id="text">USD</span>
      <button type="button" id="btn"><span id="btn-icon">x</span></button>
      <a href="#" id="link">link</a>
    </div>
  </div>
`;

test("registers as input-group", () => {
  assert.equal(registry.registry.get("input-group"), InputGroupComponent);
});

test("clicking an addon focuses the control", () => {
  const { component } = mount(BASIC);
  const control = document.getElementById("control");

  click(document.getElementById("icon"));
  assert.equal(document.activeElement, control);

  control.blur();
  click(document.querySelectorAll('[data-slot="input-group-addon"]')[1]);
  assert.equal(document.activeElement, control);

  component.destroy();
});

test("clicking a button or link inside an addon does not move focus", () => {
  const { component } = mount(BASIC);
  const control = document.getElementById("control");
  const btn = document.getElementById("btn");

  btn.focus();
  click(document.getElementById("btn-icon"));
  assert.equal(document.activeElement, btn);

  click(document.getElementById("link"));
  assert.notEqual(document.activeElement, control);

  component.destroy();
});

test("clicks outside addons are ignored", () => {
  const { el, component } = mount(BASIC);

  click(el);
  assert.notEqual(document.activeElement, document.getElementById("control"));

  component.destroy();
});

test("focuses a textarea control and prefers data-slot=input-group-control", () => {
  const { component } = mount(`
    <div id="g" data-component="input-group" data-slot="input-group" data-part="root">
      <input type="hidden" name="token" value="x" />
      <textarea id="plain"></textarea>
      <div data-slot="input-group-control" contenteditable="true" tabindex="0" id="custom"></div>
      <div data-slot="input-group-addon" data-part="addon" data-align="block-end">
        <span id="counter">120 characters left</span>
      </div>
    </div>
  `);

  click(document.getElementById("counter"));
  assert.equal(document.activeElement, document.getElementById("custom"));

  component.destroy();
});

test("falls back to the first input when no control is tagged", () => {
  const { component } = mount(`
    <div id="g" data-component="input-group" data-slot="input-group" data-part="root">
      <textarea id="plain"></textarea>
      <div data-slot="input-group-addon" data-part="addon" data-align="block-start">
        <span id="title">script.js</span>
      </div>
    </div>
  `);

  click(document.getElementById("title"));
  assert.equal(document.activeElement, document.getElementById("plain"));

  component.destroy();
});

test("an addon of a nested group only focuses its own control", () => {
  const { component } = mount(`
    <div id="outer" data-component="input-group" data-slot="input-group" data-part="root">
      <input data-slot="input-group-control" id="outer-control" />
      <div data-slot="input-group-addon" data-part="addon">
        <div id="inner" data-slot="input-group">
          <input data-slot="input-group-control" id="inner-control" />
          <div data-slot="input-group-addon" data-part="addon">
            <span id="inner-icon">i</span>
          </div>
        </div>
      </div>
    </div>
  `);

  click(document.getElementById("inner-icon"));
  assert.notEqual(
    document.activeElement,
    document.getElementById("outer-control"),
  );

  component.destroy();
});

test("applies the group role and survives LiveView patches", () => {
  const { el, component } = mount(BASIC);

  assert.equal(el.getAttribute("role"), "group");
  for (const addon of el.querySelectorAll('[data-slot="input-group-addon"]')) {
    assert.equal(addon.getAttribute("role"), "group");
  }
  assert.equal(component.skipReinitialize(el), true);

  // An addon added by a patch still focuses the control.
  el.insertAdjacentHTML(
    "beforeend",
    '<div data-slot="input-group-addon" data-part="addon"><span id="late">!</span></div>',
  );
  click(document.getElementById("late"));
  assert.equal(document.activeElement, document.getElementById("control"));

  component.destroy();
});

test("destroy removes the click listener", () => {
  const { component } = mount(BASIC);
  const control = document.getElementById("control");

  component.destroy();
  click(document.getElementById("icon"));
  assert.notEqual(document.activeElement, control);
});
