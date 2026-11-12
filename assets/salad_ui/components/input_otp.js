// saladui/components/input_otp.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

/**
 * One-time password input.
 *
 * A single real <input> (data-part="input") is stretched invisibly over the
 * slots and owns the value, focus, selection, typing, deletion and form
 * submission. This component mirrors the input's value and selection onto the
 * slots (data-active, character, fake caret), keeps the selection on one
 * character the way the input-otp library does, handles paste, and rejects
 * input that fails the `pattern` option.
 */
class InputOTPComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.doc = el.ownerDocument;
    this.input = this.getPart("input");
    this.slots = this.getAllParts("slot");
    this.maxLength =
      parseInt(this.options.maxLength, 10) ||
      parseInt(this.input?.getAttribute("maxlength"), 10) ||
      this.slots.length;
    this.regexp = compilePattern(this.options.pattern);

    this.prevValue = this.input ? this.input.value : "";
    this.mirror = [null, null];
    this.prevSelection = [null, null, null];

    this.render();
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: {
          transitions: { focus: "focused" },
        },
        focused: {
          transitions: { blur: "idle" },
        },
      },
      events: {},
      ariaConfig: {
        // The real input is the accessible control; the slots only redraw
        // its value, so keep them out of the accessibility tree.
        slot: {
          all: { hidden: "true" },
        },
      },
    };
  }

  setupComponentEvents() {
    super.setupComponentEvents();
    if (!this.input) return;

    this.onInput = this.onInput.bind(this);
    this.onPaste = this.onPaste.bind(this);
    this.onFocus = this.onFocus.bind(this);
    this.onBlur = this.onBlur.bind(this);
    this.onPointerUp = this.onPointerUp.bind(this);
    this.onSelectionChange = this.onSelectionChange.bind(this);

    this.input.addEventListener("input", this.onInput);
    this.input.addEventListener("paste", this.onPaste);
    this.input.addEventListener("focus", this.onFocus);
    this.input.addEventListener("blur", this.onBlur);
    this.input.addEventListener("mouseup", this.onPointerUp);
    // Arrow keys and Home/End move the native caret; keyup covers browsers
    // that do not fire selectionchange for text inputs.
    this.input.addEventListener("keyup", this.onSelectionChange);
    this.doc.addEventListener("selectionchange", this.onSelectionChange);

    if (typeof ResizeObserver !== "undefined") {
      this.resizeObserver = new ResizeObserver(() => this.updateRootHeight());
      this.resizeObserver.observe(this.el);
    }
    this.updateRootHeight();
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    if (!this.input) return;

    this.input.removeEventListener("input", this.onInput);
    this.input.removeEventListener("paste", this.onPaste);
    this.input.removeEventListener("focus", this.onFocus);
    this.input.removeEventListener("blur", this.onBlur);
    this.input.removeEventListener("mouseup", this.onPointerUp);
    this.input.removeEventListener("keyup", this.onSelectionChange);
    this.doc.removeEventListener("selectionchange", this.onSelectionChange);
    this.resizeObserver?.disconnect();
    this.resizeObserver = null;
  }

  afterMount() {
    // A LiveView patch rebuilds the component; keep the focused look.
    if (this.isFocused()) {
      this.transition("focus");
      this.syncSelection();
      this.render();
    }
  }

  isFocused() {
    return !!this.input && this.doc?.activeElement === this.input;
  }

  get value() {
    return this.input ? this.input.value : "";
  }

  // --- Events -------------------------------------------------------------

  onFocus() {
    const value = this.value;
    const start = Math.min(value.length, this.maxLength - 1);
    const end = value.length;
    this.setSelection(start, end);
    this.mirror = [start, end];
    this.prevSelection = [start, end, "none"];
    this.transition("focus");
    this.render();
  }

  onBlur() {
    this.transition("blur");
    this.render();
  }

  onInput(event) {
    const raw = this.value;
    const value = raw.slice(0, this.maxLength);

    if (value.length > 0 && this.regexp && !this.regexp.test(value)) {
      // Reject: restore the previous value and keep LiveView's form
      // listeners (phx-change) from seeing the rejected keystroke.
      event.stopImmediatePropagation();
      this.input.value = this.prevValue;
      const [start, end] = this.prevSelection;
      if (start !== null && end !== null) this.setSelection(start, end);
      this.render();
      return;
    }

    if (value !== raw) this.input.value = value;
    this.commit(value);
  }

  onPaste(event) {
    if (this.disabled || this.input.readOnly) return;

    const text = event.clipboardData?.getData("text/plain");
    if (text == null) return;
    event.preventDefault();

    const content = text.replace(/\s+/g, "");
    const value = this.value;
    const start = this.input.selectionStart ?? value.length;
    const end = this.input.selectionEnd ?? value.length;
    const next = (value.slice(0, start) + content + value.slice(end)).slice(
      0,
      this.maxLength,
    );

    if (next.length > 0 && this.regexp && !this.regexp.test(next)) return;

    this.input.value = next;
    const caretStart = Math.min(next.length, this.maxLength - 1);
    this.setSelection(caretStart, next.length);
    this.mirror = [caretStart, next.length];
    this.prevSelection = [caretStart, next.length, "none"];

    // Let the regular input path (and LiveView's phx-change) see the paste.
    this.input.dispatchEvent(new Event("input", { bubbles: true }));
  }

  onPointerUp(event) {
    if (this.disabled || !this.isFocused()) return;

    const index = this.slotIndexAt(event.clientX);
    if (index === null) return;

    const length = this.value.length;
    if (index < length) {
      this.setSelection(index, index + 1);
    } else {
      this.setSelection(Math.min(length, this.maxLength - 1), length);
    }
    this.syncSelection();
    this.render();
  }

  onSelectionChange() {
    if (!this.isFocused()) return;
    this.syncSelection();
    this.render();
  }

  // --- Value --------------------------------------------------------------

  commit(value, { silent = false } = {}) {
    const previous = this.prevValue;
    this.prevValue = value;

    if (this.isFocused()) this.syncSelection();
    this.render();

    if (silent || value === previous) return;

    this.pushEvent("value-changed", { value });
    if (value.length === this.maxLength && previous.length < this.maxLength) {
      this.pushEvent("complete", { value });
    }
  }

  setValue(raw, options) {
    if (!this.input) return;
    const value = String(raw ?? "").slice(0, this.maxLength);
    if (value.length > 0 && this.regexp && !this.regexp.test(value)) return;

    this.input.value = value;
    if (this.isFocused()) {
      const start = Math.min(value.length, this.maxLength - 1);
      this.setSelection(start, value.length);
    }
    this.commit(value, options);
  }

  handleCommand(command, params = {}) {
    if (command === "setValue") {
      this.setValue(params.value, { silent: true });
      return true;
    }
    if (command === "clear") {
      this.setValue("", { silent: true });
      return true;
    }
    return super.handleCommand(command, params);
  }

  // --- Selection ----------------------------------------------------------

  setSelection(start, end, direction) {
    try {
      this.input.setSelectionRange(start, end, direction);
    } catch {
      // Inputs that do not support selection (never the case for type=text).
    }
  }

  /**
   * Keep a collapsed caret on a character, as input-otp does, so typing
   * replaces it: a caret before character `c` selects `c` (or `c - 1` when
   * moving backwards). A caret after the last character stays collapsed
   * ("insert mode") while there is room for one more.
   */
  syncSelection() {
    const input = this.input;
    const value = input.value;
    const maxLength = this.maxLength;
    const s = input.selectionStart;
    const e = input.selectionEnd;
    const prev = this.prevSelection;

    let start = -1;
    let end = -1;
    let direction;

    if (value.length !== 0 && s !== null && e !== null) {
      const isSingleCaret = s === e;
      const isInsertMode = s === value.length && value.length < maxLength;

      if (isSingleCaret && !isInsertMode) {
        const c = s;
        if (c === 0) {
          start = 0;
          end = 1;
          direction = "forward";
        } else if (c === maxLength) {
          start = c - 1;
          end = c;
          direction = "backward";
        } else if (maxLength > 1 && value.length > 1) {
          let offset = 0;
          if (prev[0] !== null && prev[1] !== null) {
            direction = c < prev[1] ? "backward" : "forward";
            const wasPreviouslyInserting =
              prev[0] === prev[1] && prev[0] < maxLength;
            if (direction === "backward" && !wasPreviouslyInserting) {
              offset = -1;
            }
          }
          start = offset + c;
          end = offset + c + 1;
        }
      }

      if (start !== -1 && end !== -1 && start !== end) {
        this.setSelection(start, end, direction);
      }
    }

    const mirrorStart = start !== -1 ? start : s;
    const mirrorEnd = end !== -1 ? end : e;
    this.mirror = [mirrorStart, mirrorEnd];
    this.prevSelection = [mirrorStart, mirrorEnd, direction ?? null];
  }

  slotIndexAt(clientX) {
    if (typeof clientX !== "number") return null;
    for (const slot of this.slots) {
      const rect = slot.getBoundingClientRect();
      if (rect.width > 0 && clientX >= rect.left && clientX <= rect.right) {
        return parseInt(slot.dataset.index, 10);
      }
    }
    return null;
  }

  // --- Rendering ----------------------------------------------------------

  render() {
    if (!this.input) return;

    const value = this.value;
    const focused = this.isFocused();
    const [ms, me] = this.mirror;

    this.slots.forEach((slot) => {
      const index = parseInt(slot.dataset.index, 10);
      const char = Number.isInteger(index) ? (value[index] ?? null) : null;
      const isActive =
        focused &&
        ms !== null &&
        me !== null &&
        ((ms === me && index === ms) || (index >= ms && index < me));

      slot.setAttribute("data-active", String(isActive));

      const charEl = slot.querySelector('[data-part="slot-char"]');
      if (charEl) charEl.textContent = char ?? "";

      const caret = slot.querySelector('[data-part="caret"]');
      if (caret) caret.hidden = !(isActive && char === null);
    });
  }

  updateRootHeight() {
    const height = this.el?.getBoundingClientRect().height;
    if (height) this.el.style.setProperty("--root-height", `${height}px`);
  }

  beforeDestroy() {
    this.resizeObserver?.disconnect();
    this.resizeObserver = null;
  }
}

function compilePattern(pattern) {
  if (!pattern) return null;
  try {
    return new RegExp(pattern);
  } catch (error) {
    console.error("SaladUI: invalid input-otp pattern:", pattern, error);
    return null;
  }
}

SaladUI.register("input-otp", InputOTPComponent);

export default InputOTPComponent;
