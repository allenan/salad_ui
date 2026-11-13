defmodule SaladChatWeb.ChatPanels do
  @moduledoc """
  The larger pieces of the chat page: channel header, thread pane and the
  overlays (quick switcher, channel details, delete and reminder dialogs).
  """
  use SaladChatWeb, :html

  import SaladChatWeb.Composer
  import SaladChatWeb.MessageComponents
  import SaladChatWeb.People

  alias SaladChat.Chat
  alias SaladChat.Chat.{Channel, User}
  alias SaladChatWeb.{Paths, TimeFormat}

  ## Channel header

  attr :channel, Channel, required: true
  attr :me, User, required: true
  attr :users, :map, required: true
  attr :online, :any, required: true
  attr :pinned, :list, required: true
  attr :ctx, :map, required: true
  attr :theme, :string, required: true

  def channel_header(assigns) do
    assigns =
      assigns
      |> assign(
        :peer,
        Channel.dm?(assigns.channel) &&
          assigns.users[Channel.dm_peer(assigns.channel, assigns.me.handle)]
      )
      |> assign(:members, Enum.map(assigns.channel.members, &assigns.users[&1]))

    ~H"""
    <header class="flex h-14 shrink-0 items-center gap-2 border-b bg-background/95 px-3 backdrop-blur sm:px-4">
      <.tooltip class="hidden md:block">
        <.tooltip_trigger>
          <.sidebar_trigger target="app-sidebar" class="-ml-1" />
        </.tooltip_trigger>
        <.tooltip_content side="bottom">Toggle sidebar</.tooltip_content>
      </.tooltip>
      <.button
        variant="ghost"
        size="icon-sm"
        class="-ml-1 md:hidden"
        aria-label="Open navigation"
        phx-click={SaladUI.JS.dispatch_command("open", to: "#mobile-sidebar")}
      >
        <.icon name="hero-bars-3" />
      </.button>
      <.separator orientation="vertical" class="mr-1 h-5" />

      <button
        type="button"
        class="flex min-w-0 items-center gap-2 rounded-md px-1 py-0.5 text-left hover:bg-muted"
        phx-click={SaladUI.JS.dispatch_command("open", to: "#channel-details")}
      >
        <%= if @peer do %>
          <.user_avatar
            user={@peer}
            size="sm"
            online={@peer.bot? or MapSet.member?(@online, @peer.handle)}
          />
          <span class="truncate font-semibold">{@peer.name}</span>
        <% else %>
          <.icon
            name={if @channel.private?, do: "hero-lock-closed", else: "hero-hashtag"}
            class="size-4 shrink-0 text-muted-foreground"
          />
          <span class="truncate font-semibold">{@channel.name}</span>
        <% end %>
        <.icon name="hero-chevron-down-mini" class="size-4 shrink-0 text-muted-foreground" />
      </button>
      <p
        :if={!@peer and @channel.topic != ""}
        class="hidden min-w-0 truncate border-l pl-3 text-sm text-muted-foreground lg:block"
        title={@channel.topic}
      >
        {@channel.topic}
      </p>

      <div class="ml-auto flex items-center gap-2">
        <button
          :if={!@peer}
          type="button"
          class="hidden items-center rounded-full p-0.5 hover:bg-muted sm:flex"
          aria-label={"#{length(@members)} members"}
          phx-click={SaladUI.JS.dispatch_command("open", to: "#channel-details")}
        >
          <.avatar_group class="*:data-[slot=avatar]:ring-background">
            <.user_avatar :for={u <- Enum.take(@members, 3)} user={u} size="sm" />
            <.avatar_group_count :if={length(@members) > 3} class="text-[10px]">
              +{length(@members) - 3}
            </.avatar_group_count>
          </.avatar_group>
        </button>

        <.button_group aria-label="Channel actions">
          <.popover id="pinned-popover">
            <.popover_trigger
              as={&button/1}
              {%{variant: "outline", size: "sm"}}
              aria-label="Pinned messages"
            >
              <.icon name="hero-bookmark" />
              <span class="tabular-nums">{length(@pinned)}</span>
            </.popover_trigger>
            <.popover_content align="end" class="w-80 p-0 sm:w-96">
              <.popover_header class="border-b px-4 py-3">
                <.popover_title>Pinned messages</.popover_title>
                <.popover_description>Important messages in this conversation.</.popover_description>
              </.popover_header>
              <.scroll_area class="max-h-80">
                <.empty :if={@pinned == []} class="p-6">
                  <.empty_header>
                    <.empty_media variant="icon"><.icon name="hero-bookmark" /></.empty_media>
                    <.empty_title>Nothing pinned yet</.empty_title>
                    <.empty_description>Pin a message from its ⋮ menu.</.empty_description>
                  </.empty_header>
                </.empty>
                <.item_group :if={@pinned != []} class="p-1">
                  <.item
                    :for={m <- @pinned}
                    size="sm"
                    patch={Paths.thread_path(@me.handle, m.channel_id, m.id)}
                  >
                    <.item_media><.user_avatar user={@users[m.user_id]} size="sm" /></.item_media>
                    <.item_content>
                      <.item_title>{@users[m.user_id].name}</.item_title>
                      <.item_description>{Chat.Search.excerpt(m.body, 120)}</.item_description>
                    </.item_content>
                  </.item>
                </.item_group>
              </.scroll_area>
            </.popover_content>
          </.popover>
          <.tooltip>
            <.tooltip_trigger>
              <.button
                variant="outline"
                size="icon-sm"
                aria-label="Conversation details"
                phx-click={SaladUI.JS.dispatch_command("open", to: "#channel-details")}
              >
                <.icon name="hero-information-circle" />
              </.button>
            </.tooltip_trigger>
            <.tooltip_content side="bottom">Details</.tooltip_content>
          </.tooltip>
          <.tooltip>
            <.tooltip_trigger>
              <.button
                variant="outline"
                size="sm"
                class="hidden sm:inline-flex"
                aria-label="Search"
                phx-click={SaladUI.JS.dispatch_command("open", to: "#quick-switcher_dialog")}
              >
                <.icon name="hero-magnifying-glass" />
                <.kbd_group>
                  <.kbd>⌘</.kbd><.kbd>K</.kbd>
                </.kbd_group>
              </.button>
            </.tooltip_trigger>
            <.tooltip_content side="bottom">
              Jump to a conversation
              <.kbd_group>
                <.kbd>⌘</.kbd><.kbd>K</.kbd>
              </.kbd_group>
            </.tooltip_content>
          </.tooltip>
        </.button_group>

        <.tooltip>
          <.tooltip_trigger>
            <.button
              variant="ghost"
              size="icon-sm"
              phx-click={JS.dispatch("salad-chat:toggle-theme")}
              aria-label="Toggle theme"
            >
              <.icon name="hero-moon" class="dark:hidden" />
              <.icon name="hero-sun" class="hidden dark:block" />
            </.button>
          </.tooltip_trigger>
          <.tooltip_content side="bottom">Toggle dark mode</.tooltip_content>
        </.tooltip>
      </div>
    </header>
    """
  end

  ## Thread pane

  attr :id, :string, required: true
  attr :parent, :any, default: nil
  attr :replies, :list, default: []
  attr :channel, Channel, required: true
  attr :ctx, :map, required: true
  attr :form, :any, required: true
  attr :typing, :list, default: []
  attr :closable, :boolean, default: true

  def thread_pane(%{parent: nil} = assigns) do
    ~H"""
    <div id={@id} class="flex h-full min-h-0 flex-col">
      <.empty class="h-full bg-gradient-to-b from-muted/40 to-background">
        <.empty_header>
          <.empty_media variant="icon"><.icon name="hero-chat-bubble-left-right" /></.empty_media>
          <.empty_title>No thread selected</.empty_title>
          <.empty_description>
            Hover a message and choose <strong>Reply in thread</strong>
            to keep side conversations tidy.
          </.empty_description>
        </.empty_header>
      </.empty>
    </div>
    """
  end

  def thread_pane(assigns) do
    assigns = assign(assigns, :thread_ctx, Map.put(assigns.ctx, :thread?, true))

    ~H"""
    <div id={@id} class="flex h-full min-h-0 flex-col bg-background">
      <div class="flex h-14 shrink-0 items-center gap-2 border-b px-4">
        <div class="min-w-0">
          <h2 class="font-semibold leading-tight">Thread</h2>
          <p class="truncate text-xs text-muted-foreground">
            {if Channel.dm?(@channel),
              do: Chat.display_name(@channel, @ctx.me),
              else: "#" <> @channel.name}
          </p>
        </div>
        <.tooltip :if={@closable} class="ml-auto">
          <.tooltip_trigger>
            <.button variant="ghost" size="icon-sm" phx-click="close_thread" aria-label="Close thread">
              <.icon name="hero-x-mark" />
            </.button>
          </.tooltip_trigger>
          <.tooltip_content side="left">
            Close
            <.kbd>Esc</.kbd>
          </.tooltip_content>
        </.tooltip>
      </div>
      <.message_scroller id={"#{@id}-scroller"} auto_scroll class="min-h-0 flex-1">
        <%!-- SALAD-BUG: the viewport's containment and fade mask trap row overlays; see chat_live.ex --%>
        <.message_scroller_viewport aria-label="Thread" class="contain-none! scroll-fade-none!">
          <.message_scroller_content class="gap-0 pb-2">
            <.message_row
              id={"#{@id}-parent"}
              row={%{message: @parent, grouped?: false, day: nil}}
              ctx={@thread_ctx}
            />
            <.message_scroller_item>
              <.marker variant="separator" class="px-4 py-2">
                <.marker_content class="text-xs">
                  {@parent.reply_count} {if @parent.reply_count == 1, do: "reply", else: "replies"}
                </.marker_content>
              </.marker>
            </.message_scroller_item>
            <.message_row
              :for={row <- @replies}
              id={"#{@id}-r#{row.message.id}"}
              row={row}
              ctx={@thread_ctx}
            />
            <.message_scroller_item :if={@replies == []}>
              <p class="px-4 py-6 text-center text-sm text-muted-foreground">
                No replies yet. Start the conversation!
              </p>
            </.message_scroller_item>
          </.message_scroller_content>
        </.message_scroller_viewport>
        <.message_scroller_button aria-label="Jump to latest reply" />
      </.message_scroller>
      <.composer
        id={"#{@id}-composer"}
        form={@form}
        event="send_reply"
        placeholder="Reply…"
        typing={@typing}
        class="pt-1"
      />
    </div>
    """
  end

  ## Quick switcher (⌘K)

  attr :me, User, required: true
  attr :channels, :list, required: true
  attr :dms, :list, required: true
  attr :users, :map, required: true
  attr :online, :any, required: true

  def quick_switcher(assigns) do
    dm_peers = MapSet.new(assigns.dms, &Channel.dm_peer(&1, assigns.me.handle))

    assigns =
      assign(
        assigns,
        :people,
        assigns.users
        |> Map.values()
        |> Enum.reject(&MapSet.member?(dm_peers, &1.handle))
        |> Enum.sort_by(& &1.name)
      )

    ~H"""
    <.command_dialog id="quick-switcher">
      <.command_input {%{placeholder: "Jump to a channel, person or action…"}} />
      <.command_list class="max-h-[60vh]">
        <%!-- TODO(salad-pass-2): use combobox for channel/people search --%>
        <.command_empty>
          <.empty class="p-6">
            <.empty_header>
              <.empty_media variant="icon"><.icon name="hero-magnifying-glass" /></.empty_media>
              <.empty_title>No results</.empty_title>
              <.empty_description>Try a channel name, a person or “settings”.</.empty_description>
            </.empty_header>
          </.empty>
        </.command_empty>
        <.command_group heading="Channels">
          <.command_item
            :for={{ch, i} <- Enum.with_index(@channels)}
            phx-click={go(Paths.channel_path(@me.handle, ch.id))}
          >
            <.icon name={if ch.private?, do: "hero-lock-closed", else: "hero-hashtag"} />
            <span>{ch.name}</span>
            <.command_shortcut :if={i < 9}>⌥{i + 1}</.command_shortcut>
          </.command_item>
        </.command_group>
        <.command_separator />
        <.command_group heading="Direct messages">
          <.command_item :for={dm <- @dms} phx-click={go(Paths.channel_path(@me.handle, dm.id))}>
            <% peer = @users[Channel.dm_peer(dm, @me.handle)] %>
            <.user_avatar
              user={peer}
              size="sm"
              online={peer.bot? or MapSet.member?(@online, peer.handle)}
              class="size-5"
            />
            <span>{peer.name}</span>
            <span class="text-xs text-muted-foreground">{peer.title}</span>
          </.command_item>
        </.command_group>
        <.command_separator :if={@people != []} />
        <.command_group :if={@people != []} heading="People">
          <.command_item
            :for={u <- @people}
            phx-click={
              JS.push("open_dm", value: %{handle: u.handle}) |> close("#quick-switcher_dialog")
            }
          >
            <.user_avatar user={u} size="sm" class="size-5" />
            <span>{u.name}</span>
            <span class="text-xs text-muted-foreground">{u.title}</span>
          </.command_item>
        </.command_group>
        <.command_separator />
        <.command_group heading="Actions">
          <.command_item phx-click={close("#quick-switcher_dialog") |> open("#create-channel-dialog")}>
            <.icon name="hero-plus-circle" /> <span>Create a channel</span>
          </.command_item>
          <.command_item phx-click={close("#quick-switcher_dialog") |> open("#settings-dialog")}>
            <.icon name="hero-cog-6-tooth" /> <span>Open settings</span>
          </.command_item>
          <.command_item phx-click={
            JS.dispatch("salad-chat:toggle-theme") |> close("#quick-switcher_dialog")
          }>
            <.icon name="hero-moon" /> <span>Toggle dark mode</span>
          </.command_item>
          <.command_item phx-click={JS.navigate(~p"/")}>
            <.icon name="hero-arrows-right-left" /> <span>Switch user</span>
          </.command_item>
        </.command_group>
      </.command_list>
    </.command_dialog>
    """
  end

  defp go(path), do: path |> JS.patch() |> close("#quick-switcher_dialog")

  ## Channel details

  attr :channel, Channel, required: true
  attr :me, User, required: true
  attr :users, :map, required: true
  attr :online, :any, required: true
  attr :tz, :string, required: true

  def channel_details(assigns) do
    assigns =
      assign(
        assigns,
        :members,
        assigns.channel.members
        |> Enum.map(&assigns.users[&1])
        |> Enum.reject(&is_nil/1)
        |> Enum.sort_by(&{&1.bot?, &1.name})
      )

    ~H"""
    <.sheet id="channel-details">
      <.sheet_content side="right" class="w-full max-w-full p-0 sm:max-w-md">
        <.sheet_header class="border-b p-6 pb-4">
          <.sheet_title class="flex items-center gap-2">
            <.icon
              :if={!Channel.dm?(@channel)}
              name={if @channel.private?, do: "hero-lock-closed", else: "hero-hashtag"}
              class="size-5 text-muted-foreground"
            />
            {Chat.display_name(@channel, @me.handle)}
          </.sheet_title>
          <.sheet_description>
            {cond do
              Channel.dm?(@channel) -> "Your direct message history."
              @channel.description != "" -> @channel.description
              true -> "No description yet."
            end}
          </.sheet_description>
        </.sheet_header>
        <.tabs id="details-tabs" default="about" class="min-h-0 flex-1 p-6 pt-4">
          <.tabs_list class="w-full">
            <.tabs_trigger value="about" id="details-tabs-trigger-about" class="flex-1">
              About
            </.tabs_trigger>
            <.tabs_trigger value="members" id="details-tabs-trigger-members" class="flex-1">
              Members
              <.badge variant="secondary" class="ml-1 h-5 px-1.5">{length(@members)}</.badge>
            </.tabs_trigger>
          </.tabs_list>
          <.tabs_content
            value="about"
            id="details-tabs-content-about"
            class="flex flex-col gap-4 pt-2"
          >
            <form
              :if={!Channel.dm?(@channel)}
              id="topic-form"
              phx-submit="set_topic"
              class="flex flex-col gap-2"
            >
              <.field>
                <.field_label for="topic-input">Topic</.field_label>
                <.input_group id="topic-group">
                  <.input_group_input
                    id="topic-input"
                    name="topic"
                    value={@channel.topic}
                    placeholder="Add a topic"
                    maxlength="120"
                  />
                  <.input_group_addon align="inline-end">
                    <.input_group_button type="submit" variant="secondary">Save</.input_group_button>
                  </.input_group_addon>
                </.input_group>
                <.field_description>Shown next to the channel name in the header.</.field_description>
              </.field>
            </form>
            <.separator :if={!Channel.dm?(@channel)} />
            <dl class="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-sm">
              <dt class="text-muted-foreground">Created by</dt>
              <dd>{(@users[@channel.created_by] || %{name: "someone"}).name}</dd>
              <dt class="text-muted-foreground">Created</dt>
              <dd>{TimeFormat.day_label(TimeFormat.date(@channel.inserted_at, @tz), @tz)}</dd>
              <dt class="text-muted-foreground">Visibility</dt>
              <dd>
                <.badge variant="outline">
                  {cond do
                    Channel.dm?(@channel) -> "Direct message"
                    @channel.private? -> "Private"
                    true -> "Public"
                  end}
                </.badge>
              </dd>
            </dl>
          </.tabs_content>
          <.tabs_content value="members" id="details-tabs-content-members" class="pt-2">
            <.scroll_area class="max-h-[60vh]">
              <.item_group>
                <.item :for={u <- @members} size="sm">
                  <.item_media>
                    <.user_avatar user={u} online={u.bot? or MapSet.member?(@online, u.handle)} />
                  </.item_media>
                  <.item_content>
                    <.item_title>
                      {u.name}
                      <span :if={u.handle == @me.handle} class="font-normal text-muted-foreground">
                        (you)
                      </span>
                    </.item_title>
                    <.item_description>{u.title}</.item_description>
                  </.item_content>
                  <.item_actions :if={u.handle != @me.handle}>
                    <.button
                      variant="ghost"
                      size="icon-sm"
                      aria-label={"Message #{u.name}"}
                      phx-click={
                        JS.push("open_dm", value: %{handle: u.handle}) |> close("#channel-details")
                      }
                    >
                      <.icon name="hero-chat-bubble-left-right" />
                    </.button>
                  </.item_actions>
                </.item>
              </.item_group>
            </.scroll_area>
          </.tabs_content>
        </.tabs>
      </.sheet_content>
    </.sheet>
    """
  end

  ## Confirmations

  attr :message, :any, default: nil

  def delete_dialog(assigns) do
    ~H"""
    <.alert_dialog id="delete-dialog">
      <.alert_dialog_content size="sm">
        <.alert_dialog_header>
          <.alert_dialog_media class="bg-destructive/10 text-destructive dark:bg-destructive/20">
            <.icon name="hero-trash" class="size-8" />
          </.alert_dialog_media>
          <.alert_dialog_title>Delete message?</.alert_dialog_title>
          <.alert_dialog_description>
            <span :if={@message} class="mb-1 line-clamp-2 italic">
              “{Chat.Search.excerpt(@message.body, 100)}”
            </span>
            This can't be undone.
          </.alert_dialog_description>
        </.alert_dialog_header>
        <.alert_dialog_footer>
          <.alert_dialog_cancel>Cancel</.alert_dialog_cancel>
          <.alert_dialog_action variant="destructive" phx-click="delete_message">
            Delete
          </.alert_dialog_action>
        </.alert_dialog_footer>
      </.alert_dialog_content>
    </.alert_dialog>
    """
  end

  attr :message, :any, default: nil

  def remind_dialog(assigns) do
    ~H"""
    <.dialog id="remind-dialog">
      <.dialog_content class="sm:max-w-md">
        <.dialog_header>
          <.dialog_title>Remind me about this</.dialog_title>
          <.dialog_description>
            <span :if={@message}>
              Sprout will DM you about “{Chat.Search.excerpt(@message.body, 80)}”.
            </span>
          </.dialog_description>
        </.dialog_header>
        <form id="remind-form" phx-submit="save_reminder" class="flex flex-col gap-4">
          <.field_group>
            <.field>
              <.field_label>Quick picks</.field_label>
              <.button_group aria-label="Quick reminder times" class="w-full">
                <.button type="submit" name="in" value="1" variant="outline" class="flex-1">
                  1 min
                </.button>
                <.button type="submit" name="in" value="20" variant="outline" class="flex-1">
                  20 min
                </.button>
                <.button type="submit" name="in" value="60" variant="outline" class="flex-1">
                  1 hour
                </.button>
              </.button_group>
            </.field>
            <.field_separator>or</.field_separator>
            <.field>
              <.field_label for="remind-at">Pick a date and time</.field_label>
              <%!-- TODO(salad-pass-2): use date_picker (calendar) instead of the native input --%>
              <.input id="remind-at" name="at" type="datetime-local" />
            </.field>
          </.field_group>
          <.dialog_footer>
            <.dialog_close>
              <.button type="button" variant="outline">Cancel</.button>
            </.dialog_close>
            <.button type="submit">Set reminder</.button>
          </.dialog_footer>
        </form>
      </.dialog_content>
    </.dialog>
    """
  end

  defp open(js, selector), do: SaladUI.JS.dispatch_command(js, "open", to: selector)
  defp close(js \\ %JS{}, selector), do: SaladUI.JS.dispatch_command(js, "close", to: selector)
end
