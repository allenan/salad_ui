import assert from "node:assert/strict";
import { after, afterEach, before, beforeEach, test } from "node:test";

import "../salad_ui/components/sidebar.js";
import { SaladUIHook } from "../salad_ui/core/hook.js";
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

let media;
let cookieWrites;

// jsdom has no matchMedia: a controllable stand-in for the 768px query.
function installMatchMedia(matches) {
  const listeners = new Set();
  media = {
    matches,
    media: "(max-width: 767px)",
    addEventListener: (_type, fn) => listeners.add(fn),
    removeEventListener: (_type, fn) => listeners.delete(fn),
    set(value) {
      this.matches = value;
      listeners.forEach((fn) => fn({ matches: value }));
    },
    listeners,
  };
  window.matchMedia = () => media;
}

beforeEach(() => {
  installMatchMedia(false);
  cookieWrites = [];
  Object.defineProperty(document, "cookie", {
    configurable: true,
    get: () => cookieWrites.at(-1) || "",
    set: (value) => {
      cookieWrites.push(value);
    },
  });
});

const mounted = [];

afterEach(() => {
  mounted.splice(0).forEach((hook) => hook.destroyed());
  document.body.innerHTML = "";
  delete window.matchMedia;
});

function sidebarMarkup({
  id = "sb",
  collapsible = "icon",
  variant = "floating",
  state = "expanded",
  isMobile,
} = {}) {
  return `
    <div id="${id}" data-slot="sidebar" class="group peer"
         data-state="${state}"
         data-collapsible="${state === "collapsed" ? collapsible : ""}"
         data-variant="${variant}" data-side="left"
         ${isMobile === undefined ? "" : `data-is-mobile="${isMobile}"`}
         data-collapsible-mode="${collapsible}" data-sidebar-variant="${variant}">
      <div data-slot="sidebar-overlay" data-sidebar="overlay" data-action="close"></div>
      <div data-slot="sidebar-gap"></div>
      <div data-slot="sidebar-container" data-side="left">
        <div data-slot="sidebar-inner" data-sidebar="sidebar">
          <ul>
            <li data-sidebar="menu-item">
              <a href="#home" id="home-link" data-sidebar="menu-button"><span>Home</span></a>
              <div data-sidebar="menu-tooltip" role="tooltip" data-state="closed"
                   data-side="right" data-side-offset="8" hidden>Home tip</div>
            </li>
            <li data-sidebar="menu-item" data-component="collapsible">
              <button type="button" id="collapsible-button" data-sidebar="menu-button"
                      data-part="trigger" data-action="toggle">Projects</button>
            </li>
          </ul>
          <button type="button" data-sidebar="rail" data-action="toggle">Rail</button>
        </div>
      </div>
    </div>`;
}

function buildSidebar({
  state = "expanded",
  open,
  options = {},
  mappings = { "open-change": "open_changed" },
  sidebar = {},
} = {}) {
  document.body.innerHTML = `
    <button id="outside" type="button">Outside</button>
    <div id="provider" data-slot="sidebar-wrapper" data-component="sidebar"
         data-state="${state}"
         ${open === undefined ? "" : `data-open="${open}"`}
         data-options='${JSON.stringify({ keyboardShortcut: true, cookieName: "sidebar_state", ...options })}'
         data-event-mappings='${JSON.stringify(mappings)}'>
      ${sidebarMarkup({ state, ...sidebar })}
      <main data-slot="sidebar-inset">
        <button type="button" id="trigger" data-sidebar="trigger" data-action="toggle">Toggle</button>
        <button type="button" id="app-action" data-action="close">App action</button>
        <div data-component="tooltip">
          <button type="button" id="nested-trigger" data-sidebar="trigger" data-action="toggle">Toggle</button>
        </div>
      </main>
    </div>`;

  const el = document.getElementById("provider");
  return {
    el,
    sidebar: () => el.querySelector('[data-slot="sidebar"]'),
    container: () => el.querySelector('[data-slot="sidebar-container"]'),
    overlay: () => el.querySelector('[data-slot="sidebar-overlay"]'),
    trigger: () => document.getElementById("trigger"),
  };
}

function mountHook(el, { ignored } = {}) {
  const pushed = [];
  const hook = {
    ...SaladUIHook,
    el,
    pushEventTo: (_target, event, payload) => pushed.push({ event, payload }),
    handleEvent() {},
    liveSocket: { execJS() {} },
  };
  if (ignored) {
    hook.js = () => ({
      ignoreAttributes: (target, attrs) => ignored.set(target, attrs),
    });
  }
  hook.mounted();
  mounted.push(hook);
  return { hook, pushed };
}

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
}

function keydown(key, init = {}) {
  const event = new window.KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
    ...init,
  });
  document.body.dispatchEvent(event);
  return event;
}

test("mounting mirrors the provider state onto the sidebar", () => {
  const { el, sidebar, trigger } = buildSidebar({ state: "collapsed" });
  mountHook(el);

  assert.equal(el.dataset.state, "collapsed");
  assert.equal(sidebar().dataset.state, "collapsed");
  assert.equal(sidebar().dataset.collapsible, "icon");
  assert.equal(sidebar().dataset.variant, "floating");
  assert.equal(sidebar().hasAttribute("data-mobile"), false);
  assert.equal(trigger().getAttribute("aria-expanded"), "false");
});

test("Cmd+B and Ctrl+B toggle the sidebar, as SIDEBAR_KEYBOARD_SHORTCUT", () => {
  const { el, sidebar, trigger } = buildSidebar();
  mountHook(el);

  const event = keydown("b", { metaKey: true });
  assert.equal(event.defaultPrevented, true);
  assert.equal(sidebar().dataset.state, "collapsed");
  assert.equal(sidebar().dataset.collapsible, "icon");
  assert.equal(el.dataset.state, "collapsed");
  assert.equal(trigger().getAttribute("aria-expanded"), "false");

  keydown("b", { ctrlKey: true });
  assert.equal(sidebar().dataset.state, "expanded");
  assert.equal(sidebar().dataset.collapsible, "");

  // Plain "b" and other modified keys are left alone.
  keydown("b");
  keydown("k", { metaKey: true });
  assert.equal(sidebar().dataset.state, "expanded");
});

test("the shortcut can be turned off", () => {
  const { el, sidebar } = buildSidebar({
    options: { keyboardShortcut: false },
  });
  mountHook(el);

  const event = keydown("b", { metaKey: true });
  assert.equal(event.defaultPrevented, false);
  assert.equal(sidebar().dataset.state, "expanded");
});

test("the trigger and the rail toggle through data-action", () => {
  const { el, sidebar, trigger } = buildSidebar();
  mountHook(el);

  click(trigger());
  assert.equal(sidebar().dataset.state, "collapsed");

  click(el.querySelector('[data-sidebar="rail"]'));
  assert.equal(sidebar().dataset.state, "expanded");
});

test("only the sidebar's own controls act on it", () => {
  const { el, sidebar } = buildSidebar();
  mountHook(el);

  // App markup and a nested component's trigger (a collapsible menu button)
  // carry data-action too; the provider wraps them but leaves them alone.
  click(document.getElementById("app-action"));
  assert.equal(sidebar().dataset.state, "expanded");
  click(document.getElementById("collapsible-button"));
  assert.equal(sidebar().dataset.state, "expanded");

  // A trigger inside another component still toggles its provider.
  click(document.getElementById("nested-trigger"));
  assert.equal(sidebar().dataset.state, "collapsed");
});

function hover(el) {
  el.dispatchEvent(new window.MouseEvent("mouseover", { bubbles: true }));
}

function unhover(el, relatedTarget = document.body) {
  el.dispatchEvent(
    new window.MouseEvent("mouseout", { bubbles: true, relatedTarget }),
  );
}

test("menu tooltips show only while collapsed, following client toggles", () => {
  const { el, trigger } = buildSidebar();
  mountHook(el);
  const button = document.getElementById("home-link");
  const tooltip = el.querySelector('[data-sidebar="menu-tooltip"]');

  // Expanded: the label is visible already, no tooltip.
  hover(button);
  assert.equal(tooltip.hidden, true);
  unhover(button);

  // Collapsed on the client (no server round trip): hover opens it at once.
  click(trigger());
  hover(button.querySelector("span"));
  assert.equal(tooltip.hidden, false);
  assert.equal(tooltip.dataset.state, "open");
  assert.equal(tooltip.style.position, "fixed");

  // Moving within the button keeps it; leaving closes it.
  unhover(button.querySelector("span"), button);
  assert.equal(tooltip.hidden, false);
  unhover(button);
  assert.equal(tooltip.hidden, true);
  assert.equal(tooltip.dataset.state, "closed");

  // Focus opens it too, Escape dismisses it.
  button.focus();
  assert.equal(tooltip.hidden, false);
  keydown("Escape");
  assert.equal(tooltip.hidden, true);

  // Expanding while it is open hides it.
  hover(button);
  assert.equal(tooltip.hidden, false);
  keydown("b", { metaKey: true });
  assert.equal(tooltip.hidden, true);
});

test("menu tooltips never show on the mobile sheet", () => {
  installMatchMedia(true);
  const { el, trigger } = buildSidebar({ state: "collapsed" });
  mountHook(el);
  const button = document.getElementById("home-link");
  const tooltip = el.querySelector('[data-sidebar="menu-tooltip"]');

  click(trigger());
  hover(button);
  assert.equal(tooltip.hidden, true);

  // Back on desktop, the collapsed sidebar shows it.
  media.set(false);
  hover(button);
  assert.equal(tooltip.hidden, false);
  // Going mobile hides it.
  media.set(true);
  assert.equal(tooltip.hidden, true);
});

test("an open menu tooltip survives a patch", () => {
  const ignored = new Map();
  const { el } = buildSidebar({ state: "collapsed" });
  const { hook } = mountHook(el, { ignored });
  const tooltip = () => el.querySelector('[data-sidebar="menu-tooltip"]');

  assert.deepEqual(ignored.get(tooltip()), [
    "hidden",
    "style",
    "data-state",
    "data-side",
  ]);

  hover(document.getElementById("home-link"));
  assert.equal(tooltip().hidden, false);

  // The patch re-renders the sidebar: a new, hidden tooltip element.
  hook.beforeUpdate();
  el.querySelector('[data-slot="sidebar"]').outerHTML = sidebarMarkup({
    state: "collapsed",
  });
  hook.updated();

  assert.equal(tooltip().hidden, false);
  assert.equal(tooltip().dataset.state, "open");
  unhover(document.getElementById("home-link"));
  assert.equal(tooltip().hidden, true);
});

test("a toggle writes the sidebar_state cookie and fires on-open-change", () => {
  const { el, trigger } = buildSidebar();
  const { pushed } = mountHook(el);

  click(trigger());
  assert.deepEqual(cookieWrites, [
    "sidebar_state=false; path=/; max-age=604800",
  ]);
  assert.equal(pushed.length, 1);
  assert.equal(pushed[0].event, "open_changed");
  assert.equal(pushed[0].payload.open, false);
  assert.equal(pushed[0].payload.componentId, "provider");

  click(trigger());
  assert.equal(
    cookieWrites.at(-1),
    "sidebar_state=true; path=/; max-age=604800",
  );
  assert.equal(pushed.at(-1).payload.open, true);
});

test("a custom cookie name is used, and null disables the cookie", () => {
  const named = buildSidebar({ options: { cookieName: "nav_state" } });
  mountHook(named.el);
  click(named.trigger());
  assert.equal(cookieWrites.at(-1), "nav_state=false; path=/; max-age=604800");

  cookieWrites = [];
  const disabled = buildSidebar({ options: { cookieName: null } });
  mountHook(disabled.el);
  click(disabled.trigger());
  assert.equal(disabled.sidebar().dataset.state, "collapsed");
  assert.deepEqual(cookieWrites, []);
});

test("below 768px the sidebar is a closed offcanvas sheet", () => {
  installMatchMedia(true);
  const { el, sidebar, container, trigger } = buildSidebar();
  mountHook(el);

  assert.equal(el.dataset.mobile, "true");
  assert.equal(sidebar().dataset.mobile, "true");
  assert.equal(sidebar().dataset.state, "closed");
  assert.equal(sidebar().dataset.collapsible, "offcanvas");
  assert.equal(sidebar().hasAttribute("data-variant"), false);
  assert.equal(container().hasAttribute("inert"), true);
  assert.equal(trigger().getAttribute("aria-expanded"), "false");
  // The desktop state is untouched.
  assert.equal(el.dataset.state, "expanded");
});

test("the trigger opens the mobile sheet with a focus trap; Escape closes it", async () => {
  installMatchMedia(true);
  const { el, sidebar, container, trigger } = buildSidebar({
    mappings: { "open-mobile-change": "mobile_changed" },
  });
  const { pushed } = mountHook(el);

  trigger().focus();
  click(trigger());

  assert.equal(sidebar().dataset.state, "open");
  assert.equal(sidebar().dataset.collapsible, "");
  assert.equal(el.dataset.openMobile, "true");
  assert.equal(container().hasAttribute("inert"), false);
  assert.equal(container().getAttribute("role"), "dialog");
  assert.equal(container().getAttribute("aria-modal"), "true");
  assert.equal(container().getAttribute("aria-label"), "Sidebar");
  assert.equal(trigger().getAttribute("aria-expanded"), "true");
  assert.deepEqual(pushed.at(-1), {
    event: "mobile_changed",
    payload: { open: true, componentId: "provider", component: "sidebar" },
  });
  await waitFor(() => container().contains(document.activeElement));

  // The mobile sheet does not touch the desktop state or the cookie.
  assert.equal(el.dataset.state, "expanded");
  assert.deepEqual(cookieWrites, []);

  const event = keydown("Escape");
  assert.equal(event.defaultPrevented, true);
  assert.equal(sidebar().dataset.state, "closed");
  assert.equal(container().hasAttribute("inert"), true);
  assert.equal(container().hasAttribute("role"), false);
  assert.equal(pushed.at(-1).payload.open, false);
  await waitFor(() => document.activeElement === trigger());
});

test("a click on the overlay (outside the sheet) closes it", () => {
  installMatchMedia(true);
  const { el, sidebar, overlay, trigger } = buildSidebar();
  mountHook(el);

  click(trigger());
  assert.equal(sidebar().dataset.state, "open");

  click(overlay());
  assert.equal(sidebar().dataset.state, "closed");
});

test("Cmd+B toggles the mobile sheet while mobile", () => {
  installMatchMedia(true);
  const { el, sidebar } = buildSidebar();
  mountHook(el);

  keydown("b", { metaKey: true });
  assert.equal(sidebar().dataset.state, "open");
  keydown("b", { metaKey: true });
  assert.equal(sidebar().dataset.state, "closed");
});

test("crossing the breakpoint switches layouts and closes the sheet", () => {
  installMatchMedia(true);
  const { el, sidebar, container, trigger } = buildSidebar();
  mountHook(el);

  click(trigger());
  assert.equal(sidebar().dataset.state, "open");

  media.set(false);
  assert.equal(el.dataset.mobile, "false");
  assert.equal(el.dataset.openMobile, "false");
  assert.equal(sidebar().hasAttribute("data-mobile"), false);
  assert.equal(sidebar().dataset.state, "expanded");
  assert.equal(sidebar().dataset.variant, "floating");
  assert.equal(container().hasAttribute("inert"), false);

  media.set(true);
  assert.equal(sidebar().dataset.state, "closed");
  assert.equal(sidebar().dataset.mobile, "true");
});

test("is_mobile overrides the media query", () => {
  installMatchMedia(false);
  const forced = buildSidebar({ options: { isMobile: true } });
  mountHook(forced.el);
  assert.equal(forced.sidebar().dataset.mobile, "true");

  installMatchMedia(true);
  const desktop = buildSidebar({ sidebar: { isMobile: false } });
  mountHook(desktop.el);
  assert.equal(desktop.sidebar().hasAttribute("data-mobile"), false);
  media.set(true);
  assert.equal(desktop.sidebar().hasAttribute("data-mobile"), false);
});

test("commands reach the provider and its sidebars", () => {
  const { el, sidebar } = buildSidebar();
  const { hook } = mountHook(el);

  const command = (target, name) =>
    target.dispatchEvent(
      new window.CustomEvent("salad_ui:command", {
        detail: { command: name, params: {} },
        bubbles: false,
      }),
    );

  command(el, "collapse");
  assert.equal(sidebar().dataset.state, "collapsed");
  command(sidebar(), "toggle");
  assert.equal(sidebar().dataset.state, "expanded");
  command(sidebar(), "close");
  assert.equal(sidebar().dataset.state, "collapsed");

  // send_command goes through the hook to handleCommand.
  hook.component.handleCommand("open");
  assert.equal(sidebar().dataset.state, "expanded");
});

test("the client state survives LiveView patches", () => {
  const ignored = new Map();
  const { el, sidebar, container, trigger } = buildSidebar();
  const { hook } = mountHook(el, { ignored });

  assert.deepEqual(ignored.get(el), [
    "data-state",
    "data-mobile",
    "data-open-mobile",
  ]);
  assert.deepEqual(ignored.get(sidebar()), [
    "data-state",
    "data-collapsible",
    "data-variant",
    "data-mobile",
  ]);
  assert.deepEqual(ignored.get(container()), [
    "inert",
    "role",
    "aria-modal",
    "aria-label",
  ]);
  assert.deepEqual(ignored.get(trigger()), ["aria-expanded"]);

  click(trigger());
  assert.equal(sidebar().dataset.state, "collapsed");
  const instance = hook.component;

  // A patch that re-renders the sidebar from server markup ("expanded").
  hook.beforeUpdate();
  el.querySelector('[data-slot="sidebar"]').outerHTML = sidebarMarkup();
  hook.updated();

  assert.equal(hook.component, instance);
  assert.equal(sidebar().dataset.state, "collapsed");
  assert.equal(sidebar().dataset.collapsible, "icon");
  // The replacement is protected and still takes commands.
  assert.ok(ignored.has(sidebar()));
  click(sidebar().querySelector('[data-sidebar="rail"]'));
  assert.equal(sidebar().dataset.state, "expanded");
});

test("a rebuild (changed options) keeps the client state", () => {
  const { el, sidebar, trigger } = buildSidebar();
  const { hook } = mountHook(el, { ignored: new Map() });

  click(trigger());
  const instance = hook.component;

  el.setAttribute(
    "data-options",
    JSON.stringify({ keyboardShortcut: false, cookieName: "sidebar_state" }),
  );
  hook.updated();

  assert.notEqual(hook.component, instance);
  assert.equal(sidebar().dataset.state, "collapsed");
  // The old instance no longer listens.
  keydown("b", { metaKey: true });
  assert.equal(sidebar().dataset.state, "collapsed");
});

test("a controlled provider follows a changed open from the server", () => {
  const { el, sidebar, trigger } = buildSidebar({ open: true });
  const { hook, pushed } = mountHook(el, { ignored: new Map() });

  // The client toggles right away and reports it.
  click(trigger());
  assert.equal(sidebar().dataset.state, "collapsed");
  assert.equal(pushed.at(-1).payload.open, false);

  // The server echoes the new value...
  el.setAttribute("data-open", "false");
  hook.updated();
  assert.equal(sidebar().dataset.state, "collapsed");

  // ...and later opens it. No event or cookie for server-driven changes.
  const events = pushed.length;
  const cookies = cookieWrites.length;
  el.setAttribute("data-open", "true");
  hook.updated();
  assert.equal(sidebar().dataset.state, "expanded");
  assert.equal(pushed.length, events);
  assert.equal(cookieWrites.length, cookies);
});

test("data-open wins over the rendered state on mount", () => {
  const { el, sidebar } = buildSidebar({ state: "expanded", open: false });
  mountHook(el);

  assert.equal(sidebar().dataset.state, "collapsed");
});

test("destroy removes the global listeners", () => {
  const { el, sidebar } = buildSidebar();
  const { hook } = mountHook(el);

  hook.destroyed();
  keydown("b", { metaKey: true });
  assert.equal(sidebar().dataset.state, "expanded");
  assert.equal(media.listeners.size, 0);
});
