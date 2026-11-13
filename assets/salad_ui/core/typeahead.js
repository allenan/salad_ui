// saladui/core/typeahead.js
//
// Typeahead for menus and listboxes, after Radix's `useTypeaheadSearch` /
// `getNextMatch`: printable keys build a search string that clears 1s after
// the last key; the next enabled item whose text starts with it is matched.
// Typing one letter repeatedly ("bbb") cycles through the items starting with
// that letter.

export const TYPEAHEAD_TIMEOUT_MS = 1000;

/**
 * A printable character with no Ctrl/Alt/Meta modifier (Shift is fine: it
 * just makes the character upper case).
 */
export function isTypeaheadKey(event) {
  return (
    typeof event?.key === "string" &&
    event.key.length === 1 &&
    !event.ctrlKey &&
    !event.altKey &&
    !event.metaKey
  );
}

/**
 * The text an item is matched by: its `data-text-value` (Radix's `textValue`
 * prop) when set, else its trimmed text content.
 */
export function getTextValue(element) {
  const override = element?.getAttribute?.("data-text-value");
  if (override !== null && override !== undefined) return override;
  return (element?.textContent || "").trim();
}

/**
 * The item after `current` (wrapping around) whose text starts with `search`,
 * or undefined when there is none or it would be `current` itself.
 */
export function findNextMatch(items, search, current, getText) {
  const isRepeated =
    search.length > 1 && Array.from(search).every((char) => char === search[0]);
  const normalized = (isRepeated ? search[0] : search).toLowerCase();

  const start = Math.max(items.indexOf(current), 0);
  let candidates = [...items.slice(start), ...items.slice(0, start)];
  // A single character moves on from the current item; a longer search keeps
  // it while it still matches.
  if (normalized.length === 1) {
    candidates = candidates.filter((item) => item !== current);
  }

  const match = candidates.find((item) =>
    getText(item).toLowerCase().startsWith(normalized),
  );
  return match !== current ? match : undefined;
}

export class Typeahead {
  constructor({ timeout = TYPEAHEAD_TIMEOUT_MS } = {}) {
    this.timeout = timeout;
    this.search = "";
    this.timer = null;
  }

  /** Whether a search is in progress (Space then types a space). */
  get isSearching() {
    return this.search !== "";
  }

  reset() {
    if (this.timer !== null) clearTimeout(this.timer);
    this.timer = null;
    this.search = "";
  }

  /**
   * Feed a keydown. Returns whether the key was consumed as typeahead; when
   * it was, `onMatch` is called with the matching item, if any.
   *
   * - `items`: the enabled candidates, in order
   * - `current`: the item to search on from (the focused or selected one)
   * - `getText`: item -> text to match
   */
  handleKey(event, { items, current = null, getText, onMatch }) {
    if (!isTypeaheadKey(event)) return false;
    // Space only types a space once a search has started; otherwise it keeps
    // its usual meaning (activate, open).
    if (event.key === " ") {
      if (!this.isSearching) return false;
      // No page scroll, and no click from a focused button on key up.
      event.preventDefault();
    }

    this.search += event.key;
    if (this.timer !== null) clearTimeout(this.timer);
    this.timer = setTimeout(() => this.reset(), this.timeout);

    const match = findNextMatch(items, this.search, current, getText);
    if (match !== undefined) onMatch(match);
    return true;
  }

  destroy() {
    this.reset();
  }
}

// A LiveView patch rebuilds the component on the same element (see
// core/hook.js), e.g. the patch answering the `value-changed` a closed select
// trigger's match just pushed. The search must outlive that rebuild, or the
// next key would start a new search ("ba" would jump to "Apple" instead of
// staying on "Banana"), so searches are kept per owning element.
const searches = new WeakMap();

/**
 * The search owned by `element` (a menu panel, a select's content or
 * trigger), shared by every component instance built on it. Components
 * should not destroy() it on teardown; its timer clears it on its own.
 */
export function typeaheadFor(element) {
  if (!element) return new Typeahead();

  let typeahead = searches.get(element);
  if (!typeahead) {
    typeahead = new Typeahead();
    searches.set(element, typeahead);
  }
  return typeahead;
}

export default Typeahead;
