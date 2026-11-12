import Component from "../core/component.js";
import SaladUI from "../index.js";
import PositionedElement from "../core/positioned-element.js";

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
};

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

    // Set config from options with fallbacks to defaults
    this.config.openDelay =
      this.options.openDelay || DEFAULT_TIMING_CONFIG.openDelay;
    this.config.closeDelay =
      this.options.closeDelay || DEFAULT_TIMING_CONFIG.closeDelay;

    // Track timer IDs for delayed open/close
    this.openTimer = null;
    this.closeTimer = null;
  }

  getFallbackTrigger() {
    return Array.from(this.el.children).find(
      (child) => child.dataset.part !== "content",
    );
  }

  /**
   * A LiveView patch anywhere around the tooltip puts back its server-rendered
   * markup: the content `hidden` and closed, and, because the content gets a
   * client-assigned id, often a new content element. Rebuilding would close a
   * tooltip the pointer is still on. Keep the instance (and its pending
   * open/close timer) and re-apply the state, unless the options or event
   * mappings changed.
   */
  skipReinitialize(el) {
    if (!this.sameConfig(el)) return false;

    // A trigger found by position had its data-part stamped by the client,
    // which the patch removed.
    if (!this.queryParts().some((part) => part.dataset.part === "trigger")) {
      const fallback = this.getFallbackTrigger();
      if (fallback) fallback.dataset.part = "trigger";
    }
    this.refreshParts();
    const trigger = this.getPart("trigger");
    const content = this.getPart("content");
    if (trigger !== this.trigger || content !== this.content) {
      // The positioned element is bound to the old elements.
      this.positionedElement?.destroy();
      this.positionedElement = null;
      this.trigger = trigger;
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
        closed: {
          mouseMap: {
            trigger: {
              mouseover: "delayOpen",
              focusin: "delayOpen",
            },
          },
        },
        open: {
          mouseMap: {
            trigger: {
              mouseout: "delayClose",
              focusout: "delayClose",
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

  // Generic methods for delayed state transitions
  delayOpen() {
    this.clearTimers();
    this.openTimer = setTimeout(() => {
      this.transition("open");
    }, this.config.openDelay);
  }

  delayClose(event) {
    if (event?.currentTarget?.contains(event.relatedTarget)) return;

    this.clearTimers();
    this.closeTimer = setTimeout(() => {
      this.transition("close");
    }, this.config.closeDelay);
  }

  clearTimers() {
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
    // Initialize positioned element if needed
    this.initializePositionedElement();

    // Activate positioned element
    if (this.positionedElement) {
      this.positionedElement.activate();
    }

    // Notify the server of the state change
    this.pushEvent("open");
  }

  onOpenExit() {
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

    // Clean up the positioned element if it exists
    if (this.positionedElement) {
      this.positionedElement.destroy();
      this.positionedElement = null;
    }
  }
}

// Register the component
SaladUI.register("tooltip", TooltipComponent);

export default TooltipComponent;
