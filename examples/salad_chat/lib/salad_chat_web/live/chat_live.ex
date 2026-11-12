defmodule SaladChatWeb.ChatLive do
  @moduledoc """
  The chat page: `/as/:handle/c/:channel` (and `/t/:thread` for an open
  thread). The handle in the path is the identity, so two tabs can be two
  different people.

  Messages are a LiveView stream; every change arrives over PubSub from
  `SaladChat.Chat` and is applied to the stream, the thread pane or the
  sidebar.
  """
  use SaladChatWeb, :live_view

  import SaladChatWeb.AppSidebar
  import SaladChatWeb.ChatPanels
  import SaladChatWeb.Composer
  import SaladChatWeb.MessageComponents

  alias SaladChat.Chat
  alias SaladChat.Chat.{Channel, Message, Timezones, User}
  alias SaladChat.Sprout
  alias SaladChatWeb.{Paths, Presence, TimeFormat, Uploads}
  alias SaladUI.LiveView, as: Salad
  alias SaladUI.Toast

  @page 40
  @typing_ttl 4_000
  @typing_every 2_000

  ## Mount and navigation

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    case Chat.get_user(handle) do
      %{bot?: false} = me ->
        if connected?(socket) do
          Chat.subscribe()
          Phoenix.PubSub.subscribe(SaladChat.PubSub, Presence.topic())
          Presence.track_user(self(), handle)
        end

        users = Map.new(Chat.list_users(), &{&1.handle, &1})
        theme = (connected?(socket) && get_connect_params(socket)["theme"]) || me.prefs.theme

        {:ok,
         socket
         |> assign(
           me: me,
           users: users,
           known: users |> Map.keys() |> MapSet.new(),
           online: Presence.online_handles(),
           theme: theme,
           channel: nil,
           thread: nil,
           thread_replies: [],
           typing: %{},
           last_typing_at: 0,
           editing_id: nil,
           deleting: nil,
           reminding: nil,
           slash: [],
           thread_slash: [],
           main_form: blank_form(),
           thread_form: blank_form(),
           loaded?: false,
           has_more: false,
           oldest_id: nil,
           newest: nil,
           first_unread_id: nil,
           channel_empty?: false,
           pinned: []
         )
         |> assign_sidebar()
         |> stream_configure(:messages, dom_id: &"msg-#{&1.message.id}")
         |> stream(:messages, [])
         |> allow_upload(:attachments,
           accept: ~w(.png .jpg .jpeg .gif .webp .svg .pdf .txt .md .csv .json .zip),
           max_entries: 4,
           max_file_size: 8_000_000,
           auto_upload: true
         )}

      _ ->
        {:ok,
         socket
         |> put_flash(:error, "Pick someone to chat as first.")
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    me = socket.assigns.me
    channel = Chat.get_channel(params["channel"])

    if channel && Chat.can_view?(channel, me.handle) do
      socket =
        if current_channel?(socket, channel.id) and socket.assigns.loaded?,
          do: socket,
          else: load_channel(socket, channel)

      {:noreply, socket |> load_thread(params["thread"]) |> put_ctx()}
    else
      {:noreply,
       socket
       |> Toast.toast_error("That conversation doesn't exist or is private.")
       |> push_patch(to: Paths.channel_path(me.handle, "general"))}
    end
  end

  defp load_channel(socket, channel) do
    me = socket.assigns.me

    socket =
      assign(socket,
        channel: channel,
        page_title: Chat.display_name(channel, me.handle),
        pinned: Chat.list_pinned(channel.id),
        main_form: blank_form(),
        slash: [],
        typing: %{},
        editing_id: nil
      )

    if connected?(socket) do
      last_read = Chat.last_read(me.handle, channel.id)
      {messages, more?} = Chat.list_messages(channel.id, limit: @page)
      first_unread = Enum.find(messages, &(&1.id > last_read and &1.user_id != me.handle))
      first_unread_id = first_unread && first_unread.id
      prev = if messages != [], do: Chat.previous_message(hd(messages))

      if newest = List.last(messages), do: Chat.mark_read(me.handle, channel.id, newest.id)

      socket
      |> assign(
        loaded?: true,
        has_more: more?,
        oldest_id: messages != [] && hd(messages).id,
        newest: List.last(messages),
        first_unread_id: first_unread_id,
        channel_empty?: messages == [],
        unread: Map.delete(socket.assigns.unread, channel.id)
      )
      |> stream(:messages, build_rows(messages, prev, first_unread_id, me.timezone), reset: true)
    else
      assign(socket, loaded?: false)
    end
  end

  defp load_thread(socket, nil) do
    if socket.assigns.thread do
      socket
      |> assign(thread: nil, thread_replies: [], thread_slash: [])
      |> Salad.send_command("chat-panels", "setLayout", %{layout: [100, 0]})
      |> Salad.send_command("thread-sheet", "close")
    else
      socket
    end
  end

  defp load_thread(socket, id) do
    channel = socket.assigns.channel

    case Chat.get_message(id) do
      %Message{channel_id: ch, parent_id: nil} = parent when ch == channel.id ->
        opened? = socket.assigns.thread == nil or socket.assigns.thread.id != parent.id

        socket =
          socket
          |> assign(thread: parent, thread_form: blank_form(), thread_slash: [])
          |> assign_replies()

        if opened? and connected?(socket) do
          socket
          |> Salad.send_command("chat-panels", "setLayout", %{layout: [62, 38]})
          |> push_event("thread-opened", %{})
          |> push_event("composer:focus", %{id: "thread-desktop-composer-input"})
        else
          socket
        end

      _ ->
        socket
        |> Toast.toast_error("That thread is no longer available.")
        |> push_patch(to: Paths.channel_path(socket.assigns.me.handle, channel.id))
    end
  end

  defp assign_replies(socket) do
    replies = Chat.list_replies(socket.assigns.thread.id)
    tz = socket.assigns.me.timezone

    assign(
      socket,
      :thread_replies,
      Enum.map(build_rows(replies, nil, nil, tz), &%{&1 | day: nil})
    )
  end

  defp assign_sidebar(socket) do
    handle = socket.assigns.me.handle

    assign(socket,
      channels: Chat.list_channels(handle),
      dms: Chat.list_dms(handle),
      unread: drop_current(Chat.unread_counts(handle), socket)
    )
  end

  defp drop_current(unread, socket) do
    case socket.assigns[:channel] do
      %Channel{id: id} -> Map.delete(unread, id)
      _ -> unread
    end
  end

  defp put_ctx(socket) do
    a = socket.assigns

    assign(socket, :ctx, %{
      me: a.me.handle,
      users: a.users,
      known: a.known,
      online: a.online,
      tz: a.me.timezone,
      editing_id: a.editing_id,
      bubbles?: a.channel != nil and Channel.dm?(a.channel),
      thread?: false
    })
  end

  defp current_channel?(socket, id), do: match?(%Channel{id: ^id}, socket.assigns.channel)

  defp blank_form, do: to_form(%{"body" => ""})

  ## Rows

  defp build_rows(messages, prev, first_unread_id, tz) do
    {rows, _} =
      Enum.map_reduce(messages, prev, fn m, prev -> {row(m, prev, first_unread_id, tz), m} end)

    rows
  end

  defp row(%Message{} = m, prev, first_unread_id, tz) do
    day = TimeFormat.date(m.inserted_at, tz)
    new_day? = prev == nil or TimeFormat.date(prev.inserted_at, tz) != day
    unread? = m.id == first_unread_id

    grouped? =
      not new_day? and not unread? and prev.user_id == m.user_id and not prev.deleted? and
        m.bot == nil and DateTime.diff(m.inserted_at, prev.inserted_at) < 300

    %{
      id: m.id,
      message: m,
      grouped?: grouped?,
      day: if(new_day?, do: TimeFormat.day_label(day, tz)),
      unread?: unread?
    }
  end

  defp loaded?(socket, %Message{id: id, channel_id: ch, parent_id: nil}) do
    a = socket.assigns
    a.loaded? and a.channel.id == ch and is_integer(a.oldest_id) and id >= a.oldest_id
  end

  defp loaded?(_, _), do: false

  defp refresh_row(socket, %Message{} = m) do
    if loaded?(socket, m) do
      a = socket.assigns

      stream_insert(
        socket,
        :messages,
        row(m, Chat.previous_message(m), a.first_unread_id, a.me.timezone)
      )
    else
      socket
    end
  end

  ## Composer events

  @impl true
  def handle_event("composer_change", %{"composer" => composer} = params, socket) do
    body = params["body"] || ""
    socket = maybe_broadcast_typing(socket, body, composer)

    if composer == "main" do
      {:noreply,
       assign(socket, main_form: to_form(%{"body" => body}), slash: matching_commands(body))}
    else
      {:noreply,
       assign(socket,
         thread_form: to_form(%{"body" => body}),
         thread_slash: matching_commands(body)
       )}
    end
  end

  def handle_event("send", %{"body" => body}, socket) do
    case run_command(socket, body) do
      {:handled, socket} ->
        {:noreply, assign(socket, main_form: blank_form(), slash: [])}

      {:send, body, socket} ->
        attachments =
          consume_uploaded_entries(socket, :attachments, fn %{path: path}, entry ->
            {:ok, Uploads.store(path, entry)}
          end)

        case Chat.create_message(socket.assigns.me.handle, socket.assigns.channel.id, body,
               attachments: attachments
             ) do
          {:ok, _} ->
            {:noreply,
             socket
             |> assign(main_form: blank_form(), slash: [], last_typing_at: 0)
             |> push_event("chat:scroll-bottom", %{})}

          {:error, :empty} ->
            {:noreply, socket}

          {:error, reason} ->
            {:noreply,
             Toast.toast_error(socket, "Couldn't send that message",
               description: error_text(reason)
             )}
        end
    end
  end

  def handle_event("send_reply", %{"body" => body}, socket) do
    thread = socket.assigns.thread

    {body, socket} =
      case run_command(socket, body) do
        {:handled, socket} -> {"", socket}
        {:send, body, socket} -> {body, socket}
      end

    case thread && body != "" &&
           Chat.create_message(socket.assigns.me.handle, thread.channel_id, body,
             parent_id: thread.id
           ) do
      {:error, reason} ->
        {:noreply,
         Toast.toast_error(socket, "Couldn't send that reply", description: error_text(reason))}

      _ ->
        {:noreply, assign(socket, thread_form: blank_form(), thread_slash: [], last_typing_at: 0)}
    end
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachments, ref)}
  end

  ## Message events

  def handle_event("load_older", _, %{assigns: %{has_more: true, oldest_id: oldest}} = socket)
      when is_integer(oldest) do
    a = socket.assigns
    {messages, more?} = Chat.list_messages(a.channel.id, before: oldest, limit: @page)
    prev = if messages != [], do: Chat.previous_message(hd(messages))
    rows = build_rows(messages, prev, a.first_unread_id, a.me.timezone)

    {:noreply,
     socket
     |> assign(has_more: more?, oldest_id: if(messages != [], do: hd(messages).id, else: oldest))
     |> stream(:messages, Enum.reverse(rows), at: 0)}
  end

  def handle_event("load_older", _, socket), do: {:noreply, socket}

  def handle_event("react", %{"id" => id, "emoji" => emoji}, socket) do
    Chat.toggle_reaction(to_int(id), socket.assigns.me.handle, emoji)
    {:noreply, socket}
  end

  def handle_event("toggle_pin", %{"id" => id}, socket) do
    case Chat.toggle_pin(to_int(id), socket.assigns.me.handle) do
      {:ok, %{pinned_by: nil}} -> {:noreply, Toast.toast(socket, "Unpinned")}
      {:ok, _} -> {:noreply, Toast.toast_success(socket, "Pinned to the conversation")}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("edit", %{"id" => id}, socket) do
    socket = socket |> assign(editing_id: to_int(id)) |> put_ctx()
    {:noreply, refresh_editing(socket, to_int(id))}
  end

  def handle_event("cancel_edit", _, socket) do
    id = socket.assigns.editing_id
    socket = socket |> assign(editing_id: nil) |> put_ctx()
    {:noreply, refresh_editing(socket, id)}
  end

  def handle_event("save_edit", %{"message_id" => id, "body" => body}, socket) do
    id = to_int(id)

    socket =
      case Chat.edit_message(id, socket.assigns.me.handle, body) do
        {:ok, _} -> socket
        _ -> Toast.toast_error(socket, "Couldn't save that edit")
      end

    socket = socket |> assign(editing_id: nil) |> put_ctx()
    {:noreply, refresh_editing(socket, id)}
  end

  def handle_event("confirm_delete", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(deleting: Chat.get_message(to_int(id)))
     |> Salad.send_command("delete-dialog", "open")}
  end

  def handle_event("delete_message", _, socket) do
    socket = Salad.send_command(socket, "delete-dialog", "close")

    case socket.assigns.deleting &&
           Chat.delete_message(socket.assigns.deleting.id, socket.assigns.me.handle) do
      :ok -> {:noreply, socket |> assign(deleting: nil) |> Toast.toast("Message deleted")}
      _ -> {:noreply, Toast.toast_error(socket, "You can only delete your own messages")}
    end
  end

  def handle_event("remind", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(reminding: Chat.get_message(to_int(id)))
     |> Salad.send_command("remind-dialog", "open")}
  end

  def handle_event("save_reminder", params, socket) do
    me = socket.assigns.me

    due =
      case params do
        %{"in" => minutes} ->
          DateTime.add(DateTime.utc_now(), to_int(minutes) * 60, :second)

        %{"at" => at} when at != "" ->
          with {:ok, naive} <- NaiveDateTime.from_iso8601(String.slice(at <> ":00", 0, 19)),
               {:ok, local} <- DateTime.from_naive(naive, "Etc/UTC") do
            DateTime.add(local, -Timezones.offset(me.timezone) * 60, :second)
          else
            _ -> nil
          end

        _ ->
          nil
      end

    cond do
      due == nil or socket.assigns.reminding == nil ->
        {:noreply, Toast.toast_error(socket, "Pick a time for the reminder")}

      DateTime.before?(due, DateTime.utc_now()) ->
        {:noreply, Toast.toast_error(socket, "That time is in the past")}

      true ->
        Sprout.remind(me.handle, socket.assigns.reminding.id, due)

        {:noreply,
         socket
         |> assign(reminding: nil)
         |> Salad.send_command("remind-dialog", "close")
         |> Toast.toast_success("Reminder set",
           description:
             "Sprout will DM you #{String.downcase(TimeFormat.full(due, me.timezone))}."
         )}
    end
  end

  def handle_event("mark_unread", %{"id" => id}, socket) do
    me = socket.assigns.me
    Chat.mark_unread(me.handle, socket.assigns.channel.id, to_int(id))

    {:noreply,
     socket
     |> assign(unread: Chat.unread_counts(me.handle))
     |> Toast.toast("Marked as unread")}
  end

  ## Navigation and workspace events

  def handle_event("close_thread", _, socket) do
    a = socket.assigns

    if a.thread do
      {:noreply, push_patch(socket, to: Paths.channel_path(a.me.handle, a.channel.id))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("open_dm", %{"handle" => handle}, socket) do
    me = socket.assigns.me

    case Chat.get_user(handle) do
      nil ->
        {:noreply, socket}

      _ ->
        {:ok, dm} = Chat.ensure_dm(me.handle, handle)

        {:noreply,
         socket |> assign_sidebar() |> push_patch(to: Paths.channel_path(me.handle, dm.id))}
    end
  end

  def handle_event("view_message", %{"channel" => channel_id}, socket) do
    {:noreply, push_patch(socket, to: Paths.channel_path(socket.assigns.me.handle, channel_id))}
  end

  def handle_event("set_theme", %{"value" => theme}, socket),
    do: {:noreply, set_theme(socket, theme)}

  def handle_event("toggle_theme", _, socket) do
    {:noreply, set_theme(socket, if(socket.assigns.theme == "dark", do: "light", else: "dark"))}
  end

  def handle_event("toggle_away", %{"status" => status}, socket) when status in ~w(active away) do
    {:ok, me} = Chat.update_user(socket.assigns.me.handle, %{status: status})
    {:noreply, assign(socket, me: me)}
  end

  def handle_event("set_topic", %{"topic" => topic}, socket) do
    {:ok, _} = Chat.set_topic(socket.assigns.channel.id, topic)
    {:noreply, Toast.toast_success(socket, "Topic updated")}
  end

  defp set_theme(socket, theme) when theme in ~w(light dark system) do
    {:ok, me} = Chat.update_prefs(socket.assigns.me.handle, %{theme: theme})

    socket
    |> assign(theme: theme, me: me)
    |> push_event("set-theme", %{theme: theme})
  end

  defp set_theme(socket, _), do: socket

  defp refresh_editing(socket, nil), do: socket

  defp refresh_editing(socket, id) do
    case Chat.get_message(id) do
      %Message{parent_id: nil} = m -> refresh_row(socket, m)
      _ -> socket
    end
  end

  ## Slash commands

  defp run_command(socket, body) do
    body = String.trim(body)

    case String.split(body, ~r/\s+/, parts: 2) do
      ["/shrug" | rest] ->
        {:send, String.trim(Enum.join(rest) <> " ¯\\_(ツ)_/¯"), socket}

      ["/me", action] ->
        {:send, "*#{action}*", socket}

      ["/sprout", question] ->
        {:send, "@sprout " <> question, socket}

      ["/topic", topic] ->
        if Channel.dm?(socket.assigns.channel) do
          {:handled, Toast.toast_error(socket, "DMs don't have a topic")}
        else
          {:ok, _} = Chat.set_topic(socket.assigns.channel.id, topic)
          {:handled, Toast.toast_success(socket, "Topic updated")}
        end

      ["/theme", theme] when theme in ~w(light dark system) ->
        {:handled, set_theme(socket, theme)}

      ["/" <> _ = cmd | _] ->
        case matching_commands(cmd) do
          [{name, _, _}] when name != cmd ->
            {:handled,
             push_event(socket, "composer:set-text", %{id: "main-input", text: name <> " "})}

          _ ->
            {:handled,
             Toast.toast_error(socket, "Unknown command #{cmd}",
               description: "Type / to see what's available."
             )}
        end

      _ ->
        {:send, body, socket}
    end
  end

  defp error_text(:too_long), do: "Messages are limited to 4000 characters."
  defp error_text(:forbidden), do: "You're not a member of this conversation."
  defp error_text(_), do: "Please try again."

  ## Typing

  defp maybe_broadcast_typing(socket, body, composer) do
    now = System.monotonic_time(:millisecond)
    a = socket.assigns

    if String.trim(body) != "" and not String.starts_with?(body, "/") and
         now - a.last_typing_at > @typing_every do
      thread_id = if composer != "main" and a.thread, do: a.thread.id
      Chat.broadcast_typing(a.channel.id, thread_id, a.me.handle)
      assign(socket, last_typing_at: now)
    else
      socket
    end
  end

  defp typing_names(typing, users, thread_id) do
    for {handle, {tid, _}} <- typing, tid == thread_id, do: User.first_name(users[handle])
  end

  ## PubSub

  @impl true
  def handle_info({:message_created, %Message{} = m}, socket) do
    a = socket.assigns
    socket = assign(socket, typing: Map.delete(a.typing, m.user_id))

    cond do
      current_channel?(socket, m.channel_id) and m.parent_id == nil and a.loaded? ->
        Chat.mark_read(a.me.handle, m.channel_id, m.id)

        {:noreply,
         socket
         |> assign(newest: m, channel_empty?: false, oldest_id: a.oldest_id || m.id)
         |> stream_insert(:messages, row(m, a.newest, a.first_unread_id, a.me.timezone))}

      a.thread && m.parent_id == a.thread.id ->
        {:noreply, assign_replies(socket)}

      true ->
        {:noreply, notify(socket, m)}
    end
  end

  def handle_info({:message_updated, %Message{} = m}, socket) do
    a = socket.assigns
    socket = refresh_row(socket, m)

    socket =
      cond do
        a.thread && m.id == a.thread.id -> assign(socket, thread: m)
        a.thread && m.parent_id == a.thread.id -> assign_replies(socket)
        true -> socket
      end

    socket =
      if a.channel && m.channel_id == a.channel.id,
        do: assign(socket, pinned: Chat.list_pinned(m.channel_id)),
        else: socket

    {:noreply, socket}
  end

  def handle_info({:message_deleted, %Message{} = m}, socket) do
    a = socket.assigns

    socket =
      cond do
        a.thread && m.id == a.thread.id ->
          push_patch(socket, to: Paths.channel_path(a.me.handle, a.channel.id))

        a.thread && m.parent_id == a.thread.id ->
          assign_replies(socket)

        true ->
          socket
      end

    socket =
      if loaded?(socket, m) do
        socket = stream_delete_by_dom_id(socket, :messages, "msg-#{m.id}")
        socket = assign(socket, pinned: Chat.list_pinned(m.channel_id))

        socket =
          if a.newest && a.newest.id == m.id,
            do: assign(socket, newest: Chat.previous_message(m)),
            else: socket

        case Chat.next_message(m.channel_id, m.id) do
          nil -> socket
          next -> refresh_row(socket, next)
        end
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({event, %Channel{} = channel}, socket)
      when event in [:channel_created, :channel_updated] do
    socket = assign_sidebar(socket)

    socket =
      if socket.assigns.channel && socket.assigns.channel.id == channel.id,
        do: assign(socket, channel: channel),
        else: socket

    {:noreply, socket}
  end

  def handle_info({:user_updated, user}, socket) do
    users = Map.put(socket.assigns.users, user.handle, user)
    socket = assign(socket, users: users)

    socket =
      if user.handle == socket.assigns.me.handle, do: assign(socket, me: user), else: socket

    {:noreply, put_ctx(socket)}
  end

  def handle_info({:typing, %{channel_id: ch, thread_id: tid, handle: handle}}, socket) do
    a = socket.assigns

    if current_channel?(socket, ch) and handle != a.me.handle do
      Process.send_after(self(), :prune_typing, @typing_ttl + 50)
      expires = System.monotonic_time(:millisecond) + @typing_ttl
      {:noreply, assign(socket, typing: Map.put(a.typing, handle, {tid, expires}))}
    else
      {:noreply, socket}
    end
  end

  def handle_info(:prune_typing, socket) do
    now = System.monotonic_time(:millisecond)

    {:noreply,
     assign(socket, typing: Map.reject(socket.assigns.typing, fn {_, {_, exp}} -> exp <= now end))}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket |> assign(online: Presence.online_handles()) |> put_ctx()}
  end

  def handle_info({:settings_saved, user}, socket) do
    users = Map.put(socket.assigns.users, user.handle, user)

    {:noreply,
     socket
     |> assign(me: user, users: users, theme: user.prefs.theme)
     |> push_event("set-theme", %{theme: user.prefs.theme})
     |> put_ctx()
     |> Toast.toast_success("Preferences saved")}
  end

  # A message somewhere else: bump unread counts and maybe toast.
  defp notify(socket, %Message{} = m) do
    a = socket.assigns
    channel = Chat.get_channel(m.channel_id)

    cond do
      channel == nil or m.parent_id != nil or m.user_id == a.me.handle or
          not Chat.can_view?(channel, a.me.handle) ->
        socket

      true ->
        socket = assign(socket, unread: drop_current(Chat.unread_counts(a.me.handle), socket))
        author = a.users[m.user_id]
        mention? = Channel.dm?(channel) or Message.mentions?(m, a.me.handle)

        if mention? and a.me.prefs.notify_mentions and author do
          where =
            if Channel.dm?(channel),
              do: "sent you a message",
              else: "mentioned you in ##{channel.name}"

          Toast.toast(socket, "#{author.name} #{where}",
            description: Chat.Search.excerpt(m.body, 80),
            icon: "hero-at-symbol",
            action: %{label: "View", event: "view_message", value: %{channel: channel.id}}
          )
        else
          socket
        end
    end
  end

  defp to_int(v) when is_integer(v), do: v

  defp to_int(v) when is_binary(v) do
    case Integer.parse(v) do
      {n, _} -> n
      :error -> 0
    end
  end

  ## Render

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.sidebar_provider
        class="h-svh overflow-hidden"
        style={%{"--chat-font-size": "#{@me.prefs.font_size}px"}}
      >
        <.app_sidebar
          id="app-sidebar"
          me={@me}
          users={@users}
          channels={@channels}
          dms={@dms}
          unread={@unread}
          online={@online}
          active_id={@channel && @channel.id}
          theme={@theme}
        />
        <.app_sidebar
          id="mobile-sidebar"
          mobile
          me={@me}
          users={@users}
          channels={@channels}
          dms={@dms}
          unread={@unread}
          online={@online}
          active_id={@channel && @channel.id}
          theme={@theme}
        />

        <.sidebar_inset :if={@channel} class="h-svh min-h-0 min-w-0 overflow-hidden">
          <.channel_header
            channel={@channel}
            me={@me}
            users={@users}
            online={@online}
            pinned={@pinned}
            ctx={@ctx}
            theme={@theme}
          />
          <.resizable_panel_group id="chat-panels" class="min-h-0 flex-1">
            <.resizable_panel
              id="main-panel"
              default-size={if @thread, do: 62, else: 100}
              min-size={35}
              class="flex min-h-0 min-w-0 flex-col"
            >
              <div
                id="message-scroll"
                phx-hook="ChatScroll"
                class="salad-scroll-area min-h-0 flex-1 overflow-y-auto [overflow-anchor:none]"
              >
                <div data-scroll-content class="flex min-h-full flex-col justify-end pb-3">
                  <%= if @loaded? do %>
                    <.channel_intro
                      :if={!@has_more}
                      channel={@channel}
                      me={@me}
                      users={@users}
                      empty?={@channel_empty?}
                    />
                    <.message_skeletons :if={@has_more} id="history-skeleton" count={2} />
                    <div
                      id="messages"
                      phx-update="stream"
                      phx-viewport-top={@has_more && "load_older"}
                    >
                      <.message_row
                        :for={{dom_id, row} <- @streams.messages}
                        id={dom_id}
                        row={row}
                        ctx={@ctx}
                      />
                    </div>
                  <% else %>
                    <.message_skeletons id="initial-skeleton" count={6} />
                  <% end %>
                </div>
              </div>
              <.composer
                id="main"
                form={@main_form}
                upload={@uploads.attachments}
                slash={@slash}
                typing={typing_names(@typing, @users, nil)}
                placeholder={"Message " <> composer_target(@channel, @me)}
              />
            </.resizable_panel>
            <.resizable_handle with_handle class="max-md:hidden" />
            <.resizable_panel
              id="thread-panel"
              default-size={if @thread, do: 38, else: 0}
              min-size={0}
              max-size={60}
              class="min-h-0 min-w-0 border-l max-md:hidden"
            >
              <.thread_pane
                id="thread-desktop"
                parent={@thread}
                replies={@thread_replies}
                channel={@channel}
                ctx={@ctx}
                form={@thread_form}
                typing={typing_names(@typing, @users, @thread && @thread.id)}
              />
            </.resizable_panel>
          </.resizable_panel_group>
        </.sidebar_inset>
      </.sidebar_provider>

      <.sheet id="thread-sheet" on-close="close_thread">
        <.sheet_content side="right" class="w-full max-w-full p-0 sm:max-w-md md:hidden">
          <.thread_pane
            :if={@channel}
            id="thread-mobile"
            parent={@thread}
            replies={@thread_replies}
            channel={@channel}
            ctx={@ctx}
            form={@thread_form}
            closable={false}
            typing={typing_names(@typing, @users, @thread && @thread.id)}
          />
        </.sheet_content>
      </.sheet>

      <.quick_switcher me={@me} channels={@channels} dms={@dms} users={@users} online={@online} />
      <.channel_details
        :if={@channel}
        channel={@channel}
        me={@me}
        users={@users}
        online={@online}
        tz={@me.timezone}
      />
      <.delete_dialog message={@deleting} />
      <.remind_dialog message={@reminding} />
      <.live_component module={SaladChatWeb.SettingsComponent} id="settings" me={@me} />
      <.live_component
        module={SaladChatWeb.NewChannelComponent}
        id="new-channel"
        me={@me}
        users={@users}
      />
    </Layouts.app>
    """
  end

  defp composer_target(channel, me) do
    if Channel.dm?(channel), do: Chat.display_name(channel, me.handle), else: "#" <> channel.name
  end

  attr :channel, Channel, required: true
  attr :me, :any, required: true
  attr :users, :map, required: true
  attr :empty?, :boolean, default: false

  defp channel_intro(assigns) do
    ~H"""
    <div class="px-4 pt-10 pb-4">
      <%= if Channel.dm?(@channel) do %>
        <% peer = @users[Channel.dm_peer(@channel, @me.handle)] %>
        <SaladChatWeb.People.user_avatar user={peer} size="lg" class="mb-3 size-16 rounded-xl" />
        <h2 class="text-xl font-bold">{peer.name}</h2>
        <p class="text-sm text-muted-foreground">
          This is the beginning of your conversation with <strong>{peer.name}</strong>. {peer.title}.
        </p>
      <% else %>
        <div class="mb-3 flex size-12 items-center justify-center rounded-xl bg-primary/10 text-primary">
          <.icon
            name={if @channel.private?, do: "hero-lock-closed", else: "hero-hashtag"}
            class="size-6"
          />
        </div>
        <h2 class="text-xl font-bold">Welcome to #{@channel.name}</h2>
        <p class="text-sm text-muted-foreground">
          This is the very beginning of <strong>#{@channel.name}</strong>. {@channel.description}
        </p>
      <% end %>
      <.empty :if={@empty?} class="mt-6 border border-dashed">
        <.empty_header>
          <.empty_media variant="icon"><.icon name="hero-chat-bubble-oval-left" /></.empty_media>
          <.empty_title>No messages yet</.empty_title>
          <.empty_description>
            Be the first to say hi. Try <code class="rounded bg-muted px-1">/</code> for commands
            or mention <span class="mention">@sprout</span> for help.
          </.empty_description>
        </.empty_header>
      </.empty>
    </div>
    """
  end
end
