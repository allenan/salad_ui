defmodule SaladUI.CodeBlock do
  @moduledoc """
  Displays code, terminal output, logs and diffs with an optional header,
  line numbers, line variants and a copy button.

  Parts: `code_block/1`, `code_block_header/1`, `code_block_title/1`,
  `code_block_actions/1`, `code_block_copy_button/1`, `code_block_content/1`,
  `code_block_line/1`, `code_block_footer/1`.

  ## Composition

      code_block
      ├── code_block_header
      │   ├── code_block_title
      │   └── code_block_actions
      │       └── code_block_copy_button
      ├── code_block_actions (floating, when there is no header)
      ├── code_block_content
      │   └── code_block_line
      └── code_block_footer

  `code_block_content/1` takes its code either as the `code` attribute (a
  string, rendered as one text node or split into lines when line numbers,
  highlighting or diff mode need it) or as a list of `code_block_line/1` in its
  inner block. Prefer the `code` attribute for strings: whitespace inside a
  `<pre>` is significant, so indentation in a template would show up.

  ## Examples

      <.code_block>
        <.code_block_header>
          <.code_block_title>Terminal</.code_block_title>
          <.code_block_actions>
            <.code_block_copy_button id="install-copy" value={@output} />
          </.code_block_actions>
        </.code_block_header>
        <.code_block_content code={@output} />
      </.code_block>

      <%!-- Line numbers from line 42, lines 43-44 highlighted --%>
      <.code_block_content code={@code} line_numbers start_line={42} highlight={[43, 44]} />

      <%!-- A unified diff: "+" lines are added, "-" lines removed --%>
      <.code_block_content code={@patch} diff />

      <%!-- Terminal output with ANSI colors --%>
      <.code_block_content code={@output} language="ansi" wrap />

  ## Syntax highlighting

  Highlighting runs on the server with [Makeup](https://hex.pm/packages/makeup),
  an optional dependency. Add `makeup` and the lexers you need to your app:

      {:makeup, "~> 1.0"},
      {:makeup_elixir, "~> 1.0"},
      {:makeup_erlang, "~> 1.0"},
      {:makeup_html, "~> 0.2"}

  then pass `language` to `code_block_content/1`:

      <.code_block_content code={@code} language="elixir" line_numbers />

  A language without a registered lexer, or an app without Makeup, renders as
  plain text. The `"ansi"` language is built in and renders the SGR colors and
  styles of terminal output (colors do not carry from one line to the next).

  To render the lines yourself, use `highlight/2`. Keep `{line}` on the same
  line as its tags: whitespace inside a line is part of the code.

      <.code_block_content line_numbers>
        <.code_block_line
          :for={{line, i} <- Enum.with_index(SaladUI.CodeBlock.highlight(@code, "elixir"))}
          variant={if i in 5..9, do: "highlighted", else: "default"}
        >{line}</.code_block_line>
      </.code_block_content>

  Token colors follow GitHub's light and dark themes and switch with the
  `dark` variant.

  ## Accessibility

  - `code_block_content/1` is a `pre` with a `code` element, always `dir="ltr"`,
    and focusable (`tabindex="0"`) so keyboard users can scroll it.
  - Floating actions show when focus is inside the block, not only on hover.
  - Line numbers and diff markers are CSS-generated, so they are neither read
    by screen readers nor copied with a selection.
  - `code_block_copy_button/1` is labelled "Copy" and a polite live region
    announces "Copied" after a successful copy.
  """
  use SaladUI, :component

  alias Phoenix.HTML.Engine

  @compile {:no_warn_undefined, [Makeup.Registry]}

  @doc """
  Renders the surface that holds the header, the content and the footer.

  ## Attributes

  * `:variant` - `"default"` or `"destructive"` (for errors and failed output).
  * `:size` - `"default"` or `"sm"` (tighter padding and `text-xs` code, for tool output).
  * `:class` - Additional CSS classes.

  ## Examples

      <.code_block size="sm" variant="destructive">
        <.code_block_content code={@error} wrap class="max-h-64" />
      </.code_block>
  """
  attr :variant, :string, values: ~w(default destructive), default: "default"
  attr :size, :string, values: ~w(default sm), default: "default"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def code_block(assigns) do
    ~H"""
    <div
      data-slot="code-block"
      data-variant={@variant}
      data-size={@size}
      class={
        classes([
          "group/code-block relative flex w-full min-w-0 flex-col overflow-hidden rounded-lg text-sm data-[size=sm]:text-xs has-[>[data-slot=code-block-content]:focus-visible]:ring-3 has-[>[data-slot=code-block-content]:focus-visible]:ring-ring/50",
          code_block_variant(@variant),
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp code_block_variant("destructive"), do: "border border-destructive/30 text-destructive dark:border-destructive/40"

  defp code_block_variant(_),
    do:
      "border border-input text-foreground dark:bg-input/30 has-[>[data-slot=code-block-content]:focus-visible]:border-ring"

  @doc """
  Renders a row above the content for a `code_block_title/1` and
  `code_block_actions/1`.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def code_block_header(assigns) do
    ~H"""
    <div
      data-slot="code-block-header"
      class={
        classes([
          "flex min-w-0 shrink-0 items-center gap-2 px-4 pt-4 text-muted-foreground group-data-[size=sm]/code-block:px-3 group-data-[size=sm]/code-block:pt-3 group-data-[variant=destructive]/code-block:text-destructive *:has-[>[data-slot=code-block-title]]:min-w-0",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a filename or a label, with an optional leading icon. A long title
  truncates. To link it to a file, wrap it in an anchor.

  ## Examples

      <.code_block_title>
        <Lucideicons.terminal /> Terminal
      </.code_block_title>

      <a href="/files/router.ex">
        <.code_block_title>lib/my_app_web/router.ex</.code_block_title>
      </a>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def code_block_title(assigns) do
    ~H"""
    <div
      data-slot="code-block-title"
      class={
        classes([
          "min-w-0 truncate font-sans text-sm font-medium text-foreground group-data-[size=sm]/code-block:text-xs group-data-[variant=destructive]/code-block:text-destructive [&_svg]:pointer-events-none [&_svg]:inline-block [&_svg]:align-middle *:[svg]:me-1.5 [&_svg:not([class*='size-'])]:size-4 group-data-[size=sm]/code-block:[&_svg:not([class*='size-'])]:size-3.5",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Holds buttons at the end of the header. As a direct child of `code_block/1`
  (when there is no header) the actions float at the top end and show when the
  block is hovered or focused, and always on touch screens.

  ## Examples

      <.code_block>
        <.code_block_actions>
          <.code_block_copy_button id="output-copy" value={@output} />
        </.code_block_actions>
        <.code_block_content code={@output} />
      </.code_block>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def code_block_actions(assigns) do
    ~H"""
    <div
      data-slot="code-block-actions"
      class={
        classes([
          "ms-auto -my-1 -me-1.5 flex shrink-0 items-center gap-1",
          "[[data-slot=code-block]>&]:absolute [[data-slot=code-block]>&]:end-3 [[data-slot=code-block]>&]:top-3 [[data-slot=code-block]>&]:z-10 [[data-slot=code-block]>&]:m-0 [[data-slot=code-block]>&]:opacity-0 [[data-slot=code-block]>&]:transition-opacity [[data-slot=code-block]>&]:group-focus-within/code-block:opacity-100 [[data-slot=code-block]>&]:group-hover/code-block:opacity-100 [[data-slot=code-block]>&]:pointer-coarse:opacity-100",
          "group-data-[size=sm]/code-block:[[data-slot=code-block]>&]:end-2 group-data-[size=sm]/code-block:[[data-slot=code-block]>&]:top-2 [[data-slot=code-block]>&]:*:[button]:bg-background [[data-slot=code-block]>&]:*:[button]:ring-1 [[data-slot=code-block]>&]:*:[button]:ring-foreground/10",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a ghost icon button that copies text to the clipboard, then shows a
  check mark for two seconds and announces "Copied" to screen readers.

  Requires the `code-block` JS component (`import "salad_ui/components/code_block"`).

  ## Attributes

  * `:id` - Required. The LiveView hook needs a stable DOM id.
  * `:value` - The text to copy. When `nil`, the button copies the text of the
    `code_block_content/1` in the same `code_block/1` (without line numbers,
    diff markers or ANSI escape codes).
  * `:variant` / `:size` - Button variant and size (`"ghost"` / `"icon-xs"`).
  * `:"on-copy"` - A LiveView event name or `Phoenix.LiveView.JS` command run
    after a successful copy. An event receives `%{"value" => text}`. The
    "copied" state survives the re-render the event may cause.
  * `:class` - Additional CSS classes.

  ## Examples

      <.code_block_copy_button id="install-copy" value="mix deps.get" />
      <.code_block_copy_button id="snippet-copy" on-copy="snippet_copied" />
  """
  attr :id, :string, required: true
  attr :value, :string, default: nil
  attr :variant, :string, values: ~w(default secondary destructive outline ghost link), default: "ghost"
  attr :size, :string, values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg), default: "icon-xs"
  attr :"on-copy", :any, default: nil, doc: "event name or JS command run after a successful copy"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled)

  def code_block_copy_button(assigns) do
    assigns =
      assigns
      |> assign(:button_class, button_variant(%{variant: assigns.variant, size: assigns.size}))
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(:options, json(%{value: assigns.value}))

    ~H"""
    <button
      id={@id}
      type="button"
      data-slot="code-block-copy-button"
      data-component="code-block-copy-button"
      data-part="root"
      data-state="idle"
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      aria-label="Copy"
      class={classes([@button_class, "group/copy", @class])}
      {@rest}
    >
      <svg
        data-icon="copy"
        class="group-data-[state=copied]/copy:hidden"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
      >
        <rect width="14" height="14" x="8" y="8" rx="2" ry="2" />
        <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />
      </svg>
      <svg
        data-icon="check"
        class="hidden group-data-[state=copied]/copy:inline"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        aria-hidden="true"
      >
        <path d="M20 6 9 17l-5-5" />
      </svg>
    </button>
    <span
      id={"#{@id}-status"}
      data-slot="code-block-copy-status"
      aria-live="polite"
      phx-update="ignore"
      class="sr-only"
    ></span>
    """
  end

  @doc """
  Renders the `pre` that scrolls or wraps the code.

  ## Attributes

  * `:code` - The code as a string. When `nil`, the inner block is rendered
    (usually a list of `code_block_line/1`).
  * `:language` - Highlight `code` with this Makeup lexer name (e.g.
    `"elixir"`), or `"ansi"` for terminal colors. Unknown languages render as
    plain text.
  * `:line_numbers` - Number each line.
  * `:start_line` - The number of the first line (default `1`).
  * `:wrap` - Wrap long lines instead of scrolling.
  * `:highlight` - Line numbers (as displayed, so relative to `start_line`) to
    render with the `"highlighted"` variant.
  * `:diff` - Treat `code` as a unified diff: lines starting with `+` render
    as `"added"`, lines starting with `-` as `"removed"`, and the first column
    (the marker) is dropped from every line. Hunk headers (`@@ ... @@`) and
    `\\ No newline at end of file` notes are kept whole.
  * `:tabindex` - `0` by default so the content can be scrolled by keyboard;
    pass `-1` to remove the tab stop.
  * `:class` - Additional CSS classes, such as `max-h-72` to cap the height.

  ## Examples

      <.code_block_content code={@output} wrap />
      <.code_block_content code={@code} language="elixir" line_numbers class="max-h-72" />

      <.code_block_content line_numbers>
        <.code_block_line>defmodule Hello do</.code_block_line>
        <.code_block_line variant="highlighted">  def world, do: :ok</.code_block_line>
        <.code_block_line>end</.code_block_line>
      </.code_block_content>
  """
  attr :code, :string, default: nil
  attr :language, :any, default: nil
  attr :line_numbers, :boolean, default: false
  attr :start_line, :integer, default: 1
  attr :wrap, :boolean, default: false
  attr :highlight, :list, default: []
  attr :diff, :boolean, default: false
  attr :tabindex, :any, default: 0
  attr :style, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def code_block_content(assigns) do
    assigns =
      assigns
      |> assign(:lines, content_lines(assigns))
      |> assign(:counter_style, "counter-reset: line #{assigns.start_line - 1};#{assigns.style}")

    ~H"""
    <pre
      phx-no-format
      data-slot="code-block-content"
      data-wrap={@wrap}
      data-numbered={@line_numbers}
      dir="ltr"
      tabindex={@tabindex}
      style={@counter_style}
      class={
        classes([
          "min-h-0 min-w-0 overflow-auto px-4 py-4 text-start font-mono leading-relaxed outline-none [scrollbar-width:thin] data-wrap:wrap-break-word data-wrap:whitespace-pre-wrap group-has-data-[slot=code-block-header]/code-block:pt-2 group-has-data-[slot=code-block-footer]/code-block:pb-2 group-data-[size=sm]/code-block:px-3 group-data-[size=sm]/code-block:py-3 group-data-[size=sm]/code-block:group-has-data-[slot=code-block-header]/code-block:pt-1.5",
          @class
        ])
      }
      {@rest}
    ><code data-slot="code-block-code" class="grid min-h-lh min-w-max content-start in-data-numbered:grid-cols-[auto_1fr] in-data-wrap:min-w-0"><%= cond do %><% is_nil(@code) -> %>{render_slot(@inner_block)}<% @lines == nil -> %>{@code}<% true -> %><.code_block_line :for={{variant, line} <- @lines} variant={variant}>{line}</.code_block_line><% end %></code></pre>
    """
  end

  defp content_lines(%{code: nil}), do: nil

  defp content_lines(%{line_numbers: false, language: nil, diff: false, highlight: []}), do: nil

  defp content_lines(%{code: code} = assigns) do
    raw = code |> strip_trailing_newline() |> String.split("\n")

    {variants, source_lines} =
      if assigns.diff do
        raw
        |> Enum.map(fn
          "@@" <> _ = hunk -> {"default", hunk}
          "\\" <> _ = note -> {"default", note}
          "+" <> rest -> {"added", rest}
          "-" <> rest -> {"removed", rest}
          line -> {"default", drop_first(line)}
        end)
        |> Enum.unzip()
      else
        {Enum.map(raw, fn _ -> "default" end), raw}
      end

    rendered = highlight(Enum.join(source_lines, "\n"), assigns.language)
    highlighted = MapSet.new(assigns.highlight)

    [variants, rendered]
    |> Enum.zip()
    |> Enum.with_index(assigns.start_line)
    |> Enum.map(fn {{variant, line}, number} ->
      if variant == "default" and MapSet.member?(highlighted, number),
        do: {"highlighted", line},
        else: {variant, line}
    end)
  end

  defp drop_first(""), do: ""
  defp drop_first(line), do: String.slice(line, 1..-1//1)

  defp strip_trailing_newline(code) do
    if String.ends_with?(code, "\n"), do: binary_part(code, 0, byte_size(code) - 1), else: code
  end

  @line_base "relative -mx-4 block min-h-lh px-4 group-data-[size=sm]/code-block:-mx-3 group-data-[size=sm]/code-block:px-3 after:absolute after:start-1 after:top-0 after:text-muted-foreground after:select-none in-data-numbered:col-span-2 in-data-numbered:grid in-data-numbered:grid-cols-subgrid in-data-numbered:gap-x-3 in-data-numbered:[counter-increment:line] before:min-w-6 before:text-end before:text-muted-foreground in-data-numbered:before:content-[counter(line)] in-data-numbered:before:select-none in-data-numbered:supports-[content:counter(line)_/_'']:before:content-[counter(line)_/_'']"

  @doc """
  Renders one line of code inside `code_block_content/1`. A line without an
  inner block holds a newline so copying a selection keeps blank lines
  (`highlight/2` does the same for its empty lines).

  ## Attributes

  * `:variant` - `"default"`, `"added"` (`+` marker), `"removed"` (`−` marker)
    or `"highlighted"`.
  * `:class` - Additional CSS classes.
  """
  attr :variant, :string, values: ~w(default added removed highlighted), default: "default"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def code_block_line(assigns) do
    assigns = assign(assigns, :base, @line_base)

    ~H"""
    <span
      phx-no-format
      data-slot="code-block-line"
      data-variant={@variant}
      class={classes([@base, line_variant(@variant), @class])}
      {@rest}
    ><span data-slot="code-block-line-content" class="min-w-0"><%= if @inner_block == [] do %>{"\n"}<% else %>{render_slot(@inner_block)}<% end %></span></span>
    """
  end

  defp line_variant("highlighted"), do: "bg-muted"
  defp line_variant("added"), do: "bg-muted after:content-['+']"
  defp line_variant("removed"), do: "bg-destructive/10 after:text-destructive after:content-['−']"
  defp line_variant(_), do: nil

  @doc """
  Renders a row below the content, such as for a "Show more" button.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def code_block_footer(assigns) do
    ~H"""
    <div
      data-slot="code-block-footer"
      class={
        classes([
          "flex min-w-0 shrink-0 items-center gap-2 px-4 pb-4 text-muted-foreground group-data-[size=sm]/code-block:px-3 group-data-[size=sm]/code-block:pb-3",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # -- Highlighting ------------------------------------------------------------

  @doc """
  Highlights `code` and returns one `Phoenix.HTML.safe/0` value per line, for
  use as the inner block of `code_block_line/1`.

  `language` is a Makeup lexer name (such as `"elixir"`), a lexer module, or
  `"ansi"` for terminal output. Without Makeup, or for a language that has no
  registered lexer, the lines are returned as escaped plain text. A trailing
  newline is ignored.

  ## Examples

      SaladUI.CodeBlock.highlight(~S|IO.puts("hi")|, "elixir")
      #=> one {:safe, iodata} per line, tokens wrapped in colored spans
  """
  @spec highlight(String.t(), String.t() | module() | nil) :: [Phoenix.HTML.safe()]
  def highlight(code, language) when is_binary(code) do
    code = strip_trailing_newline(code)

    code
    |> segments(language)
    |> Enum.map(fn
      [] -> {:safe, "\n"}
      segments -> {:safe, Enum.map(segments, &segment_html/1)}
    end)
  end

  @doc """
  Removes ANSI escape sequences from `text`, e.g. to pass terminal output as
  the `value` of `code_block_copy_button/1`.

  ## Examples

      iex> SaladUI.CodeBlock.strip_ansi("\\e[32m✓\\e[39m ok")
      "✓ ok"
  """
  @spec strip_ansi(String.t()) :: String.t()
  def strip_ansi(text), do: String.replace(text, ~r/\e\[[\d;]*[A-Za-z]/, "")

  defp segments(code, language) when language in ["ansi", :ansi], do: ansi_segments(code)

  defp segments(code, language) do
    case lexer(language) do
      {lexer, opts} -> code |> lexer.lex(opts) |> tokens_to_lines()
      nil -> code |> String.split("\n") |> Enum.map(&push_segment([], nil, &1))
    end
  end

  defp segment_html({nil, text}), do: Engine.html_escape(text)

  defp segment_html({class, text}), do: ["<span class=\"", class, "\">", Engine.html_escape(text), "</span>"]

  defp lexer(nil), do: nil
  defp lexer(""), do: nil

  defp lexer(language) when is_atom(language) do
    if Code.ensure_loaded?(language) and function_exported?(language, :lex, 2),
      do: {language, []},
      else: lexer(Atom.to_string(language))
  end

  defp lexer(language) when is_binary(language) do
    if Code.ensure_loaded?(Makeup.Registry) do
      name = String.downcase(language)

      case Makeup.Registry.fetch_lexer_by_name(name) do
        {:ok, lexer} -> lexer
        :error -> Makeup.Registry.get_lexer_by_extension(name)
      end
    end
  end

  defp tokens_to_lines(tokens) do
    {lines, current} =
      Enum.reduce(tokens, {[], []}, fn {type, _meta, value}, {lines, current} ->
        class = token_class(type)
        # Makeup emits a bare codepoint for one-character tokens (`x:` in `%{x: 1}`).
        [first | rest] = value |> List.wrap() |> IO.chardata_to_string() |> String.split("\n")

        Enum.reduce(rest, {lines, push_segment(current, class, first)}, fn part, {lines, current} ->
          {[Enum.reverse(current) | lines], push_segment([], class, part)}
        end)
      end)

    Enum.reverse([Enum.reverse(current) | lines])
  end

  defp push_segment(segments, _class, ""), do: segments
  defp push_segment(segments, class, text), do: [{class, text} | segments]

  # GitHub light / dark theme colors, as Shiki uses in shadcn's code block.
  @hl_keyword "text-[#d73a49] dark:text-[#f97583]"
  @hl_string "text-[#032f62] dark:text-[#9ecbff]"
  @hl_constant "text-[#005cc5] dark:text-[#79b8ff]"
  @hl_function "text-[#6f42c1] dark:text-[#b392f0]"
  @hl_tag "text-[#22863a] dark:text-[#85e89d]"
  @hl_comment "text-[#6a737d] dark:text-[#6a737d]"
  @hl_variable "text-[#e36209] dark:text-[#ffab70]"
  @hl_deleted "text-[#b31d28] dark:text-[#fdaeb7]"

  @token_classes [
    {"comment", @hl_comment},
    {"string_symbol", @hl_constant},
    {"string_escape", @hl_constant},
    {"string_interpol", @hl_keyword},
    {"string", @hl_string},
    {"number", @hl_constant},
    {"literal", @hl_constant},
    {"keyword_constant", @hl_constant},
    {"keyword", @hl_keyword},
    {"operator", @hl_keyword},
    {"name_function", @hl_function},
    {"name_class", @hl_function},
    {"name_decorator", @hl_function},
    {"name_entity", @hl_function},
    {"name_exception", @hl_function},
    {"name_tag", @hl_tag},
    {"name_attribute", @hl_constant},
    {"name_constant", @hl_constant},
    {"name_builtin", @hl_constant},
    {"name_label", @hl_constant},
    {"name_namespace", @hl_function},
    {"name_variable", @hl_variable},
    {"generic_inserted", @hl_tag},
    {"generic_deleted", @hl_deleted},
    {"generic_heading", @hl_constant},
    {"generic_subheading", @hl_constant},
    {"generic_emph", "italic"},
    {"generic_strong", "font-bold"},
    {"error", @hl_deleted}
  ]

  defp token_class(type) do
    name = Atom.to_string(type)

    Enum.find_value(@token_classes, fn {prefix, class} ->
      if String.starts_with?(name, prefix), do: class
    end)
  end

  # -- ANSI --------------------------------------------------------------------

  @ansi_fg %{
    30 => "text-neutral-900 dark:text-neutral-400",
    31 => "text-red-600 dark:text-red-400",
    32 => "text-green-600 dark:text-green-400",
    33 => "text-yellow-600 dark:text-yellow-400",
    34 => "text-blue-600 dark:text-blue-400",
    35 => "text-fuchsia-600 dark:text-fuchsia-400",
    36 => "text-cyan-600 dark:text-cyan-400",
    37 => "text-neutral-500 dark:text-neutral-300",
    90 => "text-neutral-500 dark:text-neutral-500",
    91 => "text-red-500 dark:text-red-300",
    92 => "text-green-500 dark:text-green-300",
    93 => "text-yellow-500 dark:text-yellow-300",
    94 => "text-blue-500 dark:text-blue-300",
    95 => "text-fuchsia-500 dark:text-fuchsia-300",
    96 => "text-cyan-500 dark:text-cyan-300",
    97 => "text-neutral-400 dark:text-neutral-100"
  }

  @ansi_bg %{
    40 => "bg-neutral-900/15",
    41 => "bg-red-500/15",
    42 => "bg-green-500/15",
    43 => "bg-yellow-500/15",
    44 => "bg-blue-500/15",
    45 => "bg-fuchsia-500/15",
    46 => "bg-cyan-500/15",
    47 => "bg-neutral-500/15"
  }

  @ansi_style %{bold: "font-bold", dim: "opacity-60", italic: "italic", underline: "underline"}

  @ansi_sequence ~r/\e\[([\d;]*)([A-Za-z])/

  defp ansi_segments(code) do
    code |> String.split("\n") |> Enum.map(&ansi_line/1)
  end

  defp ansi_line(line) do
    @ansi_sequence
    |> Regex.split(line, include_captures: true)
    |> Enum.reduce({[], %{}}, &ansi_part/2)
    |> elem(0)
    |> Enum.reverse()
  end

  defp ansi_part(part, {segments, style}) do
    case Regex.run(@ansi_sequence, part) do
      [^part, params, "m"] -> {segments, apply_sgr(style, params)}
      [^part, _params, _other] -> {segments, style}
      _ -> {push_segment(segments, ansi_class(style), part), style}
    end
  end

  defp apply_sgr(style, ""), do: apply_sgr(style, "0")

  defp apply_sgr(style, params) do
    params
    |> String.split(";")
    |> Enum.map(&parse_int/1)
    |> apply_sgr_codes(style)
  end

  # 38/48 take extra arguments: `5;n` (256-color palette) or `2;r;g;b`
  # (true color). They must be consumed here, or `38;5;31` would read as red
  # and `38;2;0;0;0` as a reset. Palette colors 0-15 map to the standard
  # colors; other extended colors fall back to the default color.
  defp apply_sgr_codes([], style), do: style

  defp apply_sgr_codes([code, 5, n | rest], style) when code in [38, 48] do
    apply_sgr_codes(rest, apply_extended_color(style, code, palette_code(code, n)))
  end

  defp apply_sgr_codes([code, 2, _r, _g, _b | rest], style) when code in [38, 48] do
    apply_sgr_codes(rest, apply_extended_color(style, code, nil))
  end

  defp apply_sgr_codes([code | _rest], style) when code in [38, 48], do: style

  defp apply_sgr_codes([code | rest], style), do: apply_sgr_codes(rest, apply_sgr_code(code, style))

  defp palette_code(38, n) when n in 0..7, do: 30 + n
  defp palette_code(38, n) when n in 8..15, do: 90 + n - 8
  defp palette_code(48, n) when n in 0..15, do: 40 + rem(n, 8)
  defp palette_code(_code, _n), do: nil

  defp apply_extended_color(style, 38, nil), do: Map.delete(style, :fg)
  defp apply_extended_color(style, 48, nil), do: Map.delete(style, :bg)
  defp apply_extended_color(style, _code, sgr), do: apply_sgr_code(sgr, style)

  defp parse_int(""), do: 0

  defp parse_int(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> -1
    end
  end

  defp apply_sgr_code(0, _style), do: %{}
  defp apply_sgr_code(1, style), do: Map.put(style, :bold, true)
  defp apply_sgr_code(2, style), do: Map.put(style, :dim, true)
  defp apply_sgr_code(3, style), do: Map.put(style, :italic, true)
  defp apply_sgr_code(4, style), do: Map.put(style, :underline, true)
  defp apply_sgr_code(22, style), do: Map.drop(style, [:bold, :dim])
  defp apply_sgr_code(23, style), do: Map.delete(style, :italic)
  defp apply_sgr_code(24, style), do: Map.delete(style, :underline)
  defp apply_sgr_code(39, style), do: Map.delete(style, :fg)
  defp apply_sgr_code(49, style), do: Map.delete(style, :bg)
  defp apply_sgr_code(code, style) when is_map_key(@ansi_fg, code), do: Map.put(style, :fg, code)
  defp apply_sgr_code(code, style) when is_map_key(@ansi_bg, code), do: Map.put(style, :bg, code)
  defp apply_sgr_code(_code, style), do: style

  defp ansi_class(style) when map_size(style) == 0, do: nil

  defp ansi_class(style) do
    classes =
      [Map.get(@ansi_fg, style[:fg]), Map.get(@ansi_bg, style[:bg])] ++
        for(key <- [:bold, :dim, :italic, :underline], style[key], do: @ansi_style[key])

    classes |> Enum.reject(&is_nil/1) |> Enum.join(" ")
  end
end
