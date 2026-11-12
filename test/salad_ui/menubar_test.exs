defmodule SaladUI.MenubarTest do
  use ComponentCase

  import SaladUI.Menubar

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
      <.menubar id="mb" class="w-72" on-value-changed="menu_changed">
        <.menubar_menu value="file">
          <.menubar_trigger>File</.menubar_trigger>
          <.menubar_content>
            <.menubar_group>
              <.menubar_label>Tabs</.menubar_label>
              <.menubar_item on-select="new_tab">
                New Tab
                <.menubar_shortcut>⌘T</.menubar_shortcut>
              </.menubar_item>
            </.menubar_group>
            <.menubar_separator />
            <.menubar_sub>
              <.menubar_sub_trigger>Share</.menubar_sub_trigger>
              <.menubar_sub_content>
                <.menubar_item>Email link</.menubar_item>
              </.menubar_sub_content>
            </.menubar_sub>
          </.menubar_content>
        </.menubar_menu>
        <.menubar_menu value="view">
          <.menubar_trigger>View</.menubar_trigger>
          <.menubar_content class="w-44">
            <.menubar_checkbox_item checked>Full URLs</.menubar_checkbox_item>
            <.menubar_radio_group value="benoit">
              <.menubar_radio_item value="andy">Andy</.menubar_radio_item>
              <.menubar_radio_item value="benoit">Benoit</.menubar_radio_item>
            </.menubar_radio_group>
          </.menubar_content>
        </.menubar_menu>
      </.menubar>
      """)

    expected =
      ~w(menubar menubar-menu menubar-trigger menubar-content menubar-group menubar-label
         menubar-item menubar-shortcut menubar-separator menubar-sub menubar-sub-trigger
         menubar-sub-content menubar-checkbox-item menubar-radio-group menubar-radio-item)

    assert Enum.sort(slots(html)) == Enum.sort(expected)

    assert html =~ ~s(data-component="menubar")
    assert html =~ ~s(role="menubar")
    assert html =~ ~s(phx-hook="SaladUI")
    assert html =~ ~s(&quot;value-changed&quot;:&quot;menu_changed&quot;)
    assert html =~ ~s(&quot;loop&quot;:true)
    assert html =~ "flex h-9 items-center gap-1 rounded-md border bg-background p-1 shadow-xs"
    assert html =~ ~s(data-part="menu" data-value="file")
  end

  test "triggers are menuitem buttons that open a menu" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.menubar_trigger disabled>File</.menubar_trigger>
      """)

    assert html =~ ~r/^<button/
    assert html =~ ~s(type="button")
    assert html =~ ~s(role="menuitem")
    assert html =~ ~s(aria-haspopup="menu")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ "disabled"
    assert html =~ "data-[state=open]:bg-accent"
  end

  test "content defaults to shadcn's bottom/start placement with 8/-4 offsets" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.menubar_content>
        <.menubar_item>Undo</.menubar_item>
      </.menubar_content>
      """)

    assert html =~
             ~s(data-part="positioner" data-side="bottom" data-align="start" data-side-offset="8" data-align-offset="-4")

    assert html =~ "min-w-[12rem]"
    assert html =~ ~s(role="menu")
  end

  test "items carry variant, inset and disabled" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.menubar_item inset disabled>Force Reload</.menubar_item>
      <.menubar_item variant="destructive">Delete</.menubar_item>
      """)

    assert html =~ "data-inset"
    assert html =~ "data-disabled"
    assert html =~ ~s(data-variant="destructive")
  end

  test "checkable items use menubar's rounded-xs classes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.menubar_checkbox_item>Code</.menubar_checkbox_item>
      <.menubar_radio_group value="light">
        <.menubar_radio_item value="light">Light</.menubar_radio_item>
      </.menubar_radio_group>
      """)

    assert html =~ ~s(role="menuitemcheckbox")
    assert html =~ ~s(role="menuitemradio")
    assert html =~ "rounded-xs py-1.5 pr-2 pl-8"
  end
end
