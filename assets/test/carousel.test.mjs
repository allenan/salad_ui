import assert from "node:assert/strict";
import { after, afterEach, before, test } from "node:test";

import { registry } from "../salad_ui/core/factory.js";
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

  await waitFor(() => indexes().startsWith("1,2,0"));

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
