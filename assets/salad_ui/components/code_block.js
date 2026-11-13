// saladui/components/code_block.js
import Component from "../core/component.js";
import SaladUI from "../index.js";

const RESET_DELAY = 2000;

/**
 * Copy button of a code block. Copies `options.value` to the clipboard (or,
 * without a value, the text of the code block's content), then switches to
 * the "copied" state for two seconds: the icon becomes a check mark, the
 * label becomes "Copied" and a polite live region announces it.
 */
class CodeBlockCopyButtonComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext, initialState: "idle" });
    this.resetTimer = null;
    this.syncCopiedDom();
  }

  /**
   * A LiveView patch (e.g. the re-render an `on-copy` event causes) puts back
   * the server-rendered `data-state="idle"`, `aria-label="Copy"` and drops
   * `data-copied`. When the options and event mappings are unchanged, keep
   * this instance (and its reset timer) and re-apply the current state, so
   * the check mark stays for its full two seconds. A new value rebuilds.
   */
  skipReinitialize(el) {
    if (el !== this.el) return false;
    if (el.getAttribute("data-options") !== this._optionsRaw) return false;
    if (el.getAttribute("data-event-mappings") !== this._eventMappingsRaw) {
      return false;
    }

    this.updateUI();
    this.syncCopiedDom();
    return true;
  }

  syncCopiedDom() {
    const copied = this.state === "copied";
    this.el.toggleAttribute("data-copied", copied);
    // The live region is phx-update="ignore", so a rebuilt (idle) instance
    // must clear an announcement left by the previous one.
    // Only write on a change: rewriting the same text can re-announce it.
    const status = this.statusElement;
    const text = copied ? "Copied" : "";
    if (status && status.textContent !== text) status.textContent = text;
  }

  getComponentConfig() {
    return {
      stateMachine: {
        idle: {
          enter: "onIdleEnter",
          transitions: { copied: "copied" },
        },
        copied: {
          enter: "onCopiedEnter",
          exit: "onCopiedExit",
          transitions: { reset: "idle" },
        },
      },
      events: {
        idle: { mouseMap: { root: { click: "copy" } } },
        copied: { mouseMap: { root: { click: "copy" } } },
      },
      ariaConfig: {
        root: {
          idle: { label: "Copy" },
          copied: { label: "Copied" },
        },
      },
    };
  }

  get statusElement() {
    const sibling = this.el?.nextElementSibling;
    return sibling?.dataset.slot === "code-block-copy-status" ? sibling : null;
  }

  copyText() {
    const value = this.options.value;
    if (value !== null && value !== undefined) return String(value);

    const content = this.el
      .closest('[data-slot="code-block"]')
      ?.querySelector('[data-slot="code-block-content"]');
    if (!content) return "";

    const lines = content.querySelectorAll('[data-slot="code-block-line"]');
    if (lines.length === 0) return content.textContent;

    return Array.from(lines, (line) => {
      const text =
        line.querySelector('[data-slot="code-block-line-content"]')
          ?.textContent ?? line.textContent;
      return text === "\n" ? "" : text;
    }).join("\n");
  }

  copy() {
    if (this.disabled || this.el.disabled) return;

    const clipboard = globalThis.navigator?.clipboard;
    if (!clipboard?.writeText) return;

    const text = this.copyText();

    clipboard
      .writeText(text)
      .then(() => {
        if (this.destroyed) return;

        if (this.state === "copied") {
          this.scheduleReset();
        } else {
          this.transition("copied");
        }
        this.pushEvent("copy", { value: text });
      })
      .catch(() => {});
  }

  scheduleReset() {
    clearTimeout(this.resetTimer);
    this.resetTimer = setTimeout(() => {
      this.resetTimer = null;
      this.transition("reset");
    }, this.options.resetDelay ?? RESET_DELAY);
  }

  onIdleEnter() {
    this.syncCopiedDom();
  }

  onCopiedEnter() {
    this.syncCopiedDom();
    this.scheduleReset();
  }

  onCopiedExit() {
    clearTimeout(this.resetTimer);
    this.resetTimer = null;
  }

  beforeDestroy() {
    clearTimeout(this.resetTimer);
    this.resetTimer = null;
  }
}

SaladUI.register("code-block-copy-button", CodeBlockCopyButtonComponent);

export default CodeBlockCopyButtonComponent;
