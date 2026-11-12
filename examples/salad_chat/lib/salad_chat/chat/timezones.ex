defmodule SaladChat.Chat.Timezones do
  @moduledoc """
  A handful of fixed-offset timezones. The demo has no tz database, so each
  zone is a label and an offset in minutes (no daylight saving).
  """

  @zones [
    {"pacific", "Pacific Time (UTC−08:00)", -480},
    {"eastern", "Eastern Time (UTC−05:00)", -300},
    {"london", "London (UTC+00:00)", 0},
    {"berlin", "Berlin (UTC+01:00)", 60},
    {"kolkata", "Kolkata (UTC+05:30)", 330},
    {"tokyo", "Tokyo (UTC+09:00)", 540}
  ]

  def all, do: @zones
  def keys, do: Enum.map(@zones, &elem(&1, 0))
  def options, do: Enum.map(@zones, fn {key, label, _} -> {label, key} end)

  def offset(key) do
    case List.keyfind(@zones, key, 0) do
      {_, _, offset} -> offset
      nil -> 0
    end
  end

  def label(key) do
    case List.keyfind(@zones, key, 0) do
      {_, label, _} -> label
      nil -> key
    end
  end

  @doc "Shifts a UTC datetime into the zone (as a NaiveDateTime for display)."
  def local(%DateTime{} = dt, key) do
    dt |> DateTime.add(offset(key) * 60, :second) |> DateTime.to_naive()
  end
end
