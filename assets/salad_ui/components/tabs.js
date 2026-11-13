// saladui/components/tabs.js
import Component, { assignId } from "../core/component.js";
import SaladUI from "../index.js";
import { CollectionRegistry, Selection } from "../core/collection.js";

class TabsComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    // Initialize core properties
    this.list = this.getPart("list");
    this.triggers = this.getAllParts("trigger");
    this.contents = this.getAllParts("content");

    // Set keyboard navigation defaults
    this.config.preventDefaultKeys = [
      "ArrowLeft",
      "ArrowRight",
      "ArrowUp",
      "ArrowDown",
      "Home",
      "End",
      "Enter",
      " ",
    ];

    // Initialize tabs
    this.initialize();
  }

  initialize(value = this.options.value) {
    // Initialize registry and selection state for tabs
    this.registry = new CollectionRegistry({
      getItemValue: (item) => item.getAttribute("data-value"),
      isItemDisabled: (item) => item.getAttribute("data-disabled") === "true",
    });
    this.selection = new Selection(this.registry, {
      type: "single",
      defaultValue: this.options.defaultValue,
      value,
    });

    // Register triggers with the registry
    this.triggers.forEach((trigger) => {
      const collectionItem = this.registry.add(trigger);
      this.selection.initializeItem(collectionItem);
    });

    // Setup accessibility attributes
    this.setupAriaAttributes();

    this.ensureValidSelection();

    // Initial UI update
    this.updateActiveTab();
  }

  /**
   * A LiveView patch puts back the server-rendered markup: every trigger and
   * panel inactive, the panels `hidden`, no ids or ARIA. Rebuilding would
   * jump back to the server's tab. Keep the tab the user chose and re-apply
   * it, unless the options or event mappings changed; a new server `value`
   * selects that tab.
   */
  skipReinitialize(el) {
    if (!this.sameConfig(el, ["value"])) return false;

    const current = this.selection.getValue();
    this.refreshParts();
    this.list = this.getPart("list");
    this.triggers = this.getAllParts("trigger");
    this.contents = this.getAllParts("content");

    const changed = this.adoptOptions(el, ["value"]);
    this.updateUI();
    this.initialize(changed.includes("value") ? this.options.value : current);
    this.restoreFocus();
    return true;
  }

  // Triggers and panels get client ids; drop them so the patch keeps those
  // elements (and a focused field in a panel) instead of replacing them.
  // Should the server still replace the focused trigger, remember which tab
  // had focus so skipReinitialize() can hand it to the replacement.
  beforeUpdate() {
    const active = document.activeElement;
    this.focusedValue = this.triggers.includes(active)
      ? active.getAttribute("data-value")
      : null;
    this.clearGeneratedIds();
  }

  restoreFocus() {
    const value = this.focusedValue;
    this.focusedValue = null;
    if (value === null) return;

    const active = document.activeElement;
    if (active && active !== document.body && active.isConnected) return;
    this.triggers
      .find((trigger) => trigger.getAttribute("data-value") === value)
      ?.focus();
  }

  ensureValidSelection() {
    const selectedValue = this.selection.getValue();
    const selectedItem = selectedValue
      ? this.registry.getItemByValue(selectedValue)
      : null;

    if (selectedItem && !this.registry.isDisabled(selectedItem)) return;

    const firstTrigger = this.registry.getItem("first");
    if (firstTrigger) {
      this.selection.setValues(firstTrigger.value);
    } else {
      this.selection.values = [];
      this.selection.updateSelectedStates();
    }
  }

  /**
   * "vertical" or "horizontal" (default). Read from options because
   * getComponentConfig() runs inside the base constructor, before any
   * subclass fields exist.
   */
  getOrientation() {
    return this.options?.orientation === "vertical" ? "vertical" : "horizontal";
  }

  getComponentConfig() {
    // Like Radix, only the arrow keys on the tabs' axis move between tabs;
    // horizontal tabs follow the reading direction (mirrored under RTL).
    const vertical = this.getOrientation() === "vertical";
    const [prevKey, nextKey] = vertical
      ? ["ArrowUp", "ArrowDown"]
      : ["ArrowLeft", "ArrowRight"];
    const step = (physical) =>
      !vertical && this.isRtl()
        ? { prev: "next", next: "prev" }[physical]
        : physical;

    return {
      stateMachine: {
        idle: {
          transitions: { select: "idle" },
        },
      },
      events: {
        idle: {
          keyEventTarget: "list",
          keyMap: {
            [prevKey]: () => this.navigateTab(step("prev")),
            [nextKey]: () => this.navigateTab(step("next")),
            Home: () => this.navigateTab("first"),
            End: () => this.navigateTab("last"),
          },
          mouseMap: {
            trigger: { click: (event) => this.handleTriggerClick(event) },
          },
        },
      },
      ariaConfig: {
        list: {
          all: { role: "tablist", orientation: this.getOrientation() },
        },
        trigger: {
          // aria-controls is set with the ids in setupAriaAttributes().
          all: { role: "tab" },
        },
        content: {
          all: {
            role: "tabpanel",
            tabindex: "0",
          },
        },
      },
    };
  }

  // Link each tab and its panel by id, keeping ids the server rendered.
  setupAriaAttributes() {
    const valueOf = (el) => el.getAttribute("data-value");
    const ids = new Map(
      this.triggers.map((trigger) => [
        valueOf(trigger),
        assignId(trigger, `${this.el.id}-trigger-${valueOf(trigger)}`),
      ]),
    );

    this.contents.forEach((content) => {
      const value = valueOf(content);
      const id = assignId(content, `${this.el.id}-content-${value}`);
      const trigger = this.triggers.find((el) => valueOf(el) === value);
      trigger?.setAttribute("aria-controls", id);
      if (ids.has(value))
        content.setAttribute("aria-labelledby", ids.get(value));
    });
  }

  handleTriggerClick(event) {
    const trigger = event.currentTarget;
    if (trigger.getAttribute("data-disabled") === "true") return;

    this.selectTab(trigger.getAttribute("data-value"));
  }

  selectTab(value) {
    // Find the trigger item
    const triggerItem = this.registry.getItemByValue(value);
    if (
      !triggerItem ||
      this.registry.isDisabled(triggerItem) ||
      this.selection.isValueSelected(value)
    ) {
      return;
    }

    // Select the tab
    if (!this.selection.select(triggerItem)) return;
    this.updateActiveTab();

    // Focus the selected trigger
    triggerItem.instance.focus();

    // Emit event
    this.pushEvent("tab-changed", { value: value, tab: value });
  }

  updateActiveTab() {
    const selectedValue = this.selection.getValue();

    // Update triggers
    this.triggers.forEach((trigger) => {
      const value = trigger.getAttribute("data-value");
      const isActive = value === selectedValue;

      trigger.setAttribute("data-state", isActive ? "active" : "inactive");
      trigger.setAttribute("aria-selected", isActive.toString());
      trigger.tabIndex = isActive ? 0 : -1;
    });

    // Update content panels
    this.contents.forEach((content) => {
      const value = content.getAttribute("data-value");
      const isActive = value === selectedValue;

      content.setAttribute("data-state", isActive ? "active" : "inactive");
      content.hidden = !isActive;
    });
  }

  navigateTab(direction) {
    const currentItem = this.registry.getItemByValue(this.selection.getValue());

    const nextItem = this.registry.getItem(direction, currentItem);
    if (nextItem) this.selectTab(nextItem.value);
  }

  // Cleanup
  beforeDestroy() {
    this.registry = null;
    this.selection = null;
  }
}

// Register the component
SaladUI.register("tabs", TabsComponent);

export default TabsComponent;
