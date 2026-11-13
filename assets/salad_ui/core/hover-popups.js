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
//   stuck).

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
  }

  // Whether an open request from `event` may start the open delay.
  mayOpen(event) {
    if (event?.type === "focusin" && pointerInteraction) return false;
    return !this.blocked();
  }

  blocked() {
    const trigger = this.component.trigger;
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
    openPopups.delete(this.component);
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
