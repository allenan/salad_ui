// saladui/core/click-outside.js
/**
 * ClickOutsideMonitor utility for SaladUI components
 * Detects clicks outside of specified elements and triggers a callback.
 *
 * Content portaled out of a monitored element (a dropdown menu or select
 * opened inside a popover or dialog, moved to <body> with `Portal.move()`)
 * counts as inside it, as Radix's DismissableLayer treats its portaled
 * children: picking a menu item does not dismiss the popover it sits in.
 */
import Portal from "./portal.js";

function logicallyContains(container, target) {
  for (
    let node = target;
    node;
    node = Portal.originalParent(node) || node.parentNode
  ) {
    if (node === container) return true;
  }
  return false;
}

class ClickOutsideMonitor {
  /**
   * Create a click outside monitor
   *
   * @param {HTMLElement|HTMLElement[]} elements - Element(s) to monitor clicks outside of
   * @param {Function} callback - Function to call when click outside is detected
   * @param {Object} options - Additional options
   */
  constructor(elements, callback, options = {}) {
    // Normalize elements to an array
    this.elements = Array.isArray(elements) ? elements : [elements];
    this.callback = callback;
    this.options = {
      // Whether to also monitor touchend events (for mobile)
      trackTouch: true,
      // Optional filter function to determine if a click should trigger the callback
      filter: null,
      ...options,
    };

    this.active = false;

    // Bind methods to maintain correct this context
    this.handleClick = this.handleClick.bind(this);
    this.handleTouchEnd = this.handleTouchEnd.bind(this);
  }

  /**
   * Start monitoring clicks outside the element(s)
   */
  start() {
    if (this.active) return;

    // Add document-level event listeners
    document.addEventListener("click", this.handleClick);
    if (this.options.trackTouch) {
      document.addEventListener("touchend", this.handleTouchEnd);
    }

    this.active = true;
  }

  /**
   * Stop monitoring clicks
   */
  stop() {
    if (!this.active) return;

    // Remove document-level event listeners
    document.removeEventListener("click", this.handleClick);
    if (this.options.trackTouch) {
      document.removeEventListener("touchend", this.handleTouchEnd);
    }

    this.active = false;
  }

  /**
   * Handle click events
   */
  handleClick(event) {
    this.checkOutsideClick(event);
  }

  /**
   * Handle touchend events
   */
  handleTouchEnd(event) {
    this.checkOutsideClick(event);
  }

  /**
   * Check if click/touch was outside monitored elements
   */
  checkOutsideClick(event) {
    // Skip if not active or no callback
    if (!this.active || !this.callback) return;

    // Apply custom filter if provided
    if (this.options.filter && !this.options.filter(event)) {
      return;
    }

    // Get the event target
    const target = event.target;

    // Check if click was outside all monitored elements
    const isOutside = !this.elements.some((element) => {
      return element && logicallyContains(element, target);
    });

    // If click was outside, call the callback
    if (isOutside) {
      this.callback(event);
    }
  }

  /**
   * Update the monitored elements
   */
  updateElements(elements) {
    this.elements = Array.isArray(elements) ? elements : [elements];
  }

  /**
   * Clean up all references
   */
  destroy() {
    this.stop();
    this.elements = null;
    this.callback = null;
    this.options = null;
  }
}

export default ClickOutsideMonitor;
