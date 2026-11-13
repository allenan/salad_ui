defmodule SaladUI.MenuLoopTest do
  @moduledoc """
  Menu panels take Radix's `loop` (default `false`): `data-loop="true"` makes
  menu.js wrap ArrowDown/ArrowUp from the last item to the first and back.
  The menubar root's own `loop` (trigger navigation) still defaults to `true`.
  """
  use ComponentCase
  use SaladUI

  defp panels(html), do: Regex.scan(~r/<div[^>]*data-part="(?:sub-)?content"[^>]*>/, html)

  test "dropdown, context and menubar content (and sub-content) render no data-loop by default" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown_menu id="dm">
        <.dropdown_menu_trigger>Open</.dropdown_menu_trigger>
        <.dropdown_menu_content>
          <.dropdown_menu_item>A</.dropdown_menu_item>
          <.dropdown_menu_sub>
            <.dropdown_menu_sub_trigger>More</.dropdown_menu_sub_trigger>
            <.dropdown_menu_sub_content>
              <.dropdown_menu_item>B</.dropdown_menu_item>
            </.dropdown_menu_sub_content>
          </.dropdown_menu_sub>
        </.dropdown_menu_content>
      </.dropdown_menu>
      <.context_menu id="cm">
        <.context_menu_trigger>Here</.context_menu_trigger>
        <.context_menu_content>
          <.context_menu_item>A</.context_menu_item>
        </.context_menu_content>
      </.context_menu>
      <.menubar id="mb">
        <.menubar_menu value="file">
          <.menubar_trigger>File</.menubar_trigger>
          <.menubar_content>
            <.menubar_item>A</.menubar_item>
          </.menubar_content>
        </.menubar_menu>
      </.menubar>
      """)

    assert length(panels(html)) == 4
    refute html =~ "data-loop"
    assert html =~ ~s(data-options="{&quot;loop&quot;:true)
  end

  test "loop renders data-loop=\"true\" on each panel" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown_menu id="dm">
        <.dropdown_menu_trigger>Open</.dropdown_menu_trigger>
        <.dropdown_menu_content loop>
          <.dropdown_menu_sub>
            <.dropdown_menu_sub_trigger>More</.dropdown_menu_sub_trigger>
            <.dropdown_menu_sub_content loop>
              <.dropdown_menu_item>B</.dropdown_menu_item>
            </.dropdown_menu_sub_content>
          </.dropdown_menu_sub>
        </.dropdown_menu_content>
      </.dropdown_menu>
      <.context_menu id="cm">
        <.context_menu_trigger>Here</.context_menu_trigger>
        <.context_menu_content loop>
          <.context_menu_sub>
            <.context_menu_sub_trigger>More</.context_menu_sub_trigger>
            <.context_menu_sub_content loop>
              <.context_menu_item>B</.context_menu_item>
            </.context_menu_sub_content>
          </.context_menu_sub>
        </.context_menu_content>
      </.context_menu>
      <.menubar id="mb">
        <.menubar_menu value="file">
          <.menubar_trigger>File</.menubar_trigger>
          <.menubar_content loop>
            <.menubar_sub>
              <.menubar_sub_trigger>More</.menubar_sub_trigger>
              <.menubar_sub_content loop>
                <.menubar_item>B</.menubar_item>
              </.menubar_sub_content>
            </.menubar_sub>
          </.menubar_content>
        </.menubar_menu>
      </.menubar>
      """)

    panels = panels(html)
    assert length(panels) == 6
    assert Enum.all?(panels, fn [tag] -> tag =~ ~s(data-loop="true") end)
  end
end
