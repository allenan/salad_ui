// saladui/components/slider.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

// Fallback thumb size (px, `size-4`) when the thumb cannot be measured yet,
// e.g. while the slider is inside a hidden panel.
const DEFAULT_THUMB_SIZE = 16;

const PAGE_KEYS = ["PageUp", "PageDown"];
const ARROW_KEYS = ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"];

// Keys that move a thumb towards `min`, per start edge (mirrors Radix).
const BACK_KEYS = {
  left: ["Home", "PageDown", "ArrowDown", "ArrowLeft"],
  right: ["Home", "PageDown", "ArrowDown", "ArrowRight"],
  bottom: ["Home", "PageDown", "ArrowDown", "ArrowLeft"],
  top: ["Home", "PageDown", "ArrowUp", "ArrowLeft"],
};

const END_EDGE = { left: "right", right: "left", bottom: "top", top: "bottom" };

const THUMB_TRANSFORM = {
  left: "translateX(-50%)",
  right: "translateX(50%)",
  bottom: "translateY(50%)",
  top: "translateY(-50%)",
};

function decimalCount(value) {
  const [, fraction = ""] = String(value).split(".");
  if (/e-(\d+)/.test(String(value))) {
    return Number(String(value).match(/e-(\d+)/)[1]) + fraction.length;
  }
  return fraction.length;
}

function roundValue(value, decimals) {
  const rounder = Math.pow(10, decimals);
  return Math.round(value * rounder) / rounder;
}

class SliderComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.track = this.getPart("track");
    this.range = this.getPart("range");
    this.thumbs = this.getAllParts("thumb");
    this.inputs = Array.from(
      this.el.querySelectorAll(':scope > input[type="hidden"]'),
    );

    this.parseValues();

    // Last value the server rendered. A LiveView patch that re-renders the
    // same value must not throw away what the user picked since (see
    // skipReinitialize); a different value is a deliberate server update.
    this._serverValue = this.el.dataset.value;

    // Index of the thumb being dragged / last changed.
    this.activeIndex = 0;

    this.onPointerDown = this.onPointerDown.bind(this);
    this.onPointerMove = this.onPointerMove.bind(this);
    this.onPointerUp = this.onPointerUp.bind(this);
    this.onKeyDown = this.onKeyDown.bind(this);

    this.updateUI();
    this.updatePosition();
  }

  parseValues() {
    this.min = parseFloat(this.options.min ?? 0);
    this.max = parseFloat(this.options.max ?? 100);
    this.step = parseFloat(this.options.step ?? 1);
    if (!Number.isFinite(this.min)) this.min = 0;
    if (!Number.isFinite(this.max)) this.max = 100;
    if (!Number.isFinite(this.step) || this.step <= 0) this.step = 1;

    this.decimals = Math.max(decimalCount(this.step), decimalCount(this.min));
    this.minStepsBetweenThumbs =
      parseInt(this.options.minStepsBetweenThumbs ?? 0, 10) || 0;
    this.orientation =
      this.options.orientation === "vertical" ? "vertical" : "horizontal";
    this.dir = this.options.dir === "rtl" ? "rtl" : "ltr";
    this.inverted = !!this.options.inverted;
    this.disabled = !!this.options.disabled;
    this.startEdge = this.computeStartEdge();

    const raw = this.el.dataset.value;
    const fallback = this.options.defaultValue;
    let values;

    if (raw !== undefined && raw !== null && raw !== "") {
      values = String(raw).split(",");
    } else if (Array.isArray(fallback) && fallback.length) {
      values = fallback;
    } else if (fallback !== undefined && fallback !== null) {
      values = [fallback];
    } else {
      values = [this.min];
    }

    this.values = values
      .map((value) => parseFloat(value))
      .map((value) => (Number.isFinite(value) ? value : this.min))
      .map((value) => this.snapToStep(value))
      .sort((a, b) => a - b);
  }

  computeStartEdge() {
    if (this.orientation === "vertical") {
      return this.inverted ? "top" : "bottom";
    }
    const rtl = this.dir === "rtl";
    return rtl !== this.inverted ? "right" : "left";
  }

  // Backwards-compatible accessor for single-thumb sliders.
  get value() {
    return this.values[0];
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: {
          transitions: {
            drag: "dragging",
          },
        },
        dragging: {
          enter: "onDraggingEnter",
          exit: "onDraggingExit",
          transitions: {
            end: "idle",
          },
        },
      },
      events: {},
      ariaConfig: {
        thumb: {
          all: {
            role: "slider",
            valuemin: () => this.formatNumber(this.min),
            valuemax: () => this.formatNumber(this.max),
            valuenow: (part) => this.formatNumber(this.valueForThumb(part)),
            orientation: () => this.orientation,
            disabled: () => (this.disabled ? "true" : null),
          },
        },
      },
    };
  }

  valueForThumb(part) {
    const index = this.thumbs ? this.thumbs.indexOf(part) : -1;
    return this.values?.[index < 0 ? 0 : index];
  }

  formatNumber(value) {
    if (value === undefined || value === null) return null;
    return String(roundValue(value, this.decimals ?? 0));
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    this.el.addEventListener("mousedown", this.onPointerDown);
    this.el.addEventListener("touchstart", this.onPointerDown, {
      passive: false,
    });
    this.el.addEventListener("keydown", this.onKeyDown);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.el.removeEventListener("mousedown", this.onPointerDown);
    this.el.removeEventListener("touchstart", this.onPointerDown);
    this.el.removeEventListener("keydown", this.onKeyDown);
    this.removeDocumentListeners();
  }

  onDraggingEnter() {
    document.addEventListener("mousemove", this.onPointerMove);
    document.addEventListener("touchmove", this.onPointerMove, {
      passive: false,
    });
    document.addEventListener("mouseup", this.onPointerUp);
    document.addEventListener("touchend", this.onPointerUp);
  }

  onDraggingExit() {
    this.removeDocumentListeners();
  }

  removeDocumentListeners() {
    document.removeEventListener("mousemove", this.onPointerMove);
    document.removeEventListener("touchmove", this.onPointerMove);
    document.removeEventListener("mouseup", this.onPointerUp);
    document.removeEventListener("touchend", this.onPointerUp);
  }

  // ---- Pointer -------------------------------------------------------------

  onPointerDown(event) {
    if (this.disabled) return;
    if (event.button !== undefined && event.button !== 0) return;

    event.preventDefault();

    const value = this.valueFromPointer(event);
    if (value === null) return;

    // Grab the thumb under the pointer, otherwise the closest one.
    const thumb = event.target.closest?.('[data-part="thumb"]');
    const thumbIndex = thumb ? this.thumbs.indexOf(thumb) : -1;
    this.activeIndex =
      thumbIndex >= 0 ? thumbIndex : this.closestValueIndex(value);
    this.valuesAtDragStart = this.values.slice();

    this.transition("drag");
    if (thumbIndex < 0) this.updateValues(value, this.activeIndex);
    this.thumbs[this.activeIndex]?.focus();
  }

  onPointerMove(event) {
    if (this.disabled) return;
    event.preventDefault();

    const value = this.valueFromPointer(event);
    if (value === null) return;
    this.updateValues(value, this.activeIndex);
  }

  onPointerUp() {
    this.transition("end");
    if (this.disabled) return;

    const before = this.valuesAtDragStart || [];
    this.valuesAtDragStart = null;
    if (String(before) !== String(this.values)) {
      this.commit(this.activeIndex);
    }
  }

  valueFromPointer(event) {
    const point = event.touches?.[0] || event.changedTouches?.[0] || event;
    const rect = this.track.getBoundingClientRect();
    let ratio;

    if (this.orientation === "vertical") {
      if (rect.height === 0) return null;
      ratio =
        this.startEdge === "top"
          ? (point.clientY - rect.top) / rect.height
          : (rect.bottom - point.clientY) / rect.height;
    } else {
      if (rect.width === 0) return null;
      ratio =
        this.startEdge === "right"
          ? (rect.right - point.clientX) / rect.width
          : (point.clientX - rect.left) / rect.width;
    }

    ratio = Math.max(0, Math.min(1, ratio));
    return this.min + ratio * (this.max - this.min);
  }

  closestValueIndex(value) {
    if (this.values.length === 1) return 0;
    const distances = this.values.map((v) => Math.abs(v - value));
    const closest = Math.min(...distances);
    const index = distances.indexOf(closest);
    // Several thumbs stacked on the same value: pick the one that can move
    // towards the pointer.
    const last = distances.lastIndexOf(closest);
    return value > this.values[index] ? last : index;
  }

  // ---- Keyboard ------------------------------------------------------------

  onKeyDown(event) {
    const thumb = event.target.closest?.('[data-part="thumb"]');
    if (!thumb || !this.el.contains(thumb)) return;

    const index = this.thumbs.indexOf(thumb);
    if (index < 0) return;

    const { key } = event;
    const isArrow = ARROW_KEYS.includes(key);
    const isPage = PAGE_KEYS.includes(key);
    if (!isArrow && !isPage && key !== "Home" && key !== "End") return;

    event.preventDefault();
    if (this.disabled) return;

    let next;
    if (key === "Home") {
      next = this.min;
    } else if (key === "End") {
      next = this.max;
    } else {
      const back = BACK_KEYS[this.startEdge].includes(key);
      const multiplier = isPage || (isArrow && event.shiftKey) ? 10 : 1;
      next = this.values[index] + (back ? -1 : 1) * this.step * multiplier;
    }

    const changedIndex = this.updateValues(next, index);
    if (changedIndex !== null) this.commit(changedIndex);
  }

  // ---- Value updates -------------------------------------------------------

  snapToStep(value) {
    if (value <= this.min) return this.min;
    if (value >= this.max) return this.max;

    const snapped =
      this.min + Math.round((value - this.min) / this.step) * this.step;

    return Math.max(
      this.min,
      Math.min(this.max, roundValue(snapped, this.decimals)),
    );
  }

  hasMinStepsBetweenValues(values) {
    if (this.minStepsBetweenThumbs <= 0 || values.length < 2) return true;
    const minDistance = this.minStepsBetweenThumbs * this.step;
    for (let i = 1; i < values.length; i++) {
      // Tolerate float noise (e.g. 0.30000000000000004 - 0.2).
      if (values[i] - values[i - 1] < minDistance - 1e-9) return false;
    }
    return true;
  }

  /**
   * Moves the thumb at `atIndex` to `rawValue` (snapped and clamped), keeps
   * values sorted and moves focus to the thumb now holding that value.
   * Returns the new index of the moved thumb, or null when nothing changed.
   */
  updateValues(rawValue, atIndex) {
    const next = this.snapToStep(rawValue);
    const nextValues = this.values.slice();
    nextValues[atIndex] = next;
    nextValues.sort((a, b) => a - b);

    if (!this.hasMinStepsBetweenValues(nextValues)) return null;
    if (String(nextValues) === String(this.values)) return null;

    const newIndex =
      nextValues[atIndex] === next ? atIndex : nextValues.indexOf(next);
    this.values = nextValues;
    this.activeIndex = newIndex;

    this.syncDom();

    const focused = this.el.ownerDocument.activeElement;
    if (this.thumbs.includes(focused) && focused !== this.thumbs[newIndex]) {
      this.thumbs[newIndex]?.focus();
    }

    return newIndex;
  }

  setValues(values) {
    const list = (Array.isArray(values) ? values : [values])
      .map((value) => parseFloat(value))
      .filter((value) => Number.isFinite(value))
      .map((value) => this.snapToStep(value))
      .sort((a, b) => a - b);

    if (!list.length) return;

    // Keep the rendered thumb count; extra values are ignored, missing ones kept.
    this.values = this.values.map((current, i) => list[i] ?? current);
    this.values.sort((a, b) => a - b);
    this.syncDom();
  }

  syncDom() {
    this.updatePosition();
    this.ariaManager.applyAriaAttributes(this.state);
    this.el.dataset.value = this.values
      .map((v) => this.formatNumber(v))
      .join(",");
    this.inputs.forEach((input, i) => {
      if (this.values[i] !== undefined) {
        input.value = this.formatNumber(this.values[i]);
      }
    });
  }

  commit(index) {
    const input = this.inputs[index] || this.inputs[0];
    if (input) {
      // LiveView only forwards phx-change from form-associated event targets.
      input.dispatchEvent(new Event("change", { bubbles: true }));
    }

    const values = this.values.slice();
    this.pushEvent("value-changed", {
      value: values.length === 1 ? values[0] : values,
      values,
    });
  }

  // ---- Layout --------------------------------------------------------------

  percentOf(value) {
    if (this.max === this.min) return 0;
    return ((value - this.min) / (this.max - this.min)) * 100;
  }

  thumbSize() {
    const thumb = this.thumbs[0];
    if (!thumb) return DEFAULT_THUMB_SIZE;
    const rect = thumb.getBoundingClientRect();
    const size = this.orientation === "vertical" ? rect.height : rect.width;
    return size > 0 ? size : DEFAULT_THUMB_SIZE;
  }

  updatePosition() {
    const edge = this.startEdge;
    const endEdge = END_EDGE[edge];
    const percents = this.values.map((value) => this.percentOf(value));
    const rangeStart = percents.length > 1 ? Math.min(...percents) : 0;
    const rangeEnd = 100 - Math.max(...percents);

    if (this.range) {
      this.range.style.left = "";
      this.range.style.right = "";
      this.range.style.top = "";
      this.range.style.bottom = "";
      this.range.style[edge] = `${rangeStart}%`;
      this.range.style[endEdge] = `${rangeEnd}%`;
    }

    const half = this.thumbSize() / 2;
    this.thumbs.forEach((thumb, i) => {
      const pct = percents[i] ?? 0;
      // Keep the thumb inside the track: centre at `half` for 0%, at
      // `100% - half` for 100% (Radix's in-bounds offset).
      const offset = half * (1 - pct / 50);
      thumb.style.left = "";
      thumb.style.right = "";
      thumb.style.top = "";
      thumb.style.bottom = "";
      thumb.style[edge] = `calc(${pct}% + ${offset}px)`;
      thumb.style.transform = THUMB_TRANSFORM[edge];
    });
  }

  // ---- LiveView patches ----------------------------------------------------

  /**
   * A LiveView patch reverts the attributes this component wrote (data-value,
   * thumb/range styles, aria-valuenow, hidden input values) to whatever the
   * server rendered. When the server still renders the value it rendered last
   * time (it never stored the user's pick, e.g. a static `value={50}` with an
   * unrelated re-render) and the markup is otherwise unchanged, keep this
   * instance and re-apply the current values, so the slider does not jump
   * back and an in-progress drag survives. A new server value, new options,
   * or a different thumb count rebuilds the component from the server state.
   */
  skipReinitialize(el) {
    if (el !== this.el) return false;
    if (el.dataset.options !== this._optionsRaw) return false;
    if (el.dataset.eventMappings !== this._eventMappingsRaw) return false;
    if (!this.sameParts(el)) return false;
    if (el.dataset.value !== this._serverValue && this.state !== "dragging") {
      return false;
    }

    this.updateUI();
    this.syncDom();
    return true;
  }

  sameParts(el) {
    const thumbs = el.querySelectorAll('[data-part="thumb"]');
    const inputs = el.querySelectorAll(':scope > input[type="hidden"]');
    return (
      el.querySelector('[data-part="track"]') === this.track &&
      el.querySelector('[data-part="range"]') === this.range &&
      thumbs.length === this.thumbs.length &&
      Array.from(thumbs).every((thumb, i) => thumb === this.thumbs[i]) &&
      inputs.length === this.inputs.length &&
      Array.from(inputs).every((input, i) => input === this.inputs[i])
    );
  }

  // ---- Commands ------------------------------------------------------------

  handleCommand(command, params) {
    if (command === "setValue") {
      this.setValues(params.value);
      return true;
    }
    return super.handleCommand(command, params);
  }

  beforeDestroy() {
    this.removeDocumentListeners();
  }
}

SaladUI.register("slider", SliderComponent);

export default SliderComponent;
