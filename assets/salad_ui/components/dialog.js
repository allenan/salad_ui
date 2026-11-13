// saladui/components/dialog.js
import Component from "../core/component.js";
import SaladUI from "../index.js";
import FocusTrap from "../core/focus-trap.js";
import ClickOutsideMonitor from "../core/click-outside.js";

class DialogComponent extends Component {
  constructor(el, hookContext) {
    super(el, {
      hookContext,
      initialState: "closed",
    });

    // Initialize properties
    this.root = this.el;
    this.content = this.getPart("content");
    this.contentPanel = this.getPart("content-panel");
    this.config.preventDefaultKeys = ["Escape"];
    this.serverOpen = this.readServerOpen(el);
  }

  /**
   * The open state the server rendered: `data-open` (dialog/1), else the
   * root's `data-state` (sheet/1, alert_dialog/1).
   */
  readServerOpen(el) {
    return el.dataset.open === undefined
      ? el.dataset.state === "open"
      : el.dataset.open === "true";
  }

  /**
   * A LiveView patch (a phx-change form inside the dialog, a flash anywhere
   * on the page) puts back the server-rendered markup: the content `hidden`,
   * the closed `data-state` and no ARIA. Rebuilding from that would close a
   * dialog the user opened. Keep the instance and re-apply its state instead,
   * unless the options or event mappings changed. A new server open state is
   * applied as an open/close.
   */
  skipReinitialize(el) {
    if (!this.sameConfig(el)) return false;
    // The focus trap is bound to the panel.
    if (!this.refreshParts(["content", "content-panel"])) return false;

    // Read before reapplyState() overwrites the root's data-state.
    const serverOpen = this.readServerOpen(el);
    this.reapplyState();

    if (serverOpen !== this.serverOpen) {
      this.serverOpen = serverOpen;
      if (serverOpen !== (this.state === "open")) {
        this.transition(serverOpen ? "open" : "close");
      }
    }

    return true;
  }

  // The title and description get client ids for aria-labelledby/-describedby;
  // drop them so the patch keeps those elements (see skipReinitialize).
  beforeUpdate() {
    this.clearGeneratedIds();
  }

  afterMount() {
    const requestedState =
      this.el.dataset.open === undefined
        ? this.el.dataset.state || "closed"
        : this.el.dataset.open === "true"
          ? "open"
          : "closed";

    if (requestedState === this.state) {
      if (this.state === "open") {
        this.activateOpenState();
      }
      return;
    }

    this.transition(requestedState === "open" ? "open" : "close");
  }

  getComponentConfig() {
    return {
      stateMachine: {
        closed: {
          enter: "onClosedEnter",
          exit: "onClosedExit",
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
          keyMap: {},
        },
        open: {
          keyMap: {
            ...(this.options.closeOnEscape === false
              ? {}
              : { Escape: "close" }),
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
        content: {
          open: {
            hidden: "false",
          },
          closed: {
            hidden: "true",
          },
        },
        "content-panel": {
          all: {
            role: this.options.role || "dialog",
          },
          open: {
            modal: "true",
            labelledby: () => this.getPartId("title"),
            describedby: () => this.getPartId("description"),
          },
          closed: {
            modal: null,
            labelledby: null,
            describedby: null,
          },
        },
        "close-trigger": {
          all: {
            label: "Close dialog",
          },
        },
      },
    };
  }

  // Setup component events
  setupComponentEvents() {
    super.setupComponentEvents();

    // Only setup click handler if closeOnOutsideClick is enabled
    if (this.options.closeOnOutsideClick) {
      this.setupOutsideClickDetection();
    }
  }

  setupOutsideClickDetection() {
    // Create click outside monitor to handle clicks on the overlay
    this.clickOutsideMonitor = new ClickOutsideMonitor(
      [this.contentPanel],
      (event) => {
        // Only close if click was directly on the content container (overlay area)
        if (
          event.target === this.content ||
          event.target.dataset.part === "overlay"
        ) {
          this.transition("close");
        }
      },
    );
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();

    // Clean up click outside monitor
    this.clickOutsideMonitor?.destroy();
    this.clickOutsideMonitor = null;
  }

  // State machine handlers
  onClosedEnter() {
    // Content hides after its exit animation completes.
  }

  onClosedExit() {
    // No special handling needed
  }

  onOpenEnter() {
    this.activateOpenState();

    // Notify the server of the state change
    this.pushEvent("open");
  }

  onOpenExit() {
    this.focusTrap?.deactivate();
    this.clickOutsideMonitor?.stop();

    // Notify before an exit animation or a LiveView patch can destroy this instance.
    this.pushEvent("close");
  }

  activateOpenState() {
    // Initialize focus trap if not already created
    this.el.focus();
    if (!this.focusTrap) {
      this.focusTrap = new FocusTrap(this.contentPanel);
    }

    // Activate focus trap
    this.focusTrap.activate();

    // Activate click outside monitor if enabled
    if (this.clickOutsideMonitor) {
      this.clickOutsideMonitor.start();
    }

    // Escape handling uses the component key map.
  }

  beforeDestroy() {
    // Clean up focus trap
    this.focusTrap?.destroy();
    this.focusTrap = null;
  }
}

// Register the component
SaladUI.register("dialog", DialogComponent);

export default DialogComponent;
