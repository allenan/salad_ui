defmodule SaladChat.Chat.Search do
  @moduledoc """
  A tiny keyword search over message bodies, shared by the store and by
  Sprout's `search_messages` tool.
  """

  alias SaladChat.Chat.Message

  @stopwords ~w(the a an and or of to in on for is are was were what when who how did we our
                about with from that this it be at by as do does me my you your i can
                please tell summarize summary there any)

  @doc "Lower-cased search terms of a query, without stopwords."
  def terms(query) do
    query
    |> String.downcase()
    |> String.split(~r/[^\p{L}\p{N}_-]+/u, trim: true)
    |> Enum.reject(&(&1 in @stopwords or String.length(&1) < 3))
    |> Enum.uniq()
  end

  @doc """
  Ranks `messages` against `query` and returns the best `limit` matches,
  highest score first (ties: most recent first).
  """
  def rank(messages, query, limit \\ 5) do
    terms = terms(query)

    if terms == [] do
      []
    else
      messages
      |> Enum.reject(
        &(&1.deleted? or &1.bot != nil or &1.channel_id == "ai-assistant" or
            &1.user_id == "sprout")
      )
      |> Enum.map(&{score(&1, terms), &1})
      |> Enum.filter(fn {score, _} -> score > 0 end)
      |> Enum.sort_by(fn {score, %Message{id: id}} -> {-score, -id} end)
      |> Enum.take(limit)
      |> Enum.map(&elem(&1, 1))
    end
  end

  @doc "A search hit as a plain map (stored in Sprout's trace)."
  def to_result(%Message{} = msg) do
    %{
      id: msg.id,
      channel_id: msg.channel_id,
      user_id: msg.user_id,
      where: "#" <> msg.channel_id,
      excerpt: excerpt(msg.body)
    }
  end

  @doc "A one-line plain text preview of a message body."
  def excerpt(body, max \\ 90) do
    text =
      body
      |> String.replace(~r/```.*?```/s, "[code]")
      |> String.replace(~r/[*`_]/, "")
      |> String.replace(~r/\s+/, " ")
      |> String.trim()

    if String.length(text) > max, do: String.slice(text, 0, max - 1) <> "…", else: text
  end

  defp score(%Message{body: body}, terms) do
    text = String.downcase(body)
    Enum.count(terms, &String.contains?(text, stem(&1)))
  end

  # "retries" should match "retry", "decided" should match "decide".
  defp stem(term) do
    cond do
      String.length(term) > 5 and String.ends_with?(term, "ies") ->
        String.slice(term, 0..-4//1)

      String.length(term) > 4 and String.ends_with?(term, ~w(ed es)) ->
        String.slice(term, 0..-3//1)

      String.length(term) > 3 and String.ends_with?(term, "s") ->
        String.slice(term, 0..-2//1)

      true ->
        term
    end
  end
end
