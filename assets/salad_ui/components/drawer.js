// saladui/components/drawer.js
//
// A vaul-style drawer: a modal dialog that slides in from an edge of the
// viewport and can be dragged back out to dismiss it, optionally resting at
// intermediate snap points. Open/close, focus trap, Escape and overlay click
// come from DialogComponent; this class adds direction, dragging and snap
// points.
import DialogComponent from "./dialog.js";
import SaladUI from "../index.js";

const DIRECTIONS = ["top", "right", "bottom", "left"];

// Fraction of the draggable distance past which a release dismisses.
const CLOSE_THRESHOLD = 0.25;
// Release speed (px/ms) that counts as a flick.
const VELOCITY_THRESHOLD = 0.4;
// Movement (px) before a press becomes a drag, so taps still reach buttons.
const DRAG_START_THRESHOLD = 5;
// Matches vaul's settle animation.
const SETTLE_TRANSITION = "0.5s cubic-bezier(0.32, 0.72, 0, 1)";

const NO_DRAG_SELECTOR =
  "input, textarea, select, [contenteditable=''], [contenteditable='true'], [data-vaul-no-drag]";

class DrawerComponent extends DialogComponent {
  constructor(el, hookContext) {
    super(el, hookContext);

    this.direction = DIRECTIONS.includes(this.options.direction)
      ? this.options.direction
      : "bottom";
    this.snapPoints = Array.isArray(this.options.snapPoints)
      ? this.options.snapPoints
      : [];
    this.initialSnapIndex = this.findSnapIndex(this.options.activeSnapPoint);
    this.activeSnapIndex = this.initialSnapIndex;
    this.dismissible = this.options.dismissible !== false;
    this.overlay = this.getPart("overlay");

    this.onPointerDown = this.onPointerDown.bind(this);
    this.onPointerMove = this.onPointerMove.bind(this);
    this.onPointerUp = this.onPointerUp.bind(this);
    this.suppressClick = this.suppressClick.bind(this);

    this.stampDirection();
  }

  getComponentConfig() {
    const config = super.getComponentConfig();

    config.ariaConfig["close-trigger"] = { all: { label: "Close drawer" } };
    config.ariaConfig.handle = { all: { hidden: "true" } };

    return config;
  }

  // The direction lives on the root `drawer/1`, but shadcn's classes key off
  // `data-vaul-drawer-direction` on the content, so copy it down.
  stampDirection() {
    [this.el, this.content, this.contentPanel].forEach((node) => {
      node?.setAttribute("data-vaul-drawer-direction", this.direction);
    });
    this.contentPanel?.setAttribute("data-vaul-drawer", "");
  }

  setupComponentEvents() {
    super.setupComponentEvents();

    const dragTarget = this.options.handleOnly
      ? this.getPart("handle")
      : this.contentPanel;
    this.dragTarget = dragTarget;
    dragTarget?.addEventListener("pointerdown", this.onPointerDown);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();

    this.dragTarget?.removeEventListener("pointerdown", this.onPointerDown);
    this.dragTarget = null;
    this.stopTracking();
  }

  // Server/client commands: "open", "close", plus
  // "snap_to" with %{index: n} or %{snap_point: value}.
  handleCommand(command, params = {}) {
    if (command === "snap_to" || command === "snapTo") {
      const index =
        params.index ??
        this.findSnapIndex(params.snap_point ?? params.snapPoint);
      this.snapTo(index);
      return true;
    }

    return super.handleCommand(command, params);
  }

  // Runs on every open, and on mount when rendered open.
  activateOpenState() {
    this.resetInlineStyles();
    this.activeSnapIndex = this.initialSnapIndex;
    this.applyOffset(this.snapOffset(this.activeSnapIndex), false);

    super.activateOpenState();
  }

  onOpenExit() {
    this.stopTracking();
    super.onOpenExit();
  }

  updatePartsVisibility() {
    super.updatePartsVisibility();

    // Once fully closed, drop any drag offset so the next open starts clean.
    if (this.state === "closed" && this.contentPanel) {
      this.resetInlineStyles();
    }
  }

  beforeDestroy() {
    this.stopTracking();
    super.beforeDestroy();
  }

  // --- Geometry ----------------------------------------------------------

  isVertical() {
    return this.direction === "top" || this.direction === "bottom";
  }

  panelSize() {
    const rect = this.contentPanel.getBoundingClientRect();
    const size = this.isVertical() ? rect.height : rect.width;
    return (
      size ||
      (this.isVertical()
        ? this.contentPanel.offsetHeight
        : this.contentPanel.offsetWidth) ||
      0
    );
  }

  viewportSize() {
    return this.isVertical() ? window.innerHeight : window.innerWidth;
  }

  // A snap point is a fraction of the viewport (0..1) or a pixel string ("148px").
  snapPointPx(point) {
    if (typeof point === "string") {
      const px = parseFloat(point);
      if (point.trim().endsWith("px")) return px;
      return px <= 1 ? px * this.viewportSize() : px;
    }
    return point <= 1 ? point * this.viewportSize() : point;
  }

  findSnapIndex(value) {
    if (!this.snapPoints || this.snapPoints.length === 0) return -1;
    if (value === undefined || value === null) return 0;

    const index = this.snapPoints.findIndex(
      (point) => String(point) === String(value),
    );
    return index === -1 ? 0 : index;
  }

  // How far (px) the panel is pushed toward its edge at a snap point.
  snapOffset(index) {
    if (index < 0 || !this.snapPoints[index]) return 0;
    const size = this.panelSize();
    const px = Math.min(this.snapPointPx(this.snapPoints[index]), size);
    return Math.max(0, size - px);
  }

  // The resting offset the panel can be dragged back to without closing.
  restOffset() {
    return this.snapPoints.length ? this.snapOffset(0) : 0;
  }

  // --- Applying offsets --------------------------------------------------

  applyOffset(offset, animate) {
    if (!this.contentPanel) return;

    this.currentOffset = offset;
    const sign =
      this.direction === "bottom" || this.direction === "right" ? 1 : -1;
    const axis = this.isVertical() ? "Y" : "X";

    this.contentPanel.style.transition = animate
      ? `transform ${SETTLE_TRANSITION}`
      : "none";
    this.contentPanel.style.transform =
      offset === 0 ? "" : `translate${axis}(${sign * offset}px)`;

    this.applyOverlayOpacity(offset, animate);
  }

  applyOverlayOpacity(offset, animate) {
    if (!this.overlay) return;

    const rest = this.restOffset();
    const travel = this.panelSize() - rest;
    const progress =
      travel > 0 ? Math.min(1, Math.max(0, (offset - rest) / travel)) : 0;

    this.overlay.style.transition = animate
      ? `opacity ${SETTLE_TRANSITION}`
      : "none";
    this.overlay.style.opacity = progress > 0 ? String(1 - progress) : "";
  }

  resetInlineStyles() {
    this.currentOffset = 0;
    if (this.contentPanel) {
      this.contentPanel.style.transform = "";
      this.contentPanel.style.transition = "";
    }
    if (this.overlay) {
      this.overlay.style.opacity = "";
      this.overlay.style.transition = "";
    }
  }

  snapTo(index) {
    if (this.state !== "open" || !this.snapPoints.length) return;

    const next = Math.max(0, Math.min(this.snapPoints.length - 1, index));
    const changed = next !== this.activeSnapIndex;
    this.activeSnapIndex = next;
    this.applyOffset(this.snapOffset(next), true);

    if (changed) {
      this.pushEvent("snap-point-change", {
        index: next,
        snapPoint: this.snapPoints[next],
      });
    }
  }

  // --- Dragging ----------------------------------------------------------

  onPointerDown(event) {
    if (this.state !== "open" || this.drag) return;
    if (event.button !== undefined && event.button !== 0) return;
    if (event.target?.closest?.(NO_DRAG_SELECTOR)) return;

    this.drag = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      startTime: Date.now(),
      startOffset: this.currentOffset || 0,
      target: event.target,
      active: false,
      delta: 0,
    };

    document.addEventListener("pointermove", this.onPointerMove);
    document.addEventListener("pointerup", this.onPointerUp);
    document.addEventListener("pointercancel", this.onPointerUp);
  }

  // Signed distance along the dismiss axis: positive moves toward the edge.
  axisDelta(event) {
    const dx = event.clientX - this.drag.startX;
    const dy = event.clientY - this.drag.startY;
    switch (this.direction) {
      case "top":
        return { delta: -dy, cross: Math.abs(dx) };
      case "left":
        return { delta: -dx, cross: Math.abs(dy) };
      case "right":
        return { delta: dx, cross: Math.abs(dy) };
      default:
        return { delta: dy, cross: Math.abs(dx) };
    }
  }

  // Let scrollable content scroll instead of dragging the drawer when it
  // still has room to scroll in the direction of the gesture.
  canScroll(target, delta) {
    let node = target;
    while (node && node !== this.contentPanel) {
      const scrollable = this.isVertical()
        ? node.scrollHeight > node.clientHeight
        : node.scrollWidth > node.clientWidth;

      if (scrollable) {
        const pos = this.isVertical() ? node.scrollTop : node.scrollLeft;
        const max = this.isVertical()
          ? node.scrollHeight - node.clientHeight
          : node.scrollWidth - node.clientWidth;
        const towardStart =
          this.direction === "bottom" || this.direction === "right"
            ? delta > 0
            : delta < 0;
        if (towardStart ? Math.abs(pos) > 0 : Math.abs(pos) < max) return true;
      }
      node = node.parentElement;
    }
    return false;
  }

  onPointerMove(event) {
    const drag = this.drag;
    if (
      !drag ||
      (drag.pointerId !== undefined && event.pointerId !== drag.pointerId)
    )
      return;

    const { delta, cross } = this.axisDelta(event);

    if (!drag.active) {
      if (Math.abs(delta) < DRAG_START_THRESHOLD) return;
      if (cross > Math.abs(delta) || this.canScroll(drag.target, delta)) {
        this.stopTracking();
        return;
      }

      drag.active = true;
      this.el.setAttribute("data-dragging", "true");
      window.getSelection?.()?.removeAllRanges?.();
      try {
        this.dragTarget?.setPointerCapture?.(drag.pointerId);
      } catch {
        // Pointer capture is best-effort (e.g. synthetic events).
      }
    }

    drag.delta = delta;
    this.applyOffset(this.dampen(drag.startOffset + delta), false);
  }

  // Resist dragging past the fully open position, and past the resting
  // position when the drawer cannot be dismissed.
  dampen(offset) {
    const resist = (overshoot) =>
      Math.min(overshoot, 8 * Math.log(overshoot + 1));

    if (offset < 0) return -resist(-offset);

    const rest = this.restOffset();
    if (!this.dismissible && offset > rest) {
      return rest + resist(offset - rest);
    }
    return offset;
  }

  onPointerUp(event) {
    const drag = this.drag;
    if (
      !drag ||
      (drag.pointerId !== undefined && event.pointerId !== drag.pointerId)
    )
      return;

    this.stopTracking();
    if (!drag.active) return;

    // The release would otherwise click whatever ends up under the pointer.
    window.addEventListener("click", this.suppressClick, true);
    setTimeout(
      () => window.removeEventListener("click", this.suppressClick, true),
      0,
    );

    const elapsed = Math.max(1, Date.now() - drag.startTime);
    const velocity = drag.delta / elapsed;
    this.settle(this.currentOffset || 0, velocity);
  }

  settle(offset, velocity) {
    const size = this.panelSize();
    const rest = this.restOffset();
    const flick = Math.abs(velocity) > VELOCITY_THRESHOLD;

    if (this.dismissible && offset > rest) {
      const atLowest = this.activeSnapIndex <= 0;
      const pastThreshold = offset - rest > (size - rest) * CLOSE_THRESHOLD;
      if (pastThreshold || (flick && velocity > 0 && atLowest)) {
        this.dismiss();
        return;
      }
    }

    if (!this.snapPoints.length) {
      this.applyOffset(0, true);
      return;
    }

    let index;
    if (flick) {
      index = this.activeSnapIndex + (velocity > 0 ? -1 : 1);
    } else {
      const offsets = this.snapPoints.map((_, i) => this.snapOffset(i));
      index = offsets.reduce(
        (best, value, i) =>
          Math.abs(value - offset) < Math.abs(offsets[best] - offset)
            ? i
            : best,
        0,
      );
    }

    this.snapTo(index);
  }

  // Close from the dragged position: the exit animation's implicit start
  // keyframe is the inline transform, so the panel keeps sliding out.
  dismiss() {
    if (this.contentPanel) this.contentPanel.style.transition = "none";
    this.transition("close");
  }

  suppressClick(event) {
    event.stopPropagation();
    event.preventDefault();
    window.removeEventListener("click", this.suppressClick, true);
  }

  stopTracking() {
    document.removeEventListener("pointermove", this.onPointerMove);
    document.removeEventListener("pointerup", this.onPointerUp);
    document.removeEventListener("pointercancel", this.onPointerUp);
    this.el?.removeAttribute("data-dragging");
    this.drag = null;
  }
}

SaladUI.register("drawer", DrawerComponent);

export default DrawerComponent;
