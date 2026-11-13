import { JSDOM } from "jsdom";

import { SaladUIHook } from "../../salad_ui/core/hook.js";

const GLOBAL_KEYS = [
  "window",
  "document",
  "Node",
  "Element",
  "HTMLElement",
  "Event",
  "CustomEvent",
  "KeyboardEvent",
  "MouseEvent",
  "requestAnimationFrame",
  "cancelAnimationFrame",
  "getComputedStyle",
  "ResizeObserver",
];

class StubResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
}

export function installDom(html = "<!doctype html><body></body>") {
  const dom = new JSDOM(html, { url: "http://localhost/" });
  const { window } = dom;

  globalThis.window = window;
  globalThis.document = window.document;
  globalThis.Node = window.Node;
  globalThis.Element = window.Element;
  globalThis.HTMLElement = window.HTMLElement;
  globalThis.Event = window.Event;
  globalThis.CustomEvent = window.CustomEvent;
  globalThis.KeyboardEvent = window.KeyboardEvent;
  globalThis.MouseEvent = window.MouseEvent;
  globalThis.getComputedStyle = window.getComputedStyle.bind(window);

  // jsdom does not implement rAF/ResizeObserver; stub them on both the bare
  // global (used by scroll-manager.js) and the window object (used via
  // `window.requestAnimationFrame` in utils.js) so code under test can run
  // without a real browser.
  const requestAnimationFrame = (callback) =>
    setTimeout(() => callback(Date.now()), 0);
  const cancelAnimationFrame = (id) => clearTimeout(id);
  const ResizeObserverImpl = window.ResizeObserver || StubResizeObserver;

  globalThis.requestAnimationFrame = requestAnimationFrame;
  globalThis.cancelAnimationFrame = cancelAnimationFrame;
  globalThis.ResizeObserver = ResizeObserverImpl;

  window.requestAnimationFrame = requestAnimationFrame;
  window.cancelAnimationFrame = cancelAnimationFrame;
  window.ResizeObserver = ResizeObserverImpl;

  return dom;
}

export function uninstallDom() {
  for (const key of GLOBAL_KEYS) {
    delete globalThis[key];
  }
}

export const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Polls `predicate` until it returns truthy or `timeout` ms elapse. Prefer this
 * over a fixed `wait(ms)` when the code under test chains timers/rAFs, whose
 * firing order against a fixed wait is not guaranteed on a loaded machine.
 */
export async function waitFor(
  predicate,
  { timeout = 5000, interval = 5 } = {},
) {
  const deadline = Date.now() + timeout;
  while (!predicate()) {
    if (Date.now() > deadline)
      throw new Error(`waitFor: timed out after ${timeout}ms`);
    await wait(interval);
  }
}

export function setRect(element, rect) {
  Object.assign(element, {
    getBoundingClientRect: () => ({
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      width: 0,
      height: 0,
      ...rect,
    }),
  });

  if (rect.width !== undefined) {
    Object.defineProperty(element, "offsetWidth", {
      value: rect.width,
      configurable: true,
    });
  }
  if (rect.height !== undefined) {
    Object.defineProperty(element, "offsetHeight", {
      value: rect.height,
      configurable: true,
    });
  }
}

/**
 * Approximates what a LiveView patch does to a component's DOM: whatever the
 * client wrote reverts to the server-rendered markup. On the root and every
 * `[data-part]` below it, `data-state`, inline `style`, `role` and `aria-*`
 * are dropped. LiveView's morphdom keys elements by id, so any element still
 * carrying an id other than `keepIds` (the ids the server renders) is
 * swapped for a fresh copy, as are elements matching `replace`; a component
 * that wants its parts patched in place must drop the ids it made up in
 * beforeUpdate(). Elements matching `hidden` get `hidden` back and elements
 * matching `remove` (client-inserted nodes) go. Selectors are matched before
 * anything changes.
 */
export function simulatePatch(
  el,
  { hidden = [], remove = [], replace = [], keepIds = [el.id] } = {},
) {
  const all = (selectors) =>
    selectors.flatMap((selector) => [...el.querySelectorAll(selector)]);
  const toHide = all(hidden);
  const toRemove = all(remove);
  const keyed = [...el.querySelectorAll("[id]")].filter(
    (node) => !keepIds.includes(node.id),
  );
  const toReplace = [...new Set([...all(replace), ...keyed])].filter(
    (node, _index, nodes) =>
      !nodes.some((other) => other !== node && other.contains(node)),
  );

  toRemove.forEach((node) => node.remove());
  [el, ...el.querySelectorAll("[data-part]")].forEach((node) => {
    node.removeAttribute("data-state");
    node.removeAttribute("style");
    for (const { name } of [...node.attributes]) {
      if (name.startsWith("aria-") || name === "role") {
        node.removeAttribute(name);
      }
    }
  });
  keyed.forEach((node) => node.removeAttribute("id"));
  toHide.forEach((node) => (node.hidden = true));
  toReplace.forEach((node) => node.replaceWith(node.cloneNode(true)));
}

/** A SaladUIHook bound to `el` that already holds `component`. */
export function hookFor(el, component) {
  return { ...SaladUIHook, el, component, handleEvent() {} };
}
