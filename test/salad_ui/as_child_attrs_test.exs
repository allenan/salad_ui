defmodule SaladUI.AsChildAttrsTest do
  @moduledoc """
  A part rendered through another component (`as={&button/1}`, or
  `as_child tag={...} child={...}`) carries each attribute once, and the
  wrapping part's `data-*` labels win, as in shadcn where `asChild` spreads the
  wrapper's props last. A duplicated attribute means the browser keeps the
  child's copy, so e.g. `[data-slot=collapsible-trigger]` never matches.
  """
  use ComponentCase
  use SaladUI

  @wrappers [
    {&collapsible_trigger/1, "collapsible-trigger"},
    {&popover_trigger/1, "popover-trigger"},
    {&dropdown_menu_trigger/1, "dropdown-menu-trigger"},
    {&dropdown_menu_item/1, "dropdown-menu-item"},
    {&dialog_trigger/1, "dialog-trigger"},
    {&dialog_close/1, "dialog-close"},
    {&alert_dialog_trigger/1, "alert-dialog-trigger"},
    {&drawer_trigger/1, "drawer-trigger"},
    {&drawer_close/1, "drawer-close"},
    {&context_menu_trigger/1, "context-menu-trigger"},
    {&context_menu_item/1, "context-menu-item"},
    {&menubar_item/1, "menubar-item"},
    {&sidebar_group_label/1, "sidebar-group-label"},
    {&sidebar_menu_button/1, "sidebar-menu-button"},
    {&sidebar_menu_sub_button/1, "sidebar-menu-sub-button"},
    {&button_group_text/1, "button-group-text"}
  ]

  @children [
    &button/1,
    &badge/1,
    &sidebar_menu_button/1,
    &sidebar_menu_action/1,
    &sidebar_menu_sub_button/1,
    &input_group_button/1,
    &collapsible_trigger/1
  ]

  defp render(tag, child) do
    assigns = %{tag: tag, child: child}

    rendered_to_string(~H"""
    <.as_child tag={@tag} child={@child}>X</.as_child>
    """)
  end

  test "no wrapper/child pair renders an attribute twice, and the wrapper's data-slot wins" do
    failures =
      for {tag, slot} <- @wrappers,
          child <- @children,
          html = render(tag, child),
          problem = problem(html, slot),
          do: "#{inspect(tag)} with #{inspect(child)}: #{problem}"

    assert failures == []
  end

  defp problem(html, slot) do
    cond do
      duplicate_attrs(html) != [] -> "duplicate #{inspect(Enum.flat_map(duplicate_attrs(html), &elem(&1, 1)))}"
      not (html =~ ~s(data-slot="#{slot}")) -> "data-slot is not #{slot}"
      true -> nil
    end
  end

  test "sidebar_trigger rendered as a button keeps its own data-slot" do
    html = render(&sidebar_trigger/1, &button/1)

    assert duplicate_attrs(html) == []
    assert html =~ ~s(data-slot="sidebar-trigger")
    refute html =~ ~s(data-slot="button")
  end

  test "collapsible_trigger as_child of a sidebar_menu_button carries exactly one data-slot" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.collapsible id="c">
        <.as_child tag={&collapsible_trigger/1} child={&sidebar_menu_button/1}>Toggle</.as_child>
        <.collapsible_trigger as={&button/1} variant="outline">Toggle</.collapsible_trigger>
        <.collapsible_content>C</.collapsible_content>
      </.collapsible>
      """)

    assert duplicate_attrs(html) == []
    assert html |> String.split(~s(data-slot="collapsible-trigger")) |> length() == 3
  end

  test "a menu item rendered as a button keeps the item's data-variant" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.dropdown_menu_item as={&button/1} variant="destructive">Delete</.dropdown_menu_item>
      """)

    assert duplicate_attrs(html) == []
    assert html =~ ~s(data-variant="destructive")
  end

  test "button, badge, sidebar_menu_action and input_group_button keep their own labels standalone" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button variant="outline" size="sm">B</.button>
      <.badge variant="secondary">Badge</.badge>
      <.sidebar_menu_action>A</.sidebar_menu_action>
      <.input_group_button variant="ghost" size="xs">I</.input_group_button>
      """)

    assert html =~ ~s(data-slot="button" data-variant="outline" data-size="sm")
    assert html =~ ~s(data-slot="badge" data-variant="secondary")
    assert html =~ ~s(data-slot="sidebar-menu-action" data-sidebar="menu-action")
    assert html =~ ~s(data-variant="ghost" data-size="xs")
  end
end
