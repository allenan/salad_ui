defmodule SaladUI.NavigationMenuTest do
  use ComponentCase

  import SaladUI.NavigationMenu

  defp render_menu(assigns) do
    rendered_to_string(~H"""
    <.navigation_menu
      id="main-nav"
      viewport={@viewport}
      on-value-changed="nav_changed"
      delay-duration={100}
    >
      <.navigation_menu_list class="flex-wrap">
        <.navigation_menu_item value="home">
          <.navigation_menu_trigger>Home</.navigation_menu_trigger>
          <.navigation_menu_content>
            <.navigation_menu_link href="/docs" active>Docs</.navigation_menu_link>
          </.navigation_menu_content>
        </.navigation_menu_item>
        <.navigation_menu_item>
          <.navigation_menu_link navigate="/about" class={navigation_menu_trigger_style()}>
            About
          </.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
      <.navigation_menu_indicator />
    </.navigation_menu>
    """)
  end

  describe "navigation_menu" do
    test "renders the root nav with hook, options and event mappings" do
      html = render_menu(%{viewport: true})

      assert html =~ ~s(<nav id="main-nav")
      assert html =~ ~s(data-slot="navigation-menu")
      assert html =~ ~s(data-component="navigation-menu")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-state="closed")
      assert html =~ ~s(data-viewport="true")
      assert html =~ ~s(aria-label="Main")
      assert html =~ "group/navigation-menu"
      assert html =~ "&quot;delayDuration&quot;:100"
      assert html =~ "&quot;skipDelayDuration&quot;:300"
      assert html =~ "nav_changed"
    end

    test "renders the viewport by default" do
      html = render_menu(%{viewport: true})

      assert html =~ ~s(data-slot="navigation-menu-viewport")
      assert html =~ ~s(data-part="viewport")
      assert html =~ "h-(--navigation-menu-viewport-height)"
      assert html =~ "md:w-(--navigation-menu-viewport-width)"
    end

    test "viewport={false} omits the viewport" do
      html = render_menu(%{viewport: false})

      assert html =~ ~s(data-viewport="false")
      refute html =~ ~s(data-slot="navigation-menu-viewport")
    end

    test "renders every shadcn data-slot exactly once per element" do
      html = render_menu(%{viewport: true})

      for slot <-
            ~w(navigation-menu navigation-menu-list navigation-menu-item navigation-menu-trigger navigation-menu-content navigation-menu-link navigation-menu-indicator navigation-menu-viewport) do
        assert html =~ ~s(data-slot="#{slot}"), "missing #{slot}"
      end

      refute Enum.any?(Regex.scan(~r/<[a-zA-Z][^>]*>/, html), fn [tag] ->
               length(Regex.scan(~r/\sdata-slot=/, tag)) > 1
             end)
    end
  end

  describe "parts" do
    test "item carries its value" do
      html = render_menu(%{viewport: true})

      assert html =~ ~s(data-part="item" data-value="home")
      assert html =~ "gap-1 flex-wrap"
    end

    test "trigger is a closed button with a rotating chevron" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu_trigger disabled>Menu</.navigation_menu_trigger>
        """)

      assert html =~ ~s(type="button")
      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ "disabled"
      assert html =~ "data-[state=open]:bg-accent/50"
      assert html =~ "group-data-[state=open]:rotate-180"
    end

    test "content starts hidden with motion classes" do
      html = render_menu(%{viewport: true})

      assert html =~ ~r/data-part="content" data-state="closed" hidden/
      assert html =~ "data-[motion=from-end]:slide-in-from-right-52"
      assert html =~ "group-data-[viewport=false]/navigation-menu:top-full"
    end

    test "link supports href/navigate and the active state" do
      html = render_menu(%{viewport: true})

      assert html =~ ~s(href="/docs")
      assert html =~ ~s(data-active="true")
      assert html =~ ~s(aria-current="page")
      assert html =~ ~s(href="/about")
      assert html =~ "data-phx-link=\"redirect\""
    end

    test "inactive links omit data-active" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.navigation_menu_link href="/x">X</.navigation_menu_link>
        """)

      refute html =~ "data-active"
      refute html =~ "aria-current"
    end

    test "trigger style merges onto a link" do
      html = render_menu(%{viewport: true})

      [about] = Regex.run(~r/<a[^>]*href="\/about"[^>]*>/, html)
      assert about =~ "inline-flex"
      assert about =~ "h-9"
      assert about =~ "rounded-md"
      refute about =~ "rounded-sm"
    end

    test "indicator starts hidden with its arrow" do
      html = render_menu(%{viewport: true})

      assert html =~ ~s(data-part="indicator")
      assert html =~ ~s(data-state="hidden")
      assert html =~ "rotate-45"
    end
  end
end
