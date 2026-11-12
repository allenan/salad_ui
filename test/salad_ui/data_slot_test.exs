defmodule SaladUI.DataSlotTest do
  @moduledoc """
  Every rendered part carries shadcn/ui's `data-slot` name, so selectors such as
  `has-data-[slot=card-action]:` and `*:data-[slot=select-value]:` behave the
  same as in shadcn. One assertion per component: all expected slots render,
  and no element carries `data-slot` twice (a wrapped component that re-labels
  its child must override the child's slot, not add a second one).
  """
  use ComponentCase
  use SaladUI

  import SaladUI.Command

  defp slots(html) do
    ~r/<[a-zA-Z][^>]*>/
    |> Regex.scan(html)
    |> Enum.flat_map(fn [tag] -> Regex.scan(~r/\sdata-slot="([^"]+)"/, tag, capture: :all_but_first) end)
    |> List.flatten()
  end

  defp duplicated(html) do
    for [tag] <- Regex.scan(~r/<[a-zA-Z][^>]*>/, html),
        length(Regex.scan(~r/\sdata-slot=/, tag)) > 1,
        do: tag
  end

  # Returns {missing_slots, tags_with_duplicate_slots}; both must be empty.
  defp check(rendered, expected) do
    html = rendered_to_string(rendered)
    {expected -- slots(html), duplicated(html)}
  end

  test "accordion" do
    assigns = %{}

    assert check(
             ~H"""
             <.accordion id="a">
               <.accordion_item value="1">
                 <.accordion_trigger>Q</.accordion_trigger>
                 <.accordion_content>A</.accordion_content>
               </.accordion_item>
             </.accordion>
             """,
             ~w(accordion accordion-item accordion-trigger accordion-content)
           ) == {[], []}
  end

  test "alert" do
    assigns = %{}

    assert check(
             ~H"""
             <.alert>
               <.alert_title>T</.alert_title>
               <.alert_description>D</.alert_description>
             </.alert>
             """,
             ~w(alert alert-title alert-description)
           ) == {[], []}
  end

  test "alert dialog" do
    assigns = %{}

    assert check(
             ~H"""
             <.alert_dialog id="ad">
               <.alert_dialog_trigger>Open</.alert_dialog_trigger>
               <.alert_dialog_content>
                 <.alert_dialog_header>
                   <.alert_dialog_title>T</.alert_dialog_title>
                   <.alert_dialog_description>D</.alert_dialog_description>
                 </.alert_dialog_header>
                 <.alert_dialog_footer>
                   <.alert_dialog_cancel>Cancel</.alert_dialog_cancel>
                   <.alert_dialog_action>OK</.alert_dialog_action>
                 </.alert_dialog_footer>
               </.alert_dialog_content>
             </.alert_dialog>
             """,
             ~w(alert-dialog alert-dialog-trigger alert-dialog-portal alert-dialog-overlay
                alert-dialog-content alert-dialog-header alert-dialog-title
                alert-dialog-description alert-dialog-footer alert-dialog-cancel alert-dialog-action)
           ) == {[], []}
  end

  test "avatar" do
    assigns = %{}

    assert check(
             ~H"""
             <.avatar>
               <.avatar_image src="/a.png" />
               <.avatar_fallback>AB</.avatar_fallback>
             </.avatar>
             """,
             ~w(avatar avatar-image avatar-fallback)
           ) == {[], []}
  end

  test "badge" do
    assigns = %{}
    assert check(~H"<.badge>B</.badge>", ~w(badge)) == {[], []}
  end

  test "breadcrumb" do
    assigns = %{}

    assert check(
             ~H"""
             <.breadcrumb>
               <.breadcrumb_list>
                 <.breadcrumb_item><.breadcrumb_link href="/">Home</.breadcrumb_link></.breadcrumb_item>
                 <.breadcrumb_separator />
                 <.breadcrumb_item><.breadcrumb_ellipsis /></.breadcrumb_item>
                 <.breadcrumb_item>
                   <.breadcrumb_page>Here</.breadcrumb_page>
                 </.breadcrumb_item>
               </.breadcrumb_list>
             </.breadcrumb>
             """,
             ~w(breadcrumb breadcrumb-list breadcrumb-item breadcrumb-link breadcrumb-separator
                breadcrumb-ellipsis breadcrumb-page)
           ) == {[], []}
  end

  test "button" do
    assigns = %{}
    assert check(~H"<.button>B</.button>", ~w(button)) == {[], []}
  end

  test "card" do
    assigns = %{}

    assert check(
             ~H"""
             <.card>
               <.card_header>
                 <.card_title>T</.card_title>
                 <.card_description>D</.card_description>
               </.card_header>
               <.card_content>C</.card_content>
               <.card_footer>F</.card_footer>
             </.card>
             """,
             ~w(card card-header card-title card-description card-content card-footer)
           ) == {[], []}
  end

  test "chart" do
    assigns = %{}

    assert check(
             ~H"""
             <.chart id="c" chart-options={%{}} chart-data={[]} />
             """,
             ~w(chart)
           ) == {[], []}
  end

  test "checkbox" do
    assigns = %{name: "x"}
    assert check(~H"<.checkbox name={@name} />", ~w(checkbox)) == {[], []}
  end

  test "collapsible" do
    assigns = %{}

    assert check(
             ~H"""
             <.collapsible id="col">
               <.collapsible_trigger>T</.collapsible_trigger>
               <.collapsible_content>C</.collapsible_content>
             </.collapsible>
             """,
             ~w(collapsible collapsible-trigger collapsible-content)
           ) == {[], []}
  end

  test "command" do
    assigns = %{}

    assert check(
             ~H"""
             <.command_dialog id="cmd">
               <.command_input placeholder="Search" />
               <.command_list>
                 <.command_empty>None</.command_empty>
                 <.command_group heading="G">
                   <.command_item>
                     Item
                     <.command_shortcut>⌘K</.command_shortcut>
                   </.command_item>
                 </.command_group>
               </.command_list>
             </.command_dialog>
             """,
             ~w(dialog dialog-content command command-input-wrapper command-input command-list
                command-empty command-group command-item command-shortcut)
           ) == {[], []}
  end

  test "dialog" do
    assigns = %{}

    assert check(
             ~H"""
             <.dialog id="d">
               <.dialog_trigger>Open</.dialog_trigger>
               <.dialog_content>
                 <.dialog_header>
                   <.dialog_title>T</.dialog_title>
                   <.dialog_description>D</.dialog_description>
                 </.dialog_header>
                 <.dialog_footer>F</.dialog_footer>
               </.dialog_content>
             </.dialog>
             """,
             ~w(dialog dialog-trigger dialog-portal dialog-overlay dialog-content dialog-close
                dialog-header dialog-title dialog-description dialog-footer)
           ) == {[], []}
  end

  test "dropdown menu" do
    assigns = %{}

    assert check(
             ~H"""
             <.dropdown_menu id="dm">
               <.dropdown_menu_trigger>Open</.dropdown_menu_trigger>
               <.dropdown_menu_content>
                 <.dropdown_menu_label>L</.dropdown_menu_label>
                 <.dropdown_menu_separator />
                 <.dropdown_menu_group>
                   <.dropdown_menu_item>
                     A
                     <.dropdown_menu_shortcut>⌘A</.dropdown_menu_shortcut>
                   </.dropdown_menu_item>
                   <.dropdown_menu_checkbox_item value="b">B</.dropdown_menu_checkbox_item>
                 </.dropdown_menu_group>
               </.dropdown_menu_content>
             </.dropdown_menu>
             """,
             ~w(dropdown-menu dropdown-menu-trigger dropdown-menu-content dropdown-menu-label
                dropdown-menu-separator dropdown-menu-group dropdown-menu-item dropdown-menu-shortcut
                dropdown-menu-checkbox-item)
           ) == {[], []}
  end

  test "form" do
    assigns = %{}

    assert check(
             ~H"""
             <.form_item>
               <.form_label>Name</.form_label>
               <.form_control><.input name="n" /></.form_control>
               <.form_description>D</.form_description>
               <.form_message errors={["is required"]} />
             </.form_item>
             """,
             ~w(form-item form-label input form-description form-message)
           ) == {[], []}
  end

  test "hover card" do
    assigns = %{}

    assert check(
             ~H"""
             <.hover_card id="hc">
               <.hover_card_trigger>T</.hover_card_trigger>
               <.hover_card_content>C</.hover_card_content>
             </.hover_card>
             """,
             ~w(hover-card hover-card-trigger hover-card-portal hover-card-content)
           ) == {[], []}
  end

  # shadcn has no standalone menu; its parts follow shadcn's `<component>-<part>` scheme.
  test "menu" do
    assigns = %{}

    assert check(
             ~H"""
             <.menu>
               <.menu_label>L</.menu_label>
               <.menu_separator />
               <.menu_group>
                 <.menu_item>
                   A
                   <.menu_shortcut>⌘A</.menu_shortcut>
                 </.menu_item>
               </.menu_group>
             </.menu>
             """,
             ~w(menu menu-label menu-separator menu-group menu-item menu-shortcut)
           ) == {[], []}
  end

  test "input" do
    assigns = %{name: "x"}
    assert check(~H"<.input name={@name} />", ~w(input)) == {[], []}
  end

  test "label" do
    assigns = %{}
    assert check(~H"<.label>L</.label>", ~w(label)) == {[], []}
  end

  test "pagination" do
    assigns = %{}

    assert check(
             ~H"""
             <.pagination>
               <.pagination_content>
                 <.pagination_item><.pagination_previous href="#" /></.pagination_item>
                 <.pagination_item><.pagination_link href="#">1</.pagination_link></.pagination_item>
                 <.pagination_item><.pagination_ellipsis /></.pagination_item>
                 <.pagination_item><.pagination_next href="#" /></.pagination_item>
               </.pagination_content>
             </.pagination>
             """,
             ~w(pagination pagination-content pagination-item pagination-link pagination-ellipsis)
           ) == {[], []}
  end

  test "popover" do
    assigns = %{}

    assert check(
             ~H"""
             <.popover id="p">
               <.popover_trigger>T</.popover_trigger>
               <.popover_content>C</.popover_content>
             </.popover>
             """,
             ~w(popover popover-trigger popover-content)
           ) == {[], []}
  end

  test "progress" do
    assigns = %{}
    assert check(~H"<.progress value={40} />", ~w(progress progress-indicator)) == {[], []}
  end

  test "radio group" do
    assigns = %{}

    assert check(
             ~H"""
             <.radio_group name="r">
               <.radio_group_item id="r1" value="a" />
             </.radio_group>
             """,
             ~w(radio-group radio-group-item radio-group-indicator)
           ) == {[], []}
  end

  test "scroll area" do
    assigns = %{}
    assert check(~H"<.scroll_area>C</.scroll_area>", ~w(scroll-area scroll-area-viewport)) == {[], []}
  end

  test "select" do
    assigns = %{}

    assert check(
             ~H"""
             <.select id="s" name="s">
               <.select_trigger><.select_value placeholder="Pick" /></.select_trigger>
               <.select_content>
                 <.select_group>
                   <.select_label>L</.select_label>
                   <.select_item value="a">A</.select_item>
                   <.select_separator />
                 </.select_group>
               </.select_content>
             </.select>
             """,
             ~w(select select-trigger select-value select-content select-group select-label
                select-item select-item-indicator select-separator)
           ) == {[], []}
  end

  test "separator" do
    assigns = %{}
    assert check(~H"<.separator />", ~w(separator)) == {[], []}
  end

  test "sheet" do
    assigns = %{}

    assert check(
             ~H"""
             <.sheet id="sh">
               <.sheet_trigger>Open</.sheet_trigger>
               <.sheet_content>
                 <.sheet_header>
                   <.sheet_title>T</.sheet_title>
                   <.sheet_description>D</.sheet_description>
                 </.sheet_header>
                 <.sheet_footer>
                   <.sheet_close>Close</.sheet_close>
                 </.sheet_footer>
               </.sheet_content>
             </.sheet>
             """,
             ~w(sheet sheet-trigger sheet-portal sheet-overlay sheet-content sheet-close
                sheet-header sheet-title sheet-description sheet-footer)
           ) == {[], []}
  end

  test "sidebar" do
    assigns = %{}

    assert check(
             ~H"""
             <.sidebar_provider>
               <.sidebar id="sb">
                 <.sidebar_header><.sidebar_input placeholder="Search" /></.sidebar_header>
                 <.sidebar_separator />
                 <.sidebar_content>
                   <.sidebar_group>
                     <.sidebar_group_label>G</.sidebar_group_label>
                     <.sidebar_group_action>+</.sidebar_group_action>
                     <.sidebar_group_content>
                       <.sidebar_menu>
                         <.sidebar_menu_item>
                           <.sidebar_menu_button tooltip="Home">Home</.sidebar_menu_button>
                           <.sidebar_menu_action>...</.sidebar_menu_action>
                           <.sidebar_menu_badge>3</.sidebar_menu_badge>
                           <.sidebar_menu_sub>
                             <.sidebar_menu_sub_item>
                               <.sidebar_menu_sub_button>Sub</.sidebar_menu_sub_button>
                             </.sidebar_menu_sub_item>
                           </.sidebar_menu_sub>
                         </.sidebar_menu_item>
                         <.sidebar_menu_item><.sidebar_menu_skeleton /></.sidebar_menu_item>
                       </.sidebar_menu>
                     </.sidebar_group_content>
                   </.sidebar_group>
                 </.sidebar_content>
                 <.sidebar_footer>F</.sidebar_footer>
                 <.sidebar_rail />
               </.sidebar>
               <.sidebar_inset><.sidebar_trigger target="sb" /></.sidebar_inset>
             </.sidebar_provider>
             <.sidebar id="sb-static" collapsible="none">S</.sidebar>
             <.sidebar id="sb-mobile" is_mobile>M</.sidebar>
             """,
             ~w(sidebar-wrapper sidebar sidebar-gap sidebar-container sidebar-inner sidebar-header
                sidebar-input sidebar-separator sidebar-content sidebar-group sidebar-group-label
                sidebar-group-action sidebar-group-content sidebar-menu sidebar-menu-item
                sidebar-menu-button tooltip tooltip-trigger tooltip-content sidebar-menu-action
                sidebar-menu-badge sidebar-menu-sub sidebar-menu-sub-item sidebar-menu-sub-button
                sidebar-menu-skeleton skeleton sidebar-footer sidebar-rail sidebar-inset
                sidebar-trigger sidebar sidebar sheet)
           ) == {[], []}
  end

  test "skeleton" do
    assigns = %{}
    assert check(~H"<.skeleton />", ~w(skeleton)) == {[], []}
  end

  test "slider" do
    assigns = %{name: "x"}

    assert check(
             ~H"<.slider id={@name} value={50} />",
             ~w(slider slider-track slider-range slider-thumb)
           ) == {[], []}
  end

  test "switch" do
    assigns = %{name: "x"}
    assert check(~H"<.switch id={@name} name={@name} />", ~w(switch switch-thumb)) == {[], []}
  end

  test "table" do
    assigns = %{}

    assert check(
             ~H"""
             <.table>
               <.table_caption>Cap</.table_caption>
               <.table_header>
                 <.table_row>
                   <.table_head>H</.table_head>
                 </.table_row>
               </.table_header>
               <.table_body>
                 <.table_row>
                   <.table_cell>C</.table_cell>
                 </.table_row>
               </.table_body>
               <.table_footer>
                 <.table_row>
                   <.table_cell>F</.table_cell>
                 </.table_row>
               </.table_footer>
             </.table>
             """,
             ~w(table table-caption table-header table-row table-head table-body table-cell table-footer)
           ) == {[], []}
  end

  test "tabs" do
    assigns = %{}

    assert check(
             ~H"""
             <.tabs id="t" default="a">
               <.tabs_list>
                 <.tabs_trigger value="a">A</.tabs_trigger>
               </.tabs_list>
               <.tabs_content value="a">A</.tabs_content>
             </.tabs>
             """,
             ~w(tabs tabs-list tabs-trigger tabs-content)
           ) == {[], []}
  end

  test "textarea" do
    assigns = %{name: "x"}
    assert check(~H"<.textarea name={@name} />", ~w(textarea)) == {[], []}
  end

  test "toggle" do
    assigns = %{}
    assert check(~H"<.toggle>B</.toggle>", ~w(toggle)) == {[], []}
  end

  test "toggle group" do
    assigns = %{}

    assert check(
             ~H"""
             <.toggle_group :let={builder} name="tg" value="a">
               <.toggle_group_item value="a" builder={builder}>A</.toggle_group_item>
             </.toggle_group>
             """,
             ~w(toggle-group toggle-group-item)
           ) == {[], []}
  end

  test "tooltip" do
    assigns = %{}

    assert check(
             ~H"""
             <.tooltip>
               <.tooltip_trigger>T</.tooltip_trigger>
               <.tooltip_content>C</.tooltip_content>
             </.tooltip>
             """,
             ~w(tooltip tooltip-trigger tooltip-content)
           ) == {[], []}
  end

  test "item" do
    assigns = %{}

    assert check(
             ~H"""
             <.item_group>
               <.item>
                 <.item_header>H</.item_header>
                 <.item_media variant="icon">M</.item_media>
                 <.item_content>
                   <.item_title>T</.item_title>
                   <.item_description>D</.item_description>
                 </.item_content>
                 <.item_actions>A</.item_actions>
                 <.item_footer>F</.item_footer>
               </.item>
               <.item_separator />
               <.item href="#">L</.item>
             </.item_group>
             """,
             ~w(item-group item item-header item-media item-content item-title item-description item-actions item-footer item-separator item)
           ) == {[], []}
  end

  test "empty" do
    assigns = %{}

    assert check(
             ~H"""
             <.empty>
               <.empty_header>
                 <.empty_media variant="icon">M</.empty_media>
                 <.empty_title>T</.empty_title>
                 <.empty_description>D</.empty_description>
               </.empty_header>
               <.empty_content>C</.empty_content>
             </.empty>
             """,
             ~w(empty empty-header empty-icon empty-title empty-description empty-content)
           ) == {[], []}
  end

  test "kbd, spinner and aspect ratio" do
    assigns = %{}

    assert check(
             ~H"""
             <.kbd_group>
               <.kbd>A</.kbd>
             </.kbd_group>
             <.spinner />
             <.spinner><svg></svg></.spinner>
             <.aspect_ratio ratio={1}>X</.aspect_ratio>
             """,
             ~w(kbd-group kbd spinner spinner aspect-ratio)
           ) == {[], []}
  end
end
