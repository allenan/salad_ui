defmodule SaladUI.ButtonGroup do
  @moduledoc """
  A container that groups related buttons together with consistent styling.

  Adjacent children lose their touching corners and the duplicated border, so a
  row (or column) of outline buttons, inputs, selects and input groups reads as a
  single control. Nest button groups to add spacing between sub-groups.

  Use a button group for buttons that perform actions. Use `SaladUI.ToggleGroup`
  for buttons that toggle state.

  ## Examples

      <.button_group aria-label="Message actions">
        <.button variant="outline">Archive</.button>
        <.button variant="outline">Report</.button>
      </.button_group>

      <.button_group orientation="vertical" aria-label="Media controls" class="h-fit">
        <.button variant="outline" size="icon"><.icon name="hero-plus" class="size-4" /></.button>
        <.button variant="outline" size="icon"><.icon name="hero-minus" class="size-4" /></.button>
      </.button_group>

      <.button_group>
        <.button variant="secondary" size="sm">Copy</.button>
        <.button_group_separator />
        <.button variant="secondary" size="sm">Paste</.button>
      </.button_group>

      <.button_group>
        <.button_group_text as="label" for="url">https://</.button_group_text>
        <.input id="url" placeholder="example.com" />
      </.button_group>

  ## Accessibility

  The group renders with `role="group"`. Label it with `aria-label` or
  `aria-labelledby`. Buttons stay in the natural tab order.

  ## Overlay triggers

  SaladUI's dropdown menu, popover and select wrap their trigger in a root
  element (shadcn's Radix roots render no DOM). When such a component is a direct
  child of a button group, the group applies the joined corners and border to its
  `data-part="trigger"` child, so
  `<.dropdown_menu><.dropdown_menu_trigger as={&button/1} ...>` works inside a
  group like shadcn's `<DropdownMenuTrigger asChild>`.
  """
  use SaladUI, :component

  @base_class "flex w-fit items-stretch has-[>[data-slot=button-group]]:gap-2 [&>*]:focus-visible:relative [&>*]:focus-visible:z-10 has-[select[aria-hidden=true]:last-child]:[&>[data-slot=select-trigger]:last-of-type]:rounded-r-md [&>[data-slot=select-trigger]:not([class*='w-'])]:w-fit [&>input]:flex-1"

  @orientation_class %{
    "horizontal" =>
      "[&>*:not(:first-child)]:rounded-l-none [&>*:not(:first-child)]:border-l-0 [&>*:not(:last-child)]:rounded-r-none " <>
        "[&>[data-component]:not(:first-child)>[data-part=trigger]]:rounded-l-none [&>[data-component]:not(:first-child)>[data-part=trigger]]:border-l-0 [&>[data-component]:not(:last-child)>[data-part=trigger]]:rounded-r-none",
    "vertical" =>
      "flex-col [&>*:not(:first-child)]:rounded-t-none [&>*:not(:first-child)]:border-t-0 [&>*:not(:last-child)]:rounded-b-none " <>
        "[&>[data-component]:not(:first-child)>[data-part=trigger]]:rounded-t-none [&>[data-component]:not(:first-child)>[data-part=trigger]]:border-t-0 [&>[data-component]:not(:last-child)>[data-part=trigger]]:rounded-b-none"
  }

  @doc """
  Renders a button group.

  ## Options

  * `:orientation` - `"horizontal"` (default) or `"vertical"` layout.
  * `:class` - Additional CSS classes.
  * `:rest` - Additional HTML attributes, e.g. `aria-label`.

  ## Examples

      <.button_group aria-label="Pagination">
        <.button_group>
          <.button variant="outline" size="sm">1</.button>
          <.button variant="outline" size="sm">2</.button>
        </.button_group>
        <.button_group>
          <.button variant="outline" size="icon-sm" aria-label="Previous">
            <.icon name="hero-arrow-left" class="size-4" />
          </.button>
          <.button variant="outline" size="icon-sm" aria-label="Next">
            <.icon name="hero-arrow-right" class="size-4" />
          </.button>
        </.button_group>
      </.button_group>
  """
  attr :orientation, :string, values: ~w(horizontal vertical), default: "horizontal", doc: "the layout direction"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def button_group(assigns) do
    assigns =
      assign(assigns, :group_class, classes([@base_class, @orientation_class[assigns.orientation], assigns.class]))

    ~H"""
    <div
      role="group"
      data-slot="button-group"
      data-orientation={@orientation}
      class={@group_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders text (a prefix, suffix or label) inside a button group.

  ## Options

  * `:as` - The HTML tag or function component to render. Defaults to `"div"`.
    Use `as="label"` with `for` to label an input in the group (shadcn's
    `<ButtonGroupText asChild><Label /></ButtonGroupText>`).
  * `:class` - Additional CSS classes.

  ## Examples

      <.button_group>
        <.button_group_text>.com</.button_group_text>
      </.button_group>

      <.button_group>
        <.button_group_text as="label" for="name">Name</.button_group_text>
        <.input id="name" placeholder="Type something here..." />
      </.button_group>
  """
  attr :as, :any, default: "div", doc: "the tag (or function component) to render"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(for)
  slot :inner_block, required: true

  def button_group_text(assigns) do
    ~H"""
    <.dynamic
      tag={@as}
      data-slot={@rest[:"data-slot"] || "button-group-text"}
      class={
        classes([
          "flex items-center gap-2 rounded-md border bg-muted px-4 text-sm font-medium shadow-xs [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  Renders a separator between buttons in a group.

  Outline buttons already have a border and rarely need one; use a separator
  with `secondary`/`ghost` buttons, e.g. for split buttons.

  ## Options

  * `:orientation` - `"vertical"` (default, for horizontal groups) or
    `"horizontal"` (for vertical groups).
  * `:class` - Additional CSS classes.

  ## Examples

      <.button_group>
        <.button variant="secondary">Button</.button>
        <.button_group_separator />
        <.button variant="secondary" size="icon" aria-label="Add">
          <.icon name="hero-plus" class="size-4" />
        </.button>
      </.button_group>
  """
  attr :orientation, :string, values: ~w(vertical horizontal), default: "vertical", doc: "the separator direction"
  attr :class, :string, default: nil
  attr :rest, :global

  def button_group_separator(assigns) do
    ~H"""
    <SaladUI.Separator.separator
      data-slot="button-group-separator"
      orientation={@orientation}
      class={
        classes([
          "relative m-0! self-stretch bg-input data-[orientation=vertical]:h-auto",
          @class
        ])
      }
      {@rest}
    />
    """
  end
end
