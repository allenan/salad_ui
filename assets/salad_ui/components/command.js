import Component from "../core/component.js";
import SaladUI from "../index.js";

/**
 * CommandComponent for SaladUI
 * Implements filtering, keyboard navigation, and selection for a command palette/list.
 */
class CommandComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext, ignoreItems: false });

    // Set default field state
    this.currentItemIdx = 0;

    // Core elements
    this.collectElements();

    // Bind event handlers
    this.input?.addEventListener("input", this.handleSearch);

    // Initial search/filter
    this.handleSearch();

    // Prevent default for navigation keys
    this.config.preventDefaultKeys = [
      "Enter",
      "Escape",
      "ArrowDown",
      "ArrowUp",
    ];
  }

  /**
   * A LiveView patch puts back the server-rendered markup: every item, group
   * and separator visible again and the highlight reset, even though the
   * input still holds the query (LiveView leaves a focused input alone).
   * Rebuilding would lose the highlighted item. Keep the instance, re-read
   * the items (the server may have sent new ones) and filter them again,
   * unless the options or event mappings changed.
   */
  skipReinitialize(el) {
    if (!this.sameConfig(el)) return false;

    const highlighted = this.selectableItems?.[this.currentItemIdx];
    const highlightedValue = highlighted?.getAttribute("data-value");
    const input = this.input;

    this.refreshParts();
    this.collectElements();
    if (this.input !== input) {
      input?.removeEventListener("input", this.handleSearch);
      this.input?.addEventListener("input", this.handleSearch);
    }

    this.handleSearch();

    // Keep the highlight on the same item: the same element, or one with the
    // same value when the server replaced it.
    const index = this.selectableItems.findIndex(
      (item) =>
        item === highlighted ||
        (highlightedValue != null &&
          item.getAttribute("data-value") === highlightedValue),
    );
    if (index > 0) this.focusItem(index);

    return true;
  }

  collectElements() {
    this.input = this.getPart("input");
    this.list = this.getPart("list");
    this.empty = this.getPart("empty");
    this.groups = this.getAllParts("group");
    this.separators = this.getAllParts("separator");
    this.items = this.getAllParts("item");
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: { transitions: {} },
      },
      events: {
        idle: {
          keyMap: {
            Enter: "selectItem",
            ArrowDown: "focusNextItem",
            ArrowUp: "focusPrevItem",
            Escape: "blurInput",
          },
        },
      },
    };
  }

  // Focus item by index, wrap around if needed
  focusItem(index) {
    if (!this.selectableItems?.length) {
      this.currentItemIdx = -1;
      this.items.forEach((item) => {
        item.setAttribute("data-selected", "false");
        item.setAttribute("aria-selected", "false");
      });
      return;
    }

    // Wrap index
    if (index < 0) index = this.selectableItems.length - 1;
    if (index >= this.selectableItems.length) index = 0;

    this.currentItemIdx = index;

    // Deselect all
    this.items.forEach((item) => {
      item.setAttribute("data-selected", "false");
      item.setAttribute("aria-selected", "false");
    });

    // Select current
    const selectedItem = this.selectableItems[index];
    selectedItem.setAttribute("data-selected", "true");
    selectedItem.setAttribute("aria-selected", "true");
  }

  focusNextItem = () => this.focusItem(this.currentItemIdx + 1);
  focusPrevItem = () => this.focusItem(this.currentItemIdx - 1);

  blurInput = () => this.input?.blur();

  selectItem = () => {
    if (this.currentItemIdx === -1) return;
    const item = this.selectableItems[this.currentItemIdx];
    if (!item) return;

    item.click();
  };

  // Handle search/filtering
  handleSearch = () => {
    const query = this.input?.value.trim().toLowerCase() || "";

    // Filter items
    this.items.forEach((item) => {
      const text = item.textContent.trim().toLowerCase();
      const visible = query === "" || text.includes(query);
      item.setAttribute("data-visible", visible ? "true" : "false");
    });

    this.visibleItems = this.items.filter(
      (el) => el.getAttribute("data-visible") === "true",
    );

    this.selectableItems = this.visibleItems.filter(
      (el) => !el.hasAttribute("disabled"),
    );

    this.groups.forEach((group) => {
      const visibleOptions = group.querySelectorAll("[data-visible='true']");
      group.setAttribute(
        "data-visible",
        visibleOptions.length > 0 ? "true" : "false",
      );
    });

    // Like cmdk, separators only make sense between unfiltered groups.
    this.separators.forEach((separator) => {
      const visible = query === "" || separator.dataset.alwaysRender === "true";
      separator.setAttribute("data-visible", visible ? "true" : "false");
    });

    this.focusItem(0);

    const noItems = this.visibleItems.length === 0;

    if (noItems) {
      this.empty?.setAttribute("data-visible", "true");
    } else {
      this.empty?.setAttribute("data-visible", "false");
    }
  };

  beforeDestroy() {
    this.input?.removeEventListener("input", this.handleSearch);
  }
}

// Register the component
SaladUI.register("command", CommandComponent);

export default CommandComponent;
