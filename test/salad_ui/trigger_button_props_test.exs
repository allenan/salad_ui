defmodule SaladUI.TriggerButtonPropsTest do
  @moduledoc """
  Trigger parts take `variant`/`size` (no undefined-attribute warning) so
  `as={&button/1}` can style the button, and drop them for plain tags.
  """
  use ComponentCase

  import SaladUI.Button
  import SaladUI.Dialog
  import SaladUI.DropdownMenu
  import SaladUI.Popover

  test "as={&button/1} forwards variant and size to the button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.popover_trigger as={&button/1} variant="outline" size="sm">Open</.popover_trigger>
      <.dropdown_menu_trigger as={&button/1} variant="ghost" size="icon">Menu</.dropdown_menu_trigger>
      <.dialog_trigger as={&button/1} variant="secondary">Dialog</.dialog_trigger>
      """)

    assert html =~ ~r/data-variant="outline" data-size="sm"[^>]*data-slot="popover-trigger"/
    assert html =~ ~r/data-variant="ghost" data-size="icon"[^>]*data-slot="dropdown-menu-trigger"/
    assert html =~ ~r/data-variant="secondary"[^>]*bg-secondary[^>]*data-slot="dialog-trigger"/
    refute html =~ ~r/\svariant=/
    refute html =~ ~r/\ssize=/
  end

  test "plain tags drop variant and size instead of rendering them as attributes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.popover_trigger variant="outline">Open</.popover_trigger>
      <.dialog_trigger variant="outline" size="sm">Open</.dialog_trigger>
      """)

    refute html =~ ~r/\svariant=/
    refute html =~ ~r/\ssize=/
  end
end
