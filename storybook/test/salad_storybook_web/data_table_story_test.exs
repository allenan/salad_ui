defmodule SaladStorybookWeb.DataTableStoryTest do
  @moduledoc """
  Drives the data table examples: the rows are a LiveView stream, so these
  check that each interaction resets or re-inserts the right rows.
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp example(conn, path) do
    {:ok, view, _html} = live(conn, path)
    [child] = live_children(view)
    child
  end

  defp row_ids(view, tbody) do
    ~r/<tr[^>]*\sid="#{tbody}-([^"]+)"/
    |> Regex.scan(render(view), capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(&(&1 == "empty"))
  end

  # Menu items and the select fire their `on-*` mapping from the SaladUI JS
  # hook, which LiveViewTest cannot run. Read the mapping the browser would
  # execute from the element and push it, so the test exercises the payload
  # the component really sends. A string mapping (pushed by the hook with the
  # client payload) is returned for the caller to push.
  defp fire(view, selector, text \\ nil, client_event) do
    [mappings | _] =
      view
      |> element(selector, text)
      |> render()
      |> Floki.parse_fragment!()
      |> Floki.attribute("data-event-mappings")

    case mappings |> Jason.decode!() |> Map.fetch!(client_event) do
      [["push", %{"event" => event} = push]] -> render_click(view, event, push["value"] || %{})
      event when is_binary(event) -> event
    end
  end

  describe "data_table (shadcn demo)" do
    test "filters, sorts, pages, hides columns and selects rows", %{conn: conn} do
      view = example(conn, "/salad_ui_component/data_table")
      html = render(view)
      assert html =~ "ken99@example.com"
      assert html =~ "0 of 20 row(s) selected."
      assert length(row_ids(view, "payments")) == 10

      # sort by email: ascending then descending
      view |> element("th button", "Email") |> render_click()
      assert view |> element("th[aria-sort=ascending]") |> has_element?()
      assert hd(row_ids(view, "payments")) == "3u1reuv4"
      view |> element("th button", "Email") |> render_click()
      assert view |> element("th[aria-sort=descending]") |> has_element?()

      # paginate
      view |> element("button", "Next") |> render_click()
      assert length(row_ids(view, "payments")) == 10
      assert view |> element("button[disabled]", "Next") |> has_element?()

      # filtering resets to the first page
      view |> form("form", %{"email" => "MON"}) |> render_change()
      assert row_ids(view, "payments") == ["derv1ws0"]
      assert render(view) =~ "0 of 1 row(s) selected."

      # nothing matches: the empty row is the only one, and select-all is
      # disabled so a click can't leave it ticked with nothing to select
      view |> form("form", %{"email" => "zzz"}) |> render_change()
      assert row_ids(view, "payments") == []
      assert render(view) =~ "No results."
      assert view |> element("#data-table-select-all[disabled]") |> has_element?()

      view |> form("form", %{"email" => ""}) |> render_change()
      refute view |> element("#data-table-select-all[disabled]") |> has_element?()

      # select one row, then the page
      view |> element("#select-payments-m5gr84i9") |> render_click()
      assert view |> element(~s(#payments-m5gr84i9[data-state="selected"])) |> has_element?()
      assert view |> element(~s(#select-payments-m5gr84i9[checked])) |> has_element?()
      assert view |> element(~s(#data-table-select-all[data-indeterminate="true"])) |> has_element?()
      assert render(view) =~ "1 of 20 row(s) selected."

      view |> element("#data-table-select-all") |> render_click()
      assert render(view) =~ "10 of 20 row(s) selected."
      assert view |> element(~s(#data-table-select-all[data-indeterminate="false"][checked])) |> has_element?()

      view |> element("#data-table-select-all") |> render_click()
      assert render(view) =~ "0 of 20 row(s) selected."
      refute view |> element(~s(#select-payments-m5gr84i9[checked])) |> has_element?()

      # selection survives paging and filtering; select-all covers the page
      view |> element("#select-payments-m5gr84i9") |> render_click()
      view |> element("button", "Next") |> render_click()
      refute view |> element("#data-table-select-all[checked]") |> has_element?()
      assert render(view) =~ "1 of 20 row(s) selected."

      view |> form("form", %{"email" => "ken"}) |> render_change()
      assert view |> element("#data-table-select-all[checked]") |> has_element?()
      assert render(view) =~ "1 of 1 row(s) selected."
      view |> form("form", %{"email" => ""}) |> render_change()

      # hide the status column from the Columns menu, then show it again
      fire(view, ~s(#data-table-columns [data-value="status"]), "checked-change")
      refute render(view) =~ ~r/<th[^>]*>\s*Status/
      refute render(view) =~ ~s(<div class="capitalize">success</div>)

      assert view
             |> element(~s(#data-table-columns [data-value="status"][data-state="unchecked"]))
             |> has_element?()

      fire(view, ~s(#data-table-columns [data-value="status"]), "checked-change")
      assert render(view) =~ ~r/<th[^>]*>\s*Status/
      assert render(view) =~ ~s(<div class="capitalize">success</div>)
    end
  end

  describe "data_table_reusable (column header, view options, pagination)" do
    test "sorts and hides from the header menu and pages with the pagination component", %{conn: conn} do
      view = example(conn, "/salad_ui_component/data_table_reusable")
      html = render(view)
      assert html =~ "Page 1 of 3"
      assert html =~ "Toggle columns"

      # header menu: Asc / Desc, reflected in aria-sort
      fire(view, "#tasks-header-id [data-slot=dropdown-menu-item]", "Asc", "select")
      assert hd(row_ids(view, "tasks")) == "TASK-7709"
      assert view |> element("th[aria-sort=ascending] #tasks-header-id") |> has_element?()
      assert view |> element("th[aria-sort=none] #tasks-header-title") |> has_element?()

      fire(view, "#tasks-header-id [data-slot=dropdown-menu-item]", "Desc", "select")
      assert hd(row_ids(view, "tasks")) == "TASK-8782"
      assert view |> element("th[aria-sort=descending] #tasks-header-id") |> has_element?()

      # pagination buttons
      view |> element("#tasks-pagination button", "Go to last page") |> render_click()
      assert render(view) =~ "Page 3 of 3"
      assert view |> element("#tasks-pagination button[disabled]", "Go to next page") |> has_element?()

      view |> element("#tasks-pagination button", "Go to previous page") |> render_click()
      assert render(view) =~ "Page 2 of 3"

      view |> element("#tasks-pagination button", "Go to first page") |> render_click()
      assert render(view) =~ "Page 1 of 3"
      assert view |> element("#tasks-pagination button[disabled]", "Go to previous page") |> has_element?()

      view |> element("#tasks-pagination button", "Go to next page") |> render_click()
      assert render(view) =~ "Page 2 of 3"

      # rows per page: the select pushes its string event with the value
      event = fire(view, "#tasks-pagination-page-size", "value-changed")
      render_click(view, event, %{"value" => "20", "componentId" => "tasks-pagination-page-size"})
      assert render(view) =~ "Page 1 of 2"
      assert length(row_ids(view, "tasks")) == 20

      # filtering goes back to the first page
      view |> element("#tasks-pagination button", "Go to next page") |> render_click()
      view |> form("#tasks-filter", %{"title" => "neural"}) |> render_change()
      assert render(view) =~ "Page 1 of 1"
      assert length(row_ids(view, "tasks")) == 6
      view |> form("#tasks-filter", %{"title" => ""}) |> render_change()

      # hide a column from its header menu, and another from the View menu
      fire(view, "#tasks-header-priority [data-slot=dropdown-menu-item]", "Hide", "select")
      refute render(view) =~ ~s(id="tasks-header-priority")

      assert view
             |> element(~s(#tasks-view-options [data-value="priority"][data-state="unchecked"]))
             |> has_element?()

      fire(view, ~s(#tasks-view-options [data-value="status"]), "checked-change")
      refute render(view) =~ ~s(id="tasks-header-status")

      # the Task column can't be hidden: no Hide item, no View entry
      refute view |> element("#tasks-header-id [data-slot=dropdown-menu-item]", "Hide") |> has_element?()
      refute view |> element(~s(#tasks-view-options [data-value="id"])) |> has_element?()
    end
  end
end
