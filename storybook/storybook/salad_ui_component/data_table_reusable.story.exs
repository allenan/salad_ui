defmodule Storybook.SaladUIComponents.DataTableReusable do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Badge
  import SaladUI.Checkbox

  import SaladUI.DataTable,
    only: [data_table_column_header: 1, data_table_pagination: 1, data_table_view_options: 1]

  import SaladUI.Input
  import SaladUI.Table

  alias SaladUI.DataTable

  def doc do
    """
    The reusable components from shadcn's data-table guide (the Tasks example):
    `data_table_column_header` (sort and hide from a header menu),
    `data_table_view_options` (toggle columns) and `data_table_pagination`
    (selection count, rows per page, first / previous / next / last).
    """
  end

  @titles [
    "You can't compress the program without quantifying the open-source SSD pixel!",
    "Try to calculate the EXE feed, maybe it will index the multi-byte pixel!",
    "We need to bypass the neural TCP card!",
    "The SAS interface is down, bypass the open-source pixel so we can back up the PNG bandwidth!",
    "I'll parse the wireless SSL protocol, that should driver the API panel!",
    "Use the digital TLS panel, then you can transmit the haptic system!",
    "The UTF8 application is down, parse the neural bandwidth so we can back up the PNG firewall!",
    "Generating the driver won't do anything, we need to quantify the 1080p SMTP bandwidth!",
    "We need to program the back-end THX pixel!",
    "Calculating the bus won't do anything, we need to navigate the back-end JSON protocol!"
  ]
  @statuses ["backlog", "todo", "in progress", "done", "canceled"]
  @priorities ~w(low medium high)
  @labels ~w(bug feature documentation)

  @tasks for i <- 0..29,
             do: %{
               id: "TASK-#{8782 - i * 37}",
               title: Enum.at(@titles, rem(i * 3, 10)),
               status: Enum.at(@statuses, rem(i, 5)),
               priority: Enum.at(@priorities, rem(i * 2, 3)),
               label: Enum.at(@labels, rem(i, 3))
             }

  @impl true
  def mount(_params, _session, socket) do
    table =
      DataTable.new(
        columns: [:id, :title, :status, :priority],
        sortable: [:id, :title, :status, :priority],
        filterable: [:title],
        hideable: [:title, :status, :priority]
      )

    {:ok, socket |> assign(:table, table) |> load_rows()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex w-full flex-col gap-4">
      <div class="flex items-center justify-between">
        <form
          id="tasks-filter"
          phx-change="filter"
          phx-submit="filter"
          class="flex flex-1 items-center gap-2"
        >
          <.input
            name="title"
            value={DataTable.filter_value(@table, :title)}
            placeholder="Filter tasks..."
            phx-debounce="150"
            autocomplete="off"
            class="h-8 w-[150px] lg:w-[250px]"
          />
        </form>
        <.data_table_view_options
          id="tasks-view-options"
          table={@table}
          on-visibility-change="toggle_column"
          class="ml-auto h-8"
        />
      </div>
      <div class="overflow-hidden rounded-md border">
        <.table>
          <.table_header>
            <.table_row>
              <.table_head>
                <.checkbox
                  id="tasks-select-all"
                  value={@select_all == true}
                  indeterminate={@select_all == :indeterminate}
                  disabled={@page_rows == []}
                  phx-click="toggle_all"
                  aria-label="Select all"
                  class="translate-y-[2px]"
                />
              </.table_head>
              <.table_head
                :for={{column, title} <- @headers}
                :if={DataTable.column_visible?(@table, column)}
                aria-sort={DataTable.aria_sort(@table, column)}
              >
                <.data_table_column_header
                  id={"tasks-header-#{column}"}
                  table={@table}
                  column={column}
                  title={title}
                  on-sort="sort"
                  on-visibility-change="toggle_column"
                />
              </.table_head>
            </.table_row>
          </.table_header>
          <.table_body id="tasks" phx-update="stream">
            <.table_row id="tasks-empty" class="hidden only:table-row">
              <.table_cell colspan="5" class="h-24 text-center">No results.</.table_cell>
            </.table_row>
            <.table_row
              :for={{dom_id, task} <- @streams.tasks}
              id={dom_id}
              data-state={DataTable.selected?(@table, task.id) && "selected"}
            >
              <.table_cell>
                <.checkbox
                  id={"select-" <> dom_id}
                  value={DataTable.selected?(@table, task.id)}
                  phx-click="toggle_row"
                  phx-value-id={task.id}
                  aria-label="Select row"
                  class="translate-y-[2px]"
                />
              </.table_cell>
              <.table_cell class="w-[80px]">{task.id}</.table_cell>
              <.table_cell :if={DataTable.column_visible?(@table, :title)}>
                <div class="flex gap-2">
                  <.badge variant="outline">{task.label}</.badge>
                  <span class="max-w-[500px] truncate font-medium">{task.title}</span>
                </div>
              </.table_cell>
              <.table_cell :if={DataTable.column_visible?(@table, :status)}>
                <span class="capitalize">{task.status}</span>
              </.table_cell>
              <.table_cell :if={DataTable.column_visible?(@table, :priority)}>
                <span class="capitalize">{task.priority}</span>
              </.table_cell>
            </.table_row>
          </.table_body>
        </.table>
      </div>
      <.data_table_pagination
        id="tasks-pagination"
        table={@table}
        total={@total}
        selected-count={@selected_count}
        on-page-change="page"
        on-page-size-change="page_size"
      />
    </div>
    """
  end

  @impl true
  def handle_event("filter", %{"title" => value}, socket) do
    update_table(socket, &DataTable.put_filter(&1, :title, value))
  end

  def handle_event("sort", %{"column" => column, "direction" => direction}, socket) do
    update_table(socket, &DataTable.sort(&1, column, direction))
  end

  def handle_event("toggle_column", %{"column" => column, "visible" => visible}, socket) do
    update_table(socket, &DataTable.set_column_visibility(&1, column, visible))
  end

  def handle_event("page", %{"page" => page}, socket) do
    update_table(socket, &DataTable.set_page(&1, page))
  end

  def handle_event("page_size", %{"value" => size}, socket) do
    update_table(socket, &DataTable.set_page_size(&1, size))
  end

  def handle_event("toggle_all", _params, socket) do
    ids = Enum.map(socket.assigns.page_rows, & &1.id)
    update_table(socket, &DataTable.toggle_all(&1, ids))
  end

  def handle_event("toggle_row", %{"id" => id}, socket) do
    socket = socket |> assign(:table, DataTable.toggle_row(socket.assigns.table, id)) |> assign_selection()

    case Enum.find(socket.assigns.page_rows, &(&1.id == id)) do
      nil -> {:noreply, socket}
      row -> {:noreply, stream_insert(socket, :tasks, row)}
    end
  end

  defp update_table(socket, fun) do
    {:noreply, socket |> assign(:table, fun.(socket.assigns.table)) |> load_rows()}
  end

  defp load_rows(socket) do
    table = socket.assigns.table
    filtered = DataTable.filter_rows(@tasks, table)
    table = DataTable.clamp_page(table, length(filtered))
    page_rows = filtered |> DataTable.sort_rows(table) |> DataTable.paginate_rows(table)

    socket
    |> assign(
      table: table,
      page_rows: page_rows,
      filtered_ids: Enum.map(filtered, & &1.id),
      headers: [id: "Task", title: "Title", status: "Status", priority: "Priority"]
    )
    |> assign_selection()
    |> stream(:tasks, page_rows, reset: true)
  end

  defp assign_selection(socket) do
    %{table: table, page_rows: page_rows, filtered_ids: filtered_ids} = socket.assigns

    assign(socket,
      total: length(filtered_ids),
      selected_count: DataTable.selected_count(table, filtered_ids),
      select_all: DataTable.select_all_state(table, Enum.map(page_rows, & &1.id))
    )
  end
end
