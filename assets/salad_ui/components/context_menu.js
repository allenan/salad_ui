// saladui/components/context_menu.js
import Component from "../core/component.js";
import SaladUI from "../index.js";
import Positioner from "../core/positioner.js";
import ClickOutsideMonitor from "../core/click-outside.js";
import Portal from "../core/portal.js";
import Menu, { assignId, clearGeneratedIds } from "./menu.js";

// Touch/pen hold time before the menu opens, as in Radix.
const LONG_PRESS_DELAY = 700;

// Where an open menu was anchored, what to refocus on close and which
// sub-menus/item were open, handed from the instance a LiveView patch tears
// down to the one rebuilt in its place (keyed by root element).
const pendingRestores = new WeakMap();

function isRtl(el) {
  return el?.closest("[dir]")?.getAttribute("dir") === "rtl";
}

/**
 * Context menu: a menu opened at the pointer on right click (`contextmenu`),
 * or after a long press on touch/pen. Items, checkbox/radio items and
 * sub-menus are the dropdown menu's `Menu` internals.
 */
class ContextMenuComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext, initialState: "closed" });

    this.trigger = this.getPart("trigger");
    this.positioner = this.getPart("positioner");
    this.content = this.positioner?.querySelector("[data-part='content']");
    this.point = null;
    this.longPressTimer = null;

    this.handleContextMenu = this.handleContextMenu.bind(this);
    this.handlePointerDown = this.handlePointerDown.bind(this);
    this.clearLongPress = this.clearLongPress.bind(this);
    this.handleDocumentContextMenu = this.handleDocumentContextMenu.bind(this);
    this.handleContentKeydown = this.handleContentKeydown.bind(this);

    assignId(this.content, `${this.el.id}-content`);

    this.menu = this.content
      ? new Menu(this.content, {
          hookContext,
          rootEl: this.el,
          onItemSelect: () => this.transition("close"),
        })
      : null;

    // The click/touchend that ends the gesture which opened the menu
    // (ctrl-click on macOS, lifting a long press) lands on the trigger and
    // must not close it again; the next press on the trigger re-arms it.
    this.ignoreTriggerRelease = false;
    this.clickOutside = this.positioner
      ? new ClickOutsideMonitor(
          [this.positioner],
          () => this.transition("close", { restoreFocus: false }),
          {
            filter: (event) =>
              !(
                this.ignoreTriggerRelease &&
                this.trigger?.contains(event.target)
              ),
          },
        )
      : null;

    this.updateUI();
  }

  getComponentConfig() {
    return {
      stateMachine: {
        closed: {
          enter: "onClosedEnter",
          transitions: { open: "open" },
        },
        open: {
          enter: "onOpenEnter",
          exit: "onOpenExit",
          transitions: { close: "closed" },
        },
      },
      hiddenConfig: {
        closed: { positioner: true },
        open: { positioner: false },
      },
      ariaConfig: {
        content: {
          all: { role: "menu" },
        },
      },
    };
  }

  // Sub-menu parts carry their own open/closed state, owned by the
  // sub-trigger; keep the root from stamping its state onto them.
  queryParts() {
    return super
      .queryParts()
      .filter((part) => !part.closest("[data-part='sub']"));
  }

  get triggerDisabled() {
    const value = this.trigger?.getAttribute("data-disabled");
    return value !== null && value !== undefined && value !== "false";
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    this.trigger?.addEventListener("contextmenu", this.handleContextMenu);
    this.trigger?.addEventListener("pointerdown", this.handlePointerDown);
    this.trigger?.addEventListener("pointermove", this.clearLongPress);
    this.trigger?.addEventListener("pointercancel", this.clearLongPress);
    this.trigger?.addEventListener("pointerup", this.clearLongPress);
    this.positioner?.addEventListener("keydown", this.handleContentKeydown);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.trigger?.removeEventListener("contextmenu", this.handleContextMenu);
    this.trigger?.removeEventListener("pointerdown", this.handlePointerDown);
    this.trigger?.removeEventListener("pointermove", this.clearLongPress);
    this.trigger?.removeEventListener("pointercancel", this.clearLongPress);
    this.trigger?.removeEventListener("pointerup", this.clearLongPress);
    this.positioner?.removeEventListener("keydown", this.handleContentKeydown);
    this.stopOpenListeners();
    this.clearLongPress();
  }

  handleContextMenu(event) {
    if (this.triggerDisabled) return;

    event.preventDefault();
    this.clearLongPress();

    // A keyboard-invoked context menu (Shift+F10, the Menu key) reports no
    // pointer position (and, as a PointerEvent, an empty pointerType): anchor
    // at the trigger and focus the first item.
    const fromKeyboard =
      event.pointerType === "" || (event.clientX === 0 && event.clientY === 0);
    this.openAt(this.pointFor(event, fromKeyboard), { fromKeyboard });
  }

  handlePointerDown(event) {
    this.ignoreTriggerRelease = false;
    if (this.triggerDisabled || event.pointerType === "mouse") return;

    this.clearLongPress();
    const point = { x: event.clientX, y: event.clientY };
    this.longPressTimer = setTimeout(() => {
      this.longPressTimer = null;
      this.openAt(point);
    }, LONG_PRESS_DELAY);
  }

  clearLongPress() {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }
  }

  pointFor(event, fromKeyboard) {
    if (!fromKeyboard) return { x: event.clientX, y: event.clientY };

    const rect = this.trigger.getBoundingClientRect();
    return { x: rect.left, y: rect.top };
  }

  /**
   * Opens the menu with its top-left corner at `point` (viewport
   * coordinates), or moves it there when it is already open.
   */
  openAt(point, { fromKeyboard = false } = {}) {
    this.point = point;
    this.ignoreTriggerRelease = true;

    if (this.state === "open") {
      this.menu?.closeSubmenus();
      this.position();
      this.focusContent(fromKeyboard);
      return;
    }

    this.transition("open", { fromKeyboard });
  }

  onOpenEnter({ fromKeyboard = false } = {}) {
    const active = document.activeElement;
    this.previousFocusEl = active && active !== document.body ? active : null;
    this.show();
    this.focusContent(fromKeyboard);
    this.pushEvent("open");
  }

  show() {
    if (!this.point) {
      // Opened by a server/client command: anchor at the trigger.
      const rect = this.trigger?.getBoundingClientRect();
      this.point = { x: rect?.left || 0, y: rect?.bottom || 0 };
    }

    if (this.options.usePortal && this.positioner) {
      const container = this.options.portalContainer
        ? document.querySelector(this.options.portalContainer)
        : null;
      Portal.move(this.positioner, container || document.body);
    }

    this.position();
    this.startOpenListeners();
  }

  // Runs as soon as the menu starts closing, before the exit animation: the
  // close event and the focus return must not wait for it, since a LiveView
  // patch in that window (e.g. the reply to an item's on-select) rebuilds the
  // component and the deferred closed-state handler never runs.
  onOpenExit({ restoreFocus = true } = {}) {
    this.menu?.closeSubmenus();
    this.stopOpenListeners();
    this.pushEvent("close");

    const target = this.previousFocusEl;
    this.previousFocusEl = null;
    if (restoreFocus && target?.isConnected) target.focus();
  }

  // After the exit animation.
  onClosedEnter() {
    this.point = null;

    if (this.positioner && Portal.isInPortal(this.positioner)) {
      Portal.restore(this.positioner);
    }
  }

  focusContent(fromKeyboard) {
    if (fromKeyboard) {
      this.menu?.activate();
    } else {
      this.menu?.reset();
      this.content?.focus({ preventScroll: true });
    }
  }

  // The side of the pointer the panel opens on (`data-side` on the
  // positioner, `right` by default), mirrored under RTL.
  get side() {
    const side = this.positioner?.getAttribute("data-side") || "right";
    if (!isRtl(this.trigger)) return side;
    return { left: "right", right: "left" }[side] || side;
  }

  /**
   * Places the panel at the pointer on its `side` (by default to the right
   * of and below it), flipping to the other side when it would overflow the
   * viewport, then clamping into the viewport.
   */
  position() {
    if (!this.positioner || !this.point) return;

    this.positioner.hidden = false;
    // Caps the panel height (`max-h-(--context-menu-content-available-height)`)
    // so a long menu scrolls instead of running off the screen.
    this.positioner.style.setProperty(
      "--context-menu-content-available-height",
      `${window.innerHeight}px`,
    );

    const { x, y } = this.point;
    const reference = {
      getBoundingClientRect: () => ({
        top: y,
        bottom: y,
        left: x,
        right: x,
        width: 0,
        height: 0,
      }),
    };
    const result = Positioner.calculate(this.positioner, reference, {
      placement: this.side,
      alignment: "start",
      sideOffset: 2,
      flip: true,
    });

    const width = this.positioner.offsetWidth;
    const height = this.positioner.offsetHeight;
    const maxX = Math.max(0, window.innerWidth - width);
    const maxY = Math.max(0, window.innerHeight - height);
    let { x: left, y: top } = result;
    const sideways =
      result.placement === "left" || result.placement === "right";
    // The panel hangs below (or, opening up/down, beside) the pointer; when
    // that overflows, hang it the other way from the pointer instead.
    if (sideways && top > maxY && y - height >= 0) top = y - height;
    if (!sideways && left > maxX && x - width >= 0) left = x - width;

    Positioner.applyPosition(
      this.positioner,
      Math.min(Math.max(0, left), maxX),
      Math.min(Math.max(0, top), maxY),
    );
    this.content?.setAttribute("data-side", result.placement);
  }

  startOpenListeners() {
    this.clickOutside?.start();
    document.addEventListener("contextmenu", this.handleDocumentContextMenu);
  }

  stopOpenListeners() {
    this.clickOutside?.stop();
    document.removeEventListener("contextmenu", this.handleDocumentContextMenu);
  }

  // Right-clicking anywhere else closes the menu; the trigger's own
  // handler re-anchors it instead.
  handleDocumentContextMenu(event) {
    if (
      this.trigger?.contains(event.target) ||
      this.positioner?.contains(event.target)
    ) {
      if (this.positioner?.contains(event.target)) event.preventDefault();
      return;
    }

    this.transition("close", { restoreFocus: false });
  }

  handleContentKeydown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      event.stopPropagation();
      this.transition("close");
    } else if (event.key === "Tab") {
      // Menus keep focus inside; Tab does nothing (WAI-ARIA, Radix).
      event.preventDefault();
    }
  }

  // A LiveView patch rebuilds the component (see hook.js). Re-open at the
  // remembered point when the previous instance was open, with the same
  // sub-menus open and the same item focused (e.g. a checkbox item whose
  // server state just changed).
  afterMount() {
    const saved = pendingRestores.get(this.el) || {};
    pendingRestores.delete(this.el);
    if (this.state !== "open") return;

    this.point = saved.point || null;
    this.previousFocusEl = saved.previousFocusEl?.isConnected
      ? saved.previousFocusEl
      : null;
    this.show();

    const { menu } = saved;
    const focusedItem = menu?.focused && menu.focused !== this.content;
    if (menu && (focusedItem || menu.openSubTriggers.length > 0)) {
      this.menu?.restore(menu);
    } else {
      this.focusContent(false);
    }
  }

  // Runs right before LiveView patches this element; updated() then rebuilds
  // the component, which picks the snapshot back up in afterMount().
  beforeUpdate() {
    if (this.positioner && Portal.isInPortal(this.positioner)) {
      Portal.restore(this.positioner);
    }

    if (this.state === "open") {
      pendingRestores.set(this.el, {
        point: this.point,
        previousFocusEl: this.previousFocusEl,
        menu: this.menu?.snapshot() || null,
      });
    }

    clearGeneratedIds(this.el, this.positioner);
  }

  handleCommand(command, params = {}) {
    if (command === "toggle") {
      return this.transition(this.state === "open" ? "close" : "open", params);
    }

    return super.handleCommand(command, params);
  }

  beforeDestroy() {
    this.clearLongPress();
    this.stopOpenListeners();
    this.el.dataset.state = this.state;

    if (this.positioner && Portal.isInPortal(this.positioner)) {
      Portal.restore(this.positioner);
    }

    this.clickOutside?.destroy();
    this.clickOutside = null;
    this.menu?.destroy();
    this.menu = null;
  }
}

SaladUI.register("context-menu", ContextMenuComponent);

export default ContextMenuComponent;
