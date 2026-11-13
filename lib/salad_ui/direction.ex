defmodule SaladUI.Direction do
  @moduledoc """
  Sets the text direction (`ltr` or `rtl`) for a page or part of one, for
  right-to-left languages such as Arabic, Hebrew and Persian.

  The shadcn/ui counterpart is `DirectionProvider`. SaladUI needs no React
  context: every component reads its direction from the nearest `dir`
  attribute, so `<html dir="rtl">` alone is enough for a whole page.
  `direction_provider/1` scopes a direction to one subtree (it renders a
  `display: contents` element carrying `dir`).

  ## Examples

      <html lang="ar" dir="rtl">
        ...
      </html>

      <.direction_provider direction="rtl">
        <.dropdown_menu id="actions">...</.dropdown_menu>
      </.direction_provider>

  ## What follows the direction

  * Text, flex/grid order and logical (`ms-*`, `ps-*`, `start-*`) classes, as
    in plain CSS; `rtl:` variants (e.g. `rtl:rotate-180` on arrow icons) apply.
  * Popover, tooltip, hover card, select, combobox, dropdown menu and menubar
    content: `align="start"`/`"end"` mirror for `top`/`bottom` placements, as
    in Radix (`side="left"`/`"right"` stay physical).
  * Sub-menus (dropdown, context menu, menubar) open to the left, and
    `ArrowLeft` opens / `ArrowRight` closes them; the context menu opens to
    the left of the pointer.
  * Horizontal arrow keys follow the reading direction in tabs, radio groups,
    menubar, navigation menu, carousel, resizable handles and the calendar.
  * Slider: a horizontal slider starts at the right (its own `dir` attribute
    wins over the inherited one).
  * Content moved to `<body>` (`use_portal`) keeps the direction of its
    trigger.

  In JavaScript, `SaladUI.getDirection(el)` returns `"ltr"` or `"rtl"` for any
  element (the counterpart of shadcn's `useDirection`).

  The sidebar's `side` stays physical: pick `side="right"` for an RTL page,
  as shadcn's RTL sidebar example does.
  """
  use SaladUI, :component

  @doc """
  Renders its content with the given reading direction.

  ## Attributes

  * `:direction` - `"ltr"` or `"rtl"`. Takes precedence over `:dir`.
  * `:dir` - Alias of `:direction` (Radix's prop name).
  * `:class` - Extra classes. The element is `display: contents`, so it adds
    no box of its own.
  """
  attr :direction, :string, default: nil, values: [nil, "ltr", "rtl"], doc: "Reading direction"
  attr :dir, :string, default: nil, values: [nil, "ltr", "rtl"], doc: "Alias of `direction`"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def direction_provider(assigns) do
    assigns = assign(assigns, :resolved_dir, assigns.direction || assigns.dir || "ltr")

    ~H"""
    <div
      data-slot="direction-provider"
      dir={@resolved_dir}
      class={classes(["contents", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
