defmodule SaladUI.DropdownMenuTest do
  use ComponentCase

  import SaladUI.Button
  import SaladUI.DropdownMenu
  import SaladUI.Icon
  import SaladUI.Menu

  describe "Test Dropdown menu" do
    test "It renders dropdown trigger correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_trigger as={&button/1} variant="outline">
          Click me
        </.dropdown_menu_trigger>
        """)

      assert html =~ "Click me"

      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(type="button")
    end

    test "It renders dropdown menu content correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_content>
          <.menu class="w-56">
            <.menu_label>Account</.menu_label>
            <.menu_separator />
            <.menu_group>
              <.menu_item>
                <.icon name="hero-user" class="mr-2 h-4 w-4" />
                <span>Profile</span>
                <.menu_shortcut>⌘P</.menu_shortcut>
              </.menu_item>
              <.menu_item>
                <.icon name="hero-banknotes" class="mr-2 h-4 w-4" />
                <span>Billing</span>
                <.menu_shortcut>⌘B</.menu_shortcut>
              </.menu_item>
              <.menu_item>
                <.icon name="hero-cog-6-tooth" class="mr-2 h-4 w-4" />
                <span>Settings</span>
                <.menu_shortcut>⌘S</.menu_shortcut>
              </.menu_item>
            </.menu_group>
            <.menu_separator />
            <.menu_group>
              <.menu_item>
                <.icon name="hero-users" class="mr-2 h-4 w-4" />
                <span>Team</span>
              </.menu_item>
              <.menu_item disabled>
                <.icon name="hero-plus" class="mr-2 h-4 w-4" />
                <span>New team</span>
                <.menu_shortcut>⌘T</.menu_shortcut>
              </.menu_item>
            </.menu_group>
          </.menu>
        </.dropdown_menu_content>
        """)

      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-align="start")

      for css_class <-
            ~w(z-50 animate-in data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2) do
        assert html =~ css_class
      end
    end

    test "It renderes dropdown menu correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <div class="mt-24">
          <.dropdown_menu id="dropdown-test">
            <.dropdown_menu_trigger as={&button/1} variant="outline">
              Click me
            </.dropdown_menu_trigger>
            <.dropdown_menu_content>
              <.menu class="w-56">
                <.menu_label>Account</.menu_label>
                <.menu_separator />
                <.menu_group>
                  <.menu_item>
                    <.icon name="hero-user" class="mr-2 h-4 w-4" /> <span>Profile</span>
                    <.menu_shortcut>⌘P</.menu_shortcut>
                  </.menu_item>

                  <.menu_item>
                    <.icon name="hero-banknotes" class="mr-2 h-4 w-4" /> <span>Billing</span>
                    <.menu_shortcut>⌘B</.menu_shortcut>
                  </.menu_item>

                  <.menu_item>
                    <.icon name="hero-cog-6-tooth" class="mr-2 h-4 w-4" /> <span>Settings</span>
                    <.menu_shortcut>⌘S</.menu_shortcut>
                  </.menu_item>
                </.menu_group>
                <.menu_separator />
                <.menu_group>
                  <.menu_item>
                    <.icon name="hero-users" class="mr-2 h-4 w-4" /> <span>Team</span>
                  </.menu_item>

                  <.menu_item disabled>
                    <.icon name="hero-plus" class="mr-2 h-4 w-4" /> <span>New team</span>
                    <.menu_shortcut>⌘T</.menu_shortcut>
                  </.menu_item>
                </.menu_group>
              </.menu>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """)

      assert html =~ "<span>Profile</span>"
      assert html =~ "<span>Billing</span>"
      assert html =~ "<span>Settings</span>"
      assert html =~ "<span>New team</span>"
      assert html =~ "⌘T"
      assert html =~ "⌘S"
      assert html =~ "hero-users"

      for css_class <- ~w(relative inline-block) do
        assert html =~ css_class
      end
    end
  end

  describe "sub-menus" do
    test "renders sub, sub-trigger with chevron and a hidden sub-content panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_sub>
          <.dropdown_menu_sub_trigger inset>Invite users</.dropdown_menu_sub_trigger>
          <.dropdown_menu_sub_content class="w-40">
            <.dropdown_menu_item>Email</.dropdown_menu_item>
          </.dropdown_menu_sub_content>
        </.dropdown_menu_sub>
        """)

      assert html =~ ~s(data-slot="dropdown-menu-sub")
      assert html =~ ~s(data-part="sub")
      assert html =~ ~s(data-slot="dropdown-menu-sub-trigger")
      assert html =~ ~s(data-part="sub-trigger")
      assert html =~ ~s(data-inset)
      assert html =~ ~s(aria-haspopup="menu")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(<path d="m9 18 6-6-6-6"></path>)
      assert html =~ "data-[state=open]:bg-accent"

      assert html =~ ~r/data-part="sub-positioner"[^>]*hidden/
      assert html =~ ~s(data-side="right")
      assert html =~ ~s(data-align="start")
      assert html =~ ~s(data-side-offset="0")
      assert html =~ ~s(data-slot="dropdown-menu-sub-content")
      assert html =~ ~s(data-part="sub-content")
      assert html =~ ~s(role="menu")
      assert html =~ "shadow-lg"
      assert html =~ "w-40"
      assert html =~ "Email"
    end

    test "sub-content accepts side and offsets; disabled sub-trigger is not focusable" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_sub>
          <.dropdown_menu_sub_trigger disabled>More</.dropdown_menu_sub_trigger>
          <.dropdown_menu_sub_content side="left" side-offset={2} align-offset={-5}>
            <.dropdown_menu_item>A</.dropdown_menu_item>
          </.dropdown_menu_sub_content>
        </.dropdown_menu_sub>
        """)

      assert html =~ ~s(data-side="left")
      assert html =~ ~s(data-side-offset="2")
      assert html =~ ~s(data-align-offset="-5")
      assert html =~ ~r/data-part="sub-trigger"[^>]*data-disabled/
      assert html =~ ~r/data-part="sub-trigger"[^>]*tabindex="-1"/
    end
  end

  describe "radio group" do
    test "renders the group value and value-changed mapping" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_radio_group value="bottom" on-value-changed="set_position">
          <.dropdown_menu_radio_item value="top">Top</.dropdown_menu_radio_item>
          <.dropdown_menu_radio_item value="bottom" disabled>Bottom</.dropdown_menu_radio_item>
        </.dropdown_menu_radio_group>
        """)

      assert html =~ ~s(data-slot="dropdown-menu-radio-group")
      assert html =~ ~s(data-part="radio-group")
      assert html =~ ~s(data-value="bottom")
      assert html =~ ~s(role="group")
      assert html =~ ~s(data-event-mappings="{&quot;value-changed&quot;:&quot;set_position&quot;}")

      assert html =~ ~s(data-slot="dropdown-menu-radio-item")
      assert html =~ ~s(data-part="radio-item")
      assert html =~ ~s(data-value="top")
      assert html =~ ~s(<circle cx="12" cy="12" r="10"></circle>)
      assert html =~ "size-2 fill-current"
      assert html =~ ~r/data-part="item-indicator"[^>]*hidden/
      assert html =~ "ps-8"
      assert html =~ ~r/data-value="bottom"[^>]*data-disabled[^>]*tabindex="-1"/s
    end

    test "on-value-changed accepts a JS command" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_radio_group value="a" on-value-changed={Phoenix.LiveView.JS.push("picked")}>
          <.dropdown_menu_radio_item value="a">A</.dropdown_menu_radio_item>
        </.dropdown_menu_radio_group>
        """)

      assert html =~ "value-changed"
      assert html =~ "picked"
    end
  end
end
