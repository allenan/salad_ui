import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import Menu from "../salad_ui/components/menu.js";
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());
afterEach(() => {
  document.body.innerHTML = "";
});

function buildMenu() {
  document.body.innerHTML = `
    <div id="menu-root" data-component="dropdown-menu">
      <div id="menu-content" data-part="content">
        <div data-part="item" data-value="profile" data-disabled="false" tabindex="0"
             data-event-mappings='{"select":"selected"}'>Profile</div>
        <div data-part="item" data-value="disabled" data-disabled tabindex="-1"
             data-event-mappings='{"select":"selected"}'>Disabled</div>
        <div data-part="item" data-value="settings" tabindex="0"
             data-event-mappings='{"select":"selected"}'>Settings</div>
        <a href="#profile" data-part="item" data-value="profile-link" tabindex="0"
             data-event-mappings='{"select":"selected"}'>Profile Link</a>
        <div data-part="checkbox-item" data-value="bold" data-checked="true" tabindex="0"
             data-event-mappings='{"select":"selected","checked-change":"checked"}'>
          <span data-part="item-indicator">✓</span>
          Bold
        </div>
      </div>
    </div>
  `;

  const rootEl = document.getElementById("menu-root");
  const content = document.getElementById("menu-content");
  const pushed = [];
  const selected = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
  };

  const menu = new Menu(content, {
    hookContext,
    rootEl,
    onItemSelect: (item) => selected.push(item.value),
  });

  return {
    menu,
    rootEl,
    content,
    pushed,
    selected,
    profile: content.querySelector('[data-value="profile"]'),
    disabled: content.querySelector('[data-value="disabled"]'),
    settings: content.querySelector('[data-value="settings"]'),
    link: content.querySelector('[data-value="profile-link"]'),
    checkbox: content.querySelector('[data-value="bold"]'),
  };
}

function keydown(el, key) {
  const event = new window.KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);
  return event;
}

test("activate focuses first enabled item and arrow navigation skips disabled", () => {
  const { menu, profile, settings } = buildMenu();

  menu.activate();
  assert.equal(document.activeElement, profile);

  keydown(profile, "ArrowDown");
  assert.equal(document.activeElement, settings);

  keydown(settings, "ArrowUp");
  assert.equal(document.activeElement, profile);

  menu.destroy();
});

test("Enter on regular item selects and stops key event propagation", () => {
  const { content, menu, pushed, selected, settings } = buildMenu();
  let bubbled = false;
  content.addEventListener("keydown", () => {
    bubbled = true;
  });

  const event = keydown(settings, "Enter");

  assert.equal(event.defaultPrevented, true);
  assert.equal(bubbled, false);
  assert.deepEqual(selected, ["settings"]);
  assert.equal(pushed.length, 1);
  assert.equal(pushed[0].event, "selected");
  assert.deepEqual(pushed[0].payload, {
    value: "settings",
    componentId: "menu-root",
    component: "dropdown-menu",
  });

  menu.destroy();
});

test("checkbox item exposes ARIA, toggles on Enter, and stops propagation", () => {
  const { checkbox, content, menu, pushed, selected } = buildMenu();
  let bubbled = false;
  content.addEventListener("keydown", () => {
    bubbled = true;
  });

  assert.equal(checkbox.getAttribute("role"), "menuitemcheckbox");
  assert.equal(checkbox.getAttribute("aria-checked"), "true");

  const event = keydown(checkbox, "Enter");

  assert.equal(event.defaultPrevented, true);
  assert.equal(bubbled, false);
  assert.equal(checkbox.getAttribute("data-state"), "unchecked");
  assert.equal(checkbox.getAttribute("aria-checked"), "false");
  // Toggling fires checked-change, then selectItem() closes the menu, as
  // picking any item does in Radix.
  assert.deepEqual(selected, ["bold"]);
  assert.deepEqual(
    pushed.map(({ event: eventName }) => eventName),
    ["selected", "checked"],
  );
  assert.deepEqual(pushed.at(-1).payload, {
    value: "bold",
    checked: false,
    componentId: "menu-root",
    component: "dropdown-menu",
  });

  menu.destroy();
});

test('data-close-on-select="false" keeps the menu open for every item kind', () => {
  document.body.innerHTML = `
    <div id="menu-root" data-component="dropdown-menu">
      <div id="menu-content" data-part="content">
        <div data-part="item" data-value="stay" data-close-on-select="false"
             data-event-mappings='{"select":"selected"}'>Stay</div>
        <div data-part="item" data-value="go">Go</div>
        <div data-part="checkbox-item" data-value="bold" data-state="unchecked"
             data-close-on-select="false"
             data-event-mappings='{"checked-change":"checked"}'>
          <span data-part="item-indicator" hidden>✓</span>Bold
        </div>
        <div data-part="radio-group" data-value="a"
             data-event-mappings='{"value-changed":"changed"}'>
          <div data-part="radio-item" data-value="a">
            <span data-part="item-indicator" hidden>•</span>A
          </div>
          <div data-part="radio-item" data-value="b" data-close-on-select="false">
            <span data-part="item-indicator" hidden>•</span>B
          </div>
        </div>
      </div>
    </div>
  `;

  const content = document.getElementById("menu-content");
  const pushed = [];
  const selected = [];
  const menu = new Menu(content, {
    hookContext: {
      pushEventTo: (_target, event) => pushed.push(event),
      liveSocket: { execJS: () => {} },
    },
    rootEl: document.getElementById("menu-root"),
    onItemSelect: (item) => selected.push(item.value),
  });
  const q = (value) =>
    content.querySelector(
      `:not([data-part="radio-group"])[data-value="${value}"]`,
    );

  keydown(q("stay"), "Enter");
  keydown(q("bold"), "Enter");
  keydown(q("b"), "Enter");
  assert.deepEqual(selected, [], "opted-out items never close the menu");
  assert.deepEqual(pushed, ["selected", "checked", "changed"]);
  assert.equal(q("bold").getAttribute("aria-checked"), "true");
  assert.equal(q("b").getAttribute("aria-checked"), "true");

  keydown(q("a"), "Enter");
  keydown(q("go"), "Enter");
  assert.deepEqual(selected, ["a", "go"], "the rest close it");

  menu.destroy();
});

test("a radio group without a value adopts the item rendered checked", () => {
  document.body.innerHTML = `
    <div id="menu-root" data-component="dropdown-menu">
      <div id="menu-content" data-part="content">
        <div data-part="radio-group">
          <div data-part="radio-item" data-value="a">
            <span data-part="item-indicator" hidden>•</span>A
          </div>
          <div data-part="radio-item" data-value="b" data-state="checked">
            <span data-part="item-indicator">•</span>B
          </div>
        </div>
      </div>
    </div>
  `;

  const content = document.getElementById("menu-content");
  const menu = new Menu(content, {
    hookContext: { pushEventTo: () => {}, liveSocket: { execJS: () => {} } },
    rootEl: document.getElementById("menu-root"),
  });
  const [a, b] = content.querySelectorAll('[data-part="radio-item"]');

  assert.equal(b.getAttribute("aria-checked"), "true");
  assert.equal(b.querySelector('[data-part="item-indicator"]').hidden, false);
  assert.equal(a.getAttribute("aria-checked"), "false");

  keydown(a, "Enter");
  assert.equal(a.getAttribute("aria-checked"), "true");
  assert.equal(b.getAttribute("aria-checked"), "false");

  menu.destroy();
});

test("click on link item preserves native link behavior", () => {
  const { content, link, menu, pushed, selected } = buildMenu();
  let bubbled = false;
  content.addEventListener("click", () => {
    bubbled = true;
  });

  const event = new window.MouseEvent("click", {
    bubbles: true,
    cancelable: true,
  });
  link.dispatchEvent(event);

  assert.equal(event.defaultPrevented, false);
  assert.equal(bubbled, true);
  assert.deepEqual(selected, ["profile-link"]);
  assert.equal(pushed[0].event, "selected");

  menu.destroy();
});

test("an item click bubbles to the window, so LiveView runs its phx-click", () => {
  const { menu, pushed, selected, settings } = buildMenu();
  // LiveView handles phx-click from one bubbling click listener on window.
  const seen = [];
  const onWindowClick = (event) => seen.push(event.target);
  window.addEventListener("click", onWindowClick);

  settings.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );

  window.removeEventListener("click", onWindowClick);
  assert.deepEqual(seen, [settings]);
  // The menu still selects (on-select) and closes.
  assert.deepEqual(selected, ["settings"]);
  assert.equal(pushed.length, 1);

  menu.destroy();
});

test("Enter and Space activate an item by clicking it, as in Radix", () => {
  const { menu, pushed, selected, settings, disabled } = buildMenu();
  const clicks = [];
  const onWindowClick = (event) => clicks.push(event.target);
  window.addEventListener("click", onWindowClick);

  keydown(settings, "Enter");
  keydown(settings, " ");
  keydown(disabled, "Enter");

  window.removeEventListener("click", onWindowClick);
  assert.deepEqual(clicks, [settings, settings]);
  assert.deepEqual(selected, ["settings", "settings"]);
  assert.equal(pushed.length, 2);

  menu.destroy();
});

test("a disabled item's click never reaches its phx-click", () => {
  const { menu, pushed, selected, disabled } = buildMenu();
  let reachedWindow = false;
  const onWindowClick = () => (reachedWindow = true);
  window.addEventListener("click", onWindowClick);

  disabled.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );

  window.removeEventListener("click", onWindowClick);
  assert.equal(reachedWindow, false);
  assert.deepEqual(selected, []);
  assert.equal(pushed.length, 0);

  menu.destroy();
});

test("a checkbox item toggles once per click, and the click still bubbles", () => {
  const { checkbox, content, menu } = buildMenu();
  let bubbled = 0;
  content.addEventListener("click", () => (bubbled += 1));

  checkbox.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );

  assert.equal(checkbox.getAttribute("aria-checked"), "false");
  assert.equal(bubbled, 1);

  menu.destroy();
});

function buildTypeaheadMenu() {
  document.body.innerHTML = `
    <div id="menu-root" data-component="dropdown-menu">
      <div id="menu-content" data-part="content">
        <div data-part="item" data-value="apple" tabindex="-1">Apple</div>
        <div data-part="item" data-value="banana" tabindex="-1">Banana</div>
        <div data-part="item" data-value="blueberry" tabindex="-1">Blueberry</div>
        <div data-part="item" data-value="bravo" data-disabled tabindex="-1">Bravo</div>
        <div data-part="item" data-value="cherry" data-text-value="Cherry" tabindex="-1">★ Cherry</div>
        <div data-part="checkbox-item" data-value="brown-rice" data-state="unchecked" tabindex="-1">
          <span data-part="item-indicator" hidden><svg></svg></span>Brown Rice
        </div>
      </div>
    </div>
  `;

  const content = document.getElementById("menu-content");
  const pushed = [];
  const selected = [];
  const menu = new Menu(content, {
    hookContext: {
      pushEventTo: (target, event, payload) =>
        pushed.push({ target, event, payload }),
      liveSocket: { execJS: () => {} },
    },
    rootEl: document.getElementById("menu-root"),
    onItemSelect: (item) => selected.push(item.value),
  });
  const item = (value) => content.querySelector(`[data-value="${value}"]`);

  return { menu, content, pushed, selected, item };
}

// Types at whatever has focus, like a user would.
function type(keys, init = {}) {
  for (const key of keys) {
    document.activeElement.dispatchEvent(
      new window.KeyboardEvent("keydown", {
        key,
        bubbles: true,
        cancelable: true,
        ...init,
      }),
    );
  }
}

const focusedValue = () => document.activeElement?.getAttribute("data-value");

test("typeahead focuses the next item starting with the typed text", () => {
  const { menu } = buildTypeaheadMenu();
  menu.activate();
  assert.equal(focusedValue(), "apple");

  type(["b"]);
  assert.equal(focusedValue(), "banana");

  // A longer search stays on the current item while it still matches.
  type(["l"]);
  assert.equal(focusedValue(), "blueberry");

  menu.destroy();
});

test("typeahead matches data-text-value instead of the item's text", () => {
  const { menu } = buildTypeaheadMenu();
  menu.activate();

  type(["C"], { shiftKey: true });
  assert.equal(focusedValue(), "cherry");

  menu.destroy();
});

test("typing one letter repeatedly cycles through its items, skipping disabled ones", () => {
  const { menu } = buildTypeaheadMenu();
  menu.activate();

  const seen = [];
  for (let i = 0; i < 4; i++) {
    type(["b"]);
    seen.push(focusedValue());
  }
  assert.deepEqual(seen, ["banana", "blueberry", "brown-rice", "banana"]);

  menu.destroy();
});

test("the typeahead search clears 1s after the last key", async () => {
  const { menu } = buildTypeaheadMenu();
  menu.activate();

  type(["b", "c"]);
  // "bc" matches nothing, so focus stays where "b" put it.
  assert.equal(focusedValue(), "banana");
  assert.equal(menu.typeahead.search, "bc");

  await waitFor(() => !menu.typeahead.isSearching, { timeout: 3000 });

  type(["c"]);
  assert.equal(focusedValue(), "cherry");

  menu.destroy();
});

test("a typeahead search survives the rebuild a LiveView patch causes", () => {
  const { menu, content } = buildTypeaheadMenu();
  menu.activate();

  type(["b"]);
  assert.equal(focusedValue(), "banana");

  // The hook destroys and rebuilds the component on the same element.
  menu.destroy();
  const rebuilt = new Menu(content, {
    hookContext: {
      pushEventTo: () => {},
      liveSocket: { execJS: () => {} },
    },
    rootEl: document.getElementById("menu-root"),
  });

  // "bl", not a fresh "l" (which matches nothing).
  type(["l"]);
  assert.equal(focusedValue(), "blueberry");

  rebuilt.destroy();
});

test("reopening the menu starts a fresh search", () => {
  const { menu } = buildTypeaheadMenu();
  menu.activate();

  type(["b"]);
  assert.equal(focusedValue(), "banana");

  menu.activate();
  assert.equal(menu.typeahead.isSearching, false);
  type(["c"]);
  assert.equal(focusedValue(), "cherry");

  menu.destroy();
});

test("typeahead ignores Ctrl/Alt/Meta shortcuts", () => {
  const { menu } = buildTypeaheadMenu();
  menu.activate();

  type(["b"], { ctrlKey: true });
  type(["b"], { altKey: true });
  type(["b"], { metaKey: true });
  assert.equal(focusedValue(), "apple");
  assert.equal(menu.typeahead.isSearching, false);

  menu.destroy();
});

test("Space types a space mid-search instead of activating the item", () => {
  const { menu, pushed, selected, item } = buildTypeaheadMenu();
  menu.activate();

  type(["b", "r", "o", "w", "n", " "]);
  assert.equal(focusedValue(), "brown-rice");
  assert.equal(menu.typeahead.search, "brown ");
  assert.equal(item("brown-rice").getAttribute("data-state"), "unchecked");
  assert.deepEqual(selected, []);
  assert.deepEqual(pushed, []);

  type(["r"]);
  assert.equal(focusedValue(), "brown-rice");

  menu.destroy();
});

test("Space with no search in progress still activates the item", () => {
  const { menu, selected } = buildTypeaheadMenu();
  menu.activate();

  type([" "]);
  assert.deepEqual(selected, ["apple"]);

  menu.destroy();
});
