defmodule SaladUI.Empty do
  @moduledoc """
  Displays an empty state: a centered block with media, a title, a description
  and optional actions.

  ## Composition

      empty
      ├── empty_header
      │   ├── empty_media
      │   ├── empty_title
      │   └── empty_description
      └── empty_content

  ## Examples

      <.empty>
        <.empty_header>
          <.empty_media variant="icon">
            <.icon name="hero-folder" />
          </.empty_media>
          <.empty_title>No Projects Yet</.empty_title>
          <.empty_description>
            You haven't created any projects yet. Get started by creating your first project.
          </.empty_description>
        </.empty_header>
        <.empty_content>
          <.button>Create Project</.button>
        </.empty_content>
      </.empty>

      <%!-- Outline: add a border --%>
      <.empty class="border border-dashed">...</.empty>

      <%!-- Background: any bg-* or gradient utility --%>
      <.empty class="h-full bg-gradient-to-b from-muted/50 from-30% to-background">...</.empty>
  """
  use SaladUI, :component

  @media_variants %{
    "default" => "bg-transparent",
    "icon" =>
      "flex size-10 shrink-0 items-center justify-center rounded-lg bg-muted text-foreground [&_svg:not([class*='size-'])]:size-6"
  }

  @doc """
  Renders the empty state container. Add `border` for an outlined look, or
  `bg-*` / `bg-gradient-*` utilities for a background.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def empty(assigns) do
    ~H"""
    <div
      data-slot="empty"
      class={
        classes([
          "flex min-w-0 flex-1 flex-col items-center justify-center gap-6 rounded-lg border-dashed p-6 text-center text-balance md:p-12",
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
  Wraps the media, title and description.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def empty_header(assigns) do
    ~H"""
    <div
      data-slot="empty-header"
      class={classes(["flex max-w-sm flex-col items-center gap-2 text-center", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the media of the empty state: an icon, image, avatar or avatar group.

  ## Attributes

  * `:variant` - `"default"` (no styling, e.g. for avatars) or `"icon"` (a
    muted rounded square sized for an icon).

  ## Examples

      <.empty_media variant="icon"><.icon name="hero-inbox" /></.empty_media>

      <.empty_media>
        <.avatar class="size-12">
          <.avatar_image src="https://github.com/shadcn.png" />
          <.avatar_fallback>CN</.avatar_fallback>
        </.avatar>
      </.empty_media>
  """
  attr :variant, :string, values: ~w(default icon), default: "default", doc: "the media style"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def empty_media(assigns) do
    assigns = assign(assigns, :variant_class, @media_variants[assigns.variant])

    ~H"""
    <div
      data-slot="empty-icon"
      data-variant={@variant}
      class={
        classes([
          "mb-2 flex shrink-0 items-center justify-center [&_svg]:pointer-events-none [&_svg]:shrink-0",
          @variant_class,
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
  Renders the title of the empty state.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def empty_title(assigns) do
    ~H"""
    <div
      data-slot="empty-title"
      class={classes(["text-lg font-medium tracking-tight", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the description of the empty state. Links inside are underlined.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def empty_description(assigns) do
    ~H"""
    <div
      data-slot="empty-description"
      class={
        classes([
          "text-sm/relaxed text-muted-foreground [&>a]:underline [&>a]:underline-offset-4 [&>a:hover]:text-primary",
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
  Renders the content area: buttons, inputs or links.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def empty_content(assigns) do
    ~H"""
    <div
      data-slot="empty-content"
      class={
        classes([
          "flex w-full max-w-sm min-w-0 flex-col items-center gap-4 text-sm text-balance",
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
