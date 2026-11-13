// saladui/components/menubar.js
import Component from "../core/component.js";
import { isRtl } from "../core/direction.js";
import SaladUI from "../index.js";
import ClickOutsideMonitor from "../core/click-outside.js";
import PositionedElement from "../core/positioned-element.js";
import Portal from "../core/portal.js";
import Menu, { assignId, clearGeneratedIds } from "./menu.js";

// The open menu, tab stop and focus, handed from the instance a LiveView
// patch tears down to the one rebuilt in its place (keyed by root element).
const pendingRestores = new WeakMap();

function isDisabled(trigger) {
  if (!trigger) return true;
  const value = trigger.getAttribute("data-disabled");
  return trigger.disabled || (value !== null && value !== "false");
}

function intAttr(el, name, fallback) {
  const value = parseInt(el?.getAttribute(name) ?? "", 10);
  return Number.isFinite(value) ? value : fallback;
}

/**
 * Menubar: a row of triggers (one roving tab stop, `ArrowLeft`/`ArrowRight`
 * between them), each opening a menu panel. At most one menu is open; while
 * one is, hovering another trigger switches to it. Each panel's items,
 * checkbox/radio items and sub-menus are the dropdown menu's `Menu`
 * internals.
 *
 * The root state machine tracks whether any menu is open; which one lives in
 * `this.value` (its `data-value`, "" when closed).
 */
class MenubarComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext, initialState: "closed" });

    this.value = "";
    this.loop = this.options.loop !== false;

    this.handleTriggerPointerDown = this.handleTriggerPointerDown.bind(this);
    this.handleTriggerPointerEnter = this.handleTriggerPointerEnter.bind(this);
    this.handleTriggerKeydown = this.handleTriggerKeydown.bind(this);
    this.handleTriggerFocus = this.handleTriggerFocus.bind(this);
    this.handleContentKeydown = this.handleContentKeydown.bind(this);
    this.handleFocusOut = this.handleFocusOut.bind(this);

    this.menus = this.collectMenus();
    this.tabStop = this.menus.find((menu) => !isDisabled(menu.trigger)) || null;

    this.clickOutside = new ClickOutsideMonitor(this.ownElements(), () =>
      this.setValue("", { restoreFocus: false }),
    );

    this.updateUI();
  }

  getComponentConfig() {
    return {
      stateMachine: {
        closed: { transitions: { open: "open" } },
        open: { transitions: { close: "closed" } },
      },
    };
  }

  collectMenus() {
    const menuEls = Array.from(
      this.el.querySelectorAll("[data-part='menu']"),
    ).filter((element) => element.closest("[data-component]") === this.el);

    return menuEls.map((element, index) => {
      const value = element.getAttribute("data-value") || `menu-${index}`;
      const trigger = element.querySelector(":scope > [data-part='trigger']");
      const positioner = element.querySelector(
        ":scope > [data-part='positioner']",
      );
      const content = positioner?.querySelector(
        ":scope > [data-part='content']",
      );

      assignId(trigger, `${this.el.id}-trigger-${value}`);
      assignId(content, `${this.el.id}-content-${value}`);

      const entry = {
        value,
        element,
        trigger,
        positioner,
        content,
        positionedElement: null,
      };

      entry.menu = content
        ? new Menu(content, {
            hookContext: this.hook,
            rootEl: this.el,
            onItemSelect: () => this.setValue("", { restoreFocus: true }),
          })
        : null;

      return entry;
    });
  }

  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------

  // Only the root carries the open/closed state; each trigger and panel gets
  // its own from `this.value` in syncMenus().
  updateUI() {
    this.el.setAttribute("data-state", this.stateMachine.state);
    if (this.menus) this.syncMenus();
  }

  syncMenus() {
    this.menus.forEach((menu) => {
      const open = menu.value === this.value;
      const state = open ? "open" : "closed";
      const { trigger, content } = menu;

      if (trigger) {
        trigger.setAttribute("data-state", state);
        trigger.setAttribute("aria-expanded", String(open));
        trigger.setAttribute("tabindex", menu === this.tabStop ? "0" : "-1");
        if (content) trigger.setAttribute("aria-controls", content.id);
      }
      if (content) {
        content.setAttribute("data-state", state);
        if (trigger) content.setAttribute("aria-labelledby", trigger.id);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Opening and closing
  // ---------------------------------------------------------------------------

  menuByValue(value) {
    if (!value) return null;
    return this.menus.find((menu) => menu.value === value) || null;
  }

  get openMenu() {
    return this.menuByValue(this.value);
  }

  /**
   * Open the menu with `value` ("" closes). `focus` is where focus goes in
   * the newly open menu: "first"/"last" item, "content", or null to leave it
   * (e.g. on the trigger, when hovering across triggers). `silent` skips the
   * value-changed event (re-opening after a LiveView patch).
   */
  setValue(value, { focus = null, restoreFocus = false, silent = false } = {}) {
    const next = this.menuByValue(value);
    const nextValue =
      next && next.content && !isDisabled(next.trigger) ? value : "";
    const prev = this.openMenu;

    if (nextValue === this.value) {
      if (next) this.focusMenu(next, focus);
      return;
    }

    this.value = nextValue;
    const nextMenu = this.openMenu;

    if (prev) this.hideMenu(prev);
    if (nextMenu) {
      this.tabStop = nextMenu;
      this.showMenu(nextMenu);
    }

    if (nextMenu && this.state !== "open") {
      this.transition("open");
    } else if (!nextMenu && this.state !== "closed") {
      this.transition("close");
    } else {
      this.syncMenus();
    }

    if (nextMenu) {
      this.clickOutside?.start();
      this.focusMenu(nextMenu, focus);
    } else {
      this.clickOutside?.stop();
      if (restoreFocus) prev?.trigger?.focus();
    }

    if (!silent) this.pushEvent("value-changed", { value: nextValue });
  }

  showMenu(menu) {
    const { positioner, trigger } = menu;
    if (!positioner) return;

    positioner.hidden = false;

    if (!menu.positionedElement) {
      const container = this.options.portalContainer
        ? document.querySelector(this.options.portalContainer)
        : null;

      menu.positionedElement = new PositionedElement(positioner, trigger, {
        placement: positioner.getAttribute("data-side") || "bottom",
        alignment: positioner.getAttribute("data-align") || "start",
        sideOffset: intAttr(positioner, "data-side-offset", 8),
        alignOffset: intAttr(positioner, "data-align-offset", -4),
        flip: true,
        usePortal: this.options.usePortal === true,
        portalContainer: container || document.body,
        trapFocus: false,
        onPosition: ({ placement }) =>
          menu.content?.setAttribute("data-side", placement),
      });
    }

    menu.positionedElement.activate();
  }

  hideMenu(menu) {
    menu.menu?.closeSubmenus();
    menu.menu?.reset();
    menu.positionedElement?.deactivate();
    if (menu.positioner) menu.positioner.hidden = true;
  }

  focusMenu(menu, focus) {
    if (!focus) return;

    if (focus === "first" || focus === "last") {
      menu.menu?.activate(focus);
    } else if (focus === "content") {
      menu.menu?.reset();
      menu.content?.focus({ preventScroll: true });
    }
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  // Triggers and (possibly portalled) panels: what counts as "inside".
  ownElements() {
    return this.menus.flatMap(({ trigger, positioner }) =>
      [trigger, positioner].filter(Boolean),
    );
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    this.menus.forEach(({ trigger, positioner }) => {
      trigger?.addEventListener("pointerdown", this.handleTriggerPointerDown);
      trigger?.addEventListener("pointerenter", this.handleTriggerPointerEnter);
      trigger?.addEventListener("keydown", this.handleTriggerKeydown);
      trigger?.addEventListener("focus", this.handleTriggerFocus);
      positioner?.addEventListener("keydown", this.handleContentKeydown);
      positioner?.addEventListener("focusout", this.handleFocusOut);
    });
    this.el.addEventListener("focusout", this.handleFocusOut);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    this.menus?.forEach(({ trigger, positioner }) => {
      trigger?.removeEventListener(
        "pointerdown",
        this.handleTriggerPointerDown,
      );
      trigger?.removeEventListener(
        "pointerenter",
        this.handleTriggerPointerEnter,
      );
      trigger?.removeEventListener("keydown", this.handleTriggerKeydown);
      trigger?.removeEventListener("focus", this.handleTriggerFocus);
      positioner?.removeEventListener("keydown", this.handleContentKeydown);
      positioner?.removeEventListener("focusout", this.handleFocusOut);
    });
    this.el?.removeEventListener("focusout", this.handleFocusOut);
    this.clickOutside?.stop();
  }

  menuForTrigger(target) {
    return this.menus.find((menu) => menu.trigger === target) || null;
  }

  handleTriggerPointerDown(event) {
    const menu = this.menuForTrigger(event.currentTarget);
    if (!menu || isDisabled(menu.trigger)) return;
    // Primary button only; ctrl-click is a right click on macOS.
    if ((event.button ?? 0) !== 0 || event.ctrlKey) return;

    // Focus the trigger ourselves (Safari does not focus buttons on click),
    // and keep it there while the menu opens, as in Radix: the arrow keys
    // then work from the trigger.
    event.preventDefault();
    menu.trigger.focus();
    this.setValue(this.value === menu.value ? "" : menu.value);
  }

  handleTriggerPointerEnter(event) {
    // Touch fires pointerenter right before pointerdown; switching here
    // would make that pointerdown close the menu again.
    if (event.pointerType && event.pointerType !== "mouse") return;

    const menu = this.menuForTrigger(event.currentTarget);
    if (!menu || !this.value || this.value === menu.value) return;
    if (isDisabled(menu.trigger)) return;

    this.setValue(menu.value);
    menu.trigger.focus();
  }

  // Focus moving somewhere outside the triggers and panels (Tab away, a
  // click on another focusable element) closes the open menu.
  handleFocusOut(event) {
    const next = event.relatedTarget;
    if (!this.value || !next) return;
    if (this.ownElements().some((element) => element.contains(next))) return;

    this.setValue("");
  }

  handleTriggerFocus(event) {
    const menu = this.menuForTrigger(event.currentTarget);
    if (!menu || menu === this.tabStop) return;

    this.tabStop = menu;
    this.syncMenus();
  }

  get nextKey() {
    return isRtl(this.el) ? "ArrowLeft" : "ArrowRight";
  }

  /**
   * The enabled menu `step` places away from `from` (1 = next, -1 =
   * previous), wrapping around when `loop` is on.
   */
  adjacentMenu(from, step) {
    const enabled = this.menus.filter((menu) => !isDisabled(menu.trigger));
    if (enabled.length === 0) return null;

    const index = enabled.indexOf(from);
    if (index === -1) return enabled[0];

    let target = index + step;
    if (target < 0 || target >= enabled.length) {
      if (!this.loop) return null;
      target = (target + enabled.length) % enabled.length;
    }
    return enabled[target];
  }

  focusTrigger(menu) {
    if (!menu) return;

    this.tabStop = menu;
    this.syncMenus();
    menu.trigger.focus();
  }

  handleTriggerKeydown(event) {
    const menu = this.menuForTrigger(event.currentTarget);
    if (!menu || isDisabled(menu.trigger)) return;

    const enabled = this.menus.filter((item) => !isDisabled(item.trigger));
    const isOpen = this.value === menu.value;
    let target = null;

    switch (event.key) {
      case "Enter":
      case " ":
        this.setValue(isOpen ? "" : menu.value, { focus: "first" });
        break;
      case "ArrowDown":
        this.setValue(menu.value, { focus: "first" });
        break;
      case "ArrowUp":
        this.setValue(menu.value, { focus: "last" });
        break;
      case "ArrowRight":
      case "ArrowLeft":
        target = this.adjacentMenu(menu, event.key === this.nextKey ? 1 : -1);
        break;
      case "Home":
        target = enabled[0];
        break;
      case "End":
        target = enabled[enabled.length - 1];
        break;
      case "Escape":
        if (!this.value) return;
        this.setValue("");
        break;
      default:
        return;
    }

    event.preventDefault();
    event.stopPropagation();

    if (target && target !== menu) {
      this.focusTrigger(target);
      // With a menu open, moving between triggers moves the open menu along.
      if (this.value) this.setValue(target.value);
    }
  }

  handleContentKeydown(event) {
    const menu = this.openMenu;
    if (!menu || event.defaultPrevented) return;

    switch (event.key) {
      case "Escape":
        event.preventDefault();
        event.stopPropagation();
        this.setValue("", { restoreFocus: true });
        return;
      case "Tab":
        // Menus keep focus inside; Tab does nothing (WAI-ARIA, Radix).
        event.preventDefault();
        return;
      case "ArrowRight":
      case "ArrowLeft":
        this.moveToAdjacentMenu(event, menu);
        return;
    }
  }

  // ArrowRight/ArrowLeft on an item that does not open or close a sub-menu
  // (those keys stop propagating in menu.js) opens the next/previous menu.
  moveToAdjacentMenu(event, menu) {
    const isNext = event.key === this.nextKey;
    const target = event.target;
    if (isNext && target?.closest?.("[data-part='sub-trigger']")) return;
    const panel = target?.closest?.(
      "[data-part='content'], [data-part='sub-content']",
    );
    if (!isNext && panel && panel !== menu.content) return;

    const adjacent = this.adjacentMenu(menu, isNext ? 1 : -1);
    if (!adjacent || adjacent === menu) return;

    event.preventDefault();
    event.stopPropagation();
    this.tabStop = adjacent;
    this.setValue(adjacent.value, { focus: "first" });
  }

  // ---------------------------------------------------------------------------
  // Commands and LiveView lifecycle
  // ---------------------------------------------------------------------------

  handleCommand(command, params = {}) {
    switch (command) {
      case "open": {
        const value =
          params.value ||
          this.menus.find((menu) => !isDisabled(menu.trigger))?.value;
        return this.setValue(value || "", { focus: params.focus || null });
      }
      case "close":
        return this.setValue("", { restoreFocus: !!params.restoreFocus });
      default:
        return super.handleCommand(command, params);
    }
  }

  // A LiveView patch rebuilds the component (see hook.js): re-open the menu
  // the previous instance had open, with the same sub-menus open and the
  // same item focused, and keep the same trigger as the tab stop.
  afterMount() {
    const saved = pendingRestores.get(this.el);
    pendingRestores.delete(this.el);
    if (!saved) return;

    const tabStop = this.menuByValue(saved.tabStop);
    if (tabStop && !isDisabled(tabStop.trigger)) {
      this.tabStop = tabStop;
      this.syncMenus();
    }

    const menu = this.menuByValue(saved.value);
    if (!menu) return;

    this.setValue(menu.value, { silent: true });
    if (saved.menu?.focused || saved.menu?.openSubTriggers.length) {
      menu.menu?.restore(saved.menu);
    }
  }

  // Runs right before LiveView patches this element; updated() then rebuilds
  // the component, which picks the snapshot back up in afterMount().
  beforeUpdate() {
    const positioners = this.menus.map(({ positioner }) => positioner);
    positioners.forEach((positioner) => {
      if (positioner && Portal.isInPortal(positioner)) {
        Portal.restore(positioner);
      }
    });

    pendingRestores.set(this.el, {
      tabStop: this.tabStop?.value || null,
      value: this.value,
      menu: this.openMenu?.menu?.snapshot() || null,
    });

    clearGeneratedIds(this.el, ...positioners);
  }

  beforeDestroy() {
    this.clickOutside?.destroy();
    this.clickOutside = null;

    this.menus?.forEach((menu) => {
      menu.positionedElement?.destroy();
      menu.positionedElement = null;
      menu.menu?.destroy();
      menu.menu = null;
    });
  }
}

SaladUI.register("menubar", MenubarComponent);

export default MenubarComponent;
