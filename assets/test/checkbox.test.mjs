import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import CheckboxComponent from "../salad_ui/components/checkbox.js";
import { installDom, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function buildCheckbox({ indeterminate = false, checked = false } = {}) {
  document.body.innerHTML = `
    <input
      type="checkbox"
      id="select-all"
      data-slot="checkbox"
      data-component="checkbox"
      data-part="root"
      data-indeterminate="${indeterminate}"
      phx-hook="SaladUI"
      value="true"
      ${checked ? "checked" : ""}
    />
  `;

  const el = document.getElementById("select-all");
  const hookContext = {
    pushEventTo() {},
    liveSocket: { execJS: () => {} },
  };

  const component = new CheckboxComponent(el, hookContext);
  component.setupEvents();
  component.afterMount();

  return { component, el };
}

test("data-indeterminate=true sets the indeterminate property", () => {
  const { el } = buildCheckbox({ indeterminate: true });

  assert.equal(el.indeterminate, true);
  assert.equal(el.checked, false);
  assert.equal(el.matches(":indeterminate"), true);
});

test("data-indeterminate=false leaves the checkbox determinate", () => {
  const { el } = buildCheckbox({ indeterminate: false, checked: true });

  assert.equal(el.indeterminate, false);
  assert.equal(el.checked, true);
});

test("does not stamp data-state or aria-checked over the native input", () => {
  const { el } = buildCheckbox({ indeterminate: true });

  assert.equal(el.hasAttribute("data-state"), false);
  assert.equal(el.hasAttribute("aria-checked"), false);
});

test("re-initialising after a patch picks up the new value", () => {
  const { component, el } = buildCheckbox({ indeterminate: true });

  // SaladUIHook.updated() destroys and rebuilds the component on a patch.
  el.setAttribute("data-indeterminate", "false");
  el.checked = true;
  component.destroy();
  const rebuilt = new CheckboxComponent(el, {
    pushEventTo() {},
    liveSocket: { execJS: () => {} },
  });
  rebuilt.setupEvents();

  assert.equal(el.indeterminate, false);
  assert.equal(el.checked, true);
});

test("a click clears indeterminate natively and checks the box", () => {
  const { el } = buildCheckbox({ indeterminate: true });

  el.click();

  assert.equal(el.indeterminate, false);
  assert.equal(el.checked, true);
});
