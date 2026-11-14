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

// Subscription keys: an instance id (the triggers naming it in
// `data-salad-for`), or ATTR_KEY + an attribute name (every element carrying
// that attribute, e.g. a text tooltip's `data-salad-tooltip`).
const ATTR_KEY = "@";

function dispatch(event) {
  const byKey = subscriptions.get(event.type);
  if (!byKey || byKey.size === 0) return;

  const attributes = [];
  byKey.forEach((_handlers, key) => {
    if (key.startsWith(ATTR_KEY)) attributes.push(key.slice(ATTR_KEY.length));
  });

  // Walk up from the target like the event bubbles; each subscription hears
  // only about its innermost trigger.
  const seen = new Set();
  const notify = (key, el) => {
    if (seen.has(key)) return;
    seen.add(key);
    byKey.get(key)?.forEach((handler) => handler(event, el));
  };
  for (let el = elementOf(event.target); el; el = el.parentElement) {
    for (const id of triggerIds(el)) notify(id, el);
    for (const name of attributes) {
      if (el.hasAttribute(name)) notify(ATTR_KEY + name, el);
    }
  }
}

function subscribe(key, type, handler) {
  if (typeof document === "undefined") return () => {};

  if (!subscriptions.has(type)) subscriptions.set(type, new Map());
  const byKey = subscriptions.get(type);
  if (!byKey.has(key)) byKey.set(key, new Set());
  byKey.get(key).add(handler);

  if (!documentListeners.has(type)) {
    document.addEventListener(type, dispatch);
    documentListeners.set(type, document);
  }

  return () => {
    const handlers = byKey.get(key);
    handlers?.delete(handler);
    if (handlers?.size === 0) byKey.delete(key);
    if (byKey.size === 0) {
      documentListeners.get(type)?.removeEventListener(type, dispatch);
      documentListeners.delete(type);
      subscriptions.delete(type);
    }
  };
}

/**
 * Calls `handler(event, trigger)` for every `type` event (e.g. "click",
 * "keydown", "contextmenu") that reaches the document from inside a
 * detached trigger for `id`. One document listener per event type serves
 * every subscription. Returns the unsubscribe function.
 */
export function listen(id, type, handler) {
  if (!id) return () => {};
  return subscribe(id, type, handler);
}

/**
 * Like listen(), for every element carrying the attribute `name` instead of
 * the triggers of one instance (e.g. the text tooltips of a tooltip
 * provider: `data-salad-tooltip="Reply"`).
 */
export function listenAttribute(name, type, handler) {
  if (!name) return () => {};
  return subscribe(ATTR_KEY + name, type, handler);
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
  { expanded = true, controls = null, state = true, describedBy = null } = {},
) {
  if (!trigger) return;

  const value = open ? "open" : "closed";
  if (state && trigger.getAttribute("data-state") !== value) {
    trigger.setAttribute("data-state", value);
  }
  if (describedBy) toggleToken(trigger, "aria-describedby", describedBy, open);
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

/** Adds or removes `token` in a space-separated attribute (aria-describedby). */
export function toggleToken(el, name, token, present) {
  const tokens = (el.getAttribute(name) || "").split(/\s+/).filter(Boolean);
  if (present === tokens.includes(token)) return;

  const next = present
    ? [...tokens, token]
    : tokens.filter((existing) => existing !== token);
  if (next.length > 0) el.setAttribute(name, next.join(" "));
  else el.removeAttribute(name);
}

// Trigger attributes a LiveView patch may revert (the instance re-applies
// them), and those that change what the trigger stands for.
const STATE_ATTRS = ["data-state", "aria-expanded", "aria-describedby"];
const TARGET_ATTRS = [
  FOR_ATTR,
  CONTEXT_ATTR,
  "disabled",
  "aria-disabled",
  "data-disabled",
];

/**
 * Watches the trigger an open instance is anchored to. `onRemoved` runs
 * once when it leaves the document (a stream delete or reset, a navigation);
 * `onPatched` runs when a LiveView patch puts its server-rendered
 * `data-state`/`aria-expanded` back, so the caller can re-apply its own;
 * `onChanged` runs when its `data-salad-for`, `data-salad-context` or
 * disabled state (`disabled`, `aria-disabled`, `data-disabled`) changes,
 * e.g. a patch moved the row to another menu, disabled it, or changed what
 * it stands for. Returns the stop function.
 */
export function watchTrigger(
  trigger,
  { onRemoved, onPatched, onChanged } = {},
) {
  const view = trigger?.ownerDocument?.defaultView;
  const Observer = view?.MutationObserver;
  if (!Observer || !trigger.ownerDocument.body) return () => {};

  const observer = new Observer((records) => {
    if (!trigger.isConnected) {
      observer.disconnect();
      onRemoved?.();
      return;
    }
    const own = records.filter((record) => record.target === trigger);
    if (own.length === 0) return;

    onPatched?.();
    if (own.some((record) => TARGET_ATTRS.includes(record.attributeName))) {
      onChanged?.();
    }
  });
  observer.observe(trigger.ownerDocument.body, {
    childList: true,
    subtree: true,
  });
  observer.observe(trigger, {
    attributes: true,
    attributeFilter: [...STATE_ATTRS, ...TARGET_ATTRS],
  });
  return () => observer.disconnect();
}

// Element -> what it acts for while its shared instance is open (and until
// the event that closed it is done): `{trigger, context}`. Read by
// contextSourceOf() for the JS commands an item runs.
const sources = new WeakMap();

/**
 * Writes an open instance's context map onto elements as `phx-value-<key>`
 * attributes, so a plain `phx-click` (or a `JS.push` run from that element)
 * receives it: `%{id: 42}` arrives as `%{"id" => "42"}`. Values that are not
 * strings are JSON-encoded. With a `source` (`{trigger, context}`), the
 * elements are also registered for contextSourceOf(). `clear()` puts back
 * what was there before.
 */
export class ContextValues {
  constructor() {
    // element -> Map<attribute, value before apply() (null: absent)>
    this.written = new Map();
  }

  apply(elements, context, source = null) {
    this.clear();
    const hasContext = !!context && typeof context === "object";
    if (!hasContext && !source) return;

    const attributes = [];
    for (const [key, value] of Object.entries(hasContext ? context : {})) {
      if (value === null || value === undefined) continue;
      attributes.push([
        `phx-value-${key}`.toLowerCase(),
        typeof value === "string" ? value : JSON.stringify(value),
      ]);
    }
    if (attributes.length === 0 && !source) return;

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
      if (source) sources.set(el, source);
      if (saved.size > 0 || source) this.written.set(el, saved);
    }
  }

  clear() {
    this.written.forEach((saved, el) => {
      saved.forEach((previous, name) => {
        if (previous === null) el.removeAttribute(name);
        else el.setAttribute(name, previous);
      });
      sources.delete(el);
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
 * - `state`: mirror `data-state` (off for tooltips: their trigger is often a
 *   menu trigger too, whose `data-state` the menu owns);
 * - `describedBy()`: an id added to the trigger's `aria-describedby` while
 *   active (a tooltip's content);
 * - `targets()`: the elements that get the `phx-value-*`;
 * - `onRemoved()`: the trigger left the page while active;
 * - `id()`: the instance's root id, for `onLost`;
 * - `onLost()`: while active, the trigger stopped naming the instance in
 *   `data-salad-for`, or became disabled;
 * - `onContextChange(context)`: while active, the trigger's
 *   `data-salad-context` changed; the new context is already applied.
 */
export class DetachedAnchor {
  constructor({
    expanded = true,
    controls = () => null,
    state = true,
    describedBy = () => null,
    targets = () => [],
    onRemoved = () => {},
    id = () => null,
    onLost = () => {},
    onContextChange = () => {},
  } = {}) {
    this.options = {
      expanded,
      controls,
      state,
      describedBy,
      targets,
      onRemoved,
      id,
      onLost,
      onContextChange,
    };
    this.trigger = null;
    this.path = null;
    this.context = null;
    // What the trigger looked like when set(): its raw context attribute,
    // whether it named this instance, whether it was disabled.
    this.seen = null;
    this.values = new ContextValues();
    this.generation = 0;
    this.stopWatching = null;
    installContextCommands();
  }

  /** Point at `trigger` (null: none) with `context`; nothing is applied yet. */
  set(trigger, context = null) {
    this.trigger = trigger || null;
    this.path = trigger ? ancestry(trigger) : null;
    this.context = context ?? null;
    this.seen = trigger ? this.look(trigger) : null;
  }

  look(trigger) {
    const id = this.options.id();
    return {
      context: trigger.getAttribute?.(CONTEXT_ATTR) ?? null,
      named: !!id && isTriggerFor(trigger, id),
      disabled: isTriggerDisabled(trigger),
    };
  }

  /** Fields to hand to the instance a LiveView patch rebuilds. */
  snapshot() {
    return {
      trigger: this.trigger,
      path: this.path,
      context: this.context,
      seen: this.seen,
    };
  }

  restore({ trigger = null, path = null, context = null, seen = null } = {}) {
    this.trigger = trigger;
    this.path = path;
    this.context = context;
    this.seen = seen || (trigger ? this.look(trigger) : null);
  }

  /**
   * Compares the trigger with what it was when set(): "lost" when it no
   * longer names this instance (it did) or became disabled; "context" when
   * its `data-salad-context` changed, which then becomes the context (the
   * values are not re-applied: see activate()); null otherwise.
   */
  refresh() {
    const trigger = this.trigger;
    if (!trigger || !this.seen) return null;

    const now = this.look(trigger);
    if (
      (this.seen.named && !now.named) ||
      (!this.seen.disabled && now.disabled)
    ) {
      return "lost";
    }
    if (now.context === this.seen.context) return null;

    this.seen = { ...this.seen, context: now.context };
    this.context = readContext(trigger);
    return "context";
  }

  checkTrigger() {
    const change = this.refresh();
    if (change === "lost") {
      this.options.onLost();
    } else if (change === "context") {
      this.applyValues();
      this.options.onContextChange(this.context);
    }
  }

  sync(open) {
    setTriggerState(this.trigger, open, {
      expanded: this.options.expanded,
      controls: this.options.controls(),
      state: this.options.state,
      describedBy: this.options.describedBy(),
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
          onChanged: () => this.checkTrigger(),
        })
      : null;
    this.applyValues();
  }

  applyValues() {
    this.generation++;
    if (this.context || this.trigger) {
      this.values.apply(this.options.targets(), this.context, {
        trigger: this.trigger,
        context: this.context,
      });
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

// --- the context in JS commands ---------------------------------------------
//
// An item of a shared menu acts for the row its menu is open for. A JS
// command it runs gets that row through two placeholders in the params of
// `SaladUI.JS.dispatch_command/3` (resolved before the target component sees
// them) and through `SaladUI.JS.copy/2`:
//
//     {"__salad__": "context"}             the context map
//     {"__salad__": "context", "key": "id"} one of its values
//     {"__salad__": "trigger"}             the trigger element
//
// LiveView's `JS.dispatch` names the element that ran the command in
// `detail.dispatcher`: an item (or the menu root, for an `on-select` JS
// command), registered by ContextValues while its menu is open, or a
// detached trigger itself.

export const MARKER = "__salad__";

/**
 * What `node` acts for: `{trigger, context}` of the shared instance it is an
 * item of (while open, or until the event that closed it is done), else of
 * the detached trigger (an element with `data-salad-context`) it is in;
 * null otherwise.
 */
export function contextSourceOf(node) {
  const start = elementOf(node);
  for (let el = start; el; el = el.parentElement) {
    const source = sources.get(el);
    if (source) return source;
  }

  const trigger = start?.closest?.(`[${CONTEXT_ATTR}]`);
  return trigger ? { trigger, context: readContext(trigger) } : null;
}

function isMarker(value) {
  return (
    !!value &&
    typeof value === "object" &&
    !Array.isArray(value) &&
    typeof value[MARKER] === "string"
  );
}

function hasMarker(value) {
  if (isMarker(value)) return true;
  if (Array.isArray(value)) return value.some(hasMarker);
  if (value && typeof value === "object" && value.constructor === Object) {
    return Object.values(value).some(hasMarker);
  }
  return false;
}

/**
 * `value` with every placeholder replaced from `source` (contextSourceOf());
 * a placeholder resolves to null when there is no source or no such key.
 */
export function resolveContextParams(value, source) {
  if (isMarker(value)) {
    const context = source?.context ?? null;
    switch (value[MARKER]) {
      case "context":
        return value.key === undefined || value.key === null
          ? context
          : (context?.[value.key] ?? null);
      case "trigger":
        return source?.trigger ?? null;
      default:
        return null;
    }
  }
  if (Array.isArray(value)) {
    return value.map((entry) => resolveContextParams(entry, source));
  }
  if (value && typeof value === "object" && value.constructor === Object) {
    const resolved = {};
    for (const [key, entry] of Object.entries(value)) {
      resolved[key] = resolveContextParams(entry, source);
    }
    return resolved;
  }
  return value;
}

// Runs before the target's own listener (capture on the document), so the
// component sees resolved params.
function resolveCommand(event) {
  const detail = event.detail;
  if (!detail || !hasMarker(detail.params)) return;

  detail.params = resolveContextParams(
    detail.params,
    contextSourceOf(detail.dispatcher || null),
  );
}

/** The text `SaladUI.JS.copy/2` copies (see copyText()). */
export function textToCopy(detail = {}, origin = null) {
  const source = contextSourceOf(detail.dispatcher || origin);
  const text = resolveContextParams(detail.text, source);
  if (text !== null && text !== undefined) return String(text);

  // Relative to the row a shared menu item acts for, else to the element
  // that ran the command.
  const start = source?.trigger || elementOf(detail.dispatcher || origin);
  let scope = document;
  if (detail.within) {
    scope = start?.closest?.(detail.within);
    if (!scope) return null;
  }

  let el = detail.within ? scope : start;
  if (detail.from) {
    try {
      el = scope.querySelector(detail.from);
    } catch {
      el = null;
    }
  }
  if (!el) return null;

  const value = el.matches?.("input, textarea")
    ? el.value
    : (el.innerText ?? el.textContent);
  return (value ?? "").trim();
}

function copyText(event) {
  const text = textToCopy(event.detail || {}, event.target);
  const clipboard = globalThis.navigator?.clipboard;
  if (text === null || !clipboard?.writeText) return;

  clipboard.writeText(text).catch(() => {});
}

let installedOn = null;

/**
 * Installs the document listeners that resolve the context placeholders of
 * `salad_ui:command` events and run `salad_ui:copy` (once per document;
 * index.js and every shared instance call it).
 */
export function installContextCommands() {
  if (typeof document === "undefined" || installedOn === document) return;

  installedOn = document;
  document.addEventListener("salad_ui:command", resolveCommand, true);
  document.addEventListener("salad_ui:copy", copyText);
}
