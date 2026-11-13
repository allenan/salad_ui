defmodule SaladUI.SidebarTest do
  use ComponentCase

  import SaladUI.Sidebar

  describe "sidebar provider" do
    test "renders with default classes and style" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar_provider>Content</.sidebar_provider>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "group/sidebar-wrapper flex min-h-svh w-full has-[[data-variant=inset]]:bg-sidebar"
      assert html =~ "--sidebar-width: 16rem"
      assert html =~ "--sidebar-width-icon: 3rem"
      assert html =~ "Content"
    end

    test "accepts custom classes and styles" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar_provider class="custom-class" style={%{"custom-var": "value"}}>
          Content
        </.sidebar_provider>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "custom-class"
      assert html =~ "custom-var: value"
    end
  end

  describe "sidebar" do
    test "renders non-collapsible sidebar correctly" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar id="test-sidebar" collapsible="none">Content</.sidebar>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "flex h-full w-(--sidebar-width) flex-col bg-sidebar text-sidebar-foreground"
      assert html =~ "Content"
    end

    test "renders mobile sidebar correctly" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar id="test-sidebar" is_mobile={true}>Content</.sidebar>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-sidebar=\"sidebar\""
      assert html =~ "data-mobile=\"true\""
      assert html =~ "w-(--sidebar-width)"
      assert html =~ "bg-sidebar"
      assert html =~ "Content"
    end

    test "renders standard sidebar with correct attributes" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar id="test-sidebar" side="left" variant="sidebar" collapsible="offcanvas" state="expanded">
          Content
        </.sidebar>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-state=\"expanded\""
      assert html =~ "data-collapsible=\"\""
      assert html =~ "data-variant=\"sidebar\""
      assert html =~ "data-side=\"left\""
      assert html =~ "Content"
    end
  end

  describe "sidebar_trigger" do
    test "renders with correct attributes" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar_trigger target="test-sidebar" class="custom-class">
          Toggle
        </.sidebar_trigger>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-sidebar=\"trigger\""
      assert html =~ "size-7"
      assert html =~ "custom-class"
      assert html =~ "Toggle"
      assert html =~ "Toggle Sidebar"
    end
  end

  describe "sidebar_content" do
    test "renders with correct classes" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar_content class="custom-class">Content</.sidebar_content>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-sidebar=\"content\""
      assert html =~ "salad-scroll-area"
      assert html =~ "flex min-h-0 flex-1 flex-col gap-2 overflow-auto"
      assert html =~ "custom-class"
      assert html =~ "Content"
    end
  end

  describe "sidebar_group" do
    test "renders group with label and content" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar_group>
          <.sidebar_group_label>Group Label</.sidebar_group_label>
          <.sidebar_group_content>Group Content</.sidebar_group_content>
        </.sidebar_group>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-sidebar=\"group\""
      assert html =~ "data-sidebar=\"group-label\""
      assert html =~ "data-sidebar=\"group-content\""
      assert html =~ "Group Label"
      assert html =~ "Group Content"
    end
  end

  describe "sidebar_menu" do
    test "renders menu with items and buttons" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar_menu>
          <.sidebar_menu_item>
            <.sidebar_menu_button tooltip="Item 1">
              <span>Menu Item 1</span>
            </.sidebar_menu_button>
          </.sidebar_menu_item>
        </.sidebar_menu>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-sidebar=\"menu\""
      assert html =~ "data-sidebar=\"menu-item\""
      assert html =~ "data-sidebar=\"menu-button\""
      assert html =~ "Menu Item 1"
    end

    test "renders menu button with different variants and sizes" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar_menu_button variant="outline" size="lg" is_active={true}>
          Large Active Button
        </.sidebar_menu_button>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-sidebar=\"menu-button\""
      assert html =~ "data-size=\"lg\""
      assert html =~ "data-active"
      assert html =~ "Large Active Button"
    end
  end

  describe "sidebar_menu_sub" do
    test "renders submenu with items" do
      assigns = %{}

      html =
        ~H"""
        <.sidebar_menu_sub>
          <.sidebar_menu_sub_item>
            <.sidebar_menu_sub_button size="sm" is_active={true}>
              Sub Item
            </.sidebar_menu_sub_button>
          </.sidebar_menu_sub_item>
        </.sidebar_menu_sub>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-sidebar=\"menu-sub\""
      assert html =~ "data-sidebar=\"menu-sub-button\""
      assert html =~ "data-size=\"sm\""
      assert html =~ "data-active"
      assert html =~ "Sub Item"
    end
  end

  describe "sidebar behaviour (provider hook)" do
    test "the provider carries the sidebar hook, options and the initial state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_provider id="sp" default_open={false} on-open-change="changed">
          Content
        </.sidebar_provider>
        """)

      assert html =~ ~s(id="sp")
      assert html =~ ~s(data-component="sidebar")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-state="collapsed")
      refute html =~ "data-open="
      assert html =~ "--sidebar-width-mobile: 18rem"

      [options] = Regex.run(~r/data-options="([^"]*)"/, html, capture: :all_but_first)
      options = options |> String.replace("&quot;", "\"") |> Jason.decode!()

      assert options == %{
               "isMobile" => nil,
               "keyboardShortcut" => true,
               "cookieName" => "sidebar_state"
             }

      assert html =~ ~s(data-event-mappings="{&quot;open-change&quot;:&quot;changed&quot;}")
    end

    test "a controlled provider renders data-open, which wins over default_open" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_provider id="sp" open={false} default_open={true}>Content</.sidebar_provider>
        """)

      assert html =~ ~s(data-open="false")
      assert html =~ ~s(data-state="collapsed")
    end

    test "is_mobile, keyboard_shortcut and cookie are passed to the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_provider id="sp" is_mobile={true} keyboard_shortcut={false} cookie={nil}>
          Content
        </.sidebar_provider>
        """)

      assert html =~ "&quot;isMobile&quot;:true"
      assert html =~ "&quot;keyboardShortcut&quot;:false"
      assert html =~ "&quot;cookieName&quot;:null"
    end

    test "the sidebar exposes its collapsible mode and variant to the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb" collapsible="icon" variant="floating" state="collapsed">Content</.sidebar>
        """)

      assert html =~ ~s(data-collapsible-mode="icon")
      assert html =~ ~s(data-sidebar-variant="floating")
      assert html =~ ~s(data-state="collapsed")
      assert html =~ ~s(data-collapsible="icon")
      assert html =~ ~s(data-slot="sidebar-overlay")
      assert html =~ ~s(data-action="close")
      refute html =~ "data-mobile="
      refute html =~ "data-is-mobile="
    end

    test "is_mobile renders the closed mobile sheet without the variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar id="sb" variant="inset" is_mobile={true}>Content</.sidebar>
        """)

      assert html =~ ~s(data-mobile="true")
      assert html =~ ~s(data-is-mobile="true")
      assert html =~ ~s(data-state="closed")
      assert html =~ ~s(data-collapsible="offcanvas")
      refute html =~ ~s(data-variant="inset")
      assert html =~ ~s(data-sidebar-variant="inset")
      assert html =~ ~r/data-slot="sidebar-container"[^>]* inert/
      assert html =~ "data-[mobile=true]:[--sidebar-width:var(--sidebar-width-mobile)]"
    end

    test "is_mobile={false} forces the desktop layout" do
      assigns = %{}

      html = rendered_to_string(~H|<.sidebar id="sb" is_mobile={false}>Content</.sidebar>|)

      assert html =~ ~s(data-is-mobile="false")
      refute html =~ ~s(data-mobile=)
    end

    test "a trigger inside the provider toggles through data-action" do
      assigns = %{}

      html = rendered_to_string(~H"<.sidebar_trigger />")

      assert html =~ ~s(data-action="toggle")
      assert html =~ ~s(type="button")
      assert html =~ ~s(data-variant="ghost")
      assert html =~ "size-7"
      refute html =~ "phx-click"
    end

    test "a trigger with a target dispatches the toggle command to it" do
      assigns = %{}

      html = rendered_to_string(~H|<.sidebar_trigger target="sb" />|)

      refute html =~ "data-action"
      assert html =~ "phx-click"
      assert html =~ "salad_ui:command"
      assert html =~ "&quot;to&quot;:&quot;#sb&quot;"
      assert html =~ "&quot;command&quot;:&quot;toggle&quot;"
    end

    test "the rail toggles through data-action and hides on mobile" do
      assigns = %{}

      html = rendered_to_string(~H"<.sidebar_rail />")

      assert html =~ ~s(data-action="toggle")
      assert html =~ "group-data-[mobile=true]:hidden"
    end

    test "menu button tooltips are a hidden sibling of the button, for the hook to show" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <li>
          <.sidebar_menu_button tooltip="Home" size="sm">Home</.sidebar_menu_button>
          <.sidebar_menu_badge>3</.sidebar_menu_badge>
        </li>
        """)

      # The button is not wrapped (the badge/action `peer/menu-button`
      # selectors and an outer component's trigger need it as a direct child).
      assert html =~ ~r/<li>\s*<button[^>]*data-sidebar="menu-button"/
      assert html =~ ~r/<\/button>\s*<div[^>]*data-sidebar="menu-tooltip"/
      refute html =~ ~s(data-component="tooltip")
      assert html =~ ~s(role="tooltip")
      assert html =~ ~s(data-side="right")
      assert html =~ ~r/data-sidebar="menu-tooltip"[^>]*hidden/
    end

    test "as_child keeps an outer trigger on the menu button itself" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <SaladUI.Helpers.as_child
          tag={&SaladUI.Collapsible.collapsible_trigger/1}
          child={&sidebar_menu_button/1}
          tooltip="Projects"
        >
          Projects
        </SaladUI.Helpers.as_child>
        """)

      assert html =~
               ~r/<button[^>]*data-action="toggle"[^>]*data-sidebar="menu-button"|<button[^>]*data-sidebar="menu-button"[^>]*data-action="toggle"/

      assert html =~ ~s(data-sidebar="menu-tooltip")
    end

    test "is_mobile on the menu button skips the tooltip" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sidebar_menu_button tooltip="Home" is_mobile>Home</.sidebar_menu_button>
        """)

      refute html =~ "tooltip-content"
    end

    test "toggle/open/close helpers dispatch commands" do
      for {fun, command} <- [toggle_sidebar: "toggle", open_sidebar: "open", close_sidebar: "close"] do
        %Phoenix.LiveView.JS{ops: [["dispatch", opts]]} = apply(SaladUI.Sidebar, fun, ["sp"])
        assert opts.to == "#sp"
        assert opts.event == "salad_ui:command"
        assert opts.detail.command == command
      end
    end
  end
end
