// saladui/components/context_menu.js
import Component, {
  assignId,
  clearGeneratedIdsWithin,
} from "../core/component.js";
import { isRtl } from "../core/direction.js";
import SaladUI from "../index.js";
import Positioner from "../core/positioner.js";
import ClickOutsideMonitor from "../core/click-outside.js";
import Portal from "../core/portal.js";
import { ModalLayer } from "../core/modal-layer.js";
import {
  CONTEXT_TARGETS,
  DetachedAnchor,
  closestTrigger,
  focusFallback,
  isTriggerDisabled,
  listen,
  readContext,
  resolveAnchor,
  triggersFor,
} from "../core/detached-triggers.js";
import Menu from "./menu.js";

// Touch/pen hold time before the menu opens, as in Radix.
const LONG_PRESS_DELAY = 700;

// Where an open menu was anchored, what to refocus on close and which
// sub-menus/item were open, handed from the instance a LiveView patch tears
// down to the one rebuilt in its place (keyed by root element).
const pendingRestores = new WeakMap();

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

    // Shared menus: the detached trigger (`data-salad-for`, outside the
    // root) the open menu was opened from, and the context map it carries.
    // A context menu area has no aria-expanded, as in Radix.
    this.detached = new DetachedAnchor({
      expanded: false,
      // The root runs an item's JS command when the content is portaled
      // out of the LiveView.
      targets: () => [
        this.el,
        ...(this.positioner?.querySelectorAll(CONTEXT_TARGETS) ?? []),
      ],
      onRemoved: () => {
        if (this.state === "open" && !this.destroyed) {
          this.transition("close", { anchorRemoved: true });
        }
      },
    });

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
          getContext: () => this.context,
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
                this.anchorEl?.contains(event.target)
              ),
          },
        )
      : null;

    // Like Radix's ContextMenu (`modal` defaults to true): while open, a
    // click outside only closes the menu, the rest of the page is hidden
    // from assistive technology and scrolling is locked.
    this.modalLayer = new ModalLayer(() => [this.positioner], {
      modal: this.options.modal !== false,
    });

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

  /**
   * The trigger the open menu belongs to: the detached trigger it was
   * opened from, else the nested trigger.
   */
  get anchorEl() {
    return this.activeTrigger || this.trigger;
  }

  // The detached trigger the menu is open for (null: the nested one).
  get activeTrigger() {
    return this.detached?.trigger || null;
  }

  // The open menu's context map, for the items' event payloads.
  get context() {
    return this.detached?.context || null;
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    this.trigger?.addEventListener("contextmenu", this.handleContextMenu);
    this.trigger?.addEventListener("pointerdown", this.handlePointerDown);
    this.trigger?.addEventListener("pointermove", this.clearLongPress);
    this.trigger?.addEventListener("pointercancel", this.clearLongPress);
    this.trigger?.addEventListener("pointerup", this.clearLongPress);
    this.positioner?.addEventListener("keydown", this.handleContentKeydown);
    // Detached triggers anywhere on the page, through one document listener
    // per event type shared by every instance.
    this.unlisten = [
      listen(this.el.id, "contextmenu", this.handleDetachedContextMenu),
      listen(this.el.id, "pointerdown", this.handleDetachedPointerDown),
    ];
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.trigger?.removeEventListener("contextmenu", this.handleContextMenu);
    this.trigger?.removeEventListener("pointerdown", this.handlePointerDown);
    this.trigger?.removeEventListener("pointermove", this.clearLongPress);
    this.trigger?.removeEventListener("pointercancel", this.clearLongPress);
    this.trigger?.removeEventListener("pointerup", this.clearLongPress);
    this.positioner?.removeEventListener("keydown", this.handleContentKeydown);
    this.unlisten?.forEach((off) => off());
    this.unlisten = null;
    this.stopOpenListeners();
    this.clearLongPress();
  }

  handleContextMenu(event) {
    if (this.triggerDisabled) return;

    this.openFromEvent(event, this.trigger);
  }

  // A detached trigger inside the root would also be the nested one.
  ownsDetached(trigger) {
    return !this.el.contains(trigger) && !isTriggerDisabled(trigger);
  }

  handleDetachedContextMenu = (event, trigger) => {
    if (!this.ownsDetached(trigger)) return;

    this.openFromEvent(event, trigger);
  };

  openFromEvent(event, trigger) {
    event.preventDefault();
    this.clearLongPress();

    // A keyboard-invoked context menu (Shift+F10, the Menu key) reports no
    // pointer position (and, as a PointerEvent, an empty pointerType): anchor
    // at the trigger and focus the first item.
    const fromKeyboard =
      event.pointerType === "" || (event.clientX === 0 && event.clientY === 0);
    this.openAt(this.pointFor(event, fromKeyboard, trigger), {
      fromKeyboard,
      trigger,
      context: readContext(trigger),
    });
  }

  handlePointerDown(event) {
    this.ignoreTriggerRelease = false;
    if (this.triggerDisabled || event.pointerType === "mouse") return;

    this.startLongPress(event, this.trigger);
  }

  // Long press on a detached trigger. The pointer events that cancel it are
  // listened to on the document only while one is pending.
  handleDetachedPointerDown = (event, trigger) => {
    if (!this.ownsDetached(trigger)) return;

    this.ignoreTriggerRelease = false;
    if (event.pointerType === "mouse") return;

    this.startLongPress(event, trigger);
    document.addEventListener("pointermove", this.clearLongPress);
    document.addEventListener("pointercancel", this.clearLongPress);
    document.addEventListener("pointerup", this.clearLongPress);
  };

  startLongPress(event, trigger) {
    this.clearLongPress();
    const point = { x: event.clientX, y: event.clientY };
    this.longPressTimer = setTimeout(() => {
      this.longPressTimer = null;
      this.openAt(point, { trigger, context: readContext(trigger) });
    }, LONG_PRESS_DELAY);
  }

  clearLongPress() {
    if (this.longPressTimer) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }
    document.removeEventListener("pointermove", this.clearLongPress);
    document.removeEventListener("pointercancel", this.clearLongPress);
    document.removeEventListener("pointerup", this.clearLongPress);
  }

  pointFor(event, fromKeyboard, trigger = this.anchorEl) {
    if (!fromKeyboard) return { x: event.clientX, y: event.clientY };

    const rect = trigger.getBoundingClientRect();
    return { x: rect.left, y: rect.top };
  }

  /**
   * Opens the menu with its top-left corner at `point` (viewport
   * coordinates; null for the bottom-left corner of the trigger), or moves
   * it there when it is already open. `trigger` (a detached trigger, any
   * element, or the nested trigger) and its `context` switch what the menu
   * is opened for; left out, they stay as they are.
   */
  openAt(point, { fromKeyboard = false, trigger, context = null } = {}) {
    if (trigger !== undefined) this.setAnchor(trigger, context);
    this.point = point || this.anchorPoint();
    this.ignoreTriggerRelease = true;

    if (this.state === "open") {
      this.menu?.closeSubmenus();
      this.position();
      this.focusContent(fromKeyboard);
      return;
    }

    this.transition("open", { fromKeyboard });
  }

  /**
   * Points the menu at `trigger` with `context`. Already open for another
   * trigger, the menu moves over in place: `on-close` fires for the old
   * context and `on-open` for the new one.
   */
  setAnchor(trigger, context) {
    const detached = trigger && trigger !== this.trigger ? trigger : null;
    const open = this.state === "open";
    if (
      open &&
      detached === this.activeTrigger &&
      JSON.stringify(context) === JSON.stringify(this.context)
    ) {
      return;
    }

    if (open) {
      this.pushEvent("close", { ...this.context });
      this.detached.release({ keepValues: true });
    }

    this.detached.set(detached, context);

    if (open) {
      this.detached.activate();
      this.pushEvent("open", { ...this.context });
    }
  }

  // Where a menu opened without a pointer position goes.
  anchorPoint() {
    const rect = this.anchorEl?.getBoundingClientRect();
    return { x: rect?.left || 0, y: rect?.bottom || 0 };
  }

  onOpenEnter({ fromKeyboard = false } = {}) {
    const active = document.activeElement;
    this.previousFocusEl = active && active !== document.body ? active : null;
    this.show();
    this.detached.activate();
    this.focusContent(fromKeyboard);
    this.pushEvent("open", { ...this.context });
  }

  show() {
    // Opened by a server/client command: anchor at the trigger.
    if (!this.point) this.point = this.anchorPoint();

    if (this.options.usePortal && this.positioner) {
      const container = this.options.portalContainer
        ? document.querySelector(this.options.portalContainer)
        : null;
      Portal.move(this.positioner, container || document.body);
    }

    this.position();
    this.startOpenListeners();
    this.modalLayer.activate();
  }

  // Runs as soon as the menu starts closing, before the exit animation: the
  // close event and the focus return must not wait for it, since a LiveView
  // patch in that window (e.g. the reply to an item's on-select) rebuilds the
  // component and the deferred closed-state handler never runs.
  onOpenExit({ restoreFocus = true, anchorRemoved = false } = {}) {
    // Unblock first: the element focus returns to is aria-hidden while the
    // menu blocks. The scroll lock holds until the exit animation ends.
    this.modalLayer.releaseInteraction();
    this.menu?.closeSubmenus();
    this.stopOpenListeners();
    this.pushEvent("close", { ...this.context });

    const target = this.previousFocusEl;
    const path = this.detached.path;
    this.previousFocusEl = null;
    this.detached.release();
    if (!restoreFocus) return;

    if (target?.isConnected) {
      target.focus();
      return;
    }
    if (!anchorRemoved) return;

    // The trigger is gone (its row was deleted): focus what held it, and
    // never leave focus in the hidden menu.
    if (
      !focusFallback(path) &&
      this.positioner?.contains(document.activeElement)
    ) {
      document.activeElement.blur();
    }
  }

  // After the exit animation.
  onClosedEnter() {
    this.point = null;
    // Runs from the base constructor too, before the layer exists.
    this.modalLayer?.deactivate();

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
    if (!isRtl(this.anchorEl || this.el)) return side;
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
      // Hangs the other way from the pointer below instead of shifting.
      shift: false,
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
  // handler (or, for a detached trigger, the delegated one) re-anchors it
  // instead.
  handleDocumentContextMenu(event) {
    if (
      this.trigger?.contains(event.target) ||
      this.positioner?.contains(event.target) ||
      this.ownedTriggerOf(event.target)
    ) {
      if (this.positioner?.contains(event.target)) event.preventDefault();
      return;
    }

    // While a modal menu blocks the page, a right click on a trigger lands
    // on <html>; it still moves the menu there (Radix closes the menu on
    // pointerdown, then the trigger reopens it).
    const trigger = this.modalLayer.blocking ? this.triggerAt(event) : null;
    if (trigger) {
      event.preventDefault();
      this.openAt(
        { x: event.clientX, y: event.clientY },
        trigger === this.anchorEl
          ? {}
          : { trigger, context: readContext(trigger) },
      );
      return;
    }

    this.transition("close", { restoreFocus: false });
  }

  // The detached trigger for this menu `node` is in, if any.
  ownedTriggerOf(node) {
    const trigger = closestTrigger(node, this.el.id);
    return trigger && this.ownsDetached(trigger) ? trigger : null;
  }

  // The trigger under the pointer (the current one first, then the nested
  // trigger, then this menu's detached triggers).
  triggerAt(event) {
    const candidates = [this.anchorEl, this.trigger];
    if (this.el.id) candidates.push(...triggersFor(this.el.id));
    return (
      candidates.find(
        (trigger) =>
          trigger &&
          (trigger === this.trigger
            ? !this.triggerDisabled
            : this.ownsDetached(trigger)) &&
          this.pointIn(trigger, event),
      ) || null
    );
  }

  pointIn(trigger, { clientX: x, clientY: y }) {
    const rect = trigger?.getBoundingClientRect();
    return (
      !!rect &&
      x >= rect.left &&
      x <= rect.right &&
      y >= rect.top &&
      y <= rect.bottom
    );
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
    this.detached.restore(saved.detached);
    // The patch that rebuilt the menu also removed its trigger.
    if (this.activeTrigger && !this.activeTrigger.isConnected) {
      this.previousFocusEl = saved.previousFocusEl;
      this.transition("close", { anchorRemoved: true });
      return;
    }

    this.previousFocusEl = saved.previousFocusEl?.isConnected
      ? saved.previousFocusEl
      : null;
    this.show();
    this.detached.activate();

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
        detached: this.detached.snapshot(),
      });
    }

    // The patch reverts the items to the server's markup; the rebuilt
    // instance writes the context back (afterMount()).
    this.detached.clearValues();
    clearGeneratedIdsWithin(this.el, this.positioner);
  }

  /**
   * `open` and `toggle` take optional params: `anchor`, an element or
   * selector to open at (its bottom-left corner) instead of the nested
   * trigger; `x` and `y`, a viewport point to open at instead; and
   * `context`, a map for the items (read from the anchor's
   * `data-salad-context` when omitted). A shared menu without a nested
   * trigger needs an `anchor` or a point.
   */
  handleCommand(command, params = {}) {
    if (command === "toggle" && this.state === "open") {
      return this.transition("close", params);
    }
    if (command !== "open" && command !== "toggle") {
      return super.handleCommand(command, params);
    }

    const { anchor, context, x, y } = params || {};
    const point = Number.isFinite(x) && Number.isFinite(y) ? { x, y } : null;
    if (!anchor && !point && context === undefined && this.anchorEl) {
      return this.transition("open", params);
    }

    const target = resolveAnchor(anchor);
    if (anchor && !target) {
      console.warn("SaladUI: context menu anchor not found:", anchor);
      return false;
    }
    if (!target && !point && !this.anchorEl) {
      console.warn("SaladUI: a shared context menu needs an anchor to open");
      return false;
    }

    return this.openAt(point, {
      trigger: target || this.anchorEl,
      context: context === undefined ? readContext(target) : context,
    });
  }

  beforeDestroy() {
    this.clearLongPress();
    this.stopOpenListeners();
    // A rebuild that stays open re-applies these from afterMount().
    this.detached.teardown();
    // A rebuild that stays open activates a new layer from afterMount().
    this.modalLayer.deactivate();
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
