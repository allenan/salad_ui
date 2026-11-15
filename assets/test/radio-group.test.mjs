import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/radio_group.js"; // self-registers "radio-group"
import { installDom, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function buildRadioGroup({
  id = "plan",
  name = "subscription",
  initialValue = "monthly",
} = {}) {
  document.body.innerHTML = `
    <div id="${id}" data-component="radio-group" data-state="idle"
         data-options='${JSON.stringify({ name, initialValue })}'
         data-event-mappings='{"value-changed":"plan_changed"}'
         data-part="root">
      <div data-part="item" data-value="monthly" data-state="unchecked" data-disabled="false" tabindex="-1">
        <input type="radio" id="monthly" value="monthly" class="sr-only" tabindex="-1" />
      </div>
      <label for="monthly">Monthly</label>
      <div data-part="item" data-value="yearly" data-state="unchecked" data-disabled="false" tabindex="-1">
        <input type="radio" id="yearly" value="yearly" class="sr-only" tabindex="-1" />
      </div>
      <label id="yearly-label" for="yearly">Yearly</label>
    </div>
  `;

  const el = document.getElementById(id);
  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const component = registry.create("radio-group", el, hookContext);

  return {
    component,
    el,
    pushed,
    item: (value) =>
      el.querySelector(`[data-part="item"][data-value="${value}"]`),
    input: (value) => el.querySelector(`input[value="${value}"]`),
  };
}

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
}

test("initialization applies radio names and accessible labels", () => {
  const { input, item } = buildRadioGroup();

  assert.equal(input("monthly").name, "subscription");
  assert.equal(input("yearly").name, "subscription");
  assert.equal(
    item("monthly").getAttribute("aria-labelledby"),
    "plan-item-monthly-label-0",
  );
  assert.equal(
    document.getElementById("plan-item-monthly-label-0").textContent,
    "Monthly",
  );
  assert.equal(item("yearly").getAttribute("aria-labelledby"), "yearly-label");
});

test("selecting item keeps name and emits value change", () => {
  const { input, item, pushed } = buildRadioGroup();
  const targets = [];
  input("yearly").addEventListener("change", (event) =>
    targets.push(event.target),
  );

  click(item("yearly"));

  assert.equal(input("yearly").checked, true);
  assert.equal(input("yearly").name, "subscription");
  assert.deepEqual(pushed, [
    {
      target: document.getElementById("plan"),
      event: "plan_changed",
      payload: {
        value: "yearly",
        previousValue: "monthly",
        componentId: "plan",
        component: "radio-group",
      },
    },
  ]);
  // LiveView only forwards phx-change from form-associated event targets.
  assert.deepEqual(targets, [input("yearly")]);
});

test("older markup: a label click on the inner radio fires one change", () => {
  const { input, item } = buildRadioGroup();
  const changes = [];
  input("yearly").addEventListener("change", () => changes.push("change"));

  // A <label for> click clicks the native radio inside the item; the browser
  // then checks it and fires its own change event (jsdom too).
  click(input("yearly"));

  assert.equal(item("yearly").getAttribute("data-state"), "checked");
  assert.deepEqual(changes, ["change"]);
});

function buildButtonRadioGroup() {
  document.body.innerHTML = `
    <form id="prefs">
      <div id="plan" data-component="radio-group" data-state="idle"
           data-options='{"name":"subscription","initialValue":"monthly"}'
           data-event-mappings='{}' data-part="root">
        <input type="hidden" name="subscription" value="" />
        <div>
          <button type="button" role="radio" id="monthly" data-part="item" data-value="monthly"
                  value="monthly" data-state="unchecked" aria-checked="false" data-disabled="false" tabindex="-1"></button>
          <input type="radio" data-slot="radio-group-input" value="monthly" aria-hidden="true" tabindex="-1" />
          <label for="monthly">Monthly</label>
        </div>
        <div>
          <button type="button" role="radio" id="yearly" data-part="item" data-value="yearly"
                  value="yearly" data-state="unchecked" aria-checked="false" data-disabled="false" tabindex="-1"></button>
          <input type="radio" data-slot="radio-group-input" value="yearly" aria-hidden="true" tabindex="-1" />
          <label for="yearly">Yearly</label>
        </div>
      </div>
    </form>
  `;
  const el = document.getElementById("plan");
  const component = registry.create("radio-group", el, {
    pushEventTo: () => {},
    liveSocket: { execJS: () => {} },
  });
  return {
    component,
    el,
    item: (value) => document.getElementById(value),
    input: (value) => el.querySelector(`input[type="radio"][value="${value}"]`),
  };
}

test("button items: labels name them natively and no ids are made up", () => {
  const { el, item, input } = buildButtonRadioGroup();

  assert.equal(item("monthly").getAttribute("aria-checked"), "true");
  assert.equal(input("monthly").checked, true);
  assert.equal(input("monthly").name, "subscription");
  assert.equal(item("monthly").hasAttribute("aria-labelledby"), false);
  // Every id in the group is one the markup came with.
  assert.deepEqual(
    [...el.querySelectorAll("[id]")].map((node) => node.id),
    ["monthly", "yearly"],
  );
  assert.equal(
    [...el.querySelectorAll("label")].some((label) => label.id),
    false,
  );
});

test("button items: a label click picks the item and fires one change", () => {
  const { item, input } = buildButtonRadioGroup();
  const changes = [];
  document
    .getElementById("prefs")
    .addEventListener("change", (event) => changes.push(event.target));

  click(document.querySelector('label[for="yearly"]'));

  assert.equal(item("yearly").getAttribute("data-state"), "checked");
  assert.equal(item("monthly").getAttribute("aria-checked"), "false");
  assert.equal(input("yearly").checked, true);
  assert.deepEqual(changes, [input("yearly")]);
});

test("button items: Enter does not click the item", () => {
  const { item } = buildButtonRadioGroup();
  const event = new window.KeyboardEvent("keydown", {
    key: "Enter",
    bubbles: true,
    cancelable: true,
  });
  item("yearly").dispatchEvent(event);
  assert.equal(event.defaultPrevented, true);
});
