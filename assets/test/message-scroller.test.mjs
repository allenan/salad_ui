import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import "../salad_ui/components/message_scroller.js";
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

let originalRect = null;

before(() => {
  installDom();
  originalRect = window.HTMLElement.prototype.getBoundingClientRect;
});
after(() => {
  window.HTMLElement.prototype.getBoundingClientRect = originalRect;
  uninstallDom();
});

let current = null;
afterEach(() => {
  current?.component?.destroy();
  current = null;
});

/**
 * Builds a message scroller and fakes its layout: a `viewHeight` px viewport
 * whose rows (direct children of the content) stack top to bottom with the
 * height given by their `data-h` attribute. The content is `min-h-full`, the
 * tail spacer sits after it, and `scrollTo` lands immediately and fires a
 * scroll event, like a browser finishing the scroll. There is no native
 * scroll anchoring, so prepends must be corrected by the component.
 */
function build({
  rows = [],
  viewHeight = 400,
  options = {},
  eventMappings = {},
  pendingScroll = true,
  preserve = true,
  hook = true,
} = {}) {
  current?.component?.destroy();

  const opts = {
    autoScroll: false,
    defaultScrollPosition: "end",
    scrollEdgeThreshold: 8,
    scrollMargin: 0,
    scrollPreviousItemPeek: 64,
    ...options,
  };

  document.body.innerHTML = `
    <div id="chat" data-component="message-scroller" data-part="root" data-state="idle"
         data-options='${JSON.stringify(opts)}'
         data-event-mappings='${JSON.stringify(eventMappings)}'
         ${pendingScroll ? "data-pending-scroll" : ""}>
      <div data-part="viewport" role="region" aria-label="Messages" tabindex="0"
           data-preserve-scroll-on-prepend="${preserve}">
        <div data-part="content" role="log" aria-relevant="additions">
          ${rows.map(rowHtml).join("")}
        </div>
        <div data-part="spacer" aria-hidden="true" hidden></div>
      </div>
      <button type="button" data-part="scroll-button" data-direction="start"
              data-active="false" inert tabindex="-1">Up</button>
      <button type="button" data-part="scroll-button" data-direction="end"
              data-active="false" inert tabindex="-1">Down</button>
    </div>
  `;

  const el = document.getElementById("chat");
  const viewport = el.querySelector('[data-part="viewport"]');
  const content = el.querySelector('[data-part="content"]');
  const spacer = el.querySelector('[data-part="spacer"]');
  let scroll = 0;

  const rowsHeight = () =>
    Array.from(content.children).reduce(
      (sum, row) => sum + Number(row.dataset.h || 0),
      0,
    );
  const spacerHeight = () =>
    spacer.hidden ? 0 : Number.parseFloat(spacer.style.height || "0");
  const contentHeight = () => Math.max(viewHeight, rowsHeight());
  const scrollHeight = () => contentHeight() + spacerHeight();
  const clamp = (value) =>
    Math.min(Math.max(0, scrollHeight() - viewHeight), Math.max(0, value));

  Object.defineProperty(viewport, "clientHeight", {
    configurable: true,
    get: () => viewHeight,
  });
  Object.defineProperty(viewport, "scrollHeight", {
    configurable: true,
    get: scrollHeight,
  });
  Object.defineProperty(viewport, "scrollTop", {
    configurable: true,
    get: () => clamp(scroll),
    set: (value) => {
      scroll = clamp(value);
    },
  });

  const scrolls = [];
  viewport.scrollTo = (opts) => {
    scrolls.push(opts);
    viewport.scrollTop = opts.top;
    viewport.dispatchEvent(new window.Event("scroll"));
  };

  const rect = (top, height) => ({
    top,
    bottom: top + height,
    left: 0,
    right: 300,
    width: 300,
    height,
  });

  window.HTMLElement.prototype.getBoundingClientRect = function () {
    const scrollTop = viewport.scrollTop;
    if (this === viewport) return rect(0, viewHeight);
    if (this === content) return rect(-scrollTop, contentHeight());
    if (this.parentElement === content) {
      let top = 0;
      for (const row of content.children) {
        if (row === this) break;
        top += Number(row.dataset.h || 0);
      }
      return rect(top - scrollTop, Number(this.dataset.h || 0));
    }
    return rect(0, 0);
  };

  const pushed = [];
  const hookContext = hook
    ? {
        pushEventTo: (target, event, payload) =>
          pushed.push({ target, event, payload }),
        liveSocket: { execJS: () => {} },
      }
    : null;

  const component = registry.create("message-scroller", el, hookContext);
  const [startButton, endButton] = el.querySelectorAll(
    '[data-part="scroll-button"]',
  );

  current = {
    component,
    el,
    viewport,
    content,
    spacer,
    startButton,
    endButton,
    scrolls,
    pushed,
    spacerHeight,
    setScroll: (value) => {
      viewport.scrollTop = value;
      viewport.dispatchEvent(new window.Event("scroll"));
    },
    append: (...newRows) =>
      content.insertAdjacentHTML("beforeend", newRows.map(rowHtml).join("")),
    prepend: (...newRows) =>
      content.insertAdjacentHTML("afterbegin", newRows.map(rowHtml).join("")),
    row: (id) => content.querySelector(`[data-message-id="${id}"]`),
  };
  return current;
}

function rowHtml({ id, h = 100, anchor = false }) {
  return `<div data-slot="message-scroller-item" ${
    id ? `data-message-id="${id}"` : ""
  } data-scroll-anchor="${anchor}" data-h="${h}">${id || "row"}</div>`;
}

const conversation = (count, h = 100) =>
  Array.from({ length: count }, (_, index) => ({
    id: `m${index + 1}`,
    h,
    anchor: index % 2 === 0,
  }));

const pick = ({ current_anchor_id, visible_message_ids }) => ({
  current_anchor_id,
  visible_message_ids,
});

const settled = () =>
  waitFor(() => current.component.stateFrame === null).then(() =>
    waitFor(() => current.component.visibilityFrame === null),
  );

test("opens at the end and clears data-pending-scroll", () => {
  const { el, viewport, endButton, startButton } = build({
    rows: conversation(10),
  });

  assert.equal(viewport.scrollTop, 600);
  assert.equal(el.hasAttribute("data-pending-scroll"), false);
  assert.equal(el.getAttribute("data-scrollable"), "start");
  assert.equal(viewport.getAttribute("data-scrollable"), "start");
  assert.equal(endButton.getAttribute("data-active"), "false");
  assert.equal(endButton.hasAttribute("inert"), true);
  assert.equal(endButton.getAttribute("tabindex"), "-1");
  assert.equal(startButton.getAttribute("data-active"), "true");
  assert.equal(startButton.hasAttribute("inert"), false);
  assert.equal(startButton.hasAttribute("tabindex"), false);
});

test('defaultScrollPosition "start" stays at the top', () => {
  const { viewport, el, endButton } = build({
    rows: conversation(10),
    options: { defaultScrollPosition: "start" },
    pendingScroll: false,
  });

  assert.equal(viewport.scrollTop, 0);
  assert.equal(el.getAttribute("data-scrollable"), "end");
  assert.equal(endButton.getAttribute("data-active"), "true");
});

test('"last-anchor" opens at the last anchored turn with a peek above', () => {
  const { viewport } = build({
    rows: [
      ...conversation(6),
      { id: "q", h: 100, anchor: true },
      { id: "a", h: 500 },
    ],
    options: { defaultScrollPosition: "last-anchor" },
  });

  // The last turn (600px) does not fit in 400px: open at its anchor (600)
  // minus the 64px peek.
  assert.equal(viewport.scrollTop, 536);
});

test('"last-anchor" falls back to the end when the last turn fits', () => {
  const { viewport } = build({
    rows: [
      ...conversation(6),
      { id: "q", h: 100, anchor: true },
      { id: "a", h: 100 },
    ],
    options: { defaultScrollPosition: "last-anchor" },
  });

  assert.equal(viewport.scrollTop, 400);
});

test("an empty transcript clears data-pending-scroll and applies the position on first rows", async () => {
  const { el, viewport, append } = build({ rows: [] });

  assert.equal(el.hasAttribute("data-pending-scroll"), false);
  append(...conversation(8));
  await waitFor(() => viewport.scrollTop === 400);
});

test("a newly appended anchor settles near the top and holds while the reply streams", async () => {
  const { viewport, append, row, spacerHeight, component } = build({
    rows: conversation(6),
  });
  assert.equal(viewport.scrollTop, 200);

  append({ id: "q", h: 60, anchor: true }, { id: "a", h: 40 });
  // The anchor (top 600) lands at the reading line (600 - 64 peek), and the
  // tail spacer makes room for it even though the content ends at 700.
  await waitFor(() => viewport.scrollTop === 536);
  assert.equal(component.mode, "anchored-to-message");
  assert.equal(spacerHeight(), 236);
  assert.equal(row("q").getBoundingClientRect().top, 64);

  // The reply grows; the turn stays put while the spacer is consumed.
  row("a").dataset.h = "200";
  component.handleResize();
  assert.equal(viewport.scrollTop, 536);
  assert.equal(spacerHeight(), 76);
  assert.equal(row("q").getBoundingClientRect().top, 64);
});

test("with autoScroll the anchor hold hands off to following once the reply fills the viewport", async () => {
  const { viewport, append, row, spacerHeight, component } = build({
    rows: conversation(6),
    options: { autoScroll: true },
  });

  append({ id: "q", h: 60, anchor: true }, { id: "a", h: 40 });
  await waitFor(() => component.mode === "anchored-to-message");

  row("a").dataset.h = "600";
  component.handleResize();
  assert.equal(spacerHeight(), 0);
  assert.equal(component.mode, "following-bottom");
  assert.equal(viewport.scrollTop, 860);

  // Further chunks keep following.
  row("a").dataset.h = "700";
  component.handleResize();
  assert.equal(viewport.scrollTop, 960);
});

test("autoScroll follows appended rows only while at the live edge", async () => {
  const { viewport, append, endButton, component, setScroll, pushed, el } =
    build({
      rows: conversation(6).map((row) => ({ ...row, anchor: false })),
      options: { autoScroll: true },
      eventMappings: { "scrollable-change": "scrollable" },
    });
  assert.equal(viewport.scrollTop, 200);
  assert.equal(component.mode, "following-bottom");

  append({ id: "m7", h: 100 });
  await waitFor(() => viewport.scrollTop === 300);
  assert.equal(endButton.getAttribute("data-active"), "false");

  // The reader scrolls up with the wheel: follow is released.
  viewport.dispatchEvent(new window.Event("wheel"));
  setScroll(100);
  assert.equal(component.mode, "free-scrolling");
  assert.equal(endButton.getAttribute("data-active"), "true");
  assert.equal(el.getAttribute("data-scrollable"), "start end");
  const { start, end } = pushed.at(-1).payload;
  assert.deepEqual({ start, end }, { start: true, end: true });

  append({ id: "m8", h: 100 });
  await settled();
  assert.equal(viewport.scrollTop, 100);

  // The scroll button jumps back and re-engages follow.
  endButton.click();
  assert.equal(viewport.scrollTop, 400);
  assert.equal(component.mode, "following-bottom");
  assert.equal(current.scrolls.at(-1).behavior, "smooth");
  assert.equal(el.hasAttribute("data-autoscrolling"), true);
  await waitFor(() => !el.hasAttribute("data-autoscrolling"));

  append({ id: "m9", h: 100 });
  await waitFor(() => viewport.scrollTop === 500);
});

test("scroll keys on the viewport release follow-output", () => {
  const { viewport, component } = build({
    rows: conversation(6),
    options: { autoScroll: true },
  });
  assert.equal(component.mode, "following-bottom");

  viewport.dispatchEvent(
    new window.KeyboardEvent("keydown", { key: "PageUp", bubbles: true }),
  );
  assert.equal(component.mode, "free-scrolling");
});

test("prepended history keeps the first visible row in place", async () => {
  const { viewport, prepend, row, setScroll } = build({
    rows: conversation(8),
  });
  setScroll(250);
  const before = row("m3").getBoundingClientRect().top;

  prepend({ id: "h1", h: 100 }, { id: "h2", h: 150, anchor: true });
  await waitFor(() => viewport.scrollTop === 500);
  assert.equal(row("m3").getBoundingClientRect().top, before);
});

test("preserve_scroll_on_prepend=false leaves the scroll position alone", async () => {
  const { viewport, prepend, setScroll, component } = build({
    rows: conversation(8),
    preserve: false,
  });
  setScroll(250);

  prepend({ id: "h1", h: 100 });
  await waitFor(() => component.itemCount === 9);
  assert.equal(viewport.scrollTop, 250);
});

test("rows pruned from the top (stream limit) keep the reader's row in place", async () => {
  const { viewport, content, setScroll, row, component } = build({
    rows: conversation(8).map((row) => ({ ...row, anchor: false })),
  });
  setScroll(300);
  const before = row("m5").getBoundingClientRect().top;

  content.firstElementChild.remove();
  await waitFor(() => component.itemCount === 7);
  assert.equal(viewport.scrollTop, 200);
  assert.equal(row("m5").getBoundingClientRect().top, before);
});

test("replacing the last row (typing indicator) with a new turn still anchors it", async () => {
  const { viewport, content, component } = build({
    rows: [...conversation(6), { id: "typing", h: 40 }],
  });

  content.lastElementChild.remove();
  content.insertAdjacentHTML(
    "beforeend",
    rowHtml({ id: "q", h: 60, anchor: true }),
  );
  await waitFor(() => component.mode === "anchored-to-message");
  assert.equal(viewport.scrollTop, 536);
});

test("a stream reset reopens the new transcript at the default position", async () => {
  const { viewport, content, component } = build({
    rows: conversation(8),
    options: { defaultScrollPosition: "start" },
    pendingScroll: false,
  });
  current.setScroll(300);

  content.innerHTML = conversation(5)
    .map((row, index) => rowHtml({ ...row, id: `n${index}` }))
    .join("");
  await waitFor(() => component.firstItem?.dataset.messageId === "n0");
  assert.equal(viewport.scrollTop, 0);
});

test("emptying the stream then loading another transcript reopens at the default position", async () => {
  const { viewport, content, append, spacerHeight, component } = build({
    rows: conversation(6),
  });
  // An anchored turn reserves a tail spacer below it.
  append({ id: "q", h: 60, anchor: true }, { id: "a", h: 40 });
  await waitFor(() => component.mode === "anchored-to-message");
  assert.ok(spacerHeight() > 0);

  // stream(:messages, [], reset: true), then the next conversation arrives
  // (e.g. from handle_async): no stranded spacer, and it opens at the end.
  content.innerHTML = "";
  await waitFor(() => component.itemCount === 0);
  assert.equal(spacerHeight(), 0);
  assert.equal(component.mode, "free-scrolling");

  append(...conversation(8).map((row, index) => ({ ...row, id: `n${index}` })));
  await waitFor(() => component.firstItem?.dataset.messageId === "n0");
  assert.equal(viewport.scrollTop, 400);
  assert.equal(spacerHeight(), 0);
});

test("scroll_to_message command jumps to a row; unknown ids return false", () => {
  const { el, viewport, component } = build({ rows: conversation(10) });

  el.dispatchEvent(
    new window.CustomEvent("salad_ui:command", {
      detail: {
        command: "scroll_to_message",
        params: { message_id: "m3", behavior: "smooth" },
      },
    }),
  );
  assert.equal(viewport.scrollTop, 200);
  assert.equal(current.scrolls.at(-1).behavior, "smooth");
  assert.equal(component.mode, "settling-jump");

  component.handleCommand("scroll_to_message", {
    message_id: "m5",
    align: "center",
    scroll_margin: 0,
  });
  // Center a 100px row in a 400px viewport: 400 - (400 - 100) / 2.
  assert.equal(viewport.scrollTop, 250);

  assert.equal(
    component.handleCommand("scroll_to_message", { message_id: "nope" }),
    false,
  );
  assert.equal(component.handleCommand("scroll_to_start"), true);
  assert.equal(viewport.scrollTop, 0);
  assert.equal(component.handleCommand("scroll_to_end"), true);
  assert.equal(viewport.scrollTop, 600);
});

test("scroll_to_message before any rows is queued and runs when they arrive", async () => {
  const { viewport, append, component } = build({ rows: [] });

  assert.equal(component.scrollToMessage("m4"), true);
  append(...conversation(10));
  await waitFor(() => viewport.scrollTop === 300);
});

test("visibility-change reports the current anchored turn and visible rows", async () => {
  const { pushed, setScroll } = build({
    rows: conversation(10),
    options: { defaultScrollPosition: "start" },
    pendingScroll: false,
    eventMappings: { "visibility-change": "visibility" },
  });

  await waitFor(() => pushed.some((push) => push.event === "visibility"));
  let last = pushed.filter((push) => push.event === "visibility").at(-1);
  assert.equal(last.payload.componentId, "chat");
  assert.deepEqual(pick(last.payload), {
    current_anchor_id: "m1",
    visible_message_ids: ["m1", "m2", "m3", "m4"],
  });

  setScroll(250);
  await waitFor(
    () =>
      pushed.filter((push) => push.event === "visibility").at(-1).payload
        .current_anchor_id === "m3",
  );
  last = pushed.filter((push) => push.event === "visibility").at(-1);
  // The reading line is 64px below the top: m3 (200..300, at -50..50 on
  // screen) only peeks above it, and m3 is the last anchor to reach it.
  assert.deepEqual(last.payload.visible_message_ids, ["m4", "m5", "m6", "m7"]);
});

test("visibility is not tracked unless the event is mapped", async () => {
  const { pushed, setScroll, component } = build({ rows: conversation(10) });
  setScroll(100);
  await settled();
  assert.equal(component.visibilityFrame, null);
  assert.equal(
    pushed.some((push) => push.event === "visibility"),
    false,
  );
});

test("LiveView patches keep the instance and restore written attributes", () => {
  const { el, viewport, component, endButton } = build({
    rows: conversation(10),
    options: { defaultScrollPosition: "start" },
    pendingScroll: false,
  });
  assert.equal(el.getAttribute("data-scrollable"), "end");

  // morphdom reverts JS-written attributes to the server render.
  el.removeAttribute("data-scrollable");
  viewport.removeAttribute("data-scrollable");
  endButton.setAttribute("data-active", "false");
  endButton.setAttribute("inert", "");

  assert.equal(component.skipReinitialize(el), true);
  assert.equal(el.getAttribute("data-scrollable"), "end");
  assert.equal(endButton.getAttribute("data-active"), "true");
  assert.equal(endButton.hasAttribute("inert"), false);

  // A pending-scroll flag re-rendered by the server is cleared again.
  el.setAttribute("data-pending-scroll", "");
  component.skipReinitialize(el);
  assert.equal(el.hasAttribute("data-pending-scroll"), false);
});

test("an option change is applied in place", () => {
  const { el, component } = build({
    rows: conversation(6),
    options: { autoScroll: false },
  });
  assert.equal(component.mode, "free-scrolling");

  el.setAttribute(
    "data-options",
    JSON.stringify({ autoScroll: true, defaultScrollPosition: "end" }),
  );
  assert.equal(component.skipReinitialize(el), true);
  assert.equal(component.opts.autoScroll, true);
  // At the bottom with autoScroll on, the next commit arms following.
  component.commitScrollState();
  assert.equal(component.mode, "following-bottom");

  // Turning it off again stops following: appended rows stay below and the
  // end button shows them.
  el.setAttribute(
    "data-options",
    JSON.stringify({ autoScroll: false, defaultScrollPosition: "end" }),
  );
  component.skipReinitialize(el);
  assert.equal(component.mode, "free-scrolling");
  current.append({ id: "late", h: 200 });
  component.handleContentChange();
  assert.equal(current.viewport.scrollTop, 200);
  assert.equal(current.endButton.getAttribute("data-active"), "true");
});

test("changing the peek moves the visibility reading line", () => {
  const observers = [];
  window.IntersectionObserver = class {
    constructor(callback, options) {
      this.options = options;
      this.observed = new Set();
      this.disconnected = false;
      observers.push(this);
    }
    observe(element) {
      this.observed.add(element);
    }
    unobserve(element) {
      this.observed.delete(element);
    }
    disconnect() {
      this.disconnected = true;
    }
  };

  try {
    const { el, component } = build({
      rows: conversation(4),
      eventMappings: { "visibility-change": "visibility" },
    });
    assert.equal(observers.length, 1);
    assert.equal(observers[0].options.rootMargin, "-64px 0px 0px 0px");

    el.setAttribute(
      "data-options",
      JSON.stringify({ scrollPreviousItemPeek: 128, scrollMargin: 8 }),
    );
    component.skipReinitialize(el);

    assert.equal(observers[0].disconnected, true);
    assert.equal(observers.length, 2);
    assert.equal(observers[1].options.rootMargin, "-136px 0px 0px 0px");
    assert.equal(observers[1].observed.size, 4);
  } finally {
    current?.component?.destroy();
    current = null;
    delete window.IntersectionObserver;
  }
});

test("a replaced viewport forces a rebuild", () => {
  const { el, viewport, component } = build({ rows: conversation(3) });
  viewport.replaceWith(viewport.cloneNode(true));
  assert.equal(component.skipReinitialize(el), false);
});

test("inactive scroll buttons ignore clicks", () => {
  const { viewport, endButton, scrolls } = build({ rows: conversation(10) });
  const count = scrolls.length;
  endButton.click();
  assert.equal(scrolls.length, count);
  assert.equal(viewport.scrollTop, 600);
});

test("parts inside transcript rows are not collected or given data-state", () => {
  const { content, component } = build({ rows: [{ id: "m1", h: 100 }] });
  content.firstElementChild.insertAdjacentHTML(
    "beforeend",
    '<span data-part="trigger"></span>',
  );

  const parts = component.queryParts().map((part) => part.dataset.part);
  assert.deepEqual(parts.sort(), [
    "content",
    "root",
    "scroll-button",
    "scroll-button",
    "spacer",
    "viewport",
  ]);
  component.updateUI();
  assert.equal(
    content.querySelector('[data-part="trigger"]').hasAttribute("data-state"),
    false,
  );
});
