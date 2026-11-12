// saladui/components/carousel.js
//
// Carousel on native CSS scroll snapping (no Embla). The CSS (in carousel.ex)
// owns layout, swipe and trackpad scrolling; this component owns the
// previous/next buttons, keyboard navigation, loop, autoplay and the `select`
// event. Snap positions are measured from the DOM, clamped to the scrollable
// range and de-duplicated — like Embla's `containScroll: "trimSnaps"` — so a
// track showing three slides at once has `count - 2` positions, not `count`.
import Component from "../core/component.js";
import SaladUI from "../index.js";

// Scroll events stop this long before the position counts as settled.
const SETTLE_DELAY = 100;

class CarouselComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.viewport = this.getPart("viewport");
    this.container = this.getPart("content");

    this.snaps = [];
    this.selectedIndex = 0;
    this.settleTimer = null;
    this.autoplayTimer = null;
    this.autoplayStopped = false;
    this.autoplayPaused = false;

    this.onScroll = this.onScroll.bind(this);
    this.onResize = this.onResize.bind(this);
    this.onPointerDown = this.onPointerDown.bind(this);
    this.onPointerEnter = this.onPointerEnter.bind(this);
    this.onPointerLeave = this.onPointerLeave.bind(this);
    this.onFocusIn = this.onFocusIn.bind(this);
    this.onFocusOut = this.onFocusOut.bind(this);
  }

  /**
   * "vertical" or "horizontal" (default). Read from options because
   * getComponentConfig() runs inside the base constructor, before any
   * subclass fields exist.
   */
  getOrientation() {
    return this.options?.orientation === "vertical" ? "vertical" : "horizontal";
  }

  isVertical() {
    return this.getOrientation() === "vertical";
  }

  isRtl() {
    if (this.isVertical()) return false;
    const dir = this.el.closest("[dir]")?.getAttribute("dir");
    if (dir) return dir.toLowerCase() === "rtl";
    return window.getComputedStyle?.(this.el)?.direction === "rtl";
  }

  getComponentConfig() {
    const keyMap = {
      ArrowLeft: (event) => this.handleArrowKey(event, "left"),
      ArrowRight: (event) => this.handleArrowKey(event, "right"),
    };
    if (this.getOrientation() === "vertical") {
      keyMap.ArrowUp = (event) => this.handleArrowKey(event, "prev");
      keyMap.ArrowDown = (event) => this.handleArrowKey(event, "next");
    }

    return {
      stateMachine: {
        idle: { transitions: {} },
      },
      events: {
        idle: {
          keyMap,
          mouseMap: {
            previous: { click: () => this.userNavigate("prev") },
            next: { click: () => this.userNavigate("next") },
          },
        },
      },
      ariaConfig: {
        viewport: {
          all: { live: () => (this.autoplayActive() ? "off" : "polite") },
        },
      },
    };
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    if (!this.viewport) return;

    this.viewport.addEventListener("scroll", this.onScroll, { passive: true });
    this.viewport.addEventListener("pointerdown", this.onPointerDown);
    this.el.addEventListener("pointerenter", this.onPointerEnter);
    this.el.addEventListener("pointerleave", this.onPointerLeave);
    this.el.addEventListener("focusin", this.onFocusIn);
    this.el.addEventListener("focusout", this.onFocusOut);

    if (typeof ResizeObserver !== "undefined") {
      this.resizeObserver = new ResizeObserver(this.onResize);
      this.resizeObserver.observe(this.viewport);
      if (this.container) this.resizeObserver.observe(this.container);
    }
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    if (this.viewport) {
      this.viewport.removeEventListener("scroll", this.onScroll);
      this.viewport.removeEventListener("pointerdown", this.onPointerDown);
    }
    this.el.removeEventListener("pointerenter", this.onPointerEnter);
    this.el.removeEventListener("pointerleave", this.onPointerLeave);
    this.el.removeEventListener("focusin", this.onFocusIn);
    this.el.removeEventListener("focusout", this.onFocusOut);
    this.resizeObserver?.disconnect();
    this.resizeObserver = null;
    clearTimeout(this.settleTimer);
    this.settleTimer = null;
    this.stopAutoplayTimer();
  }

  afterMount() {
    this.labelSlides();
    this.applySnapMargins();
    this.measure();
    // Re-mounts after a LiveView patch keep the scroll position, so start
    // from wherever the viewport already is.
    this.selectedIndex = this.nearestSnap();
    this.updateControls();
    this.startAutoplay();
  }

  // --- measuring -----------------------------------------------------------

  getItems() {
    if (!this.container) return [];
    return Array.from(this.container.children).filter(
      (child) => child.getAttribute("data-part") === "item",
    );
  }

  labelSlides() {
    const items = this.getItems();
    items.forEach((item, index) => {
      if (item.hasAttribute("aria-label")) return;
      if (item.hasAttribute("aria-labelledby")) return;
      item.setAttribute("aria-label", `${index + 1} of ${items.length}`);
    });
  }

  /**
   * The gutter is padding on each slide (`pl-4`, cancelled by `-ml-4` on the
   * track), so a slide's border box starts one gutter before its content. CSS
   * snapping aligns border boxes; Embla aligns content. A negative
   * `scroll-margin` equal to the padding makes the content box the snap area.
   * It can't be a utility class because the caller's own `pl-*` sets the
   * gutter, so it is measured here and written to a <style> in <head>, where
   * LiveView patches of the carousel can't strip it the way they would an
   * inline style.
   */
  applySnapMargins() {
    const item = this.getItems()[0];
    if (!item || !this.el.id) return;

    const style = window.getComputedStyle(item);
    const margin = ["Top", "Right", "Bottom", "Left"]
      .map((side) => `${-(parseFloat(style[`padding${side}`]) || 0) || 0}px`)
      .join(" ");
    if (margin === this.snapMargin) return;
    this.snapMargin = margin;

    if (!this.snapStyle) {
      this.snapStyle = document.createElement("style");
      this.snapStyle.setAttribute("data-salad-carousel", this.el.id);
      document.head.appendChild(this.snapStyle);
    }
    const id = this.el.id.replace(/["\\]/g, "\\$&");
    this.snapStyle.textContent =
      `[id="${id}"]>[data-part="viewport"]>[data-part="content"]>[data-part="item"]` +
      `{scroll-margin:${margin}}`;
  }

  removeSnapMargins() {
    this.snapStyle?.remove();
    this.snapStyle = null;
    this.snapMargin = null;
  }

  // A slide's content box (border box minus padding): its snap area.
  contentRect(item) {
    const rect = item.getBoundingClientRect();
    const style = window.getComputedStyle(item);
    const pad = (side) => parseFloat(style[`padding${side}`]) || 0;
    const left = rect.left + pad("Left");
    const right = rect.right - pad("Right");
    const top = rect.top + pad("Top");
    const bottom = rect.bottom - pad("Bottom");
    return {
      left,
      right,
      top,
      bottom,
      width: right - left,
      height: bottom - top,
    };
  }

  viewSize() {
    return this.isVertical()
      ? this.viewport.clientHeight
      : this.viewport.clientWidth;
  }

  maxScroll() {
    const total = this.isVertical()
      ? this.viewport.scrollHeight
      : this.viewport.scrollWidth;
    return Math.max(0, total - this.viewSize());
  }

  // Logical scroll offset: always 0..maxScroll, even in RTL where
  // scrollLeft runs from 0 down to -maxScroll.
  scrollPosition() {
    if (this.isVertical()) return this.viewport.scrollTop;
    const left = this.viewport.scrollLeft;
    return this.isRtl() ? Math.abs(left) : left;
  }

  measure() {
    if (!this.viewport) {
      this.snaps = [];
      return;
    }

    const vertical = this.isVertical();
    const rtl = this.isRtl();
    const viewRect = this.viewport.getBoundingClientRect();
    const viewSize = this.viewSize();
    const maxScroll = this.maxScroll();
    const offset = this.scrollPosition();
    const align = this.options?.align || "start";

    const positions = this.getItems().map((item) => {
      const rect = this.contentRect(item);
      let start;
      if (vertical) start = rect.top - viewRect.top;
      else if (rtl) start = viewRect.right - rect.right;
      else start = rect.left - viewRect.left;
      start += offset;

      const size = vertical ? rect.height : rect.width;
      let position = start;
      if (align === "center") position = start + size / 2 - viewSize / 2;
      else if (align === "end") position = start + size - viewSize;

      return Math.min(maxScroll, Math.max(0, Math.round(position)));
    });

    // Slides that can't be scrolled to on their own (the tail of a track that
    // shows several at once) collapse onto the same clamped position.
    this.snaps = positions.reduce((snaps, position) => {
      const last = snaps[snaps.length - 1];
      if (last === undefined || Math.abs(position - last) > 1) {
        snaps.push(position);
      }
      return snaps;
    }, []);
  }

  nearestSnap(position = this.scrollPosition()) {
    let nearest = 0;
    this.snaps.forEach((snap, index) => {
      if (
        Math.abs(snap - position) < Math.abs(this.snaps[nearest] - position)
      ) {
        nearest = index;
      }
    });
    return nearest;
  }

  count() {
    return this.snaps.length;
  }

  canScrollPrev() {
    if (this.count() < 2) return false;
    return !!this.options?.loop || this.selectedIndex > 0;
  }

  canScrollNext() {
    if (this.count() < 2) return false;
    return !!this.options?.loop || this.selectedIndex < this.count() - 1;
  }

  // --- navigation ----------------------------------------------------------

  scrollPrev() {
    this.navigate("prev");
  }

  scrollNext() {
    this.navigate("next");
  }

  navigate(direction) {
    this.measure();
    const count = this.count();
    if (count < 2) return;

    const step = direction === "prev" ? -1 : 1;
    let index = this.selectedIndex + step;
    if (index < 0 || index >= count) {
      if (!this.options?.loop) return;
      index = (index + count) % count;
    }
    this.scrollTo(index);
  }

  scrollTo(index, { smooth = true } = {}) {
    this.measure();
    const count = this.count();
    if (!count) return;

    const target = Math.min(count - 1, Math.max(0, Number(index) || 0));
    this.applyScroll(this.snaps[target], smooth);
    this.select(target);
  }

  applyScroll(position, smooth) {
    const vertical = this.isVertical();
    const value = !vertical && this.isRtl() ? -position : position;
    const behavior = smooth && !this.prefersReducedMotion() ? "smooth" : "auto";

    if (typeof this.viewport.scrollTo === "function") {
      this.viewport.scrollTo({
        [vertical ? "top" : "left"]: value,
        behavior,
      });
    } else if (vertical) {
      this.viewport.scrollTop = value;
    } else {
      this.viewport.scrollLeft = value;
    }
  }

  prefersReducedMotion() {
    return !!window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches;
  }

  select(index) {
    const changed = index !== this.selectedIndex;
    this.selectedIndex = index;
    this.updateControls();
    if (changed) {
      this.pushEvent("select", { index, count: this.count() });
    }
  }

  updateControls() {
    this.getAllParts("previous").forEach((button) => {
      button.disabled = !this.canScrollPrev();
    });
    this.getAllParts("next").forEach((button) => {
      button.disabled = !this.canScrollNext();
    });
    this.el.setAttribute("data-selected-index", String(this.selectedIndex));
    this.el.setAttribute("data-snap-count", String(this.count()));
  }

  // A navigation the user asked for: also ends autoplay, like Embla's
  // Autoplay `stopOnInteraction`.
  userNavigate(direction) {
    this.stopAutoplay();
    this.navigate(direction);
  }

  handleArrowKey(event, key) {
    const target = event.target;
    if (
      target?.closest?.(
        "input, textarea, select, [contenteditable=''], [contenteditable='true']",
      )
    ) {
      return;
    }

    let direction = key;
    if (key === "left") direction = this.isRtl() ? "next" : "prev";
    if (key === "right") direction = this.isRtl() ? "prev" : "next";

    event.preventDefault();
    this.userNavigate(direction);
  }

  handleCommand(command, params = {}) {
    switch (command) {
      case "next":
        this.scrollNext();
        return true;
      case "previous":
      case "prev":
        this.scrollPrev();
        return true;
      case "scroll_to":
      case "scrollTo":
        this.scrollTo(params.index);
        return true;
      default:
        return super.handleCommand(command, params);
    }
  }

  // --- scroll tracking -----------------------------------------------------

  onScroll() {
    clearTimeout(this.settleTimer);
    this.settleTimer = setTimeout(() => this.settle(), SETTLE_DELAY);
  }

  // The user swiped/scrolled (or a programmatic scroll finished): pick the
  // snap the viewport came to rest on.
  settle() {
    this.settleTimer = null;
    if (this.destroyed) return;
    this.measure();
    this.select(this.nearestSnap());
  }

  onResize() {
    if (this.destroyed) return;
    this.applySnapMargins();
    this.measure();
    const index = Math.min(this.selectedIndex, Math.max(0, this.count() - 1));
    this.select(index);
  }

  // --- autoplay ------------------------------------------------------------

  autoplayDelay() {
    const delay = Number(this.options?.autoplay);
    return Number.isFinite(delay) && delay > 0 ? delay : null;
  }

  autoplayActive() {
    return !!this.autoplayDelay() && !this.autoplayStopped;
  }

  startAutoplay() {
    this.stopAutoplayTimer();
    if (!this.autoplayActive() || this.autoplayPaused) return;
    this.autoplayTimer = setTimeout(
      () => this.autoplayTick(),
      this.autoplayDelay(),
    );
  }

  autoplayTick() {
    this.autoplayTimer = null;
    if (this.destroyed || !this.autoplayActive()) return;

    this.measure();
    if (this.selectedIndex >= this.count() - 1) this.scrollTo(0);
    else this.navigate("next");
    this.startAutoplay();
  }

  stopAutoplayTimer() {
    clearTimeout(this.autoplayTimer);
    this.autoplayTimer = null;
  }

  stopAutoplay() {
    if (!this.autoplayDelay() || this.autoplayStopped) return;
    this.autoplayStopped = true;
    this.stopAutoplayTimer();
    this.ariaManager?.applyAriaAttributes(this.state);
  }

  onPointerDown() {
    this.stopAutoplay();
  }

  onPointerEnter() {
    this.autoplayPaused = true;
    this.stopAutoplayTimer();
  }

  onPointerLeave() {
    this.autoplayPaused = this.el.contains(document.activeElement);
    this.startAutoplay();
  }

  onFocusIn() {
    this.autoplayPaused = true;
    this.stopAutoplayTimer();
  }

  onFocusOut(event) {
    if (this.el.contains(event.relatedTarget)) return;
    this.autoplayPaused = false;
    this.startAutoplay();
  }

  beforeDestroy() {
    this.removeSnapMargins();
  }
}

SaladUI.register("carousel", CarouselComponent);

export default CarouselComponent;
