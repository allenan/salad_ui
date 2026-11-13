defmodule SaladStorybookWeb.ComboboxStoriesTest do
  @moduledoc """
  Drives the combobox examples' server events the way the JS components push
  them.
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp example(conn, path) do
    {:ok, view, _html} = live(conn, path)
    [child] = live_children(view)
    child
  end

  defp languages(view) do
    view
    |> element("#project_language-list")
    |> render()
    |> Floki.parse_fragment!()
    |> Floki.find(~s([data-part="item"]))
    |> Enum.map(&(&1 |> Floki.attribute("data-value") |> List.first()))
  end

  test "server filtering: reopening resets the results to every language", %{conn: conn} do
    view = example(conn, "/examples/combobox_server")
    all = languages(view)

    view
    |> element("#combobox-server-form")
    |> render_change(%{"query" => "ru", "project" => %{"language" => ""}})

    assert Enum.sort(languages(view)) == ["Ruby", "Rust"]

    # Picking keeps the server query; the combobox reopens with "".
    render_hook(view, "search_opened", %{"query" => ""})
    assert Enum.sort(languages(view)) == Enum.sort(all)

    # Opened by typing: the payload carries the typed query.
    render_hook(view, "search_opened", %{"query" => "go"})
    assert languages(view) == ["Go"]
  end

  test "popover: picking a status shows it on the trigger", %{conn: conn} do
    view = example(conn, "/examples/combobox_popover")
    assert render(view) =~ "+ Set status"

    view
    |> element(~s(#status-command [phx-value-status="done"]))
    |> render_click()

    assert view |> element("#status-popover") |> render() =~ "Done"

    view
    |> element(~s(#responsive-drawer-command [phx-value-status="todo"]))
    |> render_click()

    assert view |> element("#responsive-popover") |> render() =~ "Todo"
    assert view |> element("#responsive-drawer") |> render() =~ "Todo"
  end
end
