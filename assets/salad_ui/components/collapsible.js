// saladui/components/collapsible.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

class CollapsibleComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    // Initialize core properties
    this.trigger = this.getPart("trigger");
    this.content = this.getPart("content");

    // Set keyboard navigation defaults
    this.config.preventDefaultKeys = ["Enter", " "];
  }

  /**
   * A LiveView patch puts back the server-rendered markup (the content
   * `hidden`, the server's `data-state`) and, since the trigger and content
   * get client-assigned ids, may replace them outright. Rebuilding would
   * close an item the user opened. Keep the instance and re-apply its state,
   * unless the options or event mappings changed; a new server `open` value
   * is applied as an open/close.
   */
  skipReinitialize(el) {
    if (!this.sameConfig(el, ["open"])) return false;

    this.refreshParts();
    this.trigger = this.getPart("trigger");
    this.content = this.getPart("content");

    const changed = this.adoptOptions(el, ["open"]);
    this.reapplyState();

    const open = this.options.open === true;
    if (changed.includes("open") && open !== (this.state === "open")) {
      this.transition(open ? "open" : "close");
    }

    return true;
  }

  getComponentConfig() {
    return {
      stateMachine: {
        closed: {
          enter: "onClosedEnter",
          transitions: {
            toggle: "open",
            open: "open",
          },
        },
        open: {
          enter: "onOpenEnter",
          transitions: {
            toggle: "closed",
            close: "closed",
          },
        },
      },
      events: {
        closed: {
          keyEventTarget: "trigger",
          keyMap: {
            Enter: "handleTriggerActivation",
            " ": "handleTriggerActivation",
          },
        },
        open: {
          keyEventTarget: "trigger",
          keyMap: {
            Enter: "handleTriggerActivation",
            " ": "handleTriggerActivation",
          },
        },
      },
      hiddenConfig: {
        closed: {
          content: true,
        },
        open: {
          content: false,
        },
      },
      ariaConfig: {
        trigger: {
          all: {
            controls: () => this.getPartId("content"),
          },
          open: {
            expanded: "true",
          },
          closed: {
            expanded: "false",
          },
        },
        content: {
          all: {
            labelledby: () => this.getPartId("trigger"),
            role: "region",
          },
        },
      },
    };
  }

  // The "closed" and "open" states each register their own keydown listener
  // on the trigger (identical keyMap), so a single Enter/Space keypress hits
  // both listeners in the same dispatch: the first one's transition flips
  // the state synchronously, which makes the second listener's state guard
  // match too, immediately re-firing and undoing the toggle. Stamp the
  // native event so activation only actually runs once per keypress.
  handleTriggerActivation(event) {
    if (event.__saladuiHandled) return;
    event.__saladuiHandled = true;

    this.transition("toggle", { originalEvent: event, target: this.trigger });
  }

  // State handlers
  onOpenEnter() {
    this.pushEvent("open");
  }

  onClosedEnter() {
    this.pushEvent("close");
  }
}

// Register the component
SaladUI.register("collapsible", CollapsibleComponent);

export default CollapsibleComponent;
