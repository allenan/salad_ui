defmodule SaladUI.Carousel do
  @moduledoc """
  Implementation of the carousel component from https://ui.shadcn.com/docs/components/carousel

  shadcn builds its carousel on Embla. SaladUI uses native CSS scroll snapping
  for layout, touch swipe and trackpad scrolling, plus a small JS component
  (`assets/salad_ui/components/carousel.js`) for the previous/next buttons,
  keyboard navigation, looping, autoplay and the `select` event. There is no
  extra npm dependency.

  ## Example

      <.carousel id="demo-carousel" class="w-full max-w-xs">
        <.carousel_content>
          <.carousel_item :for={i <- 1..5}>
            <div class="p-1">
              <.card>
                <.card_content class="flex aspect-square items-center justify-center p-6">
                  <span class="text-4xl font-semibold">{i}</span>
                </.card_content>
              </.card>
            </div>
          </.carousel_item>
        </.carousel_content>
        <.carousel_previous />
        <.carousel_next />
      </.carousel>

  ## Sizes

  Set how many slides are in view with a `basis-*` class on `carousel_item/1`:

      <.carousel id="sizes" align="start" class="w-full max-w-sm">
        <.carousel_content>
          <.carousel_item :for={i <- 1..5} class="md:basis-1/2 lg:basis-1/3">...</.carousel_item>
        </.carousel_content>
        <.carousel_previous />
        <.carousel_next />
      </.carousel>

  ## Spacing

  Items are spaced with `pl-4` on each `carousel_item/1` and a matching `-ml-4`
  on `carousel_content/1` (`pt-4` / `-mt-4` when vertical). Pass your own pair
  to change the gap; the defaults have zero specificity, so any utility you
  pass wins:

      <.carousel_content class="-ml-2 md:-ml-4">
        <.carousel_item class="pl-2 md:pl-4">...</.carousel_item>
      </.carousel_content>

  ## Orientation

  `orientation="vertical"` stacks the slides; give `carousel_content/1` a
  height so it has something to scroll:

      <.carousel id="vertical" orientation="vertical" align="start" class="w-full max-w-xs">
        <.carousel_content class="-mt-1 h-[200px]">
          <.carousel_item :for={i <- 1..5} class="pt-1 md:basis-1/2">...</.carousel_item>
        </.carousel_content>
        <.carousel_previous />
        <.carousel_next />
      </.carousel>

  ## Streams

  Attributes on `carousel_content/1` go on the track that holds the slides,
  so it can be a stream container. LiveView patches (including slides
  streamed in or out) keep the selected slide, button state and autoplay
  state; slide labels are renumbered.

      <.carousel_content id="photos" phx-update="stream">
        <.carousel_item :for={{dom_id, photo} <- @streams.photos} id={dom_id}>...</.carousel_item>
      </.carousel_content>

  ## Options

  * `align` - Where a slide snaps inside the viewport: `"start"` (default),
    `"center"` or `"end"`. shadcn/Embla defaults to `"center"`; SaladUI defaults
    to `"start"` so the `pl-4` gutter lines up with the viewport edge.
  * `loop` - When true, next on the last slide wraps to the first (and previous
    on the first wraps to the last). Slides are not cloned, so the wrap scrolls
    back across the track rather than continuing seamlessly.
  * `autoplay` - Advance every N milliseconds (Embla's Autoplay plugin). It
    pauses while the pointer is over the carousel or focus is inside it, and
    stops for good once the user navigates (drag, buttons or keys).

  ## Keyboard

  With focus inside the carousel, Left/Right Arrow go to the previous/next
  slide (flipped when `dir="rtl"`); a vertical carousel also takes Up/Down.
  Arrow keys typed into inputs, textareas and selects are left alone.

  ## RTL

  Set `dir="rtl"` on the carousel; the arrows can be flipped with
  `class="rtl:rotate-180"` on `carousel_previous/1` and `carousel_next/1`.

  ## Component events

  * `:on-select` - Maps the `select` event, with
    `%{"index" => index, "count" => count}` (`index` is zero-based; `count` is
    the number of snap positions, fewer than the slides when several are in
    view). Fired once on mount, then whenever the selected slide or the snap
    count changes (a resize or slides streamed in/out), like shadcn's
    `onSelect` on Embla's `select` and `reInit`. The root also carries
    `data-selected-index` and `data-snap-count` for CSS or client JS.

  ## Server commands

  Send with `SaladUI.LiveView.send_command/4` or `SaladUI.JS.dispatch_command/3`:

  * `"next"` / `"previous"` - Scroll one snap forward/back.
  * `"scroll_to"` - Scroll to `%{index: index}` (zero-based).
  """
  use SaladUI, :component

  # Orientation-specific defaults are scoped with `:where(...)` arbitrary
  # variants: they have zero specificity, so a caller's plain `-ml-1`/`pl-1`
  # (the shadcn way to change the gap) always wins over them.
  @viewport_class "overscroll-contain [scrollbar-width:none] [&::-webkit-scrollbar]:hidden [:where([data-slot=carousel][data-orientation=horizontal]>&)]:snap-x [:where([data-slot=carousel][data-orientation=horizontal]>&)]:snap-mandatory [:where([data-slot=carousel][data-orientation=horizontal]>&)]:overflow-x-auto [:where([data-slot=carousel][data-orientation=horizontal]>&)]:overflow-y-hidden [:where([data-slot=carousel][data-orientation=vertical]>&)]:snap-y [:where([data-slot=carousel][data-orientation=vertical]>&)]:snap-mandatory [:where([data-slot=carousel][data-orientation=vertical]>&)]:overflow-x-hidden [:where([data-slot=carousel][data-orientation=vertical]>&)]:overflow-y-auto"

  @container_class "flex [:where([data-slot=carousel][data-orientation=horizontal]>[data-slot=carousel-content]>&)]:-ml-4 [:where([data-slot=carousel][data-orientation=vertical]>[data-slot=carousel-content]>&)]:-mt-4 [:where([data-slot=carousel][data-orientation=vertical]>[data-slot=carousel-content]>&)]:flex-col"

  @item_class "min-w-0 shrink-0 grow-0 basis-full [:where([data-slot=carousel][data-orientation=horizontal]>[data-slot=carousel-content]>*>&)]:pl-4 [:where([data-slot=carousel][data-orientation=vertical]>[data-slot=carousel-content]>*>&)]:pt-4 [:where([data-slot=carousel][data-align=start]>[data-slot=carousel-content]>*>&)]:snap-start [:where([data-slot=carousel][data-align=center]>[data-slot=carousel-content]>*>&)]:snap-center [:where([data-slot=carousel][data-align=end]>[data-slot=carousel-content]>*>&)]:snap-end"

  @previous_class "absolute size-8 rounded-full [:where([data-slot=carousel][data-orientation=horizontal]_&)]:top-1/2 [:where([data-slot=carousel][data-orientation=horizontal]_&)]:-left-12 [:where([data-slot=carousel][data-orientation=horizontal]_&)]:-translate-y-1/2 [:where([data-slot=carousel][data-orientation=vertical]_&)]:-top-12 [:where([data-slot=carousel][data-orientation=vertical]_&)]:left-1/2 [:where([data-slot=carousel][data-orientation=vertical]_&)]:-translate-x-1/2 [:where([data-slot=carousel][data-orientation=vertical]_&)]:rotate-90"

  @next_class "absolute size-8 rounded-full [:where([data-slot=carousel][data-orientation=horizontal]_&)]:top-1/2 [:where([data-slot=carousel][data-orientation=horizontal]_&)]:-right-12 [:where([data-slot=carousel][data-orientation=horizontal]_&)]:-translate-y-1/2 [:where([data-slot=carousel][data-orientation=vertical]_&)]:-bottom-12 [:where([data-slot=carousel][data-orientation=vertical]_&)]:left-1/2 [:where([data-slot=carousel][data-orientation=vertical]_&)]:-translate-x-1/2 [:where([data-slot=carousel][data-orientation=vertical]_&)]:rotate-90"

  @doc """
  Root of the carousel. Holds the options and wires up the JS component.

  ## Component events

  * `:on-select` - Fired on mount and when the selected slide or snap count changes, with `index` (zero-based) and `count`.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the carousel"

  attr :orientation, :string,
    values: ~w(horizontal vertical),
    default: "horizontal",
    doc: "Scroll axis: horizontal (Left/Right) or vertical (Up/Down)"

  attr :align, :string,
    values: ~w(start center end),
    default: "start",
    doc: "Where a slide snaps inside the viewport"

  attr :loop, :boolean, default: false, doc: "Wrap from the last slide to the first and back"

  attr :autoplay, :integer,
    default: nil,
    doc: "Advance every N milliseconds; pauses on hover/focus and stops once the user navigates"

  attr :"on-select", :any, default: nil, doc: "Handler for the select event (event name or `Phoenix.LiveView.JS`)"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def carousel(assigns) do
    assigns =
      assigns
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(
        :options,
        json(%{
          orientation: assigns.orientation,
          align: assigns.align,
          loop: assigns.loop,
          autoplay: assigns.autoplay
        })
      )

    ~H"""
    <div
      id={@id}
      data-slot="carousel"
      data-component="carousel"
      data-part="root"
      data-state="idle"
      data-orientation={@orientation}
      data-align={@align}
      data-options={@options}
      data-event-mappings={@event_map}
      role="region"
      aria-roledescription="carousel"
      phx-hook="SaladUI"
      class={classes(["relative", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The scrolling viewport and the track that holds the slides.

  `class` goes on the inner track (as in shadcn), so the spacing override
  (`-ml-*` / `-mt-*`) and a vertical carousel's height belong here.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def carousel_content(assigns) do
    assigns =
      assigns
      |> assign(:viewport_class, @viewport_class)
      |> assign(:container_class, @container_class)

    ~H"""
    <div data-slot="carousel-content" data-part="viewport" class={@viewport_class}>
      <div data-part="content" class={classes([@container_class, @class])} {@rest}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  A single slide. Use a `basis-*` class to show more than one slide at a time
  and `pl-*` (`pt-*` when vertical) to change the gap.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def carousel_item(assigns) do
    assigns = assign(assigns, :item_class, @item_class)

    ~H"""
    <div
      data-slot="carousel-item"
      data-part="item"
      role="group"
      aria-roledescription="slide"
      class={classes([@item_class, @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Button that scrolls to the previous slide. Disabled at the first slide unless `loop` is set.
  """
  attr :variant, :string,
    values: ~w(default destructive outline secondary ghost link),
    default: "outline",
    doc: "Button variant"

  attr :size, :string,
    values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg),
    default: "icon",
    doc: "Button size"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "Replaces the default arrow icon and screen-reader label"

  def carousel_previous(assigns) do
    assigns =
      assign(assigns, :button_class, [button_variant(%{variant: assigns.variant, size: assigns.size}), @previous_class])

    ~H"""
    <button
      type="button"
      data-slot="carousel-previous"
      data-part="previous"
      data-variant={@variant}
      data-size={@size}
      class={classes([@button_class, @class])}
      disabled
      {@rest}
    >
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          aria-hidden="true"
        >
          <path d="m12 19-7-7 7-7" /><path d="M19 12H5" />
        </svg>
        <span class="sr-only">Previous slide</span>
      <% end %>
    </button>
    """
  end

  @doc """
  Button that scrolls to the next slide. Disabled at the last slide unless `loop` is set.
  """
  attr :variant, :string,
    values: ~w(default destructive outline secondary ghost link),
    default: "outline",
    doc: "Button variant"

  attr :size, :string,
    values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg),
    default: "icon",
    doc: "Button size"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "Replaces the default arrow icon and screen-reader label"

  def carousel_next(assigns) do
    assigns =
      assign(assigns, :button_class, [button_variant(%{variant: assigns.variant, size: assigns.size}), @next_class])

    ~H"""
    <button
      type="button"
      data-slot="carousel-next"
      data-part="next"
      data-variant={@variant}
      data-size={@size}
      class={classes([@button_class, @class])}
      disabled
      {@rest}
    >
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          aria-hidden="true"
        >
          <path d="M5 12h14" /><path d="m12 5 7 7-7 7" />
        </svg>
        <span class="sr-only">Next slide</span>
      <% end %>
    </button>
    """
  end
end
