import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/menubar.js"; // self-registers "menubar"
import { installDom, setRect, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  document.body.innerHTML = "";
});

function menuMarkup(value, label, inner, { disabled = false } = {}) {
  return `
    <div data-part="menu" data-value="${value}" role="none">
      <button type="button" data-part="trigger" role="menuitem" tabindex="-1"
              ${disabled ? "disabled data-disabled" : ""}>${label}</button>
      <div data-part="positioner" data-side="bottom" data-align="start"
           data-side-offset="8" data-align-offset="-4" hidden>
        <div data-part="content" role="menu" tabindex="-1" data-state="closed">${inner}</div>
      </div>
    </div>
  `;
}

function build({ dir = null, loop = true, disabledLast = false } = {}) {
  const file = menuMarkup(
    "file",
    "File",
    `
      <div data-part="item" data-value="new-tab" tabindex="-1"
           data-event-mappings='{"select":"selected"}'>New Tab</div>
      <div data-part="sub">
        <div data-part="sub-trigger" data-state="closed" tabindex="-1">Share</div>
        <div data-part="sub-positioner" data-side="right" data-align="start" hidden>
          <div data-part="sub-content" data-state="closed" role="menu">
            <div data-part="item" data-value="email" tabindex="-1">Email link</div>
          </div>
        </div>
      </div>
      <div data-part="item" data-value="print" tabindex="-1">Print</div>
    `,
  );
  const edit = menuMarkup(
    "edit",
    "Edit",
    `
      <div data-part="item" data-value="undo" tabindex="-1">Undo</div>
      <div data-part="item" data-value="redo" tabindex="-1">Redo</div>
    `,
  );
  const view = menuMarkup(
    "view",
    "View",
    `
      <div data-part="checkbox-item" data-value="urls" data-state="unchecked"
           data-event-mappings='{"checked-change":"urls"}' tabindex="-1">
        <span data-part="item-indicator" hidden>✓</span>Full URLs
      </div>
      <div data-part="radio-group" data-value="andy" role="group"
           data-event-mappings='{"value-changed":"profile"}'>
        <div data-part="radio-item" data-value="andy" tabindex="-1">
          <span data-part="item-indicator" hidden>•</span>Andy
        </div>
        <div data-part="radio-item" data-value="benoit" tabindex="-1">
          <span data-part="item-indicator" hidden>•</span>Benoit
        </div>
      </div>
    `,
    { disabled: disabledLast },
  );

  document.body.innerHTML = `
    <div ${dir ? `dir="${dir}"` : ""}>
      <div id="mb" data-component="menubar" data-part="root" data-state="closed"
           role="menubar" data-options='{"loop":${loop}}'
           data-event-mappings='{"value-changed":"menu_changed"}'>
        ${file}${edit}${view}
      </div>
    </div>
    <button id="outside" type="button">outside</button>
  `;

  const el = document.getElementById("mb");
  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const triggers = el.querySelectorAll("[data-part='trigger']");
  triggers.forEach((trigger, index) =>
    setRect(trigger, {
      top: 10,
      bottom: 30,
      left: 10 + index * 60,
      right: 60 + index * 60,
      width: 50,
      height: 20,
    }),
  );

  const component = registry.create("menubar", el, hookContext);
  const byValue = (value) => el.querySelector(`[data-value='${value}']`);
  const part = (value, name) =>
    byValue(value).querySelector(`[data-part='${name}']`);

  return {
    component,
    el,
    hookContext,
    pushed,
    file: { trigger: triggers[0], ...panel("file") },
    edit: { trigger: triggers[1], ...panel("edit") },
    view: { trigger: triggers[2], ...panel("view") },
    item: (value) =>
      el.querySelector(
        `[data-value='${value}']:not([data-part='radio-group'])`,
      ),
    outside: document.getElementById("outside"),
  };

  function panel(value) {
    return {
      positioner: part(value, "positioner"),
      content: part(value, "content"),
    };
  }
}

function pointer(el, type, { pointerType = "mouse", button = 0 } = {}) {
  const event = new window.PointerEvent(type, {
    bubbles: type !== "pointerenter",
    cancelable: true,
    pointerType,
    button,
  });
  el.dispatchEvent(event);
  return event;
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

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
}

const values = (pushed) =>
  pushed
    .filter(({ event }) => event === "menu_changed")
    .map(({ payload }) => payload.value);

test("triggers carry menubar ARIA and form a single tab stop", () => {
  const { component, edit, el, file, view } = build();

  assert.equal(el.getAttribute("role"), "menubar");
  assert.equal(file.trigger.getAttribute("tabindex"), "0");
  assert.equal(edit.trigger.getAttribute("tabindex"), "-1");
  assert.equal(view.trigger.getAttribute("tabindex"), "-1");
  assert.equal(file.trigger.getAttribute("aria-expanded"), "false");
  assert.equal(file.trigger.getAttribute("aria-controls"), file.content.id);
  assert.equal(file.content.getAttribute("aria-labelledby"), file.trigger.id);

  component.destroy();
});

test("pressing a trigger opens its menu; pressing it again closes it", () => {
  const { component, el, file, pushed } = build();

  const down = pointer(file.trigger, "pointerdown");
  assert.equal(down.defaultPrevented, true);
  assert.equal(component.state, "open");
  assert.equal(el.getAttribute("data-state"), "open");
  assert.equal(file.positioner.hidden, false);
  assert.equal(file.trigger.getAttribute("data-state"), "open");
  assert.equal(file.trigger.getAttribute("aria-expanded"), "true");
  assert.equal(file.content.getAttribute("data-state"), "open");
  assert.equal(document.activeElement, file.trigger);

  pointer(file.trigger, "pointerdown");
  assert.equal(component.state, "closed");
  assert.equal(file.positioner.hidden, true);
  assert.equal(file.trigger.getAttribute("data-state"), "closed");
  assert.deepEqual(values(pushed), ["file", ""]);

  component.destroy();
});

test("right and middle presses do not open a menu", () => {
  const { component, file } = build();

  pointer(file.trigger, "pointerdown", { button: 2 });
  pointer(file.trigger, "pointerdown", { button: 1 });
  assert.equal(component.state, "closed");

  component.destroy();
});

test("while a menu is open, hovering another trigger switches to it", () => {
  const { component, edit, file, pushed } = build();

  pointer(edit.trigger, "pointerenter");
  assert.equal(component.state, "closed", "hover alone opens nothing");

  pointer(file.trigger, "pointerdown");
  pointer(edit.trigger, "pointerenter");

  assert.equal(file.positioner.hidden, true);
  assert.equal(file.trigger.getAttribute("data-state"), "closed");
  assert.equal(edit.positioner.hidden, false);
  assert.equal(edit.trigger.getAttribute("data-state"), "open");
  assert.equal(document.activeElement, edit.trigger);
  assert.equal(edit.trigger.getAttribute("tabindex"), "0");
  assert.equal(file.trigger.getAttribute("tabindex"), "-1");
  assert.deepEqual(values(pushed), ["file", "edit"]);

  component.destroy();
});

test("touch pointerenter does not switch menus", () => {
  const { component, edit, file } = build();

  pointer(file.trigger, "pointerdown");
  pointer(edit.trigger, "pointerenter", { pointerType: "touch" });
  assert.equal(file.positioner.hidden, false);
  assert.equal(edit.positioner.hidden, true);

  component.destroy();
});

test("ArrowRight/ArrowLeft rove focus across triggers, wrapping", () => {
  const { component, edit, file, view } = build();

  file.trigger.focus();
  keydown(file.trigger, "ArrowRight");
  assert.equal(document.activeElement, edit.trigger);
  assert.equal(edit.trigger.getAttribute("tabindex"), "0");
  assert.equal(file.trigger.getAttribute("tabindex"), "-1");

  keydown(edit.trigger, "ArrowRight");
  keydown(view.trigger, "ArrowRight");
  assert.equal(document.activeElement, file.trigger, "wraps to the first");

  keydown(file.trigger, "ArrowLeft");
  assert.equal(document.activeElement, view.trigger, "wraps to the last");

  keydown(view.trigger, "Home");
  assert.equal(document.activeElement, file.trigger);
  keydown(file.trigger, "End");
  assert.equal(document.activeElement, view.trigger);
  assert.equal(component.state, "closed");

  component.destroy();
});

test("loop=false stops at the ends; disabled triggers are skipped", () => {
  const { component, edit, file } = build({ loop: false, disabledLast: true });

  edit.trigger.focus();
  keydown(edit.trigger, "ArrowRight");
  assert.equal(document.activeElement, edit.trigger);

  keydown(edit.trigger, "ArrowLeft");
  assert.equal(document.activeElement, file.trigger);
  keydown(file.trigger, "ArrowLeft");
  assert.equal(document.activeElement, file.trigger);

  component.destroy();
});

test("ArrowDown, Enter and Space open a menu at its first item; ArrowUp at its last", () => {
  const { component, file, item } = build();

  file.trigger.focus();
  const down = keydown(file.trigger, "ArrowDown");
  assert.equal(down.defaultPrevented, true);
  assert.equal(document.activeElement, item("new-tab"));

  keydown(item("new-tab"), "Escape");
  assert.equal(component.state, "closed");
  assert.equal(document.activeElement, file.trigger);

  keydown(file.trigger, "ArrowUp");
  assert.equal(document.activeElement, item("print"));
  keydown(item("print"), "Escape");

  keydown(file.trigger, "Enter");
  assert.equal(document.activeElement, item("new-tab"));
  keydown(item("new-tab"), "Escape");

  keydown(file.trigger, " ");
  assert.equal(document.activeElement, item("new-tab"));

  component.destroy();
});

test("ArrowDown on the trigger of a mouse-opened menu moves into it", () => {
  const { component, file, item } = build();

  pointer(file.trigger, "pointerdown");
  keydown(file.trigger, "ArrowDown");
  assert.equal(document.activeElement, item("new-tab"));
  assert.equal(component.state, "open");

  component.destroy();
});

test("with a menu open, arrowing across triggers moves the open menu along", () => {
  const { component, edit, file } = build();

  pointer(file.trigger, "pointerdown");
  keydown(file.trigger, "ArrowRight");

  assert.equal(document.activeElement, edit.trigger);
  assert.equal(file.positioner.hidden, true);
  assert.equal(edit.positioner.hidden, false);

  component.destroy();
});

test("ArrowRight/ArrowLeft inside a menu open the adjacent menu at its first item", () => {
  const { component, edit, file, item, view } = build();

  file.trigger.focus();
  keydown(file.trigger, "ArrowDown");
  const right = keydown(item("new-tab"), "ArrowRight");
  assert.equal(right.defaultPrevented, true);
  assert.equal(file.positioner.hidden, true);
  assert.equal(edit.positioner.hidden, false);
  assert.equal(document.activeElement, item("undo"));
  assert.equal(edit.trigger.getAttribute("tabindex"), "0");

  keydown(item("undo"), "ArrowLeft");
  assert.equal(document.activeElement, item("new-tab"));

  keydown(item("new-tab"), "ArrowLeft");
  assert.equal(view.positioner.hidden, false, "wraps to the last menu");

  component.destroy();
});

test("sub-menus keep their own ArrowRight/ArrowLeft inside a menubar", () => {
  const { component, edit, file, item } = build();
  const share = file.content.querySelector("[data-part='sub-trigger']");
  const subPositioner = file.content.querySelector(
    "[data-part='sub-positioner']",
  );

  file.trigger.focus();
  keydown(file.trigger, "ArrowDown");
  keydown(item("new-tab"), "ArrowDown");
  assert.equal(document.activeElement, share);

  keydown(share, "ArrowRight");
  assert.equal(subPositioner.hidden, false, "opens the sub-menu");
  assert.equal(document.activeElement, item("email"));
  assert.equal(edit.positioner.hidden, true);

  keydown(item("email"), "ArrowLeft");
  assert.equal(subPositioner.hidden, true, "closes only the sub-menu");
  assert.equal(document.activeElement, share);
  assert.equal(file.positioner.hidden, false);

  keydown(share, "ArrowRight");
  keydown(item("email"), "ArrowRight");
  assert.equal(edit.positioner.hidden, false, "then moves to the next menu");
  assert.equal(document.activeElement, item("undo"));

  component.destroy();
});

test("typing inside an open menu jumps to the matching item", () => {
  const { component, file, item } = build();

  file.trigger.focus();
  keydown(file.trigger, "ArrowDown");
  keydown(item("new-tab"), "p");
  assert.equal(document.activeElement, item("print"));
  assert.equal(file.positioner.hidden, false);

  // The repeated letter cycles: "pp" has only one match, so focus stays.
  keydown(item("print"), "p");
  assert.equal(document.activeElement, item("print"));

  component.destroy();
});

test("typeahead in a menubar sub-menu searches only the sub-menu", () => {
  const { component, file, item } = build();
  const share = file.content.querySelector("[data-part='sub-trigger']");

  file.trigger.focus();
  keydown(file.trigger, "ArrowDown");
  keydown(item("new-tab"), "s");
  assert.equal(document.activeElement, share);
  assert.equal(share.getAttribute("data-state"), "closed");

  keydown(share, "ArrowRight");
  assert.equal(document.activeElement, item("email"));

  // "Print" and "New Tab" are in the parent panel.
  keydown(item("email"), "p");
  assert.equal(document.activeElement, item("email"));
  keydown(item("email"), "n");
  assert.equal(document.activeElement, item("email"));
  assert.equal(file.positioner.hidden, false);

  component.destroy();
});

test("RTL mirrors the horizontal keys", () => {
  const { component, edit, file, item } = build({ dir: "rtl" });

  file.trigger.focus();
  keydown(file.trigger, "ArrowLeft");
  assert.equal(document.activeElement, edit.trigger);

  keydown(edit.trigger, "ArrowDown");
  keydown(item("undo"), "ArrowRight");
  assert.equal(file.positioner.hidden, false);
  assert.equal(document.activeElement, item("new-tab"));

  component.destroy();
});

test("selecting an item closes the menu and returns focus to its trigger", () => {
  const { component, file, item, pushed } = build();

  file.trigger.focus();
  keydown(file.trigger, "ArrowDown");
  keydown(item("new-tab"), "Enter");

  assert.equal(component.state, "closed");
  assert.equal(document.activeElement, file.trigger);
  assert.ok(
    pushed.some(
      ({ event, payload }) =>
        event === "selected" && payload.value === "new-tab",
    ),
  );

  component.destroy();
});

test("checkbox and radio items update in place and keep the menu open", () => {
  const { component, item, pushed, view } = build();

  pointer(view.trigger, "pointerdown");
  click(item("urls"));
  assert.equal(item("urls").getAttribute("aria-checked"), "true");
  assert.equal(item("andy").getAttribute("aria-checked"), "true");

  click(item("benoit"));
  assert.equal(item("benoit").getAttribute("aria-checked"), "true");
  assert.equal(item("andy").getAttribute("aria-checked"), "false");
  assert.equal(component.state, "open");
  assert.ok(pushed.some(({ event }) => event === "urls"));
  assert.ok(
    pushed.some(
      ({ event, payload }) => event === "profile" && payload.value === "benoit",
    ),
  );

  component.destroy();
});

test("Tab inside a menu is swallowed; clicking outside closes", () => {
  const { component, file, item, outside } = build();

  file.trigger.focus();
  keydown(file.trigger, "ArrowDown");
  const tab = keydown(item("new-tab"), "Tab");
  assert.equal(tab.defaultPrevented, true);
  assert.equal(component.state, "open");

  click(item("new-tab").closest("[data-part='content']"));
  assert.equal(component.state, "open", "clicks inside the panel keep it");

  click(outside);
  assert.equal(component.state, "closed");

  component.destroy();
});

test("focus leaving the menubar closes the open menu", () => {
  const { component, file, outside } = build();

  pointer(file.trigger, "pointerdown");
  file.trigger.dispatchEvent(
    new window.FocusEvent("focusout", {
      bubbles: true,
      relatedTarget: outside,
    }),
  );
  assert.equal(component.state, "closed");

  component.destroy();
});

test("open and close commands", () => {
  const { component, edit, file } = build();

  component.handleCommand("open");
  assert.equal(file.positioner.hidden, false);

  component.handleCommand("open", { value: "edit" });
  assert.equal(file.positioner.hidden, true);
  assert.equal(edit.positioner.hidden, false);

  component.handleCommand("close");
  assert.equal(component.state, "closed");

  component.destroy();
});

test("a LiveView rebuild re-opens the open menu and keeps item focus", () => {
  const { component, el, file, hookContext, item, pushed } = build();

  file.trigger.focus();
  keydown(file.trigger, "ArrowDown");
  keydown(item("new-tab"), "ArrowDown");
  keydown(document.activeElement, "ArrowDown");
  assert.equal(document.activeElement, item("print"));
  const pushedBefore = pushed.length;

  // What SaladUIHook does around a patch: beforeUpdate, patch, rebuild.
  component.beforeUpdate();
  assert.equal(file.trigger.id, "", "client-only ids are stripped");
  assert.equal(file.content.id, "");
  component.destroy();
  file.positioner.hidden = true;

  const rebuilt = registry.create("menubar", el, hookContext);
  assert.equal(rebuilt.state, "open");
  assert.equal(file.positioner.hidden, false);
  assert.equal(document.activeElement, item("print"));
  assert.equal(file.trigger.getAttribute("aria-controls"), file.content.id);
  assert.equal(pushed.length, pushedBefore, "no value-changed on rebuild");

  keydown(item("print"), "ArrowUp");
  assert.equal(
    document.activeElement,
    file.content.querySelector("[data-part='sub-trigger']"),
    "roving focus continues from the kept item",
  );

  rebuilt.destroy();
});

test("a LiveView rebuild keeps an open sub-menu open and the tab stop", () => {
  const { component, edit, el, file, hookContext, item } = build();
  const subPositioner = file.content.querySelector(
    "[data-part='sub-positioner']",
  );

  edit.trigger.focus();
  keydown(edit.trigger, "ArrowLeft");
  keydown(file.trigger, "ArrowDown");
  keydown(item("new-tab"), "ArrowDown");
  keydown(document.activeElement, "ArrowRight");
  assert.equal(document.activeElement, item("email"));

  component.beforeUpdate();
  component.destroy();
  file.positioner.hidden = true;
  subPositioner.hidden = true;

  const rebuilt = registry.create("menubar", el, hookContext);
  assert.equal(subPositioner.hidden, false);
  assert.equal(document.activeElement, item("email"));
  assert.equal(file.trigger.getAttribute("tabindex"), "0");
  assert.equal(edit.trigger.getAttribute("tabindex"), "-1");

  rebuilt.destroy();
});

test("a LiveView rebuild while closed keeps the roving tab stop", () => {
  const { component, edit, el, file, hookContext } = build();

  file.trigger.focus();
  keydown(file.trigger, "ArrowRight");
  component.beforeUpdate();
  component.destroy();

  const rebuilt = registry.create("menubar", el, hookContext);
  assert.equal(rebuilt.state, "closed");
  assert.equal(edit.trigger.getAttribute("tabindex"), "0");
  assert.equal(file.trigger.getAttribute("tabindex"), "-1");

  rebuilt.destroy();
});
