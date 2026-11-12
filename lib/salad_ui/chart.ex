defmodule SaladUI.Chart do
  @moduledoc """
  Chart components, modelled on shadcn/ui's `chart` and rendered with
  [Chart.js](https://www.chartjs.org/).

  shadcn/ui builds charts from Recharts primitives. SaladUI keeps Chart.js as the
  renderer, but adopts shadcn's API around it:

  - `chart_container/1` - the themed wrapper. It takes a **chart config** (labels,
    colors and icons per data key), writes each color to a `--color-<key>` CSS
    variable scoped to the chart, and attaches the JavaScript hook.
  - `chart/1` - the plot itself: an `area`, `bar`, `line`, `pie`, `radar` or
    `radial` chart drawn from a list of maps, colored from the config.
  - `chart_tooltip/1` - shadcn's styled tooltip (label, indicator, name, value).
  - `chart_legend/1` - shadcn's styled legend.

  `chart/1`, `chart_tooltip/1` and `chart_legend/1` must be rendered inside a
  `chart_container/1`. The JavaScript lives in `salad_ui/components/chart` and
  imports `chart.js/auto`, so add `chart.js` to your assets' dependencies
  (`npm install chart.js`) and import the component in `app.js`:

      import "salad_ui/components/chart";

  ## Your first chart

      @chart_data [
        %{month: "January", desktop: 186, mobile: 80},
        %{month: "February", desktop: 305, mobile: 200},
        %{month: "March", desktop: 237, mobile: 120},
        %{month: "April", desktop: 73, mobile: 190},
        %{month: "May", desktop: 209, mobile: 130},
        %{month: "June", desktop: 214, mobile: 140}
      ]

      @chart_config %{
        desktop: %{label: "Desktop", color: "var(--chart-1)"},
        mobile: %{label: "Mobile", color: "var(--chart-2)"}
      }

      <.chart_container id="visitors" config={@chart_config} class="min-h-[200px] w-full">
        <.chart type="bar" data={@chart_data} index="month" tick_chars={3} />
        <.chart_tooltip />
        <.chart_legend />
      </.chart_container>

  Remember to give the container a height (`min-h-*`, `h-*` or the default
  `aspect-video`): the canvas fills it.

  ## Chart config

  The config is intentionally decoupled from the data, so it can be shared
  between charts. Each key is a data key (a series such as `desktop`) or a
  category value (such as `chrome` in a pie chart), mapped to:

  - `label` - human-readable name shown in the tooltip and legend.
  - `color` - any CSS color: `"#2563eb"`, `"hsl(220, 98%, 61%)"`,
    `"oklch(0.5 0.2 240)"` or a token such as `"var(--chart-1)"`.
  - `theme` - instead of `color`, a `%{light: ..., dark: ...}` map. The dark
    color applies under the `.dark` class.

  Icons are given as `:icon` slots on the container, keyed by config key; they
  replace the color swatch in the tooltip and legend.

  ## Using colors

  Each configured color becomes `var(--color-<key>)` inside the container, and
  series are colored with it automatically. Reference it yourself anywhere in
  the chart - in a data row's `fill` (pie, radial and single-series bars use it
  per row), or in Tailwind classes such as `fill-(--color-desktop)` on markup
  inside the container. Keys without a color fall back to `--chart-1` ...
  `--chart-5` in order.

  ## Updating

  Charts update in place, with animation, when their `data` or `config`
  assigns change. You can also push new rows from the server without
  re-rendering:

      SaladUI.LiveView.send_command(socket, "visitors", "update", %{data: rows})

  ## Raw Chart.js (legacy)

  Rendering `chart/1` on its own with `id`, `chart-type`, `chart-data` and
  `chart-options` still produces a bare Chart.js canvas: `chart-data` and
  `chart-options` are passed to `new Chart(...)` untouched.
  """
  use SaladUI, :component

  @doc """
  Themed wrapper for a chart. Scopes `--color-<key>` variables from `config`
  and hosts the JavaScript hook for the `chart/1`, `chart_tooltip/1` and
  `chart_legend/1` rendered inside it.

  ## Examples

      <.chart_container
        id="browsers"
        class="mx-auto aspect-square max-h-[250px]"
        config={%{
          visitors: %{label: "Visitors"},
          chrome: %{label: "Chrome", color: "var(--chart-1)"},
          safari: %{label: "Safari", theme: %{light: "#2563eb", dark: "#dc2626"}}
        }}
      >
        <:icon key="chrome"><Lucideicons.chrome /></:icon>
        <.chart type="pie" data={@data} data_key="visitors" name_key="browser" />
        <.chart_tooltip hide_label />
      </.chart_container>
  """
  attr :id, :string, required: true, doc: "unique id; also scopes the chart's color variables"

  attr :config, :map,
    default: %{},
    doc: "chart config: `%{key => %{label: ..., color: ... | theme: %{light: ..., dark: ...}}}`"

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true, doc: "a `chart/1`, plus optional `chart_tooltip/1` and `chart_legend/1`"

  slot :icon, doc: "icon shown for a config key in the tooltip and legend" do
    attr :key, :string, required: true, doc: "config key the icon belongs to"
  end

  def chart_container(assigns) do
    chart_id = "chart-" <> css_ident(assigns.id)

    assigns =
      assigns
      |> assign(:chart_id, chart_id)
      |> assign(:style, chart_style(chart_id, assigns.config))
      |> assign(:js_config, js_config(assigns.config))

    ~H"""
    <div
      id={@id}
      data-slot="chart"
      data-chart={@chart_id}
      data-component="chart"
      data-part="root"
      data-config={json(@js_config)}
      phx-hook="SaladUI"
      class={classes(["relative flex aspect-video flex-col justify-center text-xs", @class])}
      {@rest}
    >
      <style :if={@style}>
        <%= Phoenix.HTML.raw(@style) %>
      </style>
      <template :if={@icon != []} data-slot="chart-icons">
        <span :for={icon <- @icon} data-key={icon.key} class="contents">{render_slot(icon)}</span>
      </template>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The plot: a canvas drawn by Chart.js inside `chart_container/1`.

  `data` is a list of maps in any shape. Cartesian charts (`area`, `bar`,
  `line`) and `radar` read the category from `index` and draw one series per
  key in `series`; `pie` and `radial` draw one slice or ring per row, reading
  its value from `data_key` and its config key from `name_key`.

  ## Examples

      <.chart type="area" data={@data} index="month" series={["mobile", "desktop"]} stacked />

      <.chart type="bar" data={@data} index="month" horizontal value_axis={false} />

      <.chart type="pie" data={@data} data_key="visitors" name_key="browser" inner_radius={60} />

      <.chart type="radial" data={@data} data_key="visitors" name_key="browser" />

  When rendered without a container and given `chart-data`/`chart-options`, it
  renders a standalone raw Chart.js canvas instead (legacy API).
  """
  attr :type, :string,
    default: "line",
    values: ~w(area bar line pie radar radial),
    doc: "chart type"

  attr :data, :list, default: nil, doc: "list of maps, one per category (or slice/ring for pie and radial)"
  attr :index, :any, default: nil, doc: "key holding the category of each row (x axis; y axis for horizontal bars)"

  attr :series, :list,
    default: nil,
    doc: "keys to plot as series; defaults to every config key present in the first row"

  attr :data_key, :any, default: nil, doc: "pie/radial: key holding each row's value"
  attr :name_key, :any, default: nil, doc: "pie/radial: key holding each row's config key (e.g. `browser`)"

  attr :stacked, :boolean, default: false, doc: "stack bar/area series"
  attr :horizontal, :boolean, default: false, doc: "bar: draw horizontal bars"

  attr :curve, :string,
    default: "natural",
    values: ~w(natural linear step),
    doc: "line/area interpolation"

  attr :dots, :boolean, default: false, doc: "line/area/radar: draw a dot at each point"
  attr :grid, :boolean, default: true, doc: "draw grid lines (horizontal lines; the polar grid for radar)"
  attr :index_axis, :boolean, default: true, doc: "show the category axis labels"
  attr :value_axis, :boolean, default: false, doc: "show the value axis labels"
  attr :tick_chars, :integer, default: nil, doc: "truncate category labels to this many characters"
  attr :radius, :integer, default: 4, doc: "bar corner radius in px"
  attr :inner_radius, :integer, default: nil, doc: "pie: inner radius in px (donut); radial: ring hole in px"

  attr :options, :map,
    default: %{},
    doc: "Chart.js options deep-merged over the generated ones (escape hatch)"

  attr :name, :string, default: nil, doc: "accessible name of the chart"
  attr :class, :any, default: nil

  attr :id, :string, default: nil, doc: "legacy standalone mode only"
  attr :"chart-type", :string, default: "line", doc: "legacy: Chart.js chart type"
  attr :"chart-options", :map, default: nil, doc: "legacy: raw Chart.js options"
  attr :"chart-data", :any, default: nil, doc: "legacy: raw Chart.js data"
  attr :rest, :global

  def chart(%{"chart-data": raw} = assigns) when not is_nil(raw) do
    assigns =
      assigns
      |> assign(:chart_options, assigns[:"chart-options"] || %{})
      |> assign(:chart_data, raw)
      |> assign(:chart_type, assigns[:"chart-type"])

    ~H"""
    <canvas
      data-slot="chart"
      id={@id}
      name={@name}
      phx-hook="SaladUI"
      data-component="chart"
      data-part="root"
      data-chart-type={@chart_type}
      data-chart-options={json(@chart_options)}
      data-chart-data={json(@chart_data)}
      role="img"
      aria-label={@name}
      class={@class}
      {@rest}
    ></canvas>
    """
  end

  def chart(assigns) do
    options =
      %{
        type: assigns.type,
        index: assigns.index,
        series: assigns.series,
        dataKey: assigns.data_key,
        nameKey: assigns.name_key,
        stacked: assigns.stacked,
        horizontal: assigns.horizontal,
        curve: assigns.curve,
        dots: assigns.dots,
        grid: assigns.grid,
        indexAxis: assigns.index_axis,
        valueAxis: assigns.value_axis,
        tickChars: assigns.tick_chars,
        radius: assigns.radius,
        innerRadius: assigns.inner_radius,
        options: assigns.options
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    assigns = assign(assigns, :chart_options, options)

    ~H"""
    <div data-slot="chart-canvas" class={classes(["relative min-h-0 w-full flex-1", @class])} {@rest}>
      <canvas
        data-part="canvas"
        data-chart-options={json(@chart_options)}
        data-chart-data={json(@data || [])}
        role="img"
        aria-label={@name}
        aria-roledescription="chart"
        tabindex="0"
        class="outline-hidden focus-visible:rounded-md focus-visible:ring-[3px] focus-visible:ring-ring/50"
      ></canvas>
    </div>
    """
  end

  @doc """
  shadcn's tooltip, shown while hovering the chart (or moving through it with
  the arrow keys). Render it inside `chart_container/1`.

  ## Examples

      <.chart_tooltip />
      <.chart_tooltip indicator="line" />
      <.chart_tooltip indicator="dashed" hide_label />
      <.chart_tooltip label_key="visitors" name_key="browser" />
  """
  attr :indicator, :string, default: "dot", values: ~w(dot line dashed), doc: "indicator style"
  attr :hide_label, :boolean, default: false, doc: "hide the label row"
  attr :hide_indicator, :boolean, default: false, doc: "hide the color indicator"
  attr :label_key, :string, default: nil, doc: "config or data key to use for the label"
  attr :name_key, :string, default: nil, doc: "config or data key to use for item names"
  attr :color, :string, default: nil, doc: "indicator color for every item, instead of the series color"
  attr :class, :any, default: nil
  attr :rest, :global

  def chart_tooltip(assigns) do
    assigns =
      assign(assigns, :tooltip_options, %{
        indicator: assigns.indicator,
        hideLabel: assigns.hide_label,
        hideIndicator: assigns.hide_indicator,
        labelKey: assigns.label_key,
        nameKey: assigns.name_key,
        color: assigns.color
      })

    ~H"""
    <div
      data-slot="chart-tooltip"
      data-part="tooltip"
      data-tooltip-options={json(@tooltip_options)}
      hidden
      class={
        classes([
          "pointer-events-none absolute top-0 left-0 z-50 grid min-w-[8rem] items-start gap-1.5 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl",
          @class
        ])
      }
      {@rest}
    >
      <div data-slot="chart-tooltip-label" class="font-medium"></div>
      <div data-slot="chart-tooltip-items" class="grid gap-1.5"></div>
      <template data-slot="chart-tooltip-item-template">
        <.tooltip_item indicator={@indicator} hide_indicator={@hide_indicator} nest={false} />
      </template>
      <template :if={@indicator != "dot"} data-slot="chart-tooltip-nested-item-template">
        <.tooltip_item indicator={@indicator} hide_indicator={@hide_indicator} nest />
      </template>
    </div>
    """
  end

  attr :indicator, :string, required: true
  attr :hide_indicator, :boolean, required: true
  attr :nest, :boolean, required: true

  defp tooltip_item(assigns) do
    ~H"""
    <div
      data-slot="chart-tooltip-item"
      class={
        classes([
          "flex w-full flex-wrap items-stretch gap-2 [&>svg]:h-2.5 [&>svg]:w-2.5 [&>svg]:text-muted-foreground",
          @indicator == "dot" && "items-center"
        ])
      }
    >
      <div
        :if={!@hide_indicator}
        data-slot="chart-tooltip-indicator"
        class={
          classes([
            "shrink-0 rounded-[2px] border-(--color-border) bg-(--color-bg)",
            @indicator == "dot" && "h-2.5 w-2.5",
            @indicator == "line" && "w-1",
            @indicator == "dashed" && "w-0 border-[1.5px] border-dashed bg-transparent",
            @nest && @indicator == "dashed" && "my-0.5"
          ])
        }
      >
      </div>
      <div class={[
        "flex flex-1 justify-between leading-none",
        if(@nest, do: "items-end", else: "items-center")
      ]}>
        <div class="grid gap-1.5">
          <div :if={@nest} data-slot="chart-tooltip-nested-label" class="font-medium"></div>
          <span data-slot="chart-tooltip-name" class="text-muted-foreground"></span>
        </div>
        <span
          data-slot="chart-tooltip-value"
          class="font-mono font-medium text-foreground tabular-nums"
        ></span>
      </div>
    </div>
    """
  end

  @doc """
  shadcn's legend: one swatch (or config icon) and label per series, or per
  row for pie and radial charts. Render it inside `chart_container/1`.

  ## Examples

      <.chart_legend />
      <.chart_legend name_key="browser" />
      <.chart_legend vertical_align="top" />
  """
  attr :name_key, :string, default: nil, doc: "config or data key to use for item names"
  attr :hide_icon, :boolean, default: false, doc: "show the color swatch even when the config has an icon"
  attr :vertical_align, :string, default: "bottom", values: ~w(top bottom), doc: "place above or below the plot"
  attr :class, :any, default: nil
  attr :rest, :global

  def chart_legend(assigns) do
    assigns =
      assign(assigns, :legend_options, %{nameKey: assigns.name_key, hideIcon: assigns.hide_icon})

    ~H"""
    <div
      data-slot="chart-legend"
      data-part="legend"
      data-legend-options={json(@legend_options)}
      class={
        classes([
          "flex flex-wrap items-center justify-center gap-4",
          if(@vertical_align == "top", do: "order-first pb-3", else: "pt-3"),
          @class
        ])
      }
      {@rest}
    >
      <template data-slot="chart-legend-item-template">
        <div
          data-slot="chart-legend-item"
          class="flex items-center gap-1.5 [&>svg]:h-3 [&>svg]:w-3 [&>svg]:text-muted-foreground"
        >
          <div data-slot="chart-legend-indicator" class="h-2 w-2 shrink-0 rounded-[2px]"></div>
          <span data-slot="chart-legend-label"></span>
        </div>
      </template>
    </div>
    """
  end

  # -- config helpers ---------------------------------------------------------

  defp js_config(config) do
    Map.new(config, fn {key, item} ->
      item = item || %{}
      label = item[:label] || item["label"]

      {to_string(key), %{label: label && to_string(label), color: js_color(key, color_of(item, :light))}}
    end)
  end

  # Colors under a CSS-identifier key are read back through the scoped
  # `--color-<key>` variable (so `theme` follows dark mode); others raw.
  defp js_color(_key, nil), do: nil

  defp js_color(key, color) do
    if valid_ident?(key), do: "var(--color-#{key})", else: color
  end

  @doc false
  def chart_style(chart_id, config) do
    light = color_vars(config, :light)
    dark = color_vars(config, :dark)

    if light == [] and dark == [] do
      nil
    else
      Enum.join(
        [
          ~s([data-chart="#{chart_id}"] {\n#{Enum.join(light, "\n")}\n}),
          ~s(.dark [data-chart="#{chart_id}"] {\n#{Enum.join(dark, "\n")}\n})
        ],
        "\n"
      )
    end
  end

  defp color_vars(config, theme) do
    for {key, item} <- config,
        valid_ident?(key),
        color = color_of(item || %{}, theme),
        safe_css_value?(color) do
      "  --color-#{key}: #{color};"
    end
  end

  defp color_of(item, theme) do
    theme_map = item[:theme] || item["theme"]

    color =
      if is_map(theme_map) do
        theme_map[theme] || theme_map[to_string(theme)]
      else
        item[:color] || item["color"]
      end

    color && to_string(color)
  end

  defp valid_ident?(key), do: Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_-]*$/, to_string(key))

  # Values land inside a <style> element, so refuse anything that could close
  # the declaration, the rule or the element.
  defp safe_css_value?(value), do: not Regex.match?(~r/[<>{};]/, value)

  defp css_ident(id), do: String.replace(to_string(id), ~r/[^A-Za-z0-9_-]/, "")
end
