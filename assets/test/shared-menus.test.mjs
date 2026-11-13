import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/dropdown_menu.js"; // self-registers "dropdown-menu"
import "../salad_ui/components/context_menu.js"; // self-registers "context-menu"
import { resetModalLayers } from "../salad_ui/core/modal-layer.js";
import {
  ContextValues,
  listen,
  listenerCount,
  readContext,
} from "../salad_ui/core/detached-triggers.js";
import {
  hookFor,
  installDom,
  setRect,
  simulatePatch,
  uninstallDom,
  wait,
  waitFor,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

const cleanups = [];
afterEach(() => {
  cleanups.splice(0).forEach((cleanup) => cleanup());
  resetModalLayers();
  document.body.innerHTML = "";
});

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
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

function contextmenu(el, x, y) {
  const event = new window.MouseEvent("contextmenu", {
    bubbles: true,
    cancelable: true,
    clientX: x,
    clientY: y,
  });
  el.dispatchEvent(event);
  return event;
}

// Twenty rows like a chat list: each row is a detached context menu trigger
// holding a detached dropdown trigger, outside both shared menus.
function rowsHtml(count = 3) {
  return Array.from(
    { length: count },
    (_, i) => `
      <div id="row-${i + 1}" class="row" data-salad-for="ctx" data-state="closed"
           data-salad-context='{"id":${i + 1}}'>
        Message ${i + 1}
        <button id="more-${i + 1}" type="button" data-salad-for="more"
                data-salad-context='{"id":${i + 1},"kind":"msg"}'
                aria-haspopup="menu" aria-expanded="false" data-state="closed">⋮</button>
      </div>`,
  ).join("");
}

function hookContext(pushed) {
  return {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };
}

function build({ rows = 3, modal = false } = {}) {
  const options = JSON.stringify({ modal });
  document.body.innerHTML = `
    <button id="composer" type="button">composer</button>
    <div id="list" tabindex="-1">${rowsHtml(rows)}</div>
    <div id="more" data-component="dropdown-menu" data-state="closed" data-part="root"
         data-options='${options}'
         data-event-mappings='{"open":"more_open","close":"more_close"}'>
      <div data-part="positioner" data-side="bottom" data-align="end"
           data-side-offset="4" data-align-offset="0" hidden>
        <div data-part="content" tabindex="-1">
          <div data-part="item" data-value="reply" tabindex="-1" phx-click="reply">Reply</div>
          <div data-part="item" data-value="pin" tabindex="-1"
               data-event-mappings='{"select":"pin"}'>Pin</div>
        </div>
      </div>
    </div>
    <div id="ctx" data-component="context-menu" data-state="closed" data-part="root"
         data-options='${options}'
         data-event-mappings='{"open":"ctx_open","close":"ctx_close"}'>
      <div data-part="positioner" data-side="right" hidden>
        <div data-part="content" role="menu" tabindex="-1">
          <div data-part="item" data-value="copy" tabindex="-1" phx-click="copy">Copy</div>
          <div data-part="item" data-value="delete" tabindex="-1"
               data-event-mappings='{"select":"delete"}'>Delete</div>
        </div>
      </div>
    </div>
  `;

  const $ = (selector) => document.querySelector(selector);
  for (let i = 1; i <= rows; i++) {
    const top = i * 50;
    setRect($(`#row-${i}`), {
      top,
      bottom: top + 40,
      left: 0,
      right: 400,
      width: 400,
      height: 40,
    });
    setRect($(`#more-${i}`), {
      top: top + 5,
      bottom: top + 25,
      left: 370,
      right: 390,
      width: 20,
      height: 20,
    });
  }
  setRect($("#more [data-part='positioner']"), { width: 160, height: 80 });
  setRect($("#ctx [data-part='positioner']"), { width: 160, height: 80 });

  const pushed = [];
  const moreEl = $("#more");
  const ctxEl = $("#ctx");
  const more = registry.create("dropdown-menu", moreEl, hookContext(pushed));
  const ctx = registry.create("context-menu", ctxEl, hookContext(pushed));
  cleanups.push(() => {
    more.destroy();
    ctx.destroy();
  });

  return {
    $,
    pushed,
    more,
    ctx,
    moreEl,
    ctxEl,
    morePositioner: $("#more [data-part='positioner']"),
    moreContent: $("#more [data-part='content']"),
    ctxPositioner: $("#ctx [data-part='positioner']"),
    reply: $("#more [data-value='reply']"),
    pin: $("#more [data-value='pin']"),
    copy: $("#ctx [data-value='copy']"),
    del: $("#ctx [data-value='delete']"),
  };
}

// --- core/detached-triggers.js ----------------------------------------------

test("listen() keeps one document listener per event type for every instance", () => {
  document.body.innerHTML = `
    <div data-salad-for="a b"><button id="inner" data-salad-for="a">x</button></div>`;
  const calls = [];
  const before = listenerCount();
  const offs = [
    listen("a", "click", (_e, el) => calls.push(["a", el.id || "outer"])),
    listen("b", "click", (_e, el) => calls.push(["b", el.id || "outer"])),
    listen("a", "keydown", () => calls.push(["a-key"])),
  ];
  assert.equal(listenerCount(), before + 2);

  click(document.getElementById("inner"));
  // Each id hears about its innermost trigger only.
  assert.deepEqual(calls, [
    ["a", "inner"],
    ["b", "outer"],
  ]);

  offs.forEach((off) => off());
  assert.equal(listenerCount(), before);
  click(document.getElementById("inner"));
  assert.equal(calls.length, 2);
});

test("readContext() parses data-salad-context and tolerates bad JSON", () => {
  const el = document.createElement("div");
  assert.equal(readContext(el), null);
  el.setAttribute("data-salad-context", '{"id":7}');
  assert.deepEqual(readContext(el), { id: 7 });

  const error = console.error;
  console.error = () => {};
  el.setAttribute("data-salad-context", "{nope");
  assert.equal(readContext(el), null);
  console.error = error;
});

test("ContextValues writes phx-value-* and puts back what was there", () => {
  const item = document.createElement("div");
  item.setAttribute("phx-value-id", "static");
  const values = new ContextValues();

  values.apply([item], { id: 42, Thread_Id: "t1", meta: { a: 1 }, none: null });
  assert.equal(item.getAttribute("phx-value-id"), "42");
  assert.equal(item.getAttribute("phx-value-thread_id"), "t1");
  assert.equal(item.getAttribute("phx-value-meta"), '{"a":1}');
  assert.equal(item.hasAttribute("phx-value-none"), false);

  values.clear();
  assert.equal(item.getAttribute("phx-value-id"), "static");
  assert.equal(item.hasAttribute("phx-value-thread_id"), false);
  assert.equal(values.active, false);
});

// --- shared dropdown menu ---------------------------------------------------

test("a detached trigger opens the shared dropdown at itself, with aria state", () => {
  const { $, more, morePositioner, moreContent, pushed } = build();
  const trigger = $("#more-2");

  trigger.focus();
  click(trigger);

  assert.equal(more.state, "open");
  assert.equal(morePositioner.hidden, false);
  assert.equal(more.positionedElement.reference, trigger);
  assert.equal(trigger.getAttribute("aria-expanded"), "true");
  assert.equal(trigger.getAttribute("aria-controls"), moreContent.id);
  assert.equal(trigger.getAttribute("data-state"), "open");
  // Other rows' triggers are untouched.
  assert.equal($("#more-1").getAttribute("aria-expanded"), "false");
  assert.deepEqual(pushed.at(-1), {
    target: more.el,
    event: "more_open",
    payload: {
      id: 2,
      kind: "msg",
      componentId: "more",
      component: "dropdown-menu",
    },
  });

  // A second click toggles it closed; focus returns to that trigger.
  click(trigger);
  assert.equal(more.state, "closed");
  assert.equal(trigger.getAttribute("aria-expanded"), "false");
  assert.equal(trigger.hasAttribute("aria-controls"), false);
  assert.equal(trigger.getAttribute("data-state"), "closed");
  assert.equal(document.activeElement, trigger);
  assert.equal(pushed.at(-1).event, "more_close");
  assert.equal(pushed.at(-1).payload.id, 2);
});

test("Enter on a detached trigger opens the shared dropdown at its first item", async () => {
  const { $, more, reply } = build();
  const trigger = $("#more-1");
  trigger.focus();

  const event = keydown(trigger, "Enter");

  assert.equal(event.defaultPrevented, true);
  assert.equal(more.state, "open");
  await waitFor(() => document.activeElement === reply);

  keydown(reply, "Escape");
  assert.equal(more.state, "closed");
  assert.equal(document.activeElement, trigger);
});

test("opening from another detached trigger moves the menu there", () => {
  const { $, more, pushed } = build();
  click($("#more-1"));
  click($("#more-3"));

  assert.equal(more.state, "open");
  assert.equal(more.positionedElement.reference, $("#more-3"));
  assert.equal($("#more-1").getAttribute("aria-expanded"), "false");
  assert.equal($("#more-1").getAttribute("data-state"), "closed");
  assert.equal($("#more-3").getAttribute("aria-expanded"), "true");
  assert.deepEqual(
    pushed.slice(-2).map(({ event, payload }) => [event, payload.id]),
    [
      ["more_close", 1],
      ["more_open", 3],
    ],
  );
});

test("the trigger's context reaches the items as phx-value-* and in on-select", async () => {
  const { $, more, moreEl, reply, pin, pushed } = build();
  click($("#more-2"));

  assert.equal(reply.getAttribute("phx-value-id"), "2");
  assert.equal(reply.getAttribute("phx-value-kind"), "msg");
  assert.equal(pin.getAttribute("phx-value-id"), "2");
  // The root runs an item's JS command when the content is portaled.
  assert.equal(moreEl.getAttribute("phx-value-id"), "2");

  let seenByLiveView = null;
  const onWindowClick = (event) => {
    seenByLiveView = event.target.getAttribute("phx-value-id");
  };
  window.addEventListener("click", onWindowClick);
  click(pin);
  window.removeEventListener("click", onWindowClick);

  assert.equal(more.state, "closed");
  // LiveView reads phx-value-* when the click reaches the window, after the
  // item closed the menu.
  assert.equal(seenByLiveView, "2");
  const select = pushed.find(({ event }) => event === "pin");
  assert.deepEqual(select.payload, {
    id: 2,
    kind: "msg",
    value: "pin",
    componentId: "more",
    component: "dropdown-menu",
  });

  await wait(5);
  assert.equal(reply.hasAttribute("phx-value-id"), false);
  assert.equal(moreEl.hasAttribute("phx-value-id"), false);
});

test("a LiveView patch of the shared menu keeps it open with the context re-applied", () => {
  const { $, more, moreEl, reply } = build();
  click($("#more-2"));
  const hook = hookFor(moreEl, more);

  hook.beforeUpdate();
  simulatePatch(moreEl, { hidden: ["[data-part='positioner']"] });
  hook.updated();
  cleanups.push(() => hook.component?.destroy());

  const rebuilt = hook.component;
  assert.notEqual(rebuilt, more);
  assert.equal(rebuilt.state, "open");
  assert.equal(rebuilt.positionedElement.reference, $("#more-2"));
  assert.equal($("#more-2").getAttribute("aria-expanded"), "true");
  assert.equal(reply.getAttribute("phx-value-id"), "2");
});

test("removing the trigger while open closes the menu and focuses its list", async () => {
  const { $, more, morePositioner, reply } = build();
  const trigger = $("#more-2");
  trigger.focus();
  keydown(trigger, "Enter");
  await waitFor(() => document.activeElement === reply);

  $("#row-2").remove();

  await waitFor(() => more.state === "closed");
  assert.equal(morePositioner.contains(document.activeElement), false);
  assert.equal(document.activeElement, $("#list"));
  // Escape afterwards is harmless and focus stays put.
  keydown(document.activeElement, "Escape");
  assert.equal(document.activeElement, $("#list"));
});

test("a patch that reverts the open trigger's state gets it re-applied", async () => {
  const { $ } = build();
  const trigger = $("#more-1");
  click(trigger);

  trigger.setAttribute("aria-expanded", "false");
  trigger.setAttribute("data-state", "closed");

  await waitFor(() => trigger.getAttribute("aria-expanded") === "true");
  assert.equal(trigger.getAttribute("data-state"), "open");
});

test("the open command takes an anchor selector and a context", () => {
  const { $, more, moreEl, reply } = build();

  moreEl.dispatchEvent(
    new window.CustomEvent("salad_ui:command", {
      detail: {
        command: "open",
        params: { anchor: "#more-3", context: { id: 99 } },
      },
    }),
  );

  assert.equal(more.state, "open");
  assert.equal(more.positionedElement.reference, $("#more-3"));
  assert.equal($("#more-3").getAttribute("aria-expanded"), "true");
  assert.equal(reply.getAttribute("phx-value-id"), "99");
});

test("the open command reads the anchor's context when none is given", () => {
  const { more, reply } = build();

  more.handleCommand("open", { anchor: "#more-1" });

  assert.equal(more.state, "open");
  assert.equal(reply.getAttribute("phx-value-id"), "1");
});

test("a shared dropdown without a nested trigger ignores a bare open command", () => {
  const { more } = build();
  const warn = console.warn;
  console.warn = () => {};

  assert.equal(more.handleCommand("open", {}), false);
  assert.equal(more.handleCommand("open", { anchor: "#missing" }), false);
  console.warn = warn;
  assert.equal(more.state, "closed");
});

test("disabled detached triggers do nothing", () => {
  const { $, more } = build();
  $("#more-1").setAttribute("aria-disabled", "true");

  click($("#more-1"));

  assert.equal(more.state, "closed");
});

test("destroying the shared menu while open resets its trigger", () => {
  const { $, more } = build();
  click($("#more-1"));

  more.destroy();

  assert.equal($("#more-1").getAttribute("aria-expanded"), "false");
  assert.equal($("#more-1").getAttribute("data-state"), "closed");
});

// --- shared context menu ----------------------------------------------------

test("right clicking a detached row opens the shared context menu at the pointer", () => {
  const { $, ctx, ctxPositioner, copy, pushed } = build();
  const row = $("#row-2");

  const event = contextmenu(row, 120, 110);

  assert.equal(event.defaultPrevented, true);
  assert.equal(ctx.state, "open");
  assert.equal(ctxPositioner.hidden, false);
  assert.equal(row.getAttribute("data-state"), "open");
  // A context menu trigger has no aria-expanded, as in Radix.
  assert.equal(row.hasAttribute("aria-expanded"), false);
  assert.equal(ctxPositioner.style.left, "122px");
  assert.equal(copy.getAttribute("phx-value-id"), "2");
  assert.equal(pushed.at(-1).event, "ctx_open");
  assert.equal(pushed.at(-1).payload.id, 2);
});

test("a right click on the ⋮ opens the row's context menu, not the dropdown", () => {
  const { $, ctx, more } = build();

  contextmenu($("#more-1"), 380, 60);

  assert.equal(ctx.state, "open");
  assert.equal(more.state, "closed");
  assert.equal($("#row-1").getAttribute("data-state"), "open");
});

test("right clicking another row moves the open context menu there", () => {
  const { $, ctx, copy, pushed } = build();
  contextmenu($("#row-1"), 20, 60);
  contextmenu($("#row-3"), 30, 160);

  assert.equal(ctx.state, "open");
  assert.equal($("#row-1").getAttribute("data-state"), "closed");
  assert.equal($("#row-3").getAttribute("data-state"), "open");
  assert.equal(copy.getAttribute("phx-value-id"), "3");
  assert.deepEqual(
    pushed.slice(-2).map(({ event, payload }) => [event, payload.id]),
    [
      ["ctx_close", 1],
      ["ctx_open", 3],
    ],
  );
});

test("with a modal context menu, a right click on another row still moves it", () => {
  const { $, ctx, copy } = build({ modal: true });
  contextmenu($("#row-1"), 20, 60);
  assert.equal(ctx.modalLayer.blocking, true);

  // The blocked page sends the right click to <html>.
  contextmenu(document.documentElement, 30, 160);

  assert.equal(ctx.state, "open");
  assert.equal($("#row-3").getAttribute("data-state"), "open");
  assert.equal(copy.getAttribute("phx-value-id"), "3");
});

test("Escape closes the shared context menu and returns focus", () => {
  const { $, ctx, ctxPositioner } = build();
  $("#composer").focus();
  contextmenu($("#row-1"), 20, 60);
  assert.equal(ctxPositioner.contains(document.activeElement), true);

  keydown(document.activeElement, "Escape");

  assert.equal(ctx.state, "closed");
  assert.equal($("#row-1").getAttribute("data-state"), "closed");
  assert.equal(document.activeElement, $("#composer"));
});

test("on-select of a shared context menu item carries the row context", () => {
  const { $, del, pushed } = build();
  contextmenu($("#row-3"), 20, 160);

  click(del);

  const select = pushed.find(({ event }) => event === "delete");
  assert.equal(select.payload.id, 3);
  assert.equal(select.payload.value, "delete");
});

test("deleting the row while its context menu is open closes it", async () => {
  const { $, ctx, ctxPositioner } = build();
  contextmenu($("#row-2"), 20, 110);
  assert.equal(ctxPositioner.contains(document.activeElement), true);

  $("#row-2").remove();

  await waitFor(() => ctx.state === "closed");
  assert.equal(ctxPositioner.contains(document.activeElement), false);
  assert.equal(document.activeElement, $("#list"));
});

test("a long press on a detached row opens the shared context menu", async () => {
  const { $, ctx } = build();
  const row = $("#row-1");
  row.dispatchEvent(
    new window.PointerEvent("pointerdown", {
      bubbles: true,
      pointerType: "touch",
      clientX: 40,
      clientY: 70,
    }),
  );

  await waitFor(() => ctx.state === "open", { timeout: 2000 });
  assert.equal(row.getAttribute("data-state"), "open");
});

test("moving the pointer cancels a pending long press on a detached row", async () => {
  const { $, ctx } = build();
  $("#row-1").dispatchEvent(
    new window.PointerEvent("pointerdown", {
      bubbles: true,
      pointerType: "touch",
      clientX: 40,
      clientY: 70,
    }),
  );
  document.body.dispatchEvent(
    new window.PointerEvent("pointermove", { bubbles: true }),
  );

  await wait(800);
  assert.equal(ctx.state, "closed");
});

test("the context menu open command takes an anchor and a context", () => {
  const { $, ctx, copy } = build();

  ctx.handleCommand("open", { anchor: "#row-2", context: { id: 7 } });

  assert.equal(ctx.state, "open");
  assert.equal($("#row-2").getAttribute("data-state"), "open");
  assert.equal(copy.getAttribute("phx-value-id"), "7");
});
