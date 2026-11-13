defmodule SaladUI.ResizableTest do
  use ComponentCase

  import SaladUI.Resizable

  defp to_html(rendered), do: rendered |> rendered_to_string() |> clean_string()

  describe "resizable_panel_group/1" do
    test "renders a hooked horizontal group by default" do
      assigns = %{}

      html =
        to_html(~H"""
        <.resizable_panel_group id="group" class="rounded-lg border">
          <.resizable_panel>One</.resizable_panel>
        </.resizable_panel_group>
        """)

      assert html =~ ~s(id="group")
      assert html =~ ~s(data-slot="resizable-panel-group")
      assert html =~ ~s(data-component="resizable")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-orientation="horizontal")
      # The group has no role, so no aria-orientation (axe: aria-allowed-attr).
      refute html =~ ~s(aria-orientation=)
      assert html =~ "flex h-full w-full data-[orientation=vertical]:flex-col rounded-lg border"
      assert html =~ ~s(&quot;orientation&quot;:&quot;horizontal&quot;)
      assert html =~ ~s(&quot;keyboardResizeBy&quot;:10)
      refute html =~ "data-disabled"
    end

    test "passes orientation, persistence and events to JS" do
      assigns = %{}

      html =
        to_html(~H"""
        <.resizable_panel_group
          id="group"
          orientation="vertical"
          auto-save-id="layout"
          keyboard-resize-by={5}
          disabled
          on-layout-change="layout_changed"
        >
          <.resizable_panel>One</.resizable_panel>
        </.resizable_panel_group>
        """)

      refute html =~ ~s(aria-orientation=)
      assert html =~ ~s(data-orientation="vertical")
      assert html =~ ~s(&quot;autoSaveId&quot;:&quot;layout&quot;)
      assert html =~ ~s(&quot;keyboardResizeBy&quot;:5)
      assert html =~ ~s(&quot;disabled&quot;:true)
      assert html =~ ~s(&quot;layout-change&quot;:&quot;layout_changed&quot;)
      assert html =~ "data-disabled"
    end

    test "direction is accepted as an alias for orientation" do
      assigns = %{}

      html =
        to_html(~H"""
        <.resizable_panel_group id="group" direction="vertical">
          <.resizable_panel>One</.resizable_panel>
        </.resizable_panel_group>
        """)

      assert html =~ ~s(data-orientation="vertical")
    end
  end

  describe "resizable_panel/1" do
    test "renders size constraints and a pre-JS flex style" do
      assigns = %{}

      html =
        to_html(~H"""
        <.resizable_panel id="p" default-size="25%" min-size={10} max-size="40.5">Side</.resizable_panel>
        """)

      assert html =~ ~s(data-slot="resizable-panel")
      assert html =~ ~s(data-part="panel")
      assert html =~ ~s(data-default-size="25")
      assert html =~ ~s(data-min-size="10")
      assert html =~ ~s(data-max-size="40.5")
      # The size is a custom property read by a class, so app CSS can
      # override the flex without !important.
      assert html =~ ~s(style="--panel-size: 25;")
      assert html =~ "flex-[var(--panel-size,1)_1_0px] overflow-clip min-h-0 min-w-0"
      refute html =~ "flex: 25"
    end

    test "merges the app's classes after the sizing classes" do
      assigns = %{}

      html = to_html(~H|<.resizable_panel class="flex flex-col max-lg:flex-1">Body</.resizable_panel>|)

      assert html =~ "flex-[var(--panel-size,1)_1_0px] overflow-clip min-h-0 min-w-0 flex flex-col max-lg:flex-1"
    end

    test "omits constraints that are not given" do
      assigns = %{}

      html = to_html(~H"<.resizable_panel>Body</.resizable_panel>")

      refute html =~ "data-default-size"
      refute html =~ "data-min-size"
      assert html =~ ~s(style="--panel-size: 1;")
    end

    test "rejects non-percentage sizes" do
      assigns = %{}

      assert_raise ArgumentError, ~r/percentages/, fn ->
        to_html(~H|<.resizable_panel default-size="200px">Body</.resizable_panel>|)
      end
    end
  end

  describe "resizable_handle/1" do
    test "renders a focusable separator without a grip by default" do
      assigns = %{}

      html = to_html(~H|<.resizable_handle class="bg-red-500" />|)

      assert html =~ ~s(data-slot="resizable-handle")
      assert html =~ ~s(data-part="handle")
      assert html =~ ~s(role="separator")
      assert html =~ ~s(tabindex="0")
      assert html =~ "aria-[orientation=horizontal]:h-px"
      assert html =~ "bg-red-500"
      refute html =~ "lucide-grip-vertical"
    end

    test "with_handle renders the grip" do
      assigns = %{}

      html = to_html(~H"<.resizable_handle with_handle />")

      assert html =~ "z-10 flex h-4 w-3 items-center justify-center rounded-xs border bg-border"
      assert html =~ "lucide-grip-vertical size-2.5"
    end

    test "disabled handles leave the tab order" do
      assigns = %{}

      html = to_html(~H"<.resizable_handle disabled />")

      assert html =~ ~s(tabindex="-1")
      assert html =~ "data-disabled"
    end
  end

  # The opening tag matching "#id" or "[attr=value]", and one attribute of it
  # ("" for a boolean attribute, nil when absent).
  defp tag(html, "#" <> id), do: find_tag(html, ~s(id="#{id}"))

  defp tag(html, "[" <> rest) do
    [name, value] = rest |> String.trim_trailing("]") |> String.split("=")
    find_tag(html, ~s(#{name}="#{value}"))
  end

  defp find_tag(html, needle) do
    ~r/<[a-z]+\s[^>]*>/
    |> Regex.scan(html)
    |> List.flatten()
    |> Enum.find(&String.contains?(&1, " " <> needle))
  end

  defp attr_of(tag, name) do
    case Regex.run(~r/\s#{Regex.escape(name)}(?:="([^"]*)")?[\s>]/, tag) do
      nil -> nil
      [_] -> ""
      [_, value] -> value
    end
  end

  describe "collapsible panels" do
    test "collapsible and collapsed-size are rendered for the JS" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_panel_group id="g">
          <.resizable_panel default-size={75}>Main</.resizable_panel>
          <.resizable_handle />
          <.resizable_panel id="side" default-size={25} min-size={15} collapsible collapsed-size="4%">
            Side
          </.resizable_panel>
        </.resizable_panel_group>
        """)

      side = tag(html, "#side")
      assert attr_of(side, "data-collapsible") == "true"
      assert attr_of(side, "data-collapsed-size") == "4"
      assert length(Regex.scan(~r/data-collapsible=/, html)) == 1
    end

    test "collapsed renders the panel collapsed and inert before the JS runs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_panel_group id="g" on-collapse="side_collapsed" on-expand="side_expanded">
          <.resizable_panel id="main" default-size={75}>Main</.resizable_panel>
          <.resizable_handle />
          <.resizable_panel id="side" default-size={25} min-size={15} collapsible collapsed>
            Side
          </.resizable_panel>
        </.resizable_panel_group>
        """)

      side = tag(html, "#side")
      assert attr_of(side, "data-server-collapsed") == "true"
      assert attr_of(side, "data-collapsed") == ""
      assert attr_of(side, "inert") == ""
      # Starts at its collapsed size, not its default size: no flash.
      assert attr_of(side, "style") == "--panel-size: 0;"
      assert attr_of(tag(html, "#main"), "style") == "--panel-size: 75;"
      assert html =~ ~s(&quot;collapse&quot;:&quot;side_collapsed&quot;)
      assert html =~ ~s(&quot;expand&quot;:&quot;side_expanded&quot;)
    end

    test "collapsed={false} is sent to the JS and renders the default size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_panel id="side" default-size={25} collapsible collapsed={false}>
          Side
        </.resizable_panel>
        """)

      side = tag(html, "#side")
      assert attr_of(side, "data-server-collapsed") == "false"
      assert attr_of(side, "data-collapsed") == nil
      assert attr_of(side, "inert") == nil
      assert attr_of(side, "style") == "--panel-size: 25;"
    end

    test "a panel collapsed to a collapsed-size above 0 stays interactive" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_panel id="rail" default-size={25} collapsible collapsed-size={4} collapsed>
          Rail
        </.resizable_panel>
        """)

      rail = tag(html, "#rail")
      assert attr_of(rail, "data-collapsed") == ""
      assert attr_of(rail, "inert") == nil
      assert attr_of(rail, "style") == "--panel-size: 4;"
    end

    test "without collapsed the client owns the state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.resizable_panel id="side" default-size={25} collapsible>Side</.resizable_panel>
        """)

      side = tag(html, "#side")
      assert attr_of(side, "data-server-collapsed") == nil
      assert attr_of(side, "data-collapsed") == nil
      assert attr_of(side, "inert") == nil
    end

    test "collapsed needs a collapsible panel" do
      assigns = %{}

      assert_raise ArgumentError, ~r/collapsible/, fn ->
        rendered_to_string(~H|<.resizable_panel collapsed>Body</.resizable_panel>|)
      end
    end
  end
end
