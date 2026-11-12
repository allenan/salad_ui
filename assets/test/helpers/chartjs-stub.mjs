// Stand-in for `chart.js/auto` in node tests (jsdom has no canvas). Records
// every instance and the calls the chart component makes on it.
// registerChartStub() must run before salad_ui/components/chart.js is
// imported (use a dynamic import after calling it).
import { registerHooks } from "node:module";

export class FakeChart {
  static instances = [];

  constructor(canvas, config) {
    this.canvas = canvas;
    this.config = config;
    this.type = config.type;
    this.data = config.data;
    this.options = config.options;
    this.calls = [];
    this.tooltip = {
      setActiveElements: (elements, position) => {
        this.calls.push(["tooltip.setActiveElements", elements, position]);
      },
    };
    FakeChart.instances.push(this);
  }

  setActiveElements(elements) {
    this.calls.push(["setActiveElements", elements]);
  }

  update(mode) {
    this.calls.push(["update", mode]);
  }

  resize() {
    this.calls.push(["resize"]);
  }

  destroy() {
    this.destroyed = true;
    this.calls.push(["destroy"]);
  }
}

export default FakeChart;

export function registerChartStub() {
  registerHooks({
    resolve(specifier, context, nextResolve) {
      if (specifier === "chart.js/auto") {
        return { url: import.meta.url, shortCircuit: true };
      }
      return nextResolve(specifier, context);
    },
  });
}
