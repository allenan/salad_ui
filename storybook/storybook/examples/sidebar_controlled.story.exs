defmodule Storybook.Examples.SidebarControlled do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Sidebar

  def doc do
    "A controlled sidebar, as shadcn's `open` + `onOpenChange`: the LiveView owns `@open`, " <>
      "`on-open-change` reports client toggles, and `send_command/4` drives it from the server."
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, open: false, changes: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex items-center gap-2 text-sm">
        <button
          type="button"
          class="rounded-md border px-3 py-1.5"
          phx-click="set_open"
          phx-value-open="true"
        >
          Open (assign)
        </button>
        <button
          type="button"
          class="rounded-md border px-3 py-1.5"
          phx-click="set_open"
          phx-value-open="false"
        >
          Close (assign)
        </button>
        <button type="button" class="rounded-md border px-3 py-1.5" phx-click="toggle_command">
          Toggle (send_command)
        </button>
        <span id="sidebar-controlled-status" class="text-muted-foreground">
          open: {to_string(@open)} · client changes: {@changes}
        </span>
      </div>
      <div class="relative h-[420px] w-full overflow-hidden rounded-lg border [transform:translateZ(0)]">
        <.sidebar_provider
          id="sidebar-controlled-live"
          class="h-full min-h-0"
          open={@open}
          on-open-change="sidebar_open_change"
          keyboard_shortcut={false}
          cookie={nil}
        >
          <.sidebar
            id="sidebar-controlled-live-sb"
            class="h-full"
            collapsible="icon"
            state={if @open, do: "expanded", else: "collapsed"}
          >
            <.sidebar_content>
              <.sidebar_group>
                <.sidebar_group_label>Application</.sidebar_group_label>
                <.sidebar_menu>
                  <.sidebar_menu_item>
                    <.sidebar_menu_button as="a" href="#" tooltip="Home" is_active>
                      <Lucideicons.home /> <span>Home</span>
                    </.sidebar_menu_button>
                  </.sidebar_menu_item>
                  <.sidebar_menu_item>
                    <.sidebar_menu_button as="a" href="#" tooltip="Inbox">
                      <Lucideicons.inbox /> <span>Inbox</span>
                    </.sidebar_menu_button>
                  </.sidebar_menu_item>
                </.sidebar_menu>
              </.sidebar_group>
            </.sidebar_content>
            <.sidebar_rail />
          </.sidebar>
          <.sidebar_inset class="min-h-0">
            <header class="flex h-12 items-center gap-2 border-b px-4">
              <.sidebar_trigger class="-ml-1" />
            </header>
          </.sidebar_inset>
        </.sidebar_provider>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("sidebar_open_change", %{"open" => open}, socket) do
    {:noreply, socket |> assign(:open, open) |> update(:changes, &(&1 + 1))}
  end

  def handle_event("set_open", %{"open" => open}, socket) do
    {:noreply, assign(socket, :open, open == "true")}
  end

  def handle_event("toggle_command", _params, socket) do
    {:noreply, SaladUI.LiveView.send_command(socket, "sidebar-controlled-live", "toggle")}
  end
end
