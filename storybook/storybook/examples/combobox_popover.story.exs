defmodule Storybook.Examples.ComboboxPopover do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Button
  import SaladUI.Command
  import SaladUI.Drawer
  import SaladUI.Popover

  def doc do
    """
    shadcn's Popover and Responsive combobox examples: a `command` list inside a
    `popover`, or inside a `drawer` on small screens. The server keeps the
    picked status and closes the popup with `SaladUI.LiveView.send_command/4`.
    The responsive one renders both popups and lets CSS show the trigger that
    fits the screen (`md:` and up gets the popover).
    """
  end

  @statuses [
    %{value: "backlog", label: "Backlog"},
    %{value: "todo", label: "Todo"},
    %{value: "in progress", label: "In Progress"},
    %{value: "done", label: "Done"},
    %{value: "canceled", label: "Canceled"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, statuses: @statuses, status: nil, responsive_status: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-md space-y-10 py-8">
      <section class="space-y-3">
        <h3 class="text-sm font-medium">Popover</h3>
        <div class="flex items-center gap-4">
          <p class="text-sm text-muted-foreground">Status</p>
          <.popover id="status-popover">
            <.popover_trigger as={&button/1} variant="outline" class="w-[150px] justify-start">
              {label(@status, "+ Set status")}
            </.popover_trigger>
            <.popover_content side="right" align="start" class="w-[200px] p-0">
              <.status_list
                id="status-command"
                statuses={@statuses}
                target="status"
                placeholder="Change status..."
              />
            </.popover_content>
          </.popover>
        </div>
      </section>

      <section class="space-y-3">
        <h3 class="text-sm font-medium">Responsive</h3>
        <div class="hidden md:block">
          <.popover id="responsive-popover">
            <.popover_trigger as={&button/1} variant="outline" class="w-[150px] justify-start">
              {label(@responsive_status, "+ Set status")}
            </.popover_trigger>
            <.popover_content align="start" class="w-[200px] p-0">
              <.status_list
                id="responsive-command"
                statuses={@statuses}
                target="responsive_status"
                placeholder="Filter status..."
              />
            </.popover_content>
          </.popover>
        </div>
        <div class="md:hidden">
          <.drawer id="responsive-drawer">
            <.drawer_trigger>
              <.button variant="outline" class="w-[150px] justify-start">
                {label(@responsive_status, "+ Set status")}
              </.button>
            </.drawer_trigger>
            <.drawer_content>
              <div class="mt-4 border-t">
                <.status_list
                  id="responsive-drawer-command"
                  statuses={@statuses}
                  target="responsive_status"
                  placeholder="Filter status..."
                />
              </div>
            </.drawer_content>
          </.drawer>
        </div>
      </section>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :statuses, :list, required: true
  attr :target, :string, required: true
  attr :placeholder, :string, required: true

  defp status_list(assigns) do
    ~H"""
    <.command id={@id}>
      <.command_input placeholder={@placeholder} />
      <.command_list>
        <.command_empty>No results found.</.command_empty>
        <.command_item
          :for={status <- @statuses}
          phx-click="set_status"
          phx-value-target={@target}
          phx-value-status={status.value}
        >
          {status.label}
        </.command_item>
      </.command_list>
    </.command>
    """
  end

  defp label(nil, placeholder), do: placeholder
  defp label(status, _placeholder), do: status.label

  @impl true
  def handle_event("set_status", %{"target" => target, "status" => value}, socket) do
    status = Enum.find(@statuses, &(&1.value == value))

    socket =
      case target do
        "status" ->
          socket
          |> assign(status: status)
          |> SaladUI.LiveView.send_command("status-popover", "close")

        _responsive ->
          socket
          |> assign(responsive_status: status)
          |> SaladUI.LiveView.send_command("responsive-popover", "close")
          |> SaladUI.LiveView.send_command("responsive-drawer", "close")
      end

    {:noreply, socket}
  end
end
