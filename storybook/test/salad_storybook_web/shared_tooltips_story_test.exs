defmodule SaladStorybookWeb.SharedTooltipsStoryTest do
  @moduledoc """
  The shared tooltips example renders no tooltip or hover card markup per row,
  and its shared status card is filled by `on-open` from the row's context.
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp example(conn) do
    {:ok, view, _html} = live(conn, "/examples/shared_tooltips")
    [child] = live_children(view)
    child
  end

  test "rows carry triggers only; the popups render once", %{conn: conn} do
    fragment = conn |> example() |> render() |> Floki.parse_fragment!()

    assert fragment |> Floki.find("[data-salad-tooltip]") |> length() == 60
    assert fragment |> Floki.find(~s([data-salad-for="shared-tooltips-status"])) |> length() == 20
    assert fragment |> Floki.find(~s([data-component="tooltip-provider"])) |> length() == 1
    # One card per author, plus the shared status card.
    assert fragment |> Floki.find(~s([data-component="hover-card"])) |> length() == 6
    assert Floki.find(fragment, ~s([data-component="tooltip"])) == []
  end

  test "the shared status card shows what on-open assigned for the row", %{conn: conn} do
    view = example(conn)

    render_hook(view, "show_status", %{"id" => 7})

    assert view |> element("#shared-tooltips-status-text") |> render() =~ "Message 7"
  end
end
