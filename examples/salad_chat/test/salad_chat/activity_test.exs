defmodule SaladChat.ActivityTest do
  # Shares the global store and presence, so these run one at a time.
  use ExUnit.Case, async: false

  alias SaladChat.Activity
  alias SaladChat.Chat
  alias SaladChat.Chat.{Channel, Message}
  alias SaladChatWeb.Presence

  @humans ~w(maya leo priya sam ines jonah kai)

  setup do
    Chat.reset!()
    Chat.subscribe()
    :ok
  end

  defp state(opts) do
    Activity.new(Keyword.merge([seed: 42, presence: false], opts))
  end

  defp ticks(state, n) do
    Enum.map_reduce(1..n, state, fn _, state -> Activity.tick(state) end)
  end

  # Opens a "tab" as each handle, the way ChatLive tracks presence.
  defp online!(handles) do
    pid = spawn(fn -> Process.sleep(:infinity) end)
    for handle <- handles, do: {:ok, _} = Presence.track_user(pid, handle)

    on_exit(fn ->
      for handle <- handles, do: Presence.untrack(pid, Presence.topic(), handle)
      Process.exit(pid, :kill)
    end)
  end

  test "is disabled in the test config" do
    assert Activity.start_link() == :ignore
    refute Process.whereis(Activity)
  end

  test "posts in a public channel after a typing broadcast" do
    {action, _} = Activity.tick(state(weights: [post: 1]))

    assert %{type: :post, author: author, channel_id: channel_id} = action
    assert author in @humans
    assert channel_id in ~w(general engineering design random)
    assert_received {:typing, %{channel_id: ^channel_id, thread_id: nil, handle: ^author}}

    assert_received {:message_created,
                     %Message{user_id: ^author, channel_id: ^channel_id, parent_id: nil} = m}

    assert author in Chat.get_channel(channel_id).members
    assert m.body == action.body
    refute m.body =~ "{@}"
  end

  test "reacts to a recent message with a seed emoji" do
    {%{type: :react} = action, _} = Activity.tick(state(weights: [react: 1]))

    assert_received {:message_updated, %Message{id: id} = m}
    assert id == action.message_id
    assert Message.reacted?(m, action.emoji, action.author)
    assert m.user_id != action.author
    assert action.emoji in SaladChat.Activity.Lines.emoji()
  end

  test "replies in a thread" do
    {%{type: :reply, thread_id: parent_id} = action, _} =
      Activity.tick(state(weights: [reply: 1]))

    assert_received {:typing, %{thread_id: ^parent_id}}
    assert_received {:message_created, %Message{parent_id: ^parent_id} = reply}
    assert_received {:message_updated, %Message{id: ^parent_id} = parent}
    assert reply.user_id == action.author
    assert parent.reply_count == length(Chat.list_replies(parent_id))
    assert action.author in parent.reply_users
  end

  test "sends a DM between two people" do
    {%{type: :dm} = action, _} = Activity.tick(state(weights: [dm: 1]))

    assert_received {:message_created, %Message{channel_id: channel_id, user_id: author}}
    assert author == action.author
    assert %Channel{kind: :dm, members: members} = Chat.get_channel(channel_id)
    assert Enum.sort([action.author, action.peer]) == members
    refute Chat.bot_handle() in members
  end

  test "mixes actions, never as Sprout and without waking Sprout up" do
    bot = Chat.bot_handle()
    {actions, _} = ticks(state([]), 150)

    assert actions |> Enum.map(& &1.type) |> Enum.uniq() |> Enum.sort() ==
             [:dm, :post, :react, :reply]

    refute Enum.any?(actions, &(&1.author == bot))
    refute Enum.any?(actions, &(Map.get(&1, :channel_id) == "ai-assistant"))
    refute Enum.any?(actions, &(Map.get(&1, :body, "") =~ "@sprout"))

    refute_received {:message_created, %Message{user_id: ^bot}}
    assert DynamicSupervisor.count_children(SaladChat.Sprout.Supervisor).active == 0
  end

  test "mentions use the @handle syntax the message formatter renders" do
    {actions, _} = ticks(state(weights: [post: 1]), 120)
    mentions = actions |> Enum.flat_map(&Message.mentions(&1.body)) |> Enum.uniq()

    assert mentions != []
    assert Enum.all?(mentions, &(&1 in @humans))
  end

  test "does not repeat a line back to back" do
    {actions, _} = ticks(state(weights: [post: 1]), 60)

    bodies = Enum.map(actions, & &1.body)
    refute bodies |> Enum.chunk_every(2, 1, :discard) |> Enum.any?(fn [a, b] -> a == b end)
  end

  test "leaves alone the people someone is playing in a tab" do
    online!(@humans -- ["ines"])
    assert Activity.human_online() == MapSet.new(@humans -- ["ines"])

    {actions, _} = ticks(state([]), 40)
    assert Enum.all?(actions, &(&1.author == "ines"))
  end

  test "does nothing when everyone is online" do
    online!(@humans)

    assert {nil, _} = Activity.tick(state([]))
    refute_received {:message_created, _}
    refute_received {:typing, _}
  end

  test "shows simulated people as online, but not as human" do
    {%{author: author}, state} = Activity.tick(state(weights: [post: 1], presence: true))

    assert Map.has_key?(Presence.list(Presence.topic()), author)
    refute MapSet.member?(Activity.human_online(), author)

    for {handle, _} <- state.active, do: Presence.untrack(self(), Presence.topic(), handle)
  end

  test "prunes old simulated messages but never the seed" do
    seed_ids = Chat.Store.messages() |> :ets.tab2list() |> Enum.map(&elem(&1, 0))
    seed_max = Enum.max(seed_ids)

    {_, _} = ticks(state(weights: [post: 3, reply: 1], max_per_channel: 3), 60)

    messages = Chat.Store.messages() |> :ets.tab2list() |> Enum.map(&elem(&1, 1))
    assert Enum.all?(seed_ids, &Chat.get_message/1)

    simulated = Enum.filter(messages, &(&1.id > seed_max))
    assert simulated != []

    for {_channel, msgs} <- Enum.group_by(simulated, & &1.channel_id) do
      assert length(msgs) <= 3
    end
  end

  test "the same seed replays the same activity" do
    {first, _} = ticks(state([]), 20)
    Chat.reset!()
    {again, _} = ticks(state([]), 20)

    assert first == again
  end

  test "runs on its own timer" do
    {:ok, _pid} =
      start_supervised(
        {Activity,
         enabled: true,
         name: nil,
         seed: 7,
         presence: false,
         weights: [post: 1],
         interval_ms: {5, 10},
         typing_ms: {1, 2}}
      )

    assert_receive {:typing, %{handle: author}}, 1_000
    assert_receive {:message_created, %Message{user_id: ^author}}, 1_000
    assert_receive {:message_created, %Message{}}, 1_000
  end
end
