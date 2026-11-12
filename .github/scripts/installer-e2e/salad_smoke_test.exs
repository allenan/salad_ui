# Copied into a freshly generated Phoenix app by installer-e2e.sh.
# __USE_SALAD__ is replaced with `use SaladUI` (setup mode) or
# `use DemoWeb.UI` (install mode).
defmodule DemoWeb.SaladSmokeLive do
  use Phoenix.LiveView
  __USE_SALAD__

  def render(assigns) do
    ~H"""
    <.button variant="outline">SmokeButton</.button>
    <.badge variant="secondary">SmokeBadge</.badge>
    <.card>
      <.card_header><.card_title>SmokeCard</.card_title></.card_header>
      <.card_content>SmokeCardBody</.card_content>
    </.card>
    <.avatar>
      <.avatar_image src="/images/avatar.png" alt="avatar" />
      <.avatar_fallback>SmokeAvatar</.avatar_fallback>
    </.avatar>
    <.dialog id="smoke-dialog">
      <.dialog_trigger>SmokeDialogTrigger</.dialog_trigger>
      <.dialog_content>
        <.dialog_header><.dialog_title>SmokeDialogTitle</.dialog_title></.dialog_header>
      </.dialog_content>
    </.dialog>
    <.tabs id="smoke-tabs" default="a">
      <.tabs_list>
        <.tabs_trigger value="a">SmokeTabA</.tabs_trigger>
        <.tabs_trigger value="b">SmokeTabB</.tabs_trigger>
      </.tabs_list>
      <.tabs_content value="a">SmokeTabAContent</.tabs_content>
      <.tabs_content value="b">SmokeTabBContent</.tabs_content>
    </.tabs>
    <.select id="smoke-select" name="fruit" default-value="apple">
      <.select_trigger><.select_value placeholder="SmokeSelect" /></.select_trigger>
      <.select_content><.select_item value="apple">SmokeApple</.select_item></.select_content>
    </.select>
    <.dropdown_menu id="smoke-menu">
      <.dropdown_menu_trigger>SmokeMenu</.dropdown_menu_trigger>
      <.dropdown_menu_content>
        <.dropdown_menu_item>SmokeMenuItem</.dropdown_menu_item>
      </.dropdown_menu_content>
    </.dropdown_menu>
    <.tooltip id="smoke-tooltip">
      <.tooltip_trigger>SmokeTooltipTrigger</.tooltip_trigger>
      <.tooltip_content>SmokeTooltip</.tooltip_content>
    </.tooltip>
    """
  end
end

defmodule DemoWeb.SaladSmokeTest do
  use DemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "SaladUI components mount inside a real LiveView", %{conn: conn} do
    {:ok, view, html} = live_isolated(conn, DemoWeb.SaladSmokeLive)

    for text <-
          ~w(SmokeButton SmokeBadge SmokeCard SmokeAvatar SmokeDialogTrigger SmokeTabA SmokeApple SmokeMenu SmokeTooltip) do
      assert html =~ text
    end

    assert html =~ ~s(phx-hook="SaladUI")
    assert render(view) =~ "smoke-dialog"
  end
end
