defmodule SaladStorybookWeb.ToastStoryTest do
  @moduledoc """
  Drives the "Promise" button of the toast story's sonner-types variation:
  one loading toast, resolved in place to success from handle_async/3.
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the promise button shows a loading toast, then morphs the same id into success", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/salad_ui_component/toast")

    child =
      Enum.find([view | live_children(view)], &has_element?(&1, "#toast-types-promise button"))

    child |> element("#toast-types-promise button", "Promise") |> render_click()

    assert_push_event(child, "saladui:command", %{
      command: "add",
      target: "toaster-types",
      params: %{id: id, variant: "loading", title: "Loading..."}
    })

    render_async(child, 5000)

    assert_push_event(child, "saladui:command", %{
      command: "update",
      target: "toaster-types",
      params: %{id: ^id, variant: "success", title: "Event has been created"}
    })
  end
end
