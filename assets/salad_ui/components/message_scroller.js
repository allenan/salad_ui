// saladui/components/message_scroller.js
//
// Chat transcript scroller, ported from shadcn's `@shadcn/react/message-scroller`
// controller. The server renders the frame, viewport, content and rows; this
// component owns the scroll behavior:
//
// - opening position (`start`, `end`, `last-anchor`), hidden behind
//   `data-pending-scroll` until applied
// - turn anchoring: a newly appended `data-scroll-anchor="true"` row settles
//   near the top with a peek of the previous row, held there by a tail spacer
//   while the reply streams in below it
// - follow-output (`autoScroll`) only while the reader is at the live edge;
//   wheel, touch, scroll keys and scrollbar drags release it
// - prepended history keeps the first visible row where it was
// - scroll_to_message / scroll_to_end / scroll_to_start commands
// - scroll buttons that go inert when there is nothing in their direction
// - optional visibility tracking (current anchored turn + visible rows)
//
// Rows are the element children of the content part, so it works with
// `phx-update="stream"` inserts at either end (and stream resets).
import Component from "../core/component.js";
import SaladUI from "../index.js";

// Two fractional scrollTop values within this range are treated as equal.
const SCROLL_POSITION_EPSILON = 0.5;
// How long data-autoscrolling stays set during a programmatic scroll.
const AUTOSCROLLING_CLEAR_DELAY = 180;

const DEFAULT_OPTIONS = {
  autoScroll: false,
  defaultScrollPosition: "end",
  scrollEdgeThreshold: 8,
  scrollMargin: 0,
  scrollPreviousItemPeek: 64,
};

// Viewport keys that count as deliberate scroll intent and release follow.
const USER_SCROLL_KEYS = [
  "ArrowDown",
  "ArrowUp",
  "End",
  "Home",
  "PageDown",
  "PageUp",
  " ",
];

const ALIGNS = ["start", "center", "end", "nearest"];

function readNumber(value, fallback) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function readCssPixel(value) {
  if (!value) return 0;
  const number = Number.parseFloat(value);
  return Number.isFinite(number) ? number : 0;
}

function getBlockPadding(element) {
  if (!element || typeof window.getComputedStyle !== "function") {
    return { start: 0, end: 0 };
  }
  const style = window.getComputedStyle(element);
  return {
    start: readCssPixel(style.paddingBlockStart || style.paddingTop),
    end: readCssPixel(style.paddingBlockEnd || style.paddingBottom),
  };
}

function sameIds(a, b) {
  return a.length === b.length && a.every((id, index) => id === b[index]);
}

class MessageScrollerComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.readOptions();
    this.cacheParts();

    // "following-bottom" (autoScroll, pinned to the latest row),
    // "free-scrolling" (reader scrolled away), "anchored-to-message" (holding
    // a new turn at the reading line while it streams) or "settling-jump" (a
    // programmatic jump is in flight).
    this.mode = this.opts.autoScroll ? "following-bottom" : "free-scrolling";
    this.autoscrolling = false;
    this.autoscrollingTimer = null;
    this.streamingTurn = null;
    this.defaultScrollPositionApplied = false;
    this.pendingDefaultScroll =
      this.el.hasAttribute("data-pending-scroll") ||
      !!this.viewport?.hasAttribute("data-pending-scroll");

    this.itemCount = 0;
    this.firstItem = null;
    this.seenItems = new WeakSet();
    this.lastScrollTop = 0;
    this.pendingScrollToMessage = null;
    this.prependRestore = null;
    this.spacerHeight = 0;

    this.scrollable = { start: false, end: false };
    this.publishedScrollable = null;
    this.visibility = { currentAnchorId: null, visibleMessageIds: [] };
    this.visibleIds = new Set();
    this.observedItems = new Set();

    this.stateFrame = null;
    this.visibilityFrame = null;
    this.resizeFrame = null;

    this.onScroll = this.onScroll.bind(this);
    this.onUserScrollIntent = this.onUserScrollIntent.bind(this);
    this.onButtonClick = this.onButtonClick.bind(this);
    this.onResizeObserved = this.onResizeObserved.bind(this);
    this.onContentMutation = this.onContentMutation.bind(this);
    this.onIntersection = this.onIntersection.bind(this);
  }

  getComponentConfig() {
    const keyMap = {};
    USER_SCROLL_KEYS.forEach((key) => {
      keyMap[key] = "onUserScrollIntent";
    });

    return {
      stateMachine: {
        idle: { transitions: {} },
      },
      events: {
        // Scroll keys on the focused viewport release follow-output and the
        // turn anchor; the browser still performs the native scroll.
        _all: { keyEventTarget: "viewport", keyMap },
      },
      // Region/log roles and labels are server-rendered so they can be
      // overridden per instance; the scroll buttons' inert/tabindex state is
      // written by updateButtons().
      ariaConfig: {},
    };
  }

  // Only the frame's own parts: rows (everything inside the content part)
  // belong to the app and may contain any number of unrelated data-part
  // elements, so they are neither collected nor given data-state.
  queryParts() {
    const parts = [];
    const walk = (node) => {
      for (const child of node.children) {
        if (child.getAttribute("phx-hook") != null) continue;
        if (child.dataset?.part) parts.push(child);
        if (child.dataset?.part === "content") continue;
        walk(child);
      }
    };
    walk(this.el);
    return parts.concat([this.el]);
  }

  readOptions() {
    const options = this.options || {};
    const position = options.defaultScrollPosition;
    this.opts = {
      autoScroll: !!options.autoScroll,
      defaultScrollPosition: ["start", "end", "last-anchor"].includes(position)
        ? position
        : DEFAULT_OPTIONS.defaultScrollPosition,
      scrollEdgeThreshold: readNumber(
        options.scrollEdgeThreshold,
        DEFAULT_OPTIONS.scrollEdgeThreshold,
      ),
      scrollMargin: readNumber(
        options.scrollMargin,
        DEFAULT_OPTIONS.scrollMargin,
      ),
      scrollPreviousItemPeek: readNumber(
        options.scrollPreviousItemPeek,
        DEFAULT_OPTIONS.scrollPreviousItemPeek,
      ),
    };
  }

  cacheParts() {
    this.viewport = this.getPart("viewport") || null;
    this.content = this.getPart("content") || null;
    this.spacer = this.getPart("spacer") || null;
    this.buttons = this.getAllParts("scroll-button");
  }

  preserveScrollOnPrepend() {
    return this.viewport?.dataset.preserveScrollOnPrepend !== "false";
  }

  // --- lifecycle -----------------------------------------------------------

  setupComponentEvents() {
    super.setupComponentEvents();
    this.el.addEventListener("click", this.onButtonClick);

    if (this.viewport) {
      this.viewport.addEventListener("scroll", this.onScroll, {
        passive: true,
      });
      this.viewport.addEventListener("wheel", this.onUserScrollIntent, {
        passive: true,
      });
      this.viewport.addEventListener("touchmove", this.onUserScrollIntent, {
        passive: true,
      });
    }

    const ResizeObserverImpl = window.ResizeObserver;
    if (typeof ResizeObserverImpl === "function" && this.viewport) {
      this.resizeObserver = new ResizeObserverImpl(this.onResizeObserved);
      this.resizeObserver.observe(this.viewport);
      if (this.content) this.resizeObserver.observe(this.content);
    }

    const MutationObserverImpl = window.MutationObserver;
    if (typeof MutationObserverImpl === "function" && this.content) {
      this.mutationObserver = new MutationObserverImpl(this.onContentMutation);
      this.mutationObserver.observe(this.content, { childList: true });
    }
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.el.removeEventListener("click", this.onButtonClick);

    if (this.viewport) {
      this.viewport.removeEventListener("scroll", this.onScroll);
      this.viewport.removeEventListener("wheel", this.onUserScrollIntent);
      this.viewport.removeEventListener("touchmove", this.onUserScrollIntent);
    }

    this.resizeObserver?.disconnect();
    this.resizeObserver = null;
    this.mutationObserver?.disconnect();
    this.mutationObserver = null;
    this.stopVisibilityTracking();

    for (const key of ["stateFrame", "visibilityFrame", "resizeFrame"]) {
      if (this[key] !== null) {
        window.cancelAnimationFrame(this[key]);
        this[key] = null;
      }
    }
    clearTimeout(this.autoscrollingTimer);
    this.autoscrollingTimer = null;
  }

  afterMount() {
    this.protectAttributes();
    this.startVisibilityTracking();
    this.handleContentChange();

    if (!this.applyDefaultScrollPosition() && this.itemCount === 0) {
      this.clearPendingDefaultScroll();
    }

    if (
      this.opts.autoScroll &&
      this.mode === "following-bottom" &&
      this.itemCount > 0
    ) {
      this.scrollToEnd({ behavior: "auto" });
    } else {
      this.commitScrollState();
    }
  }

  /**
   * LiveView reverts the attributes this component writes (data-scrollable,
   * data-pending-scroll, the spacer's height, the buttons' inert state) on
   * every patch, and stream inserts patch constantly. LiveView >= 1.1 can be
   * told to leave them alone; older versions get them re-applied in
   * skipReinitialize().
   */
  protectAttributes() {
    let js = null;
    try {
      js = this.hook?.js?.();
    } catch {
      js = null;
    }
    if (!js || typeof js.ignoreAttributes !== "function") return;

    const stateAttrs = [
      "data-scrollable",
      "data-autoscrolling",
      "data-pending-scroll",
    ];
    js.ignoreAttributes(this.el, stateAttrs);
    if (this.viewport) js.ignoreAttributes(this.viewport, stateAttrs);
    if (this.spacer) js.ignoreAttributes(this.spacer, ["hidden", "style"]);
    this.buttons.forEach((button) =>
      js.ignoreAttributes(button, ["data-active", "inert", "tabindex"]),
    );
  }

  /**
   * Keep this instance across LiveView patches (a stream insert, a streamed
   * chunk, an option change) instead of rebuilding it, so the follow/anchor
   * mode, the tail spacer and the opening position survive. Only a different
   * viewport/content/spacer element forces a rebuild.
   */
  skipReinitialize(el) {
    if (el !== this.el) return false;

    const previous = {
      viewport: this.viewport,
      content: this.content,
      spacer: this.spacer,
    };
    this.allParts = this.queryParts();
    this.cacheParts();
    if (
      this.viewport !== previous.viewport ||
      this.content !== previous.content ||
      this.spacer !== previous.spacer
    ) {
      return false;
    }

    if (el.getAttribute("data-event-mappings") !== this._eventMappingsRaw) {
      const hadVisibility = this.tracksVisibility();
      this.parseEventMappings();
      if (this.tracksVisibility() && !hadVisibility) {
        this.startVisibilityTracking();
      } else if (!this.tracksVisibility() && hadVisibility) {
        this.stopVisibilityTracking();
      }
    }

    this.updateUI();
    this.protectAttributes();
    this.restoreWrittenState();

    if (el.getAttribute("data-options") !== this._optionsRaw) {
      const previousPosition = this.opts.defaultScrollPosition;
      const previousLine =
        this.opts.scrollMargin + this.opts.scrollPreviousItemPeek;
      this.parseOptions();
      this.readOptions();
      // The IntersectionObserver's reading line is fixed at creation; rebuild
      // it when scroll_margin or scroll_previous_item_peek moves that line.
      if (
        this.intersectionObserver &&
        this.opts.scrollMargin + this.opts.scrollPreviousItemPeek !==
          previousLine
      ) {
        this.intersectionObserver.disconnect();
        this.intersectionObserver = null;
        this.visibleIds.clear();
        this.startVisibilityTracking();
      }
      // Turning auto_scroll off must drop follow-output, or the scroller
      // keeps hiding the end button while nothing follows the new rows.
      if (!this.opts.autoScroll && this.mode === "following-bottom") {
        this.mode = "free-scrolling";
      }
      if (this.opts.defaultScrollPosition !== previousPosition) {
        this.defaultScrollPositionApplied = false;
        this.applyDefaultScrollPosition();
      }
      if (
        this.opts.autoScroll &&
        this.mode === "following-bottom" &&
        this.itemCount > 0
      ) {
        this.scrollToEnd({ behavior: "auto" });
      } else {
        this.commitScrollState();
      }
    }

    // Without a MutationObserver nothing else notices inserted rows.
    if (!this.mutationObserver) this.handleContentChange();

    return true;
  }

  // Re-reads data-event-mappings without re-binding the base listeners
  // (initEventMappings() would orphan the ones already attached).
  parseEventMappings() {
    const raw = this.el.getAttribute("data-event-mappings");
    try {
      this.eventMappings = raw ? JSON.parse(raw) : {};
    } catch {
      this.eventMappings = {};
    }
    this._eventMappingsRaw = raw;
  }

  // Re-applies everything this component writes onto server-rendered markup.
  restoreWrittenState() {
    if (!this.pendingDefaultScroll) {
      this.el.removeAttribute("data-pending-scroll");
      this.viewport?.removeAttribute("data-pending-scroll");
    }
    this.writeSpacer();
    this.writeStateAttributes(this.publishedScrollable || this.scrollable);
  }

  // --- events --------------------------------------------------------------

  onScroll() {
    this.syncAfterScroll();
  }

  onUserScrollIntent() {
    this.userScrollIntent();
  }

  onResizeObserved() {
    // Coalesce into rAF: handleResize writes the spacer, and resizing during
    // ResizeObserver delivery triggers "loop completed with undelivered
    // notifications".
    if (this.resizeFrame !== null) {
      window.cancelAnimationFrame(this.resizeFrame);
    }
    this.resizeFrame = window.requestAnimationFrame(() => {
      this.resizeFrame = null;
      this.handleResize();
    });
  }

  onContentMutation() {
    this.handleContentChange();
  }

  onButtonClick(event) {
    const button = event.target?.closest?.('[data-part="scroll-button"]');
    if (!button || button.closest("[data-component]") !== this.el) return;

    const direction =
      button.getAttribute("data-direction") === "start" ? "start" : "end";
    if (!this.isButtonActive(direction)) return;

    button.blur();
    const behavior = button.getAttribute("data-behavior") || "smooth";
    if (direction === "start") this.scrollToStart({ behavior });
    else this.scrollToEnd({ behavior });
  }

  // --- commands ------------------------------------------------------------

  handleCommand(command, params = {}) {
    const options = this.commandOptions(params);

    switch (command) {
      case "scroll_to_end":
      case "scrollToEnd":
        return this.scrollToEnd(options);
      case "scroll_to_start":
      case "scrollToStart":
        return this.scrollToStart(options);
      case "scroll_to_message":
      case "scrollToMessage": {
        const id =
          params.message_id ?? params.messageId ?? params.id ?? params.message;
        if (id === undefined || id === null) return false;
        return this.scrollToMessage(String(id), options);
      }
      default:
        return super.handleCommand(command, params);
    }
  }

  commandOptions(params) {
    const options = {};
    if (ALIGNS.includes(params.align)) options.align = params.align;
    if (["auto", "smooth", "instant"].includes(params.behavior)) {
      options.behavior = params.behavior;
    }
    const margin = params.scroll_margin ?? params.scrollMargin;
    if (margin !== undefined && Number.isFinite(Number(margin))) {
      options.scrollMargin = Number(margin);
    }
    return options;
  }

  // --- geometry ------------------------------------------------------------

  getItems() {
    if (!this.content) return [];
    return Array.from(this.content.children).filter(
      (child) =>
        child instanceof window.HTMLElement &&
        child !== this.spacer &&
        child.tagName !== "TEMPLATE",
    );
  }

  getElementTop(element) {
    const viewport = this.viewport;
    return (
      element.getBoundingClientRect().top -
      viewport.getBoundingClientRect().top +
      viewport.scrollTop
    );
  }

  getElementViewportTop(element) {
    return (
      element.getBoundingClientRect().top -
      this.viewport.getBoundingClientRect().top
    );
  }

  // Bottom of the last row plus the content's end padding, in scroll
  // coordinates. Rows that fill less than the viewport report their own
  // bottom, not the min-h-full box.
  getContentBottom() {
    const viewport = this.viewport;
    const padding = getBlockPadding(this.content);
    const viewportTop = viewport.getBoundingClientRect().top;
    const scrollTop = viewport.scrollTop;
    let bottom = padding.start + padding.end;

    for (const item of this.getItems()) {
      const rect = item.getBoundingClientRect();
      bottom = Math.max(
        bottom,
        rect.bottom - viewportTop + scrollTop + padding.end,
      );
    }
    return bottom;
  }

  // Where the tail spacer starts: the content box's bottom (the spacer is the
  // content's next sibling inside the viewport).
  getSpacerStart() {
    const viewport = this.viewport;
    return (
      this.content.getBoundingClientRect().bottom -
      viewport.getBoundingClientRect().top +
      viewport.scrollTop
    );
  }

  getMaxScrollTop() {
    const viewport = this.viewport;
    return Math.max(0, viewport.scrollHeight - viewport.clientHeight);
  }

  getElementScrollTop(element, align, scrollMargin) {
    const viewport = this.viewport;
    const elementTop = this.getElementTop(element);
    const elementHeight = element.getBoundingClientRect().height;
    const padding = getBlockPadding(this.content);

    if (align === "center") {
      const insetHeight = Math.max(
        0,
        viewport.clientHeight - padding.start - padding.end,
      );
      return (
        elementTop -
        padding.start -
        (insetHeight - elementHeight) / 2 -
        scrollMargin
      );
    }

    if (align === "end") {
      return (
        elementTop -
        viewport.clientHeight +
        elementHeight +
        padding.end +
        scrollMargin
      );
    }

    if (align === "nearest") {
      const elementBottom = elementTop + elementHeight;
      const viewTop = viewport.scrollTop + padding.start;
      const viewBottom =
        viewport.scrollTop + viewport.clientHeight - padding.end;

      if (elementTop >= viewTop && elementBottom <= viewBottom) {
        return viewport.scrollTop;
      }
      if (elementTop < viewTop)
        return elementTop - padding.start - scrollMargin;
      return elementBottom - viewport.clientHeight + padding.end + scrollMargin;
    }

    return elementTop - padding.start - scrollMargin;
  }

  computeScrollable() {
    const viewport = this.viewport;
    if (!viewport || !this.content) return { start: false, end: false };

    const threshold = this.opts.scrollEdgeThreshold;
    const contentBottom = this.getContentBottom();
    return {
      start: viewport.scrollTop > threshold,
      end:
        contentBottom - viewport.scrollTop - viewport.clientHeight > threshold,
    };
  }

  // First row with a message id that intersects the viewport. Rows are in
  // vertical order, so binary-search for the first one below the top edge.
  getFirstVisibleMessageItem() {
    const items = this.getItems();
    const viewportRect = this.viewport.getBoundingClientRect();
    let low = 0;
    let high = items.length;

    while (low < high) {
      const mid = (low + high) >> 1;
      if (items[mid].getBoundingClientRect().bottom > viewportRect.top) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    for (let index = low; index < items.length; index++) {
      const item = items[index];
      const rect = item.getBoundingClientRect();
      if (rect.top >= viewportRect.bottom) break;
      if (item.dataset.messageId && rect.bottom > viewportRect.top) return item;
    }
    return null;
  }

  // --- state ---------------------------------------------------------------

  writeStateAttributes(state) {
    const scrollable = [state.start && "start", state.end && "end"]
      .filter(Boolean)
      .join(" ");

    for (const element of [this.el, this.viewport]) {
      if (!element) continue;
      if (scrollable) element.setAttribute("data-scrollable", scrollable);
      else element.removeAttribute("data-scrollable");
      element.toggleAttribute("data-autoscrolling", this.autoscrolling);
    }

    this.updateButtons(state);
  }

  isButtonActive(direction) {
    const state = this.publishedScrollable || this.scrollable;
    return direction === "start" ? state.start : state.end;
  }

  updateButtons(state) {
    this.buttons.forEach((button) => {
      const direction =
        button.getAttribute("data-direction") === "start" ? "start" : "end";
      const active = direction === "start" ? state.start : state.end;

      button.setAttribute("data-active", active ? "true" : "false");
      button.toggleAttribute("inert", !active);
      if (active) button.removeAttribute("tabindex");
      else button.setAttribute("tabindex", "-1");
    });
  }

  // Arms follow-output at the bottom and releases it on any scroll away
  // (including a scrollbar drag), but never while a programmatic scroll is in
  // flight and never during the anchored-turn hold (the tail spacer makes a
  // freshly anchored turn read as "at the end").
  reconcileFollowMode(scrollable) {
    const scrollTop = this.viewport?.scrollTop ?? 0;
    const scrolledUp = scrollTop < this.lastScrollTop - SCROLL_POSITION_EPSILON;
    this.lastScrollTop = scrollTop;

    if (
      this.opts.autoScroll &&
      !scrollable.end &&
      this.spacerHeight === 0 &&
      this.mode !== "settling-jump" &&
      this.mode !== "anchored-to-message"
    ) {
      this.mode = "following-bottom";
    } else if (
      this.mode === "following-bottom" &&
      scrollable.end &&
      scrolledUp &&
      !this.autoscrolling
    ) {
      this.mode = "free-scrolling";
    }
  }

  commitScrollState() {
    if (this.destroyed) return;

    const next = this.computeScrollable();
    this.scrollable = next;
    this.reconcileFollowMode(next);

    // While following, the scroller is already closing the gap a streamed
    // chunk just opened; publishing it would strobe the scroll button.
    const published =
      this.mode === "following-bottom" ? { ...next, end: false } : next;

    this.writeStateAttributes(published);

    const previous = this.publishedScrollable;
    this.publishedScrollable = published;
    if (
      !previous ||
      previous.start !== published.start ||
      previous.end !== published.end
    ) {
      if (previous || published.start || published.end) {
        this.pushEvent("scrollable-change", {
          start: published.start,
          end: published.end,
        });
      }
    }
  }

  scheduleStateCommit() {
    if (this.stateFrame !== null) return;
    this.stateFrame = window.requestAnimationFrame(() => {
      this.stateFrame = null;
      this.commitScrollState();
    });
  }

  setAutoScrolling(value) {
    clearTimeout(this.autoscrollingTimer);
    this.autoscrollingTimer = null;

    if (this.autoscrolling !== value) {
      this.autoscrolling = value;
      this.commitScrollState();
    }

    if (value) {
      this.autoscrollingTimer = setTimeout(() => {
        this.autoscrollingTimer = null;
        this.autoscrolling = false;
        this.commitScrollState();
      }, AUTOSCROLLING_CLEAR_DELAY);
    }
  }

  clearPendingDefaultScroll() {
    this.pendingDefaultScroll = false;
    this.el.removeAttribute("data-pending-scroll");
    this.viewport?.removeAttribute("data-pending-scroll");
  }

  markDefaultScrollPositionApplied() {
    this.defaultScrollPositionApplied = true;
    this.clearPendingDefaultScroll();
  }

  // --- tail spacer ---------------------------------------------------------

  setTailSpacerHeight(height) {
    if (!this.spacer) return;
    const next = Math.max(0, Math.ceil(height));
    if (this.spacerHeight === next) return;
    this.spacerHeight = next;
    this.writeSpacer();
  }

  writeSpacer() {
    if (!this.spacer) return;
    this.spacer.hidden = this.spacerHeight === 0;
    if (this.spacerHeight > 0) {
      this.spacer.style.height = `${this.spacerHeight}px`;
    } else {
      this.spacer.style.removeProperty("height");
      if (!this.spacer.getAttribute("style")) {
        this.spacer.removeAttribute("style");
      }
    }
  }

  // A manual scroll during an anchored streaming turn strands the reserved
  // spacer. Shrink it as the reply grows or the reader scrolls into it, and
  // hand back to following once it is gone.
  drainReleasedSpacer() {
    if (
      !this.opts.autoScroll ||
      this.spacerHeight <= 0 ||
      this.mode === "following-bottom" ||
      this.mode === "anchored-to-message" ||
      this.mode === "settling-jump" ||
      this.autoscrolling ||
      !this.viewport ||
      !this.content
    ) {
      return false;
    }

    const viewport = this.viewport;
    const spacerStart = this.getSpacerStart();
    const viewBottom = viewport.scrollTop + viewport.clientHeight;
    if (viewBottom - spacerStart <= 0) return false;

    const next = Math.max(0, spacerStart + this.spacerHeight - viewBottom);
    if (next === 0) {
      this.scrollToEnd({ behavior: "auto" });
      return true;
    }
    this.setTailSpacerHeight(next);
    return false;
  }

  // --- scrolling -----------------------------------------------------------

  scrollToPosition(
    scrollTop,
    { behavior = "auto", autoscrolling = false } = {},
  ) {
    const viewport = this.viewport;
    if (!viewport) return;

    const next = Math.max(0, scrollTop);
    if (Math.abs(viewport.scrollTop - next) <= SCROLL_POSITION_EPSILON) {
      viewport.scrollTop = next;
      this.commitScrollState();
      return;
    }

    if (autoscrolling) this.setAutoScrolling(true);

    if (typeof viewport.scrollTo === "function") {
      viewport.scrollTo({ top: next, behavior });
    } else {
      viewport.scrollTop = next;
    }
    this.scheduleStateCommit();
  }

  scrollToStart({ behavior = "auto" } = {}) {
    if (!this.viewport) return false;
    this.setTailSpacerHeight(0);
    this.streamingTurn = null;
    this.mode = "free-scrolling";
    this.scrollToPosition(0, { behavior });
    this.scheduleVisibilitySync();
    return true;
  }

  scrollToEnd({ behavior = "auto" } = {}) {
    if (!this.viewport) return false;
    this.setTailSpacerHeight(0);
    this.streamingTurn = null;
    this.mode = this.opts.autoScroll ? "following-bottom" : "free-scrolling";
    this.scrollToPosition(this.getMaxScrollTop(), {
      autoscrolling: true,
      behavior,
    });
    this.scheduleVisibilitySync();
    return true;
  }

  scrollToElement(element, options = {}, { keepPreviousPeek = false } = {}) {
    const viewport = this.viewport;
    const content = this.content;
    if (!viewport || !content || !content.contains(element)) return false;

    const {
      align = "start",
      behavior = "auto",
      scrollMargin = this.opts.scrollMargin,
    } = options;
    const margin = keepPreviousPeek
      ? scrollMargin + this.opts.scrollPreviousItemPeek
      : scrollMargin;
    const scrollTop = this.getElementScrollTop(element, align, margin);

    this.setTailSpacerHeight(
      scrollTop + viewport.clientHeight - this.getSpacerStart(),
    );

    // Seed the prepend anchor with the target so a prepend landing before
    // this scroll settles still preserves the jumped-to row.
    this.prependRestore = {
      element,
      viewportTop: this.getElementViewportTop(element),
    };

    this.mode = keepPreviousPeek ? "anchored-to-message" : "settling-jump";
    this.streamingTurn = keepPreviousPeek ? element : null;

    this.scrollToPosition(scrollTop, { behavior });
    this.scheduleVisibilitySync();
    return true;
  }

  reanchorToAnchoredMessage() {
    const element = this.streamingTurn;
    if (
      !element ||
      !element.isConnected ||
      this.mode !== "anchored-to-message"
    ) {
      return false;
    }
    return this.scrollToElement(
      element,
      { align: "start" },
      { keepPreviousPeek: true },
    );
  }

  findMessageElement(messageId) {
    return (
      this.getItems().find((item) => item.dataset.messageId === messageId) ||
      null
    );
  }

  /**
   * Scrolls to the row with `data-message-id={messageId}`. Before any rows
   * exist the request is queued and runs when they arrive; once rows exist a
   * missing id returns false.
   */
  scrollToMessage(messageId, options = {}) {
    const element = this.findMessageElement(messageId);

    if (!element) {
      if (this.itemCount === 0) {
        this.pendingScrollToMessage = { messageId, options };
        this.markDefaultScrollPositionApplied();
        return true;
      }
      return false;
    }

    this.markDefaultScrollPositionApplied();
    if (this.scrollToElement(element, options)) {
      this.pendingScrollToMessage = null;
      return true;
    }
    this.pendingScrollToMessage = { messageId, options };
    return true;
  }

  flushPendingScrollToMessage() {
    const pending = this.pendingScrollToMessage;
    if (!pending) return false;

    const element = this.findMessageElement(pending.messageId);
    if (!element || !this.scrollToElement(element, pending.options)) {
      return false;
    }

    this.pendingScrollToMessage = null;
    this.markDefaultScrollPositionApplied();
    return true;
  }

  applyDefaultScrollPosition() {
    if (this.defaultScrollPositionApplied || this.itemCount === 0) return false;
    if (!this.viewport || !this.content) return false;

    const position = this.opts.defaultScrollPosition;
    let handled;

    if (position === "last-anchor") {
      const items = this.getItems();
      let anchor = null;
      for (let index = items.length - 1; index >= 0; index--) {
        if (items[index].dataset.scrollAnchor === "true") {
          anchor = items[index];
          break;
        }
      }

      if (!anchor) {
        handled = this.scrollToEnd({ behavior: "auto" });
      } else {
        // A short last turn already fits: opening at the end shows all of it
        // without a blank gap beneath.
        const fits =
          this.getContentBottom() - this.getElementTop(anchor) <=
          this.viewport.clientHeight;
        handled = fits
          ? this.scrollToEnd({ behavior: "auto" })
          : this.scrollToElement(
              anchor,
              { align: "start" },
              { keepPreviousPeek: true },
            );
      }
    } else if (position === "end") {
      handled = this.scrollToEnd({ behavior: "auto" });
    } else {
      handled = this.scrollToStart({ behavior: "auto" });
    }

    if (!handled) return false;
    this.markDefaultScrollPositionApplied();
    return true;
  }

  // --- prepend preservation ------------------------------------------------

  capturePrependAnchor() {
    if (!this.content || !this.viewport) {
      this.prependRestore = null;
      return;
    }
    const anchor = this.getFirstVisibleMessageItem();
    this.prependRestore = anchor
      ? { element: anchor, viewportTop: this.getElementViewportTop(anchor) }
      : null;
  }

  // Compares the anchor relative to the viewport, so this is a no-op where
  // native scroll anchoring already handled the prepend and only corrects the
  // scroll where it did not (e.g. Safari).
  restorePrependedAnchor() {
    const anchor = this.prependRestore;
    if (!anchor || !this.viewport || !anchor.element.isConnected) return false;

    const delta =
      this.getElementViewportTop(anchor.element) - anchor.viewportTop;
    if (Math.abs(delta) <= SCROLL_POSITION_EPSILON) return false;

    this.viewport.scrollTop += delta;
    // Keep lastScrollTop in step so the correction does not read as the
    // reader scrolling.
    this.lastScrollTop = this.viewport.scrollTop;
    anchor.viewportTop = this.getElementViewportTop(anchor.element);
    this.scheduleStateCommit();
    this.scheduleVisibilitySync();
    return true;
  }

  // --- content & resize ----------------------------------------------------

  handleContentChange() {
    if (!this.content || !this.viewport || this.destroyed) return;

    const items = this.getItems();
    const previousCount = this.itemCount;
    const previousFirst = this.firstItem;

    this.itemCount = items.length;
    this.firstItem = items[0] ?? null;

    // Rows this instance has not seen before, and where the surviving rows
    // sit, tell a prepend (history) from an append (a new turn) - even when
    // one patch removes the last row (a typing indicator) and appends the
    // reply in its place.
    let firstSurvivor = -1;
    let lastSurvivor = -1;
    items.forEach((item, index) => {
      if (this.seenItems.has(item)) {
        if (firstSurvivor < 0) firstSurvivor = index;
        lastSurvivor = index;
      }
    });
    items.forEach((item) => this.seenItems.add(item));

    this.syncObservedItems(items);
    this.reconcileScrollPosition({
      items,
      previousCount,
      previousFirst,
      firstSurvivor,
      lastSurvivor,
    });
    this.capturePrependAnchor();
  }

  // Branch order is load-bearing: queued jump, first content (or a replaced
  // transcript), prepend, rows pruned from the top, appended turn, update.
  reconcileScrollPosition({
    items,
    previousCount,
    previousFirst,
    firstSurvivor,
    lastSurvivor,
  }) {
    if (this.flushPendingScrollToMessage()) return;

    // A stream reset (or swapping in another conversation) removes every row
    // that was there: treat it like a freshly opened transcript.
    const replaced = previousCount > 0 && items.length > 0 && firstSurvivor < 0;
    // Emptying it (`stream(..., [], reset: true)` before the next conversation
    // loads) does the same, so the next rows open at the default position
    // and no reserved tail spacer is left behind.
    const emptied = previousCount > 0 && items.length === 0;
    if (replaced || emptied) {
      this.defaultScrollPositionApplied = false;
      this.setTailSpacerHeight(0);
      this.streamingTurn = null;
      this.mode = this.opts.autoScroll ? "following-bottom" : "free-scrolling";
    }

    if (emptied) {
      this.commitScrollState();
      this.scheduleVisibilitySync();
      return;
    }

    if (previousCount === 0 || replaced) {
      if (this.applyDefaultScrollPosition()) return;
      if (items.length > 0 && this.opts.autoScroll) {
        this.scrollToEnd({ behavior: "auto" });
        return;
      }
      this.commitScrollState();
      this.scheduleVisibilitySync();
      return;
    }

    const preserve = this.preserveScrollOnPrepend();
    const prepended = firstSurvivor > 0;
    // Rows pruned from the top (a stream `limit`) shift everything up too.
    const prunedTop = !!previousFirst && !items.includes(previousFirst);

    if (preserve && (prepended || prunedTop)) {
      // Prepended rows are history, not new turns: keep the reader's row put.
      this.restorePrependedAnchor();
    }

    const appended = lastSurvivor >= 0 ? items.slice(lastSurvivor + 1) : [];
    const newAnchors = appended.filter(
      (item) => item.dataset.scrollAnchor === "true",
    );

    if (newAnchors.length > 0) {
      // Following the live edge while several turns arrive at once keeps
      // following instead of yanking back to the first turn of the batch.
      if (
        this.opts.autoScroll &&
        this.mode === "following-bottom" &&
        newAnchors.length > 1
      ) {
        this.scrollToEnd({ behavior: "auto" });
        return;
      }

      this.scrollToElement(
        newAnchors[0],
        { align: "start" },
        { keepPreviousPeek: true },
      );
      return;
    }

    if (this.mode === "following-bottom" && this.opts.autoScroll) {
      this.scrollToEnd({ behavior: "auto" });
    } else {
      this.commitScrollState();
      this.scheduleVisibilitySync();
    }
  }

  handleResize() {
    if (this.destroyed || !this.viewport) return;

    if (this.mode === "following-bottom" && this.opts.autoScroll) {
      this.scrollToEnd({ behavior: "auto" });
      return;
    }

    // Hold the anchored turn as content below it resizes (a reply streaming
    // in), so the shrinking spacer does not let scrollTop clamp.
    const previousSpacer = this.spacerHeight;
    if (this.reanchorToAnchoredMessage()) {
      // Once the reply has consumed the spacer the reader is at the live
      // edge, so autoScroll takes over from the anchor hold.
      if (
        this.opts.autoScroll &&
        previousSpacer > 0 &&
        this.spacerHeight === 0
      ) {
        this.scrollToEnd({ behavior: "auto" });
      }
      return;
    }

    if (this.drainReleasedSpacer()) return;

    this.scheduleStateCommit();
    this.scheduleVisibilitySync();
  }

  userScrollIntent() {
    if (
      this.mode === "following-bottom" ||
      this.mode === "anchored-to-message" ||
      this.mode === "settling-jump"
    ) {
      this.streamingTurn = null;
      this.mode = "free-scrolling";
    }
  }

  syncAfterScroll() {
    if (this.destroyed || !this.viewport) return;
    this.drainReleasedSpacer();
    this.commitScrollState();
    this.scheduleVisibilitySync();
    this.capturePrependAnchor();
  }

  // --- visibility ----------------------------------------------------------

  tracksVisibility() {
    return !!this.eventMappings?.["visibility-change"];
  }

  startVisibilityTracking() {
    if (!this.tracksVisibility() || !this.viewport) return;

    const IntersectionObserverImpl = window.IntersectionObserver;
    if (
      typeof IntersectionObserverImpl === "function" &&
      !this.intersectionObserver
    ) {
      const line = this.opts.scrollMargin + this.opts.scrollPreviousItemPeek;
      this.intersectionObserver = new IntersectionObserverImpl(
        this.onIntersection,
        {
          root: this.viewport,
          // Shrink the top edge to the reading line so a previous turn
          // peeking above it is not reported as visible.
          rootMargin: `${-line}px 0px 0px 0px`,
          threshold: [0, 0.01, 0.5, 1],
        },
      );
    }
    this.observedItems.clear();
    this.syncObservedItems(this.getItems());
    this.scheduleVisibilitySync();
  }

  stopVisibilityTracking() {
    this.intersectionObserver?.disconnect();
    this.intersectionObserver = null;
    this.observedItems.clear();
    this.visibleIds.clear();
    this.visibility = { currentAnchorId: null, visibleMessageIds: [] };
  }

  syncObservedItems(items) {
    const observer = this.intersectionObserver;
    if (!observer) return;

    const current = new Set(items.filter((item) => item.dataset.messageId));
    this.observedItems.forEach((item) => {
      if (!current.has(item)) {
        observer.unobserve(item);
        this.observedItems.delete(item);
        if (item.dataset.messageId)
          this.visibleIds.delete(item.dataset.messageId);
      }
    });
    current.forEach((item) => {
      if (!this.observedItems.has(item)) {
        observer.observe(item);
        this.observedItems.add(item);
      }
    });
  }

  onIntersection(entries) {
    for (const entry of entries) {
      const messageId = entry.target.dataset?.messageId;
      if (!messageId) continue;
      if (entry.isIntersecting) this.visibleIds.add(messageId);
      else this.visibleIds.delete(messageId);
    }
    this.scheduleVisibilitySync();
  }

  scheduleVisibilitySync() {
    if (!this.tracksVisibility() || this.visibilityFrame !== null) return;
    this.visibilityFrame = window.requestAnimationFrame(() => {
      this.visibilityFrame = null;
      this.syncVisibility();
    });
  }

  computeVisibility() {
    if (!this.content || !this.viewport) {
      return { currentAnchorId: null, visibleMessageIds: [] };
    }

    const viewportRect = this.viewport.getBoundingClientRect();
    // Anchored turns land at the reading line with the previous turn peeking
    // above; a row only peeking in that band is neither visible nor current.
    const lineTop =
      viewportRect.top +
      this.opts.scrollMargin +
      this.opts.scrollPreviousItemPeek;
    const byLayout = !this.intersectionObserver;
    const visible = [];
    let currentAnchorId = null;

    for (const item of this.getItems()) {
      const messageId = item.dataset.messageId;
      if (!messageId) continue;

      const isAnchor = item.dataset.scrollAnchor === "true";
      const rect = isAnchor || byLayout ? item.getBoundingClientRect() : null;
      const isVisible =
        byLayout && rect
          ? rect.bottom > lineTop && rect.top < viewportRect.bottom
          : this.visibleIds.has(messageId);

      if (isVisible) visible.push(messageId);
      // The last anchor to reach the reading line is the current turn; it
      // stays current after its header scrolls above the viewport.
      if (isAnchor && rect && rect.top <= lineTop + SCROLL_POSITION_EPSILON) {
        currentAnchorId = messageId;
      }
    }

    return { currentAnchorId, visibleMessageIds: visible };
  }

  syncVisibility() {
    if (this.destroyed || !this.tracksVisibility()) return;

    const next = this.computeVisibility();
    const previous = this.visibility;
    if (
      previous.currentAnchorId === next.currentAnchorId &&
      sameIds(previous.visibleMessageIds, next.visibleMessageIds)
    ) {
      return;
    }

    this.visibility = next;
    this.pushEvent("visibility-change", {
      current_anchor_id: next.currentAnchorId,
      visible_message_ids: next.visibleMessageIds,
    });
  }

  beforeDestroy() {
    this.stopVisibilityTracking();
  }
}

SaladUI.register("message-scroller", MessageScrollerComponent);

export default MessageScrollerComponent;
