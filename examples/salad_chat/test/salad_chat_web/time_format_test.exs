defmodule SaladChatWeb.TimeFormatTest do
  use ExUnit.Case, async: true

  alias SaladChatWeb.TimeFormat

  @tz "Etc/UTC"

  defp at(days, hour) do
    Date.utc_today()
    |> Date.add(days)
    |> DateTime.new!(Time.new!(hour, 0, 0), @tz)
  end

  test "day_label names today, yesterday and tomorrow" do
    assert TimeFormat.day_label(Date.utc_today(), @tz) == "Today"
    assert TimeFormat.day_label(Date.add(Date.utc_today(), -1), @tz) == "Yesterday"
    assert TimeFormat.day_label(Date.add(Date.utc_today(), 1), @tz) == "Tomorrow"
  end

  test "phrase reads naturally mid-sentence" do
    assert TimeFormat.phrase(at(1, 9), @tz) == "tomorrow at 9:00 AM"

    later = at(3, 14)
    assert TimeFormat.phrase(later, @tz) =~ ~r/^on [A-Z][a-z]+day, [A-Z][a-z]+ \d+ at 2:00 PM$/
  end
end
