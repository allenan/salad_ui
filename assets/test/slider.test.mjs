import assert from "node:assert/strict";
import { after, before, test } from "node:test";

import SliderComponent from "../salad_ui/components/slider.js";
import { installDom, setRect, uninstallDom } from "./helpers/dom.mjs";

before(() => installDom());
after(() => uninstallDom());

function buildSlider({
  value = 20,
  min = 10,
  max = 50,
  step = 5,
  disabled = false,
  orientation = "horizontal",
  dir = "ltr",
  inverted = false,
  minStepsBetweenThumbs = 0,
  name = "scale",
} = {}) {
  const values = Array.isArray(value) ? value : [value];
  const inputName = values.length > 1 ? `${name}[]` : name;
  const thumbs = values
    .map(
      (_v, i) =>
        `<span data-part="thumb" data-index="${i}" role="slider" ${
          disabled ? "" : 'tabindex="0"'
        }></span>`,
    )
    .join("");
  const inputs = values
    .map(
      (v, i) =>
        `<input type="hidden" data-index="${i}" name="${inputName}" value="${v}" />`,
    )
    .join("");

  document.body.innerHTML = `
    <form id="form">
      <div
        id="slider"
        data-component="slider"
        data-state="idle"
        data-value="${values.join(",")}"
        data-options='${JSON.stringify({
          min,
          max,
          step,
          disabled,
          orientation,
          dir,
          inverted,
          minStepsBetweenThumbs,
        })}'
        data-event-mappings='{"value-changed":"slider_changed"}'
        data-part="root"
      >
        <span data-part="track"><span data-part="range"></span></span>
        ${thumbs}
        ${inputs}
      </div>
    </form>
  `;

  const el = document.getElementById("slider");
  const track = el.querySelector('[data-part="track"]');
  if (orientation === "vertical") {
    setRect(track, { top: 0, bottom: 100, height: 100, width: 6 });
  } else {
    setRect(track, { left: 0, right: 100, width: 100, height: 6 });
  }
  el.querySelectorAll('[data-part="thumb"]').forEach((thumb) =>
    setRect(thumb, { width: 20, height: 20 }),
  );

  const pushed = [];
  const hookContext = {
    pushEventTo(_el, event, payload) {
      pushed.push({ event, payload });
    },
  };

  const slider = new SliderComponent(el, hookContext);
  slider.setupEvents();

  const thumbEls = Array.from(el.querySelectorAll('[data-part="thumb"]'));
  const inputEls = Array.from(el.querySelectorAll('input[type="hidden"]'));

  return { el, slider, pushed, thumbs: thumbEls, inputs: inputEls };
}

function key(target, keyName, extra = {}) {
  const event = new window.KeyboardEvent("keydown", {
    key: keyName,
    bubbles: true,
    cancelable: true,
    ...extra,
  });
  target.dispatchEvent(event);
  return event;
}

test("ARIA lives on each thumb, not on the root", () => {
  const { el, thumbs } = buildSlider({ value: [20, 40] });

  assert.equal(el.hasAttribute("role"), false);
  assert.equal(thumbs.length, 2);
  assert.equal(thumbs[0].getAttribute("role"), "slider");
  assert.equal(thumbs[0].getAttribute("aria-valuemin"), "10");
  assert.equal(thumbs[0].getAttribute("aria-valuemax"), "50");
  assert.equal(thumbs[0].getAttribute("aria-valuenow"), "20");
  assert.equal(thumbs[1].getAttribute("aria-valuenow"), "40");
  assert.equal(thumbs[1].getAttribute("aria-orientation"), "horizontal");
});

test("pointer updates use min-relative step snapping and sync hidden input", () => {
  const { el, slider, pushed, thumbs } = buildSlider({
    min: 10,
    max: 50,
    step: 7,
    value: 10,
  });

  slider.updateValues(
    slider.valueFromPointer(
      new window.MouseEvent("mousemove", { clientX: 50 }),
    ),
    0,
  );

  assert.equal(slider.value, 31);
  assert.equal(el.querySelector('input[type="hidden"]').value, "31");
  assert.equal(thumbs[0].getAttribute("aria-valuenow"), "31");
  assert.equal(pushed.length, 0);
});

test("keyboard on a thumb syncs input, prevents default, and pushes a scalar value", () => {
  const { thumbs, inputs, pushed } = buildSlider({ value: 20, step: 5 });
  const targets = [];
  inputs[0].addEventListener("change", (event) => targets.push(event.target));

  const event = key(thumbs[0], "ArrowRight");

  assert.equal(event.defaultPrevented, true);
  assert.equal(inputs[0].value, "25");
  assert.equal(pushed[0].event, "slider_changed");
  assert.equal(pushed[0].payload.value, 25);
  assert.deepEqual(pushed[0].payload.values, [25]);
  // LiveView only forwards phx-change from form-associated event targets.
  assert.deepEqual(targets, [inputs[0]]);
});

test("each thumb is driven independently and pushes the value list", () => {
  const { thumbs, inputs, pushed } = buildSlider({
    value: [20, 40],
    min: 0,
    max: 100,
    step: 5,
  });

  key(thumbs[1], "ArrowLeft");
  assert.deepEqual(
    inputs.map((i) => i.value),
    ["20", "35"],
  );
  assert.deepEqual(pushed.at(-1).payload.value, [20, 35]);

  key(thumbs[0], "ArrowUp");
  assert.deepEqual(
    inputs.map((i) => i.value),
    ["25", "35"],
  );
  assert.equal(thumbs[0].getAttribute("aria-valuenow"), "25");
  assert.equal(thumbs[1].getAttribute("aria-valuenow"), "35");
});

test("Shift+arrow and PageUp/PageDown move by ten steps", () => {
  const { thumbs, inputs } = buildSlider({
    value: 50,
    min: 0,
    max: 100,
    step: 1,
  });

  key(thumbs[0], "ArrowRight", { shiftKey: true });
  assert.equal(inputs[0].value, "60");
  key(thumbs[0], "PageDown");
  assert.equal(inputs[0].value, "50");
  key(thumbs[0], "PageUp");
  assert.equal(inputs[0].value, "60");
});

test("Home and End move the focused thumb and keep exact boundaries", () => {
  const { thumbs, inputs, pushed } = buildSlider({
    min: 0,
    max: 10,
    step: 3,
    value: 6,
  });

  const endEvent = key(thumbs[0], "End");
  assert.equal(endEvent.defaultPrevented, true);
  assert.equal(inputs[0].value, "10");
  assert.equal(thumbs[0].getAttribute("aria-valuenow"), "10");
  assert.equal(pushed.at(-1).payload.value, 10);

  const homeEvent = key(thumbs[0], "Home");
  assert.equal(homeEvent.defaultPrevented, true);
  assert.equal(inputs[0].value, "0");
  assert.equal(pushed.at(-1).payload.value, 0);
});

test("thumbs can cross: values stay sorted and focus follows the moved thumb", () => {
  const { thumbs, inputs, slider } = buildSlider({
    value: [40, 45],
    min: 0,
    max: 100,
    step: 5,
  });

  thumbs[0].focus();
  key(thumbs[0], "ArrowRight");
  key(thumbs[0], "ArrowRight");

  assert.deepEqual(slider.values, [45, 50]);
  assert.deepEqual(
    inputs.map((i) => i.value),
    ["45", "50"],
  );
  assert.equal(document.activeElement, thumbs[1]);
});

test("min-steps-between-thumbs blocks moves that bring thumbs too close", () => {
  const { thumbs, slider, pushed } = buildSlider({
    value: [40, 50],
    min: 0,
    max: 100,
    step: 5,
    minStepsBetweenThumbs: 2,
  });

  key(thumbs[0], "ArrowRight");
  assert.deepEqual(slider.values, [40, 50]);
  assert.equal(pushed.length, 0);

  key(thumbs[0], "ArrowLeft");
  assert.deepEqual(slider.values, [35, 50]);
});

test("fractional steps produce clean decimals", () => {
  const { thumbs, inputs, pushed } = buildSlider({
    value: [0.3, 0.7],
    min: 0,
    max: 1,
    step: 0.1,
  });

  key(thumbs[0], "ArrowRight");
  key(thumbs[1], "ArrowLeft");
  key(thumbs[1], "ArrowLeft");

  assert.deepEqual(
    inputs.map((i) => i.value),
    ["0.4", "0.5"],
  );
  assert.deepEqual(pushed.at(-1).payload.values, [0.4, 0.5]);
  assert.equal(thumbs[0].getAttribute("aria-valuenow"), "0.4");
});

test("range spans between the outer thumbs and thumbs stay in bounds", () => {
  const { el, thumbs } = buildSlider({
    value: [25, 75],
    min: 0,
    max: 100,
  });
  const range = el.querySelector('[data-part="range"]');

  assert.equal(range.style.left, "25%");
  assert.equal(range.style.right, "25%");
  // 20px thumb: offset = 10 * (1 - 25/50) = 5px
  assert.equal(thumbs[0].style.left, "calc(25% + 5px)");
  assert.equal(thumbs[0].style.transform, "translateX(-50%)");
});

test("single thumb range fills from the start edge", () => {
  const { el } = buildSlider({ value: 30, min: 0, max: 100 });
  const range = el.querySelector('[data-part="range"]');

  assert.equal(range.style.left, "0%");
  assert.equal(range.style.right, "70%");
});

test("vertical slider positions from the bottom and maps pointer Y", () => {
  const { el, slider, thumbs } = buildSlider({
    value: 50,
    min: 0,
    max: 100,
    step: 1,
    orientation: "vertical",
  });
  const range = el.querySelector('[data-part="range"]');

  assert.equal(range.style.bottom, "0%");
  assert.equal(range.style.top, "50%");
  assert.equal(thumbs[0].style.bottom, "calc(50% + 0px)");
  assert.equal(thumbs[0].style.transform, "translateY(50%)");
  assert.equal(thumbs[0].getAttribute("aria-orientation"), "vertical");

  // 20px from the top of a 100px track is 80% from the bottom.
  assert.equal(
    slider.valueFromPointer(
      new window.MouseEvent("mousedown", { clientY: 20 }),
    ),
    80,
  );

  key(thumbs[0], "ArrowUp");
  assert.equal(slider.value, 51);
});

test("rtl flips horizontal direction and arrow keys", () => {
  const { slider, thumbs } = buildSlider({
    value: 50,
    min: 0,
    max: 100,
    step: 1,
    dir: "rtl",
  });

  assert.equal(thumbs[0].style.right, "calc(50% + 0px)");
  assert.equal(
    slider.valueFromPointer(
      new window.MouseEvent("mousedown", { clientX: 20 }),
    ),
    80,
  );

  key(thumbs[0], "ArrowLeft");
  assert.equal(slider.value, 51);
  key(thumbs[0], "ArrowRight");
  key(thumbs[0], "ArrowRight");
  assert.equal(slider.value, 49);
});

test("pointer down on the track moves the closest thumb and commits on release", () => {
  const { el, slider, pushed, thumbs } = buildSlider({
    value: [20, 80],
    min: 0,
    max: 100,
    step: 1,
  });
  const track = el.querySelector('[data-part="track"]');

  track.dispatchEvent(
    new window.MouseEvent("mousedown", {
      clientX: 70,
      bubbles: true,
      cancelable: true,
    }),
  );
  assert.equal(slider.state, "dragging");
  assert.deepEqual(slider.values, [20, 70]);
  assert.equal(document.activeElement, thumbs[1]);

  document.dispatchEvent(
    new window.MouseEvent("mousemove", { clientX: 60, bubbles: true }),
  );
  document.dispatchEvent(new window.MouseEvent("mouseup", { bubbles: true }));

  assert.equal(slider.state, "idle");
  assert.deepEqual(slider.values, [20, 60]);
  assert.equal(pushed.length, 1);
  assert.deepEqual(pushed[0].payload.value, [20, 60]);
});

test("setValue command accepts a list", () => {
  const { slider, inputs } = buildSlider({
    value: [20, 40],
    min: 0,
    max: 100,
  });

  slider.handleCommand("setValue", { value: [60, 30] });

  assert.deepEqual(slider.values, [30, 60]);
  assert.deepEqual(
    inputs.map((i) => i.value),
    ["30", "60"],
  );
});

test("disabled slider ignores keyboard and pointer", () => {
  const { el, slider, thumbs, inputs, pushed } = buildSlider({
    disabled: true,
    value: 20,
  });

  key(thumbs[0], "ArrowRight");
  el.querySelector('[data-part="track"]').dispatchEvent(
    new window.MouseEvent("mousedown", {
      clientX: 90,
      bubbles: true,
      cancelable: true,
    }),
  );

  assert.equal(thumbs[0].hasAttribute("tabindex"), false);
  assert.equal(thumbs[0].getAttribute("aria-disabled"), "true");
  assert.equal(inputs[0].value, "20");
  assert.equal(slider.state, "idle");
  assert.equal(pushed.length, 0);
});

test("destroy removes listeners", () => {
  const { slider, thumbs, pushed } = buildSlider({ value: 20 });

  slider.destroy();
  key(thumbs[0], "ArrowRight");

  assert.equal(pushed.length, 0);
});
