// saladui/components/resizable.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

const STORAGE_PREFIX = "salad-ui:resizable:";
const EPSILON = 0.001;
// Kept on the root element so a LiveView patch (which resets the panels'
// server-rendered styles and re-initialises the component) keeps the layout.
const LAYOUT_KEY = "__saladResizableLayout";

const round = (n) => Math.round(n * 1000) / 1000;
const sum = (list) => list.reduce((acc, n) => acc + n, 0);

function readNumber(value, fallback) {
  if (value === undefined || value === null || value === "") return fallback;
  const n = parseFloat(value);
  return Number.isFinite(n) ? n : fallback;
}

function byDocumentOrder(a, b) {
  return a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING
    ? -1
    : 1;
}

/**
 * Pure layout helpers (exported for tests). A layout is an array of panel
 * sizes in percent that sums to 100; constraints are [{min, max}].
 */
export function validateLayout(layout, constraints) {
  // Like react-resizable-panels, scale a layout that doesn't total 100 first.
  const total = sum(layout);
  const scaled =
    total > 0 && Math.abs(total - 100) > EPSILON
      ? layout.map((size) => (size / total) * 100)
      : layout;

  const next = scaled.map((size, i) =>
    Math.min(constraints[i].max, Math.max(constraints[i].min, size)),
  );

  // Hand any surplus/deficit to panels that still have room, in order.
  let remaining = 100 - sum(next);
  for (let i = 0; i < next.length && Math.abs(remaining) > EPSILON; i++) {
    const { min, max } = constraints[i];
    const room = remaining > 0 ? max - next[i] : min - next[i];
    const change =
      remaining > 0 ? Math.min(remaining, room) : Math.max(remaining, room);
    next[i] += change;
    remaining -= change;
  }

  return next.map(round);
}

/**
 * Move the handle after panel `pivot` by `delta` percent (positive grows the
 * panels before the handle). Mirrors react-resizable-panels: the panels
 * nearest the handle give/take space first and the change cascades outwards.
 */
export function adjustLayout(layout, constraints, pivot, delta) {
  const n = layout.length;
  if (Math.abs(delta) < EPSILON || pivot < 0 || pivot >= n - 1) {
    return [...layout];
  }

  const before = [];
  for (let i = pivot; i >= 0; i--) before.push(i);
  const after = [];
  for (let i = pivot + 1; i < n; i++) after.push(i);

  const growSide = delta > 0 ? before : after;
  const shrinkSide = delta > 0 ? after : before;

  const growable = sum(growSide.map((i) => constraints[i].max - layout[i]));
  const shrinkable = sum(shrinkSide.map((i) => layout[i] - constraints[i].min));
  const amount = Math.min(Math.abs(delta), growable, shrinkable);
  if (amount <= EPSILON) return [...layout];

  const next = [...layout];
  let remaining = amount;
  for (const i of shrinkSide) {
    const take = Math.min(remaining, next[i] - constraints[i].min);
    next[i] -= take;
    remaining -= take;
    if (remaining <= EPSILON) break;
  }

  remaining = amount;
  for (const i of growSide) {
    const give = Math.min(remaining, constraints[i].max - next[i]);
    next[i] += give;
    remaining -= give;
    if (remaining <= EPSILON) break;
  }

  return next.map(round);
}

class ResizableComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.orientation =
      this.options.orientation === "vertical" ? "vertical" : "horizontal";
    const step = readNumber(this.options.keyboardResizeBy, 10);
    this.keyboardResizeBy = step > 0 ? step : 10;
    this.autoSaveId = this.options.autoSaveId || null;

    this.panels = this.getAllParts("panel").sort(byDocumentOrder);
    this.handles = this.getAllParts("handle").sort(byDocumentOrder);
    this.constraints = this.panels.map((panel) => {
      const min = Math.max(0, readNumber(panel.dataset.minSize, 0));
      const max = Math.min(100, readNumber(panel.dataset.maxSize, 100));
      return { min, max: Math.max(min, max) };
    });
    // Index of the panel directly before each handle.
    this.pivots = new Map(
      this.handles.map((handle) => [
        handle,
        this.panels.filter((panel) => byDocumentOrder(panel, handle) === -1)
          .length - 1,
      ]),
    );

    this.drag = null;
    this.onPointerDown = this.onPointerDown.bind(this);
    this.onPointerMove = this.onPointerMove.bind(this);
    this.onPointerUp = this.onPointerUp.bind(this);
    this.onHandleKeyDown = this.onHandleKeyDown.bind(this);

    this.layout = this.resolveInitialLayout();
    this.signature = this.structureSignature();
    this.applyLayout();
    this.updateUI();
  }

  // What a LiveView patch must leave untouched for the live instance to be
  // reused: panel constraints/ids and handle disabled flags.
  structureSignature() {
    return JSON.stringify([
      this.panels.map((panel) => [
        panel.id,
        panel.dataset.minSize,
        panel.dataset.maxSize,
      ]),
      this.handles.map((handle) => handle.hasAttribute("data-disabled")),
    ]);
  }

  // An unrelated patch (e.g. content inside a panel re-rendering) resets the
  // panels' server-rendered styles and the handles' ARIA. Re-apply them on the
  // live instance instead of rebuilding it, so an in-progress drag survives.
  skipReinitialize(el) {
    if (
      el.dataset.options !== this._optionsRaw ||
      el.dataset.eventMappings !== this._eventMappingsRaw
    ) {
      return false;
    }

    const parts = this.queryParts();
    const same = (name, current) => {
      const found = parts
        .filter((part) => part.dataset.part === name)
        .sort(byDocumentOrder);
      return (
        found.length === current.length &&
        found.every((part, i) => part === current[i])
      );
    };
    if (!same("panel", this.panels) || !same("handle", this.handles)) {
      return false;
    }
    if (this.structureSignature() !== this.signature) return false;

    this.applyLayout();
    this.updateUI();
    this.drag?.handle.setAttribute("data-separator", "active");
    return true;
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: {
          transitions: { drag: "dragging" },
        },
        dragging: {
          enter: "onDraggingEnter",
          exit: "onDraggingExit",
          transitions: { end: "idle" },
        },
      },
      ariaConfig: {
        root: {
          all: {
            orientation: () => this.orientation,
          },
        },
        handle: {
          all: {
            role: "separator",
            // A separator's orientation is perpendicular to the panel axis.
            orientation: () =>
              this.orientation === "horizontal" ? "vertical" : "horizontal",
            controls: (handle) => this.panelBefore(handle)?.id || null,
            valuenow: (handle) =>
              this.handleValue(handle, (i) => this.layout[i]),
            valuemin: (handle) =>
              this.handleValue(handle, (i) => this.constraints[i].min),
            valuemax: (handle) =>
              this.handleValue(handle, (i) => this.constraints[i].max),
            disabled: (handle) =>
              this.isHandleDisabled(handle) ? "true" : null,
          },
        },
      },
    };
  }

  // --- layout -------------------------------------------------------------

  resolveInitialLayout() {
    if (!this.panels.length) return [];

    const candidates = [this.el[LAYOUT_KEY], this.loadPersistedLayout()];
    for (const candidate of candidates) {
      if (this.isUsableLayout(candidate)) {
        return validateLayout(candidate, this.constraints);
      }
    }

    return validateLayout(this.defaultLayout(), this.constraints);
  }

  defaultLayout() {
    const defaults = this.panels.map((panel) =>
      readNumber(panel.dataset.defaultSize, null),
    );
    const unsized = defaults.filter((size) => size === null).length;
    const leftover = Math.max(
      0,
      100 - sum(defaults.filter((size) => size !== null)),
    );
    return defaults.map((size) => (size === null ? leftover / unsized : size));
  }

  isUsableLayout(layout) {
    return (
      Array.isArray(layout) &&
      layout.length === this.panels.length &&
      layout.every((size) => typeof size === "number" && Number.isFinite(size))
    );
  }

  setLayout(layout) {
    this.layout = layout;
    this.applyLayout();
    this.ariaManager?.applyAriaAttributes(this.state);
  }

  applyLayout() {
    this.el[LAYOUT_KEY] = [...this.layout];
    this.panels.forEach((panel, i) => {
      panel.style.flexGrow = String(this.layout[i]);
      panel.style.flexShrink = "1";
      panel.style.flexBasis = "0px";
      // `clip`, not `hidden`: a hidden panel is still a scroll container, so
      // focusing an input inside it (iOS Safari, scrollIntoView) can scroll
      // the panel itself, and nothing lets the user scroll it back.
      // Browsers without `clip` keep the server-rendered `hidden`.
      panel.style.overflow = "clip";
      panel.setAttribute("data-size", String(this.layout[i]));
    });
  }

  commitLayout() {
    this.persistLayout();
    this.pushEvent("layout-change", { layout: [...this.layout] });
  }

  storageKey() {
    return this.autoSaveId ? `${STORAGE_PREFIX}${this.autoSaveId}` : null;
  }

  loadPersistedLayout() {
    const key = this.storageKey();
    if (!key) return null;
    try {
      const raw = window.localStorage.getItem(key);
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }

  persistLayout() {
    const key = this.storageKey();
    if (!key) return;
    try {
      window.localStorage.setItem(key, JSON.stringify(this.layout));
    } catch {
      // Storage can be unavailable (private mode, quota); persistence is optional.
    }
  }

  resizeAt(handle, delta, base = this.layout) {
    const pivot = this.pivots.get(handle);
    if (pivot === undefined) return false;

    const next = adjustLayout(base, this.constraints, pivot, delta);
    const changed = next.some(
      (size, i) => Math.abs(size - this.layout[i]) > EPSILON,
    );
    if (changed) this.setLayout(next);
    return changed;
  }

  // --- helpers -------------------------------------------------------------

  panelBefore(handle) {
    const pivot = this.pivots?.get(handle);
    return pivot === undefined ? null : this.panels[pivot];
  }

  handleValue(handle, read) {
    const pivot = this.pivots?.get(handle);
    if (pivot === undefined || pivot < 0 || !this.layout) return null;
    return String(Math.round(read(pivot)));
  }

  isHandleDisabled(handle) {
    return !!this.disabled || handle.hasAttribute("data-disabled");
  }

  // Only a horizontal group mirrors under RTL.
  isRtl() {
    return this.orientation === "horizontal" && super.isRtl();
  }

  pointerCoordinate(event) {
    const point = event.touches?.[0] || event;
    return this.orientation === "horizontal" ? point.clientX : point.clientY;
  }

  // Space shared by the panels: the group minus its handles.
  groupSize() {
    const axis = this.orientation === "horizontal" ? "width" : "height";
    const handles = sum(
      this.handles.map((handle) => handle.getBoundingClientRect()[axis] || 0),
    );
    return this.el.getBoundingClientRect()[axis] - handles;
  }

  // --- events ----------------------------------------------------------------

  setupComponentEvents() {
    super.setupComponentEvents();
    this.handles.forEach((handle) => {
      handle.addEventListener("pointerdown", this.onPointerDown);
      handle.addEventListener("keydown", this.onHandleKeyDown);
    });
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.handles.forEach((handle) => {
      handle.removeEventListener("pointerdown", this.onPointerDown);
      handle.removeEventListener("keydown", this.onHandleKeyDown);
    });
    this.removeDragListeners();
  }

  onPointerDown(event) {
    const handle = event.currentTarget;
    if (this.isHandleDisabled(handle)) return;
    if (event.button !== undefined && event.button !== 0) return;

    const size = this.groupSize();
    if (!(size > 0)) return;

    event.preventDefault();
    handle.focus?.({ preventScroll: true });

    this.drag = {
      handle,
      size,
      start: this.pointerCoordinate(event),
      startLayout: [...this.layout],
    };
    this.transition("drag");
  }

  onPointerMove(event) {
    if (!this.drag) return;
    event.preventDefault?.();

    let px = this.pointerCoordinate(event) - this.drag.start;
    if (this.isRtl()) px = -px;
    this.resizeAt(
      this.drag.handle,
      (px / this.drag.size) * 100,
      this.drag.startLayout,
    );
  }

  onPointerUp() {
    if (!this.drag) return;
    const changed = this.layout.some(
      (size, i) => Math.abs(size - this.drag.startLayout[i]) > EPSILON,
    );
    this.transition("end");
    if (changed) this.commitLayout();
  }

  onDraggingEnter() {
    const { handle } = this.drag;
    handle.setAttribute("data-separator", "active");

    const body = document.body;
    this.savedBodyStyle = {
      cursor: body.style.cursor,
      userSelect: body.style.userSelect,
    };
    body.style.cursor =
      this.orientation === "horizontal" ? "col-resize" : "row-resize";
    body.style.userSelect = "none";

    document.addEventListener("pointermove", this.onPointerMove);
    document.addEventListener("pointerup", this.onPointerUp);
    document.addEventListener("pointercancel", this.onPointerUp);
  }

  onDraggingExit() {
    this.drag?.handle.removeAttribute("data-separator");
    this.drag = null;
    this.removeDragListeners();
  }

  removeDragListeners() {
    document.removeEventListener("pointermove", this.onPointerMove);
    document.removeEventListener("pointerup", this.onPointerUp);
    document.removeEventListener("pointercancel", this.onPointerUp);

    if (this.savedBodyStyle) {
      document.body.style.cursor = this.savedBodyStyle.cursor;
      document.body.style.userSelect = this.savedBodyStyle.userSelect;
      this.savedBodyStyle = null;
    }
  }

  onHandleKeyDown(event) {
    const handle = event.currentTarget;

    if (event.key === "F6") {
      event.preventDefault();
      this.focusSiblingHandle(handle, event.shiftKey ? -1 : 1);
      return;
    }

    if (this.isHandleDisabled(handle)) return;

    const step = this.keyboardResizeBy;
    const horizontal = this.orientation === "horizontal";
    const forward = this.isRtl() ? -step : step;
    const deltas = horizontal
      ? { ArrowLeft: -forward, ArrowRight: forward }
      : { ArrowUp: -step, ArrowDown: step };
    deltas.Home = -100;
    deltas.End = 100;

    const delta = deltas[event.key];
    if (delta === undefined) return;

    event.preventDefault();
    if (this.resizeAt(handle, delta)) this.commitLayout();
  }

  focusSiblingHandle(handle, direction) {
    const count = this.handles.length;
    if (count < 2) return;
    const index = this.handles.indexOf(handle);
    this.handles[(index + direction + count) % count].focus();
  }

  // --- commands ----------------------------------------------------------

  handleCommand(command, params = {}) {
    if (command === "setLayout") {
      const layout = (params.layout || []).map((size) => parseFloat(size));
      if (!this.isUsableLayout(layout)) return false;
      this.setLayout(validateLayout(layout, this.constraints));
      this.persistLayout();
      return true;
    }
    return super.handleCommand(command, params);
  }

  beforeDestroy() {
    this.removeDragListeners();
  }
}

SaladUI.register("resizable", ResizableComponent);

export default ResizableComponent;
