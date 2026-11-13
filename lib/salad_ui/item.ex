defmodule SaladUI.Item do
  @moduledoc """
  A versatile flex container for displaying content with media, a title, a
  description and actions. Group items with `item_group/1` to build a list.

  Use `SaladUI.Form` (field) when you need a form control; use `item/1` when you
  only need to display content.

  ## Composition

      item_group
      └── item
          ├── item_header
          ├── item_media
          ├── item_content
          │   ├── item_title
          │   └── item_description
          ├── item_actions
          └── item_footer

  ## Examples

      <.item variant="outline">
        <.item_media variant="icon">
          <.icon name="hero-shield-exclamation" />
        </.item_media>
        <.item_content>
          <.item_title>Security Alert</.item_title>
          <.item_description>New login detected from unknown device.</.item_description>
        </.item_content>
        <.item_actions>
          <.button size="sm" variant="outline">Review</.button>
        </.item_actions>
      </.item>

      <%!-- Rendered as a link: hover and focus styles apply to the <a> --%>
      <.item variant="outline" size="sm" navigate="/profile">
        <.item_content>
          <.item_title>Your profile has been verified.</.item_title>
        </.item_content>
      </.item>

      <.item_group>
        <.item>...</.item>
        <.item_separator />
        <.item>...</.item>
      </.item_group>
  """
  use SaladUI, :component

  @item_base "group/item flex flex-wrap items-center rounded-md border border-transparent text-sm transition-colors duration-100 outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 [a]:transition-colors [a]:hover:bg-accent/50"

  @item_variants %{
    "default" => "bg-transparent",
    "outline" => "border-border",
    "muted" => "bg-muted/50"
  }

  @item_sizes %{
    "default" => "gap-4 p-4",
    "sm" => "gap-2.5 px-4 py-3",
    "xs" => "gap-2 px-3 py-2 in-data-[slot=dropdown-menu-content]:p-0"
  }

  @media_base "flex shrink-0 items-center justify-center gap-2 group-has-[[data-slot=item-description]]/item:translate-y-0.5 group-has-[[data-slot=item-description]]/item:self-start [&_svg]:pointer-events-none"

  @media_variants %{
    "default" => "bg-transparent",
    "icon" => "size-8 rounded-sm border bg-muted [&_svg:not([class*='size-'])]:size-4",
    "image" =>
      "size-10 overflow-hidden rounded-sm group-data-[size=sm]/item:size-8 group-data-[size=xs]/item:size-6 [&_img]:size-full [&_img]:object-cover"
  }

  @doc """
  Renders a group of items as a list (`role="list"`).

  ## Examples

      <.item_group class="gap-4">
        <.item variant="outline" role="listitem">...</.item>
      </.item_group>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def item_group(assigns) do
    ~H"""
    <div
      role="list"
      data-slot="item-group"
      class={classes(["group/item-group flex flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a horizontal separator between items in an `item_group/1`.
  """
  attr :class, :any, default: nil
  attr :rest, :global

  def item_separator(assigns) do
    ~H"""
    <SaladUI.Separator.separator
      orientation="horizontal"
      data-slot="item-separator"
      class={classes(["my-0", @class])}
      {@rest}
    />
    """
  end

  @doc """
  Renders an item.

  ## Attributes

  * `:variant` - `"default"` (transparent), `"outline"` (bordered) or `"muted"` (subtle background).
  * `:size` - `"default"`, `"sm"` or `"xs"`.
  * `:href`, `:navigate`, `:patch` - When any is set the item renders as a link
    (`<a>` via `Phoenix.Component.link/1`), which enables the hover background.
    This is the SaladUI equivalent of shadcn's `<Item asChild><a /></Item>`.
  * `:class` - Additional CSS classes.

  ## Examples

      <.item>
        <.item_content>
          <.item_title>Default Variant</.item_title>
          <.item_description>Standard styling.</.item_description>
        </.item_content>
      </.item>

      <.item variant="outline" href="https://hexdocs.pm" target="_blank" rel="noopener noreferrer">
        <.item_content>
          <.item_title>External resource</.item_title>
        </.item_content>
      </.item>
  """
  attr :variant, :string, values: ~w(default outline muted), default: "default", doc: "the visual style"
  attr :size, :string, values: ~w(default sm xs), default: "default", doc: "the padding and gap size"
  attr :href, :string, default: nil, doc: "renders the item as a link to this URL"
  attr :navigate, :string, default: nil, doc: "renders the item as a LiveView `navigate` link"
  attr :patch, :string, default: nil, doc: "renders the item as a LiveView `patch` link"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(method download hreflang referrerpolicy rel target replace)
  slot :inner_block, required: true

  def item(%{href: href, navigate: navigate, patch: patch} = assigns)
      when not is_nil(href) or not is_nil(navigate) or not is_nil(patch) do
    assigns = assign(assigns, :item_class, item_class(assigns))

    ~H"""
    <.link
      href={@href}
      navigate={@navigate}
      patch={@patch}
      data-slot="item"
      data-variant={@variant}
      data-size={@size}
      class={@item_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  def item(assigns) do
    assigns = assign(assigns, :item_class, item_class(assigns))

    ~H"""
    <div data-slot="item" data-variant={@variant} data-size={@size} class={@item_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp item_class(assigns) do
    classes([@item_base, @item_variants[assigns.variant], @item_sizes[assigns.size], assigns.class])
  end

  @doc """
  Renders the media area of an item: an icon, image or avatar.

  ## Attributes

  * `:variant` - `"default"` (no styling), `"icon"` (bordered muted square for
    an icon) or `"image"` (square crop for an `<img>`, scaled with the item size).

  ## Examples

      <.item_media variant="icon"><.icon name="hero-home" /></.item_media>
      <.item_media variant="image"><img src="/cover.png" alt="Cover" /></.item_media>
  """
  attr :variant, :string, values: ~w(default icon image), default: "default", doc: "the media style"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def item_media(assigns) do
    assigns = assign(assigns, :media_class, classes([@media_base, @media_variants[assigns.variant], assigns.class]))

    ~H"""
    <div data-slot="item-media" data-variant={@variant} class={@media_class} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Wraps the title and description of an item. A second `item_content` placed
  right after the first shrinks to its content (e.g. a trailing duration).
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def item_content(assigns) do
    ~H"""
    <div
      data-slot="item-content"
      class={classes(["flex flex-1 flex-col gap-1 [&+[data-slot=item-content]]:flex-none", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the title of an item.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def item_title(assigns) do
    ~H"""
    <div
      data-slot="item-title"
      class={classes(["flex w-fit items-center gap-2 text-sm leading-snug font-medium", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the description of an item, clamped to two lines. Links inside are underlined.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def item_description(assigns) do
    ~H"""
    <p
      data-slot="item-description"
      class={
        classes([
          "line-clamp-2 text-sm leading-normal font-normal text-balance text-muted-foreground",
          "[&>a]:underline [&>a]:underline-offset-4 [&>a:hover]:text-primary",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Container for buttons or other interactive elements at the end of an item.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def item_actions(assigns) do
    ~H"""
    <div data-slot="item-actions" class={classes(["flex items-center gap-2", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a full-width row above the item content (e.g. a cover image).
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def item_header(assigns) do
    ~H"""
    <div
      data-slot="item-header"
      class={classes(["flex basis-full items-center justify-between gap-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a full-width row below the item content (e.g. a progress bar).
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def item_footer(assigns) do
    ~H"""
    <div
      data-slot="item-footer"
      class={classes(["flex basis-full items-center justify-between gap-2", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
