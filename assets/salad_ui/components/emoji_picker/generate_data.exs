# Builds data.json, the emoji picker's dataset, from Unicode's emoji-test.txt
# (https://unicode.org/Public/emoji/latest/emoji-test.txt; Unicode License V3,
# see DATA_LICENSE.txt). Run it again when Unicode adds emoji (Elixir 1.18+,
# for the built-in JSON module):
#
#     elixir assets/salad_ui/components/emoji_picker/generate_data.exs path/to/emoji-test.txt [max_version]
#
# Then update DATA_LICENSE.txt's Unicode version and run
# test/salad_ui/emoji_data_test.exs.
#
# Output: {"unicode", "max_version", "groups": [{"key", "name", "icon", "emoji": [entry]}]}
# where an entry is [emoji, name] or [emoji, name, 1] when it takes a skin
# tone. A skin tone is the modifier (U+1F3FB..U+1F3FF) put after the first
# code point, replacing a U+FE0F there; an emoji is marked only when that rule
# gives exactly Unicode's sequence for all five tones (so couples and families
# with two tones are left without).
#
# Only fully-qualified emoji are kept, in Unicode's (CLDR) order, without the
# "Component" group (bare skin tones and hair) and without the skin tone
# variants themselves. Emoji newer than max_version (default 15.1, which
# current Windows, Android, iOS and macOS all draw) are left out.

[path | rest] = System.argv()
max_version = rest |> List.first("15.1") |> String.to_float()

groups = [
  {"Smileys & Emotion", "smileys", "Smileys and emotion", "😀"},
  {"People & Body", "people", "People and body", "👋"},
  {"Animals & Nature", "nature", "Animals and nature", "🌿"},
  {"Food & Drink", "food", "Food and drink", "🍔"},
  {"Travel & Places", "travel", "Travel and places", "🚗"},
  {"Activities", "activities", "Activities", "⚽"},
  {"Objects", "objects", "Objects", "💡"},
  {"Symbols", "symbols", "Symbols", "🔣"},
  {"Flags", "flags", "Flags", "🏁"}
]

tones = %{
  "light skin tone" => 0x1F3FB,
  "medium-light skin tone" => 0x1F3FC,
  "medium skin tone" => 0x1F3FD,
  "medium-dark skin tone" => 0x1F3FE,
  "dark skin tone" => 0x1F3FF
}

lines = File.read!(path) |> String.split("\n")
unicode = Enum.find_value(lines, &(Regex.run(~r/^# Version: (\S+)/, &1, capture: :all_but_first))) |> hd()

line_re = ~r/^([0-9A-F ]+?)\s*;\s*fully-qualified\s*#\s*\S+\s+E(\d+\.\d+)\s+(.+)$/

{entries, _group} =
  Enum.flat_map_reduce(lines, nil, fn line, group ->
    cond do
      match = Regex.run(~r/^# group: (.+)$/, line, capture: :all_but_first) ->
        {[], hd(match)}

      match = Regex.run(line_re, line, capture: :all_but_first) ->
        [hex, version, name] = match
        cps = hex |> String.split() |> Enum.map(&String.to_integer(&1, 16))
        {[%{group: group, cps: cps, version: String.to_float(version), name: name}], group}

      true ->
        {[], group}
    end
  end)

# "waving hand: medium skin tone" -> {"waving hand", "medium skin tone"};
# names with no tone, or with two, -> nil.
split_tone = fn name ->
  case String.split(name, ": ", parts: 2) do
    [base, rest] ->
      items = String.split(rest, ", ")
      {tone_items, others} = Enum.split_with(items, &Map.has_key?(tones, &1))

      case tone_items do
        [tone] -> {if(others == [], do: base, else: base <> ": " <> Enum.join(others, ", ")), tone}
        _ -> if Enum.any?(items, &String.ends_with?(&1, "skin tone")), do: :multi, else: nil
      end

    _ ->
      nil
  end
end

apply_tone = fn [first | rest], mod ->
  rest = with [0xFE0F | after_vs] <- rest, do: after_vs
  [first, mod | rest]
end

{variants, plain} =
  Enum.split_with(entries, fn e -> split_tone.(e.name) not in [nil] end)

variants_by_base =
  variants
  |> Enum.flat_map(fn e ->
    case split_tone.(e.name) do
      {base, tone} -> [{base, {tone, e.cps}}]
      _ -> []
    end
  end)
  |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

toned? = fn e ->
  case Map.get(variants_by_base, e.name) do
    nil ->
      false

    list ->
      found = Map.new(list)

      map_size(found) == 5 and
        Enum.all?(tones, fn {tone, mod} -> Map.get(found, tone) == apply_tone.(e.cps, mod) end)
  end
end

by_group = Enum.group_by(plain, & &1.group)

out_groups =
  for {source, key, label, icon} <- groups do
    emoji =
      by_group
      |> Map.get(source, [])
      |> Enum.filter(&(&1.version <= max_version))
      |> Enum.map(fn e ->
        base = [List.to_string(e.cps), e.name]
        if toned?.(e), do: base ++ [1], else: base
      end)

    %{key: key, name: label, icon: icon, emoji: emoji}
  end

data = %{unicode: unicode, max_version: Float.to_string(max_version), groups: out_groups}
out = Path.join(__DIR__, "data.json")
File.write!(out, JSON.encode!(data) <> "\n")

count = out_groups |> Enum.map(&length(&1.emoji)) |> Enum.sum()
toned = out_groups |> Enum.flat_map(& &1.emoji) |> Enum.count(&(length(&1) == 3))
IO.puts("Wrote #{out}: #{count} emoji, #{toned} with skin tones (Unicode #{unicode}, up to E#{max_version})")
