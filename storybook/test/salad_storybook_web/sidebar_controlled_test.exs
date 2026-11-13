defmodule SaladStorybookWeb.SidebarControlledTest do
  @moduledoc """
  Drives the controlled sidebar example: `open` reaches the provider as
  `data-open`, and `on-open-change` updates the LiveView's assign.
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @path SaladStorybookWeb.Storybook.leaves()
        |> Enum.map(& &1.path)
        |> Enum.find(&String.ends_with?(&1, "sidebar_controlled"))

  defp mount_example(conn) do
    {:ok, page, _html} = live(conn, @path)
    page |> live_children() |> Enum.find(&has_element?(&1, "#sidebar-controlled-live"))
  end

  test "the server's open state reaches the provider", %{conn: conn} do
    view = mount_example(conn)

    assert view |> element("#sidebar-controlled-live") |> render() =~ ~s(data-open="false")

    view |> element("button[phx-value-open=true]") |> render_click()
    assert view |> element("#sidebar-controlled-live") |> render() =~ ~s(data-open="true")
  end

  test "on-open-change updates the assign", %{conn: conn} do
    view = mount_example(conn)

    render_hook(view, "sidebar_open_change", %{"open" => true})
    assert view |> element("#sidebar-controlled-status") |> render() =~ "open: true"
    assert view |> element("#sidebar-controlled-status") |> render() =~ "client changes: 1"
    assert view |> element("#sidebar-controlled-live") |> render() =~ ~s(data-open="true")
  end
end
