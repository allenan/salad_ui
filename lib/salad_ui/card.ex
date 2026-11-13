defmodule SaladUI.Card do
  @moduledoc """
  Card components for containing content and actions.

  Cards provide a flexible container for displaying content with support for headers,
  footers, and various content layouts. They organize information and actions consistently.

  Parts: `card/1`, `card_header/1`, `card_title/1`, `card_description/1`,
  `card_action/1`, `card_content/1`, `card_footer/1`.

  ## Spacing

  Every part reads its inset from the `--card-spacing` CSS variable
  (`--spacing(6)` by default, `--spacing(4)` with `size="sm"`). Override it to
  tighten or loosen a single card, and use `-mx-(--card-spacing)` /
  `-mb-(--card-spacing)` for edge-to-edge content:

      <.card class="[--card-spacing:--spacing(3)]">...</.card>

      <.card_content class="-mb-(--card-spacing)">
        <div class="-mx-(--card-spacing) border-t px-(--card-spacing) py-4">...</div>
      </.card_content>
  """
  use SaladUI, :component

  @doc """
  Renders a card container.

  ## Options

  * `:size` - `"default"` or `"sm"` (tighter spacing and a smaller title).
  * `:class` - Additional CSS classes.

  ## Examples:

      <.card class="w-full max-w-sm">
        <.card_header>
          <.card_title>Account Settings</.card_title>
          <.card_description>Manage your account settings.</.card_description>
          <.card_action>
            <.button variant="link">Help</.button>
          </.card_action>
        </.card_header>
        <.card_content>
          <p>Your account details and preferences.</p>
        </.card_content>
        <.card_footer>
          <.button variant="outline">Cancel</.button>
          <.button>Save</.button>
        </.card_footer>
      </.card>
  """

  attr :class, :string, default: nil
  attr :size, :string, values: ~w(default sm), default: "default", doc: "the card size"
  slot :inner_block, required: true
  attr :rest, :global

  def card(assigns) do
    ~H"""
    <div
      data-slot="card"
      data-size={@size}
      class={
        classes([
          "group/card flex flex-col gap-[var(--card-spacing)] rounded-xl border bg-card py-[var(--card-spacing)] text-card-foreground shadow-sm [--card-spacing:--spacing(6)] data-[size=sm]:[--card-spacing:--spacing(4)] has-[>img:first-child]:pt-0 *:[img:first-child]:rounded-t-xl *:[img:last-child]:rounded-b-xl",
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
  Renders a card header section for title, description and an optional
  `card_action/1`, which is placed in the top-right corner.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_header(assigns) do
    ~H"""
    <div
      data-slot="card-header"
      class={
        classes([
          "@container/card-header grid auto-rows-min grid-rows-[auto_auto] items-start gap-2 px-[var(--card-spacing)] has-data-[slot=card-action]:grid-cols-[1fr_auto] [.border-b]:pb-[var(--card-spacing)]",
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
  Renders a card title within the header section.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_title(assigns) do
    ~H"""
    <h3
      data-slot="card-title"
      class={classes(["leading-none font-semibold group-data-[size=sm]/card:text-sm", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc """
  Renders a card description within the header section.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_description(assigns) do
    ~H"""
    <p data-slot="card-description" class={classes(["text-sm text-muted-foreground", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders an action (button, badge, menu, ...) in the top-right corner of
  `card_header/1`, spanning the title and description rows.

  ## Examples

      <.card_header>
        <.card_title>Login to your account</.card_title>
        <.card_description>Enter your email below</.card_description>
        <.card_action>
          <.button variant="link">Sign Up</.button>
        </.card_action>
      </.card_header>
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_action(assigns) do
    ~H"""
    <div
      data-slot="card-action"
      class={classes(["col-start-2 row-span-2 row-start-1 self-start justify-self-end", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the main content area of the card.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_content(assigns) do
    ~H"""
    <div data-slot="card-content" class={classes(["px-[var(--card-spacing)]", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a footer section for the card, typically containing actions.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def card_footer(assigns) do
    ~H"""
    <div
      data-slot="card-footer"
      class={
        classes([
          "flex items-center px-[var(--card-spacing)] [.border-t]:pt-[var(--card-spacing)]",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
