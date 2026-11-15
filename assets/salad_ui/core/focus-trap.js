// saladui/core/focus-trap.js
/**
 * FocusTrap utility for SaladUI components
 * Manages focus behavior for modals, popovers, and similar components
 */
// `element` itself when focusable, else its first focusable descendant (a
// trigger rendered as a <div> around a <button>).
function focusTarget(element, selector) {
  if (!element?.isConnected) return null;
  return element.matches(selector) ? element : element.querySelector(selector);
}

// Whether `el` is rendered and can take focus: not `hidden`, `inert`,
// `display: none` or `visibility: hidden` (itself or an ancestor). A closed
// popover nested in the content (an emoji picker's search box) matches the
// focusable selector but focus() on it does nothing.
function isVisible(el) {
  if (el.closest("[inert]")) return false;
  if (typeof el.checkVisibility === "function") {
    return el.checkVisibility({ visibilityProperty: true });
  }
  // No checkVisibility (Safari before 17.4, jsdom): walk up.
  const view = el.ownerDocument?.defaultView;
  for (let node = el; node && node.nodeType === 1; node = node.parentElement) {
    if (node.hidden) return false;
    const style = view?.getComputedStyle?.(node);
    if (style && (style.display === "none" || style.visibility === "hidden")) {
      return false;
    }
  }
  return true;
}

class FocusTrap {
  /**
   * Create a focus trap for a specific element
   *
   * @param {HTMLElement} element - The element to trap focus within
   * @param {Object} options - Focus trap options
   */
  constructor(element, options = {}) {
    this.element = element;
    this.options = {
      focusableSelector:
        'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
      // Loop Tab/Shift+Tab inside the element. Off for non-modal surfaces,
      // which only move focus in on open and back out on close (Radix's
      // FocusScope with `trapped={false}`).
      contain: true,
      // Where focus goes on deactivate() when nothing usable was focused at
      // activate() (focus was on <body>, or that element left the page): an
      // element, or a function returning one. A dialog opened by the server
      // passes its trigger, as Radix returns focus to the trigger.
      returnFocus: null,
      // When true, `returnFocus` wins over the element focused at activate()
      // (Radix's onCloseAutoFocus): an app names where focus goes on close.
      preferReturnFocus: false,
      // What gets focus on activate() when nothing inside is focusable: an
      // element, or a function returning one. Defaults to the trapped
      // element. A popover traps its positioner but names its content (the
      // dialog, which listens for Escape), as Radix focuses the content.
      fallbackFocus: null,
      // The element (or a function returning it) that counts as "inside"
      // when deciding whether focus was lost on close. Defaults to the
      // trapped element; a dialog passes its root, so focus on the overlay
      // container a click outside left it on still returns to the opener.
      scope: null,
      ...options,
    };

    this.previouslyFocused = null;
    this.active = false;

    // Bind methods that will be used as event handlers
    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.handleFocusIn = this.handleFocusIn.bind(this);
    this.handleMutations = this.handleMutations.bind(this);
  }

  /**
   * A LiveView patch removed the focused control (a "Join" button replaced
   * by "Leave"): focus fell to <body>, outside the trap, where keys such as
   * Escape go unheard. Put it back on the trapped element, as Radix's
   * FocusScope does.
   */
  handleMutations(mutations) {
    if (!this.active || !this.element?.isConnected) return;
    const focused = document.activeElement;
    if (focused && focused !== document.body) return;
    if (!mutations.some((mutation) => mutation.removedNodes.length > 0)) return;
    this.focusElement();
  }

  /** Focus the trapped element itself, making it focusable if need be. */
  focusElement() {
    if (!this.element.hasAttribute("tabindex")) {
      this.element.setAttribute("tabindex", "-1");
    }
    this.element.focus({ preventScroll: true });
  }

  observeRemovals() {
    if (this.options.contain === false) return;
    const Observer = this.element.ownerDocument?.defaultView?.MutationObserver;
    if (typeof Observer !== "function") return;
    this.observer ??= new Observer(this.handleMutations);
    this.observer.observe(this.element, { childList: true, subtree: true });
  }

  stopObservingRemovals() {
    this.observer?.disconnect();
  }

  /** The element focus counts as inside of (see the `scope` option). */
  scopeElement() {
    const { scope } = this.options ?? {};
    return (typeof scope === "function" ? scope() : scope) || this.element;
  }

  /**
   * While active, remember the last control outside that took focus: a menu
   * that opened this (a dialog from a menu item) hands focus back to its
   * button as it closes, and that button is where focus returns once the
   * item it was opened from is hidden.
   */
  handleFocusIn(event) {
    const target = event.target;
    if (!(target instanceof Element) || target === document.body) return;
    if (this.scopeElement()?.contains(target)) return;
    this.lastOutsideFocus = target;
  }

  /**
   * Activate the focus trap
   */
  activate() {
    if (this.active) return;

    // Store currently focused element to restore later; its id finds the
    // node a LiveView patch may replace it with.
    this.previouslyFocused = document.activeElement;
    this.previouslyFocusedId = this.previouslyFocused?.id || null;
    this.lastOutsideFocus = null;
    this.active = true;

    // Set up event listener for keyboard navigation
    this.element.addEventListener("keydown", this.handleKeyDown);
    document.addEventListener("focusin", this.handleFocusIn, true);
    this.observeRemovals();

    // Focus the first focusable element or the element itself
    this.setInitialFocus();
  }

  /**
   * Deactivate the focus trap and restore previous focus
   */
  deactivate() {
    // Closed while suspended: focus still goes back.
    if (this.suspended) this.resume();
    if (!this.active) return;

    // Remove event listeners
    this.element.removeEventListener("keydown", this.handleKeyDown);
    document.removeEventListener("focusin", this.handleFocusIn, true);
    this.stopObservingRemovals();

    const previouslyFocused = this.previouslyFocused;
    const previouslyFocusedId = this.previouslyFocusedId;
    const lastOutsideFocus = this.lastOutsideFocus;
    const container = this.scopeElement();
    const fallback = this.options.returnFocus;
    const preferFallback = this.options.preferReturnFocus;
    // Read now: destroy() clears the options before the timer runs.
    const selector = this.options.focusableSelector;

    // Return focus only while it is still in the closed content or nowhere
    // (on <body>): a close handler, or the click outside that closed it, may
    // have moved focus on purpose, and that wins (as Radix's FocusScope only
    // returns focus that is still inside).
    const focusLost = () => {
      const active = document.activeElement;
      return (
        !active ||
        active === document.body ||
        active === document.documentElement ||
        !active.isConnected ||
        container?.contains(active)
      );
    };

    // Where focus goes, decided when it goes (the close may have patched
    // the page): the opener, still on the page and rendered (restored even
    // when scrolled out of view, as Radix does); else the node a patch
    // replaced it with (same id); else the control outside that last took
    // focus while open (the button of the menu it was opened from); else the
    // fallback. An app's `return-focus` (preferReturnFocus) comes first.
    const restorable = (el) =>
      this.isRestorable(el) && isVisible(el) ? el : null;
    const fallbackTarget = () =>
      fallback
        ? restorable(
            focusTarget(
              typeof fallback === "function" ? fallback() : fallback,
              selector,
            ),
          )
        : null;
    const pick = () => {
      if (preferFallback) {
        const target = fallbackTarget();
        if (target) return target;
      }
      return (
        restorable(previouslyFocused) ||
        (previouslyFocusedId &&
          restorable(document.getElementById(previouslyFocusedId))) ||
        restorable(lastOutsideFocus) ||
        fallbackTarget()
      );
    };

    setTimeout(() => {
      if (typeof document === "undefined") return;
      if (!focusLost()) return;
      pick()?.focus();
    }, 0);

    this.previouslyFocused = null;
    this.previouslyFocusedId = null;
    this.lastOutsideFocus = null;
    this.active = false;
  }

  /**
   * Stop trapping for a moment (a LiveView patch of the content) without
   * returning focus or forgetting where it goes back to on deactivate().
   */
  suspend() {
    if (!this.active) return;
    this.element.removeEventListener("keydown", this.handleKeyDown);
    document.removeEventListener("focusin", this.handleFocusIn, true);
    this.stopObservingRemovals();
    this.active = false;
    this.suspended = true;
  }

  /** Trap again after suspend(), without moving focus. */
  resume() {
    if (!this.suspended) return;
    this.suspended = false;
    this.active = true;
    this.element.addEventListener("keydown", this.handleKeyDown);
    document.addEventListener("focusin", this.handleFocusIn, true);
    this.observeRemovals();
  }

  /**
   * Whether `element` (focused at activate()) can take focus back: still on
   * the page and not <body> (where focus sits when nothing is focused).
   */
  isRestorable(element) {
    return Boolean(
      element?.focus &&
      element !== document.body &&
      element !== document.documentElement &&
      document.body.contains(element),
    );
  }

  /**
   * Set initial focus when trap is activated
   */
  setInitialFocus() {
    setTimeout(() => {
      if (!this.active || !this.element) return;

      // Find all focusable elements after DOM is ready.
      const focusableElements = this.getFocusableElements();

      if (focusableElements.length > 0) {
        // A visible [autofocus] first (Radix's FocusScope too), else the
        // first visible focusable.
        const autoFocusEl = [
          ...this.element.querySelectorAll("[autofocus]"),
        ].find(isVisible);
        const initialFocusEl = autoFocusEl || focusableElements[0];
        initialFocusEl.focus();
      } else {
        // If no focusable elements, make the fallback (by default the
        // element itself) focusable.
        const { fallbackFocus } = this.options;
        const fallback =
          (typeof fallbackFocus === "function"
            ? fallbackFocus()
            : fallbackFocus) || this.element;
        const target = this.element.contains(fallback)
          ? fallback
          : this.element;
        if (!target.hasAttribute("tabindex")) {
          target.setAttribute("tabindex", "-1");
        }
        target.focus();
      }
    }, 50); // Small delay to ensure DOM is ready
  }

  /**
   * Handle keydown events for tab trapping and escape handling
   */
  handleKeyDown(event) {
    // Handle Tab key for focus trapping
    if (event.key === "Tab" && this.options.contain !== false) {
      const focusableElements = this.getFocusableElements();

      if (focusableElements.length === 0) return;

      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];
      const activeElement = document.activeElement;

      // Create focus loop
      if (!event.shiftKey && activeElement === lastElement) {
        firstElement.focus();
        event.preventDefault();
      } else if (event.shiftKey && activeElement === firstElement) {
        lastElement.focus();
        event.preventDefault();
      }
    }
  }

  /**
   * The visible focusable elements within the trap, in document order
   */
  getFocusableElements() {
    return Array.from(
      this.element.querySelectorAll(this.options.focusableSelector),
    ).filter(isVisible);
  }

  /**
   * Clean up all references when no longer needed
   */
  destroy() {
    this.deactivate();
    this.element = null;
    this.options = null;
    this.previouslyFocused = null;
  }
}

export default FocusTrap;
