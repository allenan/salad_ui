defmodule SaladStorybookWeb.CodeBlockStoriesTest do
  @moduledoc """
  Drives the code-block streaming and markdown LiveView examples: the server
  appends to the code and the copy button waits for a complete block.
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Storybook.Examples.CodeBlockMarkdown
  alias Storybook.Examples.CodeBlockStreaming

  defp path(suffix) do
    SaladStorybookWeb.Storybook.leaves()
    |> Enum.map(& &1.path)
    |> Enum.find(&String.ends_with?(&1, suffix))
  end

  # Storybook mounts an example as a child LiveView.
  defp mount_example(conn, suffix, selector) do
    {:ok, page, _html} = live(conn, path(suffix))
    page |> live_children() |> Enum.find(&has_element?(&1, selector))
  end

  describe "streaming" do
    test "starts complete, then replay appends one line per tick", %{conn: conn} do
      view = mount_example(conn, "code_block_streaming", "#code-block-streaming-replay")
      total = CodeBlockStreaming.total_lines()

      assert has_element?(view, "#streaming-4[data-complete]")
      refute has_element?(view, "#code-block-streaming-replay[disabled]")

      view |> element("#code-block-streaming-replay") |> render_click()
      refute has_element?(view, "[data-slot=code-block]")
      assert has_element?(view, "#code-block-streaming-replay[disabled]")

      send(view.pid, :tick)
      html = render(view)
      assert has_element?(view, "#streaming-0")
      assert has_element?(view, "#streaming-0-copy[disabled]")
      assert html =~ "data-numbered"
      refute has_element?(view, "#streaming-1")

      for _ <- 2..total, do: send(view.pid, :tick)
      render(view)

      refute has_element?(view, "#streaming-0-copy[disabled]")
      assert has_element?(view, "#streaming-4[data-complete]")
      assert has_element?(view, "#streaming-2 [data-variant=added]")
      assert has_element?(view, "#streaming-3 [data-variant=highlighted]")
      refute has_element?(view, "#code-block-streaming-replay[disabled]")
    end
  end

  describe "markdown" do
    test "fenced code renders to a code block inside a typeset reply", %{conn: conn} do
      view = mount_example(conn, "code_block_markdown", "#code-block-markdown-reply")

      assert has_element?(view, "#code-block-markdown-reply.typeset > p > code", "phx-debounce")
      assert has_element?(view, "#markdown-code-1 [data-slot=code-block-title]", "heex")
      refute has_element?(view, "#markdown-code-1-copy[disabled]")

      view |> element("#code-block-markdown-replay") |> render_click()
      refute has_element?(view, "#code-block-markdown-reply")
      refute has_element?(view, "#code-block-markdown-replay")

      chunks = length(String.split(CodeBlockMarkdown.response(), ~r/(?<=\s)/))
      for _ <- 1..chunks, do: send(view.pid, :chunk)
      render(view)

      assert has_element?(view, "#markdown-code-1")
      refute has_element?(view, "#markdown-code-1-copy[disabled]")
      assert has_element?(view, "#code-block-markdown-replay")
    end

    test "parse/1 marks an unclosed fence incomplete and keeps inline code inline" do
      assert [
               {:paragraph, ["Use ", {:code, "x"}, " here."]},
               {:code, "elixir", "IO.puts(1)\nIO.puts(2)", false}
             ] = CodeBlockMarkdown.parse("Use `x` here.\n\n```elixir\nIO.puts(1)\nIO.puts(2)")

      assert [{:paragraph, ["a b"]}, {:code, nil, "x", true}, {:paragraph, ["c"]}] =
               CodeBlockMarkdown.parse("a\nb\n```\nx\n```\nc")
    end
  end
end
