// Trace rows (lib/salad_ui/trace.ex) reuse the collapsible JS component with a
// native <button> trigger, and nest: a summary row holds step rows that are
// collapsibles themselves. These tests pin that markup to the collapsible
// behaviour it relies on.
import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/collapsible.js"; // self-registers "collapsible"
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function row(id, { open = false, inner = "" } = {}) {
  return `
    <div id="${id}" data-slot="trace-collapsible" data-component="collapsible"
         data-state="${open ? "open" : "closed"}"
         data-options='${JSON.stringify({ open })}' data-event-mappings='{}'
         data-part="root" phx-hook="SaladUI">
      <button type="button" data-slot="trace-collapsible-trigger" data-part="trigger"
              data-action="toggle" aria-expanded="false">
        <span data-slot="trace-line"><span data-slot="trace-title">${id}</span></span>
      </button>
      <div data-slot="trace-collapsible-content" data-part="content" hidden>
        <div data-slot="trace-collapsible-content-inner">${inner}</div>
      </div>
    </div>`;
}

function build() {
  document.body.innerHTML = row("summary", {
    open: true,
    inner: `<div data-slot="trace">${row("step")}</div>`,
  });

  const hookContext = {
    pushEventTo: () => {},
    liveSocket: { execJS: () => {} },
  };
  const summaryEl = document.getElementById("summary");
  const stepEl = document.getElementById("step");
  registry.create("collapsible", summaryEl, hookContext);
  registry.create("collapsible", stepEl, hookContext);

  const parts = (el) => ({
    el,
    trigger: el.querySelector(":scope > [data-part=trigger]"),
    content: el.querySelector(":scope > [data-part=content]"),
  });

  return { summary: parts(summaryEl), step: parts(stepEl) };
}

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
}

function keydown(el, key) {
  const event = new window.KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);
  return event;
}

test("an open row shows its content and sets aria-expanded on the button", () => {
  const { summary, step } = build();

  assert.equal(summary.el.getAttribute("data-state"), "open");
  assert.equal(summary.content.hidden, false);
  assert.equal(summary.trigger.getAttribute("aria-expanded"), "true");

  assert.equal(step.el.getAttribute("data-state"), "closed");
  assert.equal(step.content.hidden, true);
  assert.equal(step.trigger.getAttribute("aria-expanded"), "false");
});

test("a nested row toggles on its own without closing its parent", async () => {
  const { summary, step } = build();

  click(step.trigger);
  await waitFor(() => step.el.getAttribute("data-state") === "open");
  assert.equal(step.trigger.getAttribute("aria-expanded"), "true");
  assert.equal(summary.el.getAttribute("data-state"), "open");
  assert.equal(summary.trigger.getAttribute("aria-expanded"), "true");
});

test("closing the parent leaves the nested row's own state alone", async () => {
  const { summary, step } = build();

  click(summary.trigger);
  await waitFor(() => summary.el.getAttribute("data-state") === "closed");
  assert.equal(summary.trigger.getAttribute("aria-expanded"), "false");
  assert.equal(step.el.getAttribute("data-state"), "closed");
  assert.equal(step.trigger.getAttribute("aria-expanded"), "false");
});

test("Enter and Space on the button toggle once and suppress the native click", async () => {
  const { step } = build();

  const enter = keydown(step.trigger, "Enter");
  assert.equal(enter.defaultPrevented, true);
  await waitFor(() => step.el.getAttribute("data-state") === "open");

  const space = keydown(step.trigger, " ");
  assert.equal(space.defaultPrevented, true);
  await waitFor(() => step.el.getAttribute("data-state") === "closed");
});
