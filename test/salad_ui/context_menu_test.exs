defmodule SaladUI.ContextMenuTest do
  use ComponentCase

  import SaladUI.ContextMenu

  defp slots(html) do
    ~r/\sdata-slot="([^"]+)"/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
  end

  test "renders the full composition with shadcn data-slots and JS parts" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.context_menu id="cm" on-open="opened">
        <.context_menu_trigger class="border border-dashed">Right click here</.context_menu_trigger>
        <.context_menu_content class="w-48">
          <.context_menu_group>
            <.context_menu_label inset>Navigation</.context_menu_label>
            <.context_menu_item on-select="back">
              Back
              <.context_menu_shortcut>⌘[</.context_menu_shortcut>
            </.context_menu_item>
            <.context_menu_item disabled>Forward</.context_menu_item>
            <.context_menu_sub>
              <.context_menu_sub_trigger inset>More Tools</.context_menu_sub_trigger>
              <.context_menu_sub_content class="w-44">
                <.context_menu_item variant="destructive">Delete</.context_menu_item>
              </.context_menu_sub_content>
            </.context_menu_sub>
          </.context_menu_group>
          <.context_menu_separator />
          <.context_menu_checkbox_item checked on-checked-change="bookmarks">
            Show Bookmarks
          </.context_menu_checkbox_item>
          <.context_menu_radio_group value="pedro" on-value-changed="person">
            <.context_menu_radio_item value="pedro">Pedro Duarte</.context_menu_radio_item>
            <.context_menu_radio_item value="colm">Colm Tuite</.context_menu_radio_item>
          </.context_menu_radio_group>
        </.context_menu_content>
      </.context_menu>
      """)

    assert slots(html) --
             ~w(context-menu context-menu-trigger context-menu-content context-menu-group
                context-menu-label context-menu-item context-menu-shortcut context-menu-sub
                context-menu-sub-trigger context-menu-sub-content context-menu-separator
                context-menu-checkbox-item context-menu-radio-group context-menu-radio-item) == []

    assert html |> slots() |> length() == 14

    assert html =~ ~s(data-component="context-menu")
    assert html =~ ~s(phx-hook="SaladUI")
    assert html =~ ~s(id="cm")
    assert html =~ ~s(&quot;open&quot;:&quot;opened&quot;)

    for part <- ~w(root trigger positioner content group label item shortcut sub sub-trigger
                   sub-positioner sub-content separator checkbox-item radio-group radio-item) do
      assert html =~ ~s(data-part="#{part}"), "missing part #{part}"
    end
  end

  test "trigger renders a span that suppresses the iOS callout" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.context_menu_trigger disabled class="h-20">Area</.context_menu_trigger>
      """)

    assert html =~ ~r/^<span/
    assert html =~ "[-webkit-touch-callout:none]"
    assert html =~ "h-20"
    assert html =~ "data-disabled"
  end

  test "content is a hidden, focusable menu panel on the requested side" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.context_menu_content side="top">
        <.context_menu_item>Back</.context_menu_item>
      </.context_menu_content>
      """)

    assert html =~ ~r/data-part="positioner"[^>]*data-side="top"[^>]*hidden/
    assert html =~ ~s(role="menu")
    assert html =~ ~s(tabindex="-1")
    assert html =~ "max-h-(--context-menu-content-available-height)"
    assert html =~ "data-[state=open]:animate-in"
  end

  test "items carry variant, inset, disabled and value" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.context_menu_item variant="destructive" inset disabled value="delete">
        Delete
      </.context_menu_item>
      """)

    assert html =~ ~s(role="menuitem")
    assert html =~ ~s(data-variant="destructive")
    assert html =~ "data-inset"
    assert html =~ "data-disabled"
    assert html =~ ~s(aria-disabled="true")
    assert html =~ ~s(data-value="delete")
    assert html =~ "data-[variant=destructive]:text-destructive"
  end

  test "checkbox items reflect their checked state" do
    assigns = %{}

    checked =
      rendered_to_string(~H"""
      <.context_menu_checkbox_item checked>On</.context_menu_checkbox_item>
      """)

    unchecked =
      rendered_to_string(~H"""
      <.context_menu_checkbox_item>Off</.context_menu_checkbox_item>
      """)

    assert checked =~ ~s(data-state="checked")
    assert checked =~ ~s(aria-checked="true")
    assert unchecked =~ ~s(data-state="unchecked")
    assert unchecked =~ ~s(aria-checked="false")
    assert unchecked =~ ~r/data-part="item-indicator"[^>]*hidden/
  end

  test "radio groups carry the selected value and event mapping" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.context_menu_radio_group value="light" on-value-changed="theme">
        <.context_menu_radio_item value="light">Light</.context_menu_radio_item>
      </.context_menu_radio_group>
      """)

    assert html =~ ~s(data-part="radio-group" data-value="light")
    assert html =~ ~s(&quot;value-changed&quot;:&quot;theme&quot;)
    assert html =~ ~s(role="menuitemradio")
  end

  test "sub content renders a sub-positioner with offsets" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.context_menu_sub_content side="left" align="end" side-offset={4} align-offset={2}>
        <.context_menu_item>Save</.context_menu_item>
      </.context_menu_sub_content>
      """)

    assert html =~
             ~s(data-part="sub-positioner" data-side="left" data-align="end" data-side-offset="4" data-align-offset="2")
  end

  test "content renders collision-padding for the positioner" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.context_menu id="c">
        <.context_menu_content collision-padding={6}>x</.context_menu_content>
      </.context_menu>
      """)

    assert html =~ ~s(data-collision-padding="6")
  end
end
