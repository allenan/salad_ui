defmodule SaladUI.CodeBlockTest do
  use ComponentCase

  import SaladUI.CodeBlock

  alias Makeup.Lexers.ElixirLexer

  setup_all do
    # makeup_elixir is a dev/test dependency (via ex_doc) that registers its
    # lexer when its application starts.
    {:ok, _} = Application.ensure_all_started(:makeup_elixir)
    :ok
  end

  defp lines(html) do
    ~r/<span[^>]*data-slot="code-block-line"[^>]*>/
    |> Regex.scan(html)
    |> List.flatten()
  end

  defp text_of(html), do: String.replace(html, ~r/<[^>]+>/, "")

  describe "code_block/1" do
    test "renders slots, variant and size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block variant="destructive" size="sm" class="my-4">
          <.code_block_header>
            <.code_block_title>Terminal</.code_block_title>
            <.code_block_actions>
              <.code_block_copy_button id="copy" value="ls" />
            </.code_block_actions>
          </.code_block_header>
          <.code_block_content code="ls" />
          <.code_block_footer>footer</.code_block_footer>
        </.code_block>
        """)

      for slot <-
            ~w(code-block code-block-header code-block-title code-block-actions code-block-copy-button code-block-copy-status code-block-content code-block-code code-block-footer) do
        assert html =~ ~s(data-slot="#{slot}")
      end

      assert html =~ ~s(data-variant="destructive")
      assert html =~ ~s(data-size="sm")
      assert html =~ "border-destructive/30"
      assert html =~ "my-4"
      assert html =~ "group/code-block"
    end

    test "default variant has an input border" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block><.code_block_content code="x" /></.code_block>
        """)

      assert html =~ ~s(data-variant="default")
      assert html =~ "border-input"
    end
  end

  describe "code_block_content/1" do
    test "a plain string renders as one text node, ltr and focusable" do
      assigns = %{code: "$ mix test\n<ok>"}

      html =
        rendered_to_string(~H"""
        <.code_block_content code={@code} />
        """)

      assert html =~ ~s(dir="ltr")
      assert html =~ ~s(tabindex="0")
      assert html =~ "counter-reset: line 0;"
      assert html =~ ~s(class="grid min-h-lh min-w-max content-start) <> " " <> "in-data-numbered:grid-cols-[auto_1fr]"
      assert html =~ ">$ mix test\n&lt;ok&gt;</code></pre>"
      assert lines(html) == []
      refute html =~ ~r/\sdata-wrap[\s>=]/
      refute html =~ ~r/\sdata-numbered[\s>=]/
    end

    test "wrap, tabindex and class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block_content code="x" wrap tabindex={-1} class="max-h-64" />
        """)

      assert html =~ ~r/\sdata-wrap[\s>=]/
      assert html =~ ~s(tabindex="-1")
      assert html =~ "max-h-64"
    end

    test "fades the inline edges, the block edges when wrapped, and keeps an added scroll-fade-y" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block_content code="x" class="max-h-64 scroll-fade-y overflow-y-hidden" />
        """)

      [class] = Regex.run(~r/<pre[^>]*class="([^"]*)"/, html, capture: :all_but_first)
      classes = String.split(class)

      for c <- ~w(scroll-fade-x data-wrap:scroll-fade-y scroll-fade-y max-h-64 overflow-y-hidden),
          do: assert(c in classes)
    end

    test "a not-typeset class opts a block out of typeset without crashing the class merge" do
      assigns = %{}
      html = rendered_to_string(~H|<.code_block class="not-typeset"><.code_block_content code="x" /></.code_block>|)
      assert html =~ "not-typeset"
    end

    test "line numbers split the string and start at start_line" do
      assigns = %{code: "a\n\nb\n"}

      html =
        rendered_to_string(~H"""
        <.code_block_content code={@code} line_numbers start_line={41} />
        """)

      assert html =~ ~r/\sdata-numbered[\s>=]/
      assert html =~ "counter-reset: line 40;"
      assert length(lines(html)) == 3
      # the blank line holds a newline so copying keeps it
      assert html =~ ~s(<span data-slot="code-block-line-content" class="min-w-0">\n</span>)
    end

    test "highlight marks lines by displayed number" do
      assigns = %{code: "a\nb\nc"}

      html =
        rendered_to_string(~H"""
        <.code_block_content code={@code} line_numbers start_line={10} highlight={[11]} />
        """)

      assert [~s(data-variant="default"), ~s(data-variant="highlighted"), ~s(data-variant="default")] ==
               Enum.map(lines(html), &(~r/data-variant="[^"]+"/ |> Regex.run(&1) |> hd()))

      assert html =~ "bg-muted"
    end

    test "diff mode maps +/- to added/removed and drops the marker column" do
      assigns = %{patch: " keep\n-old\n+new"}

      html =
        rendered_to_string(~H"""
        <.code_block_content code={@patch} diff />
        """)

      assert [~s(data-variant="default"), ~s(data-variant="removed"), ~s(data-variant="added")] ==
               Enum.map(lines(html), &(~r/data-variant="[^"]+"/ |> Regex.run(&1) |> hd()))

      assert html =~ ">keep</span>"
      assert html =~ ">old</span>"
      assert html =~ ">new</span>"
      assert html =~ "after:content-[&#39;+&#39;]"
      assert html =~ "after:content-[&#39;−&#39;]"
    end

    test "diff mode keeps hunk headers and no-newline notes whole" do
      assigns = %{patch: "@@ -1,2 +1,2 @@\n-old\n+new\n\\ No newline at end of file"}

      html =
        rendered_to_string(~H"""
        <.code_block_content code={@patch} diff />
        """)

      assert [
               ~s(data-variant="default"),
               ~s(data-variant="removed"),
               ~s(data-variant="added"),
               ~s(data-variant="default")
             ] ==
               Enum.map(lines(html), &(~r/data-variant="[^"]+"/ |> Regex.run(&1) |> hd()))

      assert html =~ ">@@ -1,2 +1,2 @@</span>"
      assert html =~ ">\\ No newline at end of file</span>"
    end

    test "language highlights with Makeup" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block_content code="def hello, do: :world" language="elixir" />
        """)

      assert html =~ ~s(<span class="text-[#d73a49] dark:text-[#f97583]">def</span>)
      assert html =~ ~s(<span class="text-[#005cc5] dark:text-[#79b8ff]">:world</span>)
      assert text_of(html) =~ "def hello, do: :world"
    end

    test "an unknown language renders plain, escaped text" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block_content code="<b>hi</b>" language="no-such-language" />
        """)

      assert html =~ "&lt;b&gt;hi&lt;/b&gt;"
      refute html =~ "<span class="
    end

    test "ansi renders terminal colors and hides escape codes" do
      assigns = %{output: "\e[32m✓\e[39m ok \e[2m(4 tests)\e[22m"}

      html =
        rendered_to_string(~H"""
        <.code_block_content code={@output} language="ansi" />
        """)

      assert html =~ ~s(<span class="text-green-600 dark:text-green-400">✓</span>)
      assert html =~ ~s{<span class="opacity-60">(4 tests)</span>}
      refute html =~ "\e"
    end

    test "renders code_block_line children" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block_content line_numbers>
          <.code_block_line>one</.code_block_line>
          <.code_block_line variant="added">two</.code_block_line>
          <.code_block_line />
        </.code_block_content>
        """)

      assert length(lines(html)) == 3
      assert html =~ ~s(data-variant="added")
      assert html =~ ~s(<span data-slot="code-block-line-content" class="min-w-0">\n</span>)
    end
  end

  describe "code_block_copy_button/1" do
    test "renders a hooked ghost icon button with a live region" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block_copy_button id="copy-install" value="mix deps.get" on-copy="copied" />
        """)

      assert html =~ ~s(id="copy-install")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-component="code-block-copy-button")
      assert html =~ ~s(data-state="idle")
      assert html =~ ~s(aria-label="Copy")
      assert html =~ ~s(type="button")
      assert html =~ "size-6"
      assert html =~ "hover:bg-accent"
      assert html =~ "{&quot;value&quot;:&quot;mix deps.get&quot;}"
      assert html =~ "{&quot;copy&quot;:&quot;copied&quot;}"
      assert html =~ ~s(aria-live="polite")
      # the live region keeps its "Copied" text across LiveView patches
      assert html =~ ~r/<span[^>]*id="copy-install-status"[^>]*phx-update="ignore"/
      assert html =~ ~s(data-icon="copy")
      assert html =~ ~s(data-icon="check")
    end

    test "value defaults to nil so the content is copied" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.code_block_copy_button id="copy" />
        """)

      assert html =~ "{&quot;value&quot;:null}"
    end
  end

  describe "highlight/2" do
    test "returns one safe value per line and ignores a trailing newline" do
      assert [{:safe, _}, {:safe, "\n"}, {:safe, _}] = highlight("a\n\nb\n", nil)
    end

    test "accepts a lexer module" do
      [line] = highlight(":ok", ElixirLexer)
      assert Phoenix.HTML.safe_to_string(line) =~ "text-[#005cc5]"
    end

    test "handles one-character tokens, which Makeup emits as a bare codepoint" do
      [line] = highlight("%{x: 1}", ElixirLexer)
      assert Phoenix.HTML.safe_to_string(line) =~ ">x<"
    end

    test "ansi colors do not carry across lines" do
      [first, second] = highlight("\e[31mred\nplain", "ansi")
      assert Phoenix.HTML.safe_to_string(first) =~ "text-red-600"
      assert Phoenix.HTML.safe_to_string(second) == "plain"
    end

    test "ansi 256-color and true-color arguments are not read as other codes" do
      # 31 here is a palette index, not "red"; 0s are color components, not resets
      [line] = highlight("\e[1m\e[38;5;31mA\e[38;2;0;32;0mB\e[38;5;2mC\e[48;5;9mD", "ansi")
      html = Phoenix.HTML.safe_to_string(line)

      assert html =~ ~s(<span class="font-bold">A</span>)
      assert html =~ ~s(<span class="font-bold">B</span>)
      assert html =~ ~s(<span class="text-green-600 dark:text-green-400 font-bold">C</span>)
      assert html =~ ~s(<span class="text-green-600 dark:text-green-400 bg-red-500/15 font-bold">D</span>)
    end

    test "ansi reset and bold" do
      [line] = highlight("\e[1;34mA\e[0mB\e[mC", "ansi")
      html = Phoenix.HTML.safe_to_string(line)
      assert html =~ ~s(<span class="text-blue-600 dark:text-blue-400 font-bold">A</span>BC)
    end
  end

  test "strip_ansi/1" do
    assert strip_ansi("\e[32m✓\e[39m ok\e[2K") == "✓ ok"
  end
end
