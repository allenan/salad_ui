import assert from "node:assert/strict";
import { after, before, beforeEach, test } from "node:test";

import { FakeChart, registerChartStub } from "./helpers/chartjs-stub.mjs";
import { installDom, uninstallDom } from "./helpers/dom.mjs";

registerChartStub();
const {
  default: ChartComponent,
  deepMerge,
  payloadConfig,
  resolveCssColor,
} = await import("../salad_ui/components/chart.js");

before(() => installDom());
after(() => uninstallDom());
beforeEach(() => {
  FakeChart.instances.length = 0;
});

const MONTHS = [
  { month: "January", desktop: 186, mobile: 80 },
  { month: "February", desktop: 305, mobile: 200 },
  { month: "March", desktop: 237, mobile: 120 },
];

const BAR_CONFIG = {
  desktop: { label: "Desktop", color: "var(--color-desktop)" },
  mobile: { label: "Mobile", color: "var(--color-mobile)" },
};

const attr = (value) => JSON.stringify(value).replace(/'/g, "&#39;");

// Mirrors the markup chart.ex renders for chart_container/chart/
// chart_tooltip/chart_legend (classes trimmed).
function tooltipMarkup({ indicator = "dot", ...options } = {}) {
  const item = (nest) => `
    <div data-slot="chart-tooltip-item">
      <div data-slot="chart-tooltip-indicator"></div>
      <div>
        <div>
          ${nest ? '<div data-slot="chart-tooltip-nested-label"></div>' : ""}
          <span data-slot="chart-tooltip-name"></span>
        </div>
        <span data-slot="chart-tooltip-value"></span>
      </div>
    </div>`;

  return `
    <div data-slot="chart-tooltip" data-part="tooltip" hidden
      data-tooltip-options='${attr({ indicator, ...options })}'>
      <div data-slot="chart-tooltip-label"></div>
      <div data-slot="chart-tooltip-items"></div>
      <template data-slot="chart-tooltip-item-template">${item(false)}</template>
      ${
        indicator === "dot"
          ? ""
          : `<template data-slot="chart-tooltip-nested-item-template">${item(true)}</template>`
      }
    </div>`;
}

function legendMarkup(options = {}) {
  return `
    <div data-slot="chart-legend" data-part="legend"
      data-legend-options='${attr(options)}'>
      <template data-slot="chart-legend-item-template">
        <div data-slot="chart-legend-item">
          <div data-slot="chart-legend-indicator"></div>
          <span data-slot="chart-legend-label"></span>
        </div>
      </template>
    </div>`;
}

function buildChart({
  config = BAR_CONFIG,
  options = { type: "bar", index: "month" },
  data = MONTHS,
  tooltip = {},
  legend = {},
  icons = "",
  style = "--color-desktop: #2563eb; --color-mobile: #60a5fa; --chart-1: #111111; --chart-2: #222222; --muted: #eeeeee",
} = {}) {
  document.body.innerHTML = `
    <div id="visitors" data-slot="chart" data-chart="chart-visitors"
      data-component="chart" data-part="root" style="${style}"
      data-config='${attr(config)}'>
      ${icons ? `<template data-slot="chart-icons">${icons}</template>` : ""}
      <div data-slot="chart-canvas">
        <canvas data-part="canvas" tabindex="0"
          data-chart-options='${attr(options)}'
          data-chart-data='${attr(data)}'></canvas>
      </div>
      ${tooltip === false ? "" : tooltipMarkup(tooltip)}
      ${legend === false ? "" : legendMarkup(legend)}
    </div>`;

  const el = document.getElementById("visitors");
  const component = new ChartComponent(el, {});
  component.setupEvents();
  component.afterMount();

  const chart = FakeChart.instances.at(-1);
  return {
    el,
    component,
    chart,
    canvas: el.querySelector("canvas"),
    tooltipEl: el.querySelector('[data-slot="chart-tooltip"]'),
    legendEl: el.querySelector('[data-slot="chart-legend"]'),
  };
}

function legendItems(legendEl) {
  return Array.from(
    legendEl.querySelectorAll('[data-slot="chart-legend-item"]'),
  ).map((node) => ({
    label: node.querySelector('[data-slot="chart-legend-label"]').textContent,
    color: node.querySelector('[data-slot="chart-legend-indicator"]')?.style
      .backgroundColor,
  }));
}

function tooltipRows(tooltipEl) {
  return Array.from(
    tooltipEl.querySelectorAll(
      '[data-slot="chart-tooltip-items"] [data-slot="chart-tooltip-item"]',
    ),
  ).map((node) => ({
    name: node.querySelector('[data-slot="chart-tooltip-name"]').textContent,
    value: node.querySelector('[data-slot="chart-tooltip-value"]')?.textContent,
    indicator: node
      .querySelector('[data-slot="chart-tooltip-indicator"]')
      ?.style.getPropertyValue("--color-bg"),
  }));
}

function showTooltip(chart, dataPoints) {
  chart.options.plugins.tooltip.external({
    chart,
    tooltip: { opacity: 1, caretX: 5, caretY: 5, dataPoints },
  });
}

function keydown(el, key) {
  el.dispatchEvent(
    new window.KeyboardEvent("keydown", {
      key,
      bubbles: true,
      cancelable: true,
    }),
  );
}

test("resolveCssColor substitutes custom properties and fallbacks", () => {
  document.body.innerHTML = `<div id="x" style="--a: #123456; --b: var(--a)"></div>`;
  const el = document.getElementById("x");

  assert.equal(resolveCssColor("var(--a)", el), "#123456");
  assert.equal(resolveCssColor("var(--missing, red)", el), "red");
  assert.equal(resolveCssColor("#abcdef", el), "#abcdef");
});

test("payloadConfig follows shadcn's string-valued key lookup", () => {
  const config = { visitors: { label: "Visitors" }, chrome: { label: "C" } };
  const item = { name: "chrome", row: { browser: "chrome", visitors: 10 } };

  assert.equal(payloadConfig(config, item, "browser").key, "chrome");
  assert.equal(payloadConfig(config, item, "visitors").key, "visitors");
  assert.equal(payloadConfig(config, item, "name").config.label, "C");
});

test("deepMerge merges nested option maps", () => {
  assert.deepEqual(deepMerge({ a: { b: 1, c: 2 } }, { a: { c: 3 }, d: 4 }), {
    a: { b: 1, c: 3 },
    d: 4,
  });
});

test("bar chart: labels, one dataset per configured series, themed colors", () => {
  const { chart } = buildChart();

  assert.equal(chart.type, "bar");
  assert.deepEqual(chart.data.labels, ["January", "February", "March"]);
  assert.deepEqual(
    chart.data.datasets.map((d) => [d._key, d.label, d.backgroundColor]),
    [
      ["desktop", "Desktop", "#2563eb"],
      ["mobile", "Mobile", "#60a5fa"],
    ],
  );
  assert.deepEqual(chart.data.datasets[0].data, [186, 305, 237]);
  assert.equal(chart.data.datasets[0].borderRadius, 4);
  assert.equal(chart.options.plugins.legend.display, false);
  assert.equal(chart.options.plugins.tooltip.enabled, false);
  assert.equal(chart.options.scales.x.ticks.display, true);
  assert.equal(chart.options.scales.y.ticks.display, false);
  assert.equal(chart.options.scales.y.grid.display, true);
});

test("series without a configured color fall back to --chart-N", () => {
  const { chart } = buildChart({
    config: { desktop: { label: "Desktop" }, mobile: { label: "Mobile" } },
  });

  assert.deepEqual(
    chart.data.datasets.map((d) => d.backgroundColor),
    ["#111111", "#222222"],
  );
});

test("explicit series, horizontal layout, stacking and user options", () => {
  const { chart } = buildChart({
    options: {
      type: "bar",
      index: "month",
      series: ["mobile"],
      horizontal: true,
      stacked: true,
      tickChars: 3,
      options: { scales: { x: { ticks: { display: true } } } },
    },
  });

  assert.deepEqual(
    chart.data.datasets.map((d) => d._key),
    ["mobile"],
  );
  assert.equal(chart.options.indexAxis, "y");
  assert.equal(chart.options.scales.y.stacked, true);
  assert.equal(chart.options.scales.x.ticks.display, true);
  assert.equal(chart.options.scales.x.grid.drawTicks, false);
  assert.equal(chart.options.scales.y.ticks.callback("January"), "Jan");
});

test("area chart is a filled line; stacked areas fill to the previous one", () => {
  const { chart } = buildChart({
    options: { type: "area", index: "month", stacked: true },
  });

  assert.equal(chart.type, "line");
  assert.deepEqual(
    chart.data.datasets.map((d) => d.fill),
    ["origin", "-1"],
  );
  assert.match(chart.data.datasets[0].backgroundColor, /40%/);
  assert.equal(chart.data.datasets[0].tension, 0.4);
});

test("line chart honours curve and dots", () => {
  const { chart } = buildChart({
    options: { type: "line", index: "month", curve: "step", dots: true },
  });

  const [dataset] = chart.data.datasets;
  assert.equal(dataset.fill, false);
  assert.equal(dataset.stepped, "middle");
  assert.equal(dataset.pointRadius, 4);
});

test("radar chart uses a radial scale with point labels", () => {
  const { chart } = buildChart({ options: { type: "radar", index: "month" } });

  assert.equal(chart.type, "radar");
  assert.equal(chart.options.scales.r.pointLabels.display, true);
  assert.equal(chart.options.scales.r.ticks.display, false);
  assert.match(chart.data.datasets[0].backgroundColor, /60%/);
});

const BROWSERS = [
  { browser: "chrome", visitors: 275 },
  { browser: "safari", visitors: 200, fill: "var(--chart-2)" },
];

const BROWSER_CONFIG = {
  visitors: { label: "Total Visitors" },
  chrome: { label: "Chrome", color: "var(--color-desktop)" },
  safari: { label: "Safari" },
};

test("pie chart colors slices from row fill or config, donut via inner radius", () => {
  const { chart, legendEl } = buildChart({
    config: BROWSER_CONFIG,
    options: {
      type: "pie",
      dataKey: "visitors",
      nameKey: "browser",
      innerRadius: 60,
    },
    data: BROWSERS,
  });

  assert.equal(chart.type, "doughnut");
  assert.equal(chart.options.cutout, 60);
  assert.deepEqual(chart.data.labels, ["chrome", "safari"]);
  assert.deepEqual(chart.data.datasets[0].backgroundColor, [
    "#2563eb",
    "#222222",
  ]);
  assert.deepEqual(legendItems(legendEl), [
    { label: "Chrome", color: "rgb(37, 99, 235)" },
    { label: "Safari", color: "rgb(34, 34, 34)" },
  ]);
});

test("radial chart draws one ring per row, first row innermost", () => {
  const { chart, tooltipEl } = buildChart({
    config: BROWSER_CONFIG,
    options: { type: "radial", dataKey: "visitors", nameKey: "browser" },
    data: BROWSERS,
    tooltip: { hideLabel: true },
  });

  assert.equal(chart.type, "doughnut");
  assert.deepEqual(
    chart.data.datasets.map((d) => d.data),
    [
      [200, 75],
      [275, 0],
    ],
  );
  assert.equal(chart.data.datasets[0].backgroundColor[1], "#eeeeee");
  assert.equal(
    chart.options.plugins.tooltip.filter({ dataIndex: 1 }),
    false,
    "the ring's empty track has no tooltip",
  );

  showTooltip(chart, [
    { datasetIndex: 0, dataIndex: 0, dataset: chart.data.datasets[0] },
  ]);
  assert.deepEqual(tooltipRows(tooltipEl), [
    { name: "Safari", value: "200", indicator: "#222222" },
  ]);
});

test("legend lists series labels and swatch colors from the config", () => {
  const { legendEl } = buildChart();

  assert.deepEqual(legendItems(legendEl), [
    { label: "Desktop", color: "rgb(37, 99, 235)" },
    { label: "Mobile", color: "rgb(96, 165, 250)" },
  ]);
});

test("legend name_key maps row values to config labels", () => {
  const { legendEl } = buildChart({
    config: BROWSER_CONFIG,
    options: { type: "pie", dataKey: "visitors", nameKey: "browser" },
    data: BROWSERS,
    legend: { nameKey: "browser" },
  });

  assert.deepEqual(
    legendItems(legendEl).map((item) => item.label),
    ["Chrome", "Safari"],
  );
});

test("config icons replace the legend swatch unless hideIcon", () => {
  const icons = `<span data-key="desktop"><svg data-icon="monitor"></svg></span>`;

  const shown = buildChart({ icons });
  const first = shown.legendEl.querySelector('[data-slot="chart-legend-item"]');
  assert.ok(first.querySelector('svg[data-icon="monitor"]'));
  assert.equal(
    first.querySelector('[data-slot="chart-legend-indicator"]'),
    null,
  );

  const hidden = buildChart({ icons, legend: { hideIcon: true } });
  assert.equal(hidden.legendEl.querySelector("svg"), null);
});

test("tooltip shows the category label and one row per series", () => {
  const { chart, tooltipEl } = buildChart();
  assert.equal(tooltipEl.hidden, true);

  showTooltip(chart, [
    { datasetIndex: 0, dataIndex: 1, dataset: chart.data.datasets[0] },
    { datasetIndex: 1, dataIndex: 1, dataset: chart.data.datasets[1] },
  ]);

  assert.equal(tooltipEl.hidden, false);
  assert.equal(
    tooltipEl.querySelector('[data-slot="chart-tooltip-label"]').textContent,
    "February",
  );
  assert.deepEqual(tooltipRows(tooltipEl), [
    { name: "Desktop", value: "305", indicator: "#2563eb" },
    { name: "Mobile", value: "200", indicator: "#60a5fa" },
  ]);
  assert.match(tooltipEl.style.transform, /translate\(/);

  chart.options.plugins.tooltip.external({ chart, tooltip: { opacity: 0 } });
  assert.equal(tooltipEl.hidden, true);
});

test("tooltip hide_label, hide_indicator and color override", () => {
  const { chart, tooltipEl } = buildChart({
    tooltip: { hideLabel: true, hideIndicator: true, color: "#ff0000" },
  });

  showTooltip(chart, [
    { datasetIndex: 0, dataIndex: 0, dataset: chart.data.datasets[0] },
  ]);

  assert.equal(
    tooltipEl.querySelector('[data-slot="chart-tooltip-label"]').hidden,
    true,
  );
  assert.equal(tooltipRows(tooltipEl)[0].indicator, "");
});

test("a single item with a line/dashed indicator nests the label", () => {
  const { chart, tooltipEl } = buildChart({
    options: { type: "line", index: "month", series: ["desktop"] },
    tooltip: { indicator: "line" },
  });

  showTooltip(chart, [
    { datasetIndex: 0, dataIndex: 2, dataset: chart.data.datasets[0] },
  ]);

  assert.equal(
    tooltipEl.querySelector('[data-slot="chart-tooltip-label"]').hidden,
    true,
  );
  assert.equal(
    tooltipEl.querySelector('[data-slot="chart-tooltip-nested-label"]')
      .textContent,
    "March",
  );
});

test("tooltip label_key and name_key resolve through the config", () => {
  const { chart, tooltipEl } = buildChart({
    config: BROWSER_CONFIG,
    options: { type: "pie", dataKey: "visitors", nameKey: "browser" },
    data: BROWSERS,
    tooltip: { labelKey: "visitors", nameKey: "browser" },
  });

  showTooltip(chart, [
    { datasetIndex: 0, dataIndex: 0, dataset: chart.data.datasets[0] },
  ]);

  assert.equal(
    tooltipEl.querySelector('[data-slot="chart-tooltip-label"]').textContent,
    "Total Visitors",
  );
  assert.deepEqual(tooltipRows(tooltipEl), [
    { name: "Chrome", value: "275", indicator: "#2563eb" },
  ]);
});

test("arrow keys walk the categories and Escape clears", () => {
  const { chart, canvas, tooltipEl } = buildChart();

  keydown(canvas, "ArrowRight");
  assert.deepEqual(chart.calls.at(-3), [
    "setActiveElements",
    [
      { datasetIndex: 0, index: 0 },
      { datasetIndex: 1, index: 0 },
    ],
  ]);
  assert.deepEqual(chart.calls.at(-1), ["update", undefined]);

  keydown(canvas, "ArrowLeft");
  assert.deepEqual(chart.calls.at(-3)[1][0], { datasetIndex: 0, index: 2 });

  keydown(canvas, "Home");
  assert.deepEqual(chart.calls.at(-3)[1][0], { datasetIndex: 0, index: 0 });

  tooltipEl.hidden = false;
  keydown(canvas, "Escape");
  assert.deepEqual(chart.calls.at(-3), ["setActiveElements", []]);
  assert.equal(tooltipEl.hidden, true);
});

test("under RTL, ArrowLeft moves forward and ArrowRight moves back", () => {
  const { el, chart, canvas } = buildChart();
  el.setAttribute("dir", "rtl");

  keydown(canvas, "ArrowLeft");
  assert.deepEqual(chart.calls.at(-3)[1][0], { datasetIndex: 0, index: 0 });
  keydown(canvas, "ArrowLeft");
  assert.deepEqual(chart.calls.at(-3)[1][0], { datasetIndex: 0, index: 1 });
  keydown(canvas, "ArrowRight");
  assert.deepEqual(chart.calls.at(-3)[1][0], { datasetIndex: 0, index: 0 });
  keydown(canvas, "ArrowRight");
  assert.deepEqual(chart.calls.at(-3)[1][0], { datasetIndex: 0, index: 2 });

  // Up/Down keep their meaning.
  keydown(canvas, "ArrowDown");
  assert.deepEqual(chart.calls.at(-3)[1][0], { datasetIndex: 0, index: 0 });
});

test("an inherited RTL direction mirrors the axes", () => {
  document.documentElement.setAttribute("dir", "rtl");
  try {
    const { chart } = buildChart();
    assert.equal(chart.options.scales.x.reverse, true);
    assert.equal(chart.options.scales.y.position, "right");

    const horizontal = buildChart({
      options: { type: "bar", index: "month", horizontal: true },
    }).chart;
    assert.equal(horizontal.options.scales.x.reverse, true);
    assert.equal(horizontal.options.scales.y.position, "right");
  } finally {
    document.documentElement.removeAttribute("dir");
  }

  const { chart } = buildChart();
  assert.equal(chart.options.scales.x.reverse, false);
  assert.equal(chart.options.scales.y.position, "left");
});

test("LiveView patch with unchanged attributes keeps the chart and repairs it", () => {
  const { el, component, chart, legendEl } = buildChart();

  // morphdom drops JS-rendered children and canvas attributes
  legendEl
    .querySelectorAll('[data-slot="chart-legend-item"]')
    .forEach((node) => node.remove());

  assert.equal(component.skipReinitialize(el), true);
  assert.deepEqual(chart.calls.at(-1), ["resize"]);
  assert.equal(legendItems(legendEl).length, 2);
});

test("LiveView patch with new data updates the chart in place", () => {
  const { el, component, chart, canvas } = buildChart();

  canvas.setAttribute(
    "data-chart-data",
    JSON.stringify([{ month: "July", desktop: 1, mobile: 2 }]),
  );

  assert.equal(component.skipReinitialize(el), true);
  assert.deepEqual(chart.data.labels, ["July"]);
  assert.deepEqual(chart.calls.at(-1), ["update", undefined]);
  assert.equal(FakeChart.instances.length, 1);
});

test("LiveView patch that changes the chart type reinitializes", () => {
  const { el, component, canvas } = buildChart();

  canvas.setAttribute(
    "data-chart-options",
    JSON.stringify({ type: "line", index: "month" }),
  );

  assert.equal(component.skipReinitialize(el), false);
});

test("update command replaces the rows", () => {
  const { component, chart } = buildChart();

  component.handleCommand("update", {
    data: [{ month: "Q1", desktop: 9, mobile: 8 }],
  });

  assert.deepEqual(chart.data.labels, ["Q1"]);
  assert.deepEqual(chart.data.datasets[0].data, [9]);
});

test("rows pushed with update survive a patch that leaves the data as-is", () => {
  const { el, component, chart, tooltipEl } = buildChart({
    options: { type: "pie", dataKey: "visitors", nameKey: "browser" },
    config: { chrome: { label: "Chrome" }, safari: { label: "Safari" } },
    data: [{ browser: "chrome", visitors: 1 }],
  });

  component.handleCommand("update", {
    data: [
      { browser: "chrome", visitors: 5 },
      { browser: "safari", visitors: 7 },
    ],
  });

  // An unrelated re-render: the server still renders the original rows.
  assert.equal(component.skipReinitialize(el), true);
  assert.equal(component.rows.length, 2);
  assert.deepEqual(chart.data.datasets[0].data, [5, 7]);

  showTooltip(chart, [{ dataIndex: 1, dataset: chart.data.datasets[0] }]);
  assert.deepEqual(
    tooltipRows(tooltipEl).map((r) => [r.name, r.value]),
    [["Safari", "7"]],
  );
});

test("a patch re-reads tooltip and legend options", () => {
  const { el, component, chart, tooltipEl } = buildChart();

  tooltipEl.setAttribute(
    "data-tooltip-options",
    JSON.stringify({ indicator: "dot", hideLabel: true }),
  );
  assert.equal(component.skipReinitialize(el), true);

  showTooltip(chart, [
    { dataIndex: 0, dataset: chart.data.datasets[0] },
    { dataIndex: 0, dataset: chart.data.datasets[1] },
  ]);
  assert.equal(
    tooltipEl.querySelector('[data-slot="chart-tooltip-label"]').hidden,
    true,
  );
});

test("destroy tears down the Chart.js instance", () => {
  const { component, chart } = buildChart();

  component.destroy();
  assert.equal(chart.destroyed, true);
});

test("legacy canvas passes raw Chart.js data and options through", () => {
  document.body.innerHTML = `
    <canvas id="legacy" data-component="chart" data-part="root"
      data-chart-type="bar"
      data-chart-options='{"responsive":true}'
      data-chart-data='{"labels":["a"],"datasets":[{"data":[1]}]}'></canvas>`;

  const el = document.getElementById("legacy");
  const component = new ChartComponent(el, {});
  component.setupEvents();
  const chart = FakeChart.instances.at(-1);

  assert.equal(chart.type, "bar");
  assert.deepEqual(chart.options, { responsive: true });
  assert.deepEqual(chart.data.labels, ["a"]);

  component.handleCommand("update", { data: { labels: ["b"] } });
  assert.deepEqual(chart.data.labels, ["b"]);
  assert.deepEqual(chart.calls.at(-1), ["update", undefined]);
});
