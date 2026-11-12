defmodule Storybook.SaladUIComponents.Chart do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Chart.chart_container/1
  def container, do: {:div, class: "w-full max-w-xl"}

  def imports do
    [{SaladUI.Chart, [chart: 1, chart_tooltip: 1, chart_legend: 1]}]
  end

  @months [
    %{month: "January", desktop: 186, mobile: 80},
    %{month: "February", desktop: 305, mobile: 200},
    %{month: "March", desktop: 237, mobile: 120},
    %{month: "April", desktop: 73, mobile: 190},
    %{month: "May", desktop: 209, mobile: 130},
    %{month: "June", desktop: 214, mobile: 140}
  ]

  @browsers [
    %{browser: "chrome", visitors: 275, fill: "var(--color-chrome)"},
    %{browser: "safari", visitors: 200, fill: "var(--color-safari)"},
    %{browser: "firefox", visitors: 187, fill: "var(--color-firefox)"},
    %{browser: "edge", visitors: 173, fill: "var(--color-edge)"},
    %{browser: "other", visitors: 90, fill: "var(--color-other)"}
  ]

  @intro_config %{
    desktop: %{label: "Desktop", color: "#2563eb"},
    mobile: %{label: "Mobile", color: "#60a5fa"}
  }

  @token_config %{
    desktop: %{label: "Desktop", color: "var(--chart-1)"},
    mobile: %{label: "Mobile", color: "var(--chart-2)"}
  }

  @browser_config %{
    visitors: %{label: "Visitors"},
    chrome: %{label: "Chrome", color: "var(--chart-1)"},
    safari: %{label: "Safari", color: "var(--chart-2)"},
    firefox: %{label: "Firefox", color: "var(--chart-3)"},
    edge: %{label: "Edge", color: "var(--chart-4)"},
    other: %{label: "Other", color: "var(--chart-5)"}
  }

  @cartesian "min-h-[200px] w-full"
  @round "mx-auto aspect-square max-h-[250px]"

  def variations do
    [
      %VariationGroup{
        id: :your_first_chart,
        description: "Your first chart: bars, then a grid, an axis, a tooltip and a legend",
        variations: [
          intro(:bar, "Bars only", ~s(<.chart type="bar" data={#{months()}} index="month" grid={false} index_axis={false} />)),
          intro(:grid, "Add a grid", ~s(<.chart type="bar" data={#{months()}} index="month" index_axis={false} />)),
          intro(:axis, "Add an axis", ~s(<.chart type="bar" data={#{months()}} index="month" tick_chars={3} />)),
          intro(:tooltip, "Add a tooltip", """
          <.chart type="bar" data={#{months()}} index="month" tick_chars={3} />
          <.chart_tooltip />
          """),
          intro(:legend, "Add a legend", """
          <.chart type="bar" data={#{months()}} index="month" tick_chars={3} />
          <.chart_tooltip />
          <.chart_legend />
          """)
        ]
      },
      %VariationGroup{
        id: :chart_types,
        description: "One chart of each type, themed with the --chart-N tokens",
        variations: [
          %Variation{
            id: :area,
            description: "Area - stacked, with legend",
            attributes: %{id: "chart-area", config: @token_config, class: @cartesian},
            slots: [
              """
              <.chart type="area" data={#{months()}} index="month" series={["mobile", "desktop"]} stacked tick_chars={3} />
              <.chart_tooltip indicator="dot" />
              <.chart_legend />
              """
            ]
          },
          %Variation{
            id: :bar,
            description: "Bar - stacked, with legend",
            attributes: %{id: "chart-bar", config: @token_config, class: @cartesian},
            slots: [
              """
              <.chart type="bar" data={#{months()}} index="month" stacked tick_chars={3} />
              <.chart_tooltip hide_label />
              <.chart_legend />
              """
            ]
          },
          %Variation{
            id: :line,
            description: "Line - multiple series with dots",
            attributes: %{id: "chart-line", config: @token_config, class: @cartesian},
            slots: [
              """
              <.chart type="line" data={#{months()}} index="month" dots tick_chars={3} />
              <.chart_tooltip />
              """
            ]
          },
          %Variation{
            id: :pie,
            description: "Pie - donut with custom tooltip keys and legend names",
            attributes: %{id: "chart-pie", config: @browser_config, class: @round},
            slots: [
              """
              <.chart type="pie" data={#{browsers()}} data_key="visitors" name_key="browser" inner_radius={60} />
              <.chart_tooltip hide_label />
              <.chart_legend name_key="browser" />
              """
            ]
          },
          %Variation{
            id: :radar,
            description: "Radar - two series",
            attributes: %{id: "chart-radar", config: @token_config, class: @round},
            slots: [
              """
              <.chart type="radar" data={#{months()}} index="month" />
              <.chart_tooltip indicator="line" />
              <.chart_legend />
              """
            ]
          },
          %Variation{
            id: :radial,
            description: "Radial - one ring per browser",
            attributes: %{id: "chart-radial", config: @browser_config, class: @round},
            slots: [
              """
              <.chart type="radial" data={#{browsers()}} data_key="visitors" name_key="browser" />
              <.chart_tooltip hide_label name_key="browser" />
              """
            ]
          }
        ]
      },
      %VariationGroup{
        id: :theming,
        description: "Chart config: icons, light/dark themes, color formats and per-row fills",
        variations: [
          %Variation{
            id: :icons_and_theme,
            description: "Config icons, and a theme map (Mobile is red in dark mode)",
            attributes: %{
              id: "chart-theme",
              class: @cartesian,
              config: %{
                desktop: %{label: "Desktop", color: "var(--chart-1)"},
                mobile: %{label: "Mobile", theme: %{light: "#2563eb", dark: "#dc2626"}}
              }
            },
            slots: [
              """
              <:icon key="desktop"><Lucideicons.monitor /></:icon>
              <:icon key="mobile"><Lucideicons.smartphone /></:icon>
              <.chart type="bar" data={#{months()}} index="month" tick_chars={3} />
              <.chart_tooltip />
              <.chart_legend />
              """
            ]
          },
          %Variation{
            id: :color_formats,
            description: "hex, hsl, oklch and CSS variable colors",
            attributes: %{
              id: "chart-color-formats",
              class: @cartesian,
              config: %{
                desktop: %{label: "Desktop", color: "#2563eb"},
                mobile: %{label: "Mobile", color: "hsl(220, 98%, 61%)"},
                tablet: %{label: "Tablet", color: "oklch(0.5 0.2 240)"},
                laptop: %{label: "Laptop", color: "var(--chart-2)"}
              }
            },
            slots: [
              """
              <.chart
                type="bar"
                data={#{inspect(Enum.map(@months, &Map.merge(&1, %{tablet: div(&1.desktop, 2), laptop: div(&1.mobile, 2)})))}}
                index="month"
                series={["desktop", "mobile", "tablet", "laptop"]}
                tick_chars={3}
              />
              <.chart_tooltip />
              <.chart_legend />
              """
            ]
          },
          %Variation{
            id: :data_fill,
            description: "Colors from each row's fill (var(--color-KEY)), horizontal bars",
            attributes: %{id: "chart-data-fill", config: @browser_config, class: @cartesian},
            slots: [
              """
              <.chart type="bar" data={#{browsers()}} index="browser" series={["visitors"]} horizontal radius={5} />
              <.chart_tooltip hide_label name_key="browser" />
              """
            ]
          }
        ]
      },
      %VariationGroup{
        id: :tooltip,
        description: "Tooltip: label, name, indicator and value",
        variations: [
          tooltip_variation(:dot, "Indicator dot (default)", ~s(<.chart_tooltip />)),
          tooltip_variation(:line, "Indicator line", ~s(<.chart_tooltip indicator="line" />)),
          tooltip_variation(:dashed, "Indicator dashed, no label", ~s(<.chart_tooltip indicator="dashed" hide_label />)),
          tooltip_variation(:no_indicator, "Hide indicator", ~s(<.chart_tooltip hide_indicator />)),
          %Variation{
            id: :custom_keys,
            description: ~s(label_key="visitors" and name_key="browser": "Visitors" as label, browser names per item),
            attributes: %{id: "chart-tooltip-keys", config: @browser_config, class: @round},
            slots: [
              """
              <.chart type="pie" data={#{browsers()}} data_key="visitors" name_key="browser" />
              <.chart_tooltip label_key="visitors" name_key="browser" />
              <.chart_legend name_key="browser" vertical_align="top" />
              """
            ]
          }
        ]
      }
    ]
  end

  defp intro(id, description, slot) do
    %Variation{
      id: id,
      description: description,
      attributes: %{id: "chart-intro-#{id}", config: @intro_config, class: @cartesian},
      slots: [slot]
    }
  end

  defp tooltip_variation(id, description, tooltip) do
    %Variation{
      id: id,
      description: description,
      attributes: %{id: "chart-tooltip-#{id}", config: @token_config, class: @cartesian},
      slots: [
        """
        <.chart type="bar" data={#{months()}} index="month" tick_chars={3} />
        #{tooltip}
        """
      ]
    }
  end

  defp months, do: inspect(@months)
  defp browsers, do: inspect(@browsers)
end
