defmodule SaladUI.ChartTest do
  use ComponentCase

  import SaladUI.Chart

  @data [
    %{month: "January", desktop: 186, mobile: 80},
    %{month: "February", desktop: 305, mobile: 200}
  ]

  @config %{
    desktop: %{label: "Desktop", color: "var(--chart-1)"},
    mobile: %{label: "Mobile", theme: %{light: "#2563eb", dark: "#dc2626"}},
    visitors: %{label: "Visitors"}
  }

  defp decode_attr(html, attr) do
    [_, raw] = Regex.run(~r/#{attr}="([^"]*)"/, html)
    raw |> String.replace("&quot;", "\"") |> String.replace("&amp;", "&") |> Jason.decode!()
  end

  describe "chart_container/1" do
    test "renders the shadcn container with the hook and scoped color variables" do
      assigns = %{config: @config, data: @data}

      html =
        rendered_to_string(~H"""
        <.chart_container id="visitors" config={@config} class="min-h-[200px] w-full">
          <.chart type="bar" data={@data} index="month" />
        </.chart_container>
        """)

      assert html =~ ~s(id="visitors")
      assert html =~ ~s(data-slot="chart")
      assert html =~ ~s(data-chart="chart-visitors")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-component="chart")
      assert html =~ "min-h-[200px] w-full"
      assert html =~ "aspect-video"

      assert html =~ ~s([data-chart="chart-visitors"] {)
      assert html =~ "--color-desktop: var(--chart-1);"
      assert html =~ "--color-mobile: #2563eb;"
      assert html =~ ~s(.dark [data-chart="chart-visitors"] {)
      assert html =~ "--color-mobile: #dc2626;"
      refute html =~ "--color-visitors"

      config = decode_attr(html, "data-config")
      assert config["desktop"] == %{"label" => "Desktop", "color" => "var(--color-desktop)"}
      assert config["visitors"] == %{"label" => "Visitors", "color" => nil}
    end

    test "drops color values that could break out of the style element" do
      assigns = %{config: %{evil: %{color: "red;}</style><script>alert(1)</script>"}}}

      html =
        rendered_to_string(~H"""
        <.chart_container id="c" config={@config}>
          <.chart type="line" data={[]} />
        </.chart_container>
        """)

      refute html =~ "<script>"
      refute html =~ "<style>"
      # JS must not point at the --color-evil variable that was never written
      assert decode_attr(html, "data-config")["evil"]["color"] == nil
    end

    test "renders config icons into a template keyed by config key" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chart_container id="c" config={%{desktop: %{label: "Desktop"}}}>
          <:icon key="desktop"><svg data-icon="monitor"></svg></:icon>
          <.chart type="bar" data={[]} />
        </.chart_container>
        """)

      assert html =~ ~s(<template data-slot="chart-icons">)
      assert html =~ ~s(data-key="desktop")
      assert html =~ ~s(<svg data-icon="monitor">)
    end
  end

  describe "chart/1" do
    test "renders a canvas part with chart options and rows" do
      assigns = %{data: @data}

      html =
        rendered_to_string(~H"""
        <.chart
          type="area"
          data={@data}
          index="month"
          series={["desktop"]}
          stacked
          tick_chars={3}
          name="Visitors"
        />
        """)

      assert html =~ ~s(data-slot="chart-canvas")
      assert html =~ ~s(data-part="canvas")
      # Focusable and arrow-key driven, like Recharts' accessibilityLayer
      assert html =~ ~s(role="application")
      assert html =~ ~s(aria-roledescription="chart")
      assert html =~ ~s(aria-label="Visitors")
      assert html =~ ~s(tabindex="0")
      refute html =~ "phx-hook"

      options = decode_attr(html, "data-chart-options")
      assert options["type"] == "area"
      assert options["index"] == "month"
      assert options["series"] == ["desktop"]
      assert options["stacked"] == true
      assert options["tickChars"] == 3
      assert options["curve"] == "natural"
      refute Map.has_key?(options, "dataKey")

      assert [%{"month" => "January"} | _] = decode_attr(html, "data-chart-data")
    end

    test "the focusable canvas always has an accessible name" do
      assigns = %{}

      html = rendered_to_string(~H|<.chart type="pie" data={[]} />|)

      assert html =~ ~s(aria-label="Pie chart")
    end

    test "legacy attributes render a standalone Chart.js canvas" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chart
          id="test-chart"
          name="Test Chart"
          chart-type="bar"
          chart-options={%{responsive: true}}
          chart-data={%{labels: ["a"], datasets: []}}
        />
        """)

      assert html =~ ~s(id="test-chart")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-chart-type="bar")
      assert html =~ ~s(role="img")
      assert html =~ ~s(aria-label="Test Chart")
      assert decode_attr(html, "data-chart-options") == %{"responsive" => true}
    end
  end

  describe "chart_tooltip/1" do
    test "renders shadcn's tooltip shell, hidden until hovered" do
      assigns = %{}

      html = rendered_to_string(~H"<.chart_tooltip />")

      assert html =~ ~s(data-slot="chart-tooltip")
      assert html =~ ~s(data-part="tooltip")
      assert html =~ "hidden"
      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-live="polite")

      assert html =~
               "grid min-w-[8rem] items-start gap-1.5 rounded-lg border border-border/50 bg-background px-2.5 py-1.5 text-xs shadow-xl"

      assert html =~ ~s(data-slot="chart-tooltip-item-template")
      assert html =~ "h-2.5 w-2.5"
      refute html =~ "chart-tooltip-nested-item-template"

      assert decode_attr(html, "data-tooltip-options") == %{
               "indicator" => "dot",
               "hideLabel" => false,
               "hideIndicator" => false,
               "labelKey" => nil,
               "nameKey" => nil,
               "color" => nil
             }
    end

    test "line and dashed indicators also render a nested-label template" do
      assigns = %{}

      line = rendered_to_string(~H|<.chart_tooltip indicator="line" />|)
      assert line =~ "chart-tooltip-nested-item-template"
      assert line =~ "w-1"

      dashed = rendered_to_string(~H|<.chart_tooltip indicator="dashed" hide_label />|)
      assert dashed =~ "w-0 border-[1.5px] border-dashed bg-transparent"
      assert dashed =~ "my-0.5"
      assert dashed =~ ~s(&quot;hideLabel&quot;:true)
    end

    test "hide_indicator omits the indicator; keys pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chart_tooltip hide_indicator label_key="visitors" name_key="browser" />
        """)

      refute html =~ "chart-tooltip-indicator"
      options = decode_attr(html, "data-tooltip-options")
      assert options["labelKey"] == "visitors"
      assert options["nameKey"] == "browser"
    end
  end

  describe "chart_legend/1" do
    test "renders the legend shell below the chart by default" do
      assigns = %{}

      html = rendered_to_string(~H"<.chart_legend />")

      assert html =~ ~s(data-slot="chart-legend")
      assert html =~ ~s(data-part="legend")
      assert html =~ "flex flex-wrap items-center justify-center gap-4 pt-3"
      assert html =~ "h-2 w-2 shrink-0 rounded-[2px]"
    end

    test "vertical_align top moves it above the chart; name_key passes through" do
      assigns = %{}

      html = rendered_to_string(~H|<.chart_legend vertical_align="top" name_key="browser" />|)

      assert html =~ "order-first pb-3"
      assert decode_attr(html, "data-legend-options")["nameKey"] == "browser"
    end
  end
end
