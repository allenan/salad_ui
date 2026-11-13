defmodule SaladUI.DataTable do
  @moduledoc """
  Helpers for building data tables, following https://ui.shadcn.com/docs/components/data-table

  Like shadcn, SaladUI has no monolithic data-table component: every data
  table sorts, filters and loads its rows differently. You compose one from
  `SaladUI.Table`, `SaladUI.DropdownMenu`, `SaladUI.Checkbox`, `SaladUI.Input`
  and `SaladUI.Button`, and this module supplies the parts that would
  otherwise be rewritten for every table:

  * a `%SaladUI.DataTable{}` struct holding the table state (sorting,
    filters, pagination, column visibility and row selection) with pure
    functions to update it from LiveView events, the role TanStack Table plays
    in the shadcn guide;
  * `from_params/2` and `to_params/1`, to keep that state in the URL;
  * `run/3` (and `filter_rows/3`, `sort_rows/3`, `paginate_rows/2`) for rows
    already in memory, and `limit/1`, `offset/1`, `order_by/1` for queries;
  * the three reusable components from the guide:
    `data_table_column_header/1`, `data_table_view_options/1` and
    `data_table_pagination/1`.

  Column ids are atoms. Every function that takes a column also accepts its
  name as a string (as it arrives in event params) and ignores columns that
  were not declared in `new/1`, so params never create atoms.

  ## Recipe

  The state lives in an assign; the rows live in a stream. Any change that
  affects every row (sorting, filtering, paging, hiding a column) resets the
  stream; toggling one row re-inserts just that row.

      defmodule MyAppWeb.PaymentsLive do
        use MyAppWeb, :live_view

        alias SaladUI.DataTable

        def mount(_params, _session, socket) do
          table =
            DataTable.new(
              columns: [:status, :email, :amount],
              sortable: [:email],
              filterable: [:email]
            )

          {:ok, socket |> assign(:table, table) |> load_rows()}
        end

        def handle_event("sort", %{"column" => column}, socket) do
          update_table(socket, &DataTable.toggle_sort(&1, column))
        end

        def handle_event("filter", %{"email" => value}, socket) do
          update_table(socket, &DataTable.put_filter(&1, :email, value))
        end

        def handle_event("page", %{"page" => page}, socket) do
          update_table(socket, &DataTable.set_page(&1, page))
        end

        def handle_event("toggle_column", %{"column" => column, "visible" => visible}, socket) do
          update_table(socket, &DataTable.set_column_visibility(&1, column, visible))
        end

        def handle_event("toggle_all", _params, socket) do
          ids = Enum.map(socket.assigns.page_rows, & &1.id)
          update_table(socket, &DataTable.toggle_all(&1, ids))
        end

        def handle_event("toggle_row", %{"id" => id}, socket) do
          socket = assign(socket, :table, DataTable.toggle_row(socket.assigns.table, id))

          case Enum.find(socket.assigns.page_rows, &(to_string(&1.id) == id)) do
            nil -> {:noreply, socket}
            row -> {:noreply, stream_insert(socket, :payments, row)}
          end
        end

        defp update_table(socket, fun) do
          {:noreply, socket |> assign(:table, fun.(socket.assigns.table)) |> load_rows()}
        end

        defp load_rows(socket) do
          {rows, total} = DataTable.run(Payments.list(), socket.assigns.table)

          socket
          # run/3 returns the last page when the page is past the end (after a
          # filter or a stale URL); clamp the state so the pager agrees.
          |> assign(table: DataTable.clamp_page(socket.assigns.table, total))
          |> assign(page_rows: rows, total: total)
          |> stream(:payments, rows, reset: true)
        end
      end

  And in the template:

      <.table_head aria-sort={DataTable.aria_sort(@table, :email)}>
        <.button variant="ghost" phx-click={JS.push("sort", value: %{column: "email"})}>
          Email <.icon name="hero-arrows-up-down" />
        </.button>
      </.table_head>

      <.table_body id="payments" phx-update="stream">
        <.table_row id="payments-empty" class="hidden only:table-row">
          <.table_cell colspan="5" class="h-24 text-center">No results.</.table_cell>
        </.table_row>
        <.table_row
          :for={{dom_id, payment} <- @streams.payments}
          id={dom_id}
          data-state={DataTable.selected?(@table, payment.id) && "selected"}
        >
          <.table_cell>
            <.checkbox
              id={"select-" <> dom_id}
              value={DataTable.selected?(@table, payment.id)}
              phx-click="toggle_row"
              phx-value-id={payment.id}
              aria-label="Select row"
            />
          </.table_cell>
          <.table_cell :if={DataTable.column_visible?(@table, :email)}>{payment.email}</.table_cell>
        </.table_row>
      </.table_body>

  The select-all checkbox uses `select_all_state/2` with the checkbox's
  `indeterminate` attribute. Disable it when the page is empty: clicking it
  then changes nothing on the server, so no patch would undo the browser's
  own toggle.

      <% state = DataTable.select_all_state(@table, Enum.map(@page_rows, & &1.id)) %>
      <.checkbox
        id="select-all"
        value={state == true}
        indeterminate={state == :indeterminate}
        disabled={@page_rows == []}
        phx-click="toggle_all"
        aria-label="Select all"
      />

  ## Keeping state in the URL

  Use `to_params/1` with `push_patch/2` and `from_params/2` in
  `handle_params/3`, so sorting, filters and the page survive a reload:

      def handle_params(params, _uri, socket) do
        table = DataTable.from_params(params, columns: [:status, :email, :amount])
        {:noreply, socket |> assign(:table, table) |> load_rows()}
      end

      def handle_event("sort", %{"column" => column}, socket) do
        table = DataTable.toggle_sort(socket.assigns.table, column)
        {:noreply, push_patch(socket, to: ~p"/payments?\#{DataTable.to_params(table)}")}
      end

  Row selection is not part of the params.

  ## Database queries

  For large tables, query the page instead of calling `run/3`:

      from(p in Payment,
        order_by: ^DataTable.order_by(table),
        limit: ^DataTable.limit(table),
        offset: ^DataTable.offset(table)
      )

  `table.filters` is a map of column to search string.

  ## Differences from shadcn

  * State is held on the server in a struct rather than in TanStack Table on
    the client, so every interaction is a LiveView event.
  * Selected row ids are stored as strings (`to_string/1` of the id), because
    that is how they arrive from `phx-value-*` params. `selected?/2` and the
    other selection functions accept either form.
  * Sorting is by one column at a time.
  """
  use SaladUI, :component

  import SaladUI.Button
  import SaladUI.DropdownMenu
  import SaladUI.Select

  @default_page_size 10

  @type column :: atom()
  @type direction :: :asc | :desc
  @type t :: %__MODULE__{
          columns: [column()],
          sortable: [column()],
          filterable: [column()],
          hideable: [column()],
          sort: {column(), direction()} | nil,
          filters: %{optional(column()) => String.t()},
          page: pos_integer(),
          page_size: pos_integer(),
          default_page_size: pos_integer(),
          hidden: MapSet.t(column()),
          selected: MapSet.t(String.t())
        }

  defstruct columns: [],
            sortable: [],
            filterable: [],
            hideable: [],
            sort: nil,
            filters: %{},
            page: 1,
            page_size: @default_page_size,
            default_page_size: @default_page_size,
            hidden: MapSet.new(),
            selected: MapSet.new()

  ## Building

  @doc """
  Builds a table state.

  ## Options

  * `:columns` - (required) the column ids, as atoms, in display order.
  * `:sortable` - columns that can be sorted. Defaults to all `:columns`.
  * `:filterable` - columns that can be filtered. Defaults to all `:columns`.
  * `:hideable` - columns that can be hidden. Defaults to all `:columns`.
  * `:sort` - initial sorting, as `{column, :asc | :desc}`. Defaults to `nil`.
  * `:filters` - initial filters, as `%{column => string}`.
  * `:hidden` - initially hidden columns.
  * `:page_size` - rows per page. Defaults to `#{@default_page_size}`.

  ## Examples

      iex> table = SaladUI.DataTable.new(columns: [:status, :email], sortable: [:email])
      iex> {table.sortable, table.page, table.page_size}
      {[:email], 1, 10}
  """
  @spec new(keyword()) :: t()
  def new(opts) do
    columns = Keyword.fetch!(opts, :columns)

    if !(is_list(columns) and Enum.all?(columns, &is_atom/1)) do
      raise ArgumentError, ":columns must be a list of atoms, got: #{inspect(columns)}"
    end

    page_size = positive_integer(Keyword.get(opts, :page_size)) || @default_page_size

    table = %__MODULE__{
      columns: columns,
      sortable: subset(columns, Keyword.get(opts, :sortable, columns)),
      filterable: subset(columns, Keyword.get(opts, :filterable, columns)),
      hideable: subset(columns, Keyword.get(opts, :hideable, columns)),
      page_size: page_size,
      default_page_size: page_size
    }

    table =
      case Keyword.get(opts, :sort) do
        {column, direction} -> sort(table, column, direction)
        nil -> table
      end

    table =
      opts
      |> Keyword.get(:filters, %{})
      |> Enum.reduce(table, fn {column, value}, acc -> put_filter(acc, column, value) end)

    opts
    |> Keyword.get(:hidden, [])
    |> Enum.reduce(table, fn column, acc -> set_column_visibility(acc, column, false) end)
  end

  @doc """
  Builds a table state from URL params, as written by `to_params/1`.

  `opts` are the options of `new/1`. Unknown columns and malformed values
  are ignored.

  ## Examples

      iex> table =
      ...>   SaladUI.DataTable.from_params(
      ...>     %{"sort" => "email", "dir" => "desc", "page" => "2", "filter" => %{"email" => "ken"}},
      ...>     columns: [:status, :email]
      ...>   )
      iex> {table.sort, table.page, table.filters}
      {{:email, :desc}, 2, %{email: "ken"}}
  """
  @spec from_params(map(), keyword()) :: t()
  def from_params(params, opts) when is_map(params) do
    opts |> new() |> merge_params(params)
  end

  @doc """
  Applies URL params (see `to_params/1`) on top of an existing table state.
  """
  @spec merge_params(t(), map()) :: t()
  def merge_params(%__MODULE__{} = table, params) when is_map(params) do
    table
    |> merge_sort_param(params["sort"], params["dir"])
    |> merge_filter_param(params["filter"])
    |> merge_hide_param(params["hide"])
    |> merge_page_param(:page_size, positive_integer(params["per_page"]))
    |> merge_page_param(:page, positive_integer(params["page"]))
  end

  defp merge_sort_param(table, nil, _dir), do: table
  defp merge_sort_param(table, column, dir), do: sort(table, column, dir || "asc")

  defp merge_filter_param(table, filters) when is_map(filters) do
    Enum.reduce(filters, table, fn
      {column, value}, acc when is_binary(value) -> put_filter(acc, column, value)
      _malformed, acc -> acc
    end)
  end

  defp merge_filter_param(table, _filters), do: table

  defp merge_hide_param(table, hide) when is_binary(hide) do
    hide
    |> String.split(",", trim: true)
    |> Enum.reduce(table, &set_column_visibility(&2, &1, false))
  end

  defp merge_hide_param(table, _hide), do: table

  defp merge_page_param(table, _key, nil), do: table
  defp merge_page_param(table, key, value), do: Map.put(table, key, value)

  @doc """
  Encodes the sorting, filters, page, page size and hidden columns as URL
  params, leaving out defaults. Pass the result to `~p"/path?\#{params}"`.

  ## Examples

      iex> SaladUI.DataTable.new(columns: [:email, :amount])
      ...> |> SaladUI.DataTable.sort(:amount, :desc)
      ...> |> SaladUI.DataTable.put_filter(:email, "ken")
      ...> |> SaladUI.DataTable.to_params()
      %{"dir" => "desc", "filter" => %{"email" => "ken"}, "sort" => "amount"}
  """
  @spec to_params(t()) :: map()
  def to_params(%__MODULE__{} = table) do
    params =
      case table.sort do
        {column, direction} -> %{"sort" => to_string(column), "dir" => to_string(direction)}
        nil -> %{}
      end

    params =
      if map_size(table.filters) > 0,
        do: Map.put(params, "filter", Map.new(table.filters, fn {k, v} -> {to_string(k), v} end)),
        else: params

    params =
      case Enum.filter(table.columns, &MapSet.member?(table.hidden, &1)) do
        [] -> params
        hidden -> Map.put(params, "hide", Enum.join(hidden, ","))
      end

    params = if table.page > 1, do: Map.put(params, "page", to_string(table.page)), else: params

    if table.page_size == table.default_page_size,
      do: params,
      else: Map.put(params, "per_page", to_string(table.page_size))
  end

  ## Sorting

  @doc """
  Toggles sorting on `column`, as clicking a sortable header does: an
  unsorted or descending column becomes ascending, an ascending one becomes
  descending. Columns that are not sortable are ignored.
  """
  @spec toggle_sort(t(), column() | String.t()) :: t()
  def toggle_sort(%__MODULE__{} = table, column) do
    case resolve(table.sortable, column) do
      nil -> table
      col -> %{table | sort: {col, if(table.sort == {col, :asc}, do: :desc, else: :asc)}}
    end
  end

  @doc """
  Sorts by `column` in `direction` (`:asc`, `:desc`, `"asc"` or `"desc"`).
  A `nil` direction clears the sorting. Columns that are not sortable and
  unknown directions are ignored.
  """
  @spec sort(t(), column() | String.t(), direction() | String.t() | nil) :: t()
  def sort(%__MODULE__{} = table, _column, nil), do: clear_sort(table)

  def sort(%__MODULE__{} = table, column, direction) do
    with col when not is_nil(col) <- resolve(table.sortable, column),
         dir when not is_nil(dir) <- direction(direction) do
      %{table | sort: {col, dir}}
    else
      _ -> table
    end
  end

  @doc "Removes the sorting."
  @spec clear_sort(t()) :: t()
  def clear_sort(%__MODULE__{} = table), do: %{table | sort: nil}

  @doc "Returns `:asc` or `:desc` when the table is sorted by `column`, `nil` otherwise."
  @spec sort_direction(t(), column() | String.t()) :: direction() | nil
  def sort_direction(%__MODULE__{sort: {col, dir}} = table, column) do
    if resolve(table.columns, column) == col, do: dir
  end

  def sort_direction(%__MODULE__{}, _column), do: nil

  @doc """
  Returns the `aria-sort` value for a sortable column header: `"ascending"`,
  `"descending"` or `"none"`. Returns `nil` for columns that cannot be sorted,
  so the attribute is left out.
  """
  @spec aria_sort(t(), column() | String.t()) :: String.t() | nil
  def aria_sort(%__MODULE__{} = table, column) do
    cond do
      !sortable?(table, column) -> nil
      sort_direction(table, column) == :asc -> "ascending"
      sort_direction(table, column) == :desc -> "descending"
      true -> "none"
    end
  end

  @doc "Whether `column` can be sorted."
  @spec sortable?(t(), column() | String.t()) :: boolean()
  def sortable?(%__MODULE__{} = table, column), do: resolve(table.sortable, column) != nil

  ## Filtering

  @doc """
  Sets the filter for `column` and goes back to the first page. A blank
  value removes the filter. Columns that are not filterable are ignored.
  """
  @spec put_filter(t(), column() | String.t(), String.t() | nil) :: t()
  def put_filter(%__MODULE__{} = table, column, value) do
    case resolve(table.filterable, column) do
      nil ->
        table

      col ->
        value = if is_nil(value), do: "", else: to_string(value)

        filters =
          if String.trim(value) == "",
            do: Map.delete(table.filters, col),
            else: Map.put(table.filters, col, value)

        %{table | filters: filters, page: 1}
    end
  end

  @doc "Returns the filter value for `column`, or `\"\"`."
  @spec filter_value(t(), column() | String.t()) :: String.t()
  def filter_value(%__MODULE__{} = table, column) do
    Map.get(table.filters, resolve(table.columns, column), "")
  end

  ## Pagination

  @doc "Goes to `page` (1-based; an integer or a numeric string)."
  @spec set_page(t(), pos_integer() | String.t()) :: t()
  def set_page(%__MODULE__{} = table, page) do
    case positive_integer(page) do
      nil -> table
      page -> %{table | page: page}
    end
  end

  @doc "Goes to the next page."
  @spec next_page(t()) :: t()
  def next_page(%__MODULE__{} = table), do: %{table | page: table.page + 1}

  @doc "Goes to the previous page, stopping at the first."
  @spec previous_page(t()) :: t()
  def previous_page(%__MODULE__{} = table), do: %{table | page: max(table.page - 1, 1)}

  @doc "Sets the number of rows per page and goes back to the first page."
  @spec set_page_size(t(), pos_integer() | String.t()) :: t()
  def set_page_size(%__MODULE__{} = table, size) do
    case positive_integer(size) do
      nil -> table
      size -> %{table | page_size: size, page: 1}
    end
  end

  @doc "The number of pages for `total` rows (at least 1)."
  @spec page_count(t(), non_neg_integer()) :: pos_integer()
  def page_count(%__MODULE__{page_size: size}, total), do: max(div(total + size - 1, size), 1)

  @doc "Moves the page back inside `1..page_count(table, total)`."
  @spec clamp_page(t(), non_neg_integer()) :: t()
  def clamp_page(%__MODULE__{} = table, total) do
    %{table | page: table.page |> min(page_count(table, total)) |> max(1)}
  end

  @doc "Whether there is a page before the current one."
  @spec can_previous_page?(t()) :: boolean()
  def can_previous_page?(%__MODULE__{page: page}), do: page > 1

  @doc "Whether there is a page after the current one, given `total` rows."
  @spec can_next_page?(t(), non_neg_integer()) :: boolean()
  def can_next_page?(%__MODULE__{} = table, total), do: table.page < page_count(table, total)

  @doc "The page size, for a query's `limit`."
  @spec limit(t()) :: pos_integer()
  def limit(%__MODULE__{page_size: size}), do: size

  @doc "The number of rows before the current page, for a query's `offset`."
  @spec offset(t()) :: non_neg_integer()
  def offset(%__MODULE__{page: page, page_size: size}), do: (page - 1) * size

  @doc """
  The sorting as an `Ecto.Query` `order_by` keyword list: `[desc: :amount]`,
  or `[]` when unsorted.
  """
  @spec order_by(t()) :: keyword()
  def order_by(%__MODULE__{sort: {column, direction}}), do: [{direction, column}]
  def order_by(%__MODULE__{sort: nil}), do: []

  ## Column visibility

  @doc """
  Shows (`visible` true) or hides (`visible` false) `column`. `visible` may
  also be `"true"` or `"false"`. Columns that are not hideable are ignored.
  """
  @spec set_column_visibility(t(), column() | String.t(), boolean() | String.t()) :: t()
  def set_column_visibility(%__MODULE__{} = table, column, visible) do
    case resolve(table.hideable, column) do
      nil ->
        table

      col ->
        if visible in [true, "true"],
          do: %{table | hidden: MapSet.delete(table.hidden, col)},
          else: %{table | hidden: MapSet.put(table.hidden, col)}
    end
  end

  @doc "Shows `column` if it is hidden and hides it if it is visible."
  @spec toggle_column(t(), column() | String.t()) :: t()
  def toggle_column(%__MODULE__{} = table, column) do
    set_column_visibility(table, column, !column_visible?(table, column))
  end

  @doc "Whether `column` is visible."
  @spec column_visible?(t(), column() | String.t()) :: boolean()
  def column_visible?(%__MODULE__{} = table, column) do
    case resolve(table.columns, column) do
      nil -> false
      col -> !MapSet.member?(table.hidden, col)
    end
  end

  @doc "Whether `column` can be hidden."
  @spec hideable?(t(), column() | String.t()) :: boolean()
  def hideable?(%__MODULE__{} = table, column), do: resolve(table.hideable, column) != nil

  @doc "The visible columns, in display order."
  @spec visible_columns(t()) :: [column()]
  def visible_columns(%__MODULE__{} = table) do
    Enum.reject(table.columns, &MapSet.member?(table.hidden, &1))
  end

  ## Row selection

  @doc "Selects `id` if it is not selected and deselects it if it is."
  @spec toggle_row(t(), term()) :: t()
  def toggle_row(%__MODULE__{} = table, id) do
    key = to_string(id)

    if MapSet.member?(table.selected, key),
      do: %{table | selected: MapSet.delete(table.selected, key)},
      else: %{table | selected: MapSet.put(table.selected, key)}
  end

  @doc """
  Toggles every id in `ids` (usually the rows on the current page), as the
  select-all checkbox does: deselects them all when they are all selected,
  selects them all otherwise.
  """
  @spec toggle_all(t(), [term()]) :: t()
  def toggle_all(%__MODULE__{} = table, ids) do
    keys = MapSet.new(ids, &to_string/1)

    if select_all_state(table, ids) == true,
      do: %{table | selected: MapSet.difference(table.selected, keys)},
      else: %{table | selected: MapSet.union(table.selected, keys)}
  end

  @doc "Deselects every row."
  @spec clear_selection(t()) :: t()
  def clear_selection(%__MODULE__{} = table), do: %{table | selected: MapSet.new()}

  @doc "Whether the row with `id` is selected."
  @spec selected?(t(), term()) :: boolean()
  def selected?(%__MODULE__{} = table, id), do: MapSet.member?(table.selected, to_string(id))

  @doc """
  The state for a select-all checkbox over `ids`: `true` when all are
  selected, `:indeterminate` when some are, `false` when none are (or `ids`
  is empty).
  """
  @spec select_all_state(t(), [term()]) :: boolean() | :indeterminate
  def select_all_state(%__MODULE__{} = table, ids) do
    case {selected_count(table, ids), length(ids)} do
      {0, _} -> false
      {n, n} -> true
      _ -> :indeterminate
    end
  end

  @doc """
  The number of selected rows. With `ids`, counts only the selected rows
  among them, such as the rows that pass the current filters.
  """
  @spec selected_count(t(), [term()] | nil) :: non_neg_integer()
  def selected_count(table, ids \\ nil)
  def selected_count(%__MODULE__{} = table, nil), do: MapSet.size(table.selected)
  def selected_count(%__MODULE__{} = table, ids), do: Enum.count(ids, &selected?(table, &1))

  ## In-memory rows

  @doc """
  Filters, sorts and paginates `rows` in memory. Returns `{page_rows, total}`
  where `total` is the number of rows that pass the filters.

  When the table's page is past the last page (a filter shrank the rows, or a
  URL named a page that no longer exists) the last page is returned; call
  `clamp_page(table, total)` to bring the state in line.

  ## Options

  * `:get` - `fn row, column -> value end` reading a column's value from a
    row. Defaults to `Map.get(row, column)`.
  """
  @spec run(Enumerable.t(), t(), keyword()) :: {list(), non_neg_integer()}
  def run(rows, %__MODULE__{} = table, opts \\ []) do
    filtered = filter_rows(rows, table, opts)
    total = length(filtered)
    page_rows = filtered |> sort_rows(table, opts) |> paginate_rows(clamp_page(table, total))
    {page_rows, total}
  end

  @doc """
  Keeps the rows whose value contains each filter's text, ignoring case.
  Takes the same options as `run/3`.
  """
  @spec filter_rows(Enumerable.t(), t(), keyword()) :: list()
  def filter_rows(rows, %__MODULE__{filters: filters}, opts \\ []) do
    get = Keyword.get(opts, :get, &Map.get/2)
    terms = Enum.map(filters, fn {column, value} -> {column, String.downcase(value)} end)

    Enum.filter(rows, fn row ->
      Enum.all?(terms, fn {column, term} ->
        row |> get.(column) |> text() |> String.downcase() |> String.contains?(term)
      end)
    end)
  end

  @doc """
  Sorts the rows by the table's sort column. Strings compare ignoring case,
  structs with a `compare/2` function (`Date`, `DateTime`, `Decimal`, ...) use
  it, and `nil` values always come last. The sort is stable. Takes the same
  options as `run/3`.
  """
  @spec sort_rows(Enumerable.t(), t(), keyword()) :: list()
  def sort_rows(rows, table, opts \\ [])
  def sort_rows(rows, %__MODULE__{sort: nil}, _opts), do: Enum.to_list(rows)

  def sort_rows(rows, %__MODULE__{sort: {column, direction}}, opts) do
    get = Keyword.get(opts, :get, &Map.get/2)
    {blank, present} = rows |> Enum.map(&{get.(&1, column), &1}) |> Enum.split_with(&is_nil(elem(&1, 0)))

    sorted =
      case direction do
        :asc -> Enum.sort(present, fn {a, _}, {b, _} -> compare(a, b) != :gt end)
        :desc -> Enum.sort(present, fn {a, _}, {b, _} -> compare(a, b) != :lt end)
      end

    Enum.map(sorted ++ blank, &elem(&1, 1))
  end

  @doc "Returns the rows on the table's current page."
  @spec paginate_rows(Enumerable.t(), t()) :: list()
  def paginate_rows(rows, %__MODULE__{} = table) do
    Enum.slice(rows, offset(table), limit(table))
  end

  @doc """
  A readable label for a column id: `:created_at` becomes `"created at"`.
  Use the `capitalize` class to capitalise it, as shadcn does.
  """
  @spec column_label(column() | String.t()) :: String.t()
  def column_label(column), do: column |> to_string() |> String.replace("_", " ")

  ## Components

  @doc """
  A sortable column header: a ghost button that opens a menu with "Asc",
  "Desc" and, when the column can be hidden, "Hide". Columns that cannot be
  sorted render as plain text.

  Put it inside a `table_head/1`, with `aria-sort={DataTable.aria_sort(@table, column)}`
  on the head.

  ## Events

  * `:on-sort` - pushed with `%{"column" => column, "direction" => "asc" | "desc"}`.
    Pass it to `sort/3`.
  * `:on-visibility-change` - pushed with `%{"column" => column, "visible" => false}`
    when "Hide" is picked. Pass it to `set_column_visibility/3`. Leave it
    unset to omit the "Hide" item.

  ## Examples

      <.table_head aria-sort={DataTable.aria_sort(@table, :title)}>
        <.data_table_column_header
          id="title-header"
          table={@table}
          column={:title}
          title="Title"
          on-sort="sort"
          on-visibility-change="toggle_column"
        />
      </.table_head>
  """
  attr :id, :string, required: true, doc: "id of the dropdown menu"
  attr :table, __MODULE__, required: true
  attr :column, :any, required: true, doc: "the column id"
  attr :title, :string, required: true
  attr :"on-sort", :string, default: nil, doc: "event pushed when a sort direction is picked"
  attr :"on-visibility-change", :string, default: nil, doc: "event pushed when \"Hide\" is picked"
  attr :target, :any, default: nil, doc: "`phx-target` for the events, such as `@myself`"
  attr :class, :any, default: nil
  attr :rest, :global

  def data_table_column_header(assigns) do
    assigns =
      assign(assigns,
        sortable: assigns[:"on-sort"] != nil && sortable?(assigns.table, assigns.column),
        hideable: assigns[:"on-visibility-change"] != nil && hideable?(assigns.table, assigns.column),
        direction: sort_direction(assigns.table, assigns.column),
        column_name: to_string(assigns.column),
        sort_event: assigns[:"on-sort"],
        visibility_event: assigns[:"on-visibility-change"]
      )

    ~H"""
    <div :if={!@sortable} data-slot="data-table-column-header" class={classes([@class])} {@rest}>
      {@title}
    </div>
    <div
      :if={@sortable}
      data-slot="data-table-column-header"
      class={classes(["flex items-center gap-2", @class])}
      {@rest}
    >
      <.dropdown_menu id={@id}>
        <.dropdown_menu_trigger
          as={&button/1}
          class="-ms-3 h-8 data-[state=open]:bg-accent"
          {%{variant: "ghost", size: "sm"}}
        >
          <span>{@title}</span>
          <.lucide :if={@direction == :desc} name="arrow-down" />
          <.lucide :if={@direction == :asc} name="arrow-up" />
          <.lucide :if={is_nil(@direction)} name="chevrons-up-down" />
        </.dropdown_menu_trigger>
        <.dropdown_menu_content align="start">
          <.dropdown_menu_item on-select={
            push(@sort_event, %{column: @column_name, direction: "asc"}, @target)
          }>
            <.lucide name="arrow-up" /> Asc
          </.dropdown_menu_item>
          <.dropdown_menu_item on-select={
            push(@sort_event, %{column: @column_name, direction: "desc"}, @target)
          }>
            <.lucide name="arrow-down" /> Desc
          </.dropdown_menu_item>
          <.dropdown_menu_separator :if={@hideable} />
          <.dropdown_menu_item
            :if={@hideable}
            on-select={push(@visibility_event, %{column: @column_name, visible: false}, @target)}
          >
            <.lucide name="eye-off" /> Hide
          </.dropdown_menu_item>
        </.dropdown_menu_content>
      </.dropdown_menu>
    </div>
    """
  end

  @doc """
  A "View" menu with a checkbox item per hideable column, to show and hide
  columns.

  ## Events

  * `:on-visibility-change` - pushed with `%{"column" => column, "visible" => boolean}`.
    Pass it to `set_column_visibility/3`.

  ## Examples

      <.data_table_view_options id="view-options" table={@table} on-visibility-change="toggle_column" />

  shadcn's data-table demo uses a "Columns" button with no label instead:

      <.data_table_view_options
        id="columns-menu"
        table={@table}
        on-visibility-change="toggle_column"
        label={nil}
        size="default"
        class="ms-auto"
      >
        Columns <.icon name="hero-chevron-down" />
      </.data_table_view_options>
  """
  attr :id, :string, required: true, doc: "id of the dropdown menu"
  attr :table, __MODULE__, required: true

  attr :columns, :list,
    default: nil,
    doc: "the columns to list. Defaults to the table's hideable columns."

  attr :label, :any, default: "Toggle columns", doc: "menu label; `nil` omits it"
  attr :"on-visibility-change", :string, required: true, doc: "event pushed when an item is toggled"
  attr :target, :any, default: nil, doc: "`phx-target` for the event, such as `@myself`"
  attr :variant, :string, default: "outline", doc: "trigger button variant"
  attr :size, :string, default: "sm", doc: "trigger button size"
  attr :class, :any, default: "ms-auto hidden h-8 lg:flex", doc: "trigger button classes"
  attr :rest, :global
  slot :inner_block, doc: "trigger content. Defaults to a settings icon and \"View\"."

  def data_table_view_options(assigns) do
    assigns =
      assign(assigns,
        items: Enum.filter(assigns.columns || assigns.table.hideable, &hideable?(assigns.table, &1)),
        visibility_event: assigns[:"on-visibility-change"]
      )

    ~H"""
    <.dropdown_menu id={@id} {@rest}>
      <.dropdown_menu_trigger as={&button/1} class={@class} variant={@variant} size={@size}>
        <%= if @inner_block == [] do %>
          <.lucide name="settings-2" /> View
        <% else %>
          {render_slot(@inner_block)}
        <% end %>
      </.dropdown_menu_trigger>
      <.dropdown_menu_content align="end" class={@label && "w-[150px]"}>
        <.dropdown_menu_label :if={@label}>{@label}</.dropdown_menu_label>
        <.dropdown_menu_separator :if={@label} />
        <.dropdown_menu_checkbox_item
          :for={column <- @items}
          class="capitalize"
          value={to_string(column)}
          checked={column_visible?(@table, column)}
          on-checked-change={
            push(
              @visibility_event,
              %{column: to_string(column), visible: !column_visible?(@table, column)},
              @target
            )
          }
        >
          {column_label(column)}
        </.dropdown_menu_checkbox_item>
      </.dropdown_menu_content>
    </.dropdown_menu>
    """
  end

  @doc """
  Pagination controls for a data table: the selected row count, a rows per
  page select, "Page N of M", and first / previous / next / last buttons.

  ## Events

  * `:on-page-change` - pushed with `%{"page" => page}`. Pass it to `set_page/2`.
  * `:on-page-size-change` - pushed with `%{"value" => size}` (a string). Pass
    it to `set_page_size/2`. Leave it unset to omit the rows per page select.

  ## Examples

      <.data_table_pagination
        id="tasks-pagination"
        table={@table}
        total={@total}
        on-page-change="page"
        on-page-size-change="page_size"
      />
  """
  attr :id, :string, required: true
  attr :table, __MODULE__, required: true
  attr :total, :integer, required: true, doc: "the number of rows that pass the filters"

  attr :"selected-count", :any,
    default: nil,
    doc: "selected rows among those `total`. Defaults to `selected_count(table)`; `false` hides the count."

  attr :"page-size-options", :list, default: [10, 20, 25, 30, 40, 50]
  attr :"on-page-change", :string, required: true, doc: "event pushed with the new page"
  attr :"on-page-size-change", :string, default: nil, doc: "event pushed with the new page size"
  attr :target, :any, default: nil, doc: "`phx-target` for the events, such as `@myself`"
  attr :class, :any, default: nil
  attr :rest, :global

  def data_table_pagination(assigns) do
    %{table: table, total: total} = assigns
    page_count = page_count(table, total)

    assigns =
      assign(assigns,
        page_count: page_count,
        selected: if(is_nil(assigns[:"selected-count"]), do: selected_count(table), else: assigns[:"selected-count"]),
        can_previous: can_previous_page?(table),
        can_next: can_next_page?(table, total),
        page_event: assigns[:"on-page-change"],
        page_size_event: assigns[:"on-page-size-change"],
        page_size_options: assigns[:"page-size-options"]
      )

    ~H"""
    <div
      id={@id}
      data-slot="data-table-pagination"
      class={classes(["flex items-center justify-between px-2", @class])}
      {@rest}
    >
      <div class="flex-1 text-sm text-muted-foreground">
        <%= if @selected != false do %>
          {@selected} of {@total} row(s) selected.
        <% end %>
      </div>
      <div class="flex items-center space-x-6 lg:space-x-8">
        <div :if={@page_size_event} class="flex items-center space-x-2">
          <p class="text-sm font-medium">Rows per page</p>
          <.select
            id={@id <> "-page-size"}
            value={to_string(@table.page_size)}
            on-value-changed={@page_size_event}
          >
            <.select_trigger class="h-8 w-[70px]" aria-label="Rows per page">
              <.select_value placeholder={to_string(@table.page_size)} />
            </.select_trigger>
            <.select_content side="top">
              <.select_item :for={size <- @page_size_options} value={to_string(size)}>
                {size}
              </.select_item>
            </.select_content>
          </.select>
        </div>
        <div class="flex w-[100px] items-center justify-center text-sm font-medium">
          Page {@table.page} of {@page_count}
        </div>
        <div class="flex items-center space-x-2">
          <.button
            variant="outline"
            size="icon"
            class="hidden size-8 lg:flex"
            disabled={!@can_previous}
            phx-click={push(@page_event, %{page: 1}, @target)}
          >
            <span class="sr-only">Go to first page</span>
            <.lucide name="chevrons-left" />
          </.button>
          <.button
            variant="outline"
            size="icon"
            class="size-8"
            disabled={!@can_previous}
            phx-click={push(@page_event, %{page: max(@table.page - 1, 1)}, @target)}
          >
            <span class="sr-only">Go to previous page</span>
            <.lucide name="chevron-left" />
          </.button>
          <.button
            variant="outline"
            size="icon"
            class="size-8"
            disabled={!@can_next}
            phx-click={push(@page_event, %{page: min(@table.page + 1, @page_count)}, @target)}
          >
            <span class="sr-only">Go to next page</span>
            <.lucide name="chevron-right" />
          </.button>
          <.button
            variant="outline"
            size="icon"
            class="hidden size-8 lg:flex"
            disabled={!@can_next}
            phx-click={push(@page_event, %{page: @page_count}, @target)}
          >
            <span class="sr-only">Go to last page</span>
            <.lucide name="chevrons-right" />
          </.button>
        </div>
      </div>
    </div>
    """
  end

  ## Private

  @lucide %{
    "arrow-up" => ~s(<path d="m5 12 7-7 7 7"/><path d="M12 19V5"/>),
    "arrow-down" => ~s(<path d="M12 5v14"/><path d="m19 12-7 7-7-7"/>),
    "chevrons-up-down" => ~s(<path d="m7 15 5 5 5-5"/><path d="m7 9 5-5 5 5"/>),
    "eye-off" =>
      ~s(<path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49"/><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242"/><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143"/><path d="m2 2 20 20"/>),
    "settings-2" =>
      ~s(<path d="M14 17H5"/><path d="M19 7h-9"/><circle cx="17" cy="17" r="3"/><circle cx="7" cy="7" r="3"/>),
    "chevron-left" => ~s(<path d="m15 18-6-6 6-6"/>),
    "chevron-right" => ~s(<path d="m9 18 6-6-6-6"/>),
    "chevrons-left" => ~s(<path d="m11 17-5-5 5-5"/><path d="m18 17-5-5 5-5"/>),
    "chevrons-right" => ~s(<path d="m6 17 5-5-5-5"/><path d="m13 17 5-5-5-5"/>)
  }

  attr :name, :string, required: true

  defp lucide(assigns) do
    assigns = assign(assigns, :paths, Phoenix.HTML.raw(Map.fetch!(@lucide, assigns.name)))

    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class={if String.ends_with?(@name, ["-left", "-right"]), do: "rtl:rotate-180"}
      aria-hidden="true"
    >
      {@paths}
    </svg>
    """
  end

  defp push(nil, _value, _target), do: nil
  defp push(event, value, nil), do: JS.push(event, value: value)
  defp push(event, value, target), do: JS.push(event, value: value, target: target)

  defp resolve(allowed, column) when is_atom(column) and not is_nil(column) do
    if column in allowed, do: column
  end

  defp resolve(allowed, column) when is_binary(column) do
    Enum.find(allowed, &(Atom.to_string(&1) == column))
  end

  defp resolve(_allowed, _column), do: nil

  defp subset(columns, list), do: Enum.filter(columns, &(&1 in list))

  defp direction(dir) when dir in [:asc, "asc"], do: :asc
  defp direction(dir) when dir in [:desc, "desc"], do: :desc
  defp direction(_dir), do: nil

  defp positive_integer(n) when is_integer(n) and n > 0, do: n

  defp positive_integer(n) when is_binary(n) do
    case Integer.parse(n) do
      {int, ""} when int > 0 -> int
      _ -> nil
    end
  end

  defp positive_integer(_n), do: nil

  defp text(nil), do: ""
  defp text(value) when is_binary(value), do: value

  defp text(value) do
    if String.Chars.impl_for(value), do: to_string(value), else: inspect(value)
  end

  defp compare(%mod{} = a, %mod{} = b) do
    if Code.ensure_loaded?(mod) and function_exported?(mod, :compare, 2),
      do: mod.compare(a, b),
      else: term_compare(a, b)
  end

  defp compare(a, b) when is_binary(a) and is_binary(b) do
    term_compare(String.downcase(a), String.downcase(b))
  end

  defp compare(a, b), do: term_compare(a, b)

  defp term_compare(a, b) when a < b, do: :lt
  defp term_compare(a, b) when a > b, do: :gt
  defp term_compare(_a, _b), do: :eq
end
