defmodule SaladChat.ChatTest do
  # The store is a single global process, so these tests run one at a time.
  use ExUnit.Case, async: false

  alias SaladChat.Chat
  alias SaladChat.Chat.{Channel, Message}

  setup do
    Chat.reset!()
    Chat.subscribe()
    :ok
  end

  describe "seed data" do
    test "has people, channels, DMs and a few hundred messages" do
      assert length(Chat.list_users(bots: false)) == 7
      assert Chat.get_user("sprout").bot?

      assert ~w(ai-assistant design engineering general random) ==
               "maya" |> Chat.list_channels() |> Enum.map(& &1.id)

      assert [_ | _] = Chat.list_dms("maya")
      assert :ets.info(Chat.Store.messages(), :size) > 200
    end

    test "is deterministic apart from timestamps" do
      {before, _} = Chat.list_messages("engineering", limit: 100)
      Chat.reset!()
      {again, _} = Chat.list_messages("engineering", limit: 100)

      assert Enum.map(before, &{&1.id, &1.user_id, &1.body}) ==
               Enum.map(again, &{&1.id, &1.user_id, &1.body})
    end

    test "includes threads, reactions, pins, code and attachments" do
      {messages, _} = Chat.list_messages("engineering", limit: 200)

      assert Enum.any?(messages, &(&1.reply_count > 0))
      assert Enum.any?(messages, &(&1.reactions != []))
      assert Enum.any?(messages, & &1.pinned_by)
      assert Enum.any?(messages, &String.contains?(&1.body, "```elixir"))
      assert Enum.any?(messages, &(&1.attachments != []))
    end
  end

  describe "list_messages/2" do
    test "pages backwards through history, oldest first" do
      {page, true} = Chat.list_messages("general", limit: 10)
      assert length(page) == 10
      assert page == Enum.sort_by(page, & &1.id)
      assert Enum.all?(page, &(&1.parent_id == nil))

      {older, _} = Chat.list_messages("general", limit: 10, before: hd(page).id)
      assert List.last(older).id < hd(page).id
    end
  end

  describe "create_message/4" do
    test "stores and broadcasts the message" do
      {:ok, message} = Chat.create_message("maya", "random", "hello there")

      assert_receive {:message_created, %Message{id: id, body: "hello there"}}
      assert id == message.id
      assert Chat.latest_id("random") == id
    end

    test "rejects empty messages and unknown channels" do
      assert {:error, :empty} = Chat.create_message("maya", "random", "   ")
      assert {:error, :no_channel} = Chat.create_message("maya", "nope", "hi")
    end

    test "a reply bumps its parent's thread summary" do
      {:ok, parent} = Chat.create_message("maya", "design", "thoughts?")
      {:ok, _} = Chat.create_message("leo", "design", "love it", parent_id: parent.id)

      parent = Chat.get_message(parent.id)
      assert parent.reply_count == 1
      assert parent.reply_users == ["leo"]
      assert [%Message{body: "love it"}] = Chat.list_replies(parent.id)
      assert_receive {:message_updated, %Message{id: id, reply_count: 1}} when id == parent.id
    end

    test "a reply to a missing, nested or other-channel parent is rejected, not a crash" do
      {:ok, parent} = Chat.create_message("maya", "design", "thoughts?")
      {:ok, reply} = Chat.create_message("leo", "design", "yes", parent_id: parent.id)

      assert {:error, :no_parent} =
               Chat.create_message("leo", "design", "hi", parent_id: 999_999_999)

      assert {:error, :no_parent} =
               Chat.create_message("leo", "design", "hi", parent_id: reply.id)

      assert {:error, :no_parent} =
               Chat.create_message("leo", "random", "hi", parent_id: parent.id)

      # The store survived.
      assert Chat.get_message(parent.id).reply_count == 1
    end
  end

  test "toggle_reaction/3 adds and removes a reaction" do
    {:ok, m} = Chat.create_message("maya", "random", "react to me")

    {:ok, m} = Chat.toggle_reaction(m.id, "leo", "🎉")
    assert [%{emoji: "🎉", users: ["leo"]}] = m.reactions

    {:ok, m} = Chat.toggle_reaction(m.id, "sam", "🎉")
    assert [%{users: ["leo", "sam"]}] = m.reactions

    {:ok, m} = Chat.toggle_reaction(m.id, "leo", "🎉")
    {:ok, m} = Chat.toggle_reaction(m.id, "sam", "🎉")
    assert m.reactions == []
  end

  test "toggle_pin/2 pins and unpins" do
    {:ok, m} = Chat.create_message("maya", "random", "pin me")
    {:ok, _} = Chat.toggle_pin(m.id, "leo")
    assert Enum.any?(Chat.list_pinned("random"), &(&1.id == m.id))

    {:ok, _} = Chat.toggle_pin(m.id, "leo")
    refute Enum.any?(Chat.list_pinned("random"), &(&1.id == m.id))
  end

  describe "edit and delete" do
    test "only the author can edit" do
      {:ok, m} = Chat.create_message("maya", "random", "typo hre")
      assert {:error, :not_allowed} = Chat.edit_message(m.id, "leo", "nope")

      assert {:ok, %Message{body: "typo here", edited_at: %DateTime{}}} =
               Chat.edit_message(m.id, "maya", "typo here")
    end

    test "deleting a message with replies leaves a tombstone" do
      {:ok, parent} = Chat.create_message("maya", "random", "root")
      {:ok, reply} = Chat.create_message("leo", "random", "reply", parent_id: parent.id)

      assert :ok = Chat.delete_message(parent.id, "maya")
      assert %Message{deleted?: true} = Chat.get_message(parent.id)

      assert :ok = Chat.delete_message(reply.id, "leo")
      assert Chat.get_message(reply.id) == nil
      assert_receive {:message_deleted, %Message{id: id}} when id == reply.id
      assert Chat.get_message(parent.id).reply_count == 0
    end
  end

  describe "read state" do
    test "counts unread messages and mentions per conversation" do
      Chat.mark_read("kai", "random", Chat.latest_id("random"))
      refute Map.has_key?(Chat.unread_counts("kai"), "random")

      {:ok, _} = Chat.create_message("maya", "random", "hey @kai, lunch?")
      {:ok, _} = Chat.create_message("leo", "random", "me too")

      assert %{count: 2, mentions: 1} = Chat.unread_counts("kai")["random"]

      Chat.mark_read("kai", "random", Chat.latest_id("random"))
      refute Map.has_key?(Chat.unread_counts("kai"), "random")
    end

    test "own messages are never unread" do
      Chat.mark_read("maya", "random", Chat.latest_id("random"))
      {:ok, _} = Chat.create_message("maya", "random", "talking to myself")
      refute Map.has_key?(Chat.unread_counts("maya"), "random")
    end
  end

  describe "channels" do
    test "create_channel/2 validates the name" do
      assert {:error, errors} = Chat.create_channel(%{"name" => ""}, "maya")
      assert {"can't be blank", _} = errors[:name]

      assert {:error, errors} = Chat.create_channel(%{"name" => "general"}, "maya")
      assert {"a channel with that name already exists", _} = errors[:name]

      assert {:error, errors} = Chat.create_channel(%{"name" => "Has Spaces"}, "maya")
      assert errors[:name]
    end

    test "create_channel/2 adds the creator, members and Sprout" do
      {:ok, channel} =
        Chat.create_channel(
          %{"name" => "launch", "private" => "true", "members" => ["leo"]},
          "maya"
        )

      assert channel.private?
      assert Enum.sort(channel.members) == ~w(leo maya sprout)
      assert_receive {:channel_created, %Channel{id: "launch"}}

      assert Chat.can_view?(channel, "leo")
      refute Chat.can_view?(channel, "kai")
    end

    test "ensure_dm/2 is idempotent" do
      {:ok, dm} = Chat.ensure_dm("kai", "sam")
      assert dm.id == "dm-kai-sam"
      assert {:ok, ^dm} = Chat.ensure_dm("sam", "kai")
    end
  end

  test "search_messages/2 ranks keyword matches" do
    [best | _] = Chat.search_messages("webhook retries backoff", 3)
    assert best.body =~ "webhook retries"
  end
end
