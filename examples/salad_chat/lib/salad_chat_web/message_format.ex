defmodule SaladChatWeb.MessageFormat do
  @moduledoc """
  A deliberately small markdown subset for message bodies:

    * fenced code blocks (```` ```elixir ````), rendered with `SaladUI.CodeBlock`
    * `inline code`, **bold**, *italic*
    * `- ` bullet lists
    * @mentions and links

  Text is HTML-escaped before any markup is added.
  """

  @fence ~r/```([\w+#-]*)[ \t]*\n?(.*?)\n?```/s

  @doc "Splits a body into `{:text, string}` and `{:code, language, code}` segments."
  def segments(body) when is_binary(body) do
    @fence
    |> Regex.split(body, include_captures: true, trim: true)
    |> Enum.map(fn part ->
      case Regex.run(@fence, part) do
        [^part, lang, code] -> {:code, normalize_lang(lang), code}
        _ -> {:text, String.trim(part, "\n")}
      end
    end)
    |> Enum.reject(&(&1 == {:text, ""}))
  end

  defp normalize_lang(""), do: nil
  defp normalize_lang("js"), do: "javascript"
  defp normalize_lang(lang), do: String.downcase(lang)

  @doc """
  Renders a text segment to safe HTML. `known` is the set of valid handles
  (plus `here`/`channel`), `me` the viewer's handle, for mention styling.
  """
  def to_html(text, known, me) do
    text
    |> String.split("\n")
    |> Enum.chunk_by(&list_item?/1)
    |> Enum.map(fn lines ->
      if list_item?(hd(lines)) do
        items =
          Enum.map(
            lines,
            &["<li>", inline(String.replace(&1, ~r/^\s*[-•]\s+/, ""), known, me), "</li>"]
          )

        ["<ul class=\"my-1 ml-5 list-disc space-y-0.5\">", items, "</ul>"]
      else
        [
          "<p class=\"whitespace-pre-wrap break-words\">",
          Enum.map_intersperse(lines, "\n", &inline(&1, known, me)),
          "</p>"
        ]
      end
    end)
    |> then(&{:safe, &1})
  end

  defp list_item?(line), do: Regex.match?(~r/^\s*[-•]\s+/, line)

  defp inline(line, known, me) do
    line
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
    |> code_spans()
    |> String.replace(~r/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
    |> String.replace(~r/(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])/, "<em>\\1</em>")
    |> String.replace(
      ~r{(https?://[^\s<]+[^\s<.,;:!?)])},
      ~s(<a href="\\1" target="_blank" rel="noopener" class="text-primary underline underline-offset-2">\\1</a>)
    )
    |> mentions(known, me)
  end

  # Inline code first, so its contents are not formatted further.
  defp code_spans(line) do
    Regex.replace(~r/`([^`]+)`/, line, fn _, code ->
      ~s(<code class="rounded bg-muted px-1 py-0.5 font-mono text-[0.85em]">) <>
        String.replace(code, ["*", "@"], fn c -> "&##{:binary.first(c)};" end) <> "</code>"
    end)
  end

  defp mentions(line, known, me) do
    Regex.replace(~r/(?<![\w@&#])@([a-z][a-z0-9_]*)/, line, fn whole, handle ->
      cond do
        handle in [me, "here", "channel"] -> ~s(<span class="mention mention-me">#{whole}</span>)
        MapSet.member?(known, handle) -> ~s(<span class="mention">#{whole}</span>)
        true -> whole
      end
    end)
  end
end
