// saladui/components/sidebar.js
//
// Client-side port of shadcn/ui's SidebarProvider. The hook lives on
// `sidebar_provider` and drives every `sidebar` inside it:
//
//   * desktop open state (`expanded` / `collapsed`), mirrored onto each
//     sidebar's `data-state` / `data-collapsible` so the shadcn Tailwind
//     classes (`group-data-[collapsible=icon]:...`) keep working;
//   * a mobile offcanvas sheet below 768px (matchMedia, like useIsMobile),
//     with overlay, Escape / outside click to close, a focus trap and the
//     modal layer (shadcn renders a modal Sheet there: the page behind is
//     blocked, aria-hidden and scroll-locked);
//   * the Cmd/Ctrl+B shortcut (SIDEBAR_KEYBOARD_SHORTCUT);
//   * the `sidebar_state` cookie, so the server can render the last state;
//   * `on-open-change` and the open/close/toggle commands;
//   * sidebar_menu_button tooltips, shown only while collapsed on desktop.
import Component, { assignId } from "../core/component.js";
import SaladUI from "../index.js";
import FocusTrap from "../core/focus-trap.js";
import PositionedElement from "../core/positioned-element.js";
import { ModalLayer } from "../core/modal-layer.js";

export const SIDEBAR_COOKIE_NAME = "sidebar_state";
export const SIDEBAR_COOKIE_MAX_AGE = 60 * 60 * 24 * 7;
export const SIDEBAR_KEYBOARD_SHORTCUT = "b";
export const MOBILE_BREAKPOINT = 768;

const SIDEBAR_SELECTOR = '[data-slot="sidebar"][data-collapsible-mode]';
const TRIGGER_SELECTOR = '[data-sidebar="trigger"]';
// Only the sidebar's own controls act on it: the provider wraps the whole
// layout, so any other `data-action` inside it belongs to someone else.
const ACTION_SELECTOR = [
  '[data-sidebar="trigger"][data-action]',
  '[data-sidebar="rail"][data-action]',
  '[data-sidebar="overlay"][data-action]',
].join(", ");
const MENU_BUTTON_SELECTOR = '[data-sidebar="menu-button"]';
const MENU_TOOLTIP_SELECTOR = '[data-sidebar="menu-tooltip"]';

// Ids generated for menu tooltips rendered without a button id.
let tooltipIds = 0;

class SidebarComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext, initialState: "expanded", ignoreItems: false });

    this.openMobile = this.el.dataset.openMobile === "true";
    this.lastServerOpen = this.el.dataset.open;
    this.commandTargets = new Set();

    this.onSidebarCommand = this.onSidebarCommand.bind(this);
    this.onKeyDown = this.onKeyDown.bind(this);
    this.onMediaChange = this.onMediaChange.bind(this);
    this.onTooltipEnter = this.onTooltipEnter.bind(this);
    this.onTooltipLeave = this.onTooltipLeave.bind(this);
    this.hideTooltip = this.hideTooltip.bind(this);
    this.activeTooltip = null;
    this.tooltipSides = new WeakMap();

    const breakpoint = this.options.mobileBreakpoint || MOBILE_BREAKPOINT;
    this.mediaQuery =
      typeof window !== "undefined" && typeof window.matchMedia === "function"
        ? window.matchMedia(`(max-width: ${breakpoint - 1}px)`)
        : null;

    this.collectElements();
    this.isMobile = this.detectMobile();
    if (!this.isMobile) this.openMobile = false;
  }

  parseOptions() {
    super.parseOptions();

    // A controlled provider (`open` set) wins over the rendered data-state.
    const open = this.el.dataset.open;
    if (open === "true" || open === "false") {
      this.initialState = open === "true" ? "expanded" : "collapsed";
    }
    if (!["expanded", "collapsed"].includes(this.initialState)) {
      this.initialState = "expanded";
    }
  }

  // The provider has no parts of its own; nested components own theirs.
  queryParts() {
    return [this.el];
  }

  getComponentConfig() {
    return {
      stateMachine: {
        expanded: { transitions: { collapse: "collapsed" } },
        collapsed: { transitions: { expand: "expanded" } },
      },
    };
  }

  /**
   * Sidebars and triggers that belong to this provider (not to a nested one).
   * Re-run after a LiveView patch, which may have replaced them.
   */
  collectElements() {
    const owned = (node) =>
      node.closest('[data-component="sidebar"]') === this.el;

    this.sidebars = Array.from(
      this.el.querySelectorAll(SIDEBAR_SELECTOR),
    ).filter(owned);
    this.triggers = Array.from(
      this.el.querySelectorAll(TRIGGER_SELECTOR),
    ).filter(owned);
  }

  detectMobile() {
    if (typeof this.options.isMobile === "boolean")
      return this.options.isMobile;

    const forced = this.sidebars.find((sidebar) => sidebar.dataset.isMobile);
    if (forced) return forced.dataset.isMobile === "true";

    return !!this.mediaQuery?.matches;
  }

  get open() {
    return this.state === "expanded";
  }

  setupComponentEvents() {
    super.setupComponentEvents();

    document.addEventListener("keydown", this.onKeyDown);
    if (this.mediaQuery?.addEventListener) {
      this.mediaQuery.addEventListener("change", this.onMediaChange);
    } else {
      this.mediaQuery?.addListener?.(this.onMediaChange);
    }
    this.el.addEventListener("mouseover", this.onTooltipEnter);
    this.el.addEventListener("focusin", this.onTooltipEnter);
    this.el.addEventListener("mouseout", this.onTooltipLeave);
    this.el.addEventListener("focusout", this.onTooltipLeave);
    this.el.addEventListener("pointerdown", this.hideTooltip);
    this.bindCommandTargets();
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();

    this.el.removeEventListener("mouseover", this.onTooltipEnter);
    this.el.removeEventListener("focusin", this.onTooltipEnter);
    this.el.removeEventListener("mouseout", this.onTooltipLeave);
    this.el.removeEventListener("focusout", this.onTooltipLeave);
    this.el.removeEventListener("pointerdown", this.hideTooltip);
    document.removeEventListener("keydown", this.onKeyDown);
    if (this.mediaQuery?.removeEventListener) {
      this.mediaQuery.removeEventListener("change", this.onMediaChange);
    } else {
      this.mediaQuery?.removeListener?.(this.onMediaChange);
    }
    this.commandTargets.forEach((target) =>
      target.removeEventListener("salad_ui:command", this.onSidebarCommand),
    );
    this.commandTargets.clear();
  }

  /**
   * `dispatch_command(..., to: "#<sidebar id>")` targets a sidebar rather
   * than the provider, so each sidebar forwards its commands here.
   */
  bindCommandTargets() {
    const current = new Set(this.sidebars);
    this.commandTargets.forEach((target) => {
      if (!current.has(target)) {
        target.removeEventListener("salad_ui:command", this.onSidebarCommand);
        this.commandTargets.delete(target);
      }
    });
    current.forEach((target) => {
      if (this.commandTargets.has(target)) return;
      target.addEventListener("salad_ui:command", this.onSidebarCommand);
      this.commandTargets.add(target);
    });
  }

  onSidebarCommand(event) {
    const { command, params = {} } = event.detail || {};
    if (!command) return;

    event.stopPropagation();
    this.handleCommand(command, params ?? {});
  }

  /**
   * The trigger, the rail and the overlay act through `data-action`. Only
   * they do: the provider wraps the whole layout, so other `data-action`
   * elements in it (a collapsible menu button, app markup) are not ours. A
   * trigger counts even inside another component (e.g. a tooltip), as long
   * as this is its nearest provider.
   */
  handleActionClick(event) {
    const actionElement = event.target.closest?.(ACTION_SELECTOR);
    if (!actionElement || !this.owns(actionElement)) return;

    this.transition(actionElement.getAttribute("data-action"), {
      originalEvent: event,
      target: actionElement,
    });
  }

  owns(node) {
    return node.closest('[data-component="sidebar"]') === this.el;
  }

  // --- Menu button tooltips ----------------------------------------------
  //
  // sidebar_menu_button renders its tooltip as the button's next sibling
  // (hidden), so it never wraps the button. As in shadcn (TooltipProvider
  // delayDuration={0}, `hidden={state !== "collapsed" || isMobile}`), it
  // opens at once on hover or focus, but only if the button's sidebar is
  // collapsed and the layout is not mobile at that moment. While it shows,
  // the button is aria-describedby it, as in Radix: by the server-rendered
  // `<button id>-tooltip`, or else an id generated here (stripped again
  // before each patch by the hook, and re-assigned after it).

  tooltipFor(button) {
    const next = button?.nextElementSibling;
    return next?.matches(MENU_TOOLTIP_SELECTOR) ? next : null;
  }

  canShowTooltip(button) {
    if (this.isMobile || !button?.isConnected || !this.owns(button)) {
      return false;
    }
    const sidebar = button.closest('[data-slot="sidebar"]');
    return sidebar?.getAttribute("data-state") === "collapsed";
  }

  onTooltipEnter(event) {
    const button = event.target.closest?.(MENU_BUTTON_SELECTOR);
    if (button) this.showTooltip(button);
  }

  onTooltipLeave(event) {
    const active = this.activeTooltip;
    if (!active || !active.button.contains(event.target)) return;
    if (event.relatedTarget && active.button.contains(event.relatedTarget)) {
      return;
    }
    this.hideTooltip();
  }

  showTooltip(button) {
    const tooltip = this.tooltipFor(button);
    if (!tooltip || !this.canShowTooltip(button)) return;
    if (this.activeTooltip?.tooltip === tooltip && !tooltip.hidden) return;

    this.hideTooltip();

    // data-side follows a flip; remember the side the server asked for.
    if (!this.tooltipSides.has(tooltip)) {
      this.tooltipSides.set(tooltip, tooltip.dataset.side || "right");
    }
    const offset = parseInt(tooltip.dataset.sideOffset, 10);
    const positioned = new PositionedElement(tooltip, button, {
      placement: this.tooltipSides.get(tooltip),
      alignment: tooltip.dataset.align || "center",
      sideOffset: Number.isNaN(offset) ? 8 : offset,
      alignOffset: 0,
      flip: true,
      usePortal: false,
      trapFocus: false,
      onPosition: ({ placement }) =>
        tooltip.setAttribute("data-side", placement),
    });

    tooltip.hidden = false;
    tooltip.setAttribute("data-state", "open");
    positioned.activate();
    const index = Array.from(
      this.el.querySelectorAll(MENU_BUTTON_SELECTOR),
    ).indexOf(button);
    this.activeTooltip = { button, tooltip, positioned, index };
    this.describeButton(button, tooltip, true);
  }

  // Adds (or removes) the tooltip's id to the button's aria-describedby,
  // keeping any description the button already had.
  describeButton(button, tooltip, described) {
    const tooltipId = described
      ? assignId(tooltip, `${this.el.id || "sidebar"}-tooltip-${++tooltipIds}`)
      : tooltip.id;
    if (!tooltipId) return;
    const ids = (button.getAttribute("aria-describedby") || "")
      .split(/\s+/)
      .filter((id) => id && id !== tooltipId);
    if (described) ids.push(tooltipId);

    if (ids.length) button.setAttribute("aria-describedby", ids.join(" "));
    else button.removeAttribute("aria-describedby");
  }

  hideTooltip() {
    const active = this.activeTooltip;
    if (!active) return;

    this.activeTooltip = null;
    active.positioned.destroy();
    active.tooltip.hidden = true;
    active.tooltip.setAttribute("data-state", "closed");
    this.describeButton(active.button, active.tooltip, false);
  }

  afterMount() {
    this.protectAttributes();
    this.withoutTransitions(() => this.syncSidebars());
    if (this.isMobile && this.openMobile) this.activateMobileSheet();
  }

  /**
   * LiveView would otherwise morph the client-owned attributes back to the
   * server-rendered markup on every patch, re-opening a sidebar the user
   * collapsed. `default_open` therefore only sets the initial state; use
   * `open` (controlled) to drive it from the server.
   */
  protectAttributes() {
    let js = null;
    try {
      js = this.hook?.js?.();
    } catch {
      js = null;
    }
    if (typeof js?.ignoreAttributes !== "function") return;

    js.ignoreAttributes(this.el, [
      "data-state",
      "data-mobile",
      "data-open-mobile",
    ]);
    this.sidebars.forEach((sidebar) => {
      js.ignoreAttributes(sidebar, [
        "data-state",
        "data-collapsible",
        "data-variant",
        "data-mobile",
      ]);
      const container = this.containerOf(sidebar);
      if (container) {
        js.ignoreAttributes(container, [
          "inert",
          "role",
          "aria-modal",
          "aria-label",
        ]);
      }
    });
    this.triggers.forEach((trigger) =>
      js.ignoreAttributes(trigger, ["aria-expanded"]),
    );
    // An open menu tooltip stays open and placed across a patch.
    this.el.querySelectorAll(MENU_TOOLTIP_SELECTOR).forEach((tooltip) => {
      if (this.owns(tooltip)) {
        js.ignoreAttributes(tooltip, [
          "hidden",
          "style",
          "data-state",
          "data-side",
        ]);
      }
    });
  }

  /**
   * Keep this instance across a patch: re-find the sidebars (they may have
   * been re-rendered), re-apply the client state and follow a changed
   * controlled `open`. Only changed options or event mappings rebuild it.
   */
  skipReinitialize(el) {
    if (el !== this.el) return false;
    if (
      el.getAttribute("data-options") !== this._optionsRaw ||
      el.getAttribute("data-event-mappings") !== this._eventMappingsRaw
    ) {
      return false;
    }

    const previousContainer = this.mobileContainer;
    const activeTooltip = this.activeTooltip;
    this.collectElements();
    this.bindCommandTargets();
    this.protectAttributes();

    const serverOpen = el.dataset.open;
    if (serverOpen !== this.lastServerOpen) {
      this.lastServerOpen = serverOpen;
      if (serverOpen === "true" || serverOpen === "false") {
        this.setOpen(serverOpen === "true", { notify: false, persist: false });
      }
    }

    this.updateUI();

    // A tooltip the patch replaced (or reset) is shown again on its button,
    // or on the button that took its place.
    if (
      activeTooltip &&
      (this.activeTooltip !== activeTooltip ||
        this.tooltipFor(activeTooltip.button) !== activeTooltip.tooltip ||
        activeTooltip.tooltip.hidden)
    ) {
      if (this.activeTooltip === activeTooltip) this.hideTooltip();
      const button = activeTooltip.button.isConnected
        ? activeTooltip.button
        : this.el.querySelectorAll(MENU_BUTTON_SELECTOR)[activeTooltip.index];
      if (button) this.showTooltip(button);
    }
    // The patch drops the client-set aria-describedby of a kept button.
    if (this.activeTooltip) {
      const { button, tooltip } = this.activeTooltip;
      this.describeButton(button, tooltip, true);
    }

    if (this.isMobile && this.openMobile) {
      const container = this.containerOf(this.sidebars[0]);
      if (container !== previousContainer) this.activateMobileSheet();
      else this.modalLayer?.refresh();
    }
    return true;
  }

  // updateUI() writes the provider's data-state; mirror it onto the sidebars.
  updateUI() {
    super.updateUI();
    if (this.sidebars) this.syncSidebars();
  }

  containerOf(sidebar) {
    return sidebar?.querySelector('[data-slot="sidebar-container"]') || null;
  }

  /**
   * Write the effective state onto every sidebar.
   *
   * Desktop: data-state is expanded/collapsed and data-collapsible carries
   * the collapsible mode while collapsed (empty while expanded), as shadcn.
   *
   * Mobile: shadcn renders a Sheet instead, whose content has data-state
   * open/closed and no data-variant/data-collapsible. The same markup is
   * restyled here: data-mobile="true", data-state open/closed, and a closed
   * sheet reuses the offcanvas position (data-collapsible="offcanvas").
   */
  syncSidebars() {
    const mobile = this.isMobile;
    const open = mobile ? this.openMobile : this.open;

    this.el.setAttribute("data-mobile", String(mobile));
    this.el.setAttribute("data-open-mobile", String(mobile && this.openMobile));

    this.sidebars.forEach((sidebar) => {
      const container = this.containerOf(sidebar);

      if (mobile) {
        sidebar.setAttribute("data-mobile", "true");
        sidebar.setAttribute("data-state", open ? "open" : "closed");
        sidebar.setAttribute("data-collapsible", open ? "" : "offcanvas");
        sidebar.removeAttribute("data-variant");
      } else {
        sidebar.removeAttribute("data-mobile");
        sidebar.setAttribute("data-state", this.state);
        sidebar.setAttribute(
          "data-collapsible",
          this.open ? "" : sidebar.dataset.collapsibleMode || "offcanvas",
        );
        sidebar.setAttribute(
          "data-variant",
          sidebar.dataset.sidebarVariant || "sidebar",
        );
      }

      if (!container) return;
      if (mobile && open) {
        container.removeAttribute("inert");
        container.setAttribute("role", "dialog");
        container.setAttribute("aria-modal", "true");
        container.setAttribute("aria-label", "Sidebar");
      } else {
        container.removeAttribute("role");
        container.removeAttribute("aria-modal");
        container.removeAttribute("aria-label");
        if (mobile) {
          container.setAttribute("inert", "");
        } else {
          container.removeAttribute("inert");
        }
      }
    });

    this.triggers.forEach((trigger) =>
      trigger.setAttribute("aria-expanded", String(open)),
    );

    // Expanding (or going mobile) hides an open menu tooltip.
    if (this.activeTooltip && !this.canShowTooltip(this.activeTooltip.button)) {
      this.hideTooltip();
    }
  }

  /**
   * Apply a state change with the sidebar's width/position transitions off,
   * e.g. the first sync after mount or a switch between mobile and desktop,
   * which should snap rather than slide.
   */
  withoutTransitions(callback) {
    const nodes = [];
    this.sidebars.forEach((sidebar) => {
      nodes.push(sidebar);
      sidebar
        .querySelectorAll(
          '[data-slot="sidebar-gap"], [data-slot="sidebar-container"], [data-slot="sidebar-overlay"]',
        )
        .forEach((node) => nodes.push(node));
    });

    nodes.forEach((node) => (node.style.transition = "none"));
    callback();
    // Force a style flush so the snapped values are committed before the
    // transitions come back.
    nodes.forEach((node) => node.offsetWidth);
    requestAnimationFrame(() => {
      nodes.forEach((node) => {
        node.style.transition = "";
        if (node.getAttribute("style") === "") node.removeAttribute("style");
      });
    });
  }

  // Commands and data-action clicks: open/close/toggle act on whichever
  // sidebar is showing (the mobile sheet or the desktop sidebar), as
  // shadcn's toggleSidebar does; expand/collapse always target desktop.
  transition(event, _params = {}) {
    if (this.destroyed) return false;

    switch (event) {
      case "toggle":
        return this.toggleSidebar();
      case "open":
        return this.isMobile ? this.setOpenMobile(true) : this.setOpen(true);
      case "close":
        return this.isMobile ? this.setOpenMobile(false) : this.setOpen(false);
      // shadcn's setOpenMobile: act on the phone sheet only, e.g. close it
      // after a navigation link without collapsing the desktop sidebar.
      case "open-mobile":
        return this.isMobile && this.setOpenMobile(true);
      case "close-mobile":
        return this.setOpenMobile(false);
      case "expand":
        return this.setOpen(true);
      case "collapse":
        return this.setOpen(false);
      default:
        return false;
    }
  }

  toggleSidebar() {
    return this.isMobile
      ? this.setOpenMobile(!this.openMobile)
      : this.setOpen(!this.open);
  }

  /**
   * Desktop open state. Writes the cookie and fires `on-open-change` unless
   * the change came from the server (a controlled `open`).
   */
  setOpen(open, { notify = true, persist = true } = {}) {
    if (this.open === open) return false;

    super.transition(open ? "expand" : "collapse");

    if (persist) this.writeCookie(open);
    if (notify) this.pushEvent("open-change", { open });
    return true;
  }

  setOpenMobile(open) {
    if (this.openMobile === open) return false;

    this.openMobile = open;
    this.syncSidebars();

    if (open) {
      this.activateMobileSheet();
    } else {
      this.deactivateMobileSheet();
    }

    this.pushEvent("open-mobile-change", { open });
    return true;
  }

  activateMobileSheet() {
    const container = this.containerOf(this.sidebars[0]);
    if (!container) return;

    if (this.mobileContainer !== container) {
      this.focusTrap?.destroy?.();
      this.focusTrap = new FocusTrap(container);
      this.mobileContainer = container;
    }
    this.focusTrap.activate();
    // The sheet and its overlay (which closes it on click) form the layer.
    // Re-activation after a patch keeps the layer it already has.
    if (!this.modalLayer) {
      this.modalLayer = new ModalLayer(() => {
        const sidebar = this.mobileContainer?.closest('[data-slot="sidebar"]');
        return [
          this.mobileContainer,
          sidebar?.querySelector('[data-slot="sidebar-overlay"]'),
        ];
      });
    }
    this.modalLayer.activate();
  }

  deactivateMobileSheet() {
    // Unblock first: focus returns to the trigger, aria-hidden until then.
    this.modalLayer?.deactivate();
    this.focusTrap?.deactivate();
  }

  writeCookie(open) {
    // An explicit null (`cookie={nil}`) turns the cookie off.
    const name =
      "cookieName" in this.options
        ? this.options.cookieName
        : SIDEBAR_COOKIE_NAME;
    if (!name || typeof document === "undefined") return;

    document.cookie = `${name}=${open}; path=/; max-age=${SIDEBAR_COOKIE_MAX_AGE}`;
  }

  onKeyDown(event) {
    if (
      this.options.keyboardShortcut !== false &&
      event.key === SIDEBAR_KEYBOARD_SHORTCUT &&
      (event.metaKey || event.ctrlKey)
    ) {
      event.preventDefault();
      this.toggleSidebar();
      return;
    }

    if (event.key === "Escape") this.hideTooltip();

    if (
      event.key === "Escape" &&
      !event.defaultPrevented &&
      this.isMobile &&
      this.openMobile
    ) {
      event.preventDefault();
      this.setOpenMobile(false);
    }
  }

  onMediaChange() {
    const mobile = this.detectMobile();
    if (mobile === this.isMobile) return;

    // Leaving mobile closes the sheet; its open state is mobile-only.
    if (!mobile && this.openMobile) {
      this.openMobile = false;
      this.deactivateMobileSheet();
    }
    this.isMobile = mobile;
    this.withoutTransitions(() => this.syncSidebars());
  }

  beforeDestroy() {
    this.hideTooltip();
    this.focusTrap?.destroy?.();
    this.focusTrap = null;
    this.modalLayer?.deactivate();
    this.modalLayer = null;
    this.mobileContainer = null;
  }
}

SaladUI.register("sidebar", SidebarComponent);

export default SidebarComponent;
