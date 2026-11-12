import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import "../salad_ui/components/navigation_menu.js";
import { registry } from "../salad_ui/core/factory.js";
import {
  installDom,
  setRect,
  uninstallDom,
  wait,
  waitFor,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  document.body.innerHTML = "";
});

function buildMenu({
  viewport = true,
  delayDuration = 20,
  skipDelayDuration = 0,
  closeDelay = 5,
  animationDuration = 5,
} = {}) {
  const options = JSON.stringify({
    delayDuration,
    skipDelayDuration,
    closeDelay,
    animationDuration,
    viewport,
  });

  document.body.innerHTML = `
    <button id="before">before</button>
    <nav id="nav" data-component="navigation-menu" data-part="root"
         data-state="closed" data-viewport="${viewport}"
         data-options='${options}'
         data-event-mappings='{"value-changed":"nav_changed"}'>
      <ul data-part="list">
        <li data-part="item" data-value="home">
          <button type="button" data-part="trigger" data-state="closed">Home</button>
          <div data-part="content" data-state="closed" hidden>
            <a data-part="link" href="/a">A</a>
            <a data-part="link" href="/b">B</a>
          </div>
        </li>
        <li data-part="item">
          <button type="button" data-part="trigger" data-state="closed">Components</button>
          <div data-part="content" data-state="closed" hidden>
            <a data-part="link" href="/c">C</a>
          </div>
        </li>
        <li data-part="item" data-value="docs">
          <a data-part="link" href="/docs">Docs</a>
        </li>
      </ul>
      <div data-part="indicator" data-state="hidden" hidden></div>
      ${
        viewport
          ? `<div data-part="viewport-position"><div data-part="viewport" data-state="closed" hidden></div></div>`
          : ""
      }
    </nav>
    <button id="after">after</button>
  `;

  const el = document.getElementById("nav");
  const q = (selector) => el.querySelector(selector);
  const items = el.querySelectorAll("[data-part='item']");
  const triggers = el.querySelectorAll("[data-part='trigger']");
  const contents = el.querySelectorAll("[data-part='content']");

  const parts = {
    el,
    homeItem: items[0],
    componentsItem: items[1],
    homeTrigger: triggers[0],
    componentsTrigger: triggers[1],
    homeContent: contents[0],
    componentsContent: contents[1],
    docsLink: q("a[href='/docs']"),
    viewport: q("[data-part='viewport']"),
    indicator: q("[data-part='indicator']"),
  };

  setRect(el, { left: 10, width: 400, height: 36 });
  setRect(parts.homeTrigger, { left: 10, width: 80, height: 36 });
  setRect(parts.componentsTrigger, { left: 100, width: 120, height: 36 });
  setRect(parts.homeContent, { width: 400, height: 150 });
  setRect(parts.componentsContent, { width: 600, height: 300 });

  const pushed = [];
  const hookContext = {
    pushEventTo: (_target, event, payload) => pushed.push({ event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const component = registry.create("navigation-menu", el, hookContext);
  return { ...parts, pushed, component };
}

function pointer(type, target, pointerType = "mouse") {
  const event = new window.Event(type, { bubbles: false });
  event.pointerType = pointerType;
  target.dispatchEvent(event);
}

function key(target, keyName, init = {}) {
  const event = new window.KeyboardEvent("keydown", {
    key: keyName,
    bubbles: true,
    cancelable: true,
    ...init,
  });
  target.dispatchEvent(event);
  return event;
}

test("assigns ids and ARIA wiring between triggers and contents", () => {
  const { homeTrigger, homeContent, componentsTrigger, component } =
    buildMenu();

  assert.equal(homeTrigger.id, "nav-trigger-home");
  assert.equal(homeContent.id, "nav-content-home");
  assert.equal(homeTrigger.getAttribute("aria-controls"), "nav-content-home");
  assert.equal(homeContent.getAttribute("aria-labelledby"), "nav-trigger-home");
  assert.equal(homeTrigger.getAttribute("aria-expanded"), "false");
  // Items without a value fall back to their index.
  assert.equal(componentsTrigger.id, "nav-trigger-item-1");
  assert.equal(component.state, "closed");

  component.destroy();
});

test("click toggles an item, moves content into the viewport and sizes it", async () => {
  const { el, homeTrigger, homeContent, homeItem, viewport, pushed } =
    buildMenu();

  homeTrigger.click();

  assert.equal(el.dataset.state, "open");
  assert.equal(homeTrigger.dataset.state, "open");
  assert.equal(homeTrigger.getAttribute("aria-expanded"), "true");
  assert.equal(homeContent.hidden, false);
  assert.equal(homeContent.dataset.state, "open");
  assert.equal(homeContent.parentElement, viewport);
  assert.equal(viewport.hidden, false);
  assert.equal(viewport.dataset.state, "open");
  assert.equal(
    viewport.style.getPropertyValue("--navigation-menu-viewport-width"),
    "400px",
  );
  assert.equal(
    viewport.style.getPropertyValue("--navigation-menu-viewport-height"),
    "150px",
  );
  assert.deepEqual(pushed.at(-1), {
    event: "nav_changed",
    payload: {
      value: "home",
      componentId: "nav",
      component: "navigation-menu",
    },
  });

  homeTrigger.click();

  assert.equal(el.dataset.state, "closed");
  assert.equal(homeTrigger.getAttribute("aria-expanded"), "false");
  assert.equal(viewport.dataset.state, "closed");
  assert.equal(homeContent.dataset.state, "closed");

  await waitFor(() => homeContent.hidden && viewport.hidden);
  assert.equal(homeContent.parentElement, homeItem);
  assert.equal(
    viewport.style.getPropertyValue("--navigation-menu-viewport-width"),
    "",
  );
  assert.equal(pushed.at(-1).payload.value, "");
});

test("switching items sets motion direction and resizes the viewport", async () => {
  const {
    homeTrigger,
    componentsTrigger,
    homeContent,
    componentsContent,
    homeItem,
    viewport,
    component,
  } = buildMenu();

  homeTrigger.click();
  componentsTrigger.click();

  assert.equal(component.value, "item-1");
  assert.equal(homeContent.dataset.motion, "to-start");
  assert.equal(componentsContent.dataset.motion, "from-end");
  assert.equal(
    viewport.style.getPropertyValue("--navigation-menu-viewport-width"),
    "600px",
  );

  await waitFor(() => homeContent.hidden);
  assert.equal(homeContent.parentElement, homeItem);
  assert.equal(homeContent.hasAttribute("data-motion"), false);

  homeTrigger.click();
  assert.equal(homeContent.dataset.motion, "from-start");
  assert.equal(componentsContent.dataset.motion, "to-end");
  assert.equal(viewport.hidden, false);
});

test("hover opens after the delay; moving between triggers is instant", async () => {
  const { homeTrigger, componentsTrigger, viewport, component } = buildMenu({
    delayDuration: 30,
    closeDelay: 30,
  });

  pointer("pointerenter", homeTrigger);
  assert.equal(component.value, "");
  await waitFor(() => component.value === "home");

  // Leaving the trigger for the viewport keeps it open.
  pointer("pointerleave", homeTrigger);
  pointer("pointerenter", viewport);
  await wait(60);
  assert.equal(component.value, "home");

  // Back over another trigger: switches without waiting for the delay.
  pointer("pointerleave", viewport);
  pointer("pointerenter", componentsTrigger);
  assert.equal(component.value, "item-1");

  pointer("pointerleave", componentsTrigger);
  await waitFor(() => component.value === "");
});

test("touch pointers do not open on hover", async () => {
  const { homeTrigger, component } = buildMenu({ delayDuration: 0 });

  pointer("pointerenter", homeTrigger, "touch");
  await wait(10);
  assert.equal(component.value, "");
});

test("a click-close is not undone by the still-hovering pointer", async () => {
  const { homeTrigger, component } = buildMenu({ delayDuration: 0 });

  pointer("pointerenter", homeTrigger);
  assert.equal(component.value, "home");
  homeTrigger.click();
  assert.equal(component.value, "");

  pointer("pointerenter", homeTrigger);
  assert.equal(component.value, "");

  pointer("pointerleave", homeTrigger);
  pointer("pointerenter", homeTrigger);
  assert.equal(component.value, "home");
});

test("skip delay: re-hovering right after closing opens instantly", () => {
  const { homeTrigger, componentsTrigger, component } = buildMenu({
    delayDuration: 1000,
    skipDelayDuration: 1000,
  });

  homeTrigger.click();
  homeTrigger.click();
  assert.equal(component.value, "");

  pointer("pointerenter", componentsTrigger);
  assert.equal(component.value, "item-1");
});

test("arrow keys move focus between top-level triggers and links", () => {
  const { homeTrigger, componentsTrigger, docsLink } = buildMenu();

  homeTrigger.focus();
  assert.equal(key(homeTrigger, "ArrowRight").defaultPrevented, true);
  assert.equal(document.activeElement, componentsTrigger);

  key(componentsTrigger, "ArrowRight");
  assert.equal(document.activeElement, docsLink);

  key(docsLink, "Home");
  assert.equal(document.activeElement, homeTrigger);

  key(homeTrigger, "End");
  assert.equal(document.activeElement, docsLink);

  key(docsLink, "ArrowLeft");
  assert.equal(document.activeElement, componentsTrigger);
});

test("ArrowDown/Tab enter an open panel; arrows move between its links", () => {
  const { homeTrigger, homeContent } = buildMenu();
  const [linkA, linkB] = homeContent.querySelectorAll("a");

  homeTrigger.focus();
  // Closed: ArrowDown does nothing.
  key(homeTrigger, "ArrowDown");
  assert.equal(document.activeElement, homeTrigger);

  homeTrigger.click();
  key(homeTrigger, "ArrowDown");
  assert.equal(document.activeElement, linkA);

  key(linkA, "ArrowDown");
  assert.equal(document.activeElement, linkB);
  key(linkB, "ArrowUp");
  assert.equal(document.activeElement, linkA);

  // Shift+Tab from the first link returns to the trigger.
  assert.equal(key(linkA, "Tab", { shiftKey: true }).defaultPrevented, true);
  assert.equal(document.activeElement, homeTrigger);

  assert.equal(key(homeTrigger, "Tab").defaultPrevented, true);
  assert.equal(document.activeElement, linkA);
});

test("Tab out of the last link closes and focuses the next top-level item", () => {
  const { homeTrigger, homeContent, componentsTrigger, component } =
    buildMenu();
  const linkB = homeContent.querySelectorAll("a")[1];

  homeTrigger.click();
  linkB.focus();
  assert.equal(key(linkB, "Tab").defaultPrevented, true);
  assert.equal(component.value, "");
  assert.equal(document.activeElement, componentsTrigger);
});

test("Escape closes and returns focus to the trigger", () => {
  const { homeTrigger, homeContent, component } = buildMenu();
  const linkA = homeContent.querySelector("a");

  homeTrigger.click();
  linkA.focus();
  key(linkA, "Escape");

  assert.equal(component.value, "");
  assert.equal(document.activeElement, homeTrigger);
});

test("clicking a link, clicking outside or focusing outside closes", () => {
  const { homeTrigger, homeContent, component } = buildMenu();

  homeTrigger.click();
  homeContent.querySelector("a").click();
  assert.equal(component.value, "");

  homeTrigger.click();
  document.getElementById("after").click();
  assert.equal(component.value, "");

  homeTrigger.click();
  homeTrigger.dispatchEvent(
    new window.FocusEvent("focusout", {
      bubbles: true,
      relatedTarget: document.getElementById("before"),
    }),
  );
  assert.equal(component.value, "");
});

test("indicator follows the open trigger", async () => {
  const { homeTrigger, componentsTrigger, indicator } = buildMenu();

  componentsTrigger.click();
  assert.equal(indicator.hidden, false);
  assert.equal(indicator.dataset.state, "visible");
  assert.equal(indicator.style.width, "120px");
  assert.equal(indicator.style.transform, "translateX(90px)");

  homeTrigger.click();
  assert.equal(indicator.style.transform, "translateX(0px)");

  homeTrigger.click();
  assert.equal(indicator.dataset.state, "hidden");
  await waitFor(() => indicator.hidden);
});

test("without a viewport, content opens in place", async () => {
  const { homeTrigger, homeContent, homeItem, component } = buildMenu({
    viewport: false,
  });

  assert.equal(component.useViewport, false);
  homeTrigger.click();
  assert.equal(homeContent.parentElement, homeItem);
  assert.equal(homeContent.hidden, false);
  assert.equal(homeContent.dataset.state, "open");

  homeTrigger.click();
  assert.equal(homeContent.dataset.state, "closed");
  await waitFor(() => homeContent.hidden);
});

test("server commands open and close items", () => {
  const { component } = buildMenu();

  component.handleCommand("open", { value: "item-1" });
  assert.equal(component.value, "item-1");

  component.handleCommand("open", {});
  assert.equal(component.value, "home");

  // Link-only items cannot be opened.
  component.handleCommand("open", { value: "docs" });
  assert.equal(component.value, "");

  component.handleCommand("open", { value: "home" });
  component.handleCommand("close");
  assert.equal(component.value, "");
});

test("beforeUpdate and destroy move content back into its item", () => {
  const { homeTrigger, homeContent, homeItem, viewport, component } =
    buildMenu();

  homeTrigger.click();
  assert.equal(homeContent.parentElement, viewport);

  component.beforeUpdate();
  assert.equal(homeContent.parentElement, homeItem);
  assert.equal(homeItem.lastElementChild, homeContent);

  homeTrigger.click();
  homeTrigger.click();
  component.destroy();
  assert.equal(homeContent.parentElement, homeItem);
});

// Mimics a LiveView patch of unchanged markup: morphdom puts back the
// server-rendered attributes and drops everything the component added.
function patchFromServer(el) {
  el.setAttribute("data-state", "closed");
  el.querySelectorAll("[data-part='trigger']").forEach((trigger) => {
    trigger.setAttribute("data-state", "closed");
    trigger.setAttribute("aria-expanded", "false");
    trigger.removeAttribute("id");
    trigger.removeAttribute("aria-controls");
  });
  el.querySelectorAll("[data-part='content']").forEach((content) => {
    content.setAttribute("data-state", "closed");
    content.hidden = true;
    content.removeAttribute("id");
    content.removeAttribute("aria-labelledby");
    content.removeAttribute("data-motion");
  });
  const viewport = el.querySelector("[data-part='viewport']");
  if (viewport) {
    viewport.setAttribute("data-state", "closed");
    viewport.hidden = true;
    viewport.removeAttribute("style");
  }
  const indicator = el.querySelector("[data-part='indicator']");
  indicator.setAttribute("data-state", "hidden");
  indicator.hidden = true;
  indicator.removeAttribute("style");
}

test("an open panel and its focus survive a LiveView patch", () => {
  const {
    el,
    homeTrigger,
    homeContent,
    viewport,
    indicator,
    pushed,
    component,
  } = buildMenu();
  const linkA = homeContent.querySelector("a");

  homeTrigger.click();
  linkA.focus();
  const pushedBefore = pushed.length;

  component.beforeUpdate();
  // Moving the panel home blurs the link in a browser; jsdom keeps it, so
  // move focus away by hand.
  homeTrigger.focus();
  patchFromServer(el);
  assert.equal(component.skipReinitialize(el), true);

  assert.equal(component.value, "home");
  assert.equal(el.dataset.state, "open");
  assert.equal(homeTrigger.getAttribute("aria-expanded"), "true");
  assert.equal(homeTrigger.getAttribute("aria-controls"), "nav-content-home");
  assert.equal(homeContent.parentElement, viewport);
  assert.equal(homeContent.hidden, false);
  assert.equal(homeContent.dataset.state, "open");
  assert.equal(viewport.hidden, false);
  assert.equal(
    viewport.style.getPropertyValue("--navigation-menu-viewport-height"),
    "150px",
  );
  assert.equal(indicator.dataset.state, "visible");
  assert.equal(document.activeElement, linkA);
  assert.equal(pushed.length, pushedBefore);

  // Listeners still work after the resync.
  homeTrigger.click();
  assert.equal(component.value, "");
  assert.equal(el.dataset.state, "closed");
});

test("a patch that removes the open item closes the menu", () => {
  const { el, homeTrigger, homeItem, pushed, component } = buildMenu();

  homeTrigger.click();
  component.beforeUpdate();
  homeItem.remove();
  patchFromServer(el);
  assert.equal(component.skipReinitialize(el), true);

  assert.equal(component.value, "");
  assert.equal(el.dataset.state, "closed");
  assert.equal(pushed.at(-1).payload.value, "");
});

test("a patch with new options rebuilds the component", () => {
  const { el, component } = buildMenu();

  el.setAttribute("data-options", JSON.stringify({ delayDuration: 1 }));
  assert.equal(component.skipReinitialize(el), false);
});

test("Escape anywhere closes a hover-opened panel", () => {
  const { homeTrigger, component } = buildMenu({ delayDuration: 0 });

  pointer("pointerenter", homeTrigger);
  assert.equal(component.value, "home");

  key(document.getElementById("after"), "Escape");
  assert.equal(component.value, "");
});

test("arrow keys inside a panel follow the reading direction", () => {
  const { el, homeTrigger, homeContent } = buildMenu();
  const [linkA, linkB] = homeContent.querySelectorAll("a");
  el.setAttribute("dir", "rtl");

  homeTrigger.click();
  linkA.focus();
  key(linkA, "ArrowLeft");
  assert.equal(document.activeElement, linkB);
  key(linkB, "ArrowRight");
  assert.equal(document.activeElement, linkA);
});

test("Shift+Tab from the next item enters the open viewport panel at its end", () => {
  const { homeTrigger, componentsTrigger, homeContent } = buildMenu();
  const linkB = homeContent.querySelectorAll("a")[1];

  homeTrigger.click();
  componentsTrigger.focus();
  assert.equal(
    key(componentsTrigger, "Tab", { shiftKey: true }).defaultPrevented,
    true,
  );
  assert.equal(document.activeElement, linkB);
});
