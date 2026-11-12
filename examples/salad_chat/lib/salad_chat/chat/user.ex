defmodule SaladChat.Chat.User do
  @moduledoc "A workspace member (or the Sprout bot)."

  @default_prefs %{
    theme: "system",
    font_size: 15,
    notify_desktop: true,
    notify_mentions: true,
    notify_sounds: false,
    email_digest: false
  }

  defstruct handle: nil,
            name: nil,
            title: nil,
            bio: "",
            avatar: nil,
            color: "bg-emerald-600",
            status: "active",
            status_text: nil,
            timezone: "london",
            bot?: false,
            prefs: @default_prefs

  @type t :: %__MODULE__{}

  def default_prefs, do: @default_prefs

  @doc "Up to two initials for an avatar fallback."
  def initials(%__MODULE__{name: name}) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end

  def first_name(%__MODULE__{name: name}), do: name |> String.split(" ") |> hd()
end
