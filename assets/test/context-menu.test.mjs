import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/context_menu.js"; // self-registers "context-menu"
import { installDom, setRect, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  document.body.innerHTML = "";
});

const PANEL = { width: 160, height: 120 };

function build({
  dir = null,
  side = "right",
  disabled = false,
  usePortal = false,
  // `close-on-select={false}` on the checkbox item.
  bookmarksStayOpen = false,
  // The exit animation context_menu/1 configures.
  animated = false,
} = {}) {
  const options = JSON.stringify({
    usePortal,
    ...(animated && {
      animations: {
        open_to_closed: { duration: 130, target_part: "content" },
      },
    }),
  });
  document.body.innerHTML = `
    <div ${dir ? `dir="${dir}"` : ""}>
      <div id="cm" data-component="context-menu" data-state="closed" data-part="root"
           data-options='${options}'
           data-event-mappings='{"open":"opened","close":"closed"}'>
        <span data-part="trigger" ${disabled ? "data-disabled" : ""}>
          Right click here <button id="inner" type="button">inner</button>
        </span>
        <div data-part="positioner" data-side="${side}" hidden>
          <div data-part="content" role="menu" tabindex="-1">
            <div data-part="item" data-value="back" tabindex="-1"
                 data-event-mappings='{"select":"back"}'>Back</div>
            <div data-part="item" data-value="forward" data-disabled tabindex="-1">Forward</div>
            <div data-part="item" data-value="reload" tabindex="-1">Reload</div>
            <div data-part="sub">
              <div data-part="sub-trigger" data-state="closed" tabindex="-1">More Tools</div>
              <div data-part="sub-positioner" data-side="right" data-align="start" hidden>
                <div data-part="sub-content" data-state="closed" role="menu">
                  <div data-part="item" data-value="save" tabindex="-1">Save Page...</div>
                </div>
              </div>
            </div>
            <div data-part="checkbox-item" data-value="bookmarks" data-state="checked"
                 ${bookmarksStayOpen ? 'data-close-on-select="false"' : ""}
                 data-event-mappings='{"checked-change":"bookmarks"}' tabindex="-1">
              <span data-part="item-indicator">✓</span>Show Bookmarks
            </div>
          </div>
        </div>
      </div>
    </div>
    <button id="outside" type="button">outside</button>
  `;

  const el = document.getElementById("cm");
  const q = (selector) => el.querySelector(selector);
  const pushed = [];
  const trigger = q("[data-part='trigger']");
  const positioner = q("[data-part='positioner']");

  setRect(trigger, {
    top: 100,
    left: 100,
    right: 400,
    bottom: 300,
    width: 300,
    height: 200,
  });
  setRect(positioner, PANEL);

  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };
  const component = registry.create("context-menu", el, hookContext);

  return {
    component,
    el,
    hookContext,
    pushed,
    trigger,
    positioner,
    content: q("[data-part='content']"),
    back: q("[data-value='back']"),
    reload: q("[data-value='reload']"),
    subTrigger: q("[data-part='sub-trigger']"),
    subPositioner: q("[data-part='sub-positioner']"),
    save: q("[data-value='save']"),
    bookmarks: q("[data-part='checkbox-item']"),
    outside: document.getElementById("outside"),
  };
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

function pointer(el, type, { pointerType = "touch", x = 150, y = 150 } = {}) {
  el.dispatchEvent(
    new window.PointerEvent(type, {
      bubbles: true,
      cancelable: true,
      pointerType,
      clientX: x,
      clientY: y,
    }),
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

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
}

const px = (value) => `${value}px`;

test("right click opens the menu at the pointer and focuses the panel", () => {
  const { component, content, positioner, pushed, trigger } = build();

  const event = contextmenu(trigger, 200, 150);

  assert.equal(event.defaultPrevented, true, "suppresses the native menu");
  assert.equal(component.state, "open");
  assert.equal(positioner.hidden, false);
  assert.equal(content.getAttribute("data-state"), "open");
  assert.equal(content.getAttribute("role"), "menu");
  assert.equal(positioner.style.position, "fixed");
  assert.equal(positioner.style.left, px(202));
  assert.equal(positioner.style.top, px(150));
  assert.equal(content.getAttribute("data-side"), "right");
  assert.equal(document.activeElement, content);
  assert.deepEqual(
    pushed.map(({ event }) => event),
    ["opened"],
  );

  component.destroy();
});

test("ArrowDown from the focused panel moves to the first enabled item", () => {
  const { back, component, content, reload, trigger } = build();

  contextmenu(trigger, 200, 150);
  keydown(content, "ArrowDown");
  assert.equal(document.activeElement, back);
  keydown(back, "ArrowDown");
  assert.equal(document.activeElement, reload, "skips the disabled item");

  component.destroy();
});

test("a keyboard-invoked context menu anchors at the trigger and focuses the first item", () => {
  const { back, component, positioner, trigger } = build();

  contextmenu(trigger.querySelector("#inner"), 0, 0);

  assert.equal(component.state, "open");
  assert.equal(positioner.style.top, px(100));
  assert.equal(document.activeElement, back);

  component.destroy();
});

test("right clicking again moves the open menu to the new point", () => {
  const { component, positioner, trigger } = build();

  contextmenu(trigger, 200, 150);
  contextmenu(trigger, 300, 250);

  assert.equal(component.state, "open");
  assert.equal(positioner.style.left, px(302));
  assert.equal(positioner.style.top, px(250));

  component.destroy();
});

test("Escape closes the menu and restores focus", () => {
  const { component, content, pushed, trigger } = build();
  const inner = trigger.querySelector("#inner");
  inner.focus();

  contextmenu(inner, 200, 150);
  assert.equal(document.activeElement, content);

  const event = keydown(content, "Escape");
  assert.equal(event.defaultPrevented, true);
  assert.equal(component.state, "closed");
  assert.equal(document.activeElement, inner);
  assert.ok(pushed.some(({ event }) => event === "closed"));

  component.destroy();
});

test("Tab is swallowed while the menu is open", () => {
  const { back, component, content, trigger } = build();

  contextmenu(trigger, 200, 150);
  keydown(content, "ArrowDown");
  const event = keydown(back, "Tab");
  assert.equal(event.defaultPrevented, true);
  assert.equal(component.state, "open");

  component.destroy();
});

test("selecting an item fires on-select and closes the menu", () => {
  const { back, component, pushed, trigger } = build();

  contextmenu(trigger, 200, 150);
  click(back);

  assert.equal(component.state, "closed");
  assert.ok(
    pushed.some(
      ({ event, payload }) => event === "back" && payload.value === "back",
    ),
  );

  component.destroy();
});

test("checkbox items toggle and close the menu, as in Radix", () => {
  const { bookmarks, component, pushed, trigger } = build();

  contextmenu(trigger, 200, 150);
  click(bookmarks);

  assert.equal(component.state, "closed");
  assert.equal(bookmarks.getAttribute("aria-checked"), "false");
  assert.ok(
    pushed.some(
      ({ event, payload }) =>
        event === "bookmarks" && payload.checked === false,
    ),
  );

  component.destroy();
});

test("a checkbox item with close-on-select={false} keeps the menu open", () => {
  const { bookmarks, component, pushed, trigger } = build({
    bookmarksStayOpen: true,
  });

  contextmenu(trigger, 200, 150);
  click(bookmarks);

  assert.equal(component.state, "open");
  assert.equal(bookmarks.getAttribute("aria-checked"), "false");
  assert.ok(
    pushed.some(
      ({ event, payload }) =>
        event === "bookmarks" && payload.checked === false,
    ),
  );

  component.destroy();
});

test("sub-menus open with ArrowRight inside a context menu", () => {
  const { component, content, save, subPositioner, subTrigger, trigger } =
    build();

  contextmenu(trigger, 200, 150);
  keydown(content, "End");
  keydown(document.activeElement, "ArrowUp");
  assert.equal(document.activeElement, subTrigger);

  keydown(subTrigger, "ArrowRight");
  assert.equal(subPositioner.hidden, false);
  assert.equal(document.activeElement, save);

  keydown(save, "ArrowLeft");
  assert.equal(subPositioner.hidden, true);
  assert.equal(document.activeElement, subTrigger);

  component.destroy();
});

test("typing from the focused panel jumps to the matching item", () => {
  const { component, content, reload, trigger } = build();

  contextmenu(trigger, 200, 150);
  assert.equal(document.activeElement, content);

  keydown(content, "r");
  assert.equal(document.activeElement, reload);

  component.destroy();
});

test("typeahead skips disabled items", () => {
  const { component, content, trigger } = build();

  contextmenu(trigger, 200, 150);
  // Only the disabled "Forward" starts with "f".
  keydown(content, "f");
  assert.equal(document.activeElement, content);

  component.destroy();
});

test("typeahead inside a context sub-menu searches only the sub-menu", () => {
  const { component, content, save, subTrigger, trigger } = build();

  contextmenu(trigger, 200, 150);
  keydown(content, "End");
  keydown(document.activeElement, "ArrowUp");
  keydown(subTrigger, "ArrowRight");
  assert.equal(document.activeElement, save);

  // "Back" and "Show Bookmarks" are in the parent panel.
  keydown(save, "b");
  assert.equal(document.activeElement, save);
  keydown(save, "s");
  assert.equal(document.activeElement, save, "no other sub-menu match");

  component.destroy();
});

test("clicking outside closes without moving focus back", () => {
  const { component, outside, trigger } = build();

  contextmenu(trigger, 200, 150);
  click(outside);

  assert.equal(component.state, "closed");

  component.destroy();
});

test("right clicking elsewhere closes the menu", () => {
  const { component, outside, trigger } = build();

  contextmenu(trigger, 200, 150);
  const event = contextmenu(outside, 600, 500);

  assert.equal(component.state, "closed");
  assert.equal(event.defaultPrevented, false, "native menu shows there");

  component.destroy();
});

test("a disabled trigger leaves the native context menu alone", () => {
  const { component, trigger } = build({ disabled: true });

  const event = contextmenu(trigger, 200, 150);
  assert.equal(event.defaultPrevented, false);
  assert.equal(component.state, "closed");

  component.destroy();
});

test("a long press on touch opens the menu at the press point", async () => {
  const { component, positioner, trigger } = build();

  pointer(trigger, "pointerdown", { x: 180, y: 160 });
  assert.equal(component.state, "closed", "not before the delay");

  await waitFor(() => component.state === "open");
  assert.equal(positioner.style.left, px(182));
  assert.equal(positioner.style.top, px(160));

  // Lifting the finger ends the gesture on the trigger; that must not close.
  pointer(trigger, "pointerup", { x: 180, y: 160 });
  click(trigger);
  assert.equal(component.state, "open");

  component.destroy();
});

test("moving the finger or a mouse press does not start a long press", async () => {
  const { component, trigger } = build();

  pointer(trigger, "pointerdown");
  pointer(trigger, "pointermove");
  pointer(trigger, "pointerdown", { pointerType: "mouse" });

  assert.equal(component.longPressTimer, null);
  assert.equal(component.state, "closed");

  component.destroy();
});

test("side=top opens above the pointer", () => {
  const { component, content, positioner, trigger } = build({ side: "top" });

  contextmenu(trigger, 200, 300);
  assert.equal(positioner.style.left, px(200));
  assert.equal(positioner.style.top, px(300 - PANEL.height - 2));
  assert.equal(content.getAttribute("data-side"), "top");

  component.destroy();
});

test("RTL opens to the left of the pointer", () => {
  const { component, content, positioner, trigger } = build({ dir: "rtl" });

  contextmenu(trigger, 500, 150);
  assert.equal(positioner.style.left, px(500 - PANEL.width - 2));
  assert.equal(content.getAttribute("data-side"), "left");

  component.destroy();
});

test("near the viewport edges the menu flips and opens upwards", () => {
  const { component, content, positioner, trigger } = build();
  const x = window.innerWidth - 50;
  const y = window.innerHeight - 20;

  contextmenu(trigger, x, y);
  assert.equal(content.getAttribute("data-side"), "left");
  assert.equal(positioner.style.left, px(x - PANEL.width - 2));
  assert.equal(positioner.style.top, px(y - PANEL.height));

  component.destroy();
});

test("open/close/toggle commands drive the menu, anchored at the trigger", () => {
  const { component, positioner } = build();

  component.handleCommand("open");
  assert.equal(component.state, "open");
  assert.equal(positioner.style.top, px(300));

  component.handleCommand("toggle");
  assert.equal(component.state, "closed");
  component.handleCommand("toggle");
  assert.equal(component.state, "open");
  component.handleCommand("close");
  assert.equal(component.state, "closed");

  component.destroy();
});

test("a LiveView rebuild re-opens the menu at the same point", () => {
  const { component, el, hookContext, positioner, trigger } = build();

  const content = el.querySelector("[data-part='content']");

  contextmenu(trigger, 200, 150);
  // What SaladUIHook does around a patch: beforeUpdate, patch, rebuild.
  component.beforeUpdate();
  assert.equal(content.id, "", "client-only ids are stripped");
  component.destroy();
  positioner.hidden = true;

  const rebuilt = registry.create("context-menu", el, hookContext);
  assert.equal(rebuilt.state, "open");
  assert.equal(positioner.hidden, false);
  assert.equal(positioner.style.left, px(202));
  assert.equal(positioner.style.top, px(150));
  assert.equal(document.activeElement, content);

  rebuilt.destroy();
});

test("a LiveView rebuild keeps the open sub-menu and focused item", () => {
  const { component, content, el, hookContext, save, subPositioner, trigger } =
    build();

  contextmenu(trigger, 200, 150);
  keydown(content, "End");
  keydown(document.activeElement, "ArrowUp");
  keydown(document.activeElement, "ArrowRight");
  assert.equal(document.activeElement, save);

  component.beforeUpdate();
  component.destroy();
  subPositioner.hidden = true;

  const rebuilt = registry.create("context-menu", el, hookContext);
  assert.equal(subPositioner.hidden, false);
  assert.equal(document.activeElement, save);

  rebuilt.destroy();
});

test("a LiveView rebuild keeps focus on a toggled checkbox item", () => {
  const { bookmarks, component, el, hookContext, trigger } = build({
    bookmarksStayOpen: true,
  });

  contextmenu(trigger, 200, 150);
  bookmarks.focus();
  click(bookmarks);

  component.beforeUpdate();
  component.destroy();
  const rebuilt = registry.create("context-menu", el, hookContext);
  assert.equal(document.activeElement, bookmarks);

  keydown(bookmarks, "ArrowUp");
  assert.equal(
    document.activeElement,
    el.querySelector("[data-part='sub-trigger']"),
  );

  rebuilt.destroy();
});

test("with the exit animation, closing returns focus and fires close at once, then hides", async () => {
  const { component, content, positioner, pushed, trigger } = build({
    animated: true,
  });
  const inner = trigger.querySelector("#inner");
  inner.focus();

  contextmenu(inner, 200, 150);
  assert.equal(document.activeElement, content);

  keydown(content, "Escape");
  assert.equal(component.state, "closed");
  assert.equal(document.activeElement, inner);
  assert.ok(pushed.some(({ event }) => event === "closed"));
  // The panel stays up while it animates out.
  assert.equal(positioner.hidden, false);

  await waitFor(() => positioner.hidden === true);

  component.destroy();
});

test("a LiveView rebuild during the exit animation still returns focus and fires close", async () => {
  const { back, component, el, hookContext, positioner, pushed, trigger } =
    build({ animated: true });
  const inner = trigger.querySelector("#inner");
  inner.focus();

  // Keep hold of the exit animation so the test can let it drain.
  let exitAnimation = null;
  const machine = component.stateMachine;
  const onStateChanged = machine.options.onStateChanged;
  machine.options.onStateChanged = (...args) =>
    (exitAnimation = onStateChanged(...args));

  contextmenu(inner, 200, 150);
  // Selecting an item pushes its on-select; the server's reply patches the
  // menu before the 130ms exit animation finishes.
  click(back);
  component.beforeUpdate();
  component.destroy();
  positioner.hidden = true;

  const rebuilt = registry.create("context-menu", el, hookContext);
  assert.equal(rebuilt.state, "closed");
  assert.equal(positioner.hidden, true);
  assert.equal(document.activeElement, inner);
  assert.deepEqual(
    pushed.map(({ event }) => event).filter((event) => event !== "back"),
    ["opened", "closed"],
  );

  rebuilt.destroy();
  await exitAnimation;
});

test("a keyboard contextmenu PointerEvent (empty pointerType) opens at the first item", () => {
  const { back, component, positioner, trigger } = build();
  const inner = trigger.querySelector("#inner");
  inner.focus();

  // Browsers place a keyboard-fired contextmenu near the focused element.
  inner.dispatchEvent(
    new window.PointerEvent("contextmenu", {
      bubbles: true,
      cancelable: true,
      clientX: 180,
      clientY: 140,
      pointerType: "",
    }),
  );

  assert.equal(component.state, "open");
  assert.equal(document.activeElement, back);
  assert.equal(positioner.style.top, px(100));

  component.destroy();
});
