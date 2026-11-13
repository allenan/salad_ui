defmodule SaladChatWeb.TimeFormat do
  @moduledoc "Formats message timestamps in the viewer's timezone."

  alias SaladChat.Chat.Timezones

  @months ~w(January February March April May June July August September October November December)
  @days ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)

  @doc "\"9:41 AM\""
  def time(%DateTime{} = dt, tz) do
    local = Timezones.local(dt, tz)
    hour = rem(local.hour + 11, 12) + 1
    suffix = if local.hour < 12, do: "AM", else: "PM"
    "#{hour}:#{pad(local.minute)} #{suffix}"
  end

  @doc "The local calendar date of `dt`."
  def date(%DateTime{} = dt, tz), do: dt |> Timezones.local(tz) |> NaiveDateTime.to_date()

  @doc "\"Today\", \"Yesterday\", \"Tomorrow\" or \"Monday, November 3\"."
  def day_label(%Date{} = date, tz) do
    today = date(DateTime.utc_now(), tz)

    case Date.diff(today, date) do
      0 ->
        "Today"

      1 ->
        "Yesterday"

      -1 ->
        "Tomorrow"

      _ ->
        "#{Enum.at(@days, Date.day_of_week(date) - 1)}, #{Enum.at(@months, date.month - 1)} #{date.day}"
    end
  end

  @doc "\"Today at 9:41 AM\", for tooltips."
  def full(%DateTime{} = dt, tz), do: "#{day_label(date(dt, tz), tz)} at #{time(dt, tz)}"

  @doc "For mid-sentence use: \"tomorrow at 9:00 AM\", \"on Saturday, November 14 at 9:00 AM\"."
  def phrase(%DateTime{} = dt, tz) do
    label = day_label(date(dt, tz), tz)

    day =
      if label in ~w(Today Yesterday Tomorrow), do: String.downcase(label), else: "on #{label}"

    "#{day} at #{time(dt, tz)}"
  end

  @doc "\"just now\", \"5 min ago\", \"3 hours ago\", \"2 days ago\"."
  def relative(nil), do: ""

  def relative(%DateTime{} = dt) do
    seconds = DateTime.diff(DateTime.utc_now(), dt)

    cond do
      seconds < 60 -> "just now"
      seconds < 3600 -> "#{div(seconds, 60)} min ago"
      seconds < 7200 -> "1 hour ago"
      seconds < 86_400 -> "#{div(seconds, 3600)} hours ago"
      seconds < 172_800 -> "yesterday"
      true -> "#{div(seconds, 86_400)} days ago"
    end
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"
end
