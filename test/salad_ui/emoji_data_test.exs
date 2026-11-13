defmodule SaladUI.EmojiDataTest do
  @moduledoc """
  The emoji picker's dataset (`assets/salad_ui/components/emoji_picker/data.json`):
  every emoji it offers, with every skin tone it can apply, is one grapheme,
  so a reaction or a cursor treats it as a single character.
  """
  use ExUnit.Case, async: true

  @dir Path.expand("../../assets/salad_ui/components/emoji_picker", __DIR__)
  @tones [0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF]

  # The picker's rule (withTone in emoji_picker.js): the tone goes after the
  # first code point, in place of a U+FE0F there.
  defp with_tone(emoji, tone) do
    [first | rest] = String.to_charlist(emoji)

    rest =
      case rest do
        [0xFE0F | tail] -> tail
        tail -> tail
      end

    List.to_string([first, tone | rest])
  end

  setup_all do
    %{"groups" => groups} = @dir |> Path.join("data.json") |> File.read!() |> Jason.decode!()
    %{entries: Enum.flat_map(groups, & &1["emoji"]), groups: groups}
  end

  test "has every category, named, with an icon, and a lot of emoji", %{groups: groups, entries: entries} do
    assert Enum.map(groups, & &1["key"]) ==
             ~w(smileys people nature food travel activities objects symbols flags)

    assert Enum.all?(groups, &(&1["name"] != "" and String.length(&1["icon"]) == 1))
    assert length(entries) > 1500
    assert Enum.all?(entries, fn [e, name | _] -> e != "" and name != "" end)
  end

  test "every emoji is one grapheme", %{entries: entries} do
    assert for([emoji | _] <- entries, String.length(emoji) != 1, do: emoji) == []
  end

  test "no emoji appears twice", %{entries: entries} do
    emoji = Enum.map(entries, &hd/1)
    assert emoji -- Enum.uniq(emoji) == []
  end

  test "every skin tone the picker can apply is one grapheme too", %{entries: entries} do
    toned = for [emoji, _name, 1] <- entries, do: emoji
    assert length(toned) > 200

    long =
      for emoji <- toned,
          tone <- @tones,
          toned = with_tone(emoji, tone),
          String.length(toned) != 1,
          do: toned

    assert long == []
  end

  test "the Unicode license ships next to the data" do
    license = @dir |> Path.join("DATA_LICENSE.txt") |> File.read!()
    assert license =~ "UNICODE LICENSE V3"
  end
end
