// Shared menus whose items depend on the row (context conditions), that
// follow their trigger while open, and whose items' JS commands reach the
// row. See also shared-menus.test.mjs.
import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/dropdown_menu.js"; // self-registers "dropdown-menu"
import "../salad_ui/components/context_menu.js"; // self-registers "context-menu"
import { resetModalLayers } from "../salad_ui/core/modal-layer.js";
import {
  applyContextConditions,
  matchesContext,
} from "../salad_ui/core/context-conditions.js";
import {
  contextSourceOf,
  resolveContextParams,
  textToCopy,
} from "../salad_ui/core/detached-triggers.js";
import {
  hookFor,
  installDom,
  setRect,
  simulatePatch,
  wait,
  waitFor,
  uninstallDom,
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
  el.dispatchEvent(
    new window.MouseEvent("contextmenu", {
      bubbles: true,
      cancelable: true,
      clientX: x,
      clientY: y,
    }),
  );
}

// A mutation observer callback runs as a microtask.
const flush = () => wait(0);

const json = (value) => JSON.stringify(value).replace(/'/g, "&#39;");

// Rows: 1 is mine and unpinned, 2 someone else's and pinned, 3 a bot's.
const ROWS = [
  { id: 1, own: true, pinned: false, kind: "user" },
  { id: 2, own: false, pinned: true, kind: "user" },
  { id: 3, own: false, pinned: false, kind: "bot" },
];

// The menu items, the same in the dropdown and the context menu.
function itemsHtml() {
  return `
    <div data-part="item" data-value="reply" tabindex="-1" phx-click="reply"
         data-hide-when='${json({ kind: "bot" })}'>Reply</div>
    <div data-part="item" data-value="pin" tabindex="-1" phx-click="pin"
         data-hide-when='${json({ pinned: true })}'>Pin</div>
    <div data-part="item" data-value="unpin" tabindex="-1" phx-click="unpin"
         data-show-when='${json({ pinned: true })}'>Unpin</div>
    <div data-part="item" data-value="remind" tabindex="-1" phx-click="remind"
         data-disabled-when='${json({ kind: "bot" })}'>Remind me</div>
    <div data-part="group" role="group" data-show-when='${json({ own: true })}'>
      <div data-part="separator" role="separator"></div>
      <div data-part="label">Yours</div>
      <div data-part="item" data-value="edit" tabindex="-1" phx-click="edit">Edit</div>
    </div>
    <div data-part="separator" role="separator"></div>
    <div data-part="item" data-value="delete" tabindex="-1" phx-click="delete"
         data-show-when='${json([{ own: true }, { kind: ["bot", "agent"] }])}'>Delete</div>`;
}

function build({ modal = false } = {}) {
  const options = JSON.stringify({ modal });
  const rows = ROWS.map(
    (ctx) => `
      <div id="row-${ctx.id}" data-row data-salad-for="ctx" data-state="closed"
           data-salad-context='${json(ctx)}'>
        <p data-text>Message ${ctx.id}</p>
        <button id="more-${ctx.id}" type="button" data-salad-for="more"
                data-salad-context='${json(ctx)}' aria-haspopup="menu"
                aria-expanded="false" data-state="closed">⋮</button>
      </div>`,
  ).join("");

  document.body.innerHTML = `
    <div id="list" tabindex="-1">${rows}</div>
    <div id="more" data-component="dropdown-menu" data-state="closed" data-part="root"
         data-options='${options}' data-event-mappings='{"open":"more_open"}'>
      <div data-part="positioner" data-side="bottom" data-align="end" hidden>
        <div data-part="content" tabindex="-1">${itemsHtml()}</div>
      </div>
    </div>
    <div id="ctx" data-component="context-menu" data-state="closed" data-part="root"
         data-options='${options}'>
      <div data-part="positioner" data-side="right" hidden>
        <div data-part="content" role="menu" tabindex="-1">
          ${itemsHtml()}
          <div data-part="sub" data-hide-when='${json({ kind: "bot" })}'>
            <div data-part="sub-trigger" tabindex="-1">React</div>
            <div data-part="sub-positioner" hidden>
              <div data-part="sub-content" tabindex="-1">
                <div data-part="item" data-value="thumbs" tabindex="-1">👍</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div id="picker" data-command-log></div>
  `;

  const $ = (selector) => document.querySelector(selector);
  ROWS.forEach(({ id }) => {
    const top = id * 50;
    setRect($(`#row-${id}`), {
      top,
      bottom: top + 40,
      left: 0,
      right: 400,
      width: 400,
      height: 40,
    });
    setRect($(`#more-${id}`), {
      top: top + 5,
      bottom: top + 25,
      left: 370,
      right: 390,
      width: 20,
      height: 20,
    });
  });
  setRect($("#more [data-part='positioner']"), { width: 160, height: 200 });
  setRect($("#ctx [data-part='positioner']"), { width: 160, height: 200 });

  const pushed = [];
  const hook = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };
  const more = registry.create("dropdown-menu", $("#more"), hook);
  const ctx = registry.create("context-menu", $("#ctx"), hook);
  cleanups.push(() => {
    more.destroy();
    ctx.destroy();
  });

  const item = (menu, value) => $(`#${menu} [data-value='${value}']`);
  // The visible items of a menu's top panel, by value.
  const shown = (menu) =>
    [...document.querySelectorAll(`#${menu} [data-part='content'] > *`)]
      .flatMap((el) =>
        el.matches("[data-part='group']")
          ? [...el.children]
          : el.matches("[data-part='sub']")
            ? [el.querySelector("[data-part='sub-trigger']")]
            : [el],
      )
      .filter(
        (el) =>
          !el.hidden && !el.closest("[hidden]:not([data-part='positioner'])"),
      )
      .map((el) =>
        el.dataset.part === "item"
          ? el.dataset.value
          : el.dataset.part === "sub-trigger"
            ? "react"
            : el.dataset.part,
      );

  return { $, more, ctx, pushed, item, shown };
}

// --- matching ----------------------------------------------------------------

test("matchesContext(): every key equal, a list of accepted values, any of a list of maps", () => {
  const ctx = { id: 7, own: true, kind: "bot", tags: ["a"] };

  assert.equal(matchesContext({ own: true }, ctx), true);
  assert.equal(matchesContext({ own: true, kind: "bot" }, ctx), true);
  assert.equal(matchesContext({ own: true, kind: "user" }, ctx), false);
  assert.equal(matchesContext({ kind: ["user", "bot"] }, ctx), true);
  assert.equal(matchesContext({ kind: ["user", "agent"] }, ctx), false);
  assert.equal(matchesContext([{ own: false }, { kind: "bot" }], ctx), true);
  assert.equal(matchesContext([{ own: false }, { kind: "user" }], ctx), false);
  assert.equal(matchesContext([], ctx), false);
  // Values compare as JSON: no coercion between 7 and "7".
  assert.equal(matchesContext({ id: 7 }, ctx), true);
  assert.equal(matchesContext({ id: "7" }, ctx), false);
  // A missing key reads as null.
  assert.equal(matchesContext({ pinned: null }, ctx), true);
  assert.equal(matchesContext({ pinned: false }, ctx), false);
  // No context reads as {}.
  assert.equal(matchesContext({ own: null }, null), true);
  assert.equal(matchesContext({}, null), true);
});

test("applyContextConditions() hides, disables, tidies and undoes its own work only", () => {
  document.body.innerHTML = `
    <div id="root"><div data-part="content">
      <div data-part="label">Actions</div>
      <div data-part="item" id="a" data-show-when='{"own":true}'>A</div>
      <div data-part="separator" id="s1"></div>
      <div data-part="separator" id="s2"></div>
      <div data-part="group" id="g">
        <div data-part="item" id="b" data-hide-when='{"own":false}'>B</div>
      </div>
      <div data-part="item" id="c" data-disabled-when='{"own":false}'>C</div>
      <div data-part="item" id="d" hidden>D</div>
      <div data-part="item" id="e" data-disabled>E</div>
      <div data-part="separator" id="s3"></div>
    </div></div>`;
  const root = document.getElementById("root");
  const $ = (id) => document.getElementById(id);

  assert.equal(applyContextConditions(root, { own: false }), true);
  assert.equal($("a").hidden, true);
  // The group's only item is hidden, so the group is.
  assert.equal($("g").hidden, true);
  // "Actions" now heads a separator: hidden. The separators that lead and
  // double up go; C and the trailing separator: s3 trails.
  assert.equal($("s1").hidden, true);
  assert.equal($("s2").hidden, true);
  assert.equal($("s3").hidden, true);
  assert.equal(document.querySelector("[data-part='label']").hidden, true);
  assert.equal($("c").hidden, false);
  assert.equal($("c").getAttribute("data-disabled"), "true");

  applyContextConditions(root, { own: true });
  // No condition hides anything: the panel is left as rendered.
  for (const id of ["a", "g", "b", "s1", "s2", "s3"]) {
    assert.equal($(id).hidden, false, id);
  }
  assert.equal(document.querySelector("[data-part='label']").hidden, false);
  assert.equal($("c").hasAttribute("data-disabled"), false);
  assert.equal($("c").hasAttribute("aria-disabled"), false);
  // Server-rendered state is left alone.
  assert.equal($("d").hidden, true);
  assert.equal($("e").hasAttribute("data-disabled"), true);
});

test("applyContextConditions() leaves a menu without conditions untouched", () => {
  document.body.innerHTML = `
    <div id="root"><div data-part="content">
      <div data-part="separator" id="s1"></div>
      <div data-part="item">A</div>
      <div data-part="label" id="l">Trailing label</div>
    </div></div>`;

  assert.equal(
    applyContextConditions(document.getElementById("root"), { id: 1 }),
    false,
  );
  assert.equal(document.getElementById("s1").hidden, false);
  assert.equal(document.getElementById("l").hidden, false);
});

// --- #17: the shared menus show the items for the row -------------------------

test("the shared dropdown shows each row its own items (own, pinned, bot)", () => {
  const { $, more, shown, item } = build();

  click($("#more-1"));
  assert.equal(more.state, "open");
  assert.deepEqual(shown("more"), [
    "reply",
    "pin",
    "remind",
    "separator",
    "label",
    "edit",
    "separator",
    "delete",
  ]);
  // Hidden items are out of the accessibility tree too.
  assert.equal(item("more", "unpin").hidden, true);

  click($("#more-2"));
  assert.deepEqual(shown("more"), ["reply", "unpin", "remind"]);

  click($("#more-3"));
  assert.deepEqual(shown("more"), ["pin", "remind", "separator", "delete"]);
  const remind = item("more", "remind");
  assert.equal(remind.getAttribute("data-disabled"), "true");
  assert.equal(remind.getAttribute("aria-disabled"), "true");

  // Back on row 1, Remind me is enabled again.
  click($("#more-1"));
  assert.equal(remind.hasAttribute("data-disabled"), false);
  assert.equal(remind.hasAttribute("aria-disabled"), false);
});

test("keyboard navigation and typeahead skip hidden and disabled items", async () => {
  const { $, item, more } = build();
  const trigger = $("#more-3");
  trigger.focus();

  keydown(trigger, "Enter");
  // Reply is hidden for a bot's message: Pin is first.
  await waitFor(() => document.activeElement === item("more", "pin"));

  keydown(document.activeElement, "ArrowDown");
  // Remind me is disabled, Edit hidden: Delete.
  assert.equal(document.activeElement, item("more", "delete"));
  keydown(document.activeElement, "ArrowDown");
  assert.equal(document.activeElement, item("more", "delete"));

  keydown(document.activeElement, "Home");
  assert.equal(document.activeElement, item("more", "pin"));
  // Typeahead: "u" would match the hidden Unpin.
  keydown(document.activeElement, "u");
  assert.equal(document.activeElement, item("more", "pin"));
  keydown(document.activeElement, "Escape");
  assert.equal(more.state, "closed");
});

test("the shared context menu shows the row's items, also when moved to another row", () => {
  const { $, ctx, shown } = build();

  contextmenu($("#row-2"), 20, 110);
  assert.equal(ctx.state, "open");
  // The separator before the hidden Delete now sits between Remind me and
  // the React sub-menu.
  assert.deepEqual(shown("ctx"), [
    "reply",
    "unpin",
    "remind",
    "separator",
    "react",
  ]);

  // Right click on another row moves the open menu there.
  contextmenu($("#row-3"), 20, 160);
  assert.equal(ctx.state, "open");
  assert.deepEqual(shown("ctx"), ["pin", "remind", "separator", "delete"]);
});

test("a nested-trigger open evaluates conditions against an empty context", () => {
  const { more, shown } = build();

  more.handleCommand("open", { anchor: "#list" });

  assert.equal(more.state, "open");
  // #list has no context: own/pinned/kind read as null.
  assert.deepEqual(shown("more"), ["reply", "pin", "remind"]);
});

// --- #18: the trigger changes while the menu is open ------------------------

test("the dropdown closes when its trigger is pointed at another menu", async () => {
  const { $, more } = build();
  const trigger = $("#more-1");
  trigger.focus();
  keydown(trigger, "Enter");
  await waitFor(() => more.positioner.contains(document.activeElement));

  trigger.setAttribute("data-salad-for", "other-menu");
  await flush();

  assert.equal(more.state, "closed");
  assert.equal(trigger.getAttribute("aria-expanded"), "false");
  // Still focusable: focus goes back to it.
  assert.equal(document.activeElement, trigger);
});

test("the dropdown closes when its trigger is disabled; focus falls back to the list", async () => {
  const { $, more } = build();
  const trigger = $("#more-1");
  trigger.focus();
  keydown(trigger, "Enter");
  await waitFor(() => more.positioner.contains(document.activeElement));

  trigger.disabled = true;
  await flush();

  assert.equal(more.state, "closed");
  assert.equal(more.positioner.contains(document.activeElement), false);
  assert.equal(document.activeElement, $("#list"));
});

test("the context menu closes when its row is disabled", async () => {
  const { $, ctx } = build();
  contextmenu($("#row-2"), 20, 110);
  assert.equal(ctx.state, "open");

  $("#row-2").setAttribute("data-disabled", "");
  await flush();

  assert.equal(ctx.state, "closed");
  assert.equal(ctx.positioner.contains(document.activeElement), false);
  assert.equal($("#row-2").getAttribute("data-state"), "closed");
});

test("a changed context while open updates the items and phx-value-*", async () => {
  const { $, more, item, shown } = build();
  const trigger = $("#more-1");
  trigger.focus();
  keydown(trigger, "Enter");
  const pin = item("more", "pin");
  await waitFor(() => document.activeElement === item("more", "reply"));
  keydown(document.activeElement, "ArrowDown");
  assert.equal(document.activeElement, pin);
  assert.equal(pin.getAttribute("phx-value-pinned"), "false");

  // The server pinned the message while its menu is open.
  trigger.setAttribute(
    "data-salad-context",
    JSON.stringify({ ...ROWS[0], pinned: true }),
  );
  await flush();

  assert.equal(more.state, "open");
  assert.deepEqual(shown("more").slice(0, 3), ["reply", "unpin", "remind"]);
  assert.equal(item("more", "unpin").getAttribute("phx-value-pinned"), "true");
  // The highlighted Pin is gone: focus moved to the panel, and ArrowDown
  // starts from the top again.
  assert.equal(document.activeElement, more.content);
  keydown(document.activeElement, "ArrowDown");
  assert.equal(document.activeElement, item("more", "reply"));
});

test("a changed context while the context menu is open updates its items", async () => {
  const { $, ctx, shown, item } = build();
  contextmenu($("#row-3"), 20, 160);
  assert.deepEqual(shown("ctx"), ["pin", "remind", "separator", "delete"]);

  $("#row-3").setAttribute(
    "data-salad-context",
    JSON.stringify({ ...ROWS[2], kind: "user" }),
  );
  await flush();

  assert.equal(ctx.state, "open");
  assert.deepEqual(shown("ctx"), [
    "reply",
    "pin",
    "remind",
    "separator",
    "react",
  ]);
  assert.equal(item("ctx", "reply").getAttribute("phx-value-kind"), "user");
});

test("a patch that rebuilds the open menu and disables its trigger closes it", async () => {
  const { $, more } = build();
  const trigger = $("#more-1");
  click(trigger);
  const hook = hookFor(more.el, more);

  hook.beforeUpdate();
  simulatePatch(more.el, { hidden: ["[data-part='positioner']"] });
  trigger.setAttribute("data-salad-for", "other-menu");
  hook.updated();
  cleanups.push(() => hook.component?.destroy());

  assert.equal(hook.component.state, "closed");
});

test("a patch that rebuilds the open menu and changes its context re-evaluates", () => {
  const { $, more, shown } = build();
  click($("#more-1"));
  const hook = hookFor(more.el, more);

  hook.beforeUpdate();
  simulatePatch(more.el, { hidden: ["[data-part='positioner']"] });
  $("#more-1").setAttribute(
    "data-salad-context",
    JSON.stringify({ ...ROWS[0], pinned: true }),
  );
  hook.updated();
  cleanups.push(() => hook.component?.destroy());

  assert.equal(hook.component.state, "open");
  assert.deepEqual(shown("more").slice(0, 2), ["reply", "unpin"]);
});

// --- #19: JS commands reach the row -------------------------------------------

test("dispatch_command placeholders resolve to the open menu's trigger and context", () => {
  const { $, item } = build();
  const received = [];
  $("#picker").addEventListener("salad_ui:command", (event) =>
    received.push(event.detail.params),
  );
  click($("#more-2"));
  const remind = item("more", "remind");

  // What LiveView's JS.dispatch does when the item's phx-click runs (after
  // the click closed the menu).
  click(remind);
  $("#picker").dispatchEvent(
    new window.CustomEvent("salad_ui:command", {
      detail: {
        command: "open",
        params: {
          anchor: { __salad__: "trigger" },
          event: "react",
          values: { id: { __salad__: "context", key: "id" } },
          context: { __salad__: "context" },
        },
        dispatcher: remind,
      },
    }),
  );

  assert.equal(received.length, 1);
  assert.equal(received[0].anchor, $("#more-2"));
  assert.deepEqual(received[0].values, { id: 2 });
  assert.equal(received[0].event, "react");
  assert.deepEqual(received[0].context, ROWS[1]);
});

test("placeholders resolve from the menu root (an on-select JS command) and from a trigger", () => {
  const { $, more } = build();
  contextmenu($("#row-3"), 20, 160);
  const ctxRoot = $("#ctx");

  assert.deepEqual(contextSourceOf(ctxRoot), {
    trigger: $("#row-3"),
    context: ROWS[2],
  });
  // A detached trigger itself.
  assert.equal(contextSourceOf($("#more-1")).trigger, $("#more-1"));
  assert.deepEqual(
    resolveContextParams(
      { id: { __salad__: "context", key: "id" } },
      contextSourceOf($("#more-1")),
    ),
    { id: 1 },
  );
  // Elsewhere: null.
  assert.deepEqual(
    resolveContextParams(
      { a: { __salad__: "trigger" }, b: [{ __salad__: "context" }], c: 1 },
      contextSourceOf(more.el),
    ),
    { a: null, b: [null], c: 1 },
  );
});

test("an item's context and phx-value-* are gone once the menu has closed", async () => {
  const { $, item, more } = build();
  click($("#more-2"));
  const pin = item("more", "unpin");
  assert.equal(pin.getAttribute("phx-value-id"), "2");

  click(pin);
  assert.equal(more.state, "closed");
  // Still there for this click's LiveView handling...
  assert.equal(contextSourceOf(pin).trigger, $("#more-2"));
  await wait(5);
  // ... gone afterwards.
  assert.equal(pin.hasAttribute("phx-value-id"), false);
  assert.equal(contextSourceOf(pin), null);
});

test("SaladUI.JS.copy copies the row's text relative to the menu's trigger", async () => {
  const { $, item } = build();
  const written = [];
  const clipboard = { writeText: async (text) => written.push(text) };
  Object.defineProperty(globalThis.navigator, "clipboard", {
    value: clipboard,
    configurable: true,
  });
  cleanups.push(() => delete globalThis.navigator.clipboard);

  contextmenu($("#row-3"), 20, 160);
  const remind = item("ctx", "remind");
  click(remind);
  remind.dispatchEvent(
    new window.CustomEvent("salad_ui:copy", {
      bubbles: true,
      detail: { within: "[data-row]", from: "[data-text]", dispatcher: remind },
    }),
  );
  await flush();
  assert.deepEqual(written, ["Message 3"]);

  // `text`, with a placeholder; the element itself without from/within.
  assert.equal(
    textToCopy({ text: { __salad__: "context", key: "kind" } }, $("#more-1")),
    "user",
  );
  assert.equal(textToCopy({ text: "plain" }, null), "plain");
  // Inside a detached trigger, relative to that trigger.
  assert.equal(
    textToCopy({ from: "[data-text]", within: "[data-row]" }, $("#more-1")),
    "Message 1",
  );
  const note = document.createElement("span");
  note.textContent = "  outside  ";
  document.body.append(note);
  assert.equal(textToCopy({}, note), "outside");
  assert.equal(textToCopy({ from: "#nope" }, $("#more-1")), null);
});
