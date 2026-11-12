import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import {
  Typeahead,
  findNextMatch,
  getTextValue,
  isTypeaheadKey,
} from "../salad_ui/core/typeahead.js";
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

const ITEMS = ["Apple", "Banana", "Blueberry", "Cherry"];
const text = (item) => item;

function key(value, init = {}) {
  return new window.KeyboardEvent("keydown", {
    key: value,
    cancelable: true,
    ...init,
  });
}

test("isTypeaheadKey accepts printable characters without Ctrl/Alt/Meta", () => {
  assert.equal(isTypeaheadKey(key("a")), true);
  assert.equal(isTypeaheadKey(key("A", { shiftKey: true })), true);
  assert.equal(isTypeaheadKey(key(" ")), true);
  assert.equal(isTypeaheadKey(key("ArrowDown")), false);
  assert.equal(isTypeaheadKey(key("Enter")), false);
  assert.equal(isTypeaheadKey(key("a", { ctrlKey: true })), false);
  assert.equal(isTypeaheadKey(key("a", { altKey: true })), false);
  assert.equal(isTypeaheadKey(key("a", { metaKey: true })), false);
});

test("getTextValue prefers data-text-value over trimmed text", () => {
  const el = document.createElement("div");
  el.textContent = "  ★ Cherry  ";
  assert.equal(getTextValue(el), "★ Cherry");

  el.setAttribute("data-text-value", "Cherry");
  assert.equal(getTextValue(el), "Cherry");
});

test("findNextMatch matches case-insensitively from the current item on", () => {
  assert.equal(findNextMatch(ITEMS, "b", null, text), "Banana");
  assert.equal(findNextMatch(ITEMS, "B", "Banana", text), "Blueberry");
  // Wraps around past the end.
  assert.equal(findNextMatch(ITEMS, "a", "Cherry", text), "Apple");
  assert.equal(findNextMatch(ITEMS, "z", null, text), undefined);
});

test("findNextMatch keeps the current item while a longer search still matches it", () => {
  assert.equal(findNextMatch(ITEMS, "bl", "Banana", text), "Blueberry");
  assert.equal(findNextMatch(ITEMS, "blu", "Blueberry", text), undefined);
});

test("findNextMatch treats a repeated letter as cycling through that letter", () => {
  assert.equal(findNextMatch(ITEMS, "bb", "Banana", text), "Blueberry");
  assert.equal(findNextMatch(ITEMS, "bbb", "Blueberry", text), "Banana");
  // A lone match never matches itself.
  assert.equal(findNextMatch(ITEMS, "cc", "Cherry", text), undefined);
});

test("Typeahead buffers keys and clears the search after the timeout", async () => {
  const typeahead = new Typeahead({ timeout: 50 });
  const matches = [];
  const feed = (value, current = null) =>
    typeahead.handleKey(key(value), {
      items: ITEMS,
      current,
      getText: text,
      onMatch: (item) => matches.push(item),
    });

  assert.equal(feed("b"), true);
  assert.equal(feed("l", "Banana"), true);
  assert.equal(typeahead.search, "bl");
  assert.deepEqual(matches, ["Banana", "Blueberry"]);

  await waitFor(() => !typeahead.isSearching);
  assert.equal(typeahead.search, "");

  typeahead.destroy();
});

test("Typeahead ignores Space until a search has started, then consumes it", () => {
  const typeahead = new Typeahead();
  const options = { items: ITEMS, getText: text, onMatch: () => {} };

  const idle = key(" ");
  assert.equal(typeahead.handleKey(idle, options), false);
  assert.equal(idle.defaultPrevented, false);
  assert.equal(typeahead.isSearching, false);

  typeahead.handleKey(key("b"), options);
  const searching = key(" ");
  assert.equal(typeahead.handleKey(searching, options), true);
  assert.equal(searching.defaultPrevented, true);
  assert.equal(typeahead.search, "b ");

  typeahead.destroy();
});

test("Typeahead ignores modified and non-printable keys", () => {
  const typeahead = new Typeahead();
  const options = { items: ITEMS, getText: text, onMatch: () => {} };

  assert.equal(
    typeahead.handleKey(key("b", { ctrlKey: true }), options),
    false,
  );
  assert.equal(
    typeahead.handleKey(key("b", { metaKey: true }), options),
    false,
  );
  assert.equal(typeahead.handleKey(key("ArrowDown"), options), false);
  assert.equal(typeahead.isSearching, false);

  typeahead.destroy();
});
