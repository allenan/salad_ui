defmodule SaladChat.Chat.Message do
  @moduledoc """
  A chat message. Top-level messages have `parent_id: nil`; thread replies
  point at their parent. Messages written by Sprout carry a `bot` map with the
  trace of the steps it took and the streaming status.
  """

  defstruct id: nil,
            channel_id: nil,
            user_id: nil,
            body: "",
            inserted_at: nil,
            edited_at: nil,
            pinned_by: nil,
            parent_id: nil,
            reply_count: 0,
            reply_users: [],
            last_reply_at: nil,
            reactions: [],
            attachments: [],
            deleted?: false,
            bot: nil

  @type t :: %__MODULE__{}

  @mention ~r/(?<![\w@])@([a-z][a-z0-9_]*)/

  @doc "Handles mentioned in `body` (without the @), including `here`/`channel`."
  def mentions(body) when is_binary(body) do
    @mention
    |> Regex.scan(body, capture: :all_but_first)
    |> List.flatten()
    |> Enum.uniq()
  end

  def mentions(_), do: []

  @doc "Whether `handle` is mentioned directly or via @here/@channel."
  def mentions?(%__MODULE__{body: body}, handle) do
    m = mentions(body)
    handle in m or "here" in m or "channel" in m
  end

  def reacted?(%__MODULE__{reactions: reactions}, emoji, handle) do
    Enum.any?(reactions, &(&1.emoji == emoji and handle in &1.users))
  end

  def streaming?(%__MODULE__{bot: %{status: status}}), do: status != :done
  def streaming?(_), do: false
end
