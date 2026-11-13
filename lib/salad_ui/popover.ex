defmodule SaladUI.Popover do
  @moduledoc """
  Enhanced implementation of popover component from https://ui.shadcn.com/docs/components/popover

  ## Example:

      <.popover id="dimensions-popover">
        <.popover_trigger as={&button/1} variant="outline">Open Popover</.popover_trigger>
        <.popover_content align="start">
          <.popover_header>
            <.popover_title>Dimensions</.popover_title>
            <.popover_description>Set the dimensions for the layer.</.popover_description>
          </.popover_header>
        </.popover_content>
      </.popover>

  ## Anchor

  By default the content is positioned against the trigger. Render a
  `popover_anchor/1` inside the popover to position it against another
  element instead, while the trigger still toggles it:

      <.popover id="anchored-popover">
        <.popover_anchor class="w-64 rounded-md border p-2">Positioned here</.popover_anchor>
        <.popover_trigger>Open</.popover_trigger>
        <.popover_content>Anchored content</.popover_content>
      </.popover>

  ## Component events

  * `:on-open` - Maps the `open` event. Fired when the popover enters open state.
  * `:on-close` - Maps the `close` event. Fired when the popover enters closed state.

  ## Opening from the server

  `open` sets the initial state, and a changed `open` from the server opens or
  closes the popover (as `SaladUI.Dialog` does). Re-rendering the same `open`
  leaves the user's state alone.

  ## Server commands

  * `"open"` / `"close"` / `"toggle"` - via `SaladUI.LiveView.send_command/4`,
    `SaladUI.JS.dispatch_command/3`, or `SaladUI.command/3` from plain JS.
  """
  use SaladUI, :component

  @doc """
  The main popover component that manages state and positioning.

  ## Options

  * `:id` - Required unique identifier for the popover.
  * `:open` - Whether the popover is open. Defaults to `false`. A changed
    value from the server opens or closes it.
  * `:use-portal` - Whether to move content outside its root while open. Defaults to `false`.
  * `:portal-container` - CSS selector for portal target. Used only when `:use-portal` is `true`.
    Content portaled to `document.body` is outside your LiveView, so `phx-click`
    and other `phx-*` bindings inside it don't fire (`on-*` attributes still
    work). To keep them, portal into an element inside the LiveView, e.g.
    `<div id="portal" phx-update="ignore"></div>` and `portal-container="#portal"`.
  * `:on-open` - Handler for popover open event.
  * `:on-close` - Handler for popover close event.
  * `:class` - Additional CSS classes.

  ## Component events

  * `:on-open` - Fired when the popover opens.
  * `:on-close` - Fired when the popover closes.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the popover"
  attr :open, :boolean, default: false, doc: "Whether the popover is open; a changed value opens or closes it"
  attr :"use-portal", :boolean, default: false, doc: "Whether to render the popover in a portal"

  attr :"portal-container", :string,
    default: nil,
    doc: "Portal container selector when use-portal is enabled"

  attr :class, :any, default: nil
  attr :"on-open", :any, default: nil, doc: "Handler for popover open event"
  attr :"on-close", :any, default: nil, doc: "Handler for popover close event"
  attr :rest, :global
  slot :inner_block, required: true

  def popover(assigns) do
    # Collect event mappings
    event_map = event_mappings(assigns)

    assigns =
      assigns
      |> assign(:event_map, Jason.encode!(event_map))
      |> assign(:initial_state, if(assigns.open, do: "open", else: "closed"))
      |> assign(
        :options,
        Jason.encode!(%{
          animations: get_animation_config(),
          usePortal: assigns[:"use-portal"],
          portalContainer: assigns[:"portal-container"]
        })
      )

    ~H"""
    <div
      data-slot="popover"
      id={@id}
      class={classes(["relative inline-block", @class])}
      data-component="popover"
      data-state={@initial_state}
      data-open={to_string(@open)}
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
  The trigger element that toggles the popover.

  Renders a native `<button type="button">` by default. Set `:as` to an
  HTML tag or function component to render another trigger root.
  """
  attr :as, :any, default: "button"
  attr :type, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(variant size)
  slot :inner_block, required: true

  def popover_trigger(assigns) do
    assigns = drop_button_props(assigns)

    assigns =
      if is_function(assigns.as, 1) && is_nil(assigns.type) do
        assign(assigns, :type, "button")
      else
        assigns
      end

    ~H"""
    <button
      :if={@as == "button"}
      data-slot="popover-trigger"
      type={@type || "button"}
      data-part="trigger"
      data-action="toggle"
      class={classes([@class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    <.dynamic
      :if={@as != "button"}
      data-slot={@rest[:"data-slot"] || "popover-trigger"}
      tag={@as}
      type={@type}
      data-part="trigger"
      data-action="toggle"
      class={classes([@class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  The popover content that appears when triggered.

  ## Options

  * `:side` - Placement of the popover relative to the trigger (top, right, bottom, left). Defaults to `"bottom"`.
  * `:align` - Alignment of the popover (start, center, end). Defaults to `"center"`.
    `start`/`end` mirror under `dir="rtl"` for `top`/`bottom` sides.
  * `:side-offset` - Distance from the trigger in pixels. Defaults to `4`, as in shadcn/ui.
  * `:align-offset` - Offset along the alignment axis. Defaults to `0`.
  * `:collision-padding` - Distance in pixels kept from the viewport edges when
    the content flips or shifts to stay visible. Defaults to `0`, as in Radix.
  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :side, :string, values: ~w(top right bottom left), default: "bottom"
  attr :align, :string, values: ~w(start center end), default: "center"
  attr :"side-offset", :integer, default: 4, doc: "Distance from the trigger in pixels"
  attr :"align-offset", :integer, default: 0, doc: "Offset along the alignment axis"
  attr :"collision-padding", :integer, default: 0, doc: "Distance kept from the viewport edges"
  attr :rest, :global
  slot :inner_block, required: true

  def popover_content(assigns) do
    assigns =
      assign(assigns,
        side_offset: assigns[:"side-offset"],
        align_offset: assigns[:"align-offset"],
        collision_padding: assigns[:"collision-padding"]
      )

    ~H"""
    <div
      data-part="positioner"
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      data-align-offset={@align_offset}
      data-collision-padding={@collision_padding}
      class="absolute z-50"
      hidden
    >
      <div
        data-slot="popover-content"
        data-part="content"
        data-side={@side}
        data-align={@align}
        class={
          classes([
            "z-50 w-72 rounded-md border border-border bg-popover p-4 text-popover-foreground shadow-md outline-hidden data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
            @class
          ])
        }
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  An optional element to position the content against instead of the trigger.

  Wraps its inner block in a `div`; at most one anchor per popover is used.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def popover_anchor(assigns) do
    ~H"""
    <div data-slot="popover-anchor" data-part="anchor" class={classes([@class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Groups a `popover_title/1` and `popover_description/1` at the top of the content.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def popover_header(assigns) do
    ~H"""
    <div data-slot="popover-header" class={classes(["flex flex-col gap-1 text-sm", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The popover heading.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def popover_title(assigns) do
    ~H"""
    <div data-slot="popover-title" class={classes(["font-medium", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Supporting text below the popover title.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def popover_description(assigns) do
    ~H"""
    <p data-slot="popover-description" class={classes(["text-muted-foreground", @class])} {@rest}>
      {render_slot(@inner_block)}
    </p>
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
