// saladui/components/resizable.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

const STORAGE_PREFIX = "salad-ui:resizable:";
const EPSILON = 0.001;
// Kept on the root element so a LiveView patch (which resets the panels'
// server-rendered styles and re-initialises the component) keeps the layout.
const LAYOUT_KEY = "__saladResizableLayout";
const EXPAND_KEY = "__saladResizableExpandSizes";

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
 * sizes in percent that sums to 100; constraints are
 * [{min, max, collapsible, collapsedSize}].
 */

/**
 * The size a panel can take closest to `size` (react-resizable-panels'
 * resizePanel): clamped to [min, max], except that a collapsible panel below
 * its min snaps to its collapsed size when past halfway there, else to min.
 */
export function resizePanel(constraint, size) {
  const { min, max, collapsible = false, collapsedSize = 0 } = constraint;
  let next = size;
  if (next < min - EPSILON) {
    if (collapsible) {
      const halfway = collapsedSize + (min - collapsedSize) / 2;
      next = next < halfway ? collapsedSize : min;
    } else {
      next = min;
    }
  }
  return Math.min(max, next);
}

export function validateLayout(layout, constraints) {
  // Like react-resizable-panels, scale a layout that doesn't total 100 first.
  const total = sum(layout);
  const scaled =
    total > 0 && Math.abs(total - 100) > EPSILON
      ? layout.map((size) => (size / total) * 100)
      : layout;

  const next = scaled.map((size, i) => resizePanel(constraints[i], size));

  // Hand any surplus/deficit to panels that still have room, in order.
  let remaining = 100 - sum(next);
  for (let i = 0; i < next.length && Math.abs(remaining) > EPSILON; i++) {
    const size = resizePanel(constraints[i], next[i] + remaining);
    remaining -= size - next[i];
    next[i] = size;
  }

  return next.map(round);
}

/**
 * Move the handle after panel `pivot` by `delta` percent (positive grows the
 * panels before the handle), starting from `layout`. A port of
 * react-resizable-panels' adjustLayoutByDelta: the panels nearest the handle
 * give/take space first and the change cascades outwards; collapsible panels
 * snap between collapsed and their min size. With `trigger: "keyboard"` a
 * collapsed panel expands to its min, and a panel at its min collapses, on a
 * single step. Returns `prevLayout` (default `layout`) when nothing can move.
 */
export function adjustLayout(
  layout,
  constraints,
  pivot,
  delta,
  { trigger = "pointer", prevLayout = layout } = {},
) {
  const n = layout.length;
  if (pivot < 0 || pivot >= n - 1) return [...prevLayout];
  if (Math.abs(delta) < EPSILON) return [...layout];

  const first = pivot;
  const second = pivot + 1;
  const next = [...layout];

  if (trigger === "keyboard") {
    // Expand a collapsed panel on the growing side to its min in one step.
    const grow = delta < 0 ? second : first;
    const g = constraints[grow];
    if (g.collapsible && Math.abs(layout[grow] - g.collapsedSize) < EPSILON) {
      const local = g.min - layout[grow];
      if (local > Math.abs(delta)) delta = delta < 0 ? -local : local;
    }
    // Collapse a panel at its min on the shrinking side in one step.
    const shrink = delta < 0 ? first : second;
    const c = constraints[shrink];
    if (c.collapsible && Math.abs(layout[shrink] - c.min) < EPSILON) {
      const local = layout[shrink] - c.collapsedSize;
      if (local > Math.abs(delta)) delta = delta < 0 ? -local : local;
    }
  }

  // How much the growing side can take.
  {
    const step = delta < 0 ? 1 : -1;
    let available = 0;
    for (let i = delta < 0 ? second : first; i >= 0 && i < n; i += step) {
      available += resizePanel(constraints[i], 100) - layout[i];
    }
    const amount = Math.min(Math.abs(delta), Math.abs(available));
    delta = delta < 0 ? -amount : amount;
  }

  // Take it from the shrinking side, nearest panel first.
  let applied = 0;
  {
    const step = delta < 0 ? -1 : 1;
    for (let i = delta < 0 ? first : second; i >= 0 && i < n; i += step) {
      const remaining = Math.abs(delta) - Math.abs(applied);
      const size = resizePanel(constraints[i], layout[i] - remaining);
      if (Math.abs(size - layout[i]) > EPSILON) {
        applied += layout[i] - size;
        next[i] = size;
        if (applied >= Math.abs(delta) - EPSILON) break;
      }
    }
  }

  if (next.every((size, i) => Math.abs(size - prevLayout[i]) < EPSILON)) {
    return [...prevLayout];
  }

  // Give it to the growing side: the panel at the handle, then outwards.
  {
    const grow = delta < 0 ? second : first;
    const unsafe = layout[grow] + applied;
    const size = resizePanel(constraints[grow], unsafe);
    next[grow] = size;
    let remaining = unsafe - size;
    const step = delta > 0 ? -1 : 1;
    for (
      let i = grow;
      i >= 0 && i < n && Math.abs(remaining) > EPSILON;
      i += step
    ) {
      const resized = resizePanel(constraints[i], next[i] + remaining);
      if (Math.abs(resized - next[i]) > EPSILON) {
        remaining -= resized - next[i];
        next[i] = resized;
      }
    }
  }

  if (Math.abs(sum(next) - 100) > EPSILON * 10) return [...prevLayout];
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
      const collapsible = panel.dataset.collapsible === "true";
      const collapsedSize = Math.min(
        min,
        Math.max(0, readNumber(panel.dataset.collapsedSize, 0)),
      );
      return { min, max: Math.max(min, max), collapsible, collapsedSize };
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
        panel.dataset.collapsible,
        panel.dataset.collapsedSize,
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
        // No aria-orientation on the group: it has no role that allows one
        // (react-resizable-panels sets it on the separators only).
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
              this.handleValue(handle, (i) =>
                this.constraints[i].collapsible
                  ? this.constraints[i].collapsedSize
                  : this.constraints[i].min,
              ),
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
      if (this.constraints[i].collapsible) {
        panel.toggleAttribute("data-collapsed", this.isCollapsed(i));
      }
    });
  }

  isCollapsed(index) {
    const constraint = this.constraints[index];
    return (
      !!constraint?.collapsible &&
      Math.abs(this.layout[index] - constraint.collapsedSize) < EPSILON
    );
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

  resizeAt(handle, delta, base = this.layout, trigger = "pointer") {
    const pivot = this.pivots.get(handle);
    if (pivot === undefined) return false;
    return this.resizeAtPivot(pivot, delta, base, trigger);
  }

  resizeAtPivot(pivot, delta, base = this.layout, trigger = "pointer") {
    const next = adjustLayout(base, this.constraints, pivot, delta, {
      trigger,
      prevLayout: this.layout,
    });
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

    if (event.key === "Enter") {
      // As in react-resizable-panels: collapse the panel before the handle,
      // or expand it to its min size, when it is collapsible.
      event.preventDefault();
      const pivot = this.pivots.get(handle);
      const constraint = this.constraints[pivot];
      if (!constraint?.collapsible) return;
      const size = this.layout[pivot];
      const delta = this.isCollapsed(pivot)
        ? constraint.min - constraint.collapsedSize
        : constraint.collapsedSize - size;
      if (this.resizeAtPivot(pivot, delta, this.layout, "keyboard")) {
        this.commitLayout();
      }
      return;
    }

    const delta = deltas[event.key];
    if (delta === undefined) return;

    event.preventDefault();
    if (this.resizeAt(handle, delta, this.layout, "keyboard")) {
      this.commitLayout();
    }
  }

  focusSiblingHandle(handle, direction) {
    const count = this.handles.length;
    if (count < 2) return;
    const index = this.handles.indexOf(handle);
    this.handles[(index + direction + count) % count].focus();
  }

  // --- commands ----------------------------------------------------------

  /** A panel by id, or by index when `ref` is a number. */
  panelIndex(ref) {
    if (typeof ref === "number") {
      return ref >= 0 && ref < this.panels.length ? ref : -1;
    }
    return this.panels.findIndex((panel) => panel.id && panel.id === ref);
  }

  /**
   * Collapse a collapsible panel (react-resizable-panels' `collapse()`),
   * remembering its size for expandPanel(). The space goes to its neighbour
   * (the one before it for the last panel).
   */
  collapsePanel(index) {
    const constraint = this.constraints[index];
    if (!constraint?.collapsible || this.isCollapsed(index)) return false;

    const size = this.layout[index];
    const last = index === this.panels.length - 1;
    const pivot = last ? index - 1 : index;
    const delta = last
      ? size - constraint.collapsedSize
      : constraint.collapsedSize - size;
    const sizes = this.expandSizes();
    sizes[index] = size;
    return this.resizeAtPivot(pivot, delta, this.layout, "imperative-api");
  }

  /**
   * Expand a collapsed panel (react-resizable-panels' `expand()`) to the
   * size it had before collapsePanel(), or to its min size.
   */
  expandPanel(index) {
    const constraint = this.constraints[index];
    if (!constraint?.collapsible || !this.isCollapsed(index)) return false;

    const previous = this.expandSizes()[index];
    const target =
      typeof previous === "number" && previous >= constraint.min
        ? previous
        : constraint.min;
    const size = this.layout[index];
    const last = index === this.panels.length - 1;
    const pivot = last ? index - 1 : index;
    const delta = last ? size - target : target - size;
    return this.resizeAtPivot(pivot, delta, this.layout, "imperative-api");
  }

  // Sizes to expand collapsed panels back to; kept on the root like the
  // layout, so they survive a rebuild after a LiveView patch.
  expandSizes() {
    if (!this.el[EXPAND_KEY]) this.el[EXPAND_KEY] = {};
    return this.el[EXPAND_KEY];
  }

  handleCommand(command, params = {}) {
    if (command === "collapse" || command === "expand") {
      const index = this.panelIndex(params.panel ?? params.index);
      if (index < 0) return false;
      const changed =
        command === "collapse"
          ? this.collapsePanel(index)
          : this.expandPanel(index);
      if (changed) this.commitLayout();
      return changed;
    }
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
