// saladui/core/portal.js
import { getDirection } from "./direction.js";

/**
 * Portal utility for SaladUI components
 * Manages moving elements to a different DOM context (usually body)
 * to avoid z-index and overflow issues
 */
class Portal {
  // Static storage for element metadata
  static portalRegistry = new WeakMap();
  // Elements currently moved out, so modal layers can find what was
  // portaled out of them (see modal-layer.js).
  static portaled = new Set();

  /**
   * Move an element to a portal container
   *
   * @param {HTMLElement} element - Element to move to the portal
   * @param {HTMLElement} container - Container to move the element to (default: document.body)
   * @returns {boolean} Success status
   */
  static move(element, container = document.body) {
    if (!element) return false;

    // A portaled element leaves the subtree it inherited `dir` from (e.g. a
    // `direction_provider/1`), so carry its direction along as an attribute
    // when the portal container reads the other way.
    const dir = getDirection(element);
    const addedDir =
      !element.hasAttribute("dir") && dir !== getDirection(container);

    // Store original information for restoration
    const originalData = {
      parent: element.parentElement,
      addedDir,
      styles: {
        position: element.style.position,
        top: element.style.top,
        left: element.style.left,
        zIndex: element.style.zIndex,
        margin: element.style.margin,
        transform: element.style.transform,
        pointerEvents: element.style.pointerEvents,
      },
      inPortal: true,
    };

    // Store the metadata in our registry
    this.portalRegistry.set(element, originalData);
    this.portaled.add(element);

    // Move the element to the portal container
    container.appendChild(element);
    if (addedDir) element.setAttribute("dir", dir);

    // Apply portal styles
    element.style.position = "absolute";
    element.style.zIndex = "9999";

    return true;
  }

  /**
   * Restore an element from portal to its original position
   *
   * @param {HTMLElement} element - Element to restore
   * @returns {boolean} Success status
   */
  static restore(element) {
    if (!element) return false;

    // Get the original data from our registry
    const originalData = this.portalRegistry.get(element);

    if (!originalData || !originalData.parent) {
      return false;
    }

    try {
      // Move back to original parent
      originalData.parent.appendChild(element);
      if (originalData.addedDir) {
        element.removeAttribute("dir");
        originalData.addedDir = false;
      }

      // Restore original styles
      const styles = originalData.styles;
      element.style.position = styles.position || "";
      element.style.top = styles.top || "";
      element.style.left = styles.left || "";
      element.style.zIndex = styles.zIndex || "";
      element.style.margin = styles.margin || "";
      element.style.transform = styles.transform || "";
      element.style.pointerEvents = styles.pointerEvents || "";

      // Update portal state
      originalData.inPortal = false;
      this.portaled.delete(element);

      return true;
    } catch (error) {
      console.warn("SaladUI Portal: Failed to restore element", error);
      return false;
    }
  }

  /**
   * Check if an element is currently in a portal
   *
   * @param {HTMLElement} element - Element to check
   * @returns {boolean} Whether the element is in a portal
   */
  static isInPortal(element) {
    if (!element) return false;
    const data = this.portalRegistry.get(element);
    return data?.inPortal === true;
  }

  /**
   * The parent a portaled element was moved out of, or null when it is not
   * in a portal.
   *
   * @param {HTMLElement} element - Element to look up
   * @returns {HTMLElement|null} Its original parent
   */
  static originalParent(element) {
    if (!element) return null;
    const data = this.portalRegistry.get(element);
    return data?.inPortal ? data.parent : null;
  }

  /**
   * Every element currently in a portal and still in the document.
   *
   * @returns {HTMLElement[]} Portaled elements
   */
  static portaledElements() {
    const elements = [];
    for (const element of this.portaled) {
      // Restored, or removed for good (a destroyed positioned element).
      if (this.isInPortal(element) && element.isConnected) {
        elements.push(element);
      } else {
        this.portaled.delete(element);
      }
    }
    return elements;
  }

  /**
   * Setup scroll event passthrough for a portal element
   * Makes the portal element transparent to pointer events except for interactive elements
   *
   * @param {HTMLElement} element - Portal element to set up scroll passthrough for
   */
  static setupScrollPassthrough(element) {
    if (!element) return;

    // Get original data from registry to ensure styles are properly tracked
    const originalData = this.portalRegistry.get(element);
    if (originalData) {
      originalData.styles.pointerEvents = element.style.pointerEvents;
    }

    // Make the portal element transparent to pointer events
    element.style.pointerEvents = "none";

    Portal.updateScrollableContainer(element, "auto");
  }

  static updateScrollableContainer(parentElement, pointerEvent = "") {
    // Check if the current element is scrollable
    function isScrollable(element) {
      const style = window.getComputedStyle(element);
      const overflowY = style.overflowY;
      const overflowX = style.overflowX;

      const isScrollableY = element.scrollHeight > element.clientHeight;
      const isScrollableX = element.scrollWidth > element.clientWidth;

      return (
        ((overflowY === "auto" ||
          overflowY === "scroll" ||
          overflowY === "overlay") &&
          isScrollableY) ||
        ((overflowX === "auto" ||
          overflowX === "scroll" ||
          overflowX === "overlay") &&
          isScrollableX)
      );
    }

    // Recursive function to traverse DOM tree
    function traverse(element) {
      // Check if current element is scrollable
      if (isScrollable(element)) {
        // Set pointer-events to auto
        element.style.pointerEvents = pointerEvent;
        // Stop traversing this branch
        return;
      }

      // Process child elements if current element isn't scrollable
      for (let i = 0; i < element.children.length; i++) {
        traverse(element.children[i]);
      }
    }

    // Start traversal from parent
    traverse(parentElement);

    // No return value as requested
  }

  /**
   * Clean up scroll passthrough setup
   *
   * @param {HTMLElement} element - Element to clean up
   */
  static cleanupScrollPassthrough(element) {
    if (!element) return;

    // Get the original data from registry if available
    const originalData = this.portalRegistry.get(element);
    const originalPointerEvents = originalData?.styles?.pointerEvents || "";

    // Restore pointer-events on the element
    element.style.pointerEvents = originalPointerEvents;

    // Reset pointer-events on all children that might have been modified
    Portal.updateScrollableContainer(element, "");
  }
}

export default Portal;
