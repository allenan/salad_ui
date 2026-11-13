import Component from "../core/component.js";
import SaladUI from "../index.js";
import PositionedElement from "../core/positioned-element.js";
import {
  DetachedHoverTriggers,
  HoverPopup,
  tooltipSkipsDelay,
} from "../core/hover-popups.js";
import {
  DetachedAnchor,
  listen,
  listenAttribute,
  readContext,
} from "../core/detached-triggers.js";

// Define constants at the module level outside the class
const DEFAULT_POSITION_CONFIG = {
  placement: "top",
  alignment: "center",
  sideOffset: 8,
  alignOffset: 0,
};

const DEFAULT_TIMING_CONFIG = {
  openDelay: 150,
  closeDelay: 100,
  // Radix's skipDelayDuration: a shared tooltip opened this soon after
  // another tooltip closed (or while one is open) skips its open delay.
  skipDelay: 300,
};

/**
 * Tooltip. Its trigger is either nested in the root (`data-part="trigger"`,
 * or the first child), or detached: any element on the page naming the root
 * in `data-salad-for` (a shared tooltip serving many rows, see
 * core/detached-triggers.js). `this.trigger` is the trigger the tooltip is
 * open (or about to open) for.
 */
class TooltipComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    // Initialize core properties
    this.trigger = this.getPart("trigger") || this.getFallbackTrigger();
    this.content = this.getPart("content");

    if (this.trigger && this.trigger.dataset.part !== "trigger") {
      this.trigger.dataset.part = "trigger";
      this.allParts = this.queryParts();
      this.updateUI();
      this.updatePartsVisibility();
    }
    this.nestedTrigger = this.trigger || null;

    // Set config from options with fallbacks to defaults
    this.config.openDelay =
      this.options.openDelay || DEFAULT_TIMING_CONFIG.openDelay;
    this.config.closeDelay =
      this.options.closeDelay || DEFAULT_TIMING_CONFIG.closeDelay;
    this.config.skipDelay =
      this.options.skipDelay ?? DEFAULT_TIMING_CONFIG.skipDelay;

    // Track timer IDs for delayed open/close
    this.openTimer = null;
    this.closeTimer = null;
    // The trigger a pending open (openTimer) is for.
    this.pendingTrigger = null;

    this.isTooltip = true;
    this.hoverPopup = new HoverPopup(this);
    this.detached = new DetachedAnchor({
      expanded: false,
      // A trigger is often a menu trigger too, whose data-state the menu owns.
      state: false,
      describedBy: () => this.contentId(),
      onRemoved: () => this.closeNow(),
    });
    this.detachedTriggers = new DetachedHoverTriggers(this, (type, handler) =>
      this.subscribeDetached(type, handler),
    );
  }

  getFallbackTrigger() {
    return Array.from(this.el.children).find(
      (child) => child.dataset.part !== "content",
    );
  }

  // Detached triggers: those naming this tooltip in `data-salad-for`.
  subscribeDetached(type, handler) {
    return listen(this.el.id, type, handler);
  }

  contentId() {
    return this.getPartId("content");
  }

  // The detached trigger the tooltip is open for (null: the nested one).
  get activeTrigger() {
    return this.detached?.trigger || null;
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    this.detachedTriggers.start();
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.detachedTriggers.stop();
  }

  // The content gets a client id for aria-describedby; drop it so the patch
  // keeps the element instead of replacing it (see skipReinitialize).
  beforeUpdate() {
    this.clearGeneratedIds();
  }

  /**
   * A LiveView patch anywhere around the tooltip puts back its server-rendered
   * markup: the content `hidden` and closed, without its id. Rebuilding would close a
   * tooltip the pointer is still on. Keep the instance (and its pending
   * open/close timer) and re-apply the state, unless the options or event
   * mappings changed.
   */
  skipReinitialize(el) {
    if (!this.sameConfig(el)) return false;

    // A trigger found by position had its data-part stamped by the client,
    // which the patch removed.
    if (
      this.nestedTrigger &&
      !this.queryParts().some((part) => part.dataset.part === "trigger")
    ) {
      const fallback = this.getFallbackTrigger();
      if (fallback) fallback.dataset.part = "trigger";
    }
    this.refreshParts();
    const trigger = this.getPart("trigger") || null;
    const content = this.getPart("content");
    if (trigger !== this.nestedTrigger || content !== this.content) {
      // The positioned element is bound to the old elements.
      this.positionedElement?.destroy();
      this.positionedElement = null;
      this.nestedTrigger = trigger;
      if (!this.activeTrigger) this.trigger = trigger;
      this.content = content;
    }

    this.reapplyState();
    if (this.state === "open") {
      // The content's client id went with the patch: name it again.
      this.detached.sync(true);
      // The patch dropped the inline position: place the content again.
      this.positionedElement?.deactivate();
      this.initializePositionedElement();
      this.positionedElement?.activate();
    }

    return true;
  }

  getComponentConfig() {
    return {
      stateMachine: {
        closed: {
          enter: "onClosedEnter",
          transitions: {
            open: "open",
          },
        },
        open: {
          enter: "onOpenEnter",
          exit: "onOpenExit",
          transitions: {
            close: "closed",
          },
        },
      },
      events: {
        // Enter and leave are heard in every state: leaving during the open
        // delay must cancel it, or the tooltip opens after the pointer left.
        _all: {
          mouseMap: {
            trigger: {
              mouseover: "delayOpen",
              focusin: "delayOpen",
              mouseout: "delayClose",
              focusout: "delayClose",
              // Radix closes a tooltip when its trigger is pressed.
              pointerdown: "closeNow",
            },
            content: {
              mouseover: "clearTimers",
              mouseout: "delayClose",
            },
          },
        },
      },
      hiddenConfig: {
        closed: {
          content: true,
        },
        open: {
          content: false,
        },
      },
      ariaConfig: {
        trigger: {
          all: {
            describedby: () => this.getPartId("content"),
          },
        },
        content: {
          all: {
            role: "tooltip",
          },
        },
      },
    };
  }

  /**
   * Opens after the open delay, for `trigger` (the nested trigger by
   * default). A detached trigger opens at once while a tooltip is open or
   * right after one closed (`skipDelay`), as with Radix's provider.
   */
  delayOpen(event, trigger = this.nestedTrigger) {
    if (!trigger) return;
    if (this.state === "open" && trigger === this.trigger) {
      this.clearTimers();
      return;
    }
    if (!this.hoverPopup.mayOpen(event, trigger)) return;

    const detached = trigger !== this.nestedTrigger;
    if (
      detached &&
      (this.state === "open" || tooltipSkipsDelay(this.config.skipDelay))
    ) {
      this.clearTimers();
      this.openFor(trigger);
      return;
    }

    this.clearTimers();
    this.pendingTrigger = trigger;
    this.openTimer = setTimeout(() => {
      this.openTimer = null;
      this.pendingTrigger = null;
      if (!trigger.isConnected || this.hoverPopup.blocked(trigger)) return;
      this.openFor(trigger);
    }, this.config.openDelay);
  }

  /** Shows the tooltip for `trigger`, moving it there when open elsewhere. */
  openFor(trigger) {
    if (this.state === "open") {
      if (trigger === this.trigger) return;
      this.transition("close");
    }

    const detached = trigger === this.nestedTrigger ? null : trigger;
    this.trigger = trigger;
    this.detached.set(detached, readContext(detached));
    this.prepareContent(trigger);
    this.transition("open");
  }

  // Subclasses fill the content for the trigger (the tooltip provider).
  prepareContent(_trigger) {}

  // The pointer or focus left a detached trigger (see DetachedHoverTriggers).
  enterTrigger(event, trigger) {
    this.delayOpen(event, trigger);
  }

  leaveTrigger(_event, trigger) {
    if (trigger === this.pendingTrigger) this.clearTimers();
    if (trigger === this.trigger && this.state === "open") this.delayClose();
  }

  pressTrigger(_event, trigger) {
    if (trigger === this.trigger || trigger === this.pendingTrigger) {
      this.closeNow();
    }
  }

  delayClose(event) {
    if (event?.currentTarget?.contains(event.relatedTarget)) return;

    this.clearTimers();
    if (this.state !== "open") return;
    this.closeTimer = setTimeout(() => {
      this.closeTimer = null;
      this.transition("close");
    }, this.config.closeDelay);
  }

  closeNow() {
    this.clearTimers();
    if (this.state === "open") this.transition("close");
  }

  clearTimers() {
    this.pendingTrigger = null;
    if (this.openTimer) {
      clearTimeout(this.openTimer);
      this.openTimer = null;
    }

    if (this.closeTimer) {
      clearTimeout(this.closeTimer);
      this.closeTimer = null;
    }
  }

  // Initialize the positioned element
  initializePositionedElement() {
    if (this.positionedElement) return;

    if (!this.trigger || !this.content) return;

    // Get positioning configuration from content attributes with fallbacks to defaults
    const positionConfig = {
      placement:
        this.content.getAttribute("data-side") ||
        DEFAULT_POSITION_CONFIG.placement,
      alignment:
        this.content.getAttribute("data-align") ||
        DEFAULT_POSITION_CONFIG.alignment,
      sideOffset:
        parseInt(this.content.getAttribute("data-side-offset"), 10) ||
        DEFAULT_POSITION_CONFIG.sideOffset,
      alignOffset:
        parseInt(this.content.getAttribute("data-align-offset"), 10) ||
        DEFAULT_POSITION_CONFIG.alignOffset,
      flip: true,
      usePortal: false,
      trapFocus: false,
      onPosition: ({ placement: actualPlacement }) => {
        this.content?.setAttribute("data-side", actualPlacement);
      },
    };

    // Create positioned element
    this.positionedElement = new PositionedElement(
      this.content,
      this.trigger,
      positionConfig,
    );
  }

  // State machine handlers
  onOpenEnter() {
    this.hoverPopup.opened();

    // Initialize positioned element if needed
    this.initializePositionedElement();

    // Activate positioned element
    if (this.positionedElement) {
      this.positionedElement.activate();
    }
    this.detached.activate();

    // Notify the server of the state change
    this.pushEvent("open", { ...this.detached.context });
  }

  onOpenExit() {
    this.hoverPopup.closed();
    this.detached.release();
    this.trigger = this.nestedTrigger;

    // Destroy the positioned element because there are too many tooltips, if we keep them all, it will costs more memory
    if (this.positionedElement) {
      this.positionedElement.destroy();
      this.positionedElement = null;
    }
  }

  onClosedEnter() {
    // Notify the server of the state change
    this.pushEvent("close");
  }

  beforeDestroy() {
    this.clearTimers();
    this.hoverPopup.closed();
    this.detached.teardown();

    // Clean up the positioned element if it exists
    if (this.positionedElement) {
      this.positionedElement.destroy();
      this.positionedElement = null;
    }
  }
}

// A text tooltip: `data-salad-tooltip="Reply"` on any element, shown by the
// page's tooltip provider. `data-salad-tooltip-side` / `-align` override the
// provider's placement for one trigger.
const TEXT_ATTR = "data-salad-tooltip";

/**
 * The one tooltip that shows every text tooltip (`data-salad-tooltip`) on the
 * page, or inside its `scope`, through delegated document listeners: no
 * hook and no tooltip markup per trigger. Hover, focus, Escape, scrolling,
 * the open/close delays, the skip delay and the coordination with other
 * popups (core/hover-popups.js) are the tooltip's.
 */
class TooltipProviderComponent extends TooltipComponent {
  constructor(el, hookContext) {
    super(el, hookContext);

    this.text = this.getPart("text") || this.content;
    this.placement = {
      side: this.content?.getAttribute("data-side") || "top",
      align: this.content?.getAttribute("data-align") || "center",
    };
  }

  // Every trigger is detached.
  getFallbackTrigger() {
    return null;
  }

  subscribeDetached(type, handler) {
    return listenAttribute(TEXT_ATTR, type, (event, trigger) => {
      if (this.inScope(trigger)) handler(event, trigger);
    });
  }

  inScope(trigger) {
    const scope = this.options?.scope;
    if (!scope) return true;
    try {
      return !!trigger.closest(scope);
    } catch {
      return false;
    }
  }

  // The content's id is server-rendered.
  contentId() {
    return this.content?.id || this.getPartId("content");
  }

  enterTrigger(event, trigger) {
    if (!trigger.getAttribute(TEXT_ATTR)) return;
    super.enterTrigger(event, trigger);
  }

  prepareContent(trigger) {
    if (!this.content || !this.text) return;

    this.text.textContent = trigger.getAttribute(TEXT_ATTR) || "";
    this.content.setAttribute(
      "data-side",
      trigger.getAttribute(`${TEXT_ATTR}-side`) || this.placement.side,
    );
    this.content.setAttribute(
      "data-align",
      trigger.getAttribute(`${TEXT_ATTR}-align`) || this.placement.align,
    );
  }

  // A patch of the provider (it has no dynamic markup) puts back the empty
  // text: write it again while open.
  skipReinitialize(el) {
    if (!super.skipReinitialize(el)) return false;
    this.text = this.getPart("text") || this.content;
    if (this.state === "open" && this.trigger) {
      this.text.textContent = this.trigger.getAttribute(TEXT_ATTR) || "";
    }
    return true;
  }
}

// Register the component
SaladUI.register("tooltip", TooltipComponent);
SaladUI.register("tooltip-provider", TooltipProviderComponent);

export { TooltipProviderComponent };
export default TooltipComponent;
