defmodule SaladUI.ClassMerge do
  @moduledoc """
  Tailwind v4-aware class merging, used by `classes/1` in every component.

  It works like shadcn's `cn()`: when two classes set the same thing, the later
  one wins, so a caller's `class` overrides a component's default:

      iex> SaladUI.ClassMerge.merge(["px-2 py-1 bg-primary", "p-3 bg-red-500"])
      "p-3 bg-red-500"

      iex> SaladUI.ClassMerge.merge("data-[orientation=vertical]:h-full data-[orientation=vertical]:h-auto")
      "data-[orientation=vertical]:h-auto"

  The merging itself is done by `TwMerge`, which only knows Tailwind v3 syntax.
  This module rewrites each class into a form `TwMerge` understands, merges, and
  returns the original classes that survive, in their original order:

    * the `(--var)` shorthand is read as `[var(--var)]` (and `(length:--var)` as
      `[length:var(--var)]`), for every utility: `w-(--x) w-full` gives `w-full`
    * variants are compared as plain strings, so arbitrary variants with `=`,
      `+` or `~`, named groups (`group-data-[size=sm]/card:`) and `*:` work
    * the v4 trailing important (`p-0!`) is the same as the v3 leading one
    * v4 renames join their v3 group: `outline-hidden` (outline style),
      `shadow-2xs` (shadow), `bg-linear-*`/`bg-radial`/`bg-conic` (background image)
    * v4-only utilities get their own groups: `text-shadow-*`, `inset-shadow-*`,
      `inset-ring-*` (each with a separate color group), `wrap-*`,
      `field-sizing-*`, `scheme-*`, `perspective-*`, `transform-3d`/`-flat`,
      `backface-*`, `rotate-x/y/z-*`, `translate-z-*` and `scale-z-*`

  Classes `TwMerge` can't handle are kept as they are. Results are cached in the
  `TwMerge.Cache` table, so `TwMerge.Cache` must be in your supervision tree,
  as before.
  """

  @doc """
  Joins `input` (a string, or a nested list of strings and `nil`s) and merges
  conflicting Tailwind classes, the later class winning.
  """
  @spec merge(term()) :: String.t()
  def merge(input) do
    classes = TwMerge.join(input)
    key = {__MODULE__, classes}

    case TwMerge.Cache.retrieve(key) do
      nil ->
        merged = do_merge(classes)
        TwMerge.Cache.insert(key, merged)
        merged

      merged ->
        merged
    end
  end

  defp do_merge(classes) do
    entries = classes |> String.split() |> Enum.map(&classify/1)

    entries
    |> resolve_v4_groups()
    |> resolve_tw_merge()
    |> Enum.flat_map(fn
      {:keep, raw} -> [raw]
      _ -> []
    end)
    |> Enum.join(" ")
  end

  # -- classification ----------------------------------------------------------

  # Each class becomes one of:
  #   {:raw, raw}                - not a utility we can merge; always kept
  #   {:v4, raw, conflict_id}    - a v4-only group, merged here
  #   {:tw, raw, normalised}     - merged by TwMerge using `normalised`
  defp classify(raw) do
    case split_variants(raw) do
      {_variants, ""} -> {:raw, raw}
      {variants, base} -> classify_utility(raw, variants, base)
    end
  end

  defp classify_utility(raw, variants, base) do
    {important, base} = split_important(base)
    {negative, base} = split_negative(base)
    {value, postfix} = split_postfix(base)
    value = expand_shorthand(value)

    case v4_group(value) do
      nil ->
        postfix = if postfix, do: "/" <> normalise_postfix(postfix), else: ""
        utility = sanitise(important <> negative <> v4_alias(value) <> postfix)
        {:tw, raw, Enum.map_join(variants, &(encode_variant(&1) <> ":")) <> utility}

      group ->
        {:v4, raw, modifier_id(variants) <> important <> ":" <> group}
    end
  end

  # Splits on top-level `:` (not inside `[]` or `()`); the last part is the base.
  defp split_variants(raw) do
    {parts, current, _depth} =
      raw
      |> String.graphemes()
      |> Enum.reduce({[], "", 0}, fn
        ":", {parts, current, 0} -> {[current | parts], "", 0}
        c, {parts, current, depth} when c in ["[", "("] -> {parts, current <> c, depth + 1}
        c, {parts, current, depth} when c in ["]", ")"] -> {parts, current <> c, max(depth - 1, 0)}
        c, {parts, current, depth} -> {parts, current <> c, depth}
      end)

    {Enum.reverse(parts), current}
  end

  defp split_important("!" <> base) when base != "", do: {"!", base}

  defp split_important(base) do
    if String.ends_with?(base, "!") and byte_size(base) > 1,
      do: {"!", binary_part(base, 0, byte_size(base) - 1)},
      else: {"", base}
  end

  defp split_negative("-" <> base) when base != "", do: {"-", base}
  defp split_negative(base), do: {"", base}

  # `bg-red-500/50` -> {"bg-red-500", "50"}; only a top-level `/` counts.
  defp split_postfix(base) do
    case top_level_split(base, "/") do
      [value] -> {value, nil}
      parts -> {parts |> Enum.drop(-1) |> Enum.join("/"), List.last(parts)}
    end
  end

  defp top_level_split(string, separator) do
    {parts, current, _depth} =
      string
      |> String.graphemes()
      |> Enum.reduce({[], "", 0}, fn
        ^separator, {parts, current, 0} -> {[current | parts], "", 0}
        c, {parts, current, depth} when c in ["[", "("] -> {parts, current <> c, depth + 1}
        c, {parts, current, depth} when c in ["]", ")"] -> {parts, current <> c, max(depth - 1, 0)}
        c, {parts, current, depth} -> {parts, current <> c, depth}
      end)

    Enum.reverse([current | parts])
  end

  # TwMerge ignores the postfix when grouping but only parses `[a-z0-9]+`, so
  # `/[0.5]` or `/(--alpha)` would make the whole class unmergeable.
  defp normalise_postfix(postfix) do
    if Regex.match?(~r/^[a-z0-9]+$/, postfix), do: postfix, else: "0"
  end

  # `w-(--x)` -> `w-[var(--x)]`, `text-(length:--x)` -> `text-[length:var(--x)]`.
  defp expand_shorthand(value) do
    case Regex.run(~r/^(.+?)-\((.+)\)$/, value) do
      [_, utility, inner] ->
        if balanced?(inner), do: utility <> "-" <> shorthand_value(inner), else: value

      nil ->
        value
    end
  end

  defp shorthand_value("--" <> _ = var), do: "[var(#{var})]"

  defp shorthand_value(inner) do
    case Regex.run(~r/^([a-z][a-z-]*):(--.+)$/, inner) do
      [_, label, var] -> "[#{label}:var(#{var})]"
      nil -> "(#{inner})"
    end
  end

  defp balanced?(string) do
    string
    |> String.graphemes()
    |> Enum.reduce_while(0, fn
      "(", depth -> {:cont, depth + 1}
      ")", 0 -> {:halt, -1}
      ")", depth -> {:cont, depth - 1}
      _, depth -> {:cont, depth}
    end)
    |> Kernel.==(0)
  end

  # Characters TwMerge's parser accepts in a class (inside `[]` it also takes
  # `:` and `/`). Anything else (`=`, `+`, `"`, non-ASCII) would make the class
  # unparseable, so it is replaced; the value doesn't decide the group.
  defp sanitise(utility), do: String.replace(utility, ~r/[^A-Za-z0-9\-_.,@{}()>*&'%#:\/\[\]!]/u, "_")

  # Variants only need to compare equal, so encode every character TwMerge
  # can't parse (`=`, `/`, `*`, `@`, ...) and `_` itself. Arbitrary variants
  # keep their brackets: TwMerge keeps those in place instead of sorting them.
  defp encode_variant("[" <> rest = variant) do
    if String.ends_with?(rest, "]"),
      do: "[" <> encode(String.slice(rest, 0..-2//1)) <> "]",
      else: encode(variant)
  end

  defp encode_variant(variant), do: encode(variant)

  defp encode(string) do
    string
    |> String.to_charlist()
    |> Enum.map_join(fn
      c when c in ?a..?z or c in ?A..?Z or c in ?0..?9 or c == ?- -> <<c::utf8>>
      c -> "_" <> Integer.to_string(c, 16) <> "_"
    end)
  end

  # Same order TwMerge uses: plain variants are sorted, arbitrary ones (`[...]`)
  # stay where they are.
  defp modifier_id(variants) do
    {sorted, pending} =
      Enum.reduce(variants, {[], []}, fn variant, {sorted, pending} ->
        if String.starts_with?(variant, "["),
          do: {sorted ++ Enum.sort(pending) ++ [variant], []},
          else: {sorted, pending ++ [variant]}
      end)

    Enum.join(sorted ++ Enum.sort(pending), ":")
  end

  # -- Tailwind v4 groups --------------------------------------------------------

  # v4 names for values TwMerge knows under their v3 name.
  defp v4_alias("outline-hidden"), do: "outline-none"
  defp v4_alias("bg-linear-to-" <> direction), do: "bg-gradient-to-" <> direction
  defp v4_alias("bg-" <> rest) when rest in ["linear", "radial", "conic"], do: "bg-none"

  defp v4_alias("bg-" <> rest) do
    if Regex.match?(~r/^(linear|radial|conic)-/, rest), do: "bg-none", else: "bg-" <> rest
  end

  defp v4_alias(value), do: Regex.replace(~r/-\d+xs$/, value, "-xs")

  @shadow_sizes ~w(2xs xs sm md lg xl 2xl none)

  defp v4_group("text-shadow"), do: "text-shadow"
  defp v4_group("text-shadow-" <> rest), do: shadow_or_color("text-shadow", rest)
  defp v4_group("inset-shadow"), do: "inset-shadow"
  defp v4_group("inset-shadow-" <> rest), do: shadow_or_color("inset-shadow", rest)
  defp v4_group("inset-ring"), do: "inset-ring-w"

  defp v4_group("inset-ring-" <> rest) do
    if Regex.match?(~r/^(\d+|\[length:.+\]|\[\d.*\])$/, rest), do: "inset-ring-w", else: "inset-ring-color"
  end

  defp v4_group("wrap-" <> value) when value in ~w(break-word anywhere normal), do: "wrap"
  defp v4_group("field-sizing-" <> value) when value in ~w(fixed content), do: "field-sizing"

  defp v4_group("scheme-" <> value) when value in ~w(normal dark light light-dark only-dark only-light), do: "scheme"

  defp v4_group("perspective-origin-" <> _), do: "perspective-origin"
  defp v4_group("perspective-" <> _), do: "perspective"
  defp v4_group("transform-" <> value) when value in ~w(3d flat), do: "transform-style"
  defp v4_group("backface-" <> value) when value in ~w(visible hidden), do: "backface"
  defp v4_group("rotate-" <> <<axis, "-", _::binary>>) when axis in ~c"xyz", do: "rotate-#{[axis]}"
  defp v4_group("translate-z-" <> _), do: "translate-z"
  defp v4_group("scale-z-" <> _), do: "scale-z"
  defp v4_group(_), do: nil

  defp shadow_or_color(group, "[color:" <> _), do: group <> "-color"
  defp shadow_or_color(group, "[" <> _), do: group
  defp shadow_or_color(group, size) when size in @shadow_sizes, do: group
  defp shadow_or_color(group, _color), do: group <> "-color"

  # Later classes win: walk backwards and drop any v4 class whose conflict id
  # was already taken.
  defp resolve_v4_groups(entries) do
    entries
    |> Enum.reverse()
    |> Enum.map_reduce(MapSet.new(), fn
      {:v4, raw, id}, seen ->
        if MapSet.member?(seen, id), do: {:drop, seen}, else: {{:keep, raw}, MapSet.put(seen, id)}

      entry, seen ->
        {entry, seen}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  # -- TwMerge -------------------------------------------------------------------

  defp resolve_tw_merge(entries) do
    case safe_tw_merge(entries) do
      {:ok, merged} ->
        apply_survivors(entries, String.split(merged))

      # TwMerge 0.1 crashes on some classes (e.g. `no-scrollbar`): keep those
      # as they are and merge the rest.
      :error ->
        entries = Enum.map(entries, &mark_unmergeable/1)

        case safe_tw_merge(entries) do
          {:ok, merged} -> apply_survivors(entries, String.split(merged))
          :error -> Enum.map(entries, &keep_all/1)
        end
    end
  end

  defp mark_unmergeable({:tw, raw, _class} = entry) do
    if match?({:ok, _}, safe_tw_merge([entry])), do: entry, else: {:raw, raw}
  end

  defp mark_unmergeable(entry), do: entry

  defp safe_tw_merge(entries) do
    case for({:tw, _raw, class} <- entries, do: class) do
      [] -> {:ok, ""}
      classes -> {:ok, TwMerge.merge(Enum.join(classes, " "))}
    end
  rescue
    _ -> :error
  end

  defp keep_all({:tw, raw, _class}), do: {:keep, raw}
  defp keep_all({:raw, raw}), do: {:keep, raw}
  defp keep_all(entry), do: entry

  # TwMerge returns the surviving (normalised) classes in order, keeping the
  # last of any conflicting ones. Match them from the end so each survivor maps
  # back to the right original class.
  defp apply_survivors(entries, survivors) do
    {kept, _unmatched} =
      entries
      |> Enum.reverse()
      |> Enum.map_reduce(Enum.reverse(survivors), fn
        {:tw, raw, class}, [class | rest] -> {{:keep, raw}, rest}
        {:tw, _raw, _class}, rest -> {:drop, rest}
        {:raw, raw}, rest -> {{:keep, raw}, rest}
        entry, rest -> {entry, rest}
      end)

    Enum.reverse(kept)
  end
end
