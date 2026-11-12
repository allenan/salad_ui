defmodule SaladUI.DataTableTest do
  use ComponentCase

  import SaladUI.DataTable, only: [data_table_column_header: 1, data_table_pagination: 1, data_table_view_options: 1]

  alias SaladUI.DataTable

  doctest DataTable

  @payments [
    %{id: "m5gr84i9", amount: 316, status: "success", email: "ken99@example.com"},
    %{id: "3u1reuv4", amount: 242, status: "success", email: "Abe45@example.com"},
    %{id: "derv1ws0", amount: 837, status: "processing", email: "Monserrat44@example.com"},
    %{id: "5kma53ae", amount: 874, status: "success", email: "Silas22@example.com"},
    %{id: "bhqecj4p", amount: 721, status: "failed", email: "carmella@example.com"}
  ]

  defp table(opts \\ []) do
    DataTable.new(Keyword.merge([columns: [:status, :email, :amount]], opts))
  end

  describe "new/1" do
    test "defaults sortable, filterable and hideable to every column" do
      t = table()
      assert t.sortable == [:status, :email, :amount]
      assert t.filterable == [:status, :email, :amount]
      assert t.hideable == [:status, :email, :amount]
      assert t.page == 1
      assert t.page_size == 10
    end

    test "keeps subsets in column order and drops unknown columns" do
      t = table(sortable: [:amount, :email, :nope])
      assert t.sortable == [:email, :amount]
    end

    test "applies initial sort, filters and hidden columns" do
      t = table(sort: {:amount, :desc}, filters: %{email: "ken"}, hidden: [:status], page_size: 5)
      assert t.sort == {:amount, :desc}
      assert t.filters == %{email: "ken"}
      refute DataTable.column_visible?(t, :status)
      assert t.page_size == 5
    end

    test "raises without atom columns" do
      assert_raise ArgumentError, fn -> DataTable.new(columns: ["email"]) end
    end
  end

  describe "sorting" do
    test "toggle_sort cycles asc -> desc -> asc, as the shadcn header button does" do
      t = DataTable.toggle_sort(table(), "email")
      assert t.sort == {:email, :asc}
      t = DataTable.toggle_sort(t, :email)
      assert t.sort == {:email, :desc}
      t = DataTable.toggle_sort(t, :email)
      assert t.sort == {:email, :asc}
      assert DataTable.toggle_sort(t, :amount).sort == {:amount, :asc}
    end

    test "ignores unsortable or unknown columns and bad directions" do
      t = table(sortable: [:email])
      assert DataTable.toggle_sort(t, :status).sort == nil
      assert DataTable.toggle_sort(t, "does_not_exist").sort == nil
      assert DataTable.sort(t, :email, "sideways").sort == nil
      assert t |> DataTable.sort(:email, "desc") |> DataTable.sort(:email, nil) |> Map.get(:sort) == nil
    end

    test "aria_sort reports the direction for sortable columns only" do
      t = [sortable: [:email]] |> table() |> DataTable.sort(:email, :desc)
      assert DataTable.aria_sort(t, :email) == "descending"
      assert DataTable.aria_sort(DataTable.sort(t, :email, :asc), "email") == "ascending"
      assert DataTable.aria_sort(DataTable.clear_sort(t), :email) == "none"
      assert DataTable.aria_sort(t, :status) == nil
    end

    test "sort_rows compares strings ignoring case and is stable" do
      t = DataTable.sort(table(), :email, :asc)

      assert Enum.map(DataTable.sort_rows(@payments, t), & &1.email) == [
               "Abe45@example.com",
               "carmella@example.com",
               "ken99@example.com",
               "Monserrat44@example.com",
               "Silas22@example.com"
             ]

      t = DataTable.sort(table(), :status, :desc)
      assert Enum.map(DataTable.sort_rows(@payments, t), & &1.id) == ~w(m5gr84i9 3u1reuv4 5kma53ae derv1ws0 bhqecj4p)
    end

    test "sort_rows puts nil last in both directions and uses compare/2 for structs" do
      rows = [%{d: ~D[2024-02-01]}, %{d: nil}, %{d: ~D[2024-01-15]}, %{d: ~D[2023-12-31]}]
      t = DataTable.new(columns: [:d])

      assert Enum.map(DataTable.sort_rows(rows, DataTable.sort(t, :d, :asc)), & &1.d) ==
               [~D[2023-12-31], ~D[2024-01-15], ~D[2024-02-01], nil]

      assert Enum.map(DataTable.sort_rows(rows, DataTable.sort(t, :d, :desc)), & &1.d) ==
               [~D[2024-02-01], ~D[2024-01-15], ~D[2023-12-31], nil]
    end

    test "order_by builds an Ecto order_by keyword list" do
      assert DataTable.order_by(table()) == []
      assert DataTable.order_by(DataTable.sort(table(), :amount, :desc)) == [desc: :amount]
    end
  end

  describe "filtering" do
    test "put_filter resets the page and removes blank filters" do
      t = table() |> DataTable.set_page(3) |> DataTable.put_filter("email", "KEN")
      assert t.filters == %{email: "KEN"}
      assert t.page == 1
      assert DataTable.filter_value(t, :email) == "KEN"
      assert DataTable.put_filter(t, :email, "  ").filters == %{}
      assert DataTable.put_filter(t, :email, nil).filters == %{}
      assert DataTable.filter_value(table(), :email) == ""
    end

    test "ignores unfilterable columns" do
      t = table(filterable: [:email])
      assert DataTable.put_filter(t, :status, "x").filters == %{}
    end

    test "filter_rows matches substrings ignoring case, on any value type" do
      t = DataTable.put_filter(table(), :email, "MON")
      assert [%{id: "derv1ws0"}] = DataTable.filter_rows(@payments, t)

      t = DataTable.put_filter(table(), :amount, "87")
      assert [%{id: "5kma53ae"}] = DataTable.filter_rows(@payments, t)
    end

    test "filter_rows accepts a :get function" do
      rows = [%{"email" => "a@x.com"}, %{"email" => "b@y.com"}]
      t = DataTable.put_filter(DataTable.new(columns: [:email]), :email, "y.com")
      assert [%{"email" => "b@y.com"}] = DataTable.filter_rows(rows, t, get: &Map.get(&1, to_string(&2)))
    end
  end

  describe "pagination" do
    test "page helpers" do
      t = table(page_size: 2)
      assert DataTable.page_count(t, 5) == 3
      assert DataTable.page_count(t, 0) == 1
      refute DataTable.can_previous_page?(t)
      assert DataTable.can_next_page?(t, 5)

      t = t |> DataTable.next_page() |> DataTable.next_page()
      assert t.page == 3
      refute DataTable.can_next_page?(t, 5)
      assert DataTable.offset(t) == 4
      assert DataTable.limit(t) == 2
      assert DataTable.previous_page(DataTable.set_page(t, 1)).page == 1
      assert DataTable.clamp_page(DataTable.set_page(t, 9), 5).page == 3
    end

    test "set_page and set_page_size accept strings and ignore junk" do
      t = DataTable.set_page(table(), "4")
      assert t.page == 4
      assert DataTable.set_page(t, "abc").page == 4
      assert DataTable.set_page(t, 0).page == 4

      t = DataTable.set_page_size(t, "20")
      assert {t.page_size, t.page} == {20, 1}
      assert DataTable.set_page_size(t, "-1").page_size == 20
    end

    test "run filters, sorts and pages, returning the filtered total" do
      t = [page_size: 2] |> table() |> DataTable.sort(:amount, :desc) |> DataTable.put_filter(:status, "success")
      assert {[%{amount: 874}, %{amount: 316}], 3} = DataTable.run(@payments, t)
      assert {[%{amount: 242}], 3} = DataTable.run(@payments, DataTable.set_page(t, 2))
      # a page past the end is clamped to the last page
      assert {[%{amount: 242}], 3} = DataTable.run(@payments, DataTable.set_page(t, 7))
    end
  end

  describe "column visibility" do
    test "hides and shows hideable columns" do
      t = table(hideable: [:status, :amount])
      t = DataTable.set_column_visibility(t, "status", false)
      refute DataTable.column_visible?(t, :status)
      assert DataTable.visible_columns(t) == [:email, :amount]
      t = DataTable.set_column_visibility(t, :status, "true")
      assert DataTable.column_visible?(t, :status)
      assert t |> DataTable.toggle_column(:amount) |> DataTable.column_visible?(:amount) == false
      # email is not hideable
      assert t |> DataTable.set_column_visibility(:email, false) |> DataTable.column_visible?(:email)
      refute DataTable.column_visible?(t, :nope)
    end
  end

  describe "row selection" do
    test "toggle_row stores ids as strings and accepts either form" do
      t = DataTable.toggle_row(table(), 3)
      assert DataTable.selected?(t, "3")
      assert DataTable.selected?(t, 3)
      refute t |> DataTable.toggle_row("3") |> DataTable.selected?(3)
    end

    test "select_all_state and toggle_all over the page's ids" do
      ids = ~w(a b c)
      t = table()
      assert DataTable.select_all_state(t, ids) == false
      assert DataTable.select_all_state(t, []) == false

      t = DataTable.toggle_row(t, "b")
      assert DataTable.select_all_state(t, ids) == :indeterminate

      t = DataTable.toggle_all(t, ids)
      assert DataTable.select_all_state(t, ids) == true
      assert DataTable.selected_count(t) == 3

      # rows selected on another page are kept
      t = t |> DataTable.toggle_row("z") |> DataTable.toggle_all(ids)
      assert DataTable.select_all_state(t, ids) == false
      assert DataTable.selected_count(t) == 1
      assert DataTable.selected_count(t, ids) == 0
      assert DataTable.clear_selection(t).selected == MapSet.new()
    end
  end

  describe "params" do
    test "round-trips through to_params/from_params" do
      t =
        [page_size: 20]
        |> table()
        |> DataTable.sort(:amount, :desc)
        |> DataTable.put_filter(:email, "ken")
        |> DataTable.set_column_visibility(:status, false)
        |> DataTable.set_page(3)
        |> DataTable.set_page_size(25)
        |> DataTable.set_page(2)

      params = DataTable.to_params(t)

      assert params == %{
               "sort" => "amount",
               "dir" => "desc",
               "filter" => %{"email" => "ken"},
               "hide" => "status",
               "page" => "2",
               "per_page" => "25"
             }

      parsed = DataTable.from_params(params, columns: [:status, :email, :amount], page_size: 20)
      assert Map.delete(parsed, :selected) == Map.delete(t, :selected)
    end

    test "defaults are left out" do
      assert DataTable.to_params(table()) == %{}
    end

    test "from_params ignores unknown columns and malformed values" do
      t =
        DataTable.from_params(
          %{
            "sort" => "password",
            "filter" => %{"secret" => "x", "email" => "a"},
            "hide" => "nope,status",
            "page" => "-2",
            "per_page" => "lots"
          },
          columns: [:status, :email]
        )

      assert t.sort == nil
      assert t.filters == %{email: "a"}
      assert MapSet.to_list(t.hidden) == [:status]
      assert {t.page, t.page_size} == {1, 10}
    end
  end

  describe "data_table_column_header/1" do
    test "renders a sort menu for sortable columns" do
      assigns = %{table: DataTable.sort(table(), :email, :asc)}

      html =
        rendered_to_string(~H"""
        <.data_table_column_header
          id="email-header"
          table={@table}
          column={:email}
          title="Email"
          on-sort="sort"
          on-visibility-change="toggle_column"
        />
        """)

      assert html =~ ~s(data-slot="data-table-column-header")
      assert html =~ ~s(id="email-header")
      assert html =~ ~s(data-slot="dropdown-menu-trigger")
      assert html =~ "-ml-3 h-8 data-[state=open]:bg-accent"
      assert html =~ "Email"
      assert html =~ "Asc"
      assert html =~ "Desc"
      assert html =~ "Hide"
      assert html =~ ~s(&quot;direction&quot;:&quot;desc&quot;)
      assert html =~ ~s(&quot;visible&quot;:false)
      # ascending: the ArrowUp icon in the trigger
      assert html =~ ~s(<path d="m5 12 7-7 7 7"/>)
    end

    test "renders plain text for columns that cannot be sorted, and omits Hide without the event" do
      assigns = %{table: table(sortable: [:email], hideable: [])}

      html =
        rendered_to_string(~H"""
        <.data_table_column_header
          id="status-header"
          table={@table}
          column={:status}
          title="Status"
          on-sort="sort"
        />
        <.data_table_column_header
          id="email-header"
          table={@table}
          column={:email}
          title="Email"
          on-sort="sort"
        />
        """)

      refute html =~ "status-header"
      assert html =~ "Status"
      assert html =~ "email-header"
      refute html =~ "Hide"
    end
  end

  describe "data_table_view_options/1" do
    test "lists hideable columns as checkbox items" do
      assigns = %{table: [hideable: [:status, :amount]] |> table() |> DataTable.set_column_visibility(:amount, false)}

      html =
        rendered_to_string(~H"""
        <.data_table_view_options id="view" table={@table} on-visibility-change="toggle_column" />
        """)

      assert html =~ "Toggle columns"
      assert html =~ "View"
      assert length(Regex.scan(~r/data-slot="dropdown-menu-checkbox-item"/, html)) == 2
      assert html =~ ~r/data-value="status"[^>]*data-state="checked"/
      assert html =~ ~r/data-value="amount"[^>]*data-state="unchecked"/
      assert html =~ "ml-auto hidden h-8 lg:flex"
    end

    test "custom trigger content, no label" do
      assigns = %{table: table()}

      html =
        rendered_to_string(~H"""
        <.data_table_view_options
          id="cols"
          table={@table}
          on-visibility-change="toggle_column"
          label={nil}
          size="default"
          class="ml-auto"
        >
          Columns
        </.data_table_view_options>
        """)

      assert html =~ "Columns"
      refute html =~ "Toggle columns"
      refute html =~ ~s(data-slot="dropdown-menu-label")
    end
  end

  describe "data_table_pagination/1" do
    test "renders counts, page size select and disabled edges" do
      assigns = %{table: [page_size: 2] |> table() |> DataTable.toggle_row("a")}

      html =
        rendered_to_string(~H"""
        <.data_table_pagination
          id="pager"
          table={@table}
          total={5}
          on-page-change="page"
          on-page-size-change="page_size"
        />
        """)

      assert html =~ ~s(data-slot="data-table-pagination")
      assert html =~ "1 of 5 row(s) selected."
      assert html =~ "Rows per page"
      assert html =~ ~s(id="pager-page-size")
      assert html =~ "Page 1 of 3"
      assert html =~ "Go to first page"
      assert html =~ "Go to last page"
      assert length(Regex.scan(~r/<button[^>]*\sdisabled[\s>]/, html)) == 2
      assert html =~ ~s(&quot;page&quot;:3)
    end

    test "selected-count override and no page size select" do
      assigns = %{table: table()}

      html =
        rendered_to_string(~H"""
        <.data_table_pagination
          id="pager"
          table={@table}
          total={0}
          selected-count={4}
          on-page-change="page"
        />
        """)

      assert html =~ "4 of 0 row(s) selected."
      assert html =~ "Page 1 of 1"
      refute html =~ "Rows per page"
    end
  end
end
