// saladui/components/dialog.js
import Component from "../core/component.js";
import SaladUI from "../index.js";
import FocusTrap from "../core/focus-trap.js";
import ClickOutsideMonitor from "../core/click-outside.js";
import { ModalLayer } from "../core/modal-layer.js";

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

    // Outside blocking, aria-hidden, wheel/touch blocking and the scroll
    // lock while open (see core/modal-layer.js). The content part holds both
    // the overlay and the panel.
    this.modalLayer = new ModalLayer(() => [this.content], {
      modal: this.isModal(),
    });
  }

  /**
   * Modal unless the options say `modal: false` (Radix's `modal` prop). A
   * non-modal dialog has no overlay, leaves the page interactive, readable
   * and scrollable, does not loop Tab, and closes on any outside click.
   */
  isModal() {
    return this.options.modal !== false;
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
    // The patch dropped the inline pointer-events (and any aria-hidden on
    // the page around the dialog); put them back before the next paint.
    this.modalLayer.refresh();

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
        // Radix renders no overlay for a non-modal dialog.
        closed: {
          content: true,
          ...(this.isModal() ? {} : { overlay: true }),
        },
        open: {
          content: false,
          ...(this.isModal() ? {} : { overlay: true }),
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
            modal: this.isModal() ? "true" : null,
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
        if (this.isModal()) {
          // The page is blocked, so an outside click can only land on the
          // overlay (or the content container around it).
          if (
            event.target === this.content ||
            event.target.dataset?.part === "overlay"
          ) {
            this.transition("close");
          }
          return;
        }

        // Non-modal: any click outside closes, except on a trigger, which
        // toggles the dialog itself.
        const onTrigger = this.getAllParts("trigger").some((trigger) =>
          trigger.contains(event.target),
        );
        if (!onTrigger) this.transition("close");
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
    // Content hides after its exit animation completes; the modal layer is
    // released then too (see updatePartsVisibility).
  }

  /**
   * Runs once the parts reach a state's visibility: straight away, or after
   * the exit animation. Like Radix, the page stays scroll-locked until the
   * closing dialog is gone, so the scrollbar does not come back
   * mid-animation. (Also runs from the base constructor, before the layer
   * exists.)
   */
  updatePartsVisibility() {
    super.updatePartsVisibility();
    if (this.state === "closed") this.modalLayer?.deactivate();
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
    // Unblock the page as soon as the dialog starts closing (before focus
    // goes back to the trigger, which is aria-hidden until then); the
    // scroll lock holds through the exit animation.
    this.modalLayer.releaseInteraction();
    this.focusTrap?.deactivate();
    this.clickOutsideMonitor?.stop();

    // Notify before an exit animation or a LiveView patch can destroy this instance.
    this.pushEvent("close");
  }

  activateOpenState() {
    // Initialize focus trap if not already created
    this.el.focus();
    if (!this.focusTrap) {
      this.focusTrap = new FocusTrap(this.contentPanel, {
        contain: this.isModal(),
        // A dialog the server opened was opened with focus on <body>.
        returnFocus: () =>
          this.el &&
          this.queryParts().find((part) => part.dataset.part === "trigger"),
      });
    }

    // Activate focus trap: before the modal layer, which makes the opener
    // inert (and so may blur it) and focus could not be returned to it.
    this.focusTrap.activate();

    // Idempotent: a patch or a reopen mid-exit-animation never stacks a
    // second layer or scroll lock.
    this.modalLayer.activate();

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
    // Destroyed while open (or mid-exit-animation): a rebuild that is still
    // open activates a new layer from afterMount().
    this.modalLayer.deactivate();
  }
}

// Register the component
SaladUI.register("dialog", DialogComponent);

export default DialogComponent;
