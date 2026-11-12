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

      # nothing matches: the empty row is the only one
      view |> form("form", %{"email" => "zzz"}) |> render_change()
      assert row_ids(view, "payments") == []
      assert render(view) =~ "No results."

      view |> form("form", %{"email" => ""}) |> render_change()

      # select one row, then the page
      view |> element("#select-payments-m5gr84i9") |> render_click()
      assert view |> element(~s(#payments-m5gr84i9[data-state="selected"])) |> has_element?()
      assert view |> element(~s(#data-table-select-all[data-indeterminate="true"])) |> has_element?()
      assert render(view) =~ "1 of 20 row(s) selected."

      view |> element("#data-table-select-all") |> render_click()
      assert render(view) =~ "10 of 20 row(s) selected."
      assert view |> element(~s(#data-table-select-all[data-indeterminate="false"][checked])) |> has_element?()

      view |> element("#data-table-select-all") |> render_click()
      assert render(view) =~ "0 of 20 row(s) selected."

      # hide the status column
      render_click(view, "toggle_column", %{"column" => "status", "visible" => false})
      refute render(view) =~ ~r/<th[^>]*>\s*Status/
      refute render(view) =~ ~s(<div class="capitalize">success</div>)
    end
  end

  describe "data_table_reusable (column header, view options, pagination)" do
    test "sorts from the header menu and pages with the pagination component", %{conn: conn} do
      view = example(conn, "/salad_ui_component/data_table_reusable")
      html = render(view)
      assert html =~ "Page 1 of 3"
      assert html =~ "Toggle columns"

      render_click(view, "sort", %{"column" => "id", "direction" => "asc"})
      assert hd(row_ids(view, "tasks")) == "TASK-7709"

      render_click(view, "page", %{"page" => 3})
      assert render(view) =~ "Page 3 of 3"

      render_click(view, "page_size", %{"value" => "20"})
      assert render(view) =~ "Page 1 of 2"
      assert length(row_ids(view, "tasks")) == 20

      render_click(view, "toggle_column", %{"column" => "priority", "visible" => false})
      refute render(view) =~ ~s(id="tasks-header-priority")
    end
  end
end
