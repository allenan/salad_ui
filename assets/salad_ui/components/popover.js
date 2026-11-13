// saladui/components/popover.js
import Component from "../core/component.js";
import SaladUI from "../index.js";
import PositionedElement from "../core/positioned-element.js";

class PopoverComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    // Initialize core properties
    this.trigger = this.getPart("trigger");
    // Optional popover_anchor: positions the content in place of the trigger.
    this.anchor = this.getPart("anchor");
    this.positioner = this.getPart("positioner");
    this.content = this.positioner
      ? this.positioner.querySelector("[data-part='content']")
      : null;

    // Set keyboard navigation defaults
    this.config.preventDefaultKeys = ["Escape"];

    this.keepStateAcrossPatches();
  }

  /**
   * The open state lives on the client. Without this, any LiveView patch that
   * touches the popover (e.g. a form's phx-change re-rendering the page, or a
   * calendar inside the content re-rendering) would morph data-state/hidden
   * back to the server-rendered "closed" markup and close it. LiveView >= 1.1
   * can be told to leave those attributes alone. `open` therefore only sets
   * the initial state.
   */
  keepStateAcrossPatches() {
    const js = this.hook?.js?.();
    if (typeof js?.ignoreAttributes !== "function") return;

    this.patchSafe = true;
    js.ignoreAttributes(this.el, ["data-state"]);
    if (this.trigger) {
      js.ignoreAttributes(this.trigger, ["data-state", "aria-expanded"]);
    }
    if (this.anchor) js.ignoreAttributes(this.anchor, ["data-state"]);
    if (this.positioner) {
      js.ignoreAttributes(this.positioner, ["data-state", "hidden", "style"]);
    }
    if (this.content) {
      js.ignoreAttributes(this.content, ["data-state", "data-side"]);
    }
  }

  /**
   * Keep this instance across a patch that left the popover's own parts in
   * place, so an open popover keeps its position, focus trap and focus.
   */
  skipReinitialize(el) {
    if (!this.patchSafe) return false;

    const sameConfig =
      el.getAttribute("data-options") === this._optionsRaw &&
      el.getAttribute("data-event-mappings") === this._eventMappingsRaw;
    const partsInPlace = [this.trigger, this.positioner, this.content].every(
      (part) => !part || part.isConnected,
    );
    const sameAnchor =
      (el.querySelector("[data-part='anchor']") || null) ===
      (this.anchor || null);

    if (!sameConfig || !partsInPlace || !sameAnchor) return false;

    if (this.suspendedForPatch) {
      this.suspendedForPatch = false;
      if (this.state === "open") this.activateOpenState();
    } else if (this.state === "open") {
      this.positionedElement?.update();
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
            toggle: "open",
          },
        },
        open: {
          enter: "onOpenEnter",
          transitions: {
            close: "closed",
            toggle: "closed",
          },
        },
      },
      events: {
        closed: {
          keyMap: {},
        },
        open: {
          keyEventTarget: "content",
          keyMap: {
            Escape: "close",
          },
        },
      },
      hiddenConfig: {
        closed: {
          positioner: true, // Hide the positioner in closed state
        },
        open: {
          positioner: false, // Show the positioner in open state
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

  /**
   * Initializes the positioned element if the positioner and trigger exist and the positioned element is not already created.
   * Extracts placement configuration from DOM attributes and creates a new PositionedElement instance.
   */
  initializePositionedElement() {
    const reference = this.anchor || this.trigger;
    if (this.positioner && reference && !this.positionedElement) {
      const placement = this.positioner.getAttribute("data-side") || "bottom";
      const alignment = this.positioner.getAttribute("data-align") || "center";
      const sideOffset = parseInt(
        this.positioner.getAttribute("data-side-offset") || "4",
        10,
      );
      const alignOffset = parseInt(
        this.positioner.getAttribute("data-align-offset") || "0",
        10,
      );
      const usePortal = this.options.usePortal === true;
      const portalContainer =
        usePortal && this.options.portalContainer
          ? document.querySelector(this.options.portalContainer)
          : document.body;

      this.positionedElement = new PositionedElement(
        this.positioner,
        reference,
        {
          placement,
          alignment,
          sideOffset,
          alignOffset,
          flip: true,
          usePortal,
          portalContainer,
          trapFocus: true,
          onOutsideClick: (event) => {
            // With an anchor the trigger is outside the monitored elements;
            // let its own toggle action close the popover instead.
            if (this.trigger?.contains(event?.target)) return;
            this.transition("close");
          },
          onPosition: ({ placement: actualPlacement }) => {
            this.content?.setAttribute("data-side", actualPlacement);
          },
        },
      );
    }
  }

  afterMount() {
    if (this.state === "open") {
      this.activateOpenState();
    }
  }

  activateOpenState() {
    this.initializePositionedElement();
    this.positionedElement?.activate();
  }

  onOpenEnter() {
    this.activateOpenState();
    this.pushEvent("open");
  }

  onClosedEnter() {
    this.positionedElement?.deactivate();
    this.pushEvent("close");
  }

  beforeUpdate() {
    // Portaled content must be back inside the root for LiveView to patch it.
    // In place, it can stay active (see skipReinitialize).
    if (!this.patchSafe || this.positionedElement?.options.usePortal) {
      this.suspendedForPatch = !!this.positionedElement?.active;
      this.positionedElement?.deactivate();
    }
  }

  beforeDestroy() {
    this.positionedElement?.destroy();
    this.positionedElement = null;
  }
}

// Register the component
SaladUI.register("popover", PopoverComponent);

export default PopoverComponent;
