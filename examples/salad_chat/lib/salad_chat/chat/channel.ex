defmodule SaladChat.Chat.Channel do
  @moduledoc """
  A conversation: a named channel (`kind: :channel`) or a direct message
  between two people (`kind: :dm`).
  """

  defstruct id: nil,
            name: nil,
            kind: :channel,
            topic: "",
            description: "",
            private?: false,
            members: [],
            created_by: nil,
            inserted_at: nil

  @type t :: %__MODULE__{}

  @doc "The deterministic id of the DM between two handles."
  def dm_id(a, b), do: "dm-" <> Enum.join(Enum.sort([a, b]), "-")

  def dm?(%__MODULE__{kind: kind}), do: kind == :dm

  @doc "The other member of a DM, from `handle`'s point of view."
  def dm_peer(%__MODULE__{kind: :dm, members: members}, handle) do
    Enum.find(members, &(&1 != handle)) || handle
  end
end
