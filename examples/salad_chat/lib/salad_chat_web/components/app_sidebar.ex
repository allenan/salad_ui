defmodule SaladChatWeb.AppSidebar do
  @moduledoc """
  The workspace sidebar: workspace menu, channels, direct messages and the
  user menu. Rendered twice by the chat page: once as the desktop sidebar
  (collapsible to icons) and once inside a sheet on phones, so every id is
  prefixed with the sidebar's `id`.
  """
  use SaladChatWeb, :html

  import SaladChatWeb.People

  alias SaladChat.Chat.Channel
  alias SaladChatWeb.Paths

  attr :id, :string, required: true
  attr :mobile, :boolean, default: false
  attr :me, :any, required: true, doc: "the current %User{}"
  attr :users, :map, required: true
  attr :channels, :list, required: true
  attr :dms, :list, required: true
  attr :unread, :map, required: true
  attr :online, :any, required: true
  attr :active_id, :string, default: nil
  attr :theme, :string, default: "system"

  def app_sidebar(assigns) do
    ~H"""
    <.sidebar id={@id} collapsible="icon" is_mobile={@mobile}>
      <.sidebar_header>
        <.workspace_menu id={@id} theme={@theme} />
      </.sidebar_header>

      <.sidebar_content>
        <.sidebar_group class="py-0">
          <.sidebar_menu>
            <.sidebar_menu_item>
              <.sidebar_menu_button
                tooltip="Search (⌘K)"
                phx-click={close_mobile(@mobile) |> open("#quick-switcher_dialog")}
                class="text-sidebar-foreground/80"
              >
                <.icon name="hero-magnifying-glass" />
                <span>Jump to…</span>
                <.kbd_group class="ml-auto group-data-[collapsible=icon]:hidden">
                  <.kbd>⌘</.kbd><.kbd>K</.kbd>
                </.kbd_group>
              </.sidebar_menu_button>
            </.sidebar_menu_item>
          </.sidebar_menu>
        </.sidebar_group>

        <.section id={"#{@id}-channels"} title="Channels">
          <:action>
            <.sidebar_group_action
              title="Create channel"
              aria-label="Create channel"
              phx-click={close_mobile(@mobile) |> open("#create-channel-dialog")}
            >
              <.icon name="hero-plus" />
            </.sidebar_group_action>
          </:action>
          <.sidebar_menu_item :for={{channel, i} <- Enum.with_index(@channels)}>
            <.sidebar_menu_button
              is_active={channel.id == @active_id}
              tooltip={"#" <> channel.name}
              phx-click={navigate(@me.handle, channel.id, @mobile)}
              data-shortcut={!@mobile && i < 9 && i + 1}
            >
              <.icon name={if channel.private?, do: "hero-lock-closed", else: "hero-hashtag"} />
              <span class={unread?(@unread, channel.id) && "font-semibold text-sidebar-foreground"}>
                {channel.name}
              </span>
            </.sidebar_menu_button>
            <.unread_badge counts={@unread[channel.id]} />
          </.sidebar_menu_item>
        </.section>

        <.section id={"#{@id}-dms"} title="Direct messages">
          <.sidebar_menu_item :for={dm <- @dms}>
            <% peer = @users[Channel.dm_peer(dm, @me.handle)] %>
            <.sidebar_menu_button
              is_active={dm.id == @active_id}
              tooltip={peer.name}
              phx-click={navigate(@me.handle, dm.id, @mobile)}
            >
              <.user_avatar
                user={peer}
                size="sm"
                online={peer.bot? or MapSet.member?(@online, peer.handle)}
                class="size-5 shrink-0"
              />
              <span class={unread?(@unread, dm.id) && "font-semibold text-sidebar-foreground"}>
                {peer.name}{if peer.handle == @me.handle, do: " (you)"}
              </span>
            </.sidebar_menu_button>
            <.unread_badge counts={@unread[dm.id]} />
          </.sidebar_menu_item>
          <.sidebar_menu_item>
            <.sidebar_menu_button
              tooltip="New message"
              class="text-sidebar-foreground/70"
              phx-click={close_mobile(@mobile) |> open("#quick-switcher_dialog")}
            >
              <.icon name="hero-pencil-square" />
              <span>New message</span>
            </.sidebar_menu_button>
          </.sidebar_menu_item>
        </.section>
      </.sidebar_content>

      <.sidebar_footer>
        <.user_menu id={@id} me={@me} online={MapSet.member?(@online, @me.handle)} />
      </.sidebar_footer>
      <.sidebar_rail :if={!@mobile} />
    </.sidebar>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  slot :action
  slot :inner_block, required: true

  defp section(assigns) do
    ~H"""
    <.collapsible id={@id} open class="group/collapsible">
      <.sidebar_group>
        <.sidebar_group_label class="pr-8">
          <.collapsible_trigger
            as="button"
            class="flex w-full items-center gap-1 rounded-md text-left hover:text-sidebar-foreground"
          >
            <.icon
              name="hero-chevron-right-mini"
              class="size-4 transition-transform group-data-[state=open]/collapsible:rotate-90"
            />
            {@title}
          </.collapsible_trigger>
        </.sidebar_group_label>
        {render_slot(@action)}
        <.collapsible_content>
          <.sidebar_group_content>
            <.sidebar_menu>
              {render_slot(@inner_block)}
            </.sidebar_menu>
          </.sidebar_group_content>
        </.collapsible_content>
      </.sidebar_group>
    </.collapsible>
    """
  end

  attr :counts, :map, default: nil

  defp unread_badge(%{counts: %{count: n}} = assigns) when n > 0 do
    ~H"""
    <.sidebar_menu_badge class="top-1.5">
      <.badge
        variant={if @counts.mentions > 0, do: "destructive", else: "secondary"}
        class="h-5 min-w-5 rounded-full px-1.5 tabular-nums"
        aria-label={"#{@counts.count} unread"}
      >
        {if @counts.mentions > 0, do: @counts.mentions, else: @counts.count}
      </.badge>
    </.sidebar_menu_badge>
    """
  end

  defp unread_badge(assigns), do: ~H""

  defp unread?(unread, id), do: match?(%{count: n} when n > 0, unread[id])

  attr :id, :string, required: true
  attr :theme, :string, required: true

  defp workspace_menu(assigns) do
    ~H"""
    <.sidebar_menu>
      <.sidebar_menu_item>
        <.dropdown_menu id={"#{@id}-workspace-menu"} class="w-full">
          <.dropdown_menu_trigger class="flex w-full items-center gap-2 rounded-md p-1.5 text-left hover:bg-sidebar-accent group-data-[collapsible=icon]:p-0">
            <.logo class="size-8" />
            <span class="grid flex-1 leading-tight group-data-[collapsible=icon]:hidden">
              <span class="truncate text-sm font-semibold">Greenhouse</span>
              <span class="truncate text-xs text-muted-foreground">Salad Chat workspace</span>
            </span>
            <.icon
              name="hero-chevron-up-down"
              class="size-4 text-muted-foreground group-data-[collapsible=icon]:hidden"
            />
          </.dropdown_menu_trigger>
          <.dropdown_menu_content class="w-60">
            <.dropdown_menu_label>Greenhouse</.dropdown_menu_label>
            <.dropdown_menu_group>
              <.dropdown_menu_item on-select={open("#create-channel-dialog")}>
                <.icon name="hero-plus-circle" /> Create a channel
              </.dropdown_menu_item>
              <.dropdown_menu_item on-select={open("#settings-dialog")}>
                <.icon name="hero-cog-6-tooth" /> Preferences
                <.dropdown_menu_shortcut>⌘,</.dropdown_menu_shortcut>
              </.dropdown_menu_item>
              <.dropdown_menu_item on-select={open("#quick-switcher_dialog")}>
                <.icon name="hero-magnifying-glass" /> Jump to…
                <.dropdown_menu_shortcut>⌘K</.dropdown_menu_shortcut>
              </.dropdown_menu_item>
            </.dropdown_menu_group>
            <.dropdown_menu_separator />
            <.dropdown_menu_sub>
              <.dropdown_menu_sub_trigger>
                <.icon name="hero-swatch" /> Theme
              </.dropdown_menu_sub_trigger>
              <.dropdown_menu_sub_content>
                <.dropdown_menu_radio_group value={@theme} on-value-changed="set_theme">
                  <.dropdown_menu_radio_item value="light">Light</.dropdown_menu_radio_item>
                  <.dropdown_menu_radio_item value="dark">Dark</.dropdown_menu_radio_item>
                  <.dropdown_menu_radio_item value="system">System</.dropdown_menu_radio_item>
                </.dropdown_menu_radio_group>
              </.dropdown_menu_sub_content>
            </.dropdown_menu_sub>
            <.dropdown_menu_separator />
            <.dropdown_menu_link_item href={~p"/"}>
              <.icon name="hero-arrows-right-left" /> Switch user
            </.dropdown_menu_link_item>
          </.dropdown_menu_content>
        </.dropdown_menu>
      </.sidebar_menu_item>
    </.sidebar_menu>
    """
  end

  attr :id, :string, required: true
  attr :me, :any, required: true
  attr :online, :boolean, required: true

  defp user_menu(assigns) do
    ~H"""
    <.sidebar_menu>
      <.sidebar_menu_item>
        <.dropdown_menu id={"#{@id}-user-menu"} class="w-full">
          <.dropdown_menu_trigger class="flex w-full items-center gap-2 rounded-md p-1.5 text-left hover:bg-sidebar-accent group-data-[collapsible=icon]:p-0">
            <.user_avatar user={@me} online={@online} class="size-8" />
            <span class="grid flex-1 leading-tight group-data-[collapsible=icon]:hidden">
              <span class="truncate text-sm font-medium">{@me.name}</span>
              <span class="truncate text-xs text-muted-foreground">
                {@me.status_text || status_label(@me.status)}
              </span>
            </span>
            <.icon
              name="hero-chevron-up-down"
              class="size-4 text-muted-foreground group-data-[collapsible=icon]:hidden"
            />
          </.dropdown_menu_trigger>
          <.dropdown_menu_content side="top" class="w-60">
            <.dropdown_menu_label class="flex items-center gap-2 font-normal">
              <.user_avatar user={@me} size="sm" />
              <span class="grid leading-tight">
                <span class="font-medium">{@me.name}</span>
                <span class="text-xs text-muted-foreground">@{@me.handle}</span>
              </span>
            </.dropdown_menu_label>
            <.dropdown_menu_separator />
            <.dropdown_menu_item on-select={open("#settings-dialog")}>
              <.icon name="hero-user-circle" /> Profile & preferences
            </.dropdown_menu_item>
            <.dropdown_menu_item on-select={
              JS.push("toggle_away", value: %{status: away_toggle(@me.status)})
            }>
              <.icon name={if @me.status == "away", do: "hero-sun", else: "hero-moon"} />
              {if @me.status == "away", do: "Set yourself as active", else: "Set yourself as away"}
            </.dropdown_menu_item>
            <.dropdown_menu_separator />
            <.dropdown_menu_link_item href={~p"/"}>
              <.icon name="hero-arrows-right-left" /> Switch user
            </.dropdown_menu_link_item>
          </.dropdown_menu_content>
        </.dropdown_menu>
      </.sidebar_menu_item>
    </.sidebar_menu>
    """
  end

  defp away_toggle("away"), do: "active"
  defp away_toggle(_), do: "away"

  defp navigate(handle, channel_id, mobile) do
    JS.patch(Paths.channel_path(handle, channel_id)) |> close_mobile(mobile)
  end

  defp close_mobile(js \\ %JS{}, mobile)
  defp close_mobile(js, true), do: SaladUI.JS.dispatch_command(js, "close", to: "#mobile-sidebar")
  defp close_mobile(js, false), do: js

  defp open(js \\ %JS{}, selector), do: SaladUI.JS.dispatch_command(js, "open", to: selector)
end
