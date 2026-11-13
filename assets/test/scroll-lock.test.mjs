import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import "../salad_ui/components/dialog.js";
import "../salad_ui/components/drawer.js";
import "../salad_ui/components/sidebar.js";
import { registry } from "../salad_ui/core/factory.js";
import {
  isScrollLocked,
  lockScroll,
  resetScrollLock,
  scrollLockCount,
} from "../salad_ui/core/scroll-lock.js";
import {
  hookFor,
  installDom,
  simulatePatch,
  uninstallDom,
  waitFor,
} from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

const mounted = [];

afterEach(() => {
  mounted.splice(0).forEach((component) => component.destroy());
  resetScrollLock();
  document.body.innerHTML = "";
  document.body.removeAttribute("style");
  document.documentElement.removeAttribute("style");
  delete document.documentElement.clientWidth;
  delete window.matchMedia;
});

const html = () => document.documentElement;
const body = () => document.body;

// jsdom does no layout: give the page a 15px scrollbar.
function withScrollbar(width = 15) {
  Object.defineProperty(html(), "clientWidth", {
    configurable: true,
    get: () => window.innerWidth - width,
  });
}

function dialogMarkup(id, { open = false, options = {} } = {}) {
  return `
    <div id="${id}" data-component="dialog" data-open="${open}"
         data-options='${JSON.stringify({ closeOnOutsideClick: true, ...options })}'
         data-event-mappings='{}' data-part="root">
      <button data-part="trigger" data-action="open" type="button">Open</button>
      <div data-part="content" hidden>
        <div data-part="overlay"></div>
        <div data-part="content-panel">
          <h2 data-part="title">Title</h2>
          <button id="${id}-close" data-part="close-trigger" data-action="close" type="button">Close</button>
        </div>
      </div>
    </div>`;
}

function mount(type, el) {
  const component = registry.create(type, el, { liveSocket: {} });
  mounted.push(component);
  return component;
}

function buildDialogs(...specs) {
  body().innerHTML = specs.map(([id, opts]) => dialogMarkup(id, opts)).join("");
  return specs.map(([id]) => {
    const el = document.getElementById(id);
    return { el, component: mount("dialog", el) };
  });
}

// What the hook does on a LiveView patch: keep or rebuild the instance.
function patch(el, component, mutate = () => {}) {
  const hook = hookFor(el, component);
  hook.beforeUpdate();
  simulatePatch(el, { hidden: ['[data-part="content"]'] });
  mutate(el);
  hook.updated();
  if (hook.component !== component) {
    mounted.splice(mounted.indexOf(component), 1, hook.component);
  }
  return hook.component;
}

// --- core ------------------------------------------------------------------

test("lock hides overflow and pads the scrollbar; release restores", () => {
  withScrollbar(15);

  const release = lockScroll();
  assert.equal(isScrollLocked(), true);
  assert.equal(html().style.overflow, "hidden");
  assert.equal(body().style.overflow, "hidden");
  assert.equal(body().style.getPropertyPriority("overflow"), "important");
  assert.equal(body().style.paddingRight, "15px");
  assert.equal(body().getAttribute("data-scroll-locked"), "1");

  release();
  assert.equal(isScrollLocked(), false);
  assert.equal(html().getAttribute("style"), null);
  assert.equal(body().getAttribute("style"), null);
  assert.equal(body().hasAttribute("data-scroll-locked"), false);
});

test("existing inline styles are kept and put back exactly", () => {
  withScrollbar(15);
  body().style.setProperty("overflow", "auto", "important");
  body().style.paddingRight = "10px";
  body().style.color = "red";
  html().style.overflow = "scroll";

  const release = lockScroll();
  assert.equal(body().style.overflow, "hidden");
  assert.equal(body().style.paddingRight, "25px");
  assert.equal(body().style.color, "red");

  release();
  assert.equal(body().style.overflow, "auto");
  assert.equal(body().style.getPropertyPriority("overflow"), "important");
  assert.equal(body().style.paddingRight, "10px");
  assert.equal(body().style.color, "red");
  assert.equal(html().style.overflow, "scroll");
});

test("no padding without a scrollbar or with scrollbar-gutter: stable", () => {
  let release = lockScroll();
  assert.equal(body().style.paddingRight, "");
  release();

  withScrollbar(15);
  html().style.setProperty("scrollbar-gutter", "stable");
  release = lockScroll();
  assert.equal(body().style.overflow, "hidden");
  assert.equal(body().style.paddingRight, "");
  release();
  assert.equal(html().style.getPropertyValue("scrollbar-gutter"), "stable");
});

test("locks are ref counted and a release is idempotent", () => {
  const first = lockScroll();
  const second = lockScroll();
  assert.equal(scrollLockCount(), 2);

  first();
  first();
  assert.equal(scrollLockCount(), 1);
  assert.equal(body().style.overflow, "hidden");

  second();
  assert.equal(scrollLockCount(), 0);
  assert.equal(body().style.overflow, "");
});

// --- dialog (also sheet and alert dialog) ------------------------------------

test("a dialog locks while open and unlocks on close", () => {
  const [{ el, component }] = buildDialogs(["d1"]);
  assert.equal(isScrollLocked(), false);

  el.querySelector('[data-part="trigger"]').click();
  assert.equal(component.state, "open");
  assert.equal(scrollLockCount(), 1);
  assert.equal(body().style.overflow, "hidden");

  el.querySelector('[data-part="close-trigger"]').click();
  assert.equal(component.state, "closed");
  assert.equal(isScrollLocked(), false);
  assert.equal(body().style.overflow, "");
});

test("a dialog rendered open locks on mount", () => {
  buildDialogs(["d1", { open: true }]);
  assert.equal(scrollLockCount(), 1);
});

test("two dialogs stack: the page unlocks only when both close", () => {
  const [outer, inner] = buildDialogs(["outer"], ["inner"]);

  outer.component.transition("open");
  inner.component.transition("open");
  assert.equal(scrollLockCount(), 2);

  inner.component.transition("close");
  assert.equal(scrollLockCount(), 1);
  assert.equal(body().style.overflow, "hidden");

  outer.component.transition("close");
  assert.equal(scrollLockCount(), 0);
  assert.equal(body().style.overflow, "");
});

test("closing out of order still unlocks once both are closed", () => {
  const [outer, inner] = buildDialogs(["outer"], ["inner"]);

  outer.component.transition("open");
  inner.component.transition("open");
  outer.component.transition("close");
  assert.equal(scrollLockCount(), 1);

  inner.component.transition("close");
  assert.equal(isScrollLocked(), false);
});

test("re-opening an open dialog does not stack a second lock", () => {
  const [{ component }] = buildDialogs(["d1"]);

  component.transition("open");
  component.activateOpenState();
  component.transition("open");
  assert.equal(scrollLockCount(), 1);
});

test("a patch that keeps the dialog open neither re-locks nor unlocks", () => {
  const [{ el, component }] = buildDialogs(["d1"]);
  component.transition("open");

  const kept = patch(el, component);
  assert.equal(kept, component);
  assert.equal(component.state, "open");
  assert.equal(scrollLockCount(), 1);

  patch(el, component);
  assert.equal(scrollLockCount(), 1);

  component.transition("close");
  assert.equal(isScrollLocked(), false);
});

test("a patch with a new server open state closes and unlocks", () => {
  const [{ el, component }] = buildDialogs(["d1", { open: true }]);
  assert.equal(scrollLockCount(), 1);

  patch(el, component, (node) => node.setAttribute("data-open", "false"));
  assert.equal(component.state, "closed");
  assert.equal(isScrollLocked(), false);
});

test("a rebuild that closes the dialog unlocks", () => {
  const [{ el, component }] = buildDialogs(["d1"]);
  component.transition("open");

  const rebuilt = patch(el, component, (node) =>
    node.setAttribute(
      "data-options",
      JSON.stringify({ closeOnOutsideClick: false }),
    ),
  );
  assert.notEqual(rebuilt, component);
  assert.equal(rebuilt.state, "closed");
  assert.equal(isScrollLocked(), false);
});

test("a rebuild that stays open holds exactly one lock", () => {
  const [{ el, component }] = buildDialogs(["d1", { open: true }]);

  const rebuilt = patch(el, component, (node) =>
    node.setAttribute(
      "data-options",
      JSON.stringify({ closeOnOutsideClick: false }),
    ),
  );
  assert.notEqual(rebuilt, component);
  assert.equal(rebuilt.state, "open");
  assert.equal(scrollLockCount(), 1);
});

test("destroying an open dialog releases its lock", () => {
  const [first, second] = buildDialogs(["d1"], ["d2"]);
  first.component.transition("open");
  second.component.transition("open");

  first.component.destroy();
  assert.equal(scrollLockCount(), 1);
  second.component.destroy();
  assert.equal(isScrollLocked(), false);
});

test("the lock holds through the exit animation", async () => {
  const animations = {
    open_to_closed: {
      animation: ["duration-[30ms]", "opacity-100", "opacity-0"],
      duration: 30,
      target_part: "content-panel",
    },
  };
  const [{ el, component }] = buildDialogs(["d1", { options: { animations } }]);
  component.transition("open");

  component.transition("close");
  assert.equal(scrollLockCount(), 1);

  await waitFor(() => el.querySelector('[data-part="content"]').hidden);
  assert.equal(isScrollLocked(), false);
});

test("re-opening during the exit animation keeps a single lock", async () => {
  const animations = {
    open_to_closed: {
      animation: ["duration-[30ms]", "opacity-100", "opacity-0"],
      duration: 30,
      target_part: "content-panel",
    },
  };
  const [{ el, component }] = buildDialogs(["d1", { options: { animations } }]);
  const panel = el.querySelector('[data-part="content-panel"]');
  component.transition("open");
  component.transition("close");
  component.transition("open");

  // The stale exit animation finishes (its classes are cleaned up) without
  // releasing the lock the re-opened dialog holds.
  await waitFor(
    () =>
      !["duration-[30ms]", "opacity-100", "opacity-0"].some((name) =>
        panel.classList.contains(name),
      ),
  );
  assert.equal(component.state, "open");
  assert.equal(scrollLockCount(), 1);
});

test("modal: false does not lock", () => {
  const [{ component }] = buildDialogs(["d1", { options: { modal: false } }]);
  component.transition("open");
  assert.equal(isScrollLocked(), false);
});

// --- drawer --------------------------------------------------------------

test("a drawer locks while open and releases on close and destroy", () => {
  body().innerHTML = `
    <div id="dr" data-component="drawer" data-open="false"
         data-options='{"closeOnOutsideClick":true}' data-event-mappings='{}' data-part="root">
      <div data-part="content" hidden>
        <div data-part="overlay"></div>
        <div data-part="content-panel"><div data-part="handle"></div><button type="button">Go</button></div>
      </div>
    </div>`;
  const component = mount("drawer", document.getElementById("dr"));

  component.transition("open");
  assert.equal(scrollLockCount(), 1);
  component.transition("close");
  assert.equal(isScrollLocked(), false);

  component.transition("open");
  component.destroy();
  assert.equal(isScrollLocked(), false);
});

// --- sidebar mobile sheet ------------------------------------------------------

function buildSidebar({ mobile = true, openMobile = false } = {}) {
  const listeners = new Set();
  const media = {
    matches: mobile,
    addEventListener: (_type, fn) => listeners.add(fn),
    removeEventListener: (_type, fn) => listeners.delete(fn),
    set(value) {
      this.matches = value;
      listeners.forEach((fn) => fn({ matches: value }));
    },
  };
  window.matchMedia = () => media;

  body().innerHTML = `
    <div id="provider" data-component="sidebar" data-state="expanded"
         data-open-mobile="${openMobile}"
         data-options='{"cookieName":null}' data-event-mappings='{}'>
      <div data-slot="sidebar" data-collapsible-mode="offcanvas" data-state="expanded">
        <div data-slot="sidebar-overlay" data-sidebar="overlay" data-action="close"></div>
        <div data-slot="sidebar-container"><a href="#home">Home</a></div>
      </div>
      <button type="button" data-sidebar="trigger" data-action="toggle">Toggle</button>
    </div>`;
  const el = document.getElementById("provider");
  return { el, media, component: mount("sidebar", el) };
}

test("the sidebar's mobile sheet locks while open", () => {
  const { component } = buildSidebar();

  component.transition("toggle");
  assert.equal(component.openMobile, true);
  assert.equal(scrollLockCount(), 1);

  component.transition("toggle");
  assert.equal(isScrollLocked(), false);
});

test("the desktop sidebar never locks", () => {
  const { component } = buildSidebar({ mobile: false });
  component.transition("toggle");
  component.transition("toggle");
  assert.equal(isScrollLocked(), false);
});

test("the mobile sheet unlocks when the layout leaves mobile", () => {
  const { media } = buildSidebar({ openMobile: true });
  assert.equal(scrollLockCount(), 1);

  media.set(false);
  assert.equal(isScrollLocked(), false);
});

test("a patch keeps the open mobile sheet's single lock", () => {
  const { el, component } = buildSidebar();
  component.transition("open");

  const hook = hookFor(el, component);
  hook.beforeUpdate();
  const container = el.querySelector('[data-slot="sidebar-container"]');
  container.replaceWith(container.cloneNode(true));
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(scrollLockCount(), 1);
});

test("destroying an open mobile sheet releases its lock", () => {
  const { component } = buildSidebar({ openMobile: true });
  assert.equal(scrollLockCount(), 1);

  component.destroy();
  assert.equal(isScrollLocked(), false);
});
