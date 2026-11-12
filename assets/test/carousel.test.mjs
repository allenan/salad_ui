import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
import { SaladUIHook } from "../salad_ui/core/hook.js";
import "../salad_ui/components/carousel.js";
import { installDom, uninstallDom, waitFor } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

let current = null;
afterEach(() => {
  current?.component?.destroy();
  current = null;
});

/**
 * Builds a carousel and fakes its layout: the viewport is `viewSize` px on
 * the scroll axis and each slide is `itemSize` px, laid out back to back.
 * `viewport.scrollTo` jumps immediately and fires a scroll event, like a
 * browser finishing a smooth scroll.
 */
function buildCarousel({
  id = "carousel-1",
  items = 5,
  viewSize = 100,
  itemSize = 100,
  orientation = "horizontal",
  align = "start",
  loop = false,
  autoplay = null,
  dir = null,
  itemAttrs = "",
  eventMappings = { select: "carousel_selected" },
  hookExtras = {},
} = {}) {
  // A test that builds twice must not leave the first instance's timers and
  // head <style> behind.
  current?.component?.destroy();
  const options = { orientation, align, loop, autoplay };
  const slides = Array.from(
    { length: items },
    (_, index) =>
      `<div data-part="item" role="group" aria-roledescription="slide" ${itemAttrs}>${index + 1}</div>`,
  ).join("");

  document.body.innerHTML = `
    <div id="${id}" data-component="carousel" data-part="root" data-state="idle"
         data-orientation="${orientation}"${dir ? ` dir="${dir}"` : ""}
         data-options='${JSON.stringify(options)}'
         data-event-mappings='${JSON.stringify(eventMappings)}'>
      <div data-part="viewport">
        <div data-part="content">${slides}</div>
      </div>
      <button type="button" data-part="previous" disabled>Prev</button>
      <button type="button" data-part="next" disabled>Next</button>
      <input type="text" data-test="input" />
    </div>
  `;

  const el = document.getElementById(id);
  const viewport = el.querySelector('[data-part="viewport"]');
  const vertical = orientation === "vertical";
  const rtl = dir === "rtl";
  const total = items * itemSize;
  let scroll = 0;

  const define = (target, name, get) =>
    Object.defineProperty(target, name, { configurable: true, get });

  define(viewport, vertical ? "clientHeight" : "clientWidth", () => viewSize);
  define(viewport, vertical ? "scrollHeight" : "scrollWidth", () => total);
  Object.defineProperty(viewport, vertical ? "scrollTop" : "scrollLeft", {
    configurable: true,
    get: () => (rtl ? -scroll : scroll),
    set: (value) => {
      scroll = Math.min(total - viewSize, Math.max(0, Math.abs(value)));
    },
  });
  viewport.getBoundingClientRect = () => ({
    top: 0,
    left: 0,
    right: vertical ? 100 : viewSize,
    bottom: vertical ? viewSize : 100,
    width: vertical ? 100 : viewSize,
    height: vertical ? viewSize : 100,
  });

  const scrolls = [];
  viewport.scrollTo = (opts) => {
    scrolls.push(opts);
    if (vertical) viewport.scrollTop = opts.top;
    else viewport.scrollLeft = opts.left;
    viewport.dispatchEvent(new window.Event("scroll"));
  };

  el.querySelectorAll('[data-part="item"]').forEach((item, index) => {
    item.getBoundingClientRect = () => {
      const start = index * itemSize - scroll;
      if (vertical) {
        return {
          top: start,
          bottom: start + itemSize,
          left: 0,
          right: 100,
          width: 100,
          height: itemSize,
        };
      }
      if (rtl) {
        const right = viewSize - start;
        return {
          left: right - itemSize,
          right,
          top: 0,
          bottom: 100,
          width: itemSize,
          height: 100,
        };
      }
      return {
        left: start,
        right: start + itemSize,
        top: 0,
        bottom: 100,
        width: itemSize,
        height: 100,
      };
    };
  });

  const pushed = [];
  const hookContext = {
    pushEventTo: (target, event, payload) =>
      pushed.push({ target, event, payload }),
    liveSocket: { execJS: () => {} },
    ...hookExtras,
  };

  const component = registry.create("carousel", el, hookContext);
  const prev = el.querySelector('[data-part="previous"]');
  const next = el.querySelector('[data-part="next"]');
  const input = el.querySelector('[data-test="input"]');

  // User scroll (swipe/trackpad), not through scrollTo().
  const userScroll = (position) => {
    if (vertical) viewport.scrollTop = position;
    else viewport.scrollLeft = rtl ? -position : position;
    viewport.dispatchEvent(new window.Event("scroll"));
  };

  current = { component };
  return {
    component,
    el,
    viewport,
    prev,
    next,
    input,
    pushed,
    scrolls,
    userScroll,
    position: () => scroll,
  };
}

function click(el) {
  el.dispatchEvent(new window.MouseEvent("click", { bubbles: true }));
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

test("mounts on the first slide with previous disabled and next enabled", () => {
  const { el, prev, next } = buildCarousel();

  assert.equal(prev.disabled, true);
  assert.equal(next.disabled, false);
  assert.equal(el.getAttribute("data-selected-index"), "0");
  assert.equal(el.getAttribute("data-snap-count"), "5");
});

test("labels each slide with its position unless it already has a label", () => {
  const { el } = buildCarousel({ items: 3 });
  const labels = [...el.querySelectorAll('[data-part="item"]')].map((item) =>
    item.getAttribute("aria-label"),
  );
  assert.deepEqual(labels, ["1 of 3", "2 of 3", "3 of 3"]);

  const labelled = buildCarousel({ items: 2, itemAttrs: 'aria-label="Pic"' });
  assert.equal(
    labelled.el.querySelector('[data-part="item"]').getAttribute("aria-label"),
    "Pic",
  );
});

test("snaps slide content, not the gutter padding, via a head stylesheet", () => {
  const { component, el } = buildCarousel({
    itemAttrs: 'style="padding-left: 16px"',
  });

  const style = document.head.querySelector(
    'style[data-salad-carousel="carousel-1"]',
  );
  assert.ok(style);
  assert.match(
    style.textContent,
    /\[id="carousel-1"\]>\[data-part="viewport"\]>\[data-part="content"\]>\[data-part="item"\]\{scroll-margin:0px 0px 0px -16px\}/,
  );
  // Content boxes start 16px into each 100px slide.
  assert.deepEqual(component.snaps, [16, 116, 216, 316, 400]);

  component.destroy();
  assert.equal(
    document.head.querySelector('style[data-salad-carousel="carousel-1"]'),
    null,
  );
  assert.ok(el);
});

test("next and previous scroll one snap and push select", () => {
  const { next, prev, pushed, position, scrolls } = buildCarousel();

  click(next);
  assert.equal(position(), 100);
  assert.equal(scrolls.at(-1).behavior, "smooth");
  assert.equal(prev.disabled, false);
  assert.deepEqual(pushed.at(-1).payload, {
    index: 1,
    count: 5,
    componentId: "carousel-1",
    component: "carousel",
  });
  assert.equal(pushed.at(-1).event, "carousel_selected");

  click(prev);
  assert.equal(position(), 0);
  assert.equal(prev.disabled, true);
  assert.equal(pushed.at(-1).payload.index, 0);
});

test("next is disabled on the last slide without loop", () => {
  const { component, next, pushed } = buildCarousel({ items: 3 });

  component.scrollTo(2);
  assert.equal(next.disabled, true);

  const before = pushed.length;
  component.scrollNext();
  assert.equal(component.selectedIndex, 2);
  assert.equal(pushed.length, before);
});

test("loop wraps from the last slide to the first and back", () => {
  const { component, prev, next, position } = buildCarousel({
    items: 3,
    loop: true,
  });

  assert.equal(prev.disabled, false);
  click(prev);
  assert.equal(component.selectedIndex, 2);
  assert.equal(position(), 200);
  assert.equal(next.disabled, false);

  click(next);
  assert.equal(component.selectedIndex, 0);
  assert.equal(position(), 0);
});

test("several slides per view trim the snap list like Embla", () => {
  // Five 50px slides in a 150px viewport: only three distinct positions.
  const { component, el, next } = buildCarousel({
    items: 5,
    itemSize: 50,
    viewSize: 150,
  });

  assert.deepEqual(component.snaps, [0, 50, 100]);
  assert.equal(el.getAttribute("data-snap-count"), "3");

  component.scrollTo(2);
  assert.equal(next.disabled, true);
});

test("center alignment offsets each snap by half the leftover space", () => {
  const { component } = buildCarousel({
    items: 5,
    itemSize: 50,
    viewSize: 100,
    align: "center",
  });

  // Slide centres minus half the viewport, clamped to 0..150.
  assert.deepEqual(component.snaps, [0, 25, 75, 125, 150]);
});

test("a user scroll settles on the nearest snap and pushes select", async () => {
  const { component, userScroll, pushed, prev } = buildCarousel();

  userScroll(190);
  await waitFor(() => component.selectedIndex === 2);
  assert.equal(pushed.at(-1).payload.index, 2);
  assert.equal(prev.disabled, false);
});

test("arrow keys navigate, but not from inside an input", () => {
  const { component, el, input } = buildCarousel();

  const event = keydown(el, "ArrowRight");
  assert.equal(event.defaultPrevented, true);
  assert.equal(component.selectedIndex, 1);

  keydown(el, "ArrowLeft");
  assert.equal(component.selectedIndex, 0);

  const typed = keydown(input, "ArrowRight");
  assert.equal(typed.defaultPrevented, false);
  assert.equal(component.selectedIndex, 0);
});

test("vertical carousels also take Up/Down and scroll on the y axis", () => {
  const { component, el, position, scrolls } = buildCarousel({
    orientation: "vertical",
  });

  keydown(el, "ArrowDown");
  assert.equal(component.selectedIndex, 1);
  assert.equal(position(), 100);
  assert.equal(scrolls.at(-1).top, 100);

  keydown(el, "ArrowUp");
  assert.equal(component.selectedIndex, 0);

  keydown(el, "ArrowRight");
  assert.equal(component.selectedIndex, 1);
});

test("horizontal carousels ignore Up/Down", () => {
  const { component, el } = buildCarousel();

  const event = keydown(el, "ArrowDown");
  assert.equal(event.defaultPrevented, false);
  assert.equal(component.selectedIndex, 0);
});

test("rtl flips arrow keys and scrolls with negative scrollLeft", () => {
  const { component, el, scrolls } = buildCarousel({ dir: "rtl" });

  keydown(el, "ArrowLeft");
  assert.equal(component.selectedIndex, 1);
  assert.equal(scrolls.at(-1).left, -100);

  keydown(el, "ArrowRight");
  assert.equal(component.selectedIndex, 0);
});

test("server commands next, previous and scroll_to", () => {
  const { component, el } = buildCarousel();

  const send = (command, params) =>
    el.dispatchEvent(
      new window.CustomEvent("salad_ui:command", {
        detail: { command, params },
      }),
    );

  send("next");
  assert.equal(component.selectedIndex, 1);
  send("scroll_to", { index: 4 });
  assert.equal(component.selectedIndex, 4);
  send("previous");
  assert.equal(component.selectedIndex, 3);
  send("scroll_to", { index: 99 });
  assert.equal(component.selectedIndex, 4);
});

test("a remount keeps the slide the viewport is already on", () => {
  const first = buildCarousel();
  first.component.scrollTo(3);
  const { el, viewport } = first;
  first.component.destroy();

  const again = registry.create("carousel", el, {
    pushEventTo: () => {},
    liveSocket: { execJS: () => {} },
  });
  current = { component: again };

  assert.equal(viewport.scrollLeft, 300);
  assert.equal(again.selectedIndex, 3);
  assert.equal(el.getAttribute("data-selected-index"), "3");
});

test("autoplay advances, wraps to the start, and stops on interaction", async () => {
  const { component, prev, pushed } = buildCarousel({ items: 3, autoplay: 10 });
  const indexes = () => pushed.map(({ payload }) => payload.index).join(",");

  await waitFor(() => indexes().startsWith("0,1,2,0"));

  component.scrollTo(1);
  click(prev);
  assert.equal(component.selectedIndex, 0);
  assert.equal(component.autoplayStopped, true);
  assert.equal(component.autoplayTimer, null);
});

test("autoplay pauses while hovered and resumes on leave", async () => {
  const { component, el } = buildCarousel({ items: 3, autoplay: 10 });

  el.dispatchEvent(new window.Event("pointerenter"));
  assert.equal(component.autoplayTimer, null);
  assert.equal(component.selectedIndex, 0);

  el.dispatchEvent(new window.Event("pointerleave"));
  await waitFor(() => component.selectedIndex === 1);
});

test("viewport is a polite live region unless autoplay is running", () => {
  const plain = buildCarousel();
  assert.equal(plain.viewport.getAttribute("aria-live"), "polite");

  const auto = buildCarousel({ autoplay: 1000 });
  assert.equal(auto.viewport.getAttribute("aria-live"), "off");
  auto.component.stopAutoplay();
  assert.equal(auto.viewport.getAttribute("aria-live"), "polite");
});

// A LiveView patch: morphdom resets what the JS wrote back to the server HTML
// (buttons disabled, no data-selected-index, no slide labels), then the hook's
// updated() runs.
function patchFromServer(el) {
  el.querySelectorAll('[data-part="previous"], [data-part="next"]').forEach(
    (button) => {
      button.disabled = true;
    },
  );
  el.removeAttribute("data-selected-index");
  el.removeAttribute("data-snap-count");
  el.querySelectorAll('[data-part="item"]').forEach((item) => {
    item.removeAttribute("aria-label");
    item.removeAttribute("data-auto-label");
  });
}

function hookFor(el, component) {
  return { ...SaladUIHook, el, component, handleEvent() {} };
}

test("a LiveView patch keeps the live instance, its selection and autoplay stop", () => {
  const { component, el, prev, next, pushed } = buildCarousel({
    autoplay: 10_000,
  });
  click(next);
  click(next);
  assert.equal(component.autoplayStopped, true);
  const pushes = pushed.length;

  const hook = hookFor(el, component);
  patchFromServer(el);
  hook.updated();

  assert.equal(hook.component, component);
  assert.equal(component.destroyed, false);
  assert.equal(component.selectedIndex, 2);
  assert.equal(component.autoplayStopped, true);
  assert.equal(prev.disabled, false);
  assert.equal(next.disabled, false);
  assert.equal(el.getAttribute("data-selected-index"), "2");
  assert.equal(
    el.querySelector('[data-part="item"]').getAttribute("aria-label"),
    "1 of 5",
  );
  // Restoring state is not a new selection.
  assert.equal(pushed.length, pushes);

  // Next continues from slide 3, not from wherever a rebuild would guess.
  click(next);
  assert.equal(component.selectedIndex, 3);
});

test("a patch mid smooth-scroll does not reset the selection", async () => {
  const { component, el, viewport, next, pushed } = buildCarousel();
  // A smooth scroll that hasn't moved yet.
  viewport.scrollTo = () => {};

  click(next);
  const hook = hookFor(el, component);
  patchFromServer(el);
  hook.updated();
  click(next);

  assert.equal(component.selectedIndex, 2);
  assert.deepEqual(
    pushed.map(({ payload }) => payload.index),
    [0, 1, 2],
  );
});

test("slides streamed in are relabelled, keeping a caller's own label", () => {
  const { component, el } = buildCarousel({ items: 2 });
  const content = el.querySelector('[data-part="content"]');
  content.insertAdjacentHTML(
    "beforeend",
    '<div data-part="item">3</div><div data-part="item" aria-label="Last">4</div>',
  );

  // Streamed containers don't re-patch existing children, so their old
  // "n of 2" labels are still there.
  const hook = hookFor(el, component);
  hook.updated();

  const labels = [...el.querySelectorAll('[data-part="item"]')].map((item) =>
    item.getAttribute("aria-label"),
  );
  assert.deepEqual(labels, ["1 of 4", "2 of 4", "3 of 4", "Last"]);
});

test("a patch that changes the options rebuilds the component", () => {
  const { component, el } = buildCarousel();
  const hook = hookFor(el, component);

  el.setAttribute("data-options", JSON.stringify({ loop: true }));
  hook.updated();

  assert.equal(component.destroyed, true);
  assert.notEqual(hook.component, component);
  assert.equal(hook.component.options.loop, true);
  current = { component: hook.component };
});

test("arrow keys with a modifier are left to the browser", () => {
  const { component, el } = buildCarousel();

  const event = new window.KeyboardEvent("keydown", {
    key: "ArrowRight",
    altKey: true,
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);

  assert.equal(event.defaultPrevented, false);
  assert.equal(component.selectedIndex, 0);
});

test("mount reports the starting slide and the snap count", () => {
  // Three 50px slides in a 100px viewport: two snap positions, not three.
  const { pushed } = buildCarousel({ items: 3, itemSize: 50 });

  assert.equal(pushed.length, 1);
  assert.equal(pushed[0].payload.index, 0);
  assert.equal(pushed[0].payload.count, 2);
});

test("select is pushed again when the snap count changes", () => {
  const { component, el, pushed } = buildCarousel({ items: 3 });
  const content = el.querySelector('[data-part="content"]');
  const before = pushed.length;

  // A stream inserts a slide (it has no layout in the DOM shim, so give it
  // one after the existing slides).
  content.insertAdjacentHTML("beforeend", '<div data-part="item">4</div>');
  const added = content.lastElementChild;
  added.getBoundingClientRect = () => ({
    left: 300 - component.scrollPosition(),
    right: 400 - component.scrollPosition(),
    top: 0,
    bottom: 100,
    width: 100,
    height: 100,
  });
  Object.defineProperty(component.viewport, "scrollWidth", {
    configurable: true,
    get: () => 400,
  });

  hookFor(el, component).updated();

  assert.equal(pushed.length, before + 1);
  assert.deepEqual(
    { index: pushed.at(-1).payload.index, count: pushed.at(-1).payload.count },
    { index: 0, count: 4 },
  );

  // Nothing changed: no new event.
  hookFor(el, component).updated();
  assert.equal(pushed.length, before + 1);
});

test("asks LiveView to keep the button state it writes", () => {
  const ignored = [];
  const { el, prev, next } = buildCarousel({
    hookExtras: {
      js: () => ({
        ignoreAttributes: (target, attrs) => ignored.push([target, attrs]),
      }),
    },
  });

  const find = (target) => ignored.find(([el]) => el === target)?.[1];
  assert.deepEqual(find(prev), ["disabled"]);
  assert.deepEqual(find(next), ["disabled"]);
  assert.deepEqual(find(el), ["data-selected-index", "data-snap-count"]);
  assert.deepEqual(find(el.querySelector('[data-part="viewport"]')), [
    "aria-live",
  ]);
});
