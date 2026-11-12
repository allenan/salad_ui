// saladui/components/hover_card.js
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
  openDelay: 300,
  closeDelay: 200,
};

class HoverCardComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    // Initialize core properties
    this.trigger = this.getPart("trigger");
    this.content = this.getPart("content");

    // Set config from options with fallbacks to defaults
    this.config.openDelay =
      this.options.openDelay || DEFAULT_TIMING_CONFIG.openDelay;
    this.config.closeDelay =
      this.options.closeDelay || DEFAULT_TIMING_CONFIG.closeDelay;

    // Track timer IDs for delayed open/close
    this.openTimer = null;
    this.closeTimer = null;
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
              mouseenter: "delayOpen",
              focusin: "delayOpen",
            },
          },
        },
        open: {
          mouseMap: {
            trigger: {
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
            expanded: "true",
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

  // Generic methods for delayed state transitions
  delayOpen() {
    this.clearTimers();
    this.openTimer = setTimeout(() => {
      this.transition("open");
    }, this.config.openDelay);
  }

  delayClose() {
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

    if (this.positionedElement) {
      this.positionedElement.destroy();
      this.positionedElement = null;
    }
  }
}

// Register the component
SaladUI.register("hover-card", HoverCardComponent);

export default HoverCardComponent;
