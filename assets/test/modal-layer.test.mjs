import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import "../salad_ui/components/dialog.js";
import "../salad_ui/components/drawer.js";
import "../salad_ui/components/dropdown_menu.js";
import "../salad_ui/components/popover.js";
import "../salad_ui/components/select.js";
import { registry } from "../salad_ui/core/factory.js";
import {
  isModalBlocking,
  modalLayerCount,
  resetModalLayers,
} from "../salad_ui/core/modal-layer.js";
import {
  isScrollLocked,
  resetScrollLock,
} from "../salad_ui/core/scroll-lock.js";
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

const mounted = [];

afterEach(() => {
  mounted.splice(0).forEach((component) => component.destroy());
  resetModalLayers();
  resetScrollLock();
  document.body.innerHTML = "";
  document.body.removeAttribute("style");
  document.documentElement.removeAttribute("style");
});

const hookContext = {
  pushEventTo() {},
  liveSocket: { execJS() {} },
};

function mount(type, el) {
  const component = registry.create(type, el, hookContext);
  mounted.push(component);
  return component;
}

const $ = (selector) => document.querySelector(selector);

function dialogMarkup(id, { options = {}, inner = "", panel = "" } = {}) {
  const json = JSON.stringify({ closeOnOutsideClick: true, ...options });
  return `
    <div id="${id}" data-component="${options.direction ? "drawer" : "dialog"}"
         data-open="false" data-options='${json}' data-event-mappings='{}'
         data-part="root">
      <button id="${id}-trigger" data-part="trigger" data-action="open" type="button">Open</button>
      <div id="${id}-content" data-part="content" hidden>
        <div id="${id}-overlay" data-part="overlay"></div>
        <div id="${id}-panel" data-part="content-panel">
          <h2 data-part="title">Title</h2>
          <button id="${id}-action" type="button">Action</button>
          <button id="${id}-close" data-part="close-trigger" data-action="close" type="button">Close</button>
          ${panel}
        </div>
      </div>
      ${inner}
    </div>`;
}

// A page with a header, a main column holding the dialog, a live region and
// an element the app already hides.
function buildPage(dialogHtml = dialogMarkup("dialog")) {
  document.body.innerHTML = `
    <header id="header"><button id="page-button" type="button">Page</button></header>
    <main id="main">
      <p id="sibling">Text</p>
      ${dialogHtml}
    </main>
    <div id="live" aria-live="polite"></div>
    <div id="pre-hidden" aria-hidden="true"></div>
  `;
}

function buildDialog(options = {}) {
  buildPage(dialogMarkup("dialog", { options }));
  return mount("dialog", $("#dialog"));
}

function dropdownMarkup(id, options = {}) {
  return `
    <div id="${id}" data-component="dropdown-menu" data-state="closed"
         data-options='${JSON.stringify(options)}' data-event-mappings='{}'
         data-part="root">
      <button type="button" data-part="trigger">Menu</button>
      <div data-part="positioner" data-side="bottom" data-align="start" hidden>
        <div data-part="content" tabindex="-1">
          <div data-part="item" data-value="one" tabindex="0">One</div>
        </div>
      </div>
    </div>`;
}

function buildDropdown(options = {}) {
  document.body.innerHTML = `
    <header id="header"><button id="page-button" type="button">Page</button></header>
    ${dropdownMarkup("menu", options)}
  `;
  const el = $("#menu");
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
  return mount("dropdown-menu", el);
}

// pointer-events is inherited: the nearest value up the tree decides.
function effectivePointerEvents(el) {
  for (let node = el; node?.nodeType === 1; node = node.parentElement) {
    const value = node.style.pointerEvents;
    if (value && value !== "inherit") return value;
  }
  return "auto";
}

// What a browser does with a real click on `el`: an element with
// `pointer-events: none` is never hit, so the click falls through to what is
// underneath it (here, <html>). Returns the element that was hit.
function userClick(el) {
  const target =
    effectivePointerEvents(el) === "none" ? document.documentElement : el;
  ["pointerdown", "mousedown", "pointerup", "mouseup", "click"].forEach(
    (type) =>
      target.dispatchEvent(
        new window.MouseEvent(type, { bubbles: true, cancelable: true }),
      ),
  );
  return target;
}

function wheel(target, init = {}) {
  const event = new window.WheelEvent("wheel", {
    bubbles: true,
    cancelable: true,
    deltaY: 40,
    ...init,
  });
  target.dispatchEvent(event);
  return event.defaultPrevented;
}

function touch(target, type, y, fingers = 1) {
  const point = { clientX: 0, clientY: y, target };
  const event = new window.Event(type, { bubbles: true, cancelable: true });
  const touches = Array.from({ length: fingers }, () => point);
  Object.defineProperty(event, "touches", { value: touches });
  Object.defineProperty(event, "changedTouches", { value: [point] });
  target.dispatchEvent(event);
  return event.defaultPrevented;
}

// jsdom does no layout: give `el` a scroll position and size.
function makeScrollable(el, { scrollTop = 0, scrollHeight, clientHeight }) {
  el.style.overflowY = "auto";
  Object.defineProperty(el, "scrollHeight", { value: scrollHeight });
  Object.defineProperty(el, "clientHeight", { value: clientHeight });
  el.scrollTop = scrollTop;
  Object.defineProperty(el, "scrollTop", {
    value: scrollTop,
    writable: true,
  });
}

const hidden = (selector) => $(selector).getAttribute("aria-hidden") === "true";

// --- outside pointer blocking ---------------------------------------------

test("an open dialog disables pointer events outside its content", () => {
  const dialog = buildDialog();
  let pageClicks = 0;
  $("#page-button").addEventListener("click", () => (pageClicks += 1));

  dialog.transition("open");

  assert.equal(document.body.style.pointerEvents, "none");
  assert.equal($("#dialog-content").style.pointerEvents, "auto");
  assert.equal(effectivePointerEvents($("#page-button")), "none");
  assert.equal(effectivePointerEvents($("#dialog-trigger")), "none");
  assert.equal(effectivePointerEvents($("#dialog-overlay")), "auto");
  assert.equal(effectivePointerEvents($("#dialog-action")), "auto");

  // A click aimed at the page never reaches it.
  assert.equal(userClick($("#page-button")), document.documentElement);
  assert.equal(pageClicks, 0);
  assert.equal(dialog.state, "open");

  // The overlay is the dismiss surface.
  userClick($("#dialog-overlay"));
  assert.equal(dialog.state, "closed");
  assert.equal(document.body.hasAttribute("style"), false);
  assert.equal($("#dialog-content").hasAttribute("style"), false);

  // Afterwards the page is clickable again.
  assert.equal(userClick($("#page-button")), $("#page-button"));
  assert.equal(pageClicks, 1);
});

test("the body's own inline pointer-events comes back on close", () => {
  const dialog = buildDialog();
  document.body.style.setProperty("pointer-events", "auto", "important");

  dialog.transition("open");
  assert.equal(document.body.style.pointerEvents, "none");

  dialog.transition("close");
  assert.equal(document.body.style.pointerEvents, "auto");
  assert.equal(
    document.body.style.getPropertyPriority("pointer-events"),
    "important",
  );
});

test("an open modal dropdown menu: an outside click only dismisses it", () => {
  const menu = buildDropdown();
  let pageClicks = 0;
  $("#page-button").addEventListener("click", () => (pageClicks += 1));

  menu.transition("open");
  const positioner = $('#menu [data-part="positioner"]');
  assert.equal(document.body.style.pointerEvents, "none");
  assert.equal(positioner.style.pointerEvents, "auto");
  assert.ok(isScrollLocked());

  userClick($("#page-button"));
  assert.equal(pageClicks, 0);
  assert.equal(menu.state, "closed");
  assert.equal(isModalBlocking(), false);
  assert.equal(isScrollLocked(), false);
  assert.equal(document.body.hasAttribute("style"), false);
  assert.equal(positioner.style.pointerEvents, "");
});

// --- aria-hidden -------------------------------------------------------------

test("everything outside an open dialog is aria-hidden, and restored on close", () => {
  const dialog = buildDialog();

  dialog.transition("open");

  assert.ok(hidden("#header"));
  assert.equal($("#header").getAttribute("data-aria-hidden"), "true");
  assert.ok(hidden("#sibling"));
  assert.ok(hidden("#dialog-trigger"));
  // The path to the content, the content and the live region stay exposed.
  for (const id of [
    "#main",
    "#dialog",
    "#dialog-content",
    "#dialog-panel",
    "#live",
  ]) {
    assert.equal(hidden(id), false, id);
    assert.equal($(id).hasAttribute("data-aria-hidden"), false, id);
  }
  assert.ok(hidden("#pre-hidden"));

  dialog.transition("close");

  for (const id of ["#header", "#sibling", "#dialog-trigger"]) {
    assert.equal($(id).hasAttribute("aria-hidden"), false, id);
    assert.equal($(id).hasAttribute("data-aria-hidden"), false, id);
  }
  // The app's own aria-hidden is left alone.
  assert.ok(hidden("#pre-hidden"));
  assert.equal($("#pre-hidden").hasAttribute("data-aria-hidden"), false);
});

test("everything hidden outside an open dialog is also inert, and restored on close", () => {
  const dialog = buildDialog();
  $("#pre-hidden").setAttribute("inert", "");

  dialog.transition("open");

  // inert takes the hidden page out of the tab order (axe aria-hidden-focus).
  for (const id of ["#header", "#sibling", "#dialog-trigger"]) {
    assert.ok($(id).hasAttribute("inert"), id);
  }
  // Never the layer, its ancestors or a live region.
  for (const id of [
    "#main",
    "#dialog",
    "#dialog-content",
    "#dialog-panel",
    "#live",
  ]) {
    assert.equal($(id).hasAttribute("inert"), false, id);
  }

  dialog.transition("close");

  for (const id of ["#header", "#sibling", "#dialog-trigger"]) {
    assert.equal($(id).hasAttribute("inert"), false, id);
  }
  // The app's own inert is left alone.
  assert.ok($("#pre-hidden").hasAttribute("inert"));
});

test("stacked dialogs: the inner one hides and blocks the outer until it closes", () => {
  buildPage(dialogMarkup("outer", { panel: dialogMarkup("inner") }));
  const inner = mount("dialog", $("#inner"));
  const outer = mount("dialog", $("#outer"));

  outer.transition("open");
  inner.transition("open");

  assert.equal(modalLayerCount(), 2);
  assert.equal($("#inner-content").style.pointerEvents, "auto");
  assert.equal(effectivePointerEvents($("#outer-action")), "none");
  assert.equal(effectivePointerEvents($("#inner-action")), "auto");
  assert.ok(hidden("#outer-action"));
  assert.ok(hidden("#outer-overlay"));
  assert.ok(hidden("#header"));
  assert.equal($("#inner-panel").hasAttribute("aria-hidden"), false);

  inner.transition("close");

  assert.equal(modalLayerCount(), 1);
  assert.equal(effectivePointerEvents($("#outer-action")), "auto");
  assert.equal($("#outer-action").hasAttribute("aria-hidden"), false);
  assert.equal($("#outer-overlay").hasAttribute("aria-hidden"), false);
  assert.ok(hidden("#header"));
  assert.ok(isScrollLocked());

  outer.transition("close");

  assert.equal(isModalBlocking(), false);
  assert.equal(isScrollLocked(), false);
  // Only the app's own aria-hidden is left (the content parts carry theirs).
  assert.deepEqual(
    [...document.querySelectorAll('[aria-hidden="true"]:not([data-part])')].map(
      (node) => node.id,
    ),
    ["pre-hidden"],
  );
  assert.equal(document.querySelectorAll("[data-aria-hidden]").length, 0);
});

test("two sibling dialogs: the later one blocks the earlier", () => {
  buildPage(dialogMarkup("first") + dialogMarkup("second"));
  const first = mount("dialog", $("#first"));
  const second = mount("dialog", $("#second"));

  first.transition("open");
  second.transition("open");

  assert.ok(hidden("#first"));
  assert.equal(effectivePointerEvents($("#first-action")), "none");
  assert.equal(effectivePointerEvents($("#second-action")), "auto");

  // Closing the earlier one out of order leaves the later one in charge.
  first.transition("close");
  assert.ok(hidden("#first"));
  assert.equal(effectivePointerEvents($("#second-action")), "auto");

  second.transition("close");
  assert.equal(document.querySelectorAll("[data-aria-hidden]").length, 0);
  assert.equal(document.body.hasAttribute("style"), false);
});

test("a modal dropdown opened inside a dialog takes over, then hands back", () => {
  buildPage(dialogMarkup("dialog", { panel: dropdownMarkup("menu") }));
  const menu = mount("dropdown-menu", $("#menu"));
  const dialog = mount("dialog", $("#dialog"));

  dialog.transition("open");
  menu.transition("open");

  const positioner = $('#menu [data-part="positioner"]');
  assert.equal(positioner.style.pointerEvents, "auto");
  assert.equal(effectivePointerEvents($("#dialog-action")), "none");
  assert.ok(hidden("#dialog-action"));

  // A click on the dialog only closes the menu.
  userClick($("#dialog-action"));
  assert.equal(menu.state, "closed");
  assert.equal(dialog.state, "open");
  assert.equal(effectivePointerEvents($("#dialog-action")), "auto");
  assert.equal($("#dialog-action").hasAttribute("aria-hidden"), false);
  assert.ok(hidden("#header"));
});

test("a select portaled out of an open dialog works like part of the dialog", async () => {
  const selectHtml = `
    <div id="fruit" data-component="select" data-state="closed"
         data-options='{"name":"fruit","usePortal":true}'
         data-event-mappings='{}' data-part="root">
      <button id="fruit-trigger" type="button" data-part="trigger">
        <span data-part="value" data-placeholder="Pick">Pick</span>
      </button>
      <div id="fruit-content" data-part="content" hidden>
        <div data-part="item" data-value="apple" tabindex="0">
          <span data-part="item-indicator" hidden></span>
          <span data-part="item-text">Apple</span>
        </div>
        <div id="banana" data-part="item" data-value="banana" tabindex="0">
          <span data-part="item-indicator" hidden></span>
          <span data-part="item-text">Banana</span>
        </div>
      </div>
    </div>`;
  buildPage(dialogMarkup("dialog", { panel: selectHtml }));
  const select = mount("select", $("#fruit"));
  const dialog = mount("dialog", $("#dialog"));

  dialog.transition("open");
  userClick($("#fruit-trigger"));
  assert.equal(select.state, "open");

  const content = $("#fruit-content");
  assert.equal($("#fruit").contains(content), false, "the list is portaled");

  // Neither hidden from assistive technology nor blocked.
  await waitFor(() => content.style.pointerEvents === "auto");
  for (let node = content; node !== document.body; node = node.parentElement) {
    assert.notEqual(node.getAttribute("aria-hidden"), "true", node.id);
  }
  assert.ok(hidden("#header"));
  assert.equal(effectivePointerEvents($("#banana")), "auto");

  // Wheel over the list is not treated as outside the dialog.
  makeScrollable(content, { scrollHeight: 300, clientHeight: 100 });
  assert.equal(wheel($("#banana")), false);

  // Picking an item is not an outside click: the dialog stays open.
  userClick($("#banana"));
  assert.deepEqual(select.selection.getValue(true), ["banana"]);
  assert.equal(select.state, "closed");
  assert.equal(dialog.state, "open");
  assert.equal(effectivePointerEvents($("#dialog-action")), "auto");
});

test("content portaled out of an open dialog stays interactive and exposed", async () => {
  const popoverHtml = `
    <div id="popover" data-component="popover" data-state="closed"
         data-options='{"usePortal":true,"portalContainer":"#portal"}'
         data-event-mappings='{}' data-part="root">
      <button id="popover-trigger" data-part="trigger" data-action="toggle" type="button">Pick</button>
      <div data-part="positioner" data-side="bottom" data-align="center" hidden>
        <div data-part="content"><button id="popover-action" type="button">Choice</button></div>
      </div>
    </div>`;
  buildPage(dialogMarkup("dialog", { panel: popoverHtml }));
  document.body.insertAdjacentHTML("afterbegin", '<div id="portal"></div>');
  const popover = mount("popover", $("#popover"));
  const dialog = mount("dialog", $("#dialog"));

  dialog.transition("open");
  assert.ok(hidden("#portal"));

  popover.transition("open");
  const positioner = $("#portal > [data-part='positioner']");
  assert.ok(positioner, "the popover content is portaled");

  await waitFor(() => !$("#portal").hasAttribute("aria-hidden"));
  assert.equal($("#portal").hasAttribute("inert"), false);
  assert.equal(positioner.style.pointerEvents, "auto");
  assert.equal(effectivePointerEvents($("#popover-action")), "auto");
  assert.ok(hidden("#header"));

  // Wheel over the portaled list is not blocked as "outside".
  makeScrollable(positioner, { scrollHeight: 300, clientHeight: 100 });
  assert.equal(wheel($("#popover-action")), false);

  popover.transition("close");
  await waitFor(() => hidden("#portal"));
});

// --- LiveView patches ---------------------------------------------------------

test("a patch of the open dialog keeps the page blocked and hidden", () => {
  const dialog = buildDialog();
  const el = $("#dialog");
  dialog.transition("open");

  const hook = hookFor(el, dialog);
  hook.beforeUpdate();
  simulatePatch(el, {
    hidden: ['[data-part="content"]'],
    keepIds: [...el.querySelectorAll("[id]")].map((node) => node.id),
  });
  // The trigger is not a part the simulated patch touches; strip it too.
  $("#dialog-trigger").removeAttribute("aria-hidden");
  hook.updated();

  assert.equal(hook.component, dialog, "the instance is kept");
  assert.equal(dialog.state, "open");
  assert.equal($("#dialog-content").style.pointerEvents, "auto");
  assert.ok(hidden("#dialog-trigger"));
  assert.equal(document.body.style.pointerEvents, "none");
  assert.equal(modalLayerCount(), 1);
});

test("a patch elsewhere on the page gets aria-hidden and pointer-events back", async () => {
  const dialog = buildDialog();
  dialog.transition("open");

  // morphdom drops attributes the server does not render, swaps nodes and
  // inserts new ones.
  $("#header").removeAttribute("aria-hidden");
  $("#sibling").replaceWith(
    Object.assign(document.createElement("p"), { id: "sibling" }),
  );
  $("#main").insertAdjacentHTML("afterbegin", '<nav id="new-nav"></nav>');
  $("#dialog-content").removeAttribute("style");

  await waitFor(
    () =>
      hidden("#header") &&
      hidden("#sibling") &&
      hidden("#new-nav") &&
      $("#dialog-content").style.pointerEvents === "auto",
  );

  dialog.transition("close");
  assert.equal(document.querySelectorAll("[data-aria-hidden]").length, 0);
  assert.equal($("#new-nav").hasAttribute("aria-hidden"), false);
});

test("a rebuild of the open dialog swaps in a single new layer", () => {
  const dialog = buildDialog();
  const el = $("#dialog");
  dialog.transition("open");

  const hook = hookFor(el, dialog);
  hook.beforeUpdate();
  simulatePatch(el, { hidden: ['[data-part="content"]'] });
  el.setAttribute("data-open", "true");
  el.setAttribute("data-options", '{"closeOnOutsideClick":false}');
  hook.updated();
  mounted.splice(mounted.indexOf(dialog), 1, hook.component);

  assert.notEqual(hook.component, dialog);
  assert.equal(hook.component.state, "open");
  assert.equal(modalLayerCount(), 1);
  assert.equal(
    el.querySelector('[data-part="content"]').style.pointerEvents,
    "auto",
  );
  assert.ok(hidden("#header"));
});

test("a layer branch (the toast viewport) stays interactive and exposed", () => {
  const dialog = buildDialog();
  document.body.insertAdjacentHTML(
    "beforeend",
    '<div id="toaster"><ol id="toasts" data-salad-layer-branch><li><button id="toast-close" type="button">x</button></li></ol><template id="tpl"></template></div>',
  );

  dialog.transition("open");

  assert.equal($("#toasts").style.pointerEvents, "auto");
  assert.equal(effectivePointerEvents($("#toast-close")), "auto");
  assert.equal(hidden("#toaster"), false);
  assert.equal(hidden("#toasts"), false);
  assert.equal($("#toaster").hasAttribute("inert"), false);
  assert.equal($("#toasts").hasAttribute("inert"), false);
  assert.ok(hidden("#tpl"));

  dialog.transition("close");
  assert.equal($("#toasts").hasAttribute("style"), false);
});

test("destroying an open dialog restores the page", () => {
  const dialog = buildDialog();
  dialog.transition("open");

  mounted.splice(0).forEach((component) => component.destroy());

  assert.equal(modalLayerCount(), 0);
  assert.equal(isScrollLocked(), false);
  assert.equal(document.body.hasAttribute("style"), false);
  assert.equal(document.querySelectorAll("[data-aria-hidden]").length, 0);
});

test("a dialog removed from the page without a destroy unblocks it", async () => {
  const dialog = buildDialog();
  dialog.transition("open");

  $("#dialog").remove();

  await waitFor(() => document.body.style.pointerEvents === "");
  assert.equal(document.querySelectorAll("[data-aria-hidden]").length, 0);
});

// --- exit animation -------------------------------------------------------------

test("closing unblocks at once; the scroll lock holds through the exit animation", async () => {
  const dialog = buildDialog({
    animations: { open_to_closed: { duration: 30, target_part: "content" } },
  });
  dialog.transition("open");

  dialog.transition("close");
  assert.equal(document.body.style.pointerEvents, "");
  assert.equal($("#header").hasAttribute("aria-hidden"), false);
  assert.ok(isScrollLocked());

  await waitFor(() => $("#dialog-content").hidden);
  assert.equal(isScrollLocked(), false);
  assert.equal(modalLayerCount(), 0);
});

// --- wheel / touch ------------------------------------------------------------

test("wheel and touch scrolling are blocked outside the dialog's scroll areas", () => {
  buildPage(
    dialogMarkup("dialog", {
      panel: '<div id="scroller"><p id="scroll-text">Long</p></div>',
    }),
  );
  const dialog = mount("dialog", $("#dialog"));
  const scroller = $("#scroller");

  // Nothing is blocked while closed.
  assert.equal(wheel($("#dialog-trigger")), false);
  assert.equal(wheel($("#page-button")), false);

  dialog.transition("open");

  assert.equal(wheel($("#dialog-overlay")), true, "wheel on the overlay");
  assert.equal(wheel($("#page-button")), true, "wheel on the page");
  assert.equal(wheel($("#dialog-action")), true, "nothing to scroll");

  makeScrollable(scroller, { scrollHeight: 300, clientHeight: 100 });
  assert.equal(wheel($("#scroll-text")), false, "room to scroll down");
  assert.equal(
    wheel($("#scroll-text"), { deltaY: -40 }),
    true,
    "already at the top",
  );
  scroller.scrollTop = 200;
  assert.equal(wheel($("#scroll-text")), true, "already at the bottom");
  assert.equal(wheel($("#scroll-text"), { deltaY: -40 }), false);

  // Pinch-zoom is never blocked.
  assert.equal(wheel($("#dialog-overlay"), { ctrlKey: true }), false);

  // A drag up on the overlay would scroll the page.
  touch($("#dialog-overlay"), "touchstart", 300);
  assert.equal(touch($("#dialog-overlay"), "touchmove", 200), true);
  touch($("#scroll-text"), "touchstart", 300);
  assert.equal(touch($("#scroll-text"), "touchmove", 320), false, "scrolls up");
  assert.equal(
    touch($("#dialog-overlay"), "touchmove", 200, 2),
    false,
    "pinch",
  );

  dialog.transition("close");
  assert.equal(wheel($("#page-button")), false);
});

// --- modal: false -------------------------------------------------------------

test("a non-modal dialog blocks, hides and locks nothing", () => {
  const dialog = buildDialog({ modal: false });
  let pageClicks = 0;
  $("#page-button").addEventListener("click", () => (pageClicks += 1));

  dialog.transition("open");

  assert.equal(document.body.hasAttribute("style"), false);
  assert.equal(document.querySelectorAll("[data-aria-hidden]").length, 0);
  assert.equal(isScrollLocked(), false);
  assert.equal(isModalBlocking(), false);
  assert.equal($("#dialog-overlay").hidden, true, "no overlay");
  assert.equal($("#dialog-panel").hasAttribute("aria-modal"), false);
  assert.equal(wheel($("#page-button")), false);

  // An outside click reaches the page and closes the dialog.
  assert.equal(userClick($("#page-button")), $("#page-button"));
  assert.equal(pageClicks, 1);
  assert.equal(dialog.state, "closed");
});

test("a non-modal dialog ignores clicks on its own trigger and content", () => {
  const dialog = buildDialog({ modal: false });
  dialog.transition("open");

  userClick($("#dialog-action"));
  assert.equal(dialog.state, "open");
  userClick($("#dialog-trigger"));
  assert.equal(dialog.state, "open");
});

test("a non-modal dialog does not loop Tab", () => {
  const dialog = buildDialog({ modal: false });
  dialog.transition("open");

  $("#dialog-close").focus();
  const tab = new window.KeyboardEvent("keydown", {
    key: "Tab",
    bubbles: true,
    cancelable: true,
  });
  $("#dialog-close").dispatchEvent(tab);
  assert.equal(tab.defaultPrevented, false);
});

test("a non-modal dropdown menu blocks, hides and locks nothing", () => {
  const menu = buildDropdown({ modal: false });
  let pageClicks = 0;
  $("#page-button").addEventListener("click", () => (pageClicks += 1));

  menu.transition("open");
  assert.equal(document.body.hasAttribute("style"), false);
  assert.equal(document.querySelectorAll("[data-aria-hidden]").length, 0);
  assert.equal(isScrollLocked(), false);

  userClick($("#page-button"));
  assert.equal(pageClicks, 1);
  assert.equal(menu.state, "closed");
});

test("a drawer is modal by default and honours modal: false", () => {
  buildPage(
    dialogMarkup("drawer", { options: { direction: "bottom" } }) +
      dialogMarkup("loose", { options: { direction: "right", modal: false } }),
  );
  const drawer = mount("drawer", $("#drawer"));
  const loose = mount("drawer", $("#loose"));

  loose.transition("open");
  assert.equal(isModalBlocking(), false);
  assert.equal(isScrollLocked(), false);
  loose.transition("close");

  drawer.transition("open");
  assert.equal(document.body.style.pointerEvents, "none");
  assert.equal($("#drawer-content").style.pointerEvents, "auto");
  assert.ok(hidden("#header"));
  assert.ok(isScrollLocked());

  drawer.transition("close");
  assert.equal(isModalBlocking(), false);
  assert.equal(document.body.hasAttribute("style"), false);
});
