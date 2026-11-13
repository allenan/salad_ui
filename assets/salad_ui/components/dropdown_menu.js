// saladui/components/dropdown_menu.js
import Component from "../core/component.js";
import SaladUI from "../index.js";
import PositionedElement from "../core/positioned-element.js";
import { ModalLayer } from "../core/modal-layer.js";
import Menu, { assignId, clearGeneratedIds } from "./menu.js";

// Open sub-menus and focus, handed from the instance torn down by a LiveView
// patch to the one rebuilt in its place (keyed by root element).
const pendingRestores = new WeakMap();

// Caps the content (`max-h-(--dropdown-menu-content-available-height)`), like
// Radix's --radix-dropdown-menu-content-available-height, so a long menu near
// the viewport edge scrolls instead of running off-screen.
const AVAILABLE_HEIGHT_VAR = "--dropdown-menu-content-available-height";

/**
 * DropdownMenuComponent class for SaladUI framework
 * Manages a dropdown menu with support for keyboard navigation and accessibility
 */
class DropdownMenuComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    // Initialize core properties
    this.trigger = this.getPart("trigger");
    this.positioner = this.getPart("positioner");
    this.content = this.positioner?.querySelector("[data-part='content']");
    this.handleTriggerClick = this.handleTriggerClick.bind(this);
    this.handleTriggerKeydown = this.handleTriggerKeydown.bind(this);

    // The content is labelled by the trigger (aria-labelledby), as in Radix.
    // Generated ids are stripped again in beforeUpdate().
    assignId(this.trigger, `${this.el.id}-trigger`);
    assignId(this.content, `${this.el.id}-content`);
    // Pointer opens focus the content itself.
    if (this.content && !this.content.hasAttribute("tabindex")) {
      this.content.setAttribute("tabindex", "-1");
    }
    this.updateUI();

    this.menu = this.content
      ? new Menu(this.content, {
          hookContext,
          rootEl: this.el,
          onItemSelect: this.onItemSelect.bind(this),
        })
      : null;

    // Set keyboard navigation defaults
    this.config.preventDefaultKeys = ["Escape", "ArrowDown", " ", "Enter"];

    // Like Radix's DropdownMenu (`modal` defaults to true), an open menu
    // blocks outside pointer events, hides the rest of the page from
    // assistive technology and locks scrolling; `modal: false` turns that
    // off. The layer is the positioner, which may be portaled.
    this.modalLayer = new ModalLayer(() => [this.positioner], {
      modal: this.options.modal !== false,
    });
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
          exit: "onOpenExit",
          transitions: {
            close: "closed",
            toggle: "closed",
          },
        },
      },
      events: {
        closed: {
          keyMap: {
            ArrowDown: "open",
            " ": "open",
            Enter: "open",
          },
        },
        open: {
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
            haspopup: "menu",
            controls: () => this.content?.id || null,
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
            role: "menu",
            labelledby: () => this.trigger?.id || null,
          },
        },
      },
    };
  }

  // Parts inside a sub-menu (`sub`, `sub-trigger`, `sub-content`, ...) carry
  // their own open/closed state, owned by the sub-trigger; keep the root from
  // stamping its state onto them.
  queryParts() {
    return super
      .queryParts()
      .filter((part) => !part.closest("[data-part='sub']"));
  }

  initializePositionedElement() {
    if (this.positioner && this.trigger && !this.positionedElement) {
      const side = this.positioner.getAttribute("data-side") || "bottom";
      const align = this.positioner.getAttribute("data-align") || "start";
      const sideOffset = parseInt(
        this.positioner.getAttribute("data-side-offset") || "4",
        10,
      );
      const alignOffset = parseInt(
        this.positioner.getAttribute("data-align-offset") || "0",
        10,
      );

      // Get portal options
      const usePortal = this.options.usePortal === true;
      let portalContainer = null;
      if (this.options.portalContainer) {
        portalContainer = document.querySelector(this.options.portalContainer);
      }

      this.positionedElement = new PositionedElement(
        this.positioner,
        this.trigger,
        {
          placement: side,
          alignment: align,
          sideOffset,
          alignOffset,
          flip: true,
          usePortal,
          portalContainer: portalContainer || document.body,
          trapFocus: false,
          onOutsideClick: () =>
            this.transition("close", { restoreFocus: false }),
          // The side the content actually opened on, after a flip, so the
          // slide-in animation comes from the trigger.
          onPosition: ({ placement }) =>
            this.content?.setAttribute("data-side", placement),
          // Not a custom placement (returns null): it caps the content
          // height before every position pass (open, scroll, resize).
          computePosition: () => {
            this.updateAvailableHeight(side, align, sideOffset);
            return null;
          },
        },
      );
    }
  }

  /**
   * Sets --dropdown-menu-content-available-height to the room the viewport
   * leaves beside the trigger. Above or below it, that is the larger of the
   * two sides, so the cap cannot flip the placement back and forth (the
   * content flips to the larger side when it does not fit). Beside it (left
   * or right), the room in the direction the content grows from its `align`.
   */
  updateAvailableHeight(side, align, sideOffset) {
    if (!this.content || !this.trigger) return;

    const rect = this.trigger.getBoundingClientRect();
    const height = window.innerHeight;
    let room;
    if (side === "left" || side === "right") {
      const middle = rect.top + rect.height / 2;
      room = {
        start: height - rect.top,
        end: rect.bottom,
        center: 2 * Math.min(middle, height - middle),
      }[align];
    } else {
      room = Math.max(rect.top, height - rect.bottom) - sideOffset;
    }

    this.content.style.setProperty(
      AVAILABLE_HEIGHT_VAR,
      `${Math.max(0, Math.floor(room ?? height))}px`,
    );
  }

  afterMount() {
    const restore = pendingRestores.get(this.el);
    pendingRestores.delete(this.el);

    if (this.state === "open") {
      this.activateOpenState(false, restore);
    }
  }

  // Runs right before LiveView patches this element; updated() then rebuilds
  // the component, which picks the snapshot back up in afterMount().
  beforeUpdate() {
    if (this.state === "open") {
      pendingRestores.set(this.el, {
        menu: this.menu?.snapshot(),
        previousFocusEl: this.previousFocusEl,
      });
    }

    // With `use-portal` the content lives outside the root; LiveView can
    // only patch it back inside. The rebuilt instance portals it again
    // (afterMount() -> activateOpenState()).
    this.positionedElement?.deactivate();

    clearGeneratedIds(this.el, this.positioner);
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    this.trigger?.addEventListener("click", this.handleTriggerClick);
    this.trigger?.addEventListener("keydown", this.handleTriggerKeydown);
    this.positioner?.addEventListener("keydown", this.handleContentKeydown);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.trigger?.removeEventListener("click", this.handleTriggerClick);
    this.trigger?.removeEventListener("keydown", this.handleTriggerKeydown);
    this.positioner?.removeEventListener("keydown", this.handleContentKeydown);
  }

  // Escape inside the content closes the menu; Tab does nothing, so focus
  // stays in the menu (Radix, like context_menu.js and menubar.js). Handled
  // on the positioner, since with `use-portal` keys pressed in the content
  // never reach the root.
  handleContentKeydown = (event) => {
    if (this.state !== "open") return;

    if (event.key === "Tab") {
      event.preventDefault();
      return;
    }
    if (event.key !== "Escape") return;

    event.preventDefault();
    event.stopPropagation();
    this.transition("close");
  };

  handleTriggerClick() {
    if (this.state === "open") {
      this.previousFocusEl = this.trigger;
    }

    this.transition("toggle");
  }

  handleTriggerKeydown(event) {
    if (event.defaultPrevented || this.state !== "open") return;

    const keyActions = {
      ArrowUp: () => this.menu?.navigateItem("prev"),
      ArrowDown: () => this.menu?.navigateItem("next"),
      Home: () => this.menu?.navigateItem("first"),
      End: () => this.menu?.navigateItem("last"),
      Escape: () => this.transition("close"),
      Enter: () => this.transition("close"),
      " ": () => this.transition("close"),
    };
    const action = keyActions[event.key];
    if (!action) return;

    event.preventDefault();
    event.stopPropagation();
    action();
  }

  /**
   * Shows and positions the content and moves focus into it. As in Radix, a
   * keyboard open (`focusFirst`) focuses the first item; any other open
   * (pointer, server command, initial `open`) focuses the content itself, so
   * no item is highlighted until the pointer or ArrowDown/typeahead picks one.
   */
  activateOpenState(pushEvent = true, restore = null, focusFirst = false) {
    const activeElement = document.activeElement;
    const restoredFocusEl = restore?.previousFocusEl?.isConnected
      ? restore.previousFocusEl
      : null;
    // Never return focus into the (then hidden) menu itself on close.
    this.previousFocusEl =
      this.previousFocusEl ||
      restoredFocusEl ||
      (activeElement &&
      activeElement !== document.body &&
      !this.positioner?.contains(activeElement)
        ? activeElement
        : this.trigger);

    this.initializePositionedElement();
    this.positionedElement?.activate();
    this.modalLayer.activate();

    // After a LiveView patch: reopen the same sub-menus and refocus the same
    // item; a menu that had only the content focused gets that back.
    const saved = restore?.menu;
    const savedItem = saved?.focused && saved.focused !== this.content;
    if (saved && (savedItem || saved.openSubTriggers.length > 0)) {
      this.menu?.restore(saved);
    } else {
      this.focusContent(focusFirst);
    }

    window.requestAnimationFrame(() => {
      if (this.destroyed || typeof document === "undefined") return;

      if (
        this.state === "open" &&
        !this.content?.contains(document.activeElement)
      ) {
        this.focusContent(focusFirst);
      }
    });

    if (pushEvent) {
      this.pushEvent("open");
    }
  }

  focusContent(focusFirst) {
    if (focusFirst) {
      this.menu?.activate();
    } else {
      // Forget any highlighted item (and typeahead search) so ArrowDown and
      // typing start from the top.
      this.menu?.reset();
      this.content?.focus({ preventScroll: true });
    }
  }

  // Enter, Space or ArrowDown on the trigger (the closed-state keyMap) pass
  // the keydown as `originalEvent`; a click or a server command does not.
  onOpenEnter({ originalEvent } = {}) {
    this.activateOpenState(true, null, originalEvent?.type === "keydown");
  }

  // Runs as soon as the menu starts closing, before the exit animation: the
  // close event and the focus return must not wait for it, since a LiveView
  // patch in that window (e.g. the reply to an item's on-select) rebuilds the
  // component and the deferred closed-state handler never runs.
  onOpenExit({ restoreFocus = true } = {}) {
    // Unblock the page first: focus goes back to the trigger, which is
    // aria-hidden while the menu blocks. The scroll lock holds until the
    // exit animation ends (onClosedEnter).
    this.modalLayer.releaseInteraction();
    this.menu?.closeSubmenus();
    this.pushEvent("close");

    const focusTarget = this.previousFocusEl?.isConnected
      ? this.previousFocusEl
      : this.trigger;
    this.previousFocusEl = null;
    if (restoreFocus) focusTarget?.focus();
  }

  // After the exit animation.
  onClosedEnter() {
    this.positionedElement?.deactivate();
    // Runs from the base constructor too, before the layer exists.
    this.modalLayer?.deactivate();
  }

  onItemSelect() {
    this.transition("close");
  }

  beforeDestroy() {
    this.el.dataset.state = this.state;
    // A rebuild that stays open activates a new layer from afterMount().
    this.modalLayer.deactivate();

    // Clean up the positioned element
    if (this.positionedElement) {
      this.positionedElement.destroy();
      this.positionedElement = null;
    }

    // Clean up menu items
    if (this.menu) {
      this.menu.destroy();
      this.menu = null;
    }
  }
}

// Register the component
SaladUI.register("dropdown-menu", DropdownMenuComponent);

export default DropdownMenuComponent;
