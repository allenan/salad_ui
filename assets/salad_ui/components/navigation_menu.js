// saladui/components/navigation_menu.js
import Component from "../core/component.js";
import ClickOutsideMonitor from "../core/click-outside.js";
import SaladUI from "../index.js";

const DEFAULTS = {
  delayDuration: 200,
  skipDelayDuration: 300,
  // Radix's grace period between leaving a trigger/panel and closing, long
  // enough to cross the gap between the list and the viewport.
  closeDelay: 150,
  // Longest exit animation (tw-animate-css defaults to 150ms). Parts are only
  // hidden/moved back once it has finished.
  animationDuration: 200,
};

const TABBABLE =
  'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

const VIEWPORT_WIDTH = "--navigation-menu-viewport-width";
const VIEWPORT_HEIGHT = "--navigation-menu-viewport-height";

function numberOption(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
}

/**
 * NavigationMenuComponent — a port of Radix's NavigationMenu.
 *
 * The root state machine only tracks whether *any* item is open; which one is
 * open lives in `this.value` (the item's data-value, "" when closed). Each
 * item's trigger/content state, the shared viewport and the indicator are
 * driven from `setValue()`.
 *
 * With a viewport, the open item's content element is moved into the
 * viewport while it is shown and moved back to its item once hidden (and
 * before every LiveView patch, see beforeUpdate()).
 */
class NavigationMenuComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext, initialState: "closed" });

    this.config.delayDuration = numberOption(
      this.options.delayDuration,
      DEFAULTS.delayDuration,
    );
    this.config.skipDelayDuration = numberOption(
      this.options.skipDelayDuration,
      DEFAULTS.skipDelayDuration,
    );
    this.config.closeDelay = numberOption(
      this.options.closeDelay,
      DEFAULTS.closeDelay,
    );
    this.config.animationDuration = numberOption(
      this.options.animationDuration,
      DEFAULTS.animationDuration,
    );

    this.list = this.getPart("list");
    this.viewport = this.getPart("viewport") || null;
    this.indicator = this.getPart("indicator") || null;
    this.useViewport =
      !!this.viewport && this.el.getAttribute("data-viewport") !== "false";

    this.value = "";
    this.openTimer = null;
    this.closeTimer = null;
    this.viewportTimer = null;
    this.indicatorTimer = null;
    this.lastClosedAt = 0;
    this.clickClosedValue = null;

    this.items = this.collectItems();
    this.syncParts();
  }

  getComponentConfig() {
    return {
      stateMachine: {
        closed: { transitions: { open: "open" } },
        open: { transitions: { close: "closed" } },
      },
    };
  }

  collectItems() {
    const parts = this.queryParts();
    const partOf = (element, name) =>
      parts.find(
        (node) =>
          node.dataset.part === name &&
          node.closest("[data-part='item']") === element,
      ) || null;

    return parts
      .filter((node) => node.dataset.part === "item")
      .map((element, index) => {
        const value = element.dataset.value || `item-${index}`;
        const trigger = partOf(element, "trigger");
        const content = partOf(element, "content");

        if (trigger && !trigger.id) {
          trigger.id = `${this.el.id}-trigger-${value}`;
        }
        if (content && !content.id) {
          content.id = `${this.el.id}-content-${value}`;
        }
        if (trigger && content) {
          trigger.setAttribute("aria-controls", content.id);
          content.setAttribute("aria-labelledby", trigger.id);
        }

        return {
          value,
          index,
          element,
          trigger,
          content,
          home: content?.parentElement || null,
          homeNext: content?.nextSibling || null,
          hideTimer: null,
        };
      });
  }

  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------

  // The base implementation stamps the root state on every part; here each
  // trigger needs its own state, so only the root carries the menu state.
  updateUI() {
    this.el.setAttribute("data-state", this.stateMachine.state);
    if (this.items) this.syncParts();
  }

  syncParts() {
    this.items.forEach((item) => {
      if (!item.trigger) return;
      const open = item.value === this.value;
      item.trigger.setAttribute("data-state", open ? "open" : "closed");
      item.trigger.setAttribute("aria-expanded", String(open));
    });
  }

  itemByValue(value) {
    if (!value) return null;
    return (
      this.items.find((item) => item.value === value && item.content) || null
    );
  }

  /**
   * Open the item with `value` ("" closes the menu). Handles motion
   * direction, the viewport, the indicator and the value-changed event.
   */
  setValue(value) {
    const nextValue = this.itemByValue(value) ? value : "";
    const prevValue = this.value;
    if (nextValue === prevValue) return;

    const prevItem = this.itemByValue(prevValue);
    const nextItem = this.itemByValue(nextValue);
    this.value = nextValue;

    let motion = { prev: null, next: null };
    if (prevItem && nextItem) {
      const forward = nextItem.index > prevItem.index;
      motion = {
        prev: forward ? "to-start" : "to-end",
        next: forward ? "from-end" : "from-start",
      };
    }

    if (prevItem) this.hideContent(prevItem, motion.prev);
    if (nextItem) this.showContent(nextItem, motion.next);

    if (nextItem && this.state !== "open") {
      this.transition("open");
    } else if (!nextItem && this.state !== "closed") {
      this.lastClosedAt = Date.now();
      this.transition("close");
    }

    this.syncParts();
    this.updateViewport(nextItem);
    this.updateIndicator(nextItem);
    this.updateClickOutside();

    this.pushEvent("value-changed", { value: nextValue });
  }

  showContent(item, motion) {
    clearTimeout(item.hideTimer);
    item.hideTimer = null;

    const { content } = item;
    if (this.useViewport && content.parentElement !== this.viewport) {
      this.viewport.appendChild(content);
    }

    content.hidden = false;
    content.setAttribute("data-state", "open");
    if (motion) content.setAttribute("data-motion", motion);
    else content.removeAttribute("data-motion");
  }

  hideContent(item, motion) {
    const { content } = item;
    content.setAttribute("data-state", "closed");
    if (motion) content.setAttribute("data-motion", motion);
    else content.removeAttribute("data-motion");

    clearTimeout(item.hideTimer);
    item.hideTimer = setTimeout(() => {
      item.hideTimer = null;
      if (this.destroyed || this.value === item.value) return;
      content.hidden = true;
      content.removeAttribute("data-motion");
      this.restoreContent(item);
    }, this.config.animationDuration);
  }

  restoreContent(item) {
    const { content, home, homeNext } = item;
    if (!content || !home || content.parentElement === home) return;
    const before = homeNext?.parentNode === home ? homeNext : null;
    home.insertBefore(content, before);
  }

  updateViewport(activeItem) {
    if (!this.useViewport) return;

    clearTimeout(this.viewportTimer);
    this.viewportTimer = null;
    this.observeContent(activeItem?.content || null);

    if (activeItem) {
      this.viewport.hidden = false;
      this.viewport.setAttribute("data-state", "open");
      this.measureViewport();
      return;
    }

    this.viewport.setAttribute("data-state", "closed");
    this.viewportTimer = setTimeout(() => {
      this.viewportTimer = null;
      if (this.destroyed || this.value) return;
      this.viewport.hidden = true;
      // Drop the size so the next open starts from `auto` instead of
      // animating from the last panel's size.
      this.viewport.style.removeProperty(VIEWPORT_WIDTH);
      this.viewport.style.removeProperty(VIEWPORT_HEIGHT);
    }, this.config.animationDuration);
  }

  measureViewport() {
    const content = this.itemByValue(this.value)?.content;
    if (!this.viewport || !content) return;
    // offsetWidth/Height ignore the viewport's zoom transform.
    this.viewport.style.setProperty(VIEWPORT_WIDTH, `${content.offsetWidth}px`);
    this.viewport.style.setProperty(
      VIEWPORT_HEIGHT,
      `${content.offsetHeight}px`,
    );
  }

  observeContent(content) {
    this.resizeObserver?.disconnect();
    if (!content || typeof ResizeObserver === "undefined") return;
    if (!this.resizeObserver) {
      this.resizeObserver = new ResizeObserver(() => this.measureViewport());
    }
    this.resizeObserver.observe(content);
  }

  updateIndicator(activeItem) {
    const indicator = this.indicator;
    if (!indicator) return;

    clearTimeout(this.indicatorTimer);
    this.indicatorTimer = null;

    if (activeItem?.trigger) {
      const parent = indicator.offsetParent || this.el;
      const parentRect = parent.getBoundingClientRect();
      const triggerRect = activeItem.trigger.getBoundingClientRect();

      indicator.hidden = false;
      indicator.setAttribute("data-state", "visible");
      Object.assign(indicator.style, {
        position: "absolute",
        left: "0px",
        width: `${triggerRect.width}px`,
        transform: `translateX(${triggerRect.left - parentRect.left}px)`,
      });
      return;
    }

    indicator.setAttribute("data-state", "hidden");
    this.indicatorTimer = setTimeout(() => {
      this.indicatorTimer = null;
      if (this.destroyed || this.value) return;
      indicator.hidden = true;
    }, this.config.animationDuration);
  }

  updateClickOutside() {
    if (!this.clickOutside) return;
    if (this.value) this.clickOutside.start();
    else this.clickOutside.stop();
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  setupComponentEvents() {
    super.setupComponentEvents();

    this.listeners = [];
    const on = (element, type, handler) => {
      if (!element) return;
      element.addEventListener(type, handler);
      this.listeners.push([element, type, handler]);
    };

    this.items.forEach((item) => {
      if (!item.trigger || !item.content) return;
      on(item.trigger, "pointerenter", (e) => this.onTriggerEnter(item, e));
      on(item.trigger, "pointerleave", (e) => this.onPointerLeave(e));
      on(item.trigger, "click", () => this.onTriggerClick(item));
    });

    // With a viewport every panel lives inside it, so hover tracking happens
    // on the viewport alone (pointerleave on a panel would also fire when the
    // pointer merely moves onto the viewport's padding around it).
    const panels = this.useViewport
      ? [this.viewport]
      : this.items.map((item) => item.trigger && item.content);
    panels.filter(Boolean).forEach((panel) => {
      on(panel, "pointerenter", (e) => this.onPanelEnter(e));
      on(panel, "pointerleave", (e) => this.onPointerLeave(e));
    });

    on(this.el, "keydown", (e) => this.onKeyDown(e));
    on(this.el, "click", (e) => this.onRootClick(e));
    on(this.el, "focusout", (e) => this.onFocusOut(e));

    this.clickOutside = new ClickOutsideMonitor(this.el, () => this.dismiss());
    this.updateClickOutside();
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.listeners?.forEach(([element, type, handler]) =>
      element.removeEventListener(type, handler),
    );
    this.listeners = null;
    this.clickOutside?.destroy();
    this.clickOutside = null;
  }

  isTouch(event) {
    return event?.pointerType === "touch";
  }

  onTriggerEnter(item, event) {
    if (this.isTouch(event) || item.trigger.disabled) return;
    if (this.clickClosedValue === item.value) return;

    this.clearCloseTimer();
    this.clearOpenTimer();
    if (this.value === item.value) return;

    const skipDelay =
      this.value ||
      Date.now() - this.lastClosedAt < this.config.skipDelayDuration;

    if (skipDelay || this.config.delayDuration === 0) {
      this.setValue(item.value);
      return;
    }

    this.openTimer = setTimeout(() => {
      this.openTimer = null;
      this.setValue(item.value);
    }, this.config.delayDuration);
  }

  onPointerLeave(event) {
    if (this.isTouch(event)) return;
    this.clickClosedValue = null;
    this.clearOpenTimer();
    this.startCloseTimer();
  }

  onPanelEnter(event) {
    if (this.isTouch(event)) return;
    this.clearCloseTimer();
  }

  onTriggerClick(item) {
    if (item.trigger.disabled) return;
    this.clearOpenTimer();
    this.clearCloseTimer();

    if (this.value === item.value) {
      // Like Radix: don't let the still-hovering pointer reopen it.
      this.clickClosedValue = item.value;
      this.setValue("");
    } else {
      this.clickClosedValue = null;
      this.setValue(item.value);
    }
  }

  onRootClick(event) {
    if (event.target.closest?.("[data-part='link']")) this.dismiss();
  }

  onFocusOut(event) {
    const next = event.relatedTarget;
    if (next && !this.el.contains(next)) this.dismiss();
  }

  dismiss() {
    this.clearOpenTimer();
    this.clearCloseTimer();
    this.setValue("");
  }

  startCloseTimer() {
    this.clearCloseTimer();
    if (!this.value) return;
    this.closeTimer = setTimeout(() => {
      this.closeTimer = null;
      this.setValue("");
    }, this.config.closeDelay);
  }

  clearOpenTimer() {
    clearTimeout(this.openTimer);
    this.openTimer = null;
  }

  clearCloseTimer() {
    clearTimeout(this.closeTimer);
    this.closeTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Keyboard
  // ---------------------------------------------------------------------------

  isRtl() {
    return this.el.closest("[dir]")?.getAttribute("dir") === "rtl";
  }

  /** Top-level triggers and links, in DOM order, that can take focus. */
  topLevelFocusables() {
    const scope = this.list || this.el;
    return Array.from(
      scope.querySelectorAll("[data-part='trigger'], [data-part='link']"),
    ).filter(
      (node) =>
        !node.closest("[data-part='content']") &&
        !node.disabled &&
        node.getAttribute("aria-disabled") !== "true",
    );
  }

  tabbables(container) {
    return Array.from(container.querySelectorAll(TABBABLE)).filter(
      (node) => !node.hidden && !node.closest("[hidden]"),
    );
  }

  focus(element) {
    if (!element) return false;
    element.focus();
    return true;
  }

  onKeyDown(event) {
    if (event.defaultPrevented) return;

    if (event.key === "Escape") {
      const item = this.itemByValue(this.value);
      if (!item) return;
      event.preventDefault();
      this.dismiss();
      item.trigger?.focus();
      return;
    }

    const content = event.target.closest?.("[data-part='content']");
    if (content) {
      const item = this.items.find((i) => i.content === content);
      if (item) this.onContentKeyDown(event, item);
      return;
    }

    const focusables = this.topLevelFocusables();
    const index = focusables.indexOf(event.target);
    if (index === -1) return;

    const item = this.items.find((i) => i.trigger === event.target);
    const isOpenTrigger = item && item.value === this.value;

    if (isOpenTrigger && event.key === "ArrowDown") {
      event.preventDefault();
      this.focus(this.tabbables(item.content)[0]);
      return;
    }

    if (isOpenTrigger && event.key === "Tab" && !event.shiftKey) {
      if (this.focus(this.tabbables(item.content)[0])) event.preventDefault();
      return;
    }

    const rtl = this.isRtl();
    const keys = {
      ArrowRight: rtl ? index - 1 : index + 1,
      ArrowLeft: rtl ? index + 1 : index - 1,
      Home: 0,
      End: focusables.length - 1,
    };
    if (!(event.key in keys)) return;

    event.preventDefault();
    this.focus(focusables[keys[event.key]]);
  }

  onContentKeyDown(event, item) {
    if (event.key === "Tab") {
      const tabbables = this.tabbables(item.content);
      const index = tabbables.indexOf(event.target);

      if (event.shiftKey && index <= 0) {
        event.preventDefault();
        item.trigger?.focus();
        return;
      }

      if (!event.shiftKey && index === tabbables.length - 1) {
        // Leave the panel for whatever follows its trigger in the list.
        const focusables = this.topLevelFocusables();
        const next = focusables[focusables.indexOf(item.trigger) + 1];
        if (next) {
          event.preventDefault();
          this.dismiss();
          next.focus();
        }
      }
      return;
    }

    if (/^(INPUT|TEXTAREA|SELECT)$/.test(event.target.tagName)) return;

    const links = Array.from(
      item.content.querySelectorAll("[data-part='link']"),
    );
    const index = links.indexOf(event.target);
    if (index === -1) return;

    const keys = {
      ArrowDown: index + 1,
      ArrowRight: index + 1,
      ArrowUp: index - 1,
      ArrowLeft: index - 1,
      Home: 0,
      End: links.length - 1,
    };
    if (!(event.key in keys)) return;

    event.preventDefault();
    this.focus(links[keys[event.key]]);
  }

  // ---------------------------------------------------------------------------
  // Commands & lifecycle
  // ---------------------------------------------------------------------------

  handleCommand(command, params = {}) {
    switch (command) {
      case "open": {
        const value =
          params.value ?? this.items.find((i) => i.trigger && i.content)?.value;
        this.setValue(value || "");
        return true;
      }
      case "close":
        this.dismiss();
        return true;
      default:
        return false;
    }
  }

  restoreAllContent() {
    this.items?.forEach((item) => this.restoreContent(item));
  }

  // LiveView must see contents back inside their items before it patches.
  beforeUpdate() {
    this.restoreAllContent();
  }

  beforeDestroy() {
    this.clearOpenTimer();
    this.clearCloseTimer();
    clearTimeout(this.viewportTimer);
    clearTimeout(this.indicatorTimer);
    this.items?.forEach((item) => clearTimeout(item.hideTimer));
    this.resizeObserver?.disconnect();
    this.resizeObserver = null;
    this.restoreAllContent();
  }
}

SaladUI.register("navigation-menu", NavigationMenuComponent);

export default NavigationMenuComponent;
