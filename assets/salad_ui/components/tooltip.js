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

// Popups a tooltip must not compete with. While one is open, only tooltips
// whose trigger sits inside open popup content may show.
const OVERLAY_COMPONENTS = [
  "dialog",
  "drawer",
  "popover",
  "dropdown-menu",
  "context-menu",
  "menubar",
  "select",
  "combobox",
  "hover-card",
  "navigation-menu",
];
const OPEN_OVERLAY = OVERLAY_COMPONENTS.map(
  (name) => `[data-component="${name}"][data-state="open"]`,
).join(", ");
const OPEN_CONTENT = OVERLAY_COMPONENTS.map(
  (name) => `[data-slot^="${name}"][data-slot$="content"][data-state="open"]`,
)
  .concat(['[role="dialog"]', '[role="alertdialog"]', '[role="menu"]'])
  .join(", ");

// Every open tooltip, so opening one closes the others (Radix's
// TooltipProvider allows one at a time).
const openTooltips = new Set();

// Whether the last interaction was a pointer (true) or a key (false): focus
// that follows a click (or returns to a button after a menu it opened
// closes) does not open a tooltip; keyboard focus does.
let pointerInteraction = false;
let interactionListening = false;
function listenForInteraction() {
  if (interactionListening || typeof document === "undefined") return;
  interactionListening = true;
  document.addEventListener(
    "pointerdown",
    () => {
      pointerInteraction = true;
    },
    true,
  );
  document.addEventListener(
    "keydown",
    () => {
      pointerInteraction = false;
    },
    true,
  );
}

export function closeAllTooltips() {
  openTooltips.forEach((tooltip) => tooltip.closeNow());
}

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

    listenForInteraction();
    this.onDocumentPointerMove = this.onDocumentPointerMove.bind(this);
    this.onDocumentKeyDown = this.onDocumentKeyDown.bind(this);
    this.onDocumentScroll = this.onDocumentScroll.bind(this);
  }

  getFallbackTrigger() {
    return Array.from(this.el.children).find(
      (child) => child.dataset.part !== "content",
    );
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
              // Leaving before the open delay ends cancels it; without this
              // the timer opened a tooltip the pointer had already left.
              mouseout: "cancelOpen",
              focusout: "cancelOpen",
              pointerdown: "cancelOpen",
            },
          },
        },
        open: {
          mouseMap: {
            trigger: {
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

  // Generic methods for delayed state transitions
  delayOpen(event) {
    if (event?.type === "focusin" && pointerInteraction) return;
    if (this.blockedByOverlay()) return;

    this.clearTimers();
    this.openTimer = setTimeout(() => {
      this.openTimer = null;
      if (this.blockedByOverlay()) return;
      this.transition("open");
    }, this.config.openDelay);
  }

  cancelOpen(event) {
    if (
      event?.type === "mouseout" &&
      event.currentTarget?.contains(event.relatedTarget)
    ) {
      return;
    }
    this.clearTimers();
  }

  closeNow() {
    this.clearTimers();
    if (this.state === "open") this.transition("close");
  }

  // A popup (menu, popover, dialog, select, ...) is open and this trigger is
  // not inside its content: the tooltip would compete with it.
  blockedByOverlay() {
    if (typeof document === "undefined" || !this.trigger) return false;
    if (!document.querySelector(OPEN_OVERLAY)) return false;
    return !this.trigger.closest(OPEN_CONTENT);
  }

  // A missed mouseout (the trigger was patched or moved under a still
  // pointer) must not leave the tooltip stuck: close once the pointer is
  // over something else.
  onDocumentPointerMove(event) {
    if (event.pointerType === "touch") return;
    const target = event.target;
    if (this.trigger?.contains(target) || this.content?.contains(target)) {
      if (this.closeTimer) this.clearTimers();
      return;
    }
    if (!this.closeTimer) this.delayClose();
  }

  onDocumentKeyDown(event) {
    if (event.key === "Escape") this.closeNow();
  }

  // Radix closes a tooltip when a scroll container around its trigger
  // scrolls: the content would otherwise float away from it.
  onDocumentScroll(event) {
    const target = event.target;
    if (target === document || target?.contains?.(this.trigger)) {
      this.closeNow();
    }
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
    openTooltips.forEach((tooltip) => {
      if (tooltip !== this) tooltip.closeNow();
    });
    openTooltips.add(this);
    document.addEventListener("pointermove", this.onDocumentPointerMove, {
      passive: true,
    });
    document.addEventListener("keydown", this.onDocumentKeyDown);
    document.addEventListener("scroll", this.onDocumentScroll, {
      capture: true,
      passive: true,
    });

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
    this.removeDocumentListeners();

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

  removeDocumentListeners() {
    openTooltips.delete(this);
    document.removeEventListener("pointermove", this.onDocumentPointerMove);
    document.removeEventListener("keydown", this.onDocumentKeyDown);
    document.removeEventListener("scroll", this.onDocumentScroll, {
      capture: true,
    });
  }

  beforeDestroy() {
    this.clearTimers();
    this.removeDocumentListeners();

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
