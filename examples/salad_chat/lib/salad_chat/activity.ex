defmodule SaladChat.Activity do
  @moduledoc """
  Simulated workspace activity, so the demo is never a still life.

  Every few seconds (a random delay in `:interval_ms`) one of the seeded
  people does something, picked by `:weights`:

    * `:post` - a message in a public channel they belong to
    * `:react` - a reaction on a recent message
    * `:reply` - a reply in a thread (usually one that already has replies)
    * `:dm` - a direct message to someone else

  Messages are preceded by a typing broadcast lasting a random
  `:typing_ms`. Everything goes through `SaladChat.Chat`, so LiveViews render
  it like any other change. It never posts as Sprout, never writes in
  #ai-assistant, never mentions @sprout and posts with `silent: true`, so
  Sprout is never triggered.

  People who have a chat tab open are being played by a visitor and are left
  alone. While someone is simulated they show as online in
  `SaladChatWeb.Presence` (with `simulated: true` in their meta) for
  `:online_ms`.

  The store lives in memory, so at most `:max_per_channel` simulated
  messages (thread replies included) are kept per conversation; older ones
  are deleted, together with any replies. Seed history is never touched.

  Configure with `config :salad_chat, SaladChat.Activity, ...`; the
  `SALAD_CHAT_ACTIVITY=off` env var turns it off (see `config/runtime.exs`).
  """
  use GenServer

  alias SaladChat.Activity.Lines
  alias SaladChat.Chat
  alias SaladChat.Chat.{Channel, Message}
  alias SaladChatWeb.Presence

  @defaults [
    enabled: true,
    interval_ms: {6_000, 20_000},
    typing_ms: {1_500, 3_000},
    weights: [post: 50, react: 25, reply: 18, dm: 7],
    max_per_channel: 200,
    online_ms: 90_000,
    max_online: 3,
    presence: true,
    seed: nil
  ]

  # Lines remembered to avoid saying the same thing twice in a row.
  @recent 12

  ## API

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  @doc """
  Starts the simulator, or returns `:ignore` when it is disabled. `opts`
  override the application config; `name: nil` starts an unnamed process.
  """
  def start_link(opts \\ []) do
    opts = config(opts)

    if opts[:enabled] do
      GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
    else
      :ignore
    end
  end

  @doc "Builds the simulator state. Takes the same options as `start_link/1`."
  def new(opts \\ []) do
    opts = config(opts)

    rand =
      case opts[:seed] do
        nil -> :rand.seed_s(:exsss)
        seed -> :rand.seed_s(:exsss, seed)
      end

    %{
      rand: rand,
      weights: opts[:weights] |> Map.new() |> Enum.filter(fn {_, w} -> w > 0 end) |> Enum.sort(),
      interval_ms: opts[:interval_ms],
      typing_ms: opts[:typing_ms],
      max_per_channel: opts[:max_per_channel],
      online_ms: opts[:online_ms],
      max_online: opts[:max_online],
      presence?: opts[:presence],
      recent: [],
      posted: %{},
      active: %{}
    }
  end

  @doc """
  Runs one step synchronously, without the typing pause: picks an action,
  broadcasts typing for it and performs it. Returns `{action, state}`, where
  `action` is `nil` when nobody is free to act.
  """
  def tick(state) do
    {action, state} = plan(state)
    typing(action)
    {_result, state} = perform(action, state)
    {action, state}
  end

  @doc "Picks the next action (a map with a `:type`) without performing it."
  def plan(state) do
    online = human_online()
    authors = Enum.reject(humans(), &MapSet.member?(online, &1))
    {kind, state} = weighted(state)

    case plan(kind, authors, state) do
      {nil, state} when kind != :post -> plan(:post, authors, state)
      result -> result
    end
  end

  @doc "Performs an action from `plan/1`. Returns `{result, state}`."
  def perform(nil, state), do: {:skipped, state}

  def perform(action, state) do
    if MapSet.member?(human_online(), action.author) do
      # Someone opened a tab as this person while they were "typing".
      {:skipped, state}
    else
      case do_perform(action, state) do
        {{:ok, _} = result, state} -> {result, mark_active(state, action.author)}
        other -> other
      end
    end
  end

  @doc "Broadcasts typing for an action that posts a message."
  def typing(%{type: type} = action) when type in [:post, :reply, :dm] do
    Chat.broadcast_typing(action.channel_id, action.thread_id, action.author)
  end

  def typing(_), do: :ok

  @doc """
  Handles with a real chat tab open: tracked in presence by a LiveView, not by
  this simulator.
  """
  def human_online do
    for {handle, %{metas: metas}} <- Presence.list(Presence.topic()),
        Enum.any?(metas, &(!Map.get(&1, :simulated, false))),
        into: MapSet.new(),
        do: handle
  end

  ## GenServer

  @impl true
  def init(opts) do
    state = new(opts)
    schedule_tick(state)
  end

  @impl true
  def handle_info(:tick, state) do
    state = expire_active(state)
    {action, state} = plan(state)

    if action && action.type != :react do
      typing(action)
      {delay, state} = between(state, state.typing_ms)
      Process.send_after(self(), {:perform, action}, delay)
      {:noreply, state}
    else
      {_result, state} = perform(action, state)
      {:ok, state} = schedule_tick(state)
      {:noreply, state}
    end
  end

  def handle_info({:perform, action}, state) do
    {_result, state} = perform(action, state)
    {:ok, state} = schedule_tick(state)
    {:noreply, state}
  end

  defp schedule_tick(state) do
    {delay, state} = between(state, state.interval_ms)
    Process.send_after(self(), :tick, delay)
    {:ok, state}
  end

  ## Planning

  defp plan(_kind, [], state), do: {nil, state}

  defp plan(:post, authors, state) do
    channels = Enum.filter(channels(), &(eligible(&1, authors) != []))

    with {%Channel{} = channel, state} <- pick(state, channels),
         {author, state} <- pick(state, eligible(channel, authors)) do
      {body, state} = line(state, Lines.channel(channel.id), author, members(channel))

      {%{type: :post, author: author, channel_id: channel.id, thread_id: nil, body: body}, state}
    end
  end

  defp plan(:react, authors, state) do
    candidates =
      for channel <- channels(),
          message <- recent_messages(channel, 6),
          reactors = eligible(channel, authors) -- [message.user_id],
          reactors != [],
          do: {message, reactors}

    with {{message, reactors}, state} <- pick(state, candidates),
         {author, state} <- pick(state, reactors),
         {emoji, state} when emoji != nil <- pick_emoji(state, message, author) do
      {%{type: :react, author: author, message_id: message.id, emoji: emoji}, state}
    else
      {_, state} -> {nil, state}
    end
  end

  defp plan(:reply, authors, state) do
    candidates =
      for channel <- channels(),
          message <- recent_messages(channel, 12),
          eligible(channel, authors) != [],
          do: {message, channel}

    # Mostly join a conversation that is already going.
    {threaded?, state} = chance(state, 70)
    threads = Enum.filter(candidates, fn {m, _} -> m.reply_count > 0 end)
    candidates = if threaded? and threads != [], do: threads, else: candidates

    with {{parent, channel}, state} <- pick(state, candidates) do
      last = parent.id |> Chat.list_replies() |> List.last()
      # Nobody replies to themselves twice in a row; prefer fresh voices.
      skip = if last, do: [last.user_id], else: [parent.user_id]
      people = eligible(channel, authors)
      people = if people -- skip == [], do: people, else: people -- skip

      {author, state} = pick(state, people)
      {body, state} = line(state, Lines.replies(), author, members(channel))

      {%{type: :reply, author: author, channel_id: channel.id, thread_id: parent.id, body: body},
       state}
    end
  end

  defp plan(:dm, authors, state) do
    with {author, state} <- pick(state, authors),
         {peer, state} when peer != nil <- pick(state, humans() -- [author]) do
      {body, state} = line(state, Lines.dms(), author, [])

      {%{
         type: :dm,
         author: author,
         peer: peer,
         channel_id: Channel.dm_id(author, peer),
         thread_id: nil,
         body: body
       }, state}
    else
      {_, state} -> {nil, state}
    end
  end

  # The seeded people; never Sprout.
  defp humans do
    bot = Chat.bot_handle()
    for user <- Chat.list_users(bots: false), user.handle != bot, do: user.handle
  end

  # Public channels we have lines for (so never #ai-assistant or new ones).
  defp channels do
    known = Lines.channel_ids()

    Chat.bot_handle()
    |> Chat.list_channels()
    |> Enum.filter(&(&1.id in known and not &1.private?))
  end

  defp members(%Channel{members: members}), do: members -- [Chat.bot_handle()]

  defp eligible(channel, authors), do: Enum.filter(members(channel), &(&1 in authors))

  defp recent_messages(channel, n) do
    bot = Chat.bot_handle()
    {messages, _} = Chat.list_messages(channel.id, limit: n)
    Enum.filter(messages, &(not &1.deleted? and &1.bot == nil and &1.user_id != bot))
  end

  # Half the time pile onto an existing reaction, like people do.
  defp pick_emoji(state, message, author) do
    existing =
      for %{emoji: e} <- message.reactions, not Message.reacted?(message, e, author), do: e

    fresh = Enum.reject(Lines.emoji(), &Message.reacted?(message, &1, author))
    {pile_on?, state} = chance(state, 50)
    pick(state, if(pile_on? and existing != [], do: existing, else: fresh))
  end

  # A line from `pool` not said recently, with `{@}` filled in with someone
  # else in the conversation (lines with `{@}` are skipped when there is
  # nobody to mention).
  defp line(state, pool, author, members) do
    others = members -- [author]
    pool = if others == [], do: Enum.reject(pool, &String.contains?(&1, "{@}")), else: pool
    fresh = pool -- state.recent

    {template, state} = pick(state, if(fresh == [], do: pool, else: fresh))
    {mention, state} = pick(state, others)
    body = String.replace(template, "{@}", "@#{mention}")

    {body, %{state | recent: Enum.take([template | state.recent], @recent)}}
  end

  ## Performing

  defp do_perform(%{type: :react} = action, state) do
    with %Message{deleted?: false} = message <- Chat.get_message(action.message_id),
         false <- Message.reacted?(message, action.emoji, action.author),
         {:ok, message} <- Chat.toggle_reaction(message.id, action.author, action.emoji) do
      {{:ok, message}, state}
    else
      _ -> {:skipped, state}
    end
  end

  defp do_perform(%{type: :dm} = action, state) do
    {:ok, dm} = Chat.ensure_dm(action.author, action.peer)
    post(%{action | channel_id: dm.id}, state)
  end

  defp do_perform(%{thread_id: nil} = action, state), do: post(action, state)

  defp do_perform(action, state) do
    # The thread may have been deleted while we were "typing".
    case Chat.get_message(action.thread_id) do
      %Message{deleted?: false} -> post(action, state)
      _ -> {:skipped, state}
    end
  end

  defp post(action, state) do
    case Chat.create_message(action.author, action.channel_id, action.body,
           parent_id: action.thread_id,
           silent: true
         ) do
      {:ok, message} -> {{:ok, message}, remember(state, message)}
      error -> {error, state}
    end
  end

  # Keeps the ids we posted per conversation and prunes the oldest beyond
  # `:max_per_channel`.
  defp remember(state, %Message{channel_id: channel_id, id: id}) do
    queue = :queue.in(id, Map.get(state.posted, channel_id, :queue.new()))
    queue = prune(queue, state.max_per_channel)
    %{state | posted: Map.put(state.posted, channel_id, queue)}
  end

  defp prune(queue, max) do
    if :queue.len(queue) > max do
      {{:value, id}, queue} = :queue.out(queue)
      delete_with_replies(id)
      prune(queue, max)
    else
      queue
    end
  end

  defp delete_with_replies(id) do
    case Chat.get_message(id) do
      nil ->
        :ok

      message ->
        for reply <- Chat.list_replies(message.id),
            do: Chat.delete_message(reply.id, reply.user_id)

        Chat.delete_message(message.id, message.user_id)
    end
  end

  ## Simulated presence

  defp mark_active(%{presence?: false} = state, _handle), do: state

  defp mark_active(state, handle) do
    if !Map.has_key?(state.active, handle) do
      Presence.track(self(), Presence.topic(), handle, %{
        online_at: System.system_time(:second),
        simulated: true
      })
    end

    expires = System.monotonic_time(:millisecond) + state.online_ms
    state = %{state | active: Map.put(state.active, handle, expires)}

    # Only a few people look busy at once; the longest idle goes offline.
    if map_size(state.active) > state.max_online do
      {oldest, _} = Enum.min_by(state.active, &elem(&1, 1))
      untrack(state, oldest)
    else
      state
    end
  end

  defp expire_active(state) do
    now = System.monotonic_time(:millisecond)

    state.active
    |> Enum.filter(fn {_, expires} -> expires <= now end)
    |> Enum.reduce(state, fn {handle, _}, state -> untrack(state, handle) end)
  end

  defp untrack(state, handle) do
    Presence.untrack(self(), Presence.topic(), handle)
    %{state | active: Map.delete(state.active, handle)}
  end

  ## Randomness (an explicit `:rand` state, so a seed replays exactly)

  defp weighted(%{weights: []} = state), do: {:post, state}

  defp weighted(state) do
    total = state.weights |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    {roll, state} = uniform(state, total)

    kind =
      Enum.reduce_while(state.weights, roll, fn {kind, weight}, left ->
        if left <= weight, do: {:halt, kind}, else: {:cont, left - weight}
      end)

    {kind, state}
  end

  defp pick(state, []), do: {nil, state}

  defp pick(state, list) do
    {i, state} = uniform(state, length(list))
    {Enum.at(list, i - 1), state}
  end

  defp chance(state, percent) do
    {roll, state} = uniform(state, 100)
    {roll <= percent, state}
  end

  defp between(state, {lo, hi}) when hi > lo do
    {n, state} = uniform(state, hi - lo + 1)
    {lo + n - 1, state}
  end

  defp between(state, {lo, _hi}), do: {lo, state}

  defp uniform(state, n) do
    {value, rand} = :rand.uniform_s(n, state.rand)
    {value, %{state | rand: rand}}
  end

  defp config(opts) do
    @defaults
    |> Keyword.merge(Application.get_env(:salad_chat, __MODULE__, []))
    |> Keyword.merge(opts)
  end
end
