// saladui/core/detached-triggers.js
//
// Detached triggers: one component instance (a "shared" dropdown menu,
// context menu, ...) serving many triggers rendered anywhere on the page,
// e.g. one per row of a long list. Rendering the popup once instead of once
// per row keeps the row markup, and the page, small.
//
// A detached trigger names the instance it opens by root id and may carry
// a context map (JSON) describing what it stands for:
//
//     <button data-salad-for="msg-more" data-salad-context='{"id":42}'>
//
// `data-salad-for` may list several space-separated ids (a button that is a
// menu trigger and a tooltip trigger). Detached triggers are not
// `data-part`s: they live outside the instance's root, so no hook runs per
// trigger. Instead each instance subscribes with `listen()`, which keeps one
// document-level listener per event type for every instance on the page.
//
// This has no Radix equivalent; it is an additive, opt-in SaladUI extension.

export const FOR_ATTR = "data-salad-for";
export const CONTEXT_ATTR = "data-salad-context";

// The elements of a shared menu's content that receive its context as
// `phx-value-*` (see ContextValues): the items and anything with a
// `phx-click`.
export const CONTEXT_TARGETS = [
  "[data-part='item']",
  "[data-part='checkbox-item']",
  "[data-part='radio-item']",
  "[phx-click]",
].join(", ");

/**
 * The element an `open` command's `anchor` param names: an element, or a
 * selector for one. Null when nothing (connected) matches.
 */
export function resolveAnchor(anchor) {
  if (!anchor) return null;
  if (typeof anchor !== "string") return anchor.isConnected ? anchor : null;

  try {
    return document.querySelector(anchor);
  } catch {
    return null;
  }
}

// event type -> Map<instance id, Set<handler>>
const subscriptions = new Map();
// event type -> the one document listener for it
const documentListeners = new Map();

/** The instance ids a detached trigger names (empty for any other node). */
export function triggerIds(el) {
  const raw = el?.getAttribute?.(FOR_ATTR);
  return raw ? raw.split(/\s+/).filter(Boolean) : [];
}

/** Whether `el` is a detached trigger for the instance `id`. */
export function isTriggerFor(el, id) {
  return triggerIds(el).includes(id);
}

/** The nearest detached trigger for `id` at or above `node`, if any. */
export function closestTrigger(node, id) {
  for (let el = elementOf(node); el; el = el.parentElement) {
    if (isTriggerFor(el, id)) return el;
  }
  return null;
}

/** Every detached trigger for `id` in `root` (the document by default). */
export function triggersFor(id, root = document) {
  return [...root.querySelectorAll(`[${FOR_ATTR}]`)].filter((el) =>
    isTriggerFor(el, id),
  );
}

/** A trigger's `data-salad-context`, parsed; null when absent or invalid. */
export function readContext(el) {
  const raw = el?.getAttribute?.(CONTEXT_ATTR);
  if (!raw) return null;

  try {
    const context = JSON.parse(raw);
    return context && typeof context === "object" ? context : null;
  } catch {
    console.error("SaladUI: invalid data-salad-context JSON:", raw);
    return null;
  }
}

/** Whether a trigger is disabled (`disabled`, `aria-disabled`, `data-disabled`). */
export function isTriggerDisabled(el) {
  if (!el) return true;
  if (el.disabled === true || el.getAttribute("aria-disabled") === "true") {
    return true;
  }
  const value = el.getAttribute("data-disabled");
  return value !== null && value !== "false";
}

function elementOf(node) {
  if (!node) return null;
  return node.nodeType === 1 ? node : node.parentElement || null;
}

function dispatch(event) {
  const byId = subscriptions.get(event.type);
  if (!byId || byId.size === 0) return;

  // Walk up from the target like the event bubbles; each instance hears only
  // about its innermost trigger.
  const seen = new Set();
  for (let el = elementOf(event.target); el; el = el.parentElement) {
    for (const id of triggerIds(el)) {
      if (seen.has(id)) continue;
      seen.add(id);
      byId.get(id)?.forEach((handler) => handler(event, el));
    }
  }
}

/**
 * Calls `handler(event, trigger)` for every `type` event (e.g. "click",
 * "keydown", "contextmenu") that reaches the document from inside a
 * detached trigger for `id`. One document listener per event type serves
 * every subscription. Returns the unsubscribe function.
 */
export function listen(id, type, handler) {
  if (!id || typeof document === "undefined") return () => {};

  if (!subscriptions.has(type)) subscriptions.set(type, new Map());
  const byId = subscriptions.get(type);
  if (!byId.has(id)) byId.set(id, new Set());
  byId.get(id).add(handler);

  if (!documentListeners.has(type)) {
    document.addEventListener(type, dispatch);
    documentListeners.set(type, document);
  }

  return () => {
    const handlers = byId.get(id);
    handlers?.delete(handler);
    if (handlers?.size === 0) byId.delete(id);
    if (byId.size === 0) {
      documentListeners.get(type)?.removeEventListener(type, dispatch);
      documentListeners.delete(type);
      subscriptions.delete(type);
    }
  };
}

/** Number of document listeners the delegation holds (for tests). */
export function listenerCount() {
  return documentListeners.size;
}

/** `el` and its ancestors, nearest first (for focusFallback() after `el` is gone). */
export function ancestry(el) {
  const path = [];
  for (let node = el; node; node = node.parentElement) path.push(node);
  return path;
}

const FOCUSABLE =
  "a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]";

/**
 * Focus the nearest focusable element of `path` (see ancestry()) that is
 * still in the document, e.g. the list a removed row sat in. Returns it, or
 * null when there is none (focus is then left to the document body).
 */
export function focusFallback(path = []) {
  for (const node of path) {
    if (!node?.isConnected) continue;
    if (node === document.body || node === document.documentElement) break;
    if (!node.matches?.(FOCUSABLE) || node.closest("[hidden], [inert]")) {
      continue;
    }

    node.focus({ preventScroll: true });
    if (document.activeElement === node) return node;
  }
  return null;
}

/**
 * Mirrors an instance's open state onto the detached trigger it is anchored
 * to: `data-state` (so a row can style itself with
 * `group-has-[[data-state=open]]`), and with `expanded`, `aria-expanded`
 * plus `aria-controls` while open.
 */
export function setTriggerState(
  trigger,
  open,
  { expanded = true, controls = null } = {},
) {
  if (!trigger) return;

  const state = open ? "open" : "closed";
  if (trigger.getAttribute("data-state") !== state) {
    trigger.setAttribute("data-state", state);
  }
  if (!expanded) return;

  if (trigger.getAttribute("aria-expanded") !== String(open)) {
    trigger.setAttribute("aria-expanded", String(open));
  }
  if (open && controls) {
    if (trigger.getAttribute("aria-controls") !== controls) {
      trigger.setAttribute("aria-controls", controls);
    }
  } else if (!open && trigger.hasAttribute("aria-controls")) {
    trigger.removeAttribute("aria-controls");
  }
}

/**
 * Watches the trigger an open instance is anchored to. `onRemoved` runs
 * once when it leaves the document (a stream delete or reset, a navigation);
 * `onPatched` runs when a LiveView patch puts its server-rendered
 * `data-state`/`aria-expanded` back, so the caller can re-apply its own.
 * Returns the stop function.
 */
export function watchTrigger(trigger, { onRemoved, onPatched } = {}) {
  const view = trigger?.ownerDocument?.defaultView;
  const Observer = view?.MutationObserver;
  if (!Observer || !trigger.ownerDocument.body) return () => {};

  const observer = new Observer((records) => {
    if (!trigger.isConnected) {
      observer.disconnect();
      onRemoved?.();
      return;
    }
    if (records.some((record) => record.target === trigger)) onPatched?.();
  });
  observer.observe(trigger.ownerDocument.body, {
    childList: true,
    subtree: true,
  });
  observer.observe(trigger, {
    attributes: true,
    attributeFilter: ["data-state", "aria-expanded"],
  });
  return () => observer.disconnect();
}

/**
 * Writes an open instance's context map onto elements as `phx-value-<key>`
 * attributes, so a plain `phx-click` (or a `JS.push` run from that element)
 * receives it: `%{id: 42}` arrives as `%{"id" => "42"}`. Values that are not
 * strings are JSON-encoded. `clear()` puts back what was there before.
 */
export class ContextValues {
  constructor() {
    // element -> Map<attribute, value before apply() (null: absent)>
    this.written = new Map();
  }

  apply(elements, context) {
    this.clear();
    if (!context || typeof context !== "object") return;

    const attributes = [];
    for (const [key, value] of Object.entries(context)) {
      if (value === null || value === undefined) continue;
      attributes.push([
        `phx-value-${key}`.toLowerCase(),
        typeof value === "string" ? value : JSON.stringify(value),
      ]);
    }
    if (attributes.length === 0) return;

    for (const el of elements) {
      if (!el?.setAttribute) continue;
      const saved = new Map();
      for (const [name, value] of attributes) {
        try {
          if (!saved.has(name)) saved.set(name, el.getAttribute(name));
          el.setAttribute(name, value);
        } catch {
          // Not a valid attribute name (e.g. a key with a space): skip it.
          saved.delete(name);
        }
      }
      if (saved.size > 0) this.written.set(el, saved);
    }
  }

  clear() {
    this.written.forEach((saved, el) => {
      saved.forEach((previous, name) => {
        if (previous === null) el.removeAttribute(name);
        else el.setAttribute(name, previous);
      });
    });
    this.written.clear();
  }

  get active() {
    return this.written.size > 0;
  }
}

/**
 * What a shared instance is open for: the detached trigger (or any element
 * an `open` command anchored it to) and its context map. Between
 * `activate()` and `release()` it mirrors the open state onto the trigger,
 * watches the trigger (`onRemoved` when it leaves the page) and writes the
 * context onto `targets()` as `phx-value-*`.
 *
 * Options:
 * - `expanded`: also set `aria-expanded`/`aria-controls` (not for a
 *   context menu area);
 * - `controls()`: the id `aria-controls` names;
 * - `targets()`: the elements that get the `phx-value-*`;
 * - `onRemoved()`: the trigger left the page while active.
 */
export class DetachedAnchor {
  constructor({
    expanded = true,
    controls = () => null,
    targets = () => [],
    onRemoved = () => {},
  } = {}) {
    this.options = { expanded, controls, targets, onRemoved };
    this.trigger = null;
    this.path = null;
    this.context = null;
    this.values = new ContextValues();
    this.generation = 0;
    this.stopWatching = null;
  }

  /** Point at `trigger` (null: none) with `context`; nothing is applied yet. */
  set(trigger, context = null) {
    this.trigger = trigger || null;
    this.path = trigger ? ancestry(trigger) : null;
    this.context = context ?? null;
  }

  /** Fields to hand to the instance a LiveView patch rebuilds. */
  snapshot() {
    return { trigger: this.trigger, path: this.path, context: this.context };
  }

  restore({ trigger = null, path = null, context = null } = {}) {
    this.trigger = trigger;
    this.path = path;
    this.context = context;
  }

  sync(open) {
    setTriggerState(this.trigger, open, {
      expanded: this.options.expanded,
      controls: this.options.controls(),
    });
  }

  /** The instance opened (or was rebuilt open) for this anchor. */
  activate() {
    this.sync(true);
    this.stopWatching?.();
    this.stopWatching = this.trigger
      ? watchTrigger(this.trigger, {
          onRemoved: () => this.options.onRemoved(),
          onPatched: () => this.sync(true),
        })
      : null;
    this.applyValues();
  }

  applyValues() {
    this.generation++;
    if (this.context) {
      this.values.apply(this.options.targets(), this.context);
    } else {
      this.values.clear();
    }
  }

  /**
   * The instance closed, or moves to another anchor. The `phx-value-*` stay
   * until the current event is done: an item's click closes the menu before
   * it bubbles to the window, where LiveView reads them for its
   * `phx-click`. `keepValues` leaves them for the next activate() instead.
   */
  release({ keepValues = false } = {}) {
    this.stopWatching?.();
    this.stopWatching = null;
    this.sync(false);
    this.set(null);
    if (keepValues || !this.values.active) return;

    const generation = ++this.generation;
    setTimeout(() => {
      if (generation === this.generation) this.values.clear();
    }, 0);
  }

  /** Remove the `phx-value-*` now (before a patch of the targets). */
  clearValues() {
    this.generation++;
    this.values.clear();
  }

  /**
   * The instance is torn down: undo everything on the page, keeping the
   * fields for a snapshot() already taken.
   */
  teardown() {
    this.stopWatching?.();
    this.stopWatching = null;
    this.sync(false);
    this.clearValues();
  }
}
