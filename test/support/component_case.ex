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

      # Asserts some `<tag ...>` opening tag carries every `{name, value}` in
      # `attrs`, in any order. Rendered attribute order is not stable (it
      # follows atom creation order), so never assert it with one regex.
      defp assert_tag(html, tag, attrs) do
        found =
          ~r/<#{tag}\b[^>]*>/
          |> Regex.scan(html)
          |> Enum.any?(fn [open] ->
            Enum.all?(attrs, fn {name, value} -> open =~ ~s( #{name}="#{value}") end)
          end)

        assert found, "no <#{tag}> with #{inspect(attrs)} in:\n#{html}"
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
