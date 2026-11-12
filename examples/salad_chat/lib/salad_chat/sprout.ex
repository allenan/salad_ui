defmodule SaladChat.Sprout do
  @moduledoc """
  Sprout, the workspace's (canned) AI assistant.

  Messages posted in #ai-assistant, in a DM with Sprout, or that mention
  @sprout get a reply from a `SaladChat.Sprout.Responder`, which streams its
  trace and answer into a message with `Process.send_after/3`.

  This process also owns reminders ("Remind me about this").
  """
  use GenServer

  alias SaladChat.Chat
  alias SaladChat.Chat.{Channel, Message, Search}
  alias SaladChat.Sprout.Responder

  @assistant_channel "ai-assistant"

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Whether Sprout should answer `message` posted in `channel`."
  def should_reply?(%Message{user_id: user_id} = message, %Channel{} = channel) do
    bot = Chat.bot_handle()

    user_id != bot and message.bot == nil and
      (channel.id == @assistant_channel or
         (Channel.dm?(channel) and bot in channel.members) or
         bot in Message.mentions(message.body))
  end

  @doc "Starts a reply if Sprout should answer. Returns `:ok` either way."
  def maybe_reply(%Message{} = message, %Channel{} = channel) do
    if should_reply?(message, channel) do
      DynamicSupervisor.start_child(SaladChat.Sprout.Supervisor, {Responder, message})
    end

    :ok
  end

  @doc "Sends `handle` a DM from Sprout about `message_id` at `due_at`."
  def remind(handle, message_id, %DateTime{} = due_at) do
    GenServer.cast(__MODULE__, {:remind, handle, message_id, due_at})
  end

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_cast({:remind, handle, message_id, due_at}, state) do
    delay = max(DateTime.diff(due_at, DateTime.utc_now(), :millisecond), 0)
    # Timers beyond ~49 days overflow; nobody keeps a demo running that long.
    Process.send_after(self(), {:fire, handle, message_id}, min(delay, 2_000_000_000))
    {:noreply, state}
  end

  @impl true
  def handle_info({:fire, handle, message_id}, state) do
    bot = Chat.bot_handle()
    {:ok, dm} = Chat.ensure_dm(handle, bot)

    text =
      case Chat.get_message(message_id) do
        nil ->
          "⏰ Reminder: you asked me to remind you about a message, but it has since been deleted."

        message ->
          "⏰ Reminder: \"#{Search.excerpt(message.body)}\" from @#{message.user_id} in ##{message.channel_id}"
      end

    Chat.create_message(bot, dm.id, text, silent: true)
    {:noreply, state}
  end
end
