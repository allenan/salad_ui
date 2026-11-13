import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { after, afterEach, before, beforeEach, test } from "node:test";
import { URL } from "node:url";

import "../salad_ui/components/popover.js";
import EmojiPicker, {
  valuesFrom,
  withTone,
} from "../salad_ui/components/emoji_picker.js";
import { registry } from "../salad_ui/core/factory.js";
import { installDom, setRect, uninstallDom, waitFor } from "./helpers/dom.mjs";

const DATA = JSON.parse(
  readFileSync(
    new URL("../salad_ui/components/emoji_picker/data.json", import.meta.url),
  ),
);

const TONES = [0x1f3fb, 0x1f3fc, 0x1f3fd, 0x1f3fe, 0x1f3ff].map((cp) =>
  String.fromCodePoint(cp),
);

let loads = 0;
const mounted = [];

before(() => installDom());
after(() => uninstallDom());
beforeEach(() => {
  loads = 0;
  EmojiPicker.resetData();
  EmojiPicker.loadData = async () => {
    loads += 1;
    return { default: DATA };
  };
  window.localStorage.clear();
});
afterEach(() => {
  mounted.splice(0).forEach((component) => component.destroy());
  document.body.innerHTML = "";
});

// The markup SaladUI.EmojiPicker.emoji_picker/1 renders, trimmed of classes.
function buildPicker({ options = {}, mappings = {} } = {}) {
  const close = JSON.stringify([
    ["dispatch", { event: "emoji-picker:closed", to: "#picker" }],
  ]);
  document.body.innerHTML = `
    <button id="opener" type="button" data-emoji-picker="picker"
            data-emoji-event="react" data-emoji-value-message-id="7">Add</button>
    <button id="other" type="button" data-emoji-picker="picker">Other</button>
    <button id="menu-item" type="button">More</button>
    <div id="picker" data-component="emoji-picker" data-part="root"
         data-options='${JSON.stringify(options)}'
         data-event-mappings='${JSON.stringify(mappings)}'>
      <div id="picker-popover" data-component="popover" data-state="closed"
           data-options='{"usePortal":false}'
           data-event-mappings='{"close":${close}}' data-part="root">
        <div id="picker-anchor" data-part="anchor"></div>
        <div data-part="positioner" data-side="top" data-align="end" hidden>
          <div data-part="content" aria-label="Emoji">
            <div id="picker-panel" data-slot="emoji-picker-panel">
              <input id="picker-search" data-slot="emoji-picker-search" type="search" />
              <nav data-slot="emoji-picker-nav"></nav>
              <div id="picker-grid" data-slot="emoji-picker-grid" role="listbox"></div>
              <div data-slot="emoji-picker-preview"><span></span><span></span></div>
              <div data-slot="emoji-picker-tones" hidden>
                ${[0, 1, 2, 3, 4, 5].map((t) => `<button type="button" data-tone="${t}"></button>`).join("")}
              </div>
              <button type="button" data-slot="emoji-picker-tone-button"></button>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;

  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: {
      // Enough of LiveView's JS.dispatch for the popover's on-close.
      execJS: (_el, json) => {
        for (const [op, args] of JSON.parse(json)) {
          if (op !== "dispatch") continue;
          document
            .querySelector(args.to)
            .dispatchEvent(new CustomEvent(args.event, { bubbles: true }));
        }
      },
    },
  };

  const root = document.getElementById("picker");
  const popoverEl = document.getElementById("picker-popover");
  for (const id of ["opener", "other", "menu-item"]) {
    setRect(document.getElementById(id), {
      top: 300,
      left: 100,
      width: 40,
      height: 30,
    });
  }
  setRect(popoverEl.querySelector('[data-part="positioner"]'), {
    width: 352,
    height: 380,
  });

  const popover = registry.create("popover", popoverEl, hookContext);
  const picker = registry.create("emoji-picker", root, hookContext);
  mounted.push(picker, popover);

  return {
    root,
    picker,
    popover,
    pushed,
    opener: document.getElementById("opener"),
    search: document.getElementById("picker-search"),
    grid: document.getElementById("picker-grid"),
  };
}

function click(el) {
  el.dispatchEvent(
    new window.MouseEvent("click", { bubbles: true, cancelable: true }),
  );
}

function key(el, name) {
  const event = new window.KeyboardEvent("keydown", {
    key: name,
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);
  return event;
}

function type(input, value) {
  input.value = value;
  input.dispatchEvent(new window.Event("input", { bubbles: true }));
}

const options = (grid) => [...grid.querySelectorAll('[role="option"]')];

async function openFrom(ctx, opener = ctx.opener) {
  click(opener);
  await waitFor(() => ctx.popover.state === "open");
  await waitFor(() => options(ctx.grid).length > 0);
}

test("withTone puts the modifier after the first code point, replacing U+FE0F", () => {
  assert.equal(withTone("👍", 0), "👍");
  assert.equal(withTone("👍", 3), "👍🏽");
  // ☝️ is U+261D U+FE0F: the variation selector makes way for the tone.
  assert.equal(withTone("☝️", 1), "☝🏻");
});

test("valuesFrom reads data-emoji-value-* like phx-value-*", () => {
  const el = document.createElement("button");
  el.setAttribute("data-emoji-value-message-id", "7");
  el.setAttribute("data-emoji-value-kind", "post");
  el.setAttribute("data-emoji-event", "react");
  assert.deepEqual(valuesFrom(el.dataset), { message_id: "7", kind: "post" });
});

test("every dataset entry, with every skin tone it takes, is one grapheme", () => {
  const segmenter = new Intl.Segmenter("en", { granularity: "grapheme" });
  const graphemes = (s) => [...segmenter.segment(s)].length;
  const entries = DATA.groups.flatMap((group) => group.emoji);

  assert.ok(entries.length > 1500);
  const bad = [];
  for (const [emoji, name, toned] of entries) {
    if (!name || graphemes(emoji) !== 1) bad.push(emoji);
    if (toned) {
      for (let tone = 1; tone <= 5; tone++) {
        const shown = withTone(emoji, tone);
        if (graphemes(shown) !== 1 || !TONES.some((t) => shown.includes(t))) {
          bad.push(shown);
        }
      }
    }
  }
  assert.deepEqual(bad, []);
});

test("an opener loads the dataset once and opens the popover at the opener", async () => {
  const ctx = buildPicker();
  assert.equal(loads, 0, "the dataset is not loaded until the picker opens");

  await openFrom(ctx);

  assert.equal(loads, 1);
  const anchor = document.getElementById("picker-anchor");
  assert.equal(anchor.style.top, "300px");
  assert.equal(anchor.style.width, "40px");
  assert.equal(options(ctx.grid)[0].textContent, "😀");
  assert.equal(
    ctx.search.getAttribute("aria-activedescendant"),
    options(ctx.grid)[0].id,
  );
  const nav = document.querySelector('[data-slot="emoji-picker-nav"]');
  assert.equal(nav.children.length, 1 + DATA.groups.length);
  assert.equal(
    nav.querySelector('[data-section-key="recent"]').hidden,
    true,
    "no recent emoji yet",
  );
});

test("search narrows the grid; nothing found shows the empty label", async () => {
  const ctx = buildPicker();
  await openFrom(ctx);

  type(ctx.search, "thumbs up");
  assert.equal(options(ctx.grid)[0].textContent, "👍");
  assert.equal(options(ctx.grid)[0].getAttribute("aria-label"), "thumbs up");

  type(ctx.search, "zzzz-nothing");
  assert.equal(options(ctx.grid).length, 0);
  assert.match(ctx.grid.textContent, /No emoji found\./);
});

test("Enter picks: pushes the opener's event and on-select, closes, then tells the opener", async () => {
  const ctx = buildPicker({ mappings: { select: "emoji_selected" } });
  const picks = [];
  ctx.opener.addEventListener("emoji-picker:select", (e) =>
    picks.push(e.detail),
  );
  await openFrom(ctx);

  type(ctx.search, "thumbs up");
  key(ctx.search, "Enter");

  assert.equal(ctx.popover.state, "closed");
  assert.deepEqual(
    ctx.pushed.map(({ event, payload }) => [event, payload]),
    [
      ["react", { message_id: "7", emoji: "👍" }],
      [
        "emoji_selected",
        {
          message_id: "7",
          emoji: "👍",
          name: "thumbs up",
          componentId: "picker",
          component: "emoji-picker",
        },
      ],
    ],
  );
  await waitFor(() => picks.length === 1);
  assert.deepEqual(picks[0], { emoji: "👍", name: "thumbs up" });
  assert.equal(document.activeElement, ctx.opener);
  assert.deepEqual(
    JSON.parse(window.localStorage.getItem("salad-ui:emoji-picker:recent")),
    ["👍"],
  );
});

test("recently used emoji come first on the next open", async () => {
  window.localStorage.setItem(
    "salad-ui:emoji-picker:recent",
    JSON.stringify(["🎉", "👍"]),
  );
  const ctx = buildPicker();
  await openFrom(ctx);

  const first = ctx.grid.querySelector('[role="group"]');
  assert.equal(first.dataset.section, "recent");
  assert.equal(first.textContent.startsWith("Recently used🎉👍"), true);
  assert.equal(
    document.querySelector('[data-section-key="recent"]').hidden,
    false,
  );
});

test("arrow keys move through the grid, by row across sections", async () => {
  const ctx = buildPicker();
  await openFrom(ctx);
  const cols = ctx.picker.cols;

  key(ctx.search, "ArrowRight");
  assert.equal(ctx.picker.active, 1);
  key(ctx.search, "ArrowDown");
  assert.equal(ctx.picker.active, 1 + cols);
  key(ctx.search, "ArrowUp");
  key(ctx.search, "ArrowLeft");
  key(ctx.search, "ArrowLeft");
  assert.equal(ctx.picker.active, 0, "stops at the first emoji");
  assert.equal(
    ctx.search.getAttribute("aria-activedescendant"),
    options(ctx.grid)[0].id,
  );
});

test("a click on the opener of an open picker closes it", async () => {
  const ctx = buildPicker();
  await openFrom(ctx);

  click(ctx.opener);
  await waitFor(() => ctx.popover.state === "closed");
  await new Promise((resolve) => setTimeout(resolve, 20));
  assert.equal(ctx.popover.state, "closed");
});

test("the open command opens at an anchor with an event and values", async () => {
  const ctx = buildPicker();
  ctx.root.dispatchEvent(
    new CustomEvent("salad_ui:command", {
      detail: {
        command: "open",
        params: {
          anchor: "#menu-item",
          event: "react",
          values: { message_id: "9" },
          return_focus: "#menu-item",
        },
      },
    }),
  );
  await waitFor(() => options(ctx.grid).length > 0);
  assert.equal(ctx.popover.state, "open");

  click(options(ctx.grid)[0]);
  assert.deepEqual(ctx.pushed[0].payload, { message_id: "9", emoji: "😀" });
  await waitFor(() => document.activeElement?.id === "menu-item");
});

test("a skin tone applies to the emoji that take one and is remembered", async () => {
  const ctx = buildPicker();
  await openFrom(ctx);
  const toneButton = document.querySelector(
    '[data-slot="emoji-picker-tone-button"]',
  );
  assert.equal(
    toneButton.getAttribute("aria-label"),
    "Skin tone: No skin tone",
  );

  click(toneButton);
  click(document.querySelector('[data-tone="3"]'));

  assert.equal(toneButton.getAttribute("aria-label"), "Skin tone: Medium");
  assert.equal(window.localStorage.getItem("salad-ui:emoji-picker:tone"), "3");
  type(ctx.search, "waving hand");
  assert.equal(options(ctx.grid)[0].textContent, "👋🏽");
});

test("labels override the English strings, including category names", async () => {
  const ctx = buildPicker({
    options: {
      labels: { empty: "Rien.", groups: { smileys: "Visages" } },
      storageKey: "app:emoji",
    },
  });
  await openFrom(ctx);

  assert.equal(
    document.querySelector('[data-section-key="smileys"]').title,
    "Visages",
  );
  type(ctx.search, "zzzz");
  assert.match(ctx.grid.textContent, /Rien\./);

  type(ctx.search, "");
  key(ctx.search, "Enter");
  assert.ok(window.localStorage.getItem("app:emoji:recent"));
});

test("an opener for another picker, or after destroy, does nothing", async () => {
  const ctx = buildPicker();
  const stray = document.createElement("button");
  stray.dataset.emojiPicker = "elsewhere";
  document.body.appendChild(stray);

  click(stray);
  await new Promise((resolve) => setTimeout(resolve, 20));
  assert.equal(loads, 0);

  ctx.picker.destroy();
  click(ctx.opener);
  await new Promise((resolve) => setTimeout(resolve, 20));
  assert.equal(ctx.popover.state, "closed");
});

test("a LiveView patch that leaves the options alone keeps the instance", () => {
  const ctx = buildPicker();
  assert.equal(ctx.picker.skipReinitialize(ctx.root), true);
  ctx.root.setAttribute("data-options", '{"storageKey":"other"}');
  assert.equal(ctx.picker.skipReinitialize(ctx.root), false);
});
