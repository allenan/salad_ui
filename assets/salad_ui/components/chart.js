// saladui/components/chart.js
//
// Two modes:
//
// - Container mode (`chart_container/1`): the hook root is the container
//   div. It reads the chart config (labels + colors) from `data-config`, the
//   plot from the `canvas` part, and renders shadcn's tooltip and legend into
//   the `tooltip`/`legend` parts from server-rendered <template>s, so every
//   Tailwind class lives in chart.ex.
// - Legacy mode (`chart/1` alone): the hook root is a bare <canvas> whose
//   `data-chart-data`/`data-chart-options` go to Chart.js untouched.
import Component from "../core/component.js";
import SaladUI from "../index.js";
import Chart from "chart.js/auto";

const DEFAULT_CHART_TYPE = "line";
const CATEGORICAL_TYPES = ["pie", "radial"];
const PALETTE_SIZE = 5;
const TOOLTIP_OFFSET = 10;
const VAR_PATTERN = /var\(\s*(--[\w-]+)\s*(?:,([^)]*))?\)/g;

function parseJSON(value, fallback) {
  if (!value) return fallback;
  try {
    return JSON.parse(value);
  } catch (error) {
    console.error("SaladUI chart: invalid JSON", error);
    return fallback;
  }
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

export function deepMerge(target, source) {
  if (!isPlainObject(source)) return target;
  const result = { ...target };
  Object.entries(source).forEach(([key, value]) => {
    result[key] =
      isPlainObject(value) && isPlainObject(result[key])
        ? deepMerge(result[key], value)
        : value;
  });
  return result;
}

/**
 * Substitutes `var(--name)` references in a CSS color with their computed
 * values on `el`, so Chart.js (which draws on a canvas and cannot read CSS
 * variables) receives a concrete color.
 */
export function resolveCssColor(value, el) {
  if (typeof value !== "string") return value;
  let out = value.trim();
  if (!out.includes("var(") || !el) return out;

  const style = getComputedStyle(el);
  for (let i = 0; i < 5 && out.includes("var("); i++) {
    out = out.replace(
      VAR_PATTERN,
      (_, name, fallback) =>
        style.getPropertyValue(name).trim() || (fallback ?? "").trim(),
    );
  }
  return out;
}

let colorProbe;
const PROBE_SENTINEL = "#010203";

/**
 * Normalises any CSS color (hex, hsl, oklch, ...) to `rgba()` with the given
 * alpha. Chart.js derives hover colors by parsing color strings and only
 * understands rgb/hex/hsl, so oklch tokens are converted through a 1x1 canvas.
 * Without OffscreenCanvas (e.g. jsdom) the color is returned as-is, or wrapped
 * in `color-mix()` when an alpha is requested.
 */
export function toRgba(color, alpha = 1) {
  if (typeof color !== "string" || color === "") return color;

  const Canvas = globalThis.OffscreenCanvas;
  if (typeof Canvas === "undefined") {
    return alpha === 1
      ? color
      : `color-mix(in srgb, ${color} ${Math.round(alpha * 100)}%, transparent)`;
  }

  colorProbe ??= new Canvas(1, 1).getContext("2d", {
    willReadFrequently: true,
  });
  colorProbe.fillStyle = PROBE_SENTINEL;
  colorProbe.fillStyle = color;
  if (colorProbe.fillStyle === PROBE_SENTINEL) return color;

  colorProbe.clearRect(0, 0, 1, 1);
  colorProbe.fillRect(0, 0, 1, 1);
  const [r, g, b, a] = colorProbe.getImageData(0, 0, 1, 1).data;
  return `rgba(${r}, ${g}, ${b}, ${+((a / 255) * alpha).toFixed(3)})`;
}

const hasOwn = (object, key) =>
  object != null && Object.prototype.hasOwnProperty.call(object, key);

/**
 * shadcn's getPayloadConfigFromPayload: when the item (or its data row) holds
 * a string under `key`, that string is the config key (e.g. `browser` ->
 * "chrome"); otherwise `key` itself is.
 */
export function payloadConfig(config, item, key) {
  let configKey = key;
  if (typeof item?.[key] === "string") {
    configKey = item[key];
  } else if (typeof item?.row?.[key] === "string") {
    configKey = item.row[key];
  }
  const hit = hasOwn(config, configKey) ? configKey : key;
  return { key: hit, config: config?.[hit] };
}

class ChartComponent extends Component {
  constructor(el, hookContext) {
    super(el, { hookContext });

    this.legacy = this.el.tagName === "CANVAS";
    this.activeIndex = null;
    this.pointer = null;

    if (this.legacy) {
      this.initializeLegacyChart();
    } else {
      this.readState();
      this.initializeChart();
    }
  }

  getComponentConfig() {
    const legacy = this.el.tagName === "CANVAS";

    return {
      stateMachine: {
        idle: {
          transitions: { select: "idle" },
        },
      },
      events: legacy
        ? {}
        : {
            _all: {
              keyEventTarget: "canvas",
              keyMap: {
                ArrowRight: "focusNext",
                ArrowDown: "focusNext",
                ArrowLeft: "focusPrevious",
                ArrowUp: "focusPrevious",
                Home: "focusFirst",
                End: "focusLast",
                Escape: "clearFocus",
              },
            },
          },
      // The tooltip's live-region attributes are server-rendered (chart.ex)
      // so LiveView patches keep them.
      ariaConfig: {},
    };
  }

  initConfig() {
    super.initConfig();
    this.config.preventDefaultKeys = [
      "ArrowRight",
      "ArrowDown",
      "ArrowLeft",
      "ArrowUp",
      "Home",
      "End",
    ];
  }

  // -- state ----------------------------------------------------------------

  readState() {
    this.readParts();
    this.readData();
  }

  /**
   * Config, chart options and rows. After mount, only re-read when the server
   * sent new values, so rows pushed with send_command "update" survive
   * unrelated re-renders.
   */
  readData() {
    this._configRaw = this.el.getAttribute("data-config");
    this._optionsRaw = this.canvas?.getAttribute("data-chart-options");
    this._dataRaw = this.canvas?.getAttribute("data-chart-data");

    this.chartConfig = parseJSON(this._configRaw, {});
    this.chartOptions = parseJSON(this._optionsRaw, {});
    this.rows = parseJSON(this._dataRaw, []);
  }

  /** Parts and tooltip/legend options; re-read after every LiveView patch. */
  readParts() {
    this.allParts = this.queryParts();
    this.canvas = this.getPart("canvas");
    this.tooltipEl = this.getPart("tooltip") || null;
    this.legendEl = this.getPart("legend") || null;
    this.tooltipOptions = parseJSON(
      this.tooltipEl?.getAttribute("data-tooltip-options"),
      {},
    );
    this.legendOptions = parseJSON(
      this.legendEl?.getAttribute("data-legend-options"),
      {},
    );
  }

  get type() {
    return this.chartOptions.type || DEFAULT_CHART_TYPE;
  }

  get categorical() {
    return CATEGORICAL_TYPES.includes(this.type);
  }

  // -- colors ---------------------------------------------------------------

  resolve(color, alpha = 1) {
    return toRgba(resolveCssColor(color, this.el), alpha);
  }

  paletteColor(index) {
    return `var(--chart-${(index % PALETTE_SIZE) + 1})`;
  }

  configColor(key, index) {
    return this.chartConfig[key]?.color || this.paletteColor(index);
  }

  rowColor(row, index) {
    if (row?.fill) return this.resolve(row.fill);
    const key = row?.[this.chartOptions.nameKey];
    return this.resolve(this.configColor(key, index));
  }

  labelFor(key) {
    return this.chartConfig[key]?.label ?? String(key);
  }

  // -- Chart.js config --------------------------------------------------------

  seriesKeys() {
    const { series, index } = this.chartOptions;
    if (Array.isArray(series) && series.length) return series.map(String);

    const first = this.rows[0] || {};
    const configured = Object.keys(this.chartConfig).filter(
      (key) => key !== index && hasOwn(first, key),
    );
    if (configured.length) return configured;

    return Object.keys(first).filter(
      (key) => key !== index && typeof first[key] === "number",
    );
  }

  buildDatasets() {
    const o = this.chartOptions;
    const rows = this.rows;
    this.seriesColors = new Map();

    if (this.type === "pie") {
      this.rowColors = rows.map((row, i) => this.rowColor(row, i));
      return [
        {
          _key: o.dataKey,
          data: rows.map((row) => row[o.dataKey] ?? null),
          backgroundColor: this.rowColors,
          borderWidth: 0,
          hoverOffset: 4,
        },
      ];
    }

    if (this.type === "radial") {
      this.rowColors = rows.map((row, i) => this.rowColor(row, i));
      const values = rows.map((row) => Number(row[o.dataKey]) || 0);
      const max = Math.max(...values, 0) || 1;
      const track = this.resolve("var(--muted)");
      // Chart.js draws dataset 0 as the outer ring; Recharts draws the first
      // row innermost, so build the rings in reverse.
      return rows
        .map((row, i) => ({
          _row: i,
          data: [values[i], Math.max(max - values[i], 0)],
          backgroundColor: [this.rowColors[i], track],
          hoverBackgroundColor: [this.rowColors[i], track],
          borderWidth: 0,
          borderRadius: 999,
        }))
        .reverse();
    }

    const keys = this.seriesKeys();
    return keys.map((key, i) => {
      const color = this.resolve(this.configColor(key, i));
      this.seriesColors.set(key, color);
      const data = rows.map((row) => row[key] ?? null);
      const base = { _key: key, label: this.labelFor(key), data };

      if (this.type === "bar") {
        const perRow = keys.length === 1 && rows.some((row) => row?.fill);
        return {
          ...base,
          backgroundColor: perRow
            ? rows.map((row) => (row?.fill ? this.resolve(row.fill) : color))
            : color,
          borderRadius: o.radius ?? 4,
          borderSkipped: false,
        };
      }

      if (this.type === "radar") {
        return {
          ...base,
          backgroundColor: this.resolve(this.configColor(key, i), 0.6),
          borderColor: color,
          borderWidth: o.dots ? 2 : 0,
          pointBackgroundColor: color,
          pointRadius: o.dots ? 4 : 0,
          pointHoverRadius: 4,
          fill: true,
        };
      }

      const area = this.type === "area";
      const curve = o.curve || "natural";
      return {
        ...base,
        borderColor: color,
        backgroundColor: area
          ? this.resolve(this.configColor(key, i), 0.4)
          : color,
        borderWidth: 2,
        fill: area ? (o.stacked && i > 0 ? "-1" : "origin") : false,
        tension: curve === "natural" ? 0.4 : 0,
        cubicInterpolationMode: curve === "natural" ? "monotone" : "default",
        stepped: curve === "step" ? "middle" : false,
        pointBackgroundColor: color,
        pointBorderWidth: 0,
        pointRadius: o.dots ? 4 : 0,
        pointHoverRadius: 4,
      };
    });
  }

  buildScales() {
    const o = this.chartOptions;
    const muted = this.resolve("var(--muted-foreground)");
    const border = this.resolve("var(--border)");
    const font = { family: getComputedStyle(this.el).fontFamily, size: 12 };

    if (this.type === "radar") {
      return {
        r: {
          beginAtZero: true,
          grid: { display: o.grid !== false, color: border },
          angleLines: { display: o.grid !== false, color: border },
          ticks: { display: false },
          pointLabels: { display: o.indexAxis !== false, color: muted, font },
        },
      };
    }

    if (this.categorical) return {};

    const tickChars = o.tickChars;
    const config = this.chartConfig;
    const indexScale = o.horizontal ? "y" : "x";
    const valueScale = o.horizontal ? "x" : "y";

    return {
      [indexScale]: {
        stacked: !!o.stacked,
        grid: { display: false, drawTicks: false },
        border: { display: false },
        ticks: {
          display: o.indexAxis !== false,
          color: muted,
          font,
          padding: 10,
          callback(value) {
            const raw = this.getLabelForValue
              ? this.getLabelForValue(value)
              : value;
            const label = hasOwn(config, raw)
              ? (config[raw].label ?? raw)
              : raw;
            return tickChars ? String(label).slice(0, tickChars) : label;
          },
        },
      },
      [valueScale]: {
        stacked: !!o.stacked,
        beginAtZero: true,
        grid: {
          display: o.grid !== false,
          color: this.resolve("var(--border)", 0.5),
          drawTicks: false,
        },
        border: { display: false },
        ticks: { display: !!o.valueAxis, color: muted, font, padding: 10 },
      },
    };
  }

  buildChartConfig() {
    const o = this.chartOptions;
    const type = this.type;
    const datasets = this.buildDatasets();

    let chartType = type === "area" ? "line" : type;
    if (type === "radial" || (type === "pie" && o.innerRadius)) {
      chartType = "doughnut";
    }

    const labels = this.categorical
      ? this.rows.map((row) => String(row?.[o.nameKey] ?? ""))
      : this.rows.map((row) => row?.[o.index] ?? "");

    const options = {
      responsive: true,
      maintainAspectRatio: false,
      indexAxis: o.horizontal ? "y" : "x",
      interaction: this.categorical
        ? { mode: "nearest", intersect: true }
        : { mode: "index", intersect: false },
      scales: this.buildScales(),
      plugins: {
        legend: { display: false },
        tooltip: {
          enabled: false,
          external: (context) => this.renderTooltip(context),
          filter: (item) => type !== "radial" || item.dataIndex === 0,
        },
      },
    };

    if (type === "pie") options.cutout = o.innerRadius || 0;
    if (type === "radial") options.cutout = o.innerRadius ?? "30%";

    return {
      type: chartType,
      data: { labels, datasets },
      options: deepMerge(options, o.options),
    };
  }

  initializeChart() {
    if (!this.canvas) {
      console.error("SaladUI chart: chart_container/1 is missing a chart/1");
      return;
    }
    this.chart = new Chart(this.canvas, this.buildChartConfig());
    this.renderLegend();
  }

  /** Rebuilds colors/data/options in place and animates to them. */
  refreshChart(mode) {
    if (!this.chart) return;
    const next = this.buildChartConfig();
    this.chart.data = next.data;
    this.chart.options = next.options;
    this.chart.update(mode);
    this.renderLegend();
  }

  // LiveView patches wipe what JS rendered (legend items, canvas size
  // attributes). Keep the Chart.js instance and repair/update it in place
  // unless the canvas itself or the chart type was replaced.
  skipReinitialize(el) {
    if (this.legacy || !this.chart) return false;

    const canvas = el.querySelector('canvas[data-part="canvas"]');
    if (!canvas || canvas !== this.canvas) return false;

    const nextOptions = parseJSON(
      canvas.getAttribute("data-chart-options"),
      {},
    );
    if ((nextOptions.type || DEFAULT_CHART_TYPE) !== this.type) return false;

    const changed =
      el.getAttribute("data-config") !== this._configRaw ||
      canvas.getAttribute("data-chart-options") !== this._optionsRaw ||
      canvas.getAttribute("data-chart-data") !== this._dataRaw;

    this.readParts();
    this.hideTooltip();
    this.chart.resize();
    if (changed) {
      this.readData();
      this.refreshChart();
    } else {
      this.renderLegend();
    }
    return true;
  }

  handleCommand(command, params = {}) {
    if (command !== "update") return super.handleCommand(command, params);

    if (this.legacy) {
      this.updateLegacyChart(params);
      return true;
    }

    if (Array.isArray(params.data)) this.rows = params.data;
    if (isPlainObject(params.config)) this.chartConfig = params.config;
    if (isPlainObject(params.options)) {
      this.chartOptions = deepMerge(this.chartOptions, params.options);
    }
    this.refreshChart();
    return true;
  }

  // -- payloads (shadcn's tooltip/legend item shape) -------------------------

  /** Tooltip payload for the Chart.js data points under the cursor. */
  tooltipPayload(dataPoints) {
    const o = this.chartOptions;
    if (!dataPoints?.length) return { items: [] };

    if (this.categorical) {
      const point = dataPoints[0];
      const rowIndex =
        this.type === "radial" ? point.dataset?._row : point.dataIndex;
      const row = this.rows[rowIndex];
      if (!row) return { items: [] };
      return {
        label: undefined,
        items: [this.categoricalItem(row, rowIndex)],
      };
    }

    const rowIndex = dataPoints[0].dataIndex;
    const row = this.rows[rowIndex];
    return {
      label: row?.[o.index],
      items: dataPoints
        .filter((point) => point.dataset?._key != null)
        .map((point) => {
          const key = point.dataset._key;
          return {
            name: key,
            dataKey: key,
            value: row?.[key],
            color: this.seriesColors.get(key),
            row,
          };
        }),
    };
  }

  categoricalItem(row, rowIndex) {
    const o = this.chartOptions;
    return {
      name: String(row?.[o.nameKey] ?? ""),
      dataKey: o.dataKey,
      value: row?.[o.dataKey],
      color: this.rowColors?.[rowIndex],
      row,
    };
  }

  legendPayload() {
    if (this.categorical) {
      return this.rows.map((row, i) => this.categoricalItem(row, i));
    }
    return this.seriesKeys().map((key) => ({
      name: key,
      dataKey: key,
      color: this.seriesColors?.get(key),
    }));
  }

  iconFor(key) {
    const template = Array.from(this.el.children).find(
      (child) =>
        child.tagName === "TEMPLATE" &&
        child.getAttribute("data-slot") === "chart-icons",
    );
    if (!template || key == null) return null;
    const holder = Array.from(template.content.children).find(
      (child) => child.getAttribute("data-key") === String(key),
    );
    const icon = holder?.firstElementChild;
    return icon ? icon.cloneNode(true) : null;
  }

  // -- tooltip ----------------------------------------------------------------

  tooltipLabel(payload) {
    const { hideLabel, labelKey } = this.tooltipOptions;
    if (hideLabel || !payload.items.length) return null;

    const [item] = payload.items;
    const key = `${labelKey ?? item?.dataKey ?? item?.name ?? "value"}`;
    const { config: itemConfig } = payloadConfig(this.chartConfig, item, key);
    const value =
      !labelKey && payload.label != null && payload.label !== ""
        ? (this.chartConfig[payload.label]?.label ?? String(payload.label))
        : itemConfig?.label;

    return value || null;
  }

  renderTooltip({ tooltip } = {}) {
    const el = this.tooltipEl;
    if (!el || !el.isConnected) return;

    if (!tooltip || tooltip.opacity === 0) {
      this.hideTooltip();
      return;
    }

    const payload = this.tooltipPayload(tooltip.dataPoints);
    if (!payload.items.length) {
      this.hideTooltip();
      return;
    }

    this.fillTooltip(payload);
    this.positionTooltip(tooltip);
  }

  fillTooltip(payload) {
    const el = this.tooltipEl;
    const {
      indicator = "dot",
      hideIndicator,
      nameKey,
      color,
    } = this.tooltipOptions;
    const label = this.tooltipLabel(payload);
    const nest = payload.items.length === 1 && indicator !== "dot";

    const labelEl = el.querySelector('[data-slot="chart-tooltip-label"]');
    const itemsEl = el.querySelector('[data-slot="chart-tooltip-items"]');
    const template = el.querySelector(
      nest
        ? 'template[data-slot="chart-tooltip-nested-item-template"]'
        : 'template[data-slot="chart-tooltip-item-template"]',
    );
    if (!itemsEl || !template) return;

    if (labelEl) {
      labelEl.textContent = label ?? "";
      labelEl.hidden = nest || !label;
    }

    const nodes = payload.items.map((item) => {
      const node = template.content.firstElementChild.cloneNode(true);
      const key = `${nameKey ?? item.name ?? item.dataKey ?? "value"}`;
      const { key: configKey, config: itemConfig } = payloadConfig(
        this.chartConfig,
        item,
        key,
      );
      const indicatorColor =
        color ?? (item.row?.fill ? this.resolve(item.row.fill) : item.color);

      const indicatorEl = node.querySelector(
        '[data-slot="chart-tooltip-indicator"]',
      );
      const icon = this.iconFor(configKey);
      if (icon) {
        if (indicatorEl) indicatorEl.replaceWith(icon);
        else node.prepend(icon);
      } else if (indicatorEl && !hideIndicator) {
        indicatorEl.style.setProperty("--color-bg", indicatorColor);
        indicatorEl.style.setProperty("--color-border", indicatorColor);
      }

      const nestedLabel = node.querySelector(
        '[data-slot="chart-tooltip-nested-label"]',
      );
      if (nestedLabel) {
        if (label) nestedLabel.textContent = label;
        else nestedLabel.remove();
      }

      node.querySelector('[data-slot="chart-tooltip-name"]').textContent =
        itemConfig?.label ?? item.name;

      const valueEl = node.querySelector('[data-slot="chart-tooltip-value"]');
      if (item.value == null) {
        valueEl.remove();
      } else {
        valueEl.textContent =
          typeof item.value === "number"
            ? item.value.toLocaleString()
            : String(item.value);
      }

      return node;
    });

    itemsEl.replaceChildren(...nodes);
  }

  positionTooltip(tooltip) {
    const el = this.tooltipEl;
    const box = this.el.getBoundingClientRect();
    const canvasBox = this.canvas.getBoundingClientRect();
    const point = this.pointer ?? {
      x: tooltip.caretX ?? 0,
      y: tooltip.caretY ?? 0,
    };

    el.hidden = false;

    let x = canvasBox.left - box.left + point.x + TOOLTIP_OFFSET;
    let y = canvasBox.top - box.top + point.y + TOOLTIP_OFFSET;
    if (x + el.offsetWidth > box.width) {
      x = Math.max(0, x - el.offsetWidth - TOOLTIP_OFFSET * 2);
    }
    if (y + el.offsetHeight > box.height) {
      y = Math.max(0, y - el.offsetHeight - TOOLTIP_OFFSET * 2);
    }

    el.style.transform = `translate(${Math.round(x)}px, ${Math.round(y)}px)`;
  }

  hideTooltip() {
    if (this.tooltipEl) this.tooltipEl.hidden = true;
  }

  // -- legend -----------------------------------------------------------------

  renderLegend() {
    const el = this.legendEl;
    if (!el) return;

    const template = el.querySelector(
      'template[data-slot="chart-legend-item-template"]',
    );
    el.querySelectorAll('[data-slot="chart-legend-item"]').forEach((node) =>
      node.remove(),
    );
    if (!template) return;

    const { nameKey, hideIcon } = this.legendOptions;

    this.legendPayload().forEach((item) => {
      const node = template.content.firstElementChild.cloneNode(true);
      const key = `${nameKey ?? (this.categorical ? item.name : item.dataKey) ?? "value"}`;
      const { key: configKey, config: itemConfig } = payloadConfig(
        this.chartConfig,
        item,
        key,
      );

      const swatch = node.querySelector('[data-slot="chart-legend-indicator"]');
      const icon = hideIcon ? null : this.iconFor(configKey);
      if (icon) {
        swatch.replaceWith(icon);
      } else if (item.color) {
        swatch.style.backgroundColor = item.color;
      }

      node.querySelector('[data-slot="chart-legend-label"]').textContent =
        itemConfig?.label ?? item.name;
      el.appendChild(node);
    });
  }

  // -- keyboard (shadcn's accessibilityLayer) ---------------------------------

  activeElementsAt(index) {
    if (this.type === "pie") return [{ datasetIndex: 0, index }];
    if (this.type === "radial") {
      return [{ datasetIndex: this.rows.length - 1 - index, index: 0 }];
    }
    return (this.chart?.data?.datasets || []).map((_, datasetIndex) => ({
      datasetIndex,
      index,
    }));
  }

  activate(index) {
    const count = this.rows.length;
    if (!this.chart || count === 0) return;

    this.activeIndex = ((index % count) + count) % count;
    this.pointer = null;
    const elements = this.activeElementsAt(this.activeIndex);
    this.chart.setActiveElements(elements);
    this.chart.tooltip?.setActiveElements(elements, { x: 0, y: 0 });
    this.chart.update();
  }

  focusNext() {
    this.activate(this.activeIndex == null ? 0 : this.activeIndex + 1);
  }

  focusPrevious() {
    this.activate(this.activeIndex == null ? -1 : this.activeIndex - 1);
  }

  focusFirst() {
    this.activate(0);
  }

  focusLast() {
    this.activate(this.rows.length - 1);
  }

  clearFocus() {
    this.activeIndex = null;
    if (this.chart) {
      this.chart.setActiveElements([]);
      this.chart.tooltip?.setActiveElements([], { x: 0, y: 0 });
      this.chart.update();
    }
    this.hideTooltip();
  }

  // -- events -----------------------------------------------------------------

  setupComponentEvents() {
    super.setupComponentEvents();
    if (this.legacy || !this.canvas) return;

    this.onPointerMove = (event) => {
      this.pointer = { x: event.offsetX, y: event.offsetY };
    };
    this.onPointerLeave = () => {
      this.pointer = null;
      this.hideTooltip();
    };
    this.onBlur = () => {
      if (this.activeIndex != null) this.clearFocus();
    };
    this.canvas.addEventListener("mousemove", this.onPointerMove);
    this.canvas.addEventListener("mouseleave", this.onPointerLeave);
    this.canvas.addEventListener("blur", this.onBlur);

    // Recolor when the theme flips (`.dark` on <html>, or the OS scheme).
    this.onThemeChange = () => this.refreshChart("none");
    const Observer = globalThis.MutationObserver ?? window.MutationObserver;
    if (Observer) {
      this.themeObserver = new Observer(this.onThemeChange);
      this.themeObserver.observe(document.documentElement, {
        attributes: true,
        attributeFilter: ["class", "style", "data-theme"],
      });
    }
    this.colorScheme = window.matchMedia?.("(prefers-color-scheme: dark)");
    this.colorScheme?.addEventListener?.("change", this.onThemeChange);
  }

  teardownComponentEvents() {
    super.teardownComponentEvents();
    if (this.legacy || !this.canvas) return;

    this.canvas.removeEventListener("mousemove", this.onPointerMove);
    this.canvas.removeEventListener("mouseleave", this.onPointerLeave);
    this.canvas.removeEventListener("blur", this.onBlur);
    this.themeObserver?.disconnect();
    this.themeObserver = null;
    this.colorScheme?.removeEventListener?.("change", this.onThemeChange);
    this.colorScheme = null;
  }

  beforeDestroy() {
    this.hideTooltip();
    if (this.chart) {
      this.chart.destroy();
      this.chart = null;
    }
  }

  // -- legacy -----------------------------------------------------------------

  initializeLegacyChart() {
    this.chartOptions = parseJSON(this.el.dataset.chartOptions, {});
    this.chart = new Chart(this.el, {
      type: this.el.dataset.chartType || DEFAULT_CHART_TYPE,
      data: parseJSON(this.el.dataset.chartData, {}),
      options: this.chartOptions,
    });
  }

  updateLegacyChart(payload) {
    if (!this.chart) return;
    if (payload.data) {
      this.chart.data = { ...this.chart.data, ...payload.data };
    }
    if (payload.options) {
      this.chartOptions = { ...this.chartOptions, ...payload.options };
      this.chart.options = this.chartOptions;
    }
    this.chart.update();
  }
}

// Register the component
SaladUI.register("chart", ChartComponent);

export default ChartComponent;
