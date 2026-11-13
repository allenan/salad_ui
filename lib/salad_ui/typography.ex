defmodule SaladUI.Typography do
  @moduledoc """
  Typography components: headings, paragraphs, lists, quotes, tables and text
  styles from the shadcn/ui typography page.

  shadcn/ui ships these as copy-paste class recipes rather than components;
  SaladUI wraps each recipe in a function component so it can be reused and
  overridden with `class`. Every component accepts `:class` (merged with
  `TwMerge`) and global HTML attributes.

  | Component                  | Element        |
  | -------------------------- | -------------- |
  | `typography_h1/1`          | `<h1>`         |
  | `typography_h2/1`          | `<h2>`         |
  | `typography_h3/1`          | `<h3>`         |
  | `typography_h4/1`          | `<h4>`         |
  | `typography_p/1`           | `<p>`          |
  | `typography_blockquote/1`  | `<blockquote>` |
  | `typography_table/1`       | `<table>`      |
  | `typography_list/1`        | `<ul>`/`<ol>`  |
  | `typography_inline_code/1` | `<code>`       |
  | `typography_lead/1`        | `<p>`          |
  | `typography_large/1`       | `<div>`        |
  | `typography_small/1`       | `<small>`      |
  | `typography_muted/1`       | `<p>`          |

  ## Examples

      <.typography_h1>Taxing Laughter: The Joke Tax Chronicles</.typography_h1>
      <.typography_lead>
        Once upon a time, in a far-off land, there was a very lazy king.
      </.typography_lead>
      <.typography_h2>The King's Plan</.typography_h2>
      <.typography_p>
        The king thought long and hard, and finally came up with
        <a href="#" class="font-medium text-primary underline underline-offset-4">a brilliant plan</a>.
      </.typography_p>
      <.typography_blockquote>
        "After all," he said, "everyone enjoys a good joke."
      </.typography_blockquote>
      <.typography_list>
        <li>1st level of puns: 5 gold coins</li>
        <li>2nd level of jokes: 10 gold coins</li>
      </.typography_list>
      <.typography_p>Install <.typography_inline_code>salad_ui</.typography_inline_code>.</.typography_p>
  """
  use SaladUI, :component

  @doc "Renders a page title (`<h1>`)."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_h1(assigns) do
    ~H"""
    <h1
      class={classes(["scroll-m-20 text-4xl font-extrabold tracking-tight text-balance", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h1>
    """
  end

  @doc "Renders a section heading (`<h2>`) with a bottom border."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_h2(assigns) do
    ~H"""
    <h2
      class={
        classes([
          "scroll-m-20 border-b pb-2 text-3xl font-semibold tracking-tight transition-colors first:mt-0",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </h2>
    """
  end

  @doc "Renders a sub-section heading (`<h3>`)."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_h3(assigns) do
    ~H"""
    <h3 class={classes(["scroll-m-20 text-2xl font-semibold tracking-tight", @class])} {@rest}>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc "Renders a minor heading (`<h4>`)."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_h4(assigns) do
    ~H"""
    <h4 class={classes(["scroll-m-20 text-xl font-semibold tracking-tight", @class])} {@rest}>
      {render_slot(@inner_block)}
    </h4>
    """
  end

  @doc "Renders a paragraph. Consecutive paragraphs are spaced with `mt-6`."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_p(assigns) do
    ~H"""
    <p class={classes(["leading-7 [&:not(:first-child)]:mt-6", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "Renders an italic block quote with a left border."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_blockquote(assigns) do
    ~H"""
    <blockquote class={classes(["mt-6 border-s-2 ps-6 italic", @class])} {@rest}>
      {render_slot(@inner_block)}
    </blockquote>
    """
  end

  @doc """
  Renders a bordered, zebra-striped table inside a scroll container. Write plain
  `<thead>`, `<tbody>`, `<tr>`, `<th>` and `<td>` inside; cells honour
  `align="center"` and `align="right"`.

  ## Examples

      <.typography_table>
        <thead>
          <tr><th>King's Treasury</th><th>People's happiness</th></tr>
        </thead>
        <tbody>
          <tr><td>Empty</td><td>Overflowing</td></tr>
          <tr><td>Modest</td><td align="right">Satisfied</td></tr>
        </tbody>
      </.typography_table>
  """
  attr :class, :string, default: nil, doc: "classes for the `<table>`"
  attr :rest, :global
  slot :inner_block, required: true

  def typography_table(assigns) do
    ~H"""
    <div class="my-6 w-full overflow-y-auto">
      <table
        class={
          classes([
            "w-full",
            "[&_tr]:m-0 [&_tr]:border-t [&_tr]:p-0 [&_tr:nth-child(even)]:bg-muted",
            "[&_th]:border [&_th]:px-4 [&_th]:py-2 [&_th]:text-start [&_th]:font-bold [&_th[align=center]]:text-center [&_th[align=right]]:text-right",
            "[&_td]:border [&_td]:px-4 [&_td]:py-2 [&_td]:text-start [&_td[align=center]]:text-center [&_td[align=right]]:text-right",
            @class
          ])
        }
        {@rest}
      >
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end

  @doc """
  Renders a bulleted list (`<ul>`), or a numbered list (`<ol>`) with `ordered`.
  """
  attr :ordered, :boolean, default: false, doc: "render an `<ol>` with decimal markers"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_list(%{ordered: true} = assigns) do
    ~H"""
    <ol class={classes(["my-6 ms-6 list-decimal [&>li]:mt-2", @class])} {@rest}>
      {render_slot(@inner_block)}
    </ol>
    """
  end

  def typography_list(assigns) do
    ~H"""
    <ul class={classes(["my-6 ms-6 list-disc [&>li]:mt-2", @class])} {@rest}>
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc "Renders inline code."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_inline_code(assigns) do
    ~H"""
    <code
      class={
        classes([
          "relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold",
          @class
        ])
      }
      {@rest}
    >{render_slot(@inner_block)}</code>
    """
  end

  @doc "Renders an introductory paragraph in larger, muted text."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_lead(assigns) do
    ~H"""
    <p class={classes(["text-xl text-muted-foreground", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc "Renders large, semibold text."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_large(assigns) do
    ~H"""
    <div class={classes(["text-lg font-semibold", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Renders small, medium-weight text (`<small>`)."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_small(assigns) do
    ~H"""
    <small class={classes(["text-sm leading-none font-medium", @class])} {@rest}>
      {render_slot(@inner_block)}
    </small>
    """
  end

  @doc "Renders small, muted text."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def typography_muted(assigns) do
    ~H"""
    <p class={classes(["text-sm text-muted-foreground", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end
end
