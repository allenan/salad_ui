// saladui/components/combobox.js
import Component from "../core/component.js";
import { isRtl } from "../core/direction.js";
import SaladUI from "../index.js";
import PositionedElement from "../core/positioned-element.js";

// Matches the `var(--salad-combobox-available-height, 24rem)` caps on
// combobox_content and combobox_list.
const AVAILABLE_HEIGHT_VAR = "--salad-combobox-available-height";
const REFERENCE_WIDTH_VAR = "--salad-reference-width";
// sideOffset plus a little breathing room from the window edge.
const COLLISION_MARGIN = 12;

// Clicks on these inside the input group or the chips box keep their own
// behaviour instead of focusing the input.
const INTERACTIVE =
  "button, a[href], input, select, textarea, label, [contenteditable]";

const isItemDisabled = (item) => {
  const dataDisabled = item.getAttribute("data-disabled");
  return (
    item.hasAttribute("disabled") ||
    item.getAttribute("aria-disabled") === "true" ||
    (dataDisabled !== null && dataDisabled !== "false")
  );
};

const sameList = (a, b) =>
  a.length === b.length && a.every((value, index) => value === b[index]);

/**
 * Combobox: a text input that filters a listbox (WAI-ARIA combobox pattern).
 *
 * Focus stays in the input while the list is open; the highlighted option is
 * exposed through `aria-activedescendant`. The selection, the query and the
 * highlight live in this instance and are re-applied to the DOM by render(),
 * so a LiveView patch that re-renders the items (server filtering) keeps the
 * popup open: skipReinitialize() refreshes this instance instead of letting
 * the hook rebuild it.
 *
 * Supports single selection (the input shows the selected label), multiple
 * selection rendered as chips (combobox_chips), and a popup mode where a
 * standalone trigger opens the content and the input lives inside it.
 */
class ComboboxComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.labels = new Map();
    this.query = "";
    this.highlighted = null;
    this.pendingHighlight = null;
    this.suppressInput = false;
    this.readOptions();
    this.values = this.normalizeValue(this.options.value);

    this.onClick = this.onClick.bind(this);
    this.onMouseDown = this.onMouseDown.bind(this);
    this.onMouseMove = this.onMouseMove.bind(this);
    this.onInput = this.onInput.bind(this);
    this.onKeyDown = this.onKeyDown.bind(this);
    this.onFocusOut = this.onFocusOut.bind(this);

    this.content = this.getPart("content");
    this.learnChipLabels();
    this.render();
    this.initInputText();
    this.syncHiddenInputs();
  }

  readOptions() {
    this.multiple = !!this.options.multiple;
    this.filterEnabled = this.options.filter !== false;
    this.autoHighlight = !!this.options.autoHighlight;
  }

  normalizeValue(value) {
    if (this.multiple) {
      if (value === null || value === undefined) return [];
      return (Array.isArray(value) ? value : [value]).map(String);
    }
    if (Array.isArray(value)) value = value[0];
    if (value === null || value === undefined || value === "") return [];
    return [String(value)];
  }

  getComponentConfig() {
    const expanded = {
      open: { expanded: "true" },
      closed: { expanded: "false" },
    };

    return {
      stateMachine: {
        closed: {
          enter: "onClosedEnter",
          transitions: { open: "open", toggle: "open" },
        },
        open: {
          enter: "onOpenEnter",
          exit: "onOpenExit",
          transitions: { close: "closed", toggle: "closed" },
        },
      },
      hiddenConfig: {
        closed: { content: true },
        open: { content: false },
      },
      ariaConfig: {
        input: {
          all: { role: "combobox", autocomplete: "list", haspopup: "listbox" },
          ...expanded,
        },
        trigger: expanded,
        list: { all: { role: "listbox" } },
      },
    };
  }

  // ---- Parts ---------------------------------------------------------------

  /** Elements matching `selector` that belong to this combobox. */
  own(selector) {
    if (!this.el) return [];
    return Array.from(this.el.querySelectorAll(selector)).filter(
      (node) => node.closest("[data-component]") === this.el,
    );
  }

  inContent(node) {
    return !!(node && this.content && this.content.contains(node));
  }

  getItems() {
    return this.own("[data-part='item']");
  }

  getInputs() {
    return this.own("[data-part='input']");
  }

  /** The input outside the content (the input group or the chips input). */
  mainInput() {
    return this.getInputs().find((input) => !this.inContent(input)) || null;
  }

  /** The input inside the content, in popup mode. */
  contentInput() {
    return this.getInputs().find((input) => this.inContent(input)) || null;
  }

  activeInput() {
    return this.mainInput() || this.contentInput();
  }

  standaloneTrigger() {
    return (
      this.own("[data-part='trigger']").find(
        (trigger) =>
          !trigger.closest("[data-slot='input-group']") &&
          !this.inContent(trigger),
      ) || null
    );
  }

  chipsBox() {
    return (
      this.own("[data-part='chips']").find((box) => !this.inContent(box)) ||
      null
    );
  }

  anchor() {
    const chips = this.chipsBox();
    if (chips) return chips;

    const input = this.mainInput();
    const group = input?.closest("[data-slot='input-group']");
    if (group && this.el.contains(group)) return group;

    return this.standaloneTrigger() || input || this.el;
  }

  isDisabled() {
    if (this.options?.disabled) return true;
    const control = this.mainInput() || this.standaloneTrigger();
    return !!control?.disabled;
  }

  itemLabel(item) {
    const label = item.getAttribute("data-label");
    if (label !== null && label !== "") return label;

    const clone = item.cloneNode(true);
    clone
      .querySelectorAll("[data-part='item-indicator']")
      .forEach((node) => node.remove());
    return clone.textContent.replace(/\s+/g, " ").trim();
  }

  labelFor(value) {
    return this.labels.get(value) ?? value;
  }

  learnChipLabels() {
    this.own("[data-part='chip']").forEach((chip) => {
      const value = chip.dataset.value;
      const label = chip
        .querySelector("[data-part='chip-label']")
        ?.textContent.trim();
      if (value && label && !this.labels.has(value)) {
        this.labels.set(value, label);
      }
    });
  }

  // ---- Events --------------------------------------------------------------

  setupComponentEvents() {
    super.setupComponentEvents();

    this.el.addEventListener("click", this.onClick);
    this.el.addEventListener("mousedown", this.onMouseDown);
    this.el.addEventListener("mousemove", this.onMouseMove);
    this.el.addEventListener("input", this.onInput);
    this.el.addEventListener("keydown", this.onKeyDown);
    this.el.addEventListener("focusout", this.onFocusOut);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();

    this.el.removeEventListener("click", this.onClick);
    this.el.removeEventListener("mousedown", this.onMouseDown);
    this.el.removeEventListener("mousemove", this.onMouseMove);
    this.el.removeEventListener("input", this.onInput);
    this.el.removeEventListener("keydown", this.onKeyDown);
    this.el.removeEventListener("focusout", this.onFocusOut);
  }

  ownTarget(event) {
    const target = event.target;
    if (!(target instanceof Element)) return null;
    if (target.closest("[data-component]") !== this.el) return null;
    return target;
  }

  onClick(event) {
    const target = this.ownTarget(event);
    if (!target || this.isDisabled()) return;

    const chipRemove = target.closest("[data-part='chip-remove']");
    if (chipRemove) {
      const chip = chipRemove.closest("[data-part='chip']");
      if (chip) this.removeValue(chip.dataset.value);
      this.focusInput();
      return;
    }

    if (target.closest("[data-part='clear']")) {
      this.clear();
      this.focusInput();
      return;
    }

    if (target.closest("[data-part='trigger']")) {
      this.onTriggerClick();
      return;
    }

    const item = target.closest("[data-part='item']");
    if (item && this.inContent(item)) {
      if (!isItemDisabled(item)) this.selectValue(item.dataset.value);
      return;
    }

    const input = target.closest("[data-part='input']");
    if (input) {
      if (this.state !== "open" && !this.inContent(input)) this.open();
      return;
    }

    // Like InputGroupAddon (and Base UI's Chips): clicking the box focuses
    // the input.
    const box = target.closest(
      "[data-part='chips'], [data-slot='input-group']",
    );
    if (box && !this.inContent(box) && !target.closest(INTERACTIVE)) {
      this.focusInput();
    }
  }

  onTriggerClick() {
    if (this.state === "open") {
      this.close();
      if (!this.standaloneTrigger()) this.focusInput();
      return;
    }

    this.open();
    // The popup-mode input is focused in onOpenEnter.
    if (this.mainInput()) this.focusInput();
  }

  // Keep focus in the input while clicking items, chips and the input's own
  // buttons, so the list does not close on focusout.
  onMouseDown(event) {
    const target = this.ownTarget(event);
    if (!target || target.closest("input, textarea")) return;

    const keepsFocus =
      this.inContent(target) ||
      target.closest("[data-part='clear'], [data-part='chip-remove']") ||
      (target.closest("[data-part='trigger']") && this.mainInput());

    if (keepsFocus) event.preventDefault();
  }

  onMouseMove(event) {
    const target = this.ownTarget(event);
    if (!target || this.state !== "open") return;

    const item = target.closest("[data-part='item']");
    if (!item || !this.inContent(item) || isItemDisabled(item)) return;

    const value = item.dataset.value;
    if (value === this.highlighted) return;

    this.highlighted = value;
    this.render();
  }

  onInput(event) {
    if (this.suppressInput) return;

    const target = this.ownTarget(event);
    if (!target || target.dataset.part !== "input") return;

    this.query = target.value;
    this.highlighted = null;

    if (this.state !== "open") {
      this.open({ keepQuery: true });
    } else {
      this.render();
    }
  }

  onKeyDown(event) {
    const target = this.ownTarget(event);
    if (!target || this.isDisabled()) return;

    if (target.dataset.part === "input") {
      this.onInputKeyDown(event, target);
    } else if (target.dataset.part === "chip") {
      this.onChipKeyDown(event, target);
    } else if (
      (event.key === "ArrowDown" || event.key === "ArrowUp") &&
      target.closest("[data-part='trigger']") &&
      target.closest("[data-part='trigger']") === this.standaloneTrigger()
    ) {
      event.preventDefault();
      if (this.state !== "open") {
        this.open({ highlight: event.key === "ArrowUp" ? "last" : "first" });
      }
    }
  }

  onInputKeyDown(event, input) {
    const open = this.state === "open";

    switch (event.key) {
      case "ArrowDown":
      case "ArrowUp": {
        event.preventDefault();
        const forward = event.key === "ArrowDown";
        if (event.altKey) {
          // Alt+ArrowDown shows the list without highlighting; Alt+ArrowUp
          // hides it (WAI-ARIA combobox pattern).
          if (forward && !open) this.open();
          if (!forward && open) this.close();
        } else if (!open) {
          this.open({ highlight: forward ? "first" : "last" });
        } else {
          this.moveHighlight(forward ? 1 : -1);
        }
        break;
      }
      case "ArrowLeft":
      case "ArrowRight": {
        // From the start of the chips input, the "back" arrow moves focus
        // onto the last chip.
        if (
          event.key === this.backKey(input) &&
          this.multiple &&
          input.selectionStart === 0 &&
          input.selectionEnd === 0
        ) {
          const chips = this.chipElements();
          if (chips.length > 0) {
            event.preventDefault();
            chips[chips.length - 1].focus({ preventScroll: true });
          }
        }
        break;
      }
      case "Enter": {
        if (event.isComposing) return;
        if (!open || this.highlighted === null) return;
        event.preventDefault();
        this.selectValue(this.highlighted);
        break;
      }
      case "Escape": {
        if (!open) return;
        event.preventDefault();
        event.stopPropagation();
        this.close();
        break;
      }
      case "Tab": {
        if (open) this.close();
        break;
      }
      case "Backspace": {
        if (this.multiple && input.value === "" && this.values.length > 0) {
          this.removeValue(this.values[this.values.length - 1]);
        }
        break;
      }
    }
  }

  /**
   * Keyboard on a focused chip: the arrows move between the chips and back to
   * the input, Backspace/Delete remove the chip, Escape and typing return to
   * the input.
   */
  onChipKeyDown(event, chip) {
    const chips = this.chipElements();
    const index = chips.indexOf(chip);
    if (index === -1) return;

    const input = this.mainInput();
    const back = this.backKey(chip);
    const forward = back === "ArrowLeft" ? "ArrowRight" : "ArrowLeft";
    const focus = (node) => node?.focus({ preventScroll: true });

    switch (event.key) {
      case back:
        event.preventDefault();
        focus(chips[index - 1] || chip);
        break;
      case forward:
        event.preventDefault();
        focus(chips[index + 1] || input);
        break;
      case "Backspace":
      case "Delete": {
        event.preventDefault();
        const neighbour =
          event.key === "Backspace"
            ? chips[index - 1] || chips[index + 1]
            : chips[index + 1];
        const neighbourValue = neighbour?.dataset.value;
        this.removeValue(chip.dataset.value);
        const next =
          neighbourValue !== undefined &&
          this.chipElements().find((c) => c.dataset.value === neighbourValue);
        focus(next || input);
        break;
      }
      case "Escape":
        event.preventDefault();
        event.stopPropagation();
        if (this.state === "open") this.close();
        focus(input);
        break;
      default:
        // Typing goes on in the input.
        if (
          event.key.length === 1 &&
          !event.ctrlKey &&
          !event.metaKey &&
          !event.altKey
        ) {
          focus(input);
        }
    }
  }

  /** The arrow key pointing towards the chips, by text direction. */
  backKey(node) {
    return isRtl(node) ? "ArrowRight" : "ArrowLeft";
  }

  chipElements() {
    const box = this.chipsBox();
    if (!box) return [];
    return Array.from(box.querySelectorAll("[data-part='chip']")).filter(
      (chip) => chip.closest("[data-component]") === this.el,
    );
  }

  onFocusOut(event) {
    if (this.state !== "open") return;

    // A null relatedTarget is a click on something unfocusable (handled by
    // the outside-click monitor) or the window losing focus: keep it open.
    const next = event.relatedTarget;
    if (!next || this.el.contains(next)) return;

    this.close();
  }

  focusInput() {
    const input = this.activeInput();
    if (input && document.activeElement !== input) {
      input.focus({ preventScroll: true });
    }
  }

  // ---- Commands ------------------------------------------------------------

  handleCommand(command, params = {}) {
    switch (command) {
      case "open":
        return this.open();
      case "close":
        return this.close();
      case "toggle":
        return this.state === "open" ? this.close() : this.open();
      case "clear":
        return this.clear();
      default:
        return super.handleCommand(command, params);
    }
  }

  open({ keepQuery = false, highlight = null } = {}) {
    if (this.isDisabled() || this.state === "open") return false;

    if (!keepQuery) this.query = "";
    this.pendingHighlight = highlight;
    return this.transition("open");
  }

  close() {
    if (this.state !== "open") return false;
    return this.transition("close");
  }

  // ---- State handlers ------------------------------------------------------

  onOpenEnter() {
    this.render();

    if (this.pendingHighlight) {
      this.highlightDefault(this.pendingHighlight);
      this.pendingHighlight = null;
    }

    this.ensurePositioned();
    this.reposition();
    this.positionedElement?.activate();
    this.reposition();
    this.scrollToHighlighted();

    // Popup mode: the search input lives inside the content.
    if (!this.mainInput()) {
      const input = this.contentInput();
      input?.focus({ preventScroll: true });
    }

    this.pushEvent("open");
  }

  onOpenExit() {
    this.positionedElement?.deactivate();
    this.highlighted = null;
    this.pendingHighlight = null;

    const main = this.mainInput();
    if (main) {
      this.setInputText(
        main,
        this.multiple || this.values.length === 0
          ? ""
          : this.labelFor(this.values[0]),
      );
    }

    const contentInput = this.contentInput();
    if (contentInput) {
      const hadFocus = contentInput === document.activeElement;
      this.setInputText(contentInput, "");
      if (hadFocus) {
        this.standaloneTrigger()?.focus({ preventScroll: true });
      }
    }

    this.render();
  }

  onClosedEnter() {
    this.query = "";
    this.render();
    this.pushEvent("close");
  }

  // ---- Selection -----------------------------------------------------------

  getValue() {
    return this.multiple ? [...this.values] : (this.values[0] ?? null);
  }

  selectValue(value) {
    if (value === undefined || value === null || this.isDisabled()) return;

    if (this.multiple) {
      this.values = this.values.includes(value)
        ? this.values.filter((v) => v !== value)
        : [...this.values, value];
      this.query = "";
      this.highlighted = value;
      const input = this.activeInput();
      if (input) this.setInputText(input, "");
    } else {
      if (this.values.length === 1 && this.values[0] === value) {
        // Picking the selected item again only closes the list.
        this.close();
        const input = this.mainInput();
        if (input) this.setInputText(input, this.labelFor(value));
        return;
      }
      this.values = [value];
    }

    this.commitValue();

    if (!this.multiple) {
      this.close();
      const input = this.mainInput();
      if (input) this.setInputText(input, this.labelFor(value));
    }
  }

  removeValue(value) {
    if (!this.values.includes(value)) return;

    this.values = this.values.filter((v) => v !== value);
    this.commitValue();
  }

  clear() {
    if (this.isDisabled()) return;

    const changed = this.values.length > 0;
    this.values = [];
    this.query = "";
    this.highlighted = null;
    this.getInputs().forEach((input) => this.setInputText(input, ""));

    if (changed) {
      this.commitValue();
    } else {
      this.render();
    }
  }

  commitValue() {
    this.render();
    this.syncHiddenInputs();
    this.dispatchFormEvents();
    this.pushEvent("value-changed", { value: this.getValue() });
  }

  /**
   * Set an input's text programmatically. With server filtering, clearing
   * the query also tells the server (through the form's phx-change), since
   * no `input` event would fire otherwise.
   */
  setInputText(input, text) {
    if (input.value === text) return;

    input.value = text;
    if (!this.filterEnabled && text === "") {
      this.suppressInput = true;
      try {
        input.dispatchEvent(new Event("input", { bubbles: true }));
      } finally {
        this.suppressInput = false;
      }
    }
  }

  initInputText() {
    const input = this.mainInput();
    if (!input || this.multiple || this.values.length === 0) return;
    if (input.value === "") input.value = this.labelFor(this.values[0]);
  }

  // ---- Highlight -----------------------------------------------------------

  navigableItems() {
    return this.getItems().filter(
      (item) => !item.hidden && !isItemDisabled(item),
    );
  }

  highlightDefault(which) {
    const items = this.navigableItems();
    const selected = items.find((item) =>
      this.values.includes(item.dataset.value),
    );
    const fallback = which === "last" ? items[items.length - 1] : items[0];
    const item = selected || fallback;
    this.highlighted = item ? item.dataset.value : null;
    this.render();
  }

  moveHighlight(step) {
    const items = this.navigableItems();
    if (items.length === 0) return;

    const index = items.findIndex(
      (item) => item.dataset.value === this.highlighted,
    );
    let next;
    if (index === -1) {
      next = step > 0 ? 0 : items.length - 1;
    } else {
      next = (index + step + items.length) % items.length;
    }

    this.highlighted = items[next].dataset.value;
    this.render();
    this.scrollToHighlighted();
  }

  scrollToHighlighted() {
    const item = this.getItems().find((i) =>
      i.hasAttribute("data-highlighted"),
    );
    if (item && typeof item.scrollIntoView === "function") {
      item.scrollIntoView({ block: "nearest" });
    }
  }

  // ---- Rendering -----------------------------------------------------------

  /** Re-apply the instance state to the DOM. Safe to call at any time. */
  render() {
    if (this.destroyed || !this.el) return;

    const query = this.filterEnabled ? this.query.trim().toLowerCase() : "";
    const items = this.getItems();
    const list = this.own("[data-part='list']")[0] || null;
    if (list && !list.id) list.id = `${this.el.id}-list`;

    let visibleCount = 0;
    items.forEach((item, index) => {
      const value = item.dataset.value ?? "";
      const label = this.itemLabel(item);
      this.labels.set(value, label);

      const visible = query === "" || label.toLowerCase().includes(query);
      item.hidden = !visible;
      if (visible) visibleCount += 1;

      if (!item.id) item.id = `${this.el.id}-option-${index}`;
      const selected = this.values.includes(value);
      item.setAttribute("aria-selected", selected ? "true" : "false");
      item.toggleAttribute("data-selected", selected);
      const indicator = item.querySelector("[data-part='item-indicator']");
      if (indicator) indicator.hidden = !selected;
    });

    this.renderGroups();
    this.renderSeparators(items);

    const empty = visibleCount === 0;
    this.content?.toggleAttribute("data-empty", empty);
    list?.toggleAttribute("data-empty", empty);

    this.renderHighlight(items, this.query.trim() !== "");
    this.renderControls(list);
    this.renderChips();
    this.renderValueDisplay();
  }

  renderGroups() {
    this.own("[data-part='group']").forEach((group, index) => {
      group.hidden = !group.querySelector("[data-part='item']:not([hidden])");

      const label = group.querySelector("[data-part='label']");
      if (label) {
        if (!label.id) label.id = `${this.el.id}-group-${index}-label`;
        group.setAttribute("aria-labelledby", label.id);
      }
    });
  }

  // A separator shows only between visible items, like cmdk's.
  renderSeparators(items) {
    const visible = items.filter((item) => !item.hidden);
    const FOLLOWING = Node.DOCUMENT_POSITION_FOLLOWING;
    const PRECEDING = Node.DOCUMENT_POSITION_PRECEDING;

    this.own("[data-part='separator']").forEach((separator) => {
      const before = visible.some(
        (item) => separator.compareDocumentPosition(item) & PRECEDING,
      );
      const after = visible.some(
        (item) => separator.compareDocumentPosition(item) & FOLLOWING,
      );
      separator.hidden = !(before && after);
    });
  }

  renderHighlight(items, hasQuery) {
    const navigable = items.filter(
      (item) => !item.hidden && !isItemDisabled(item),
    );

    if (
      this.highlighted !== null &&
      !navigable.some((item) => item.dataset.value === this.highlighted)
    ) {
      this.highlighted = null;
    }

    if (
      this.highlighted === null &&
      this.autoHighlight &&
      hasQuery &&
      this.state === "open" &&
      navigable.length > 0
    ) {
      this.highlighted = navigable[0].dataset.value;
    }

    let active = null;
    items.forEach((item) => {
      const on =
        this.state === "open" &&
        !item.hidden &&
        item.dataset.value === this.highlighted;
      item.toggleAttribute("data-highlighted", on);
      if (on && !active) active = item;
    });

    this.getInputs().forEach((input) => {
      if (active) {
        input.setAttribute("aria-activedescendant", active.id);
      } else {
        input.removeAttribute("aria-activedescendant");
      }
    });
  }

  renderControls(list) {
    const disabled = this.isDisabled();
    const rootDisabled = !!this.options.disabled;

    if (this.multiple) {
      list?.setAttribute("aria-multiselectable", "true");
    } else {
      list?.removeAttribute("aria-multiselectable");
    }

    this.getInputs().forEach((input) => {
      if (list) input.setAttribute("aria-controls", list.id);
      if (rootDisabled) input.disabled = true;
    });

    this.own("[data-part='trigger']").forEach((trigger) => {
      if (list) trigger.setAttribute("aria-controls", list.id);
      if (rootDisabled) trigger.disabled = true;
    });

    this.own("[data-part='clear']").forEach((clear) => {
      clear.hidden = this.values.length === 0;
      if (rootDisabled) clear.disabled = true;
    });

    this.own("[data-part='chip-remove']").forEach((button) => {
      button.disabled = disabled;
    });

    if (this.chipsBox()) {
      this.content?.setAttribute("data-chips", "true");
    } else {
      this.content?.removeAttribute("data-chips");
    }

    this.syncInvalidState();
  }

  /**
   * Mirror the root's `data-invalid` (a form field with errors) onto the
   * input as `aria-invalid`. An explicit `aria-invalid` on the input wins;
   * `data-invalid-synced` tells our own attribute apart from it.
   */
  syncInvalidState() {
    const input = this.mainInput() || this.standaloneTrigger();
    if (!input) return;

    const synced = input.hasAttribute("data-invalid-synced");
    if (input.hasAttribute("aria-invalid") && !synced) return;

    if (this.el.dataset.invalid === "true") {
      input.setAttribute("aria-invalid", "true");
      input.setAttribute("data-invalid-synced", "");
    } else if (synced) {
      input.removeAttribute("aria-invalid");
      input.removeAttribute("data-invalid-synced");
    }
  }

  /**
   * Chips mirror the selection. Chips already in the DOM (rendered by the
   * server, or by an earlier render) are kept when they match it; otherwise
   * they are rebuilt from the chip template in front of the input.
   */
  renderChips() {
    const box = this.chipsBox();
    if (!box) return;

    const existing = this.chipElements();
    const disabled = this.isDisabled();

    if (
      !sameList(
        existing.map((chip) => chip.dataset.value),
        this.values,
      )
    ) {
      existing.forEach((chip) => chip.remove());

      const template = box.querySelector("template[data-part='chip-template']");
      const input = box.querySelector("[data-part='input']");
      const reference = input && input.parentNode === box ? input : null;

      this.values.forEach((value) => {
        const chip = this.buildChip(template, value);
        box.insertBefore(chip, reference);
      });
    }

    // Focusable from the keyboard (see onChipKeyDown), not in the tab order.
    this.chipElements().forEach((chip) => {
      if (!chip.hasAttribute("tabindex")) chip.setAttribute("tabindex", "-1");
    });

    box.querySelectorAll("[data-part='chip-remove']").forEach((button) => {
      const chip = button.closest("[data-part='chip']");
      if (chip) {
        button.setAttribute(
          "aria-label",
          `Remove ${this.labelFor(chip.dataset.value)}`,
        );
      }
      button.disabled = disabled;
    });
  }

  buildChip(template, value) {
    const source = template?.content?.firstElementChild;
    const chip = source
      ? source.cloneNode(true)
      : document.createElement("div");

    if (!source) chip.setAttribute("data-part", "chip");
    chip.dataset.value = value;

    const label = chip.querySelector("[data-part='chip-label']") || chip;
    label.textContent = this.labelFor(value);
    return chip;
  }

  renderValueDisplay() {
    const hasValue = this.values.length > 0;
    const trigger = this.standaloneTrigger();
    trigger?.toggleAttribute("data-placeholder", !hasValue);

    this.own("[data-part='value']").forEach((display) => {
      const placeholder = display.getAttribute("data-placeholder") || "";
      const text = hasValue
        ? this.values.map((value) => this.labelFor(value)).join(", ")
        : placeholder;
      if (display.textContent !== text) display.textContent = text;
    });
  }

  // ---- Positioning ---------------------------------------------------------

  ensurePositioned() {
    if (!this.content) return;

    const anchor = this.anchor();
    if (this.positionedElement) {
      if (this.positionedElement.reference !== anchor) {
        this.positionedElement.updateReference(anchor);
      }
      return;
    }

    const data = this.content.dataset;
    this.positionedElement = new PositionedElement(this.content, anchor, {
      placement: data.side || "bottom",
      alignment: data.align || "start",
      sideOffset: parseInt(data.sideOffset || "6", 10),
      alignOffset: parseInt(data.alignOffset || "0", 10),
      flip: true,
      usePortal: false,
      trapFocus: false,
      onOutsideClick: (event) => {
        const target = event?.target;
        // Chips removed by this click are detached by now; they were inside.
        if (target && (!target.isConnected || this.el?.contains(target))) {
          return;
        }
        this.close();
      },
      onPosition: ({ placement }) => {
        this.content?.setAttribute("data-side", placement);
      },
    });
  }

  /**
   * Size the content to its anchor and cap its height at the room left in
   * the window, then place it. Also re-applied after a LiveView patch, which
   * strips these inline styles.
   */
  reposition() {
    if (!this.content || typeof window === "undefined") return;

    const anchor = this.positionedElement?.reference || this.anchor();
    this.content.style.setProperty(
      REFERENCE_WIDTH_VAR,
      `${anchor.offsetWidth}px`,
    );

    const rect = anchor.getBoundingClientRect();
    const room = Math.max(rect.top, window.innerHeight - rect.bottom);
    const available = Math.max(0, Math.floor(room - COLLISION_MARGIN));
    this.content.style.setProperty(AVAILABLE_HEIGHT_VAR, `${available}px`);

    this.positionedElement?.update();
  }

  // ---- Forms ---------------------------------------------------------------

  getInputName() {
    const name = this.options.name || "";
    if (!this.multiple || !name || name.endsWith("[]")) return name;
    return `${name}[]`;
  }

  syncHiddenInputs() {
    if (!this.el) return;

    this.el
      .querySelectorAll("input[data-salad-ui-combobox-input='true']")
      .forEach((input) => input.remove());

    const name = this.getInputName();
    if (!name) return;

    const values = this.multiple ? this.values : this.values.slice(0, 1);
    values.forEach((value) => {
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = name;
      input.value = value;
      input.dataset.saladUiComboboxInput = "true";
      this.el.appendChild(input);
    });
  }

  dispatchFormEvents() {
    if (!this.el.closest("form")) return;

    // The server-rendered tracker survives patches, so LiveView keeps
    // counting the combobox as used (see SaladUI.Select).
    const target =
      this.el.querySelector("input[data-salad-ui-combobox-tracker='true']") ||
      this.el.querySelector("input[data-salad-ui-combobox-input='true']") ||
      this.el;
    target.dispatchEvent(new Event("change", { bubbles: true }));
  }

  // ---- LiveView patches ----------------------------------------------------

  /**
   * Keep this instance across LiveView patches (server filtering re-renders
   * the items while the list is open) and re-apply its state to the patched
   * DOM. A new server `value` replaces the selection.
   */
  skipReinitialize(el) {
    if (el !== this.el || this.destroyed) return false;

    const optionsRaw = el.getAttribute("data-options");
    if (optionsRaw !== this._optionsRaw) {
      let next;
      try {
        next = optionsRaw ? JSON.parse(optionsRaw) : {};
      } catch {
        return false;
      }
      const previous = this.options;
      this.options = next;
      this._optionsRaw = optionsRaw;
      this.readOptions();

      if (JSON.stringify(previous.value) !== JSON.stringify(next.value)) {
        this.values = this.normalizeValue(next.value);
      }
    }

    const mappingsRaw = el.getAttribute("data-event-mappings");
    if (mappingsRaw !== this._eventMappingsRaw) {
      try {
        this.eventMappings = mappingsRaw ? JSON.parse(mappingsRaw) : {};
        this._eventMappingsRaw = mappingsRaw;
      } catch {
        return false;
      }
    }

    this.refresh();
    return true;
  }

  refresh() {
    this.allParts = this.queryParts().filter(
      (element) =>
        !element.dataset.part.startsWith("item") &&
        !element.dataset.part.endsWith("-item"),
    );

    const content = this.getPart("content") || null;
    if (content !== this.content) {
      this.positionedElement?.destroy();
      this.positionedElement = null;
      this.content = content;
    }

    this.updateUI();
    this.updatePartsVisibility();

    // The patch reset the inputs the user is not typing in.
    const main = this.mainInput();
    if (main && main !== document.activeElement) {
      const text =
        this.state === "open"
          ? this.query
          : this.multiple || this.values.length === 0
            ? main.value
            : this.labelFor(this.values[0]);
      main.value = text;
    }

    this.learnChipLabels();
    this.syncHiddenInputs();
    this.render();

    if (this.state === "open") {
      this.ensurePositioned();
      this.positionedElement?.activate();
      this.reposition();
    }
  }

  beforeDestroy() {
    this.positionedElement?.destroy();
    this.positionedElement = null;
  }
}

SaladUI.register("combobox", ComboboxComponent);

export default ComboboxComponent;
