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
      ...options,
    };

    this.previouslyFocused = null;
    this.active = false;

    // Bind methods that will be used as event handlers
    this.handleKeyDown = this.handleKeyDown.bind(this);
  }

  /**
   * Activate the focus trap
   */
  activate() {
    if (this.active) return;

    // Store currently focused element to restore later
    this.previouslyFocused = document.activeElement;
    this.active = true;

    // Set up event listener for keyboard navigation
    this.element.addEventListener("keydown", this.handleKeyDown);

    // Focus the first focusable element or the element itself
    this.setInitialFocus();
  }

  /**
   * Deactivate the focus trap and restore previous focus
   */
  deactivate() {
    if (!this.active) return;

    // Remove event listeners
    this.element.removeEventListener("keydown", this.handleKeyDown);

    const previouslyFocused = this.previouslyFocused;
    const container = this.element;
    const fallback = this.options.returnFocus;
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

    if (
      this.isRestorable(previouslyFocused) &&
      !this.options.preferReturnFocus
    ) {
      // Restored even when the opener is scrolled out of view, as Radix does;
      // otherwise focus would fall to <body>.
      setTimeout(() => {
        if (
          typeof document === "undefined" ||
          !document.body.contains(previouslyFocused)
        ) {
          return;
        }
        if (focusLost()) previouslyFocused.focus();
      }, 0);
    } else if (fallback) {
      // Nothing was focused at open (a dialog the server opened), or the app
      // named a target: go to the fallback.
      setTimeout(() => {
        if (typeof document === "undefined") return;
        const target = focusTarget(
          typeof fallback === "function" ? fallback() : fallback,
          selector,
        );
        if (target && focusLost()) target.focus();
      }, 0);
    }

    this.previouslyFocused = null;
    this.active = false;
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
        // Look for an element with autofocus attribute first
        const autoFocusEl = this.element.querySelector("[autofocus]");
        const initialFocusEl = autoFocusEl || focusableElements[0];
        initialFocusEl.focus();
      } else {
        // If no focusable elements, make the element itself focusable
        this.element.setAttribute("tabindex", "-1");
        this.element.focus();
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
   * Get all focusable elements within the trap
   */
  getFocusableElements() {
    return Array.from(
      this.element.querySelectorAll(this.options.focusableSelector),
    );
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
