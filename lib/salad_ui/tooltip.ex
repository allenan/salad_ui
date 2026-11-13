defmodule SaladUI.Tooltip do
  @moduledoc """
  Implementation of Tooltip component for SaladUI framework.

  Tooltips provide additional information about an element when hovering over it.

  ## Examples:

      <.tooltip id="help-tooltip">
        <.tooltip_trigger>
          <.button variant="ghost" size="icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-help-circle size-4">
              <circle cx="12" cy="12" r="10"></circle>
              <path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path>
              <path d="M12 17h.01"></path>
            </svg>
          </.button>
        </.tooltip_trigger>
        <.tooltip_content side="top" align="center">
          Need help? Click here for more information.
        </.tooltip_content>
      </.tooltip>

  ## Component events

  * `:on-open` - Maps the `open` event. Fired when the tooltip enters open state.
  * `:on-close` - Maps the `close` event. Fired when the tooltip enters closed state.

  Tooltip is a pure client-side interaction (hover/focus driven) and does not
  support `SaladUI.LiveView.send_command/4`.

  ## Re-renders

  A LiveView re-render keeps an open tooltip open and positioned, and a
  pending open or close still runs. Changing the options rebuilds it from the
  new markup.
  """
  use SaladUI, :component

  @doc """
  The main tooltip component that manages state and positioning.

  ## Options

  * `:id` - Required. Unique identifier for the tooltip; its hook needs one
    that stays the same across renders.
  * `:open-delay` - Delay in milliseconds before opening the tooltip. Defaults to `150`.
  * `:close-delay` - Delay in milliseconds before closing the tooltip. Defaults to `100`.
  * `:on-open` - Handler for tooltip open event.
  * `:on-close` - Handler for tooltip close event.
  * `:class` - Additional CSS classes.

  ## Component events

  * `:on-open` - Fired when the tooltip opens.
  * `:on-close` - Fired when the tooltip closes.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the tooltip (the hook needs a stable id)"
  attr :"open-delay", :integer, default: 150, doc: "Delay in milliseconds before opening the tooltip"
  attr :"close-delay", :integer, default: 100, doc: "Delay in milliseconds before closing the tooltip"
  attr :"on-open", :any, default: nil, doc: "Handler for tooltip open event"
  attr :"on-close", :any, default: nil, doc: "Handler for tooltip close event"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tooltip(assigns) do
    # Collect event mappings
    event_map = event_mappings(assigns)

    assigns =
      assigns
      |> assign(:event_map, json(event_map))
      |> assign(
        :options,
        json(%{
          openDelay: assigns[:"open-delay"],
          closeDelay: assigns[:"close-delay"],
          animations: get_animation_config()
        })
      )

    ~H"""
    <div
      data-slot="tooltip"
      id={@id}
      class={classes(["relative inline-block", @class])}
      data-component="tooltip"
      data-state="closed"
      data-event-mappings={@event_map}
      data-options={@options}
      data-part="root"
      phx-hook="SaladUI"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The trigger element that activates the tooltip when hovered.

  If not provided, the first child of the tooltip will be used as trigger.

  Renders a wrapping `<div>` by default. Set `:as` to a tag or function
  component to make that element the trigger itself (shadcn's
  `<TooltipTrigger asChild>`), e.g. so a button inside a `button_group/1`
  is styled as one of the group's buttons:

      <.tooltip id="details-tooltip">
        <.tooltip_trigger as={&button/1} variant="outline" size="icon-sm" aria-label="Details">
          <.icon name="hero-information-circle" />
        </.tooltip_trigger>
        <.tooltip_content>Details</.tooltip_content>
      </.tooltip>
  """
  attr :as, :any, default: "div"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(variant size type)
  slot :inner_block, required: true

  def tooltip_trigger(assigns) do
    assigns = drop_button_props(assigns)

    ~H"""
    <div
      :if={@as == "div"}
      data-slot="tooltip-trigger"
      data-part="trigger"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    <.dynamic
      :if={@as != "div"}
      data-slot={@rest[:"data-slot"] || "tooltip-trigger"}
      tag={@as}
      data-part="trigger"
      class={classes([@class])}
      {Map.delete(@rest, :"data-slot")}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  The tooltip content that appears when triggered.

  ## Options

  * `:side` - Placement of the tooltip relative to the trigger (top, right, bottom, left). Defaults to `"top"`.
  * `:align` - Alignment of the tooltip (start, center, end). Defaults to `"center"`.
    `start`/`end` mirror under `dir="rtl"` for `top`/`bottom` sides.
  * `:side-offset` - Distance from the trigger in pixels. Defaults to `4`.
  * `:align-offset` - Offset along the alignment axis. Defaults to `0`.
  * `:collision-padding` - Distance in pixels kept from the viewport edges when
    the content flips or shifts to stay visible. Defaults to `0`, as in Radix.
  * `:class` - Additional CSS classes.

  The content ends with shadcn's arrow: a rotated `size-2.5` square in the
  content's color, centred on the edge that faces the trigger. It follows
  `data-side`, which the positioner updates when the tooltip flips sides.
  If you change the content's background, recolor the arrow to match, e.g.
  `class="bg-primary [&_[data-slot=tooltip-arrow]>span]:bg-primary"`.
  """
  attr :class, :any, default: nil
  attr :side, :string, values: ~w(top right bottom left), default: "top"
  attr :align, :string, values: ~w(start center end), default: "center"
  attr :"side-offset", :integer, default: 8, doc: "Distance from the trigger in pixels"
  attr :"align-offset", :integer, default: 0, doc: "Offset along the alignment axis"
  attr :"collision-padding", :integer, default: 0, doc: "Distance kept from the viewport edges"
  attr :rest, :global
  slot :inner_block, required: true

  def tooltip_content(assigns) do
    assigns =
      assign(assigns,
        side_offset: assigns[:"side-offset"],
        align_offset: assigns[:"align-offset"],
        collision_padding: assigns[:"collision-padding"]
      )

    ~H"""
    <div
      data-part="content"
      data-slot="tooltip-content"
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      data-align-offset={@align_offset}
      data-collision-padding={@collision_padding}
      class={
        classes([
          "group/tooltip z-50 w-fit animate-in rounded-md bg-foreground px-3 py-1.5 text-xs text-balance text-background fade-in-0 zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95",
          @class
        ])
      }
      hidden
      {@rest}
    >
      {render_slot(@inner_block)}
      <span
        data-slot="tooltip-arrow"
        aria-hidden="true"
        class={[
          "pointer-events-none absolute",
          "group-data-[side=top]/tooltip:top-full group-data-[side=top]/tooltip:left-1/2 group-data-[side=top]/tooltip:-translate-x-1/2",
          "group-data-[side=bottom]/tooltip:bottom-full group-data-[side=bottom]/tooltip:left-1/2 group-data-[side=bottom]/tooltip:-translate-x-1/2 group-data-[side=bottom]/tooltip:rotate-180",
          "group-data-[side=left]/tooltip:top-1/2 group-data-[side=left]/tooltip:left-full group-data-[side=left]/tooltip:-translate-y-1/2 group-data-[side=left]/tooltip:-rotate-90",
          "group-data-[side=right]/tooltip:top-1/2 group-data-[side=right]/tooltip:right-full group-data-[side=right]/tooltip:-translate-y-1/2 group-data-[side=right]/tooltip:rotate-90"
        ]}
      >
        <span class="z-50 block size-2.5 translate-y-[calc(-50%_-_2px)] rotate-45 rounded-[2px] bg-foreground fill-foreground"></span>
      </span>
    </div>
    """
  end

  defp get_animation_config do
    %{
      "open_to_closed" => %{
        duration: 130,
        target_part: "content"
      }
    }
  end
end
