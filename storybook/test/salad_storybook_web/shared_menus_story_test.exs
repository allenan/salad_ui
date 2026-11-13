defmodule SaladStorybookWeb.SharedMenusStoryTest do
  @moduledoc """
  Drives the shared menus example the way the client does: `phx-click` items
  receive the open row's context as `phx-value-*` (strings), string
  `on-select` handlers receive it merged into their payload (JSON types).
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp example(conn) do
    {:ok, view, _html} = live(conn, "/examples/shared_menus")
    [child] = live_children(view)
    child
  end

  test "rows render detached triggers and the menus render once", %{conn: conn} do
    html = conn |> example() |> render()
    fragment = Floki.parse_fragment!(html)

    assert fragment |> Floki.find(~s([data-salad-for="shared-menus-more"])) |> length() == 20
    assert fragment |> Floki.find(~s([data-salad-for="shared-menus-context"])) |> length() == 20
    assert fragment |> Floki.find(~s([data-slot="dropdown-menu-content"])) |> length() == 1
    assert fragment |> Floki.find(~s([data-slot="context-menu-content"])) |> length() == 1
  end

  test "items act on the row from the context", %{conn: conn} do
    view = example(conn)

    render_click(view, "reply", %{"id" => "3"})
    assert view |> element("#shared-menus-last") |> render() =~ "Reply to message 3"

    render_hook(view, "pin", %{"id" => 4, "value" => "Pin"})
    assert view |> element("#messages-4") |> render() =~ "pinned"

    render_click(view, "delete", %{"id" => "5"})
    refute has_element?(view, "#messages-5")
  end
end
