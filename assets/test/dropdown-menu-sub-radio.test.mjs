import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/dropdown_menu.js"; // self-registers "dropdown-menu"
import { installDom, setRect, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  document.body.innerHTML = "";
});

function subMarkup(id, label, inner) {
  return `
    <div data-part="sub">
      <div data-part="sub-trigger" data-value="${id}" data-state="closed" tabindex="0">${label}</div>
      <div data-part="sub-positioner" data-side="right" data-align="start"
           data-side-offset="0" data-align-offset="0" hidden>
        <div data-part="sub-content" data-state="closed" role="menu">${inner}</div>
      </div>
    </div>
  `;
}

function build({ dir = null } = {}) {
  const more = subMarkup(
    "more",
    "More options",
    `
      <div data-part="item" data-value="calendly" tabindex="0"
           data-event-mappings='{"select":"selected"}'>Calendly</div>
      <div data-part="item" data-value="slack" tabindex="0"
           data-event-mappings='{"select":"selected"}'>Slack</div>
    `,
  );
  const invite = subMarkup(
    "invite",
    "Invite users",
    `
      <div data-part="item" data-value="email" tabindex="0"
           data-event-mappings='{"select":"selected"}'>Email</div>
      <div data-part="item" data-value="message" tabindex="0"
           data-event-mappings='{"select":"selected"}'>Message</div>
      ${more}
    `,
  );

  document.body.innerHTML = `
    <div ${dir ? `dir="${dir}"` : ""}>
      <div id="dm" data-component="dropdown-menu" data-state="closed"
           data-options='{"usePortal":false}'
           data-event-mappings='{"open":"open","close":"close"}'
           data-part="root">
        <button type="button" data-part="trigger" tabindex="0">Open</button>
        <div data-part="positioner" data-side="bottom" data-align="start"
             data-side-offset="4" data-align-offset="0" hidden>
          <div data-part="content">
            <div data-part="item" data-value="team" tabindex="0">Team</div>
            ${invite}
            <div data-part="item" data-value="new-team" tabindex="0">New Team</div>
            <div data-part="radio-group" data-value="bottom"
                 data-event-mappings='{"value-changed":"position_changed"}' role="group">
              <div data-part="radio-item" data-value="top" tabindex="0"
                   data-event-mappings='{"select":"selected"}'>
                <span data-part="item-indicator" hidden>•</span>Top
              </div>
              <div data-part="radio-item" data-value="bottom" tabindex="0">
                <span data-part="item-indicator" hidden>•</span>Bottom
              </div>
              <div data-part="radio-item" data-value="right" data-disabled tabindex="-1">
                <span data-part="item-indicator" hidden>•</span>Right
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;

  const el = document.getElementById("dm");
  const q = (selector) => el.querySelector(selector);
  const pushed = [];

  setRect(q('[data-part="trigger"]'), {
    top: 10,
    left: 10,
    bottom: 30,
    right: 110,
    width: 100,
    height: 20,
  });

  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };
  const component = registry.create("dropdown-menu", el, hookContext);

  const subTriggers = el.querySelectorAll('[data-part="sub-trigger"]');
  const subContents = el.querySelectorAll('[data-part="sub-content"]');
  const subPositioners = el.querySelectorAll('[data-part="sub-positioner"]');

  return {
    component,
    el,
    pushed,
    trigger: q('[data-part="trigger"]'),
    positioner: q('[data-part="positioner"]'),
    team: q('[data-value="team"]'),
    newTeam: q('[data-value="new-team"]'),
    invite: subTriggers[0],
    inviteContent: subContents[0],
    invitePositioner: subPositioners[0],
    email: q('[data-value="email"]'),
    message: q('[data-value="message"]'),
    more: subTriggers[1],
    moreContent: subContents[1],
    calendly: q('[data-value="calendly"]'),
    slack: q('[data-value="slack"]'),
    group: q('[data-part="radio-group"]'),
    top: q('[data-part="radio-item"][data-value="top"]'),
    bottom: q('[data-part="radio-item"][data-value="bottom"]'),
    right: q('[data-part="radio-item"][data-value="right"]'),
  };
}

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
}

function hover(el) {
  el.dispatchEvent(new window.MouseEvent("mouseenter"));
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

test("sub-trigger exposes WAI-ARIA submenu attributes", () => {
  const { component, invite, inviteContent } = build();

  assert.equal(invite.getAttribute("role"), "menuitem");
  assert.equal(invite.getAttribute("aria-haspopup"), "menu");
  assert.equal(invite.getAttribute("aria-expanded"), "false");
  assert.ok(inviteContent.id);
  assert.equal(invite.getAttribute("aria-controls"), inviteContent.id);
  assert.equal(inviteContent.getAttribute("role"), "menu");

  component.destroy();
});

test("opening the root menu does not stamp its state onto sub-menu parts", () => {
  const { component, invite, inviteContent, trigger } = build();

  click(trigger);
  assert.equal(component.state, "open");
  assert.equal(invite.getAttribute("data-state"), "closed");
  assert.equal(inviteContent.getAttribute("data-state"), "closed");

  component.destroy();
});

test("ArrowRight opens the sub-menu and focuses its first item; ArrowLeft closes it", () => {
  const {
    component,
    email,
    invite,
    inviteContent,
    invitePositioner,
    team,
    trigger,
  } = build();

  click(trigger);
  assert.equal(document.activeElement, team);

  keydown(team, "ArrowDown");
  assert.equal(document.activeElement, invite);

  const open = keydown(invite, "ArrowRight");
  assert.equal(open.defaultPrevented, true);
  assert.equal(invitePositioner.hidden, false);
  assert.equal(invite.getAttribute("data-state"), "open");
  assert.equal(invite.getAttribute("aria-expanded"), "true");
  assert.equal(inviteContent.getAttribute("data-state"), "open");
  assert.equal(document.activeElement, email);

  const close = keydown(email, "ArrowLeft");
  assert.equal(close.defaultPrevented, true);
  assert.equal(invitePositioner.hidden, true);
  assert.equal(invite.getAttribute("aria-expanded"), "false");
  assert.equal(inviteContent.getAttribute("data-state"), "closed");
  assert.equal(document.activeElement, invite);
  assert.equal(component.state, "open");

  component.destroy();
});

test("Enter and Space on a sub-trigger open it without selecting or closing the root", () => {
  const { component, email, invite, pushed, trigger } = build();

  click(trigger);
  invite.focus();
  keydown(invite, "Enter");
  assert.equal(document.activeElement, email);
  assert.equal(component.state, "open");
  assert.equal(
    pushed.some(({ event }) => event === "selected"),
    false,
  );

  keydown(email, "ArrowLeft");
  keydown(invite, " ");
  assert.equal(document.activeElement, email);

  component.destroy();
});

test("arrow navigation inside a sub-menu stays in the sub-menu", () => {
  const { component, email, invite, message, more, trigger } = build();

  click(trigger);
  invite.focus();
  keydown(invite, "ArrowRight");

  keydown(email, "ArrowDown");
  assert.equal(document.activeElement, message);
  keydown(message, "ArrowDown");
  assert.equal(document.activeElement, more);
  keydown(more, "ArrowDown");
  assert.equal(document.activeElement, email, "wraps within the sub-menu");
  keydown(email, "End");
  assert.equal(document.activeElement, more);

  component.destroy();
});

test("nested sub-menus: ArrowLeft closes only the innermost", () => {
  const { calendly, component, email, invite, more, moreContent, trigger } =
    build();

  click(trigger);
  invite.focus();
  keydown(invite, "ArrowRight");
  keydown(email, "End");
  keydown(more, "ArrowRight");
  assert.equal(document.activeElement, calendly);
  assert.equal(moreContent.getAttribute("data-state"), "open");

  keydown(calendly, "ArrowLeft");
  assert.equal(moreContent.getAttribute("data-state"), "closed");
  assert.equal(document.activeElement, more);
  assert.equal(invite.getAttribute("data-state"), "open");

  component.destroy();
});

test("hovering a sub-trigger opens it; hovering a sibling item closes it", () => {
  const { component, invite, invitePositioner, newTeam, trigger } = build();

  click(trigger);
  hover(invite);
  assert.equal(invite.getAttribute("data-state"), "open");
  assert.equal(invitePositioner.hidden, false);
  assert.equal(document.activeElement, invite, "hover keeps focus on trigger");

  hover(newTeam);
  assert.equal(invite.getAttribute("data-state"), "closed");
  assert.equal(invitePositioner.hidden, true);
  assert.equal(document.activeElement, newTeam);

  component.destroy();
});

test("hovering back onto the sub-trigger from its sub-menu refocuses the trigger", () => {
  const { component, invite, message, trigger } = build();

  click(trigger);
  hover(invite);
  hover(message);
  assert.equal(document.activeElement, message);

  hover(invite);
  assert.equal(document.activeElement, invite);
  assert.equal(invite.getAttribute("data-state"), "open");

  component.destroy();
});

test("selecting a sub-menu item pushes select and closes every menu", async () => {
  const {
    component,
    invite,
    inviteContent,
    message,
    positioner,
    pushed,
    trigger,
  } = build();

  click(trigger);
  hover(invite);
  click(message);

  assert.equal(component.state, "closed");
  assert.equal(inviteContent.getAttribute("data-state"), "closed");
  assert.equal(invite.getAttribute("data-state"), "closed");
  const selected = pushed.find(({ event }) => event === "selected");
  assert.equal(selected.payload.value, "message");
  assert.equal(selected.payload.componentId, "dm");

  await waitFor(() => positioner.hidden === true);
  component.destroy();
});

test("Escape inside a sub-menu closes the whole menu and focuses the trigger", async () => {
  const { component, email, invite, inviteContent, trigger } = build();

  click(trigger);
  invite.focus();
  keydown(invite, "ArrowRight");
  keydown(email, "Escape");

  assert.equal(component.state, "closed");
  assert.equal(inviteContent.getAttribute("data-state"), "closed");
  await waitFor(() => document.activeElement === trigger);

  component.destroy();
});

test("under dir=rtl the horizontal keys are mirrored and the sub-menu opens left", () => {
  const { component, email, invite, inviteContent, trigger } = build({
    dir: "rtl",
  });

  click(trigger);
  invite.focus();
  keydown(invite, "ArrowRight");
  assert.equal(invite.getAttribute("data-state"), "closed");

  keydown(invite, "ArrowLeft");
  assert.equal(invite.getAttribute("data-state"), "open");
  assert.equal(document.activeElement, email);
  assert.equal(inviteContent.getAttribute("data-side"), "left");

  keydown(email, "ArrowRight");
  assert.equal(invite.getAttribute("data-state"), "closed");
  assert.equal(document.activeElement, invite);

  component.destroy();
});

test("radio items derive checked state from the group value", () => {
  const { bottom, component, right, top } = build();

  assert.equal(top.getAttribute("role"), "menuitemradio");
  assert.equal(top.getAttribute("aria-checked"), "false");
  assert.equal(bottom.getAttribute("aria-checked"), "true");
  assert.equal(bottom.getAttribute("data-state"), "checked");
  assert.equal(
    bottom.querySelector('[data-part="item-indicator"]').hidden,
    false,
  );
  assert.equal(top.querySelector('[data-part="item-indicator"]').hidden, true);
  assert.equal(right.getAttribute("aria-disabled"), "true");

  component.destroy();
});

test("picking a radio item moves the check, fires value-changed and keeps the menu open", () => {
  const { bottom, component, group, pushed, top, trigger } = build();

  click(trigger);
  click(top);

  assert.equal(top.getAttribute("aria-checked"), "true");
  assert.equal(top.getAttribute("data-state"), "checked");
  assert.equal(bottom.getAttribute("aria-checked"), "false");
  assert.equal(
    bottom.querySelector('[data-part="item-indicator"]').hidden,
    true,
  );
  assert.equal(group.getAttribute("data-value"), "top");
  assert.equal(component.state, "open");

  assert.deepEqual(
    pushed.slice(-2).map(({ event }) => event),
    ["selected", "position_changed"],
  );
  assert.deepEqual(pushed.at(-1).payload, {
    value: "top",
    componentId: "dm",
    component: "dropdown-menu",
  });

  component.destroy();
});

test("re-picking the checked radio item or a disabled one does not fire value-changed", () => {
  const { bottom, component, pushed, right, trigger } = build();

  click(trigger);
  bottom.focus();
  keydown(bottom, "Enter");
  click(right);

  assert.equal(
    pushed.some(({ event }) => event === "position_changed"),
    false,
  );
  assert.equal(bottom.getAttribute("aria-checked"), "true");
  assert.equal(right.getAttribute("aria-checked"), "false");

  component.destroy();
});

test("reopening the root menu focuses the first item again", async () => {
  const { component, newTeam, positioner, team, trigger } = build();

  click(trigger);
  hover(newTeam);
  assert.equal(document.activeElement, newTeam);

  click(trigger);
  await waitFor(() => positioner.hidden === true);

  click(trigger);
  assert.equal(document.activeElement, team);

  component.destroy();
});

test("an open sub-menu re-positions when its parent panel's enter animation ends", () => {
  const { component, el, invite, inviteContent, team, trigger } = build();
  const content = el.querySelector('[data-part="content"]');

  click(trigger);
  hover(invite);

  const subTrigger = component.menu.menuItems.find(
    (item) => item.el === invite,
  );
  let updates = 0;
  const original = subTrigger.positionedElement.update.bind(
    subTrigger.positionedElement,
  );
  subTrigger.positionedElement.update = () => {
    updates += 1;
    return original();
  };

  // A bubbling animationend from the sub-menu itself is ignored.
  inviteContent.dispatchEvent(
    new window.Event("animationend", { bubbles: true }),
  );
  assert.equal(updates, 0);

  content.dispatchEvent(new window.Event("animationend", { bubbles: true }));
  assert.equal(updates, 1);

  // Once closed, the listener is gone.
  hover(team);
  content.dispatchEvent(new window.Event("animationend", { bubbles: true }));
  assert.equal(updates, 1);

  component.destroy();
});
