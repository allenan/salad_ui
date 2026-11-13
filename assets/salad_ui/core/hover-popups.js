// saladui/core/hover-popups.js
//
// Shared rules for popups that open on hover or focus (tooltip, hover card),
// so they never pile up or compete with other popups:
// - one open at a time: opening one closes the others, except a popup whose
//   content holds the new one's trigger (a tooltip inside a hover card);
// - none opens while a click-opened popup (menu, popover, dialog, select, ...)
//   is open, unless its trigger is inside that popup's content;
// - focus that follows a pointer press does not open one; keyboard focus does;
// - an open one closes on Escape, on a scroll around its trigger, and when the
//   pointer is seen over something else (a missed mouseleave must not leave it
//   stuck);
// - one opened while a modal layer blocks the page (its trigger is inside a
//   dialog or menu) joins the layer stack as a non-modal layer above it, so
//   its content stays interactive, exposed and focusable even when it lives
//   outside that layer (a shared hover card or the tooltip provider).

import { ModalLayer, isModalBlocking } from "./modal-layer.js";

const CLICK_POPUPS = [
  "dialog",
  "drawer",
  "popover",
  "dropdown-menu",
  "context-menu",
  "menubar",
  "select",
  "combobox",
  "navigation-menu",
];
const OPEN_CLICK_POPUP = CLICK_POPUPS.map(
  (name) => `[data-component="${name}"][data-state="open"]`,
).join(", ");
const OPEN_POPUP_CONTENT = CLICK_POPUPS.concat(["hover-card"])
  .map(
    (name) => `[data-slot^="${name}"][data-slot$="content"][data-state="open"]`,
  )
  .concat(['[role="dialog"]', '[role="alertdialog"]', '[role="menu"]'])
  .join(", ");

const openPopups = new Set();

let pointerInteraction = false;
let listening = false;

function listenForInteraction() {
  if (listening || typeof document === "undefined") return;
  listening = true;
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

/** Close every open tooltip and hover card. */
export function closeAllHoverPopups() {
  openPopups.forEach((popup) => popup.closeNow());
}

// When a tooltip last closed, for Radix's skipDelayDuration: right after one
// tooltip closes (or while one is open), the next opens without its delay.
let lastTooltipClose = -Infinity;

/**
 * Whether a tooltip opening now skips its open delay: another tooltip is
 * open, or one closed less than `skipDelay` ms ago.
 */
export function tooltipSkipsDelay(skipDelay) {
  for (const popup of openPopups) {
    if (popup.isTooltip) return true;
  }
  return skipDelay > 0 && Date.now() - lastTooltipClose < skipDelay;
}

/** Forget the last tooltip close (for tests). */
export function resetTooltipSkipDelay() {
  lastTooltipClose = -Infinity;
}

/**
 * Mixin-style helper: a component (tooltip, hover card) owns one of these.
 * The component provides `trigger`, `content`, `state`, `closeNow()` and
 * `delayClose()`.
 */
export class HoverPopup {
  constructor(component) {
    this.component = component;
    listenForInteraction();
    this.onPointerMove = this.onPointerMove.bind(this);
    this.onKeyDown = this.onKeyDown.bind(this);
    this.onScroll = this.onScroll.bind(this);
    this.layer = new ModalLayer(() => [this.component.content], {
      modal: false,
    });
  }

  // Whether an open request from `event` (for `trigger`, the current one by
  // default) may start the open delay.
  mayOpen(event, trigger = this.component.trigger) {
    if (event?.type === "focusin" && pointerInteraction) return false;
    return !this.blocked(trigger);
  }

  blocked(trigger = this.component.trigger) {
    if (typeof document === "undefined" || !trigger) return false;
    if (!document.querySelector(OPEN_CLICK_POPUP)) return false;
    return !trigger.closest(OPEN_POPUP_CONTENT);
  }

  opened() {
    const trigger = this.component.trigger;
    openPopups.forEach((popup) => {
      if (popup === this.component) return;
      if (trigger && popup.content?.contains(trigger)) return;
      popup.closeNow();
    });
    openPopups.add(this.component);
    // Above an open modal layer, as the top layer's own content: the modal
    // layer's focus guard, pointer blocking and aria-hidden leave it be.
    if (isModalBlocking()) this.layer.activate();

    document.addEventListener("pointermove", this.onPointerMove, {
      passive: true,
    });
    document.addEventListener("keydown", this.onKeyDown);
    document.addEventListener("scroll", this.onScroll, {
      capture: true,
      passive: true,
    });
  }

  closed() {
    if (openPopups.delete(this.component) && this.component.isTooltip) {
      lastTooltipClose = Date.now();
    }
    this.layer.deactivate();
    if (typeof document === "undefined") return;
    document.removeEventListener("pointermove", this.onPointerMove);
    document.removeEventListener("keydown", this.onKeyDown);
    document.removeEventListener("scroll", this.onScroll, { capture: true });
  }

  // Over the trigger, the content, or a popup nested in it (a tooltip inside
  // a hover card): stay open.
  isInside(target) {
    const { trigger, content } = this.component;
    if (trigger?.contains(target) || content?.contains(target)) return true;
    for (const popup of openPopups) {
      if (
        popup !== this.component &&
        content?.contains(popup.trigger) &&
        popup.content?.contains(target)
      ) {
        return true;
      }
    }
    return false;
  }

  onPointerMove(event) {
    if (event.pointerType === "touch") return;
    if (this.isInside(event.target)) {
      if (this.component.closeTimer) this.component.clearTimers();
      return;
    }
    if (!this.component.closeTimer) this.component.delayClose();
  }

  onKeyDown(event) {
    if (event.key === "Escape") this.component.closeNow();
  }

  // Radix closes a tooltip when a scroll container around its trigger
  // scrolls: the content would otherwise float away from it.
  onScroll(event) {
    const target = event.target;
    const trigger = this.component.trigger;
    if (this.component.content?.contains(target)) return;
    if (target === document || target?.contains?.(trigger)) {
      this.component.closeNow();
    }
  }
}

/**
 * Hover and focus on detached triggers (core/detached-triggers.js) for a
 * shared tooltip or hover card, through the delegated document listeners:
 * `subscribe(type, handler)` is listen() bound to the instance (or
 * listenAttribute() for the tooltip provider). The component provides
 * `enterTrigger(event, trigger)`, `leaveTrigger(event, trigger)` and
 * optionally `pressTrigger(event, trigger)`.
 */
export class DetachedHoverTriggers {
  constructor(component, subscribe) {
    this.component = component;
    this.subscribe = subscribe;
    this.unsubscribe = [];
  }

  start() {
    this.stop();
    const component = this.component;
    // mouseover/mouseout bubble (mouseenter/mouseleave do not); moves
    // between a trigger's own children are not an enter or a leave.
    const crossing = (handler) => (event, trigger) => {
      if (trigger.contains(event.relatedTarget)) return;
      handler(event, trigger);
    };
    const enter = (event, trigger) => component.enterTrigger(event, trigger);
    const leave = (event, trigger) => component.leaveTrigger(event, trigger);
    this.unsubscribe = [
      this.subscribe("mouseover", crossing(enter)),
      this.subscribe("mouseout", crossing(leave)),
      this.subscribe("focusin", enter),
      this.subscribe("focusout", crossing(leave)),
      this.subscribe("pointerdown", (event, trigger) =>
        component.pressTrigger?.(event, trigger),
      ),
    ];
  }

  stop() {
    this.unsubscribe.forEach((off) => off());
    this.unsubscribe = [];
  }
}
