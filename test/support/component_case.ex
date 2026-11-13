defmodule ComponentCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.Component
      import Phoenix.LiveViewTest
      import Plug.HTML, only: [html_escape: 1]

      defp count_substring(string, substring) do
        string
        |> String.split(substring)
        |> Enum.count()
        |> Kernel.-(1)
      end

      # Returns `{tag, [attribute]}` for every rendered start tag that carries an
      # attribute more than once (the browser keeps only the first copy).
      def duplicate_attrs(html) do
        for [tag] <- Regex.scan(~r/<[a-zA-Z][^>]*>/, html),
            names =
              for(
                [name] <- Regex.scan(~r/\s([^\s=\/>]+)/, Regex.replace(~r/"[^"]*"/, tag, ~s("")), capture: :all_but_first),
                do: name
              ),
            duplicates = Enum.uniq(names -- Enum.uniq(names)),
            duplicates != [],
            do: {tag, duplicates}
      end

      def clean_string(str) do
        str
        |> String.replace("\n", "")
        |> String.replace("\r", "")
        |> String.replace("  ", "")
      end
    end
  end
end
