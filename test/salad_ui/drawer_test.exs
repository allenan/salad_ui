defmodule SaladUI.DrawerTest do
  use ComponentCase

  import SaladUI.Button
  import SaladUI.Drawer

  defp options(html) do
    [_, raw] = Regex.run(~r/data-options="([^"]*)"/, html)

    raw
    |> String.replace("&quot;", "\"")
    |> Jason.decode!()
  end

  describe "drawer/1" do
    test "renders the root with drawer component wiring and defaults" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.drawer id="d">
          <span>Body</span>
        </.drawer>
        """)

      assert html =~ ~s(data-slot="drawer")
      assert html =~ ~s(data-component="drawer")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-open="false")
      assert html =~ ~s(data-vaul-drawer-direction="bottom")

      opts = options(html)
      assert opts["direction"] == "bottom"
      assert opts["snapPoints"] == []
      assert opts["dismissible"] == true
      assert opts["closeOnEscape"] == true
      assert opts["closeOnOutsideClick"] == true
      assert opts["handleOnly"] == false
      assert opts["animations"]["open_to_closed"]["duration"] == 500
    end

    test "passes direction, snap points and open state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.drawer
          id="d"
          open
          direction="right"
          snap_points={["148px", 0.5, 1]}
          active_snap_point={0.5}
          handle_only
        >
          <span>Body</span>
        </.drawer>
        """)

      assert html =~ ~s(data-open="true")
      assert html =~ ~s(data-vaul-drawer-direction="right")

      opts = options(html)
      assert opts["direction"] == "right"
      assert opts["snapPoints"] == ["148px", 0.5, 1]
      assert opts["activeSnapPoint"] == 0.5
      assert opts["handleOnly"] == true
    end

    test "dismissible={false} disables Escape and overlay click" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.drawer id="d" dismissible={false}><span /></.drawer>
        """)

      opts = options(html)
      assert opts["dismissible"] == false
      assert opts["closeOnEscape"] == false
      assert opts["closeOnOutsideClick"] == false
    end

    test "encodes event mappings" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.drawer id="d" on-open="opened" on-close="closed" on-snap-point-change="snapped">
          <span />
        </.drawer>
        """)

      assert html =~ "snap-point-change&quot;:&quot;snapped"
      assert html =~ "open&quot;:&quot;opened"
      assert html =~ "close&quot;:&quot;closed"
    end
  end

  describe "parts" do
    test "trigger and close carry their actions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.drawer_trigger><.button variant="outline">Open</.button></.drawer_trigger>
        <.drawer_close as="button" type="button">Cancel</.drawer_close>
        """)

      assert html =~ ~s(data-slot="drawer-trigger")
      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(data-action="open")
      assert_tag(html, "button", [{"data-slot", "drawer-close"}, {"data-action", "close"}])
    end

    test "content renders overlay, panel and handle with shadcn classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.drawer_content class="data-[vaul-drawer-direction=bottom]:max-h-[50vh]" dir="rtl">
          Body
        </.drawer_content>
        """)

      assert html =~ ~s(data-slot="drawer-portal")
      assert html =~ ~s(data-part="content")
      assert html =~ ~s(data-slot="drawer-overlay")
      assert html =~ "bg-black/50"
      assert html =~ ~s(data-slot="drawer-content")
      assert html =~ ~s(data-part="content-panel")
      assert html =~ "group/drawer-content"
      assert html =~ "data-[vaul-drawer-direction=bottom]:rounded-t-lg"
      assert html =~ "data-[vaul-drawer-direction=right]:sm:max-w-sm"
      assert html =~ ~s(dir="rtl")
      # The caller's max-height wins over the default 80vh.
      assert html =~ "data-[vaul-drawer-direction=bottom]:max-h-[50vh]"
      refute html =~ "data-[vaul-drawer-direction=bottom]:max-h-[80vh]"

      assert html =~ ~s(data-slot="drawer-handle")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "group-data-[vaul-drawer-direction=bottom]/drawer-content:block"
    end

    test "header, footer, title and description" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.drawer_header class="text-left">
          <.drawer_title>Move Goal</.drawer_title>
          <.drawer_description>Set your daily activity goal.</.drawer_description>
        </.drawer_header>
        <.drawer_footer class="pt-2">Actions</.drawer_footer>
        """)

      assert html =~ ~s(data-slot="drawer-header")
      assert html =~ "group-data-[vaul-drawer-direction=top]/drawer-content:text-center"
      assert html =~ "text-left"
      assert_tag(html, "h2", [{"data-slot", "drawer-title"}, {"data-part", "title"}])
      assert html =~ "font-semibold text-foreground"
      assert_tag(html, "p", [{"data-slot", "drawer-description"}, {"data-part", "description"}])
      assert html =~ ~s(data-slot="drawer-footer")
      assert html =~ "mt-auto flex flex-col gap-2"
      assert html =~ "pt-2"
    end
  end
end
