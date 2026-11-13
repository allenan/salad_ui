// saladui/components/hover_card.js
import Component from "../core/component.js";
import SaladUI from "../index.js";
import PositionedElement from "../core/positioned-element.js";
import { DetachedHoverTriggers, HoverPopup } from "../core/hover-popups.js";
import {
  DetachedAnchor,
  listen,
  readContext,
} from "../core/detached-triggers.js";

// Define constants at the module level outside the class
const DEFAULT_POSITION_CONFIG = {
  placement: "bottom",
  alignment: "center",
  sideOffset: 4,
  alignOffset: 0,
};

const DEFAULT_TIMING_CONFIG = {
  openDelay: 300,
  closeDelay: 200,
};

/**
 * Hover card. Its trigger is either nested in the root, or detached: any
 * element on the page naming the root in `data-salad-for` (one card per
 * user serving all their messages, or one card whose content the server
 * fills from the trigger's context in `on-open`). `this.trigger` is the
 * trigger the card is open for.
 */
class HoverCardComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    // Initialize core properties
    this.trigger = this.getPart("trigger") || null;
    this.nestedTrigger = this.trigger;
    this.content = this.getPart("content");

    // Set config from options with fallbacks to defaults
    this.config.openDelay =
      this.options.openDelay || DEFAULT_TIMING_CONFIG.openDelay;
    this.config.closeDelay =
      this.options.closeDelay || DEFAULT_TIMING_CONFIG.closeDelay;

    // Track timer IDs for delayed open/close
    this.openTimer = null;
    this.closeTimer = null;
    // The trigger a pending open (openTimer, or an `on-open` awaiting the
    // server's reply) is for.
    this.pendingTrigger = null;
    this.openRequest = null;

    this.hoverPopup = new HoverPopup(this);
    this.detached = new DetachedAnchor({
      onRemoved: () => this.closeNow(),
    });
    this.detachedTriggers = new DetachedHoverTriggers(this, (type, handler) =>
      listen(this.el.id, type, handler),
    );
  }

  // The detached trigger the card is open for (null: the nested one).
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

  /**
   * A LiveView patch around the hover card puts back its server-rendered
   * markup: the content `hidden` and closed, the trigger without its ARIA.
   * Rebuilding would close a card the pointer is still on. Keep the instance
   * (and its pending open/close timer) and re-apply the state, unless the
   * options or event mappings changed.
   */
  skipReinitialize(el) {
    if (!this.sameConfig(el)) return false;

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
        // delay must cancel it, or the card opens after the pointer left and
        // nothing closes it.
        _all: {
          mouseMap: {
            trigger: {
              mouseenter: "delayOpen",
              focusin: "delayOpen",
              mouseleave: "delayClose",
              focusout: "delayClose",
            },
            content: {
              mouseenter: "clearTimers",
              mouseleave: "delayClose",
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
            haspopup: "dialog",
          },
          open: {
            // Open at a detached trigger, the nested one stays collapsed.
            expanded: () => (this.activeTrigger ? "false" : "true"),
          },
          closed: {
            expanded: "false",
          },
        },
        content: {
          all: {
            role: "dialog",
          },
        },
      },
    };
  }

  /**
   * Opens after the open delay, for `trigger` (the nested trigger by
   * default). Open for another trigger, the card keeps its own close delay
   * running and moves over once the open delay has passed.
   */
  delayOpen(event, trigger = this.nestedTrigger) {
    if (!trigger) return;
    if (this.state === "open" && trigger === this.trigger) {
      this.clearTimers();
      return;
    }
    if (!this.hoverPopup.mayOpen(event, trigger)) return;

    if (this.state === "open") {
      this.cancelPendingOpen();
    } else {
      this.clearTimers();
    }
    this.pendingTrigger = trigger;
    this.openTimer = setTimeout(() => {
      this.openTimer = null;
      if (!trigger.isConnected || this.hoverPopup.blocked(trigger)) {
        this.pendingTrigger = null;
        return;
      }
      this.requestOpen(trigger);
    }, this.config.openDelay);
  }

  /**
   * A detached trigger with a context and a server `on-open` handler: push
   * `open` with the context first and show the card once the server replied
   * (and LiveView applied the content it rendered for that context), so it
   * never shows the previous trigger's content.
   */
  requestOpen(trigger) {
    const detached = trigger === this.nestedTrigger ? null : trigger;
    const context = readContext(detached);
    if (!detached || !context || typeof this.eventMappings.open !== "string") {
      this.pendingTrigger = null;
      this.openFor(trigger, context);
      return;
    }

    const request = {};
    this.openRequest = request;
    this.pushEvent("open", context, undefined, () => {
      if (this.openRequest !== request || this.destroyed) return;
      this.openRequest = null;
      this.pendingTrigger = null;
      if (trigger.isConnected) this.openFor(trigger, context, true);
    });
  }

  /** Shows the card for `trigger`, moving it there when open elsewhere. */
  openFor(trigger, context = null, pushed = false) {
    if (this.state === "open") {
      if (trigger === this.trigger) return;
      this.transition("close");
    }

    const detached = trigger === this.nestedTrigger ? null : trigger;
    this.trigger = trigger;
    this.detached.set(detached, context);
    this.transition("open", { pushed });
  }

  // The pointer or focus entered or left a detached trigger (see
  // DetachedHoverTriggers).
  enterTrigger(event, trigger) {
    this.delayOpen(event, trigger);
  }

  leaveTrigger(_event, trigger) {
    if (trigger === this.pendingTrigger) this.cancelPendingOpen();
    if (trigger === this.trigger && this.state === "open") this.delayClose();
  }

  delayClose(event) {
    // Focus moving within the trigger or into the card keeps it open.
    if (
      event?.type === "focusout" &&
      (this.trigger?.contains(event.relatedTarget) ||
        this.content?.contains(event.relatedTarget))
    ) {
      return;
    }

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

  cancelPendingOpen() {
    this.pendingTrigger = null;
    this.openRequest = null;
    if (this.openTimer) {
      clearTimeout(this.openTimer);
      this.openTimer = null;
    }
  }

  clearTimers() {
    this.cancelPendingOpen();

    if (this.closeTimer) {
      clearTimeout(this.closeTimer);
      this.closeTimer = null;
    }
  }

  // Initialize the positioned element
  initializePositionedElement() {
    if (this.positionedElement) {
      if (this.trigger && this.positionedElement.reference !== this.trigger) {
        this.positionedElement.updateReference(this.trigger);
      }
      return;
    }

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
      usePortal: false, // Don't use portal to keep DOM structure
      trapFocus: false,
    };

    // Create positioned element
    this.positionedElement = new PositionedElement(
      this.content,
      this.trigger,
      positionConfig,
    );
  }

  // State machine handlers
  onOpenEnter({ pushed = false } = {}) {
    this.hoverPopup.opened();

    // Initialize positioned element if needed
    this.initializePositionedElement();

    // Activate positioned element
    if (this.positionedElement) {
      this.positionedElement.activate();
    }
    this.detached.activate();

    // Notify the server of the state change (unless requestOpen() did).
    if (!pushed) this.pushEvent("open", { ...this.detached.context });
  }

  onOpenExit() {
    this.hoverPopup.closed();
    this.detached.release();
    this.trigger = this.nestedTrigger;

    // Deactivate positioned element
    if (this.positionedElement) {
      this.positionedElement.deactivate();
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

    if (this.positionedElement) {
      this.positionedElement.destroy();
      this.positionedElement = null;
    }
  }
}

// Register the component
SaladUI.register("hover-card", HoverCardComponent);

export default HoverCardComponent;
