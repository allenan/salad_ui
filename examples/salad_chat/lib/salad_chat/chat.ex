defmodule SaladChat.Chat do
  @moduledoc """
  The chat context: people, channels, messages, reactions, pins and read
  state, kept in memory by `SaladChat.Chat.Store`.

  Every change is broadcast on the `"chat"` PubSub topic as one of:

    * `{:message_created, message}`
    * `{:message_updated, message}`
    * `{:message_deleted, message}`
    * `{:channel_created, channel}` / `{:channel_updated, channel}`
    * `{:user_updated, user}`
    * `{:typing, %{channel_id, thread_id, handle}}`
  """

  alias SaladChat.Chat.{Channel, Message, Search, Store, User}

  @topic "chat"
  @bot "sprout"

  def subscribe, do: Phoenix.PubSub.subscribe(SaladChat.PubSub, @topic)

  def broadcast(event), do: Phoenix.PubSub.broadcast(SaladChat.PubSub, @topic, event)

  def bot_handle, do: @bot

  @doc "Wipes and reseeds the store (used by tests)."
  def reset!, do: Store.reset!()

  ## Users

  def list_users(opts \\ []) do
    users = Store.users() |> :ets.tab2list() |> Enum.map(&elem(&1, 1))
    users = if opts[:bots] == false, do: Enum.reject(users, & &1.bot?), else: users
    Enum.sort_by(users, &{&1.bot?, &1.name})
  end

  def get_user(handle) when is_binary(handle) do
    case :ets.lookup(Store.users(), handle) do
      [{_, user}] -> user
      [] -> nil
    end
  end

  def get_user(_), do: nil

  @doc "Updates profile fields (`name`, `title`, `bio`, `status`, `status_text`, `timezone`)."
  def update_user(handle, attrs) do
    allowed = [:name, :title, :bio, :status, :status_text, :timezone, :prefs]

    user =
      Store.run(fn ->
        user = get_user(handle)
        user = struct(user, Map.take(attrs, allowed))
        :ets.insert(Store.users(), {handle, user})
        user
      end)

    broadcast({:user_updated, user})
    {:ok, user}
  end

  def update_prefs(handle, prefs) do
    user = get_user(handle)
    update_user(handle, %{prefs: Map.merge(user.prefs, prefs)})
  end

  ## Channels

  def get_channel(id) do
    case :ets.lookup(Store.channels(), id) do
      [{_, channel}] -> channel
      [] -> nil
    end
  end

  defp all_channels, do: Store.channels() |> :ets.tab2list() |> Enum.map(&elem(&1, 1))

  @doc "Named channels `handle` can see: every public channel plus private ones they belong to."
  def list_channels(handle) do
    all_channels()
    |> Enum.filter(&(&1.kind == :channel and can_view?(&1, handle)))
    |> Enum.sort_by(& &1.name)
  end

  @doc "DMs `handle` is part of, ordered by the other person's name."
  def list_dms(handle) do
    all_channels()
    |> Enum.filter(&(&1.kind == :dm and handle in &1.members))
    |> Enum.sort_by(fn ch ->
      ch |> Channel.dm_peer(handle) |> get_user() |> then(&{&1.bot?, &1.name})
    end)
  end

  def can_view?(%Channel{kind: :dm, members: members}, handle), do: handle in members
  def can_view?(%Channel{private?: true, members: members}, handle), do: handle in members
  def can_view?(%Channel{}, _handle), do: true

  def member?(%Channel{members: members}, handle), do: handle in members

  @doc "Returns the DM between two people, creating it on first use."
  def ensure_dm(a, b) do
    id = Channel.dm_id(a, b)

    case get_channel(id) do
      %Channel{} = channel ->
        {:ok, channel}

      nil ->
        channel = %Channel{
          id: id,
          name: id,
          kind: :dm,
          members: Enum.sort(Enum.uniq([a, b])),
          created_by: a,
          inserted_at: DateTime.utc_now()
        }

        Store.run(fn -> :ets.insert(Store.channels(), {id, channel}) end)
        broadcast({:channel_created, channel})
        {:ok, channel}
    end
  end

  @doc """
  Validates channel params (`"name"`, `"description"`, `"private"`,
  `"members"`). Returns a keyword list of errors, empty when valid.
  """
  def validate_channel(params) do
    name = params |> Map.get("name", "") |> to_string() |> String.trim()

    name_errors =
      cond do
        name == "" ->
          [name: {"can't be blank", []}]

        String.length(name) > 40 ->
          [name: {"should be at most %{count} characters", [count: 40]}]

        not Regex.match?(~r/^[a-z0-9][a-z0-9_-]*$/, name) ->
          [name: {"use lowercase letters, numbers, - and _", []}]

        get_channel(name) != nil ->
          [name: {"a channel with that name already exists", []}]

        true ->
          []
      end

    desc = params |> Map.get("description", "") |> to_string()

    desc_errors =
      if String.length(desc) > 160,
        do: [description: {"should be at most %{count} characters", [count: 160]}],
        else: []

    name_errors ++ desc_errors
  end

  @doc "Turns a free-form name into a channel slug."
  def slugify(name) do
    name
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_-]+/, "-")
    |> String.trim("-")
  end

  def create_channel(params, creator) do
    case validate_channel(params) do
      [] ->
        name = String.trim(params["name"])
        members = params |> Map.get("members", []) |> List.wrap() |> Enum.filter(&get_user/1)

        channel = %Channel{
          id: name,
          name: name,
          kind: :channel,
          description: String.trim(params["description"] || ""),
          topic: "",
          private?: params["private"] in [true, "true"],
          members: Enum.uniq([creator, @bot | members]),
          created_by: creator,
          inserted_at: DateTime.utc_now()
        }

        Store.run(fn -> :ets.insert(Store.channels(), {channel.id, channel}) end)
        broadcast({:channel_created, channel})
        {:ok, channel}

      errors ->
        {:error, errors}
    end
  end

  def set_topic(channel_id, topic) do
    channel =
      Store.run(fn ->
        channel = %{get_channel(channel_id) | topic: String.slice(String.trim(topic), 0, 120)}
        :ets.insert(Store.channels(), {channel.id, channel})
        channel
      end)

    broadcast({:channel_updated, channel})
    {:ok, channel}
  end

  def join_channel(channel_id, handle) do
    channel =
      Store.run(fn ->
        channel = get_channel(channel_id)
        channel = %{channel | members: Enum.uniq(channel.members ++ [handle])}
        :ets.insert(Store.channels(), {channel.id, channel})
        channel
      end)

    broadcast({:channel_updated, channel})
    {:ok, channel}
  end

  ## Messages

  def get_message(id) when is_integer(id) do
    case :ets.lookup(Store.messages(), id) do
      [{_, message}] -> message
      [] -> nil
    end
  end

  def get_message(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> get_message(int)
      _ -> nil
    end
  end

  def get_message(_), do: nil

  @doc """
  The newest top-level messages of a channel, oldest first.

  Options: `:limit` (default 40) and `:before` (a message id, for loading
  older history). Returns `{messages, more?}`.
  """
  def list_messages(channel_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 40)
    guards = if before = opts[:before], do: [{:<, :"$1", before}], else: []
    spec = [{{:"$1", %{channel_id: channel_id, parent_id: nil}}, guards, [:"$_"]}]

    case :ets.select_reverse(Store.messages(), spec, limit + 1) do
      :"$end_of_table" ->
        {[], false}

      {rows, _cont} ->
        messages = rows |> Enum.take(limit) |> Enum.map(&elem(&1, 1)) |> Enum.reverse()
        {messages, length(rows) > limit}
    end
  end

  def list_replies(parent_id) do
    Store.messages()
    |> :ets.select([{{:_, %{parent_id: parent_id}}, [], [:"$_"]}])
    |> Enum.map(&elem(&1, 1))
    |> Enum.sort_by(& &1.id)
  end

  def list_pinned(channel_id) do
    Store.messages()
    |> :ets.select([{{:_, %{channel_id: channel_id, deleted?: false}}, [], [:"$_"]}])
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(& &1.pinned_by)
    |> Enum.sort_by(& &1.id, :desc)
  end

  @doc "The top-level message right before `message` in its channel, if any."
  def previous_message(%Message{channel_id: channel_id, id: id}) do
    case list_messages(channel_id, before: id, limit: 1) do
      {[prev], _} -> prev
      _ -> nil
    end
  end

  @doc "The top-level message right after message id `id` in a channel, if any."
  def next_message(channel_id, id) do
    Store.messages()
    |> :ets.select(
      [{{:"$1", %{channel_id: channel_id, parent_id: nil}}, [{:>, :"$1", id}], [:"$_"]}],
      1
    )
    |> case do
      {[{_, message}], _} -> message
      _ -> nil
    end
  end

  @doc "The latest top-level message id in a channel (0 when empty)."
  def latest_id(channel_id) do
    case list_messages(channel_id, limit: 1) do
      {[m], _} -> m.id
      _ -> 0
    end
  end

  @doc """
  Posts a message. Options: `:parent_id` (thread reply) and `:attachments`.
  Returns `{:ok, message}` or `{:error, reason}`.
  """
  def create_message(handle, channel_id, body, opts \\ []) do
    body = body |> to_string() |> String.trim()
    attachments = Keyword.get(opts, :attachments, [])
    channel = get_channel(channel_id)

    cond do
      channel == nil -> {:error, :no_channel}
      not can_view?(channel, handle) -> {:error, :forbidden}
      body == "" and attachments == [] -> {:error, :empty}
      String.length(body) > 4000 -> {:error, :too_long}
      true -> do_create(handle, channel, body, attachments, opts)
    end
  end

  defp do_create(handle, channel, body, attachments, opts) do
    parent_id = opts[:parent_id]

    {message, parent} =
      Store.run(fn ->
        message = %Message{
          id: Store.next_id(),
          channel_id: channel.id,
          user_id: handle,
          body: body,
          parent_id: parent_id,
          attachments: attachments,
          bot: opts[:bot],
          inserted_at: DateTime.utc_now()
        }

        :ets.insert(Store.messages(), {message.id, message})
        {message, if(parent_id, do: bump_parent(parent_id, message))}
      end)

    broadcast({:message_created, message})
    if parent, do: broadcast({:message_updated, parent})

    unless opts[:silent], do: SaladChat.Sprout.maybe_reply(message, channel)

    {:ok, message}
  end

  defp bump_parent(parent_id, reply) do
    parent = get_message(parent_id)

    parent = %{
      parent
      | reply_count: parent.reply_count + 1,
        reply_users: Enum.uniq(parent.reply_users ++ [reply.user_id]),
        last_reply_at: reply.inserted_at
    }

    :ets.insert(Store.messages(), {parent.id, parent})
    parent
  end

  @doc "Applies `fun` to a message and broadcasts the result. Used for Sprout's streaming."
  def update_message(id, fun) do
    case Store.run(fn -> update_in_store(id, fun) end) do
      nil ->
        {:error, :not_found}

      message ->
        broadcast({:message_updated, message})
        {:ok, message}
    end
  end

  defp update_in_store(id, fun) do
    case get_message(id) do
      nil ->
        nil

      message ->
        message = fun.(message)
        :ets.insert(Store.messages(), {message.id, message})
        message
    end
  end

  def edit_message(id, handle, body) do
    body = String.trim(body)

    with %Message{user_id: ^handle} <- get_message(id),
         false <- body == "" do
      update_message(id, &%{&1 | body: body, edited_at: DateTime.utc_now()})
    else
      _ -> {:error, :not_allowed}
    end
  end

  @doc """
  Deletes a message. A message with replies stays as a tombstone so the
  thread keeps its root.
  """
  def delete_message(id, handle) do
    case get_message(id) do
      %Message{user_id: ^handle} = message ->
        result =
          Store.run(fn ->
            if message.reply_count > 0 do
              tomb = %{
                message
                | deleted?: true,
                  body: "",
                  attachments: [],
                  reactions: [],
                  pinned_by: nil
              }

              :ets.insert(Store.messages(), {message.id, tomb})
              {:updated, tomb}
            else
              :ets.delete(Store.messages(), message.id)
              parent = if message.parent_id, do: unbump_parent(message.parent_id, message.id)
              {:deleted, message, parent}
            end
          end)

        case result do
          {:updated, tomb} ->
            broadcast({:message_updated, tomb})

          {:deleted, message, parent} ->
            broadcast({:message_deleted, message})
            if parent, do: broadcast({:message_updated, parent})
        end

        :ok

      _ ->
        {:error, :not_allowed}
    end
  end

  defp unbump_parent(parent_id, removed_id) do
    case get_message(parent_id) do
      nil ->
        nil

      parent ->
        replies = Enum.reject(list_replies(parent_id), &(&1.id == removed_id))

        parent = %{
          parent
          | reply_count: length(replies),
            reply_users: replies |> Enum.map(& &1.user_id) |> Enum.uniq(),
            last_reply_at: List.last(replies) && List.last(replies).inserted_at
        }

        :ets.insert(Store.messages(), {parent.id, parent})
        parent
    end
  end

  def toggle_reaction(id, handle, emoji) do
    update_message(id, fn message ->
      reactions =
        if Enum.any?(message.reactions, &(&1.emoji == emoji)) do
          message.reactions
          |> Enum.map(fn
            %{emoji: ^emoji, users: users} = r ->
              if handle in users,
                do: %{r | users: users -- [handle]},
                else: %{r | users: users ++ [handle]}

            r ->
              r
          end)
          |> Enum.reject(&(&1.users == []))
        else
          message.reactions ++ [%{emoji: emoji, users: [handle]}]
        end

      %{message | reactions: reactions}
    end)
  end

  def toggle_pin(id, handle) do
    update_message(id, fn message ->
      %{message | pinned_by: if(message.pinned_by, do: nil, else: handle)}
    end)
  end

  @doc "Keyword search across public channels, best matches first."
  def search_messages(query, limit \\ 5) do
    public =
      for ch <- all_channels(),
          ch.kind == :channel and not ch.private?,
          into: MapSet.new(),
          do: ch.id

    Store.messages()
    |> :ets.tab2list()
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(&MapSet.member?(public, &1.channel_id))
    |> Search.rank(query, limit)
  end

  ## Read state

  def last_read(handle, channel_id) do
    case :ets.lookup(Store.reads(), {handle, channel_id}) do
      [{_, id}] -> id
      [] -> 0
    end
  end

  def mark_read(handle, channel_id, message_id) do
    if message_id > last_read(handle, channel_id) do
      Store.run(fn -> :ets.insert(Store.reads(), {{handle, channel_id}, message_id}) end)
    end

    :ok
  end

  @doc "Moves the read marker back so `message_id` and later show as unread."
  def mark_unread(handle, channel_id, message_id) do
    Store.run(fn -> :ets.insert(Store.reads(), {{handle, channel_id}, message_id - 1}) end)
    :ok
  end

  @doc """
  Unread top-level messages per conversation for `handle`:
  `%{channel_id => %{count: n, mentions: n}}`. Messages in DMs count as
  mentions, like in most chat apps.
  """
  def unread_counts(handle) do
    visible =
      Map.new(list_channels(handle) ++ list_dms(handle), fn ch ->
        {ch.id, {ch, last_read(handle, ch.id)}}
      end)

    :ets.foldl(
      fn {id, %Message{} = m}, acc ->
        case Map.get(visible, m.channel_id) do
          {ch, read} when m.parent_id == nil and m.user_id != handle and id > read ->
            mention = if Channel.dm?(ch) or Message.mentions?(m, handle), do: 1, else: 0

            Map.update(acc, m.channel_id, %{count: 1, mentions: mention}, fn c ->
              %{count: c.count + 1, mentions: c.mentions + mention}
            end)

          _ ->
            acc
        end
      end,
      %{},
      Store.messages()
    )
  end

  ## Typing

  def broadcast_typing(channel_id, thread_id, handle) do
    broadcast({:typing, %{channel_id: channel_id, thread_id: thread_id, handle: handle}})
  end

  ## Helpers

  @doc "Display name of a conversation from `handle`'s point of view."
  def display_name(%Channel{kind: :dm} = channel, handle) do
    case get_user(Channel.dm_peer(channel, handle)) do
      %User{name: name} -> name
      nil -> channel.name
    end
  end

  def display_name(%Channel{name: name}, _handle), do: name
end
