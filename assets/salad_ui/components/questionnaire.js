// saladui/components/questionnaire.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

/**
 * Multi-step questionnaire.
 *
 * The root is a native <form>; every item is a <fieldset> whose answers are
 * native radios, checkboxes and text inputs. Previous / Skip / Next / Submit
 * are submit buttons posting `_questionnaire[action]`, so the server can run
 * the whole flow without JavaScript (see SaladUI.Questionnaire.State).
 *
 * This component enhances that form:
 *
 * - client-driven (no server `item`): navigation, skipping and validation
 *   happen in the browser; only a valid final submission reaches the server.
 * - server-driven (`data-options.serverDriven`): the server owns the active
 *   item. The active item is validated here first (no round trip for a missing
 *   answer), then the submission goes through and the server re-renders.
 *
 * Both modes keep status, invalid state, shortcuts, progress, action
 * visibility and ARIA in sync, and add keyboard navigation. Client state
 * survives LiveView patches (which rebuild this component) on the root
 * element itself.
 */

const STATE_KEY = "__saladQuestionnaire";
const ACTION_NAME = "_questionnaire[action]";
const ACTIONS = ["previous", "skip", "next", "submit"];
const NON_TEXT_INPUT_TYPES = [
  "button",
  "checkbox",
  "hidden",
  "radio",
  "reset",
  "submit",
];
const NAVIGABLE_INPUT_TYPES = [
  "email",
  "password",
  "search",
  "tel",
  "text",
  "url",
];

const hasText = (value) => value != null && String(value).trim().length > 0;

function shortcutKeys(mode) {
  if (mode === "letters") {
    return Array.from({ length: 26 }, (_, i) => String.fromCharCode(65 + i));
  }
  if (mode === "numbers") {
    return Array.from({ length: 9 }, (_, i) => String(i + 1));
  }
  return [];
}

function isTextEntry(el) {
  if (!el || el.nodeType !== 1) return false;
  if (el.tagName === "TEXTAREA" || el.tagName === "SELECT") return true;
  if (el.tagName === "INPUT") return !NON_TEXT_INPUT_TYPES.includes(el.type);
  return !!el.isContentEditable;
}

const isRadio = (el) => el?.tagName === "INPUT" && el.type === "radio";

function toggleAttr(el, name, on, value = "") {
  if (on) {
    if (el.getAttribute(name) !== value) el.setAttribute(name, value);
  } else if (el.hasAttribute(name)) {
    el.removeAttribute(name);
  }
}

function setAttr(el, name, value) {
  if (value === null || value === undefined || value === false) {
    if (el.hasAttribute(name)) el.removeAttribute(name);
  } else if (el.getAttribute(name) !== String(value)) {
    el.setAttribute(name, String(value));
  }
}

class QuestionnaireComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.serverDriven = !!this.options.serverDriven;
    this.shortcutMode = this.options.shortcuts || null;
    this.initialItem = this.options.item ?? null;

    const persisted = el[STATE_KEY] || null;
    const restore = !this.serverDriven && persisted;

    this.skipped = new Set(restore ? persisted.skipped : []);
    this.attempted = new Set(restore ? persisted.attempted : []);
    // Items the server rendered invalid (e.g. an external validator's
    // message) stay invalid until their answer changes.
    this.forced = new Set(restore ? persisted.forced : []);
    this.inputSelected = new Map(restore ? persisted.inputSelected : []);

    if (!restore) this.seedFromDom();

    this.items().forEach((item) => {
      const name = item.dataset.name;
      if (!this.inputSelected.has(name)) {
        this.inputSelected.set(name, this.defaultInputSelected(item));
      }
    });

    const names = this.enabledNames();
    let active = restore ? persisted.active : this.options.item;
    if (!names.includes(active)) active = names[0] ?? null;
    this.active = active;

    this.focusOnMount =
      this.serverDriven && persisted?.awaitingServer ? true : false;

    this.render();
    this.statuses = this.currentStatuses();
    this.persist();
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: { transitions: {} },
      },
      events: {},
      ariaConfig: {
        progress: {
          all: { role: "progressbar", live: "polite" },
        },
        "default-action": {
          all: { hidden: "true" },
        },
        "choice-shortcut": {
          all: { hidden: "true" },
        },
      },
    };
  }

  setupComponentEvents() {
    super.setupComponentEvents();

    this.onSubmit = this.onSubmit.bind(this);
    this.onKeyDown = this.onKeyDown.bind(this);
    this.onChange = this.onChange.bind(this);
    this.onInput = this.onInput.bind(this);
    this.onReset = this.onReset.bind(this);

    this.el.addEventListener("submit", this.onSubmit);
    this.el.addEventListener("keydown", this.onKeyDown);
    this.el.addEventListener("change", this.onChange);
    this.el.addEventListener("input", this.onInput);
    this.el.addEventListener("reset", this.onReset);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();

    this.el.removeEventListener("submit", this.onSubmit);
    this.el.removeEventListener("keydown", this.onKeyDown);
    this.el.removeEventListener("change", this.onChange);
    this.el.removeEventListener("input", this.onInput);
    this.el.removeEventListener("reset", this.onReset);
    clearTimeout(this.resetTimer);
  }

  afterMount() {
    // After a server-driven step, focus the item the server rendered (or the
    // first answer of an item it marked invalid), as a client step would.
    if (!this.focusOnMount) return;
    this.focusOnMount = false;
    const item = this.activeItem();
    if (!item) return;
    if (this.isInvalid(item)) this.focusInvalid(item);
    else item.focus();
  }

  // --- DOM queries --------------------------------------------------------

  owns(node) {
    return node.closest('[data-component="questionnaire"]') === this.el;
  }

  ownParts(name) {
    return Array.from(this.el.querySelectorAll(`[data-part="${name}"]`)).filter(
      (node) => this.owns(node),
    );
  }

  items() {
    return this.ownParts("item");
  }

  isDisabled(item) {
    return item.disabled || item.hasAttribute("data-disabled");
  }

  enabledItems() {
    return this.items().filter((item) => !this.isDisabled(item));
  }

  enabledNames() {
    return this.enabledItems().map((item) => item.dataset.name);
  }

  itemByName(name) {
    return this.items().find((item) => item.dataset.name === name) || null;
  }

  activeItem() {
    return (
      this.enabledItems().find((i) => i.dataset.name === this.active) || null
    );
  }

  itemOf(node) {
    const item = node?.closest?.('[data-part="item"]');
    return item && this.owns(item) ? item : null;
  }

  isRequired(item) {
    return item.hasAttribute("data-required");
  }

  isMultiple(item) {
    return item.hasAttribute("data-multiple");
  }

  choiceInputs(item) {
    return Array.from(item.querySelectorAll('[data-part="choice-input"]'));
  }

  textInputs(item) {
    return Array.from(item.querySelectorAll('[data-part="input"]'));
  }

  answerControls(item) {
    return Array.from(
      item.querySelectorAll('[data-part="choice-input"], [data-part="input"]'),
    ).filter((control) => !control.disabled);
  }

  // --- Answer state -------------------------------------------------------

  seedFromDom() {
    this.items().forEach((item) => {
      const name = item.dataset.name;
      if (item.dataset.status === "skipped") this.skipped.add(name);
      if (item.hasAttribute("data-invalid")) {
        this.attempted.add(name);
        this.forced.add(name);
      }
    });
  }

  /** Whether the freeform text is (part of) the item's answer. */
  defaultInputSelected(item) {
    const filled = this.textInputs(item).some((input) => hasText(input.value));
    if (this.isMultiple(item)) return filled;
    return filled && !this.choiceInputs(item).some((input) => input.checked);
  }

  inputAnswered(item) {
    if (!this.inputSelected.get(item.dataset.name)) return false;
    return this.textInputs(item).some(
      (input) => !input.disabled && hasText(input.value),
    );
  }

  answered(item) {
    return (
      this.choiceInputs(item).some(
        (input) => input.checked && !input.disabled,
      ) || this.inputAnswered(item)
    );
  }

  status(item) {
    if (this.skipped.has(item.dataset.name)) return "skipped";
    return this.answered(item) ? "answered" : "unanswered";
  }

  isSkippedOptional(item) {
    return this.skipped.has(item.dataset.name) && !this.isRequired(item);
  }

  isValid(item) {
    if (this.isDisabled(item) || this.isSkippedOptional(item)) return true;
    return !this.forced.has(item.dataset.name) && this.answered(item);
  }

  isInvalid(item) {
    const name = item.dataset.name;
    return (
      !this.isDisabled(item) &&
      !this.isSkippedOptional(item) &&
      (this.forced.has(name) ||
        (this.attempted.has(name) && !this.answered(item)))
    );
  }

  validate(item) {
    this.attempted.add(item.dataset.name);
    return this.isValid(item);
  }

  isAnswerFilled(control, item) {
    if (control.dataset.part === "choice-input") return control.checked;
    return (
      !!this.inputSelected.get(item.dataset.name) && hasText(control.value)
    );
  }

  currentStatuses() {
    return new Map(
      this.items().map((item) => [item.dataset.name, this.status(item)]),
    );
  }

  // --- Events -------------------------------------------------------------

  onChange(event) {
    const target = event.target;
    if (target?.dataset?.part !== "choice-input") return;
    const item = this.itemOf(target);
    if (!item) return;

    this.forced.delete(item.dataset.name);
    if (target.checked) {
      this.skipped.delete(item.dataset.name);
      if (!this.isMultiple(item))
        this.inputSelected.set(item.dataset.name, false);
    }
    this.update();
  }

  onInput(event) {
    const target = event.target;
    if (target?.dataset?.part !== "input") return;
    const item = this.itemOf(target);
    if (!item) return;

    const filled = hasText(target.value);
    this.forced.delete(item.dataset.name);
    this.inputSelected.set(item.dataset.name, filled);
    if (filled) {
      this.skipped.delete(item.dataset.name);
      if (!this.isMultiple(item)) {
        this.choiceInputs(item).forEach((input) => {
          input.checked = false;
        });
      }
    }
    this.update();
  }

  onReset(event) {
    clearTimeout(this.resetTimer);
    // The reset event fires before the browser restores the defaults.
    this.resetTimer = setTimeout(() => {
      if (this.destroyed || event.defaultPrevented) return;

      this.skipped.clear();
      this.attempted.clear();
      this.forced.clear();
      if (this.serverDriven) this.seedFromDom();
      this.items().forEach((item) => {
        this.inputSelected.set(
          item.dataset.name,
          this.defaultInputSelected(item),
        );
      });

      if (!this.serverDriven) {
        const names = this.enabledNames();
        const initial = names.includes(this.initialItem)
          ? this.initialItem
          : (names[0] ?? null);
        if (initial !== this.active) {
          this.setActive(initial);
          return;
        }
      }
      this.update();
    }, 0);
  }

  onSubmit(event) {
    if (event.defaultPrevented) return;

    const submitter = event.submitter;
    const action =
      submitter && submitter.name === ACTION_NAME && this.owns(submitter)
        ? submitter.value
        : "submit";

    const allow = this.serverDriven
      ? this.serverAction(action)
      : this.clientAction(action);

    if (allow) {
      if (this.serverDriven) this.persist({ awaitingServer: true });
      return;
    }

    event.preventDefault();
    event.stopPropagation();
  }

  onKeyDown(event) {
    if (event.defaultPrevented || event.isComposing || event.keyCode === 229) {
      return;
    }

    const target = event.target;
    const item = this.activeItem();
    if (!item || !target || target.nodeType !== 1) return;

    if (
      event.key === "Enter" &&
      (event.metaKey || event.ctrlKey) &&
      !event.altKey &&
      !event.shiftKey
    ) {
      event.preventDefault();
      if (!event.repeat) this.submitWith("continue");
      return;
    }

    if (event.metaKey || event.ctrlKey || event.altKey) return;

    if (event.key === "ArrowUp" || event.key === "ArrowDown") {
      const direction = event.key === "ArrowDown" ? 1 : -1;
      if (this.moveAnswerFocus(item, target, direction)) {
        event.preventDefault();
        return;
      }
    }

    if (
      (event.key === "ArrowLeft" || event.key === "ArrowRight") &&
      !isTextEntry(target) &&
      !isRadio(target)
    ) {
      event.preventDefault();
      if (event.repeat) return;

      if (event.key === "ArrowLeft") {
        if (!this.isFirst()) this.submitWith("previous");
      } else if (!this.isLast() && this.status(item) !== "unanswered") {
        this.submitWith("next");
      }
      return;
    }

    if (event.key === "Enter") {
      if (!this.answerControls(item).includes(target)) return;
      event.preventDefault();
      if (!event.repeat && this.isAnswerFilled(target, item)) {
        this.submitWith("continue");
      }
      return;
    }

    if (!this.shortcutMode || isTextEntry(target)) return;

    const key =
      this.shortcutMode === "letters" ? event.key.toUpperCase() : event.key;
    const choice = Array.from(
      item.querySelectorAll('[data-part="choice"]'),
    ).find((node) => node.getAttribute("data-shortcut") === key);
    const input = choice?.querySelector('[data-part="choice-input"]');
    if (!input || input.disabled) return;

    event.preventDefault();
    if (event.repeat) return;
    input.focus();
    input.click();
  }

  // --- Navigation ---------------------------------------------------------

  indexOfActive() {
    return this.enabledNames().indexOf(this.active);
  }

  isFirst() {
    return this.indexOfActive() <= 0;
  }

  isLast() {
    const names = this.enabledNames();
    return names.length > 0 && this.indexOfActive() === names.length - 1;
  }

  /**
   * Submits the form with `_questionnaire[action]` set to `action`, so a
   * keyboard or server command goes through the same path as a button press
   * (and reaches the server in server-driven mode).
   */
  submitWith(action) {
    const button = this.ownParts("default-action")[0];
    if (!button || typeof this.el.requestSubmit !== "function") {
      // Not a questionnaire form: run the action directly.
      if (!this.serverDriven) this.clientAction(action);
      return;
    }

    const previous = button.value;
    button.value = action;
    try {
      this.el.requestSubmit(button);
    } finally {
      button.value = previous;
    }
  }

  /** Server-driven: validate locally, then let the server move the step. */
  serverAction(action) {
    const item = this.activeItem();
    if (!item || action === "previous") return true;

    if (action === "skip") {
      if (this.isRequired(item)) return false;
      return true;
    }

    if (!this.validate(item)) {
      this.update();
      this.focusInvalid(item);
      return false;
    }
    return true;
  }

  /** Client-driven: returns true when the native submission should proceed. */
  clientAction(action) {
    switch (action) {
      case "previous":
        this.goPrevious();
        return false;
      case "next":
        this.goNext();
        return false;
      case "skip":
        return this.skipCurrent() ? this.validateAll() : false;
      case "continue":
        if (!this.isLast()) {
          this.goNext();
          return false;
        }
        return this.validateAll();
      default:
        return this.validateAll();
    }
  }

  goPrevious() {
    const names = this.enabledNames();
    const index = names.indexOf(this.active);
    if (index > 0) this.setActive(names[index - 1]);
  }

  goNext() {
    const item = this.activeItem();
    if (!item) return;
    if (!this.validate(item)) {
      this.update();
      this.focusInvalid(item);
      return;
    }
    const names = this.enabledNames();
    const index = names.indexOf(this.active);
    if (index < names.length - 1) this.setActive(names[index + 1]);
    else this.update();
  }

  /** Skips the active optional item. Returns true when it was the last item. */
  skipCurrent() {
    const item = this.activeItem();
    if (!item || this.isRequired(item)) return false;

    const name = item.dataset.name;
    this.choiceInputs(item).forEach((input) => {
      input.checked = false;
    });
    this.inputSelected.set(name, false);
    this.skipped.add(name);

    if (this.isLast()) {
      this.update();
      return true;
    }
    const names = this.enabledNames();
    this.setActive(names[names.indexOf(name) + 1]);
    return false;
  }

  /** Validates every enabled item; opens the first invalid one. */
  validateAll() {
    const invalid = this.enabledItems().find((item) => !this.validate(item));
    if (!invalid) {
      this.update();
      return true;
    }

    if (invalid.dataset.name === this.active) {
      this.update();
      this.focusInvalid(invalid);
    } else {
      this.setActive(invalid.dataset.name, "invalid");
    }
    return false;
  }

  setActive(name, focusTarget = "item") {
    if (name == null) return;
    if (name === this.active) {
      this.update();
      return;
    }

    this.active = name;
    this.update();
    this.pushEvent("item-change", { item: name });

    const item = this.activeItem();
    if (!item) return;
    if (focusTarget === "invalid") this.focusInvalid(item);
    else item.focus();
  }

  focusInvalid(item) {
    const selected = item.querySelector(
      '[data-part="input"][data-filled][name]:not(:disabled)',
    );
    const first = item.querySelector(
      "input:not([type=hidden]):not(:disabled), textarea:not(:disabled)",
    );
    (selected || first || item).focus();
  }

  moveAnswerFocus(item, target, direction) {
    const answers = this.answerControls(item);
    const index = answers.indexOf(target);
    const current = index < 0 ? null : answers[index];

    const emptyNavigableInput =
      current?.dataset.part === "input" &&
      NAVIGABLE_INPUT_TYPES.includes(current.type) &&
      !hasText(current.value);

    if (
      !answers.length ||
      (isTextEntry(target) && !emptyNavigableInput) ||
      (index < 0 && target !== item)
    ) {
      return false;
    }

    const next =
      index < 0
        ? answers.find((answer) => this.isAnswerFilled(answer, item)) ||
          (direction > 0 ? answers[0] : answers[answers.length - 1])
        : answers[(index + direction + answers.length) % answers.length];

    if (!next || next === target) return false;
    // Native radios already move (and select) between themselves.
    if (index >= 0 && isRadio(target) && isRadio(next)) return false;

    next.focus();
    if (isRadio(next)) next.click();
    return true;
  }

  // --- Rendering ----------------------------------------------------------

  update() {
    if (this.destroyed) return;
    this.render();
    this.emitStatusChanges();
    this.persist();
  }

  emitStatusChanges() {
    const statuses = this.currentStatuses();
    statuses.forEach((status, name) => {
      if (this.statuses?.get(name) !== status) {
        this.pushEvent("status-change", { item: name, status });
      }
    });
    this.statuses = statuses;
  }

  persist(extra = {}) {
    if (!this.el) return;
    this.el[STATE_KEY] = {
      active: this.active,
      skipped: [...this.skipped],
      attempted: [...this.attempted],
      forced: [...this.forced],
      inputSelected: [...this.inputSelected],
      awaitingServer: false,
      ...extra,
    };
  }

  render() {
    const items = this.items();
    const enabled = items.filter((item) => !this.isDisabled(item));
    const names = enabled.map((item) => item.dataset.name);
    const index = names.indexOf(this.active);
    const total = names.length;
    const current = index < 0 ? 0 : index + 1;
    const first = total > 0 && index === 0;
    const last = total > 0 && index === total - 1;
    const activeItem = index < 0 ? null : enabled[index];
    const status = activeItem ? this.status(activeItem) : null;
    const required = activeItem ? this.isRequired(activeItem) : null;

    const root = this.el;
    setAttr(root, "data-current", current);
    setAttr(root, "data-total", total);
    toggleAttr(root, "data-first", first);
    toggleAttr(root, "data-last", last);
    toggleAttr(root, "data-required", required === true);
    setAttr(root, "data-status", status);
    setAttr(root, "data-shortcuts", this.shortcutMode);

    const activeInput = this.ownParts("active-input")[0];
    if (activeInput) activeInput.value = this.active ?? "";
    this.renderSkippedInputs(enabled, activeInput);

    items.forEach((item) =>
      this.renderItem(item, item === activeItem, { first, last }),
    );
    this.renderProgress({ current, total, first, last });
    this.renderActions({ first, last, total, status, required });
  }

  renderSkippedInputs(enabled, anchor) {
    const names = enabled
      .filter((item) => this.isSkippedOptional(item))
      .map((item) => item.dataset.name);
    const existing = this.ownParts("skipped-input");
    if (
      existing.length === names.length &&
      existing.every((input, i) => input.value === names[i])
    ) {
      return;
    }

    existing.forEach((input) => input.remove());
    let after = anchor;
    names.forEach((name) => {
      const input = document.createElement("input");
      input.type = "hidden";
      input.name = "_questionnaire[skipped][]";
      input.value = name;
      input.setAttribute("data-part", "skipped-input");
      if (after) after.after(input);
      else this.el.prepend(input);
      after = input;
    });
  }

  renderItem(item, active, { first, last }) {
    const name = item.dataset.name;
    const disabled = this.isDisabled(item);
    const status = this.status(item);
    const invalid = this.isInvalid(item);
    const multiple = this.isMultiple(item);

    toggleAttr(item, "data-active", active);
    item.hidden = !active;
    toggleAttr(item, "inert", !active);
    setAttr(item, "data-status", status);
    toggleAttr(item, "data-invalid", invalid);
    setAttr(item, "aria-invalid", invalid ? "true" : null);

    // aria-describedby: descriptions, then the error while invalid, then
    // whatever the template set (remembered across renders).
    if (!item.hasAttribute("data-describedby-base")) {
      item.setAttribute(
        "data-describedby-base",
        item.getAttribute("aria-describedby") || "",
      );
    }
    const ids = [
      ...Array.from(item.querySelectorAll('[data-part="description"]')).map(
        (node) => node.id,
      ),
      ...(invalid
        ? Array.from(item.querySelectorAll('[data-part="error"]')).map(
            (node) => node.id,
          )
        : []),
      item.getAttribute("data-describedby-base"),
    ].filter(Boolean);
    setAttr(item, "aria-describedby", ids.length ? ids.join(" ") : null);

    const answers = this.answerControls(item);
    const keyShortcuts = active
      ? [
          "Meta+Enter Control+Enter",
          answers.length ? "ArrowUp ArrowDown" : null,
          !first ? "ArrowLeft" : null,
          !last && status !== "unanswered" ? "ArrowRight" : null,
        ]
          .filter(Boolean)
          .join(" ")
      : null;
    setAttr(item, "aria-keyshortcuts", keyShortcuts);

    item.querySelectorAll('[data-part="choices"]').forEach((choices) => {
      setAttr(choices, "data-shortcuts", this.shortcutMode);
    });

    const keys = shortcutKeys(this.shortcutMode);
    let nextKey = 0;
    item.querySelectorAll('[data-part="choice"]').forEach((choice) => {
      const input = choice.querySelector('[data-part="choice-input"]');
      if (!input) return;
      const choiceDisabled = disabled || input.disabled;
      const checked = input.checked;
      const shortcut =
        !choiceDisabled && nextKey < keys.length ? keys[nextKey++] : null;

      setAttr(choice, "data-type", multiple ? "checkbox" : "radio");
      toggleAttr(choice, "data-checked", checked);
      toggleAttr(choice, "data-unchecked", !checked);
      toggleAttr(choice, "data-disabled", choiceDisabled);
      toggleAttr(choice, "data-invalid", invalid);
      setAttr(choice, "data-shortcut", shortcut);

      const hint = choice.querySelector('[data-part="choice-shortcut"]');
      if (hint) {
        if (hint.textContent.trim() !== (shortcut ?? "")) {
          hint.textContent = shortcut ?? "";
        }
        hint.hidden = !shortcut;
      }

      setAttr(input, "aria-invalid", invalid ? "true" : null);
      const inputShortcuts = [
        shortcut,
        checked && !choiceDisabled ? "Enter" : null,
      ]
        .filter(Boolean)
        .join(" ");
      setAttr(input, "aria-keyshortcuts", inputShortcuts || null);
    });

    const selected = !!this.inputSelected.get(name);
    this.textInputs(item).forEach((input) => {
      const filled = hasText(input.value);
      const fieldName = input.dataset.name || `${name}[]`;
      setAttr(input, "name", selected ? fieldName : null);
      toggleAttr(input, "data-filled", filled);
      toggleAttr(input, "data-empty", !filled);
      toggleAttr(input, "data-invalid", invalid);
      setAttr(input, "aria-invalid", invalid ? "true" : null);
      setAttr(
        input,
        "aria-keyshortcuts",
        filled && selected && !input.disabled ? "Enter" : null,
      );
    });

    item.querySelectorAll('[data-part="error"]').forEach((error) => {
      error.hidden = !invalid;
      toggleAttr(error, "data-invalid", invalid);
      setAttr(error, "role", invalid ? "alert" : null);
    });
  }

  renderProgress({ current, total, first, last }) {
    const label = total ? `Question ${current} of ${total}` : null;

    this.ownParts("progress").forEach((progress) => {
      setAttr(progress, "data-current", current);
      setAttr(progress, "data-total", total);
      toggleAttr(progress, "data-first", first);
      toggleAttr(progress, "data-last", last);
      setAttr(progress, "aria-valuemin", total ? 1 : null);
      setAttr(progress, "aria-valuemax", total || null);
      setAttr(progress, "aria-valuenow", total ? current : null);
      setAttr(progress, "aria-valuetext", label);

      if (progress.hasAttribute("data-default-label")) {
        if (progress.textContent.trim() !== (label ?? "")) {
          progress.textContent = label ?? "";
        }
        return;
      }

      progress.querySelectorAll("[data-progress-current]").forEach((node) => {
        node.textContent = String(current);
      });
      progress.querySelectorAll("[data-progress-total]").forEach((node) => {
        node.textContent = String(total);
      });
      progress.querySelectorAll("[data-progress-step]").forEach((node) => {
        const step = parseInt(node.getAttribute("data-progress-step"), 10);
        toggleAttr(node, "data-complete", step <= current);
      });
    });
  }

  renderActions({ first, last, total, status, required }) {
    ACTIONS.forEach((action) => {
      this.ownParts(action).forEach((button) => {
        let visible;
        if (action === "previous") visible = total > 1 && !first;
        else if (action === "skip") visible = required === false;
        else if (action === "next") visible = total > 1 && !last;
        else visible = total > 0 && last;

        const shortcut =
          (action === "next" || action === "submit") &&
          visible &&
          !button.disabled
            ? "Enter"
            : null;

        button.hidden = !visible;
        toggleAttr(button, "inert", !visible);
        setAttr(button, "aria-hidden", visible ? null : "true");
        toggleAttr(button, "data-visible", visible);
        toggleAttr(button, "data-hidden", !visible);
        setAttr(button, "data-status", status);
        setAttr(button, "data-shortcut", shortcut);
        setAttr(button, "aria-keyshortcuts", shortcut);
      });
    });
  }

  // --- Commands -----------------------------------------------------------

  handleCommand(command, params = {}) {
    if (ACTIONS.includes(command)) {
      this.submitWith(command);
      return true;
    }
    if (command === "goto") {
      if (!this.serverDriven && this.enabledNames().includes(params.item)) {
        this.setActive(params.item);
      }
      return true;
    }
    if (command === "reset") {
      this.el.reset();
      return true;
    }
    return super.handleCommand(command, params);
  }
}

SaladUI.register("questionnaire", QuestionnaireComponent);

export default QuestionnaireComponent;
