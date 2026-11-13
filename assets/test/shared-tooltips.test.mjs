import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import "../salad_ui/components/tooltip.js"; // "tooltip" and "tooltip-provider"
import "../salad_ui/components/hover-card.js";
import "../salad_ui/components/dropdown_menu.js";
import { registry } from "../salad_ui/core/factory.js";
import { resetModalLayers } from "../salad_ui/core/modal-layer.js";
import { resetTooltipSkipDelay } from "../salad_ui/core/hover-popups.js";
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

const created = [];
afterEach(() => {
  created.splice(0).forEach((component) => component.destroy());
  resetModalLayers();
  resetTooltipSkipDelay();
  document.body.innerHTML = "";
  // A pointer press elsewhere would keep focus-opens blocked.
  document.dispatchEvent(new window.KeyboardEvent("keydown", { key: "x" }));
});

const OPEN = 20;
const CLOSE = 10;

function fire(type, target, init = {}) {
  const Ctor = type.startsWith("pointer")
    ? window.PointerEvent
    : type.startsWith("mouse")
      ? window.MouseEvent
      : type.startsWith("focus")
        ? window.FocusEvent
        : type === "keydown"
          ? window.KeyboardEvent
          : window.Event;
  const event = new Ctor(type, { bubbles: true, cancelable: true, ...init });
  target.dispatchEvent(event);
  return event;
}

// The pointer moves from `from` (or outside) onto `to`.
function hover(to, from = document.body) {
  fire("mouseout", from, { relatedTarget: to });
  fire("mouseover", to, { relatedTarget: from });
}

function hookContext(pushed, { reply = true } = {}) {
  return {
    pushEventTo: (target, event, payload, onReply) => {
      pushed.push({ target, event, payload, onReply });
      if (reply && onReply) setTimeout(() => onReply({}), 0);
    },
    liveSocket: { execJS: () => {} },
  };
}

function rect(el, top) {
  setRect(el, {
    top,
    bottom: top + 20,
    left: 10,
    right: 110,
    width: 100,
    height: 20,
  });
}

function mount(type, id, context) {
  const el = document.getElementById(id);
  const component = registry.create(type, el, context);
  created.push(component);
  return component;
}

// --- tooltip provider: text tooltips ----------------------------------------

function buildProvider({ scope = null, skipDelay = 300, rows = 3 } = {}) {
  const options = JSON.stringify({
    openDelay: OPEN,
    closeDelay: CLOSE,
    skipDelay,
    scope,
  });
  document.body.innerHTML = `
    <div id="list">
      ${Array.from(
        { length: rows },
        (_, i) => `
        <div class="row" id="row-${i + 1}">
          <button id="reply-${i + 1}" type="button" data-salad-tooltip="Reply ${i + 1}">↩</button>
          <button id="react-${i + 1}" type="button" data-salad-tooltip="React"
                  data-salad-tooltip-side="bottom" aria-describedby="hint">☺</button>
        </div>`,
      ).join("")}
    </div>
    <button id="outside" type="button" data-salad-tooltip="Outside">x</button>
    <span id="hint">hint</span>
    <div id="tooltips" data-component="tooltip-provider" data-state="closed"
         data-options='${options}' data-event-mappings="{}" data-part="root">
      <div id="tooltips-content" data-part="content" data-side="top" data-align="center"
           data-side-offset="8" hidden>
        <span data-part="text"></span><span data-slot="tooltip-arrow"></span>
      </div>
    </div>
  `;
  const $ = (selector) => document.querySelector(selector);
  document
    .querySelectorAll("button")
    .forEach((button, i) => rect(button, i * 30));
  setRect($("#tooltips-content"), { width: 60, height: 24 });
  const provider = mount("tooltip-provider", "tooltips", hookContext([]));
  return {
    $,
    provider,
    content: $("#tooltips-content"),
    text: $("[data-part='text']"),
  };
}

test("a text tooltip shows the trigger's text after the open delay", async () => {
  const { $, provider, content, text } = buildProvider();
  const reply = $("#reply-2");

  hover(reply);
  assert.equal(content.hidden, true);
  await waitFor(() => provider.state === "open");

  assert.equal(content.hidden, false);
  assert.equal(text.textContent, "Reply 2");
  assert.equal(content.getAttribute("role"), "tooltip");
  assert.equal(reply.getAttribute("aria-describedby"), "tooltips-content");
  // A tooltip does not own its trigger's data-state.
  assert.equal(reply.hasAttribute("data-state"), false);

  hover(document.body, reply);
  await waitFor(() => provider.state === "closed");
  assert.equal(reply.hasAttribute("aria-describedby"), false);
});

test("aria-describedby keeps the trigger's own ids", async () => {
  const { $, provider } = buildProvider();
  const react = $("#react-1");

  hover(react);
  await waitFor(() => provider.state === "open");
  assert.equal(react.getAttribute("aria-describedby"), "hint tooltips-content");
  assert.equal(
    document.getElementById("tooltips-content").getAttribute("data-side"),
    "bottom",
  );

  provider.closeNow();
  assert.equal(react.getAttribute("aria-describedby"), "hint");
});

test("leaving during the open delay cancels the open", async () => {
  const { $, provider } = buildProvider();
  hover($("#reply-1"));
  hover(document.body, $("#reply-1"));

  await wait(OPEN * 3);
  assert.equal(provider.state, "closed");
});

test("moving to another trigger while open switches at once", async () => {
  const { $, provider, text } = buildProvider();
  hover($("#reply-1"));
  await waitFor(() => provider.state === "open");

  hover($("#reply-3"), $("#reply-1"));

  assert.equal(provider.state, "open");
  assert.equal(text.textContent, "Reply 3");
  assert.equal($("#reply-1").hasAttribute("aria-describedby"), false);
  assert.equal(
    $("#reply-3").getAttribute("aria-describedby"),
    "tooltips-content",
  );
  assert.equal(provider.positionedElement.reference, $("#reply-3"));
});

test("within the skip delay after a tooltip closed, the next opens at once", async () => {
  const { $, provider, text } = buildProvider();
  hover($("#reply-1"));
  await waitFor(() => provider.state === "open");
  hover(document.body, $("#reply-1"));
  await waitFor(() => provider.state === "closed");

  hover($("#reply-2"));

  assert.equal(provider.state, "open");
  assert.equal(text.textContent, "Reply 2");
});

test("after the skip delay the open delay applies again", async () => {
  const { $, provider } = buildProvider({ skipDelay: 5 });
  hover($("#reply-1"));
  await waitFor(() => provider.state === "open");
  hover(document.body, $("#reply-1"));
  await waitFor(() => provider.state === "closed");
  await wait(20);

  hover($("#reply-2"));
  assert.equal(provider.state, "closed");
  await waitFor(() => provider.state === "open");
});

test("keyboard focus opens a text tooltip, Escape closes it", async () => {
  const { $, provider } = buildProvider();
  fire("keydown", document, { key: "Tab" });
  fire("focusin", $("#reply-1"));
  await waitFor(() => provider.state === "open");

  fire("keydown", $("#reply-1"), { key: "Escape" });
  assert.equal(provider.state, "closed");
});

test("focus that follows a pointer press does not open a text tooltip", async () => {
  const { $, provider } = buildProvider();
  fire("pointerdown", $("#reply-1"));
  fire("focusin", $("#reply-1"));

  await wait(OPEN * 3);
  assert.equal(provider.state, "closed");
});

test("pressing the trigger closes its text tooltip", async () => {
  const { $, provider } = buildProvider();
  hover($("#reply-1"));
  await waitFor(() => provider.state === "open");

  fire("pointerdown", $("#reply-1"));
  assert.equal(provider.state, "closed");
});

test("a scoped provider ignores text tooltips outside its scope", async () => {
  const { $, provider } = buildProvider({ scope: "#list" });
  hover($("#outside"));
  await wait(OPEN * 3);
  assert.equal(provider.state, "closed");

  hover($("#reply-1"), $("#outside"));
  await waitFor(() => provider.state === "open");
});

test("removing the trigger closes its text tooltip", async () => {
  const { $, provider } = buildProvider();
  hover($("#reply-2"));
  await waitFor(() => provider.state === "open");

  $("#row-2").remove();
  await waitFor(() => provider.state === "closed");
});

test("a patch of the provider keeps the open tooltip and its text", async () => {
  const { $, provider, text } = buildProvider();
  hover($("#reply-1"));
  await waitFor(() => provider.state === "open");
  const el = document.getElementById("tooltips");
  const hook = hookFor(el, provider);

  hook.beforeUpdate();
  simulatePatch(el, {
    hidden: ["[data-part='content']"],
    keepIds: ["tooltips", "tooltips-content"],
  });
  text.textContent = "";
  hook.updated();

  assert.equal(hook.component, provider);
  assert.equal(provider.state, "open");
  assert.equal(text.textContent, "Reply 1");
});

test("a menu trigger with a text tooltip keeps the menu's data-state", async () => {
  document.body.innerHTML = "";
  const { $, provider } = buildProvider();
  const button = $("#reply-1");
  button.setAttribute("data-salad-for", "menu");
  button.setAttribute("data-state", "closed");

  hover(button);
  await waitFor(() => provider.state === "open");
  assert.equal(button.getAttribute("data-state"), "closed");
});

test("no text tooltip opens while a menu is open, except inside it", async () => {
  const { $, provider } = buildProvider();
  document.body.insertAdjacentHTML(
    "beforeend",
    `<div id="menu" data-component="dropdown-menu" data-state="open"></div>
     <div role="menu" data-state="open"><button id="in-menu" type="button" data-salad-tooltip="In menu">m</button></div>`,
  );
  rect($("#in-menu"), 300);

  hover($("#reply-1"));
  await wait(OPEN * 3);
  assert.equal(provider.state, "closed");

  hover($("#in-menu"), $("#reply-1"));
  await waitFor(() => provider.state === "open");
});

// --- shared rich tooltip ----------------------------------------------------

test("a shared rich tooltip opens for a detached trigger with its context", async () => {
  document.body.innerHTML = `
    <span id="a1" data-salad-for="tip" data-salad-context='{"id":1}'>Ada</span>
    <span id="a2" data-salad-for="tip" data-salad-context='{"id":2}'>Grace</span>
    <div id="tip" data-component="tooltip" data-state="closed" data-part="root"
         data-options='{"openDelay":${OPEN},"closeDelay":${CLOSE}}'
         data-event-mappings='{"open":"tip_open"}'>
      <div data-part="content" hidden>Online</div>
    </div>`;
  rect(document.getElementById("a1"), 0);
  rect(document.getElementById("a2"), 30);
  const pushed = [];
  const tip = mount("tooltip", "tip", hookContext(pushed));
  const content = document.querySelector("#tip [data-part='content']");

  hover(document.getElementById("a2"));
  await waitFor(() => tip.state === "open");

  assert.equal(content.hidden, false);
  assert.equal(tip.positionedElement.reference, document.getElementById("a2"));
  assert.equal(
    document.getElementById("a2").getAttribute("aria-describedby"),
    content.id,
  );
  assert.deepEqual(pushed.at(-1).payload, {
    id: 2,
    componentId: "tip",
    component: "tooltip",
  });

  hover(document.getElementById("a1"), document.getElementById("a2"));
  assert.equal(tip.positionedElement.reference, document.getElementById("a1"));
  assert.equal(
    document.getElementById("a2").hasAttribute("aria-describedby"),
    false,
  );
});

// --- shared hover cards -----------------------------------------------------

function buildCards({ onOpen = null, reply = true } = {}) {
  const mappings = onOpen ? `{"open":"${onOpen}"}` : "{}";
  document.body.innerHTML = `
    <div id="list" tabindex="-1">
      <div id="m1"><button id="t1" type="button" data-salad-for="card-ada" data-salad-context='{"id":1}'
              aria-haspopup="dialog" aria-expanded="false" data-state="closed">Ada</button></div>
      <div id="m2"><button id="t2" type="button" data-salad-for="card-ada" data-salad-context='{"id":2}'
              aria-haspopup="dialog" aria-expanded="false" data-state="closed">Ada</button></div>
    </div>
    <div id="card-ada" data-component="hover-card" data-state="closed" data-part="root"
         data-options='{"openDelay":${OPEN},"closeDelay":${CLOSE}}'
         data-event-mappings='${mappings}'>
      <div data-part="content" data-side="bottom" hidden>
        <div data-part="content-wrapper">
          Ada Lovelace
          <button id="card-action" type="button" data-salad-tooltip="Message">✉</button>
        </div>
      </div>
    </div>
    <div id="tooltips" data-component="tooltip-provider" data-state="closed"
         data-options='{"openDelay":${OPEN},"closeDelay":${CLOSE}}' data-event-mappings="{}" data-part="root">
      <div id="tooltips-content" data-part="content" hidden><span data-part="text"></span></div>
    </div>`;
  const $ = (selector) => document.querySelector(selector);
  rect($("#t1"), 0);
  rect($("#t2"), 30);
  rect($("#card-action"), 200);
  setRect($("#card-ada [data-part='content']"), { width: 200, height: 100 });
  setRect($("#tooltips-content"), { width: 60, height: 24 });
  const pushed = [];
  const card = mount("hover-card", "card-ada", hookContext(pushed, { reply }));
  const provider = mount("tooltip-provider", "tooltips", hookContext([]));
  return {
    $,
    card,
    provider,
    pushed,
    content: $("#card-ada [data-part='content']"),
  };
}

test("a hover card per entity opens at whichever trigger is hovered", async () => {
  const { $, card, content } = buildCards();

  hover($("#t2"));
  await waitFor(() => card.state === "open");

  assert.equal(content.hidden, false);
  assert.equal(card.positionedElement.reference, $("#t2"));
  assert.equal($("#t2").getAttribute("aria-expanded"), "true");
  assert.equal($("#t2").getAttribute("data-state"), "open");
  assert.equal($("#t1").getAttribute("aria-expanded"), "false");

  hover(document.body, $("#t2"));
  await waitFor(() => card.state === "closed");
  assert.equal($("#t2").getAttribute("aria-expanded"), "false");
  assert.equal($("#t2").getAttribute("data-state"), "closed");
});

test("moving to another trigger of the same card moves it after the open delay", async () => {
  const { $, card } = buildCards();
  hover($("#t1"));
  await waitFor(() => card.state === "open");

  hover($("#t2"), $("#t1"));
  await waitFor(() => card.positionedElement.reference === $("#t2"));
  assert.equal(card.state, "open");
  assert.equal($("#t1").getAttribute("aria-expanded"), "false");
  assert.equal($("#t2").getAttribute("aria-expanded"), "true");
});

test("a text tooltip inside an open hover card keeps the card open", async () => {
  const { $, card, provider } = buildCards();
  hover($("#t1"));
  await waitFor(() => card.state === "open");

  // Into the card: a browser also fires mouseenter on the card's content.
  hover($("#card-action"), $("#t1"));
  $("#card-ada [data-part='content']").dispatchEvent(
    new window.MouseEvent("mouseenter", { relatedTarget: $("#t1") }),
  );
  await waitFor(() => provider.state === "open");
  assert.equal(card.state, "open");

  // The pointer over the tooltip's own content (outside the card) is still
  // inside the card's popup tree.
  fire("pointermove", $("#tooltips-content"), { pointerType: "mouse" });
  await wait(CLOSE * 4);
  assert.equal(card.state, "open");
});

test("a shared card with a server on-open shows after the reply, with the context", async () => {
  const { $, card, pushed } = buildCards({
    onOpen: "show_profile",
    reply: false,
  });

  hover($("#t2"));
  await waitFor(() => pushed.some(({ event }) => event === "show_profile"));
  const request = pushed.find(({ event }) => event === "show_profile");
  assert.equal(request.payload.id, 2);
  // Not shown before the server answered (its content is the previous one).
  await wait(OPEN);
  assert.equal(card.state, "closed");

  request.onReply({});
  assert.equal(card.state, "open");
  assert.equal(card.positionedElement.reference, $("#t2"));
  // The open event is not pushed twice.
  assert.equal(
    pushed.filter(({ event }) => event === "show_profile").length,
    1,
  );
});

test("leaving before the server replied cancels the shared card's open", async () => {
  const { $, card, pushed } = buildCards({
    onOpen: "show_profile",
    reply: false,
  });
  hover($("#t1"));
  await waitFor(() => pushed.some(({ event }) => event === "show_profile"));

  hover(document.body, $("#t1"));
  pushed.find(({ event }) => event === "show_profile").onReply({});

  assert.equal(card.state, "closed");
});

test("removing the trigger closes its hover card", async () => {
  const { $, card } = buildCards();
  hover($("#t1"));
  await waitFor(() => card.state === "open");

  $("#m1").remove();
  await waitFor(() => card.state === "closed");
});

test("keyboard focus on a detached trigger opens the card, Escape closes it", async () => {
  const { $, card } = buildCards();
  fire("keydown", document, { key: "Tab" });
  fire("focusin", $("#t1"));
  await waitFor(() => card.state === "open");

  fire("keydown", $("#t1"), { key: "Escape" });
  assert.equal(card.state, "closed");
});
