defmodule SaladChat.Sprout.Responder do
  @moduledoc """
  Streams one Sprout reply. Each step updates the reply message through
  `SaladChat.Chat.update_message/2`, which broadcasts it to every LiveView:

    1. `:thinking` - the reasoning row appears, shimmering.
    2. `:searching` - the `search_messages` tool call runs against the store.
    3. `:answering` - the answer streams in token by token.
    4. `:done`.

  Timings come from `config :salad_chat, :sprout` (`step_ms`, `token_ms`).
  """
  use GenServer, restart: :temporary

  alias SaladChat.Chat
  alias SaladChat.Chat.Search
  alias SaladChat.Sprout.Script

  def start_link(message), do: GenServer.start_link(__MODULE__, message)

  @impl true
  def init(question) do
    plan = Script.plan(question.body)

    bot = %{
      status: :thinking,
      question: question.body,
      query: plan.query,
      reasoning: plan.reasoning,
      results: [],
      thought_ms: nil,
      started_at: System.monotonic_time(:millisecond)
    }

    {:ok, reply} =
      Chat.create_message(Chat.bot_handle(), question.channel_id, "…",
        parent_id: question.parent_id,
        bot: bot,
        silent: true
      )

    schedule(:search, step_ms() * 2)
    {:ok, %{id: reply.id, plan: plan, tokens: []}}
  end

  @impl true
  def handle_info(:search, state) do
    results = state.plan.query |> Chat.search_messages(3) |> Enum.map(&Search.to_result/1)
    answer = state.plan.answer || Script.answer_from_results(state.plan.query, results)

    update(state, fn bot ->
      %{
        bot
        | status: :searching,
          results: results,
          thought_ms: System.monotonic_time(:millisecond) - bot.started_at
      }
    end)

    schedule(:answer, step_ms() * 2)
    {:noreply, %{state | tokens: Script.tokens(answer)}}
  end

  def handle_info(:answer, state) do
    update(state, &%{&1 | status: :answering}, "")
    schedule(:token, token_ms())
    {:noreply, state}
  end

  def handle_info(:token, %{tokens: [token | rest]} = state) do
    {:ok, _} = Chat.update_message(state.id, &%{&1 | body: &1.body <> token})
    schedule(:token, token_ms())
    {:noreply, %{state | tokens: rest}}
  end

  def handle_info(:token, %{tokens: []} = state) do
    update(state, &%{&1 | status: :done})
    {:stop, :normal, state}
  end

  defp update(state, fun, body \\ nil) do
    Chat.update_message(state.id, fn message ->
      message = %{message | bot: fun.(message.bot)}
      if body, do: %{message | body: body}, else: message
    end)
  end

  defp schedule(msg, ms), do: Process.send_after(self(), msg, ms)

  defp step_ms, do: config(:step_ms, 700)
  defp token_ms, do: config(:token_ms, 35)

  defp config(key, default) do
    :salad_chat |> Application.get_env(:sprout, []) |> Keyword.get(key, default)
  end
end
