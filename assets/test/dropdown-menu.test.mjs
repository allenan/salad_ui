import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/dropdown_menu.js"; // self-registers "dropdown-menu"
import {
  hookFor,
  installDom,
  setRect,
  simulatePatch,
  uninstallDom,
  waitFor,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  document.body.innerHTML = "";
});

function buildDropdown({
  id = "dropdown-1",
  state = "closed",
  // The exit animation dropdown_menu/1 configures.
  animated = false,
  usePortal = false,
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
    <div id="${id}" data-component="dropdown-menu" data-state="${state}"
         data-options='${options}'
         data-event-mappings='{"open":"open","close":"close"}'
         data-part="root">
      <button type="button" data-part="trigger" tabindex="0">Open</button>
      <div data-part="positioner" data-side="bottom" data-align="start"
           data-side-offset="4" data-align-offset="0" hidden>
        <div data-part="content" data-side="bottom" data-align="start" tabindex="-1">
          <div data-part="item" data-value="profile" tabindex="0"
               data-event-mappings='{"select":"selected"}'>Profile</div>
          <div data-part="item" data-value="settings" tabindex="0"
               data-event-mappings='{"select":"selected"}'>Settings</div>
          <div data-part="checkbox-item" data-value="bold" data-state="checked"
               data-checked="true" tabindex="0"
               data-event-mappings='{"checked-change":"checked","select":"selected"}'>
            <span data-part="item-indicator">✓</span>
            Bold
          </div>
        </div>
      </div>
    </div>
  `;

  const el = document.getElementById(id);
  const trigger = el.querySelector('[data-part="trigger"]');
  const positioner = el.querySelector('[data-part="positioner"]');
  const content = el.querySelector('[data-part="content"]');
  const profile = el.querySelector('[data-value="profile"]');
  const settings = el.querySelector('[data-value="settings"]');
  const checkbox = el.querySelector('[data-part="checkbox-item"]');
  const pushed = [];

  setRect(trigger, {
    top: 10,
    left: 10,
    bottom: 30,
    right: 110,
    width: 100,
    height: 20,
  });
  setRect(positioner, { width: 160, height: 80 });
  setRect(content, { width: 160, height: 80 });

  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const component = registry.create("dropdown-menu", el, hookContext);

  return {
    component,
    el,
    trigger,
    positioner,
    content,
    profile,
    settings,
    checkbox,
    pushed,
  };
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

test("trigger click opens then closes dropdown", () => {
  const { component, positioner, pushed, trigger } = buildDropdown();

  click(trigger);
  assert.equal(positioner.hidden, false);
  assert.equal(trigger.getAttribute("aria-expanded"), "true");
  assert.equal(pushed.at(-1).event, "open");

  click(trigger);
  assert.equal(positioner.hidden, true);
  assert.equal(trigger.getAttribute("aria-expanded"), "false");
  assert.equal(pushed.at(-1).event, "close");
  assert.equal(document.activeElement, trigger);

  component.destroy();
});

test("opening another dropdown closes currently open dropdown", () => {
  document.body.innerHTML = `
    <div id="dropdown-1" data-component="dropdown-menu" data-state="closed"
         data-options='{"usePortal":false}' data-event-mappings='{}' data-part="root">
      <button type="button" data-part="trigger" tabindex="0">Open 1</button>
      <div data-part="positioner" data-side="bottom" data-align="start"
           data-side-offset="4" data-align-offset="0" hidden>
        <div data-part="content" data-side="bottom" data-align="start">
          <div data-part="item" data-value="one" tabindex="0">One</div>
        </div>
      </div>
    </div>
    <div id="dropdown-2" data-component="dropdown-menu" data-state="closed"
         data-options='{"usePortal":false}' data-event-mappings='{}' data-part="root">
      <button type="button" data-part="trigger" tabindex="0">Open 2</button>
      <div data-part="positioner" data-side="bottom" data-align="start"
           data-side-offset="4" data-align-offset="0" hidden>
        <div data-part="content" data-side="bottom" data-align="start">
          <div data-part="item" data-value="two" tabindex="0">Two</div>
        </div>
      </div>
    </div>
  `;

  const hookContext = {
    pushEventTo: () => {},
    liveSocket: { execJS: () => {} },
  };
  const firstEl = document.getElementById("dropdown-1");
  const secondEl = document.getElementById("dropdown-2");
  const first = registry.create("dropdown-menu", firstEl, hookContext);
  const second = registry.create("dropdown-menu", secondEl, hookContext);
  const firstTrigger = firstEl.querySelector('[data-part="trigger"]');
  const secondTrigger = secondEl.querySelector('[data-part="trigger"]');
  const firstPositioner = firstEl.querySelector('[data-part="positioner"]');
  const secondPositioner = secondEl.querySelector('[data-part="positioner"]');

  [firstEl, secondEl].forEach((el) => {
    setRect(el.querySelector('[data-part="trigger"]'), {
      top: 10,
      left: 10,
      bottom: 30,
      right: 110,
      width: 100,
      height: 20,
    });
    setRect(el.querySelector('[data-part="positioner"]'), {
      width: 160,
      height: 80,
    });
  });

  click(firstTrigger);
  assert.equal(firstPositioner.hidden, false);

  click(secondTrigger);
  assert.equal(firstPositioner.hidden, true);
  assert.equal(secondPositioner.hidden, false);
  assert.notEqual(document.activeElement, firstTrigger);
  assert.equal(secondEl.contains(document.activeElement), true);

  first.destroy();
  second.destroy();
});

test("initial open state activates positioning and ARIA controls", () => {
  const { component, content, positioner, pushed, trigger } = buildDropdown({
    state: "open",
  });

  assert.equal(positioner.hidden, false);
  assert.equal(component.positionedElement.active, true);
  assert.equal(content.id, "dropdown-1-content");
  assert.equal(trigger.getAttribute("aria-controls"), content.id);
  assert.equal(trigger.getAttribute("aria-expanded"), "true");
  assert.equal(pushed.length, 0);

  component.destroy();
});

test("Enter on focused item selects without reopening and focusing first item", () => {
  const { component, positioner, profile, pushed, settings, trigger } =
    buildDropdown();

  keydown(trigger, "Enter");
  assert.equal(document.activeElement, profile);

  keydown(profile, "ArrowDown");
  assert.equal(document.activeElement, settings);

  keydown(settings, "Enter");
  assert.equal(component.state, "closed");
  assert.equal(positioner.hidden, true);
  assert.equal(document.activeElement, trigger);
  assert.deepEqual(
    pushed.map(({ event }) => event),
    ["open", "selected", "close"],
  );

  component.destroy();
});

test("arrow keys navigate and prevent page scroll when open trigger keeps focus", () => {
  const { component, positioner, profile, settings, trigger } = buildDropdown();

  click(trigger);
  trigger.focus();

  const event = keydown(trigger, "ArrowDown");

  assert.equal(positioner.hidden, false);
  assert.equal(event.defaultPrevented, true);
  // A pointer open highlights nothing, so ArrowDown starts at the first item.
  assert.equal(document.activeElement, profile);
  keydown(trigger, "ArrowDown");
  assert.equal(document.activeElement, settings);

  component.destroy();
});

test("checkbox item starts checked and exposes menuitemcheckbox ARIA", () => {
  const { checkbox, component, pushed, trigger } = buildDropdown();

  click(trigger);
  assert.equal(checkbox.getAttribute("role"), "menuitemcheckbox");
  assert.equal(checkbox.getAttribute("aria-checked"), "true");

  click(checkbox);
  assert.equal(checkbox.getAttribute("data-state"), "unchecked");
  assert.equal(checkbox.getAttribute("aria-checked"), "false");
  assert.deepEqual(
    pushed.slice(-3).map(({ event }) => event),
    ["selected", "checked", "close"],
  );
  assert.deepEqual(pushed.at(-2).payload, {
    value: "bold",
    checked: false,
    componentId: "dropdown-1",
    component: "dropdown-menu",
  });
  // Toggling a checkbox item closes the menu, as in Radix.
  assert.equal(component.state, "closed");
  assert.equal(document.activeElement, trigger);

  component.destroy();
});

test("a checkbox item with close-on-select={false} toggles and keeps the menu open", () => {
  const { checkbox, component, pushed, trigger } = buildDropdown();
  checkbox.setAttribute("data-close-on-select", "false");

  click(trigger);
  click(checkbox);
  assert.equal(checkbox.getAttribute("aria-checked"), "false");
  click(checkbox);
  assert.equal(checkbox.getAttribute("aria-checked"), "true");

  assert.equal(component.state, "open");
  assert.deepEqual(pushed.filter(({ event }) => event === "checked").length, 2);
  assert.equal(
    pushed.some(({ event }) => event === "close"),
    false,
  );

  component.destroy();
});

test("a pointer open focuses the content and highlights no item", () => {
  const { component, content, profile, settings, trigger } = buildDropdown();

  click(trigger);
  assert.equal(document.activeElement, content);
  assert.equal(component.menu.rovingFocus.focusedItem, null);

  // Typeahead starts from no highlight.
  keydown(content, "s");
  assert.equal(document.activeElement, settings);

  click(trigger);
  click(trigger);
  assert.equal(document.activeElement, content, "reopening resets it");
  keydown(content, "ArrowDown");
  assert.equal(document.activeElement, profile);

  component.destroy();
});

for (const key of ["Enter", " ", "ArrowDown"]) {
  test(`opening with ${JSON.stringify(key)} on the trigger focuses the first item`, () => {
    const { component, profile, trigger } = buildDropdown();

    trigger.focus();
    const event = keydown(trigger, key);
    assert.equal(event.defaultPrevented, true);
    assert.equal(component.state, "open");
    assert.equal(document.activeElement, profile);

    component.destroy();
  });
}

test("the pointer leaving an item takes the highlight back to the content", () => {
  const { component, content, profile, settings, trigger } = buildDropdown();
  const pointer = (type, el) =>
    el.dispatchEvent(new window.MouseEvent(type, { clientX: 50, clientY: 50 }));

  click(trigger);
  pointer("mouseenter", profile);
  assert.equal(document.activeElement, profile);

  pointer("mouseleave", profile);
  assert.equal(document.activeElement, content);
  assert.equal(component.menu.rovingFocus.focusedItem, null);
  assert.equal(component.state, "open");

  // ArrowDown starts from the top again.
  keydown(content, "ArrowDown");
  assert.equal(document.activeElement, profile);

  // Resting on a disabled item un-highlights too.
  settings.setAttribute("data-disabled", "");
  component.menu.menuItems[1].disabled = true;
  pointer("mouseenter", settings);
  assert.equal(document.activeElement, content);

  component.destroy();
});

test("Tab inside the open content is swallowed", () => {
  const { component, profile, trigger } = buildDropdown({ usePortal: true });

  keydown(trigger, "Enter");
  assert.equal(document.activeElement, profile);
  const event = keydown(profile, "Tab");
  assert.equal(event.defaultPrevented, true);
  assert.equal(component.state, "open");
  assert.equal(document.activeElement, profile);

  component.destroy();
});

test("the content's data-side follows a flip", () => {
  const { component, content, positioner, trigger } = buildDropdown();
  window.innerHeight = 600;
  // 20px below the trigger: the 80px panel flips above it.
  setRect(trigger, {
    top: 550,
    bottom: 580,
    left: 10,
    right: 110,
    width: 100,
    height: 30,
  });

  click(trigger);
  assert.equal(positioner.getAttribute("data-placement"), "top");
  assert.equal(content.getAttribute("data-side"), "top");

  component.destroy();
});

test("a server open command focuses the content", () => {
  const { component, content } = buildDropdown();

  component.handleCommand("open");
  assert.equal(component.state, "open");
  assert.equal(document.activeElement, content);

  component.destroy();
});

test("the content is labelled by the trigger; generated ids are stripped before a patch", () => {
  const { component, content, trigger } = buildDropdown();

  assert.equal(trigger.id, "dropdown-1-trigger");
  assert.equal(content.getAttribute("role"), "menu");
  assert.equal(content.getAttribute("aria-labelledby"), trigger.id);
  assert.equal(trigger.getAttribute("aria-controls"), content.id);

  component.beforeUpdate();
  assert.equal(trigger.id, "");
  assert.equal(content.id, "");

  component.destroy();
});

test("a server-rendered trigger id is kept", () => {
  const { component, content, el, trigger } = buildDropdown();
  // Drop the generated id, as before a patch, then render one server-side.
  component.beforeUpdate();
  component.destroy();
  trigger.id = "my-trigger";

  const rebuilt = registry.create("dropdown-menu", el, {
    pushEventTo: () => {},
    liveSocket: { execJS: () => {} },
  });
  assert.equal(content.getAttribute("aria-labelledby"), "my-trigger");
  rebuilt.beforeUpdate();
  assert.equal(trigger.id, "my-trigger");

  rebuilt.destroy();
});

test("the content height is capped at the room beside the trigger", () => {
  const { component, content, trigger } = buildDropdown();
  window.innerHeight = 600;
  // 470px above the trigger, 100px below it.
  setRect(trigger, {
    top: 470,
    bottom: 500,
    left: 10,
    right: 110,
    width: 100,
    height: 30,
  });

  click(trigger);
  assert.equal(
    content.style.getPropertyValue("--dropdown-menu-content-available-height"),
    // The larger side, less the 4px side offset.
    "466px",
  );

  component.destroy();
});

test("with use-portal, an open menu survives a LiveView patch", () => {
  const { component, el, positioner, settings, trigger } = buildDropdown({
    usePortal: true,
  });
  const hook = hookFor(el, component);
  hook.pushEventTo = () => {};
  hook.liveSocket = { execJS: () => {} };

  keydown(trigger, "Enter");
  keydown(document.activeElement, "ArrowDown");
  assert.equal(document.activeElement, settings);
  assert.equal(el.contains(positioner), false, "portaled");

  hook.beforeUpdate();
  assert.equal(el.contains(positioner), true, "handed back for the patch");
  simulatePatch(el, { hidden: ['[data-part="positioner"]'] });
  hook.updated();

  const rebuilt = hook.component;
  assert.notEqual(rebuilt, component);
  assert.equal(rebuilt.state, "open");
  assert.equal(el.contains(positioner), false, "portaled again");
  assert.equal(document.body.contains(positioner), true);
  assert.equal(
    document.querySelectorAll('[data-part="positioner"]').length,
    1,
    "no stray copy",
  );
  assert.equal(positioner.hidden, false);
  assert.equal(document.activeElement, settings);

  keydown(settings, "Escape");
  assert.equal(rebuilt.state, "closed");
  assert.equal(el.contains(positioner), true);

  hook.destroyed();
});

test("with the exit animation, closing returns focus and fires close at once, then hides", async () => {
  const { component, positioner, pushed, trigger } = buildDropdown({
    animated: true,
  });
  trigger.focus();

  click(trigger);
  assert.equal(pushed.at(-1).event, "open");

  keydown(positioner.querySelector('[data-part="content"]'), "Escape");
  assert.equal(component.state, "closed");
  assert.equal(pushed.at(-1).event, "close");
  assert.equal(document.activeElement, trigger);
  // The panel stays up while it animates out.
  assert.equal(positioner.hidden, false);

  await waitFor(() => positioner.hidden === true);
  component.destroy();
});

test("a LiveView rebuild during the exit animation still returns focus and fires close", async () => {
  const { component, el, positioner, profile, pushed, trigger } = buildDropdown(
    { animated: true },
  );
  trigger.focus();

  // Keep hold of the exit animation so the test can let it drain.
  let exitAnimation = null;
  const machine = component.stateMachine;
  const onStateChanged = machine.options.onStateChanged;
  machine.options.onStateChanged = (...args) =>
    (exitAnimation = onStateChanged(...args));

  click(trigger);
  // Selecting an item pushes its on-select; the server's reply patches the
  // menu before the 130ms exit animation finishes.
  click(profile);
  assert.equal(component.state, "closed");
  component.beforeUpdate();
  component.destroy();
  positioner.hidden = true;

  const rebuilt = registry.create("dropdown-menu", el, {
    pushEventTo: () => {},
    liveSocket: { execJS: () => {} },
  });
  assert.equal(rebuilt.state, "closed");
  assert.equal(document.activeElement, trigger);
  assert.deepEqual(
    pushed.map(({ event }) => event).filter((event) => event !== "selected"),
    ["open", "close"],
  );

  rebuilt.destroy();
  await exitAnimation;
});
