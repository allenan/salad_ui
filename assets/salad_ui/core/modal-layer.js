// saladui/core/modal-layer.js
/**
 * Radix-style modal behaviour shared by every modal surface (dialog, sheet,
 * alert dialog, drawer, a modal dropdown menu). While a modal layer is open:
 *
 * - Outside pointer events are disabled, as Radix's DismissableLayer does
 *   with `disableOutsidePointerEvents`: `<body>` gets `pointer-events: none`
 *   and the layer's elements `pointer-events: auto`, so a click outside the
 *   layer can only dismiss it (via its overlay, or a click that lands on
 *   `<html>`), never activate what is underneath.
 * - Everything outside the layer is hidden from assistive technology, as the
 *   `aria-hidden` package's `hideOthers()` does for Radix: the siblings of
 *   the layer and of each of its ancestors up to `<body>` get
 *   `aria-hidden="true"` (and a `data-aria-hidden` marker). `aria-live`
 *   regions and scripts are left alone. Elements that already carried
 *   `aria-hidden` keep it after the layer closes.
 * - Wheel and touch scrolling outside the layer is cancelled, as
 *   react-remove-scroll does, so the page behind (including an inner scroll
 *   container of the app's layout) cannot scroll through the overlay. Inside
 *   the layer a gesture is let through while the scrollable element under
 *   the pointer can still scroll that way; pinch-zoom is never blocked.
 * - Page scrolling is locked through `lockScroll()` (see scroll-lock.js).
 *
 * Layers stack in the order they open. Only the topmost open modal layer
 * blocks: anything opened above it (a non-modal layer, a closing nested
 * modal) stays interactive and visible, and closing it hands blocking back to
 * the modal below. Content portaled out of a layer with `Portal.move()` (a
 * select, popover or combobox list opened from a dialog) counts as part of
 * that layer.
 *
 * Elements marked `data-salad-layer-branch` (the toast viewport) stay
 * interactive and exposed above every modal layer, like the toasts Radix
 * renders as their own layers above an open dialog.
 *
 *   const layer = new ModalLayer(() => [contentEl], { modal: true });
 *   layer.activate();            // on open (idempotent)
 *   layer.releaseInteraction();  // when it starts closing: unblock the page
 *   layer.deactivate();          // once closed: release the scroll lock too
 *
 * A non-modal layer (`modal: false`) blocks nothing and locks nothing; it
 * only takes its place in the stack.
 *
 * LiveView patches put the server-rendered attributes back, which drops the
 * `aria-hidden` and inline `pointer-events` written here. While any layer
 * blocks, a MutationObserver on `<body>` re-applies them after every patch,
 * and recomputes which elements to hide when nodes are added or removed.
 * `refresh()` re-applies synchronously.
 */
import Portal from "./portal.js";
import { lockScroll } from "./scroll-lock.js";

// Marks the nodes hidden by a modal layer, as the aria-hidden package does.
const MARKER = "data-aria-hidden";
// Always above the modal layers (see the header).
const BRANCH_SELECTOR = "[data-salad-layer-branch]";

// Open layers, in the order they were activated.
const stack = [];

// <body>'s own inline pointer-events, saved while blocking.
let savedBody = null;
// Layer elements given `pointer-events: auto` -> their own inline value.
const pointerOwned = new Map();
// Nodes outside the layer -> { uncontrolled } (aria-hidden before we came).
const hiddenOwned = new Map();
// Elements interactive while blocking: the topmost modal layer, the layers
// above it, and whatever was portaled out of them.
let allowed = [];

let observer = null;
let syncScheduled = false;
let listeningDocument = null;
let touchStart = [0, 0];

function readInline(el, property) {
  return {
    value: el.style.getPropertyValue(property),
    priority: el.style.getPropertyPriority(property),
    hadStyle: el.hasAttribute("style"),
  };
}

function writeInline(el, property, saved) {
  if (saved.value) {
    el.style.setProperty(property, saved.value, saved.priority);
  } else {
    el.style.removeProperty(property);
  }
  if (!saved.hadStyle && el.getAttribute("style") === "") {
    el.removeAttribute("style");
  }
}

function layerElements(entry) {
  return [].concat(entry.getElements() || []).filter((el) => el?.isConnected);
}

function topModalIndex() {
  for (let index = stack.length - 1; index >= 0; index -= 1) {
    const entry = stack[index];
    if (entry.modal && entry.blocking && layerElements(entry).length) {
      return index;
    }
  }
  return -1;
}

// The element a node logically sits in: a portaled element's original
// parent, else its DOM parent.
function logicalParent(node) {
  return Portal.originalParent(node) || node.parentElement;
}

function logicallyInside(node, containers) {
  for (let current = node; current; current = logicalParent(current)) {
    if (containers.has(current)) return true;
  }
  return false;
}

function computeAllowed(index) {
  const base = new Set(stack.slice(index).flatMap(layerElements));
  const portaled = Portal.portaledElements().filter(
    (el) => !base.has(el) && logicallyInside(el, base),
  );
  const branches = [...document.querySelectorAll(BRANCH_SELECTOR)].filter(
    (el) => !base.has(el),
  );
  return [...base, ...portaled, ...branches];
}

// --- pointer events --------------------------------------------------------

function applyPointerEvents(body) {
  if (savedBody?.body !== body) {
    restoreBody();
    savedBody = { body, ...readInline(body, "pointer-events") };
  }
  if (body.style.getPropertyValue("pointer-events") !== "none") {
    body.style.setProperty("pointer-events", "none");
  }

  for (const [el, saved] of pointerOwned) {
    if (allowed.includes(el)) continue;
    writeInline(el, "pointer-events", saved);
    pointerOwned.delete(el);
  }
  for (const el of allowed) {
    if (!pointerOwned.has(el)) {
      pointerOwned.set(el, readInline(el, "pointer-events"));
    }
    if (el.style.getPropertyValue("pointer-events") !== "auto") {
      el.style.setProperty("pointer-events", "auto");
    }
  }
}

function restoreBody() {
  if (!savedBody) return;
  writeInline(savedBody.body, "pointer-events", savedBody);
  savedBody = null;
}

// --- aria-hidden -----------------------------------------------------------

function nodesToHide(body) {
  const targets = [
    ...allowed,
    ...body.querySelectorAll("[aria-live], script"),
  ].filter((el) => body.contains(el));
  const keep = new Set();
  targets.forEach((target) => {
    for (let node = target; node && node !== body; node = node.parentNode) {
      keep.add(node);
    }
  });
  const stop = new Set(targets);
  const hide = new Set();

  const walk = (parent) => {
    if (stop.has(parent)) return;
    for (const child of parent.children) {
      if (keep.has(child)) {
        walk(child);
      } else {
        hide.add(child);
      }
    }
  };
  walk(body);

  return hide;
}

function unhide(node, { uncontrolled }) {
  if (!uncontrolled) node.removeAttribute("aria-hidden");
  node.removeAttribute(MARKER);
}

function applyAriaHidden(body) {
  const hide = nodesToHide(body);

  for (const [node, state] of hiddenOwned) {
    if (hide.has(node)) continue;
    unhide(node, state);
    hiddenOwned.delete(node);
  }

  for (const node of hide) {
    let state = hiddenOwned.get(node);
    if (!state) {
      const current = node.getAttribute("aria-hidden");
      state = { uncontrolled: current !== null && current !== "false" };
      hiddenOwned.set(node, state);
    }
    if (!state.uncontrolled && node.getAttribute("aria-hidden") !== "true") {
      node.setAttribute("aria-hidden", "true");
    }
    if (!node.hasAttribute(MARKER)) node.setAttribute(MARKER, "true");
  }
}

// --- wheel / touch ---------------------------------------------------------

const SCROLLING = ["auto", "scroll", "overlay"];

function canScrollOnAxis(node, axis) {
  if (node.tagName === "TEXTAREA") return true;
  const style = window.getComputedStyle(node);
  return SCROLLING.includes(axis === "v" ? style.overflowY : style.overflowX);
}

// Whether some element from `target` up to `container` can still scroll by
// `delta` along `axis` (react-remove-scroll's handleScroll, without letting
// the gesture chain past the layer).
function canScroll(target, container, axis, delta) {
  for (let node = target; node; node = node.parentElement) {
    if (canScrollOnAxis(node, axis)) {
      let position;
      let room;
      if (axis === "v") {
        position = node.scrollTop;
        room = node.scrollHeight - node.clientHeight - position;
      } else {
        const rtl = window.getComputedStyle(node).direction === "rtl";
        position = rtl ? -node.scrollLeft : node.scrollLeft;
        room = node.scrollWidth - node.clientWidth - position;
      }
      if (delta > 0 ? room >= 1 : position >= 1) return true;
    }
    if (node === container) break;
  }
  return false;
}

function shouldCancel(event) {
  const touches = event.touches;
  // Pinch zoom (a ctrl+wheel, or two fingers) is always allowed.
  if (event.type === "wheel" ? event.ctrlKey : touches?.length > 1) {
    return false;
  }

  const target = event.target;
  if (!target || target.nodeType !== 1) return true;
  const container = allowed.find((el) => el.contains(target));
  if (!container) return true;

  let dx;
  let dy;
  if (event.type === "wheel") {
    dx = event.deltaX;
    dy = event.deltaY;
  } else {
    const touch = event.changedTouches?.[0] || touches?.[0];
    if (!touch) return false;
    dx = touchStart[0] - touch.clientX;
    dy = touchStart[1] - touch.clientY;
  }

  const axis = Math.abs(dx) > Math.abs(dy) ? "h" : "v";
  const delta = axis === "h" ? dx : dy;
  if (!delta) return false;
  if (event.type !== "wheel") {
    // A horizontal swipe on a range input moves its thumb, not the page.
    if (axis === "h" && target.type === "range") return false;
    // Extending a text selection by dragging (iOS).
    const selection = window.getSelection?.();
    const anchor = selection?.isCollapsed ? null : selection?.anchorNode;
    if (anchor && (anchor === target || anchor.contains(target))) return false;
  }

  return !canScroll(target, container, axis, delta);
}

function onScrollGesture(event) {
  if (event.cancelable && shouldCancel(event)) event.preventDefault();
}

function onTouchStart(event) {
  const touch = event.changedTouches?.[0] || event.touches?.[0];
  touchStart = touch ? [touch.clientX, touch.clientY] : [0, 0];
}

const NON_PASSIVE = { passive: false };

function startListening(doc) {
  if (listeningDocument === doc) return;
  stopListening();
  doc.addEventListener("wheel", onScrollGesture, NON_PASSIVE);
  doc.addEventListener("touchmove", onScrollGesture, NON_PASSIVE);
  doc.addEventListener("touchstart", onTouchStart, NON_PASSIVE);
  listeningDocument = doc;
}

function stopListening() {
  if (!listeningDocument) return;
  listeningDocument.removeEventListener("wheel", onScrollGesture, NON_PASSIVE);
  listeningDocument.removeEventListener(
    "touchmove",
    onScrollGesture,
    NON_PASSIVE,
  );
  listeningDocument.removeEventListener(
    "touchstart",
    onTouchStart,
    NON_PASSIVE,
  );
  listeningDocument = null;
}

// --- re-applying after patches ----------------------------------------------

function relevant(record) {
  return (
    record.type === "childList" ||
    record.target === savedBody?.body ||
    pointerOwned.has(record.target) ||
    hiddenOwned.has(record.target)
  );
}

function scheduleSync() {
  if (syncScheduled) return;
  syncScheduled = true;
  queueMicrotask(() => {
    syncScheduled = false;
    sync();
  });
}

function startObserving(body) {
  if (observer?.body === body) return;
  stopObserving();
  const Observer = body.ownerDocument.defaultView?.MutationObserver;
  if (!Observer) return;

  const instance = new Observer((records) => {
    if (records.some(relevant)) scheduleSync();
  });
  instance.observe(body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["aria-hidden", "style"],
  });
  observer = { instance, body };
}

function stopObserving() {
  observer?.instance.disconnect();
  observer = null;
}

// --- sync --------------------------------------------------------------------

function restoreAll() {
  for (const [el, saved] of pointerOwned)
    writeInline(el, "pointer-events", saved);
  pointerOwned.clear();
  for (const [node, state] of hiddenOwned) unhide(node, state);
  hiddenOwned.clear();
  restoreBody();
  allowed = [];
  stopObserving();
  stopListening();
}

/**
 * Bring the page in line with the open layers: block and hide everything
 * outside the topmost modal one, or undo it all when none is open.
 */
export function sync() {
  if (typeof document === "undefined") return;

  const body = document.body;
  const index = topModalIndex();
  if (!body || index === -1) {
    restoreAll();
    return;
  }

  allowed = computeAllowed(index);
  applyPointerEvents(body);
  applyAriaHidden(body);
  startObserving(body);
  startListening(document);
  // Our own writes need no second pass.
  observer?.instance.takeRecords();
}

/**
 * One layer of the modal stack, owned by a component instance. `getElements`
 * returns the layer's element(s), read on every sync so a part re-read after
 * a patch is picked up.
 */
export class ModalLayer {
  constructor(getElements, { modal = true } = {}) {
    this.getElements =
      typeof getElements === "function" ? getElements : () => getElements;
    this.modal = modal;
    this.entry = null;
    this.releaseScroll = null;
  }

  /** Whether the layer is in the stack (open, or closing). */
  get active() {
    return this.entry !== null;
  }

  /** Whether the layer currently blocks the page. */
  get blocking() {
    return Boolean(this.modal && this.entry?.blocking);
  }

  /**
   * Open the layer, or make a closing one block again (re-opened during its
   * exit animation). Idempotent: never stacks a second entry or scroll lock.
   */
  activate() {
    if (this.entry) {
      this.entry.blocking = true;
    } else {
      this.entry = {
        getElements: this.getElements,
        modal: this.modal,
        blocking: true,
      };
      stack.push(this.entry);
    }
    if (this.modal && !this.releaseScroll) this.releaseScroll = lockScroll();
    sync();
  }

  /**
   * Stop blocking the page while the layer animates out (Radix drops
   * `disableOutsidePointerEvents` as soon as a dialog closes). The scroll
   * lock is kept until deactivate().
   */
  releaseInteraction() {
    if (!this.entry?.blocking) return;
    this.entry.blocking = false;
    sync();
  }

  /** Remove the layer and release its scroll lock. Idempotent. */
  deactivate() {
    if (this.entry) {
      const index = stack.indexOf(this.entry);
      if (index !== -1) stack.splice(index, 1);
      this.entry = null;
      sync();
    }
    this.releaseScroll?.();
    this.releaseScroll = null;
  }

  /** Re-apply the page state now, e.g. right after a LiveView patch. */
  refresh() {
    if (this.entry) sync();
  }
}

/** Number of layers in the stack (open or closing). */
export function modalLayerCount() {
  return stack.length;
}

/** Whether some modal layer currently blocks the page. */
export function isModalBlocking() {
  return topModalIndex() !== -1;
}

/**
 * Drop every layer and restore the page. For test teardown and for apps that
 * swap the whole document; components deactivate their own layers.
 */
export function resetModalLayers() {
  stack.length = 0;
  syncScheduled = false;
  restoreAll();
}
