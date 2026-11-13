// saladui/components/toast.js
import Component from "../core/component.js";
import { getDirection } from "../core/direction.js";
import SaladUI from "../index.js";

const DEFAULT_DURATION = 4000;
const DEFAULT_GAP = 14;
const COLLAPSED_SCALE_STEP = 0.05;
// Floor low enough that every card up through a 5-deep collapsed stack
// (the largest `visibleToasts` the storybook demo offers) still gets a
// distinct scale/width — a 0.9 floor made every card from index 2 on
// share the same width, so index 2/3/4 rendered with flush, un-tapered
// edges instead of a receding stack.
const MIN_COLLAPSED_SCALE = 0.75;
const EXIT_FALLBACK_MS = 500;
const SWIPE_THRESHOLD_PX = 45;
const SWIPE_VELOCITY_THRESHOLD = 0.11; // px/ms, matches Sonner's flick-to-dismiss
const SWIPE_EXIT_DISTANCE = "150%";
// Sonner's phone layout: full-width cards at the mobile offsets at or below
// 600px (`@media (max-width: 600px)`). The toaster's `breakpoint` moves it.
const DEFAULT_BREAKPOINT = 600;

// shadcn's Toaster icon set (lucide CircleCheck / Info / TriangleAlert /
// OctagonX / Loader2), inlined as SVG so the library carries no icon-font or
// sprite dependency. Each renders at size-4, like shadcn's `className="size-4"`.
const LUCIDE_PATHS = {
  success:
    '<circle cx="12" cy="12" r="10"></circle><path d="m9 12 2 2 4-4"></path>',
  info: '<circle cx="12" cy="12" r="10"></circle><path d="M12 16v-4"></path><path d="M12 8h.01"></path>',
  warning:
    '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"></path>' +
    '<path d="M12 9v4"></path><path d="M12 17h.01"></path>',
  error:
    '<path d="m15 9-6 6"></path>' +
    '<path d="M2.586 16.726A2 2 0 0 1 2 15.312V8.688a2 2 0 0 1 .586-1.414l4.688-4.688A2 2 0 0 1 8.688 2h6.624a2 2 0 0 1 1.414.586l4.688 4.688A2 2 0 0 1 22 8.688v6.624a2 2 0 0 1-.586 1.414l-4.688 4.688a2 2 0 0 1-1.414.586H8.688a2 2 0 0 1-1.414-.586z"></path>' +
    '<path d="m9 9 6 6"></path>',
  loading: '<path d="M21 12a9 9 0 1 1-6.219-8.56"></path>',
};

const LUCIDE_ICON_NAMES = {
  success: "circle-check",
  info: "info",
  warning: "triangle-alert",
  error: "octagon-x",
  loading: "loader-circle",
};

// Sonner's neutral card as shadcn themes it: --normal-bg: var(--popover),
// --normal-text: var(--popover-foreground), --normal-border: var(--border).
const NEUTRAL_CARD_CLASSES = "border-border bg-popover text-popover-foreground";

const CARD_BASE_CLASSES = [
  "group relative flex w-[var(--toast-width)] items-center gap-3 rounded-(--radius) border p-4 text-sm shadow-lg",
  "group-data-[mobile=true]/toast-viewport:w-full",
  "[&_svg]:shrink-0",
  "[transition:translate_300ms_ease-out,scale_300ms_ease-out,transform_300ms_ease-out,opacity_300ms_ease-out,height_300ms_ease-out,background-color_300ms_ease-out,border-color_300ms_ease-out,color_300ms_ease-out,box-shadow_200ms_ease-out]",
  "data-[swiping=true]:transition-none",
  "relative",
  "data-[front=false]:absolute data-[front=false]:inset-x-0",
  "data-[front=false]:data-[position^=bottom]:bottom-0",
  "data-[front=false]:data-[position^=top]:top-0",
  "[&>*]:transition-opacity [&>*]:duration-[300ms]",
  "group-data-[expanded=false]/toast-viewport:data-[front=false]:[&>*]:opacity-0",
  "group-data-[expanded=true]/toast-viewport:after:content-['']",
  "group-data-[expanded=true]/toast-viewport:after:absolute",
  "group-data-[expanded=true]/toast-viewport:after:inset-x-0",
  "group-data-[expanded=true]/toast-viewport:after:h-[calc(var(--toast-gap,14px)+1px)]",
  "group-data-[expanded=true]/toast-viewport:data-[position^=bottom]:after:bottom-full",
  "group-data-[expanded=true]/toast-viewport:data-[position^=top]:after:top-full",
  "data-[state=entering]:opacity-0",
  "data-[state=entering]:data-[position^=top]:-translate-y-full",
  "data-[state=entering]:data-[position^=bottom]:translate-y-full",
  "data-[state=visible]:opacity-100",
  "data-[state=visible]:translate-y-[var(--stack-y,0px)]",
  "data-[state=visible]:scale-[var(--scale,1)]",
  "data-[state=dismissing]:opacity-0",
  "data-[state=dismissing]:data-[position^=top]:-translate-y-full",
  "data-[state=dismissing]:data-[position^=bottom]:translate-y-full",
].join(" ");

const CLOSE_TRIGGER_CLASSES =
  "absolute end-0 top-0 -translate-y-1/2 translate-x-1/2 rtl:-translate-x-1/2 rounded-full p-0.5 flex items-center justify-center text-foreground/50 transition-colors " +
  "bg-background border border-border hover:text-foreground " +
  "focus-visible:outline-hidden focus-visible:ring-ring/50 focus-visible:ring-[3px]";

const ACTION_BUTTON_CLASSES =
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-xs font-medium " +
  "transition-colors focus-visible:ring-ring focus-visible:outline-hidden focus-visible:ring-1 " +
  "disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground shadow-xs " +
  "hover:bg-primary/90 h-7 px-2.5";

const CANCEL_BUTTON_CLASSES =
  "text-muted-foreground hover:text-foreground text-xs font-medium";

/**
 * Wraps setTimeout with pause()/resume(), recomputing the remaining delay
 * instead of tracking a separate hover/focus boolean.
 */
class Timer {
  constructor(callback, delay) {
    this.callback = callback;
    this.delay = delay;
    this.remaining = delay;
    this.timerId = null;
    this.startedAt = null;

    if (this.delay !== Infinity) this.start();
  }

  start() {
    if (this.delay === Infinity) return;
    this.startedAt = Date.now();
    this.timerId = setTimeout(this.callback, this.remaining);
  }

  pause() {
    if (this.timerId === null) return;
    clearTimeout(this.timerId);
    this.timerId = null;
    this.remaining -= Date.now() - this.startedAt;
  }

  resume() {
    if (this.timerId !== null || this.delay === Infinity) return;
    this.start();
  }

  clear() {
    if (this.timerId !== null) clearTimeout(this.timerId);
    this.timerId = null;
  }
}

// A loading toast never times out (Sonner skips its timer while
// `type === "loading"`, whatever `duration` says); it stays up until an
// update() resolves it to another variant or it is dismissed explicitly.
// Without a per-toast duration, the toaster's `duration` applies (Sonner's
// `toast.duration || durationFromToaster || TOAST_LIFETIME`).
function resolveDuration(params, variant, toasterDuration) {
  if (variant === "loading") return Infinity;
  for (const duration of [params.duration, toasterDuration]) {
    if (duration === "infinity" || duration === Infinity) return Infinity;
    if (typeof duration === "number") return duration;
  }
  return DEFAULT_DURATION;
}

// Sonner's `closeButton`: the per-toast value wins over the toaster's.
function resolveCloseButton(params, toasterCloseButton) {
  const own = params.closeButton ?? params.close_button;
  return typeof own === "boolean" ? own : Boolean(toasterCloseButton);
}

// Maps a key name from the `hotkey` option ("T", "1", "Escape") to the
// `KeyboardEvent.code` it is matched against. Matching the code, as Sonner
// does, keeps Option+T working on macOS, where `event.key` is "†".
export function hotkeyCode(key) {
  if (/^[a-z]$/i.test(key)) return `Key${key.toUpperCase()}`;
  if (/^[0-9]$/.test(key)) return `Digit${key}`;
  return key;
}

function lucideIcon(variant) {
  const spin = variant === "loading" ? " animate-spin" : "";
  return (
    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" ' +
    'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" ' +
    `stroke-linejoin="round" aria-hidden="true" class="lucide lucide-${LUCIDE_ICON_NAMES[variant]} size-4${spin}">` +
    LUCIDE_PATHS[variant] +
    "</svg>"
  );
}

// Toasts are announced through the toaster's polite live region, as in
// Sonner; `important: true` makes one card its own assertive region.
function resolveImportant(params) {
  return params.important === true;
}

// Payload pushed to the LiveView handling an action/cancel click. `value`
// carries arbitrary caller-supplied data through to the handler alongside
// the toast id — e.g. { action: { label: "Undo", event: "undo", value: %{item_id: 5} } }
// arrives server-side as %{"id" => toast_id, "item_id" => 5}. Nothing is
// added when `value` is omitted or isn't a plain object, so existing
// action/cancel payloads (just `{id}`) are unaffected. `id` is spread last so
// it stays authoritative even if `value` happens to contain its own `id` key.
function actionPayload(id, value) {
  return isPlainObject(value) ? { ...value, id } : { id };
}

function isPlainObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

// The phone layout keys on `data-mobile`, which the toaster sets from a
// media query at its `breakpoint` (a Tailwind breakpoint would be fixed at
// build time). Centred positions centre on `--toaster-center-x` (default
// 50%, the window), so an app can centre toasts on the content beside a
// sidebar. Keep in sync with SaladUI.Toast's viewport_class/1.
function viewportClasses(position) {
  const classes = [
    "group/toast-viewport fixed z-[9999] flex flex-col outline-hidden",
    "w-[var(--toast-width)] data-[mobile=true]:w-[calc(100%-var(--mobile-offset-l)-var(--mobile-offset-r))]",
  ];

  if (position.startsWith("top")) {
    classes.push(
      "flex-col-reverse top-[var(--offset-t)] data-[mobile=true]:top-[var(--mobile-offset-t)]",
    );
  } else {
    classes.push(
      "bottom-[var(--offset-b)] data-[mobile=true]:bottom-[var(--mobile-offset-b)]",
    );
  }

  if (position.endsWith("left")) {
    classes.push(
      "left-[var(--offset-l)] items-start rtl:items-end data-[mobile=true]:left-[var(--mobile-offset-l)]",
    );
  } else if (position.endsWith("right")) {
    classes.push(
      "right-[var(--offset-r)] items-end rtl:items-start data-[mobile=true]:right-[var(--mobile-offset-r)]",
    );
  } else {
    classes.push(
      "left-[var(--toaster-center-x,50%)] -translate-x-1/2 items-center data-[mobile=true]:left-[var(--mobile-offset-l)] data-[mobile=true]:translate-x-0",
    );
  }

  return classes.join(" ");
}

// Every direction the toast is allowed to swipe out in, mirroring Sonner's
// getDefaultSwipeDirections: both the vertical component implied by the
// toast's edge (top/bottom -> up/down) and the horizontal component
// (left/right). Center positions contribute no horizontal direction, so
// (matching real Sonner behavior, not the "always swipe right" heuristic
// this used to guess) horizontal drags on a centered toast never satisfy an
// allowed direction and are always rubber-banded back instead of dismissing.
function defaultSwipeDirections(position) {
  const [yPart, xPart] = position.split("-");
  const directions = [];
  if (yPart === "top") directions.push("up");
  if (yPart === "bottom") directions.push("down");
  if (xPart === "left") directions.push("left");
  if (xPart === "right") directions.push("right");
  return directions;
}

// Positions (and so the default swipe directions) are physical, as in
// Sonner: a bottom-right toaster sits bottom-right on an RTL page too. A
// configured `swipeDirection` may also be logical: "end" dismisses towards
// the end of the line (right in LTR, left in RTL), "start" towards its start.
export function resolveSwipeDirection(direction, dir) {
  if (direction === "end") return dir === "rtl" ? "left" : "right";
  if (direction === "start") return dir === "rtl" ? "right" : "left";
  return direction;
}

class ToastComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext, initialState: "idle" });

    this.viewport = this.getPart("viewport");
    // The phone layout's media query (see viewportClasses), watched from
    // setupComponentEvents.
    this.mobileQuery = this.createMobileQuery();
    this.stack = new Map(); // id -> record
    this.templates = new Map(); // name -> <template>
    this.viewports = new Map(); // position -> viewport element
    this._viewportListeners = new Map(); // viewport -> { expand, collapse }
    // Viewports currently hovered/focused. While any is, every timer stays
    // paused — including one armed by an add/update mid-hover (e.g. a
    // loading toast resolving under the pointer), as in Sonner.
    this._interacting = new Set();

    this.getAllParts("toast-template").forEach((tpl) => {
      if (tpl.dataset.name) this.templates.set(tpl.dataset.name, tpl);
    });

    if (this.viewport) {
      const position =
        this.options.position ||
        this.viewport.dataset.position ||
        "bottom-right";
      if (this.viewport.dataset.position !== position) {
        this.viewport.dataset.position = position;
      }
      this.viewport.className = viewportClasses(position);
      this.viewports.set(position, this.viewport);
      this.applyLayout(this.viewport);
      this.attachViewportInteractions(this.viewport);
    }

    this.el.__toastComponent = this;

    // Tracked from visibilitychange (not read off document.hidden directly)
    // so a toaster mounted in a tab that never fires the event keeps running.
    this._hidden = false;
    this.onVisibilityChange = () => {
      this._hidden = document.hidden;
      if (this.timersPaused()) {
        this.forEachTimer((timer) => timer.pause());
      } else {
        this.forEachTimer((timer) => timer.resume());
      }
    };

    this.onHotkey = (event) => this.handleHotkey(event);

    // Crossing the breakpoint changes the cards' width, so their heights.
    this.onMediaChange = () => {
      this.viewports.forEach((viewport) => this.applyLayout(viewport));
      this.stack.forEach((record) => {
        record.el.style.height = "";
        record.naturalHeight = record.el.offsetHeight;
      });
      this.viewports.forEach((viewport) =>
        this.recomputeStackPositions(viewport),
      );
    };
  }

  getComponentConfig() {
    return {
      // The landmark and live region is the server-rendered <section>
      // root; the viewports stay plain lists, as Sonner's <ol>s are.
      stateMachine: { idle: { transitions: {} } },
    };
  }

  // Skip the rebuild when data-options/data-event-mappings are unchanged —
  // avoids losing the live card stack and timers to an unrelated LiveView
  // patch (e.g. @flash changing elsewhere on the page).
  skipReinitialize(el) {
    return (
      el.dataset.options === this._optionsRaw &&
      el.dataset.eventMappings === this._eventMappingsRaw
    );
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    document.addEventListener("visibilitychange", this.onVisibilityChange);
    document.addEventListener("keydown", this.onHotkey);
    this.mobileQuery?.addEventListener?.("change", this.onMediaChange);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    document.removeEventListener("visibilitychange", this.onVisibilityChange);
    document.removeEventListener("keydown", this.onHotkey);
    this.mobileQuery?.removeEventListener?.("change", this.onMediaChange);
  }

  /** The px width at or below which the phone layout applies. */
  getBreakpoint() {
    const breakpoint = Number(this.options?.breakpoint);
    return Number.isFinite(breakpoint) && breakpoint > 0
      ? breakpoint
      : DEFAULT_BREAKPOINT;
  }

  createMobileQuery() {
    if (typeof window === "undefined" || typeof window.matchMedia !== "function")
      return null;
    return window.matchMedia(`(max-width: ${this.getBreakpoint()}px)`);
  }

  isMobile() {
    return this.mobileQuery?.matches === true;
  }

  applyLayout(viewport) {
    viewport.dataset.mobile = this.isMobile() ? "true" : "false";
  }

  beforeDestroy() {
    this.stack.forEach((record) => {
      record.timer?.clear();
      record.el.remove();
    });
    this.stack.clear();

    // Tear down viewport event listeners. Per-position viewports are
    // appended to document.body and outlive the component unless we
    // remove them — stale listeners would reference a destroyed
    // instance whose this.options is null.
    this._viewportListeners.forEach(({ expand, collapse }, viewport) => {
      viewport.removeEventListener("mouseenter", expand);
      viewport.removeEventListener("mouseleave", collapse);
      viewport.removeEventListener("focusin", expand);
      viewport.removeEventListener("focusout", collapse);

      if (viewport !== this.viewport && viewport.parentNode) {
        viewport.parentNode.removeChild(viewport);
      }
    });
    this._viewportListeners.clear();
    this._interacting.clear();

    if (this.el) this.el.__toastComponent = null;
  }

  handleCommand(command, params = {}) {
    switch (command) {
      case "add":
        return this.addToast(params);
      case "update":
        return this.updateToast(params);
      case "dismiss":
        return params.id
          ? this.dismissToast(params.id, "programmatic")
          : this.dismissAll();
      default:
        return super.handleCommand(command, params);
    }
  }

  forEachTimer(fn) {
    this.stack.forEach((record) => record.timer && fn(record.timer));
  }

  timersPaused() {
    return this._hidden || this._interacting.size > 0;
  }

  // Arms a dismiss timer for `id` (null for a sticky toast), born paused
  // when the stack is hovered/focused or the tab is hidden.
  armTimer(id, duration) {
    if (duration === Infinity) return null;
    const timer = new Timer(() => this.dismissToast(id, "timeout"), duration);
    if (this.timersPaused()) timer.pause();
    return timer;
  }

  generateId() {
    return `toast-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  }

  // -- viewport management -------------------------------------------------

  getOrCreateViewport(position) {
    if (this.viewports.has(position)) return this.viewports.get(position);

    const viewport = document.createElement("ol");
    viewport.dataset.part = "viewport";
    viewport.dataset.position = position;
    viewport.dataset.expanded = this.options.expand ? "true" : "false";
    viewport.setAttribute("data-salad-layer-branch", "");
    viewport.className = viewportClasses(position);
    this.applyLayout(viewport);
    if (this.viewport) viewport.style.cssText = this.viewport.style.cssText;

    // Inside the root <section>, as all of Sonner's lists are, so every
    // position is in the "Notifications" landmark and live region.
    this.el.appendChild(viewport);
    this.viewports.set(position, viewport);
    this.attachViewportInteractions(viewport);

    return viewport;
  }

  attachViewportInteractions(viewport) {
    if (viewport.dataset.expanded === undefined) {
      viewport.dataset.expanded = this.options.expand ? "true" : "false";
    }

    const expand = () => this.expandViewport(viewport);
    const collapse = (event) => {
      if (event?.relatedTarget && viewport.contains(event.relatedTarget))
        return;
      this.collapseViewport(viewport);
    };

    viewport.addEventListener("mouseenter", expand);
    viewport.addEventListener("mouseleave", collapse);
    viewport.addEventListener("focusin", expand);
    viewport.addEventListener("focusout", collapse);

    this._viewportListeners.set(viewport, { expand, collapse });
  }

  expandViewport(viewport) {
    this._interacting.add(viewport);
    viewport.dataset.expanded = "true";
    this.forEachTimer((timer) => timer.pause());
    this.recomputeStackPositions(viewport);
  }

  collapseViewport(viewport) {
    this._interacting.delete(viewport);
    if (!this.timersPaused()) this.forEachTimer((timer) => timer.resume());
    // An always-expanded toaster still resumes its timers on leave; it just
    // never collapses.
    if (this.options.expand) return;
    viewport.dataset.expanded = "false";
    this.recomputeStackPositions(viewport);
  }

  // -- add / update / dismiss ----------------------------------------------

  addToast(params = {}) {
    const id = params.id || this.generateId();

    if (this.stack.has(id)) {
      return this.updateToast({ ...params, id });
    }

    const variant = params.variant || "default";
    const position = params.position || this.options.position || "bottom-right";
    const viewport = this.getOrCreateViewport(position);
    const duration = resolveDuration(params, variant, this.options.duration);

    const card = this.buildCard(id, params, variant, position);
    card.dataset.state = "entering";
    viewport.appendChild(card);

    // Force layout so "entering" (the transition's start point) is computed
    // before we schedule the flip to "visible" — and, while forcing that
    // layout anyway, capture the card's real natural height. Every stacking
    // calculation below reads this stored value instead of a live
    // offsetHeight, since a card's rendered height can later reflect the
    // collapsed-stack clamp rather than its true content size.
    const naturalHeight = card.offsetHeight;

    // A single rAF isn't enough: it can still run before the browser has
    // ever painted "entering", so the transition has nothing to animate
    // from and the card just snaps straight to "visible". Two nested rAFs
    // guarantee a real painted frame in between — same trick core/utils.js's
    // executeAnimation() uses for every other component's transitions.
    requestAnimationFrame(() => {
      if (this.destroyed || !this.stack.has(id)) return;
      requestAnimationFrame(() => {
        if (this.destroyed || !this.stack.has(id)) return;
        card.dataset.state = "visible";
      });
    });

    const timer = this.armTimer(id, duration);

    this.stack.set(id, {
      id,
      el: card,
      variant,
      position,
      params,
      timer,
      naturalHeight,
      dismissible: params.dismissible !== false,
    });

    this.attachSwipeHandlers(card, id);
    this.recomputeStackPositions(viewport);

    return id;
  }

  updateToast(params = {}) {
    const { id } = params;
    if (!id) return;

    const record = this.stack.get(id);
    if (!record) return this.addToast(params);

    record.timer?.clear();

    const variant = params.variant || record.variant;

    const merged =
      variant === record.variant
        ? { ...record.params, ...params }
        : { ...record.params, ...params, duration: params.duration };

    record.el.style.height = "";
    this.populateCard(record.el, id, merged, variant, record.position);
    record.naturalHeight = record.el.offsetHeight;

    record.params = merged;
    record.variant = variant;
    record.dismissible = merged.dismissible !== false;

    record.timer = this.armTimer(
      id,
      resolveDuration(merged, variant, this.options.duration),
    );

    this.recomputeStackPositions(this.viewports.get(record.position));
  }

  dismissToast(id, reason = "programmatic", swipeDirection = null) {
    const record = this.stack.get(id);
    if (!record) return;

    record.timer?.clear();
    this.stack.delete(id);

    const { el, position } = record;
    el.dataset.state = "dismissing";
    if (swipeDirection) {
      el.dataset.swipeOut = swipeDirection;
      // A swipe-completed dismissal must keep exiting in the direction it
      // was dragged (any of up/down/left/right), not whatever direction the
      // position-based dismiss classes assume — so this inline transform
      // (which wins over the utility classes since it lives on the style
      // attribute) replaces the class-driven translate for this one exit.
      el.style.transform = {
        left: `translateX(-${SWIPE_EXIT_DISTANCE})`,
        right: `translateX(${SWIPE_EXIT_DISTANCE})`,
        up: `translateY(-${SWIPE_EXIT_DISTANCE})`,
        down: `translateY(${SWIPE_EXIT_DISTANCE})`,
      }[swipeDirection];
    }

    let done = false;
    const finish = () => {
      if (done) return;
      done = true;
      el.removeEventListener("transitionend", finish);
      el.remove();
      // The exit fallback can fire after the toaster was destroyed.
      if (this.destroyed) return;
      this.pushEvent("dismiss", { id, reason });
      this.recomputeStackPositions(this.viewports.get(position));
    };

    el.addEventListener("transitionend", finish, { once: true });
    setTimeout(finish, EXIT_FALLBACK_MS);

    this.recomputeStackPositions(this.viewports.get(position));
  }

  dismissAll() {
    Array.from(this.stack.keys()).forEach((id) =>
      this.dismissToast(id, "programmatic"),
    );
  }

  // -- stacking transform ---------------------------------------------------

  recomputeStackPositions(viewport) {
    if (!viewport) return;

    const visibleToasts = this.options.visibleToasts ?? 3;
    const expanded = viewport.dataset.expanded === "true";
    const anchorsBottom = !viewport.dataset.position?.startsWith("top");
    const gap = Number(this.options.gap) || DEFAULT_GAP;

    // Newest is the last DOM child (front); walk front-to-back. Every card
    // shares the same near edge (bottom-0/top-0, set by buildCard's
    // data-position class), and the viewport's own height tracks only the
    // (non-absolute) front card.
    const cards = Array.from(viewport.children).reverse();

    // Each card's real, unclamped content height — tracked in JS
    // (record.naturalHeight, refreshed on add/update) rather than measured
    // live here. A card mid-dismiss has already been dropped from
    // this.stack, so it falls back to a live read (fine, it's leaving).
    const naturalHeight = (card) =>
      this.stack.get(card.dataset.toastId)?.naturalHeight ?? card.offsetHeight;

    const heights = cards.map(naturalHeight);
    const frontHeight = heights[0] ?? 0;

    // Running sum of real heights of every card *ahead* of the current one
    // — Sonner's `toastsHeightBefore` — used for the expanded offset below.
    let heightAccum = 0;

    cards.forEach((card, index) => {
      card.dataset.front = index === 0 ? "true" : "false";
      card.style.zIndex = String(cards.length - index);

      if (index >= visibleToasts) {
        card.style.opacity = "0";
        card.style.pointerEvents = "none";
      } else {
        card.style.opacity = "";
        card.style.pointerEvents = "";
      }

      if (index === 0) {
        card.style.setProperty("--stack-y", "0px");
        card.style.setProperty("--scale", "1");
        card.style.height = `${heights[index]}px`;
      } else if (expanded) {
        const offsetPx = heightAccum + index * gap;
        card.style.setProperty(
          "--stack-y",
          `${anchorsBottom ? -offsetPx : offsetPx}px`,
        );
        card.style.setProperty("--scale", "1");
        card.style.height = `${heights[index]}px`;
      } else {
        const peek = index * gap;
        card.style.setProperty(
          "--stack-y",
          `${anchorsBottom ? -peek : peek}px`,
        );
        card.style.setProperty(
          "--scale",
          `${Math.max(1 - index * COLLAPSED_SCALE_STEP, MIN_COLLAPSED_SCALE)}`,
        );
        // Clamp collapsed background cards to the front card's height (and
        // fade their content via the CSS rule above) so a taller card peeks
        // as a clean sliver instead of visibly overflowing past the front
        // card — matches Sonner's `height: var(--front-toast-height)`.
        card.style.height = `${frontHeight}px`;
      }

      heightAccum += heights[index];
    });
  }

  // -- card building ----------------------------------------------------------

  buildCard(id, params, variant, position) {
    const card = document.createElement("li");
    card.dataset.part = "toast";
    card.dataset.toastId = id;
    card.id = `${this.el.id}-${id}`;
    card.tabIndex = -1;

    this.populateCard(card, id, params, variant, position);

    return card;
  }

  // Rewrites variant/content/attributes on an existing card element in
  // place, reusing the same node — used for both the initial build and for
  // update(). Recreating the element for update() instead (the first
  // version of this did) meant the browser never had a continuous element
  // to transition, so a variant swap always hard-cut instead of animating.
  //
  // NOTE: replaceChildren() + rebuild means any custom DOM listeners
  // attached to card children by external code are lost on update.
  // All internal handlers (actions, close, swipe) are re-attached
  // correctly — this only affects external consumers mutating the DOM.
  populateCard(card, id, params, variant, position) {
    const unstyled = !!params.unstyled;
    const important = resolveImportant(params);
    const dismissible = params.dismissible !== false;
    // Replaces NEUTRAL_CARD_CLASSES wholesale (border + background + text),
    // not just the text color — so a single `color`/`colors` value tints the
    // whole card (icon + title inherit its text color; description keeps its
    // own explicit text-muted-foreground) instead of fighting the default
    // border/bg classes for the same CSS properties.
    const colorClass = params.color || this.options.colors?.[variant] || "";

    card.dataset.variant = variant;
    card.dataset.position = position;
    // No role: a list item may not be a status or an alert (axe
    // aria-allowed-role). The toaster's section announces it.
    if (important) {
      card.setAttribute("aria-live", "assertive");
      card.setAttribute("aria-atomic", "true");
    } else {
      card.removeAttribute("aria-live");
      card.removeAttribute("aria-atomic");
    }

    if (!unstyled) {
      card.className = [
        CARD_BASE_CLASSES,
        colorClass || NEUTRAL_CARD_CLASSES,
        this.options.class,
        params.class,
      ]
        .filter(Boolean)
        .join(" ");
    } else {
      card.className = [colorClass, params.class].filter(Boolean).join(" ");
    }

    card.replaceChildren();

    // Like Sonner, never on a loading toast.
    if (
      variant !== "loading" &&
      resolveCloseButton(params, this.options.closeButton)
    ) {
      card.appendChild(this.buildCloseTrigger(id, dismissible));
    }

    const icon = this.buildIcon(params, variant);
    if (icon) card.appendChild(icon);

    // Content and the action/cancel row are two columns of the same row
    // (icon | content | actions), not stacked on separate lines — content
    // has flex-1 so it fills the remaining width and wraps normally if the
    // text is long, while the actions column stays a fixed, un-shrunk
    // width docked to the right (see buildActionsRow's shrink-0).
    card.appendChild(this.buildContent(params));

    const actionsRow = this.buildActionsRow(id, params);
    if (actionsRow) card.appendChild(actionsRow);

    if (dismissible) {
      delete card.dataset.dismissible;
    } else {
      card.dataset.dismissible = "false";
    }
  }

  // Icon has no color class of its own — the built-in lucide SVGs stroke
  // with `currentColor` and hero-* overrides are `background-color:
  // currentColor` (mask-based), so either picks up whatever color the card
  // resolved to (see populateCard's colorClass) by inheritance, same as the
  // title text does.
  //
  // `params.icon` / the toaster's `icons` option replace the built-in icon
  // with an icon class name (e.g. "hero-sparkles"); `icon: false` drops it.
  buildIcon(params, variant) {
    if (params.icon === false) return null;

    const override = params.icon || this.options.icons?.[variant];
    if (!override && !LUCIDE_PATHS[variant]) return null;

    const wrapper = document.createElement("span");
    wrapper.dataset.part = "icon";
    wrapper.className =
      "flex size-4 shrink-0 items-center justify-center self-center";

    if (override) {
      const span = document.createElement("span");
      span.className = [override, "size-4 shrink-0"].join(" ");
      wrapper.appendChild(span);
    } else {
      wrapper.innerHTML = lucideIcon(variant);
    }

    return wrapper;
  }

  buildContent(params) {
    const wrapper = document.createElement("div");
    wrapper.className = "flex-1 space-y-1";

    if (params.template) {
      const template = this.templates.get(params.template);
      if (template) {
        wrapper.appendChild(template.content.cloneNode(true));
        return wrapper;
      }
    }

    if (params.title) {
      const title = document.createElement("p");
      title.dataset.part = "title";
      title.className = "text-sm font-medium leading-none";
      title.textContent = params.title;
      wrapper.appendChild(title);
    }

    if (params.description) {
      const description = document.createElement("p");
      description.dataset.part = "description";
      description.className = "text-sm text-muted-foreground";
      description.textContent = params.description;
      wrapper.appendChild(description);
    }

    return wrapper;
  }

  buildCloseTrigger(id, dismissible = true) {
    const button = document.createElement("button");
    button.type = "button";
    button.dataset.part = "close-trigger";
    button.className = CLOSE_TRIGGER_CLASSES;
    button.setAttribute("aria-label", "Close toast");
    if (!dismissible) button.dataset.disabled = "true";
    button.innerHTML =
      '<svg xmlns="http://www.w3.org/2000/svg" width="6" height="6" viewBox="0 0 24 24" ' +
      'fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' +
      '<path d="M18 6 6 18"></path><path d="m6 6 12 12"></path></svg>';
    button.addEventListener("click", () => {
      if (this.stack.get(id)?.dismissible === false) return;
      this.dismissToast(id, "close-button");
    });

    return button;
  }

  buildActionsRow(id, params) {
    if (!params.action && !params.cancel) return null;

    const row = document.createElement("div");
    // shrink-0, not w-full: this row is a sibling of the content column in
    // the card's single flex row (icon | content | actions), not a
    // full-width block stacked below it. `w-full` there computed a
    // flex-basis of the *entire row's* width, squeezing the content column
    // down to almost nothing and wrapping the title far more than
    // necessary. shrink-0 keeps it pinned to its natural (small) button
    // width so content's flex-1 gets to claim the rest of the row.
    row.className = "flex shrink-0 items-center justify-end gap-2";

    if (params.cancel) {
      const cancel = document.createElement("button");
      cancel.type = "button";
      cancel.dataset.part = "cancel";
      cancel.className = CANCEL_BUTTON_CLASSES;
      cancel.textContent = params.cancel.label;
      cancel.addEventListener("click", () => {
        if (params.cancel.event)
          this.hook.pushEventTo(
            this.el,
            params.cancel.event,
            actionPayload(id, params.cancel.value),
          );
        this.dismissToast(id, "cancel");
      });
      row.appendChild(cancel);
    }

    if (params.action) {
      const action = document.createElement("button");
      action.type = "button";
      action.dataset.part = "action";
      action.className = ACTION_BUTTON_CLASSES;
      action.textContent = params.action.label;
      action.addEventListener("click", () => {
        if (params.action.event)
          this.hook.pushEventTo(
            this.el,
            params.action.event,
            actionPayload(id, params.action.value),
          );
        this.dismissToast(id, "action");
      });
      row.appendChild(action);
    }

    return row;
  }

  // -- swipe to dismiss -----------------------------------------------------

  attachSwipeHandlers(card, id) {
    const threshold = SWIPE_THRESHOLD_PX;
    // A configured swipeDirection is a narrow single-direction override;
    // otherwise both directions implied by the toast's corner are allowed
    // (e.g. bottom-right dismisses on a swipe down *or* right), matching
    // Sonner's getDefaultSwipeDirections.
    // Logical directions resolve against the card's reading direction on
    // each pointerdown, so a direction switched after the toast appeared is
    // still honoured.
    const resolveAllowedDirections = () =>
      this.options.swipeDirection
        ? [
            resolveSwipeDirection(
              this.options.swipeDirection,
              getDirection(card),
            ),
          ]
        : defaultSwipeDirections(card.dataset.position);
    let allowedDirections = resolveAllowedDirections();

    let dragging = false;
    // Locked on first move past 1px, like Sonner — whichever axis has the
    // larger delta at that moment owns the rest of the drag.
    let axis = null;
    let startX = 0;
    let startY = 0;
    let startTime = 0;
    let dx = 0;
    let dy = 0;

    // Rubber-band dampening for movement in a direction that isn't allowed
    // (e.g. dragging left when only "right" is allowed) — same curve Sonner
    // uses, so the card still visibly follows the pointer but resists.
    const dampen = (delta) => delta / (1.5 + Math.abs(delta) / 20);

    const onPointerDown = (event) => {
      const record = this.stack.get(id);
      // Like Sonner, a loading toast can't be swiped away mid-flight.
      if (
        !record ||
        record.dismissible === false ||
        record.variant === "loading"
      )
        return;
      if (
        event.target.closest(
          '[data-part="action"], [data-part="cancel"], [data-part="close-trigger"]',
        )
      ) {
        return;
      }

      dragging = true;
      axis = null;
      allowedDirections = resolveAllowedDirections();
      startX = event.clientX;
      startY = event.clientY;
      startTime = Date.now();
      card.dataset.swiping = "true";
      record.timer?.pause();
      card.setPointerCapture?.(event.pointerId);
    };

    const onPointerMove = (event) => {
      if (!dragging) return;
      const rawDx = event.clientX - startX;
      const rawDy = event.clientY - startY;

      if (!axis && (Math.abs(rawDx) > 1 || Math.abs(rawDy) > 1)) {
        axis = Math.abs(rawDx) > Math.abs(rawDy) ? "x" : "y";
      }
      if (!axis) return;

      if (axis === "x") {
        const allowed =
          (rawDx > 0 && allowedDirections.includes("right")) ||
          (rawDx < 0 && allowedDirections.includes("left"));
        dx = allowed ? rawDx : dampen(rawDx);
        dy = 0;
      } else {
        const allowed =
          (rawDy > 0 && allowedDirections.includes("down")) ||
          (rawDy < 0 && allowedDirections.includes("up"));
        dy = allowed ? rawDy : dampen(rawDy);
        dx = 0;
      }

      card.style.transform = `translate(${dx}px, ${dy}px)`;
    };

    const endDrag = () => {
      if (!dragging) return;
      dragging = false;
      card.dataset.swiping = "false";
      card.style.transform = "";

      const record = this.stack.get(id);
      const delta = axis === "x" ? dx : axis === "y" ? dy : 0;
      const elapsed = Math.max(Date.now() - startTime, 1);
      const velocity = Math.abs(delta) / elapsed;
      const direction =
        axis === "x"
          ? delta > 0
            ? "right"
            : "left"
          : delta > 0
            ? "down"
            : "up";

      const passesThreshold =
        Math.abs(delta) > threshold || velocity > SWIPE_VELOCITY_THRESHOLD;

      if (axis && passesThreshold && allowedDirections.includes(direction)) {
        this.dismissToast(id, "swipe", direction);
      } else {
        record?.timer?.resume();
      }

      axis = null;
      dx = 0;
      dy = 0;
    };

    card.addEventListener("pointerdown", onPointerDown);
    card.addEventListener("pointermove", onPointerMove);
    card.addEventListener("pointerup", endDrag);
    card.addEventListener("pointercancel", endDrag);
  }

  // -- hotkey -----------------------------------------------------------------

  handleHotkey(event) {
    const hotkey = this.options.hotkey ?? "Alt+T";
    if (!hotkey) return;
    const parts = hotkey.split("+").map((part) => part.trim());
    const modifiers = parts.slice(0, -1).map((part) => part.toLowerCase());
    const has = (...names) => names.some((name) => modifiers.includes(name));

    if (
      event.code !== hotkeyCode(parts.at(-1)) ||
      event.altKey !== has("alt", "option") ||
      event.shiftKey !== has("shift") ||
      event.ctrlKey !== has("ctrl", "control") ||
      event.metaKey !== has("meta", "cmd", "command")
    ) {
      return;
    }

    const frontCard = this.el.querySelector(
      '[data-part="toast"][data-front="true"]',
    );
    if (!frontCard) return;

    event.preventDefault();
    frontCard.focus();
  }
}

SaladUI.register("toast", ToastComponent);

/**
 * Client-only toast API, mirroring Sonner's `import { toast } from "sonner"`
 * ergonomics for pages/components that want to toast without a LiveView
 * round trip. Targets whichever `<.toaster>` mounted first on the page.
 */
function getToaster() {
  return (
    document.querySelector('[data-component="toast"]')?.__toastComponent || null
  );
}

function dispatchToast(variant, message, opts = {}) {
  const toaster = getToaster();
  if (!toaster) {
    console.error("SaladUI: toast() called but no <.toaster> is mounted");
    return null;
  }

  return toaster.handleCommand("add", { ...opts, variant, title: message });
}

function toast(message, opts) {
  return dispatchToast("default", message, opts);
}

toast.success = (message, opts) => dispatchToast("success", message, opts);
toast.error = (message, opts) => dispatchToast("error", message, opts);
toast.warning = (message, opts) => dispatchToast("warning", message, opts);
toast.info = (message, opts) => dispatchToast("info", message, opts);
toast.loading = (message, opts) => dispatchToast("loading", message, opts);
toast.message = (message, opts = {}) =>
  dispatchToast(opts.variant || "default", message, opts);

toast.dismiss = (id) => {
  getToaster()?.handleCommand("dismiss", id ? { id } : {});
};

toast.update = (id, opts = {}) => {
  getToaster()?.handleCommand("update", { ...opts, id });
};

/**
 * Sonner's `toast.promise`: shows a loading toast (if `loading` is given),
 * then morphs that same card into a success or error toast when the promise
 * settles. `success`/`error` are strings or functions of the resolved value /
 * rejection reason. A settled state with no matching message dismisses the
 * card, as in Sonner. Returns the toast id (or null with no toaster mounted).
 */
toast.promise = (promise, data = {}) => {
  const toaster = getToaster();
  if (!toaster) {
    console.error(
      "SaladUI: toast.promise() called but no <.toaster> is mounted",
    );
    return null;
  }

  const { loading, success, error, ...opts } = data;
  const id = opts.id || toaster.generateId();

  if (loading !== undefined) {
    toaster.handleCommand("add", {
      ...opts,
      id,
      variant: "loading",
      title: loading,
    });
  }

  const settle = (variant, message, arg) => {
    if (message === undefined) {
      toaster.handleCommand("dismiss", { id });
      return;
    }
    const title = typeof message === "function" ? message(arg) : message;
    toaster.handleCommand("update", { ...opts, id, variant, title });
  };

  // Wrapped so a promise factory that throws synchronously rejects (and
  // settles the card as an error) instead of escaping toast.promise().
  new Promise((resolve) =>
    resolve(typeof promise === "function" ? promise() : promise),
  ).then(
    (value) => settle("success", success, value),
    (reason) => settle("error", error, reason),
  );

  return id;
};

export default ToastComponent;
export { toast };
