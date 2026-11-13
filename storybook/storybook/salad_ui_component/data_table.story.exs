defmodule Storybook.SaladUIComponents.DataTable do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Button
  import SaladUI.Checkbox
  import SaladUI.DataTable, only: [data_table_view_options: 1]
  import SaladUI.DropdownMenu
  import SaladUI.Icon
  import SaladUI.Input
  import SaladUI.Table

  alias Phoenix.LiveView.JS
  alias SaladUI.DataTable

  def doc do
    """
    shadcn's data-table demo: sorting, filtering, pagination, column visibility
    and row selection, built from `table`, `dropdown_menu`, `checkbox`, `input`
    and `button` with the `SaladUI.DataTable` state helpers. Rows are a LiveView
    stream. The first five rows are shadcn's; fifteen more show pagination.
    """
  end

  @shadcn_rows [
    %{id: "m5gr84i9", amount: 316, status: "success", email: "ken99@example.com"},
    %{id: "3u1reuv4", amount: 242, status: "success", email: "Abe45@example.com"},
    %{id: "derv1ws0", amount: 837, status: "processing", email: "Monserrat44@example.com"},
    %{id: "5kma53ae", amount: 874, status: "success", email: "Silas22@example.com"},
    %{id: "bhqecj4p", amount: 721, status: "failed", email: "carmella@example.com"}
  ]

  @names ~w(Olivia liam Emma noah Ava elijah Sophia james Isabella lucas Mia mason Amelia ethan Harper)
  @statuses ~w(pending processing success failed)

  @payments @shadcn_rows ++
              (@names
               |> Enum.with_index(1)
               |> Enum.map(fn {name, i} ->
                 %{
                   id: "pay" <> String.pad_leading(Integer.to_string(i), 5, "0"),
                   amount: rem(i * 389, 950) + 50,
                   status: Enum.at(@statuses, rem(i, 4)),
                   email: "#{name}#{i * 3}@example.com"
                 }
               end))

  @impl true
  def mount(_params, _session, socket) do
    table = DataTable.new(columns: [:status, :email, :amount], sortable: [:email], filterable: [:email])

    {:ok, socket |> assign(:table, table) |> load_rows()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="flex items-center py-4">
        <form id="data-table-filter" phx-change="filter" phx-submit="filter" class="w-full max-w-sm">
          <.input
            name="email"
            value={DataTable.filter_value(@table, :email)}
            placeholder="Filter emails..."
            phx-debounce="150"
            autocomplete="off"
          />
        </form>
        <.data_table_view_options
          id="data-table-columns"
          table={@table}
          on-visibility-change="toggle_column"
          label={nil}
          size="default"
          class="ml-auto"
        >
          Columns <.icon name="hero-chevron-down" class="size-4" />
        </.data_table_view_options>
      </div>
      <div class="overflow-hidden rounded-md border">
        <.table>
          <.table_header>
            <.table_row>
              <.table_head>
                <.checkbox
                  id="data-table-select-all"
                  value={@select_all == true}
                  indeterminate={@select_all == :indeterminate}
                  disabled={@page_rows == []}
                  phx-click="toggle_all"
                  aria-label="Select all"
                />
              </.table_head>
              <.table_head :if={DataTable.column_visible?(@table, :status)}>Status</.table_head>
              <.table_head
                :if={DataTable.column_visible?(@table, :email)}
                aria-sort={DataTable.aria_sort(@table, :email)}
              >
                <.button variant="ghost" phx-click={JS.push("sort", value: %{column: "email"})}>
                  Email <.icon name="hero-arrows-up-down" class="size-4" />
                </.button>
              </.table_head>
              <.table_head :if={DataTable.column_visible?(@table, :amount)}>
                <div class="text-right">Amount</div>
              </.table_head>
              <.table_head><span class="sr-only">Actions</span></.table_head>
            </.table_row>
          </.table_header>
          <.table_body id="data-table-payments" phx-update="stream">
            <.table_row id="data-table-payments-empty" class="hidden only:table-row">
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
              <.table_cell :if={DataTable.column_visible?(@table, :status)}>
                <div class="capitalize">{payment.status}</div>
              </.table_cell>
              <.table_cell :if={DataTable.column_visible?(@table, :email)}>
                <div class="lowercase">{payment.email}</div>
              </.table_cell>
              <.table_cell :if={DataTable.column_visible?(@table, :amount)}>
                <div class="text-right font-medium">{format_amount(payment.amount)}</div>
              </.table_cell>
              <.table_cell>
                <.dropdown_menu id={"actions-" <> dom_id}>
                  <.dropdown_menu_trigger
                    as={&button/1}
                    class="h-8 w-8 p-0"
                    {%{variant: "ghost"}}
                  >
                    <span class="sr-only">Open menu</span>
                    <.icon name="hero-ellipsis-horizontal" class="size-4" />
                  </.dropdown_menu_trigger>
                  <.dropdown_menu_content align="end">
                    <.dropdown_menu_label>Actions</.dropdown_menu_label>
                    <.dropdown_menu_item on-select={
                      JS.dispatch("storybook:clipboard", detail: %{text: payment.id})
                    }>
                      Copy payment ID
                    </.dropdown_menu_item>
                    <.dropdown_menu_separator />
                    <.dropdown_menu_item>View customer</.dropdown_menu_item>
                    <.dropdown_menu_item>View payment details</.dropdown_menu_item>
                  </.dropdown_menu_content>
                </.dropdown_menu>
              </.table_cell>
            </.table_row>
          </.table_body>
        </.table>
      </div>
      <div class="flex items-center justify-end space-x-2 py-4">
        <div class="flex-1 text-sm text-muted-foreground">
          {@selected_count} of {@total} row(s) selected.
        </div>
        <div class="space-x-2">
          <.button
            variant="outline"
            size="sm"
            phx-click="previous_page"
            disabled={!DataTable.can_previous_page?(@table)}
          >
            Previous
          </.button>
          <.button
            variant="outline"
            size="sm"
            phx-click="next_page"
            disabled={!DataTable.can_next_page?(@table, @total)}
          >
            Next
          </.button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("filter", %{"email" => value}, socket) do
    update_table(socket, &DataTable.put_filter(&1, :email, value))
  end

  def handle_event("sort", %{"column" => column}, socket) do
    update_table(socket, &DataTable.toggle_sort(&1, column))
  end

  def handle_event("toggle_column", %{"column" => column, "visible" => visible}, socket) do
    update_table(socket, &DataTable.set_column_visibility(&1, column, visible))
  end

  def handle_event("previous_page", _params, socket) do
    update_table(socket, &DataTable.previous_page/1)
  end

  def handle_event("next_page", _params, socket) do
    update_table(socket, &DataTable.next_page/1)
  end

  # Every row on the page changes, so reset the stream.
  def handle_event("toggle_all", _params, socket) do
    ids = Enum.map(socket.assigns.page_rows, & &1.id)
    update_table(socket, &DataTable.toggle_all(&1, ids))
  end

  # Only this row changes: re-insert it so its checkbox and data-state update.
  def handle_event("toggle_row", %{"id" => id}, socket) do
    table = DataTable.toggle_row(socket.assigns.table, id)

    socket =
      socket
      |> assign(:table, table)
      |> assign_selection()

    case Enum.find(socket.assigns.page_rows, &(&1.id == id)) do
      nil -> {:noreply, socket}
      row -> {:noreply, stream_insert(socket, :payments, row)}
    end
  end

  defp update_table(socket, fun) do
    {:noreply, socket |> assign(:table, fun.(socket.assigns.table)) |> load_rows()}
  end

  defp load_rows(socket) do
    table = socket.assigns.table
    filtered = DataTable.filter_rows(@payments, table)
    table = DataTable.clamp_page(table, length(filtered))
    page_rows = filtered |> DataTable.sort_rows(table) |> DataTable.paginate_rows(table)

    socket
    |> assign(table: table, page_rows: page_rows, filtered_ids: Enum.map(filtered, & &1.id))
    |> assign_selection()
    |> stream(:payments, page_rows, reset: true)
  end

  defp assign_selection(socket) do
    %{table: table, page_rows: page_rows, filtered_ids: filtered_ids} = socket.assigns

    assign(socket,
      total: length(filtered_ids),
      selected_count: DataTable.selected_count(table, filtered_ids),
      select_all: DataTable.select_all_state(table, Enum.map(page_rows, & &1.id))
    )
  end

  defp format_amount(amount) do
    whole =
      amount |> Integer.to_string() |> String.reverse() |> String.replace(~r/(\d{3})(?=\d)/, "\\1,") |> String.reverse()

    "$#{whole}.00"
  end
end
