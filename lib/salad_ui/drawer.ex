defmodule SaladUI.Drawer do
  @moduledoc """
  Implementation of the Drawer component from https://ui.shadcn.com/docs/components/drawer

  A drawer is a modal panel that slides in from an edge of the screen, in the
  style of [vaul](https://vaul.emilkowal.ski). Users can drag it back toward
  its edge to dismiss it, and it can rest at intermediate snap points.

  Open/close, focus trapping, Escape and overlay click behave like `dialog/1`.

  ## Examples

      <.drawer id="goal-drawer">
        <.drawer_trigger>
          <.button variant="outline">Open Drawer</.button>
        </.drawer_trigger>
        <.drawer_content>
          <div class="mx-auto w-full max-w-sm">
            <.drawer_header>
              <.drawer_title>Move Goal</.drawer_title>
              <.drawer_description>Set your daily activity goal.</.drawer_description>
            </.drawer_header>
            <div class="p-4 pb-0">...</div>
            <.drawer_footer>
              <.button>Submit</.button>
              <.drawer_close>
                <.button variant="outline" class="w-full">Cancel</.button>
              </.drawer_close>
            </.drawer_footer>
          </div>
        </.drawer_content>
      </.drawer>

  ### Sides

  Set `direction` on `drawer/1` to `"top"`, `"right"`, `"bottom"` (default)
  or `"left"`. The drag handle is only shown for bottom drawers.

      <.drawer id="settings-drawer" direction="right">
        ...
      </.drawer>

  ### Snap points

  `snap_points` lists the positions the drawer can rest at, smallest first.
  Each is a fraction of the viewport (`0.5`) or a pixel string (`"148px"`).
  Give the content a fixed height so it can be pulled up between them.

      <.drawer id="sheet" snap_points={["148px", "355px", 1]} active_snap_point="355px">
        <.drawer_trigger><.button>Open</.button></.drawer_trigger>
        <.drawer_content class="h-full max-h-[97%]">...</.drawer_content>
      </.drawer>

  ## Dragging

  The drawer follows the pointer when dragged toward its edge. Releasing it
  more than a quarter of the way out, or flicking it, closes it; otherwise it
  settles back (or to the nearest snap point). Form fields and anything marked
  `data-vaul-no-drag` never start a drag, and scrollable content scrolls
  before the drawer moves. Pass `handle_only` to drag by the handle only.

  ## Re-renders

  A LiveView re-render (a form inside the drawer validating, a flash) keeps an
  open drawer open, at its snap point and with focus where it was. Changing
  the rendered `open` value opens or closes it; changing other options
  rebuilds it from the new markup.

  ## Modal behaviour

  Like vaul's, a drawer is modal by default (`modal={true}`): while it is
  open, clicks outside it never reach the page (a click outside only closes
  the drawer through its overlay), everything outside it is `aria-hidden`,
  and wheel and touch scrolling outside it are cancelled. Pass
  `modal={false}` for a non-modal drawer: no overlay, the page stays
  interactive and scrollable. See "Modal behaviour" in `SaladUI.Dialog`.

  ## Scroll lock

  As with vaul, an open drawer locks page scrolling and pads `<body>` by the
  scrollbar's width so the page does not shift. The lock is shared with
  dialogs and sheets and counted, so nested modals unlock the page only once
  the last one has closed. Fixed-position elements can opt out of the shift
  with the `right-scroll-bar-position` and `width-before-scroll-bar` classes.
  See `SaladUI.Dialog` for details.

  ## Component events

  * `:on-open` - Fired when the drawer opens.
  * `:on-close` - Fired when the drawer closes.
  * `:on-snap-point-change` - Fired when the drawer settles at a different snap
    point; the payload carries `index` and `snapPoint`.

  ## Server commands

  Use `SaladUI.LiveView.send_command(socket, id, command, params)` with:

  * `"open"` - Opens the drawer.
  * `"close"` - Closes the drawer.
  * `"snap_to"` - Moves an open drawer to a snap point, given `%{index: n}` or
    `%{snap_point: value}`.
  """
  use SaladUI, :component

  @doc """
  The drawer root. It holds the state and options shared by its parts.

  ## Options

  * `:id` - Required unique identifier.
  * `:open` - Whether the drawer starts open. Defaults to `false`.
  * `:direction` - Edge the drawer slides from: `top`, `right`, `bottom` or `left`. Defaults to `"bottom"`.
  * `:snap_points` - Resting positions, smallest first: fractions of the viewport or `"<n>px"` strings.
  * `:active_snap_point` - The snap point to open at. Defaults to the first one.
  * `:dismissible` - When `false`, dragging, Escape and overlay clicks cannot close it. Defaults to `true`.
  * `:handle_only` - Only the handle starts a drag. Defaults to `false`.
  * `:"close-on-outside-click"` - Whether an overlay click closes it. Defaults to `true`.
  * `:modal` - Whether it blocks, hides and scroll-locks the page while open. Defaults to `true`.
  * `:on-open`, `:on-close`, `:on-snap-point-change` - Event handlers: a server event name or `%Phoenix.LiveView.JS{}`.
  """
  attr :id, :string, required: true
  attr :open, :boolean, default: false, doc: "whether the drawer starts open"

  attr :direction, :string,
    values: ~w(top right bottom left),
    default: "bottom",
    doc: "the edge the drawer slides in from"

  attr :snap_points, :list,
    default: [],
    doc: ~s|resting positions, smallest first: viewport fractions (0.5) or pixel strings ("148px")|

  attr :active_snap_point, :any, default: nil, doc: "the snap point to open at; defaults to the first"
  attr :dismissible, :boolean, default: true, doc: "whether drag, Escape and overlay click can close it"
  attr :handle_only, :boolean, default: false, doc: "only the handle starts a drag"
  attr :"close-on-outside-click", :boolean, default: true, doc: "whether an overlay click closes it"

  attr :modal, :boolean,
    default: true,
    doc: "block, hide and scroll-lock the page while open; `false` makes a non-modal drawer"

  attr :class, :string, default: nil

  attr :"on-open", :any, default: nil, doc: "handler for the open event (server event name or JS command)"
  attr :"on-close", :any, default: nil, doc: "handler for the close event (server event name or JS command)"

  attr :"on-snap-point-change", :any,
    default: nil,
    doc: "handler fired when the drawer settles at another snap point"

  attr :rest, :global
  slot :inner_block, required: true

  def drawer(assigns) do
    assigns =
      assigns
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(
        :options,
        json(%{
          direction: assigns.direction,
          snapPoints: assigns.snap_points,
          activeSnapPoint: assigns.active_snap_point,
          dismissible: assigns.dismissible,
          handleOnly: assigns.handle_only,
          closeOnEscape: assigns.dismissible,
          closeOnOutsideClick: assigns.dismissible && assigns[:"close-on-outside-click"],
          modal: assigns.modal,
          animations: %{"open_to_closed" => %{duration: 500, target_part: "content"}}
        })
      )

    ~H"""
    <div
      data-slot="drawer"
      id={@id}
      class={classes(["", @class])}
      data-component="drawer"
      data-vaul-drawer-direction={@direction}
      data-options={@options}
      data-open={to_string(@open)}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      data-part="root"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Opens the drawer when clicked. Wrap a `button/1` in it, the equivalent of
  shadcn's `<DrawerTrigger asChild>`, or render it as a tag with `as`.
  """
  attr :class, :string, default: nil
  attr :as, :any, default: "div", doc: "the tag (or function component) to render"
  attr :rest, :global, include: ~w(variant size)
  slot :inner_block, required: true

  def drawer_trigger(assigns) do
    assigns = drop_button_props(assigns)

    ~H"""
    <.dynamic
      data-slot={@rest[:"data-slot"] || "drawer-trigger"}
      data-part="trigger"
      data-action="open"
      tag={@as}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  The drawer panel with its overlay and drag handle.

  Classes keyed on `data-vaul-drawer-direction` (e.g.
  `data-[vaul-drawer-direction=bottom]:max-h-[50vh]`) work as in shadcn: the
  direction is copied onto the panel from `drawer/1`.
  """
  attr :class, :string, default: nil
  attr :rest, :global, doc: "extra attributes for the panel, e.g. `dir=\"rtl\"`"
  slot :inner_block, required: true

  def drawer_content(assigns) do
    ~H"""
    <div data-slot="drawer-portal" data-part="content" tabindex="0" hidden>
      <div
        data-slot="drawer-overlay"
        data-part="overlay"
        class="fixed inset-0 z-50 bg-black/50 duration-500 data-[state=closed]:animate-out data-[state=closed]:fill-mode-forwards data-[state=closed]:fade-out-0 data-[state=open]:animate-in data-[state=open]:fade-in-0"
      />
      <div
        data-slot="drawer-content"
        data-part="content-panel"
        class={
          classes([
            "group/drawer-content fixed z-50 flex h-auto touch-none flex-col bg-background outline-none",
            "duration-500 ease-[cubic-bezier(0.32,0.72,0,1)] data-[state=closed]:animate-out data-[state=closed]:fill-mode-forwards data-[state=open]:animate-in",
            "data-[vaul-drawer-direction=top]:inset-x-0 data-[vaul-drawer-direction=top]:top-0 data-[vaul-drawer-direction=top]:mb-24 data-[vaul-drawer-direction=top]:max-h-[80vh] data-[vaul-drawer-direction=top]:rounded-b-lg data-[vaul-drawer-direction=top]:border-b data-[vaul-drawer-direction=top]:data-[state=open]:slide-in-from-top data-[vaul-drawer-direction=top]:data-[state=closed]:slide-out-to-top",
            "data-[vaul-drawer-direction=bottom]:inset-x-0 data-[vaul-drawer-direction=bottom]:bottom-0 data-[vaul-drawer-direction=bottom]:mt-24 data-[vaul-drawer-direction=bottom]:max-h-[80vh] data-[vaul-drawer-direction=bottom]:rounded-t-lg data-[vaul-drawer-direction=bottom]:border-t data-[vaul-drawer-direction=bottom]:data-[state=open]:slide-in-from-bottom data-[vaul-drawer-direction=bottom]:data-[state=closed]:slide-out-to-bottom",
            "data-[vaul-drawer-direction=right]:inset-y-0 data-[vaul-drawer-direction=right]:right-0 data-[vaul-drawer-direction=right]:w-3/4 data-[vaul-drawer-direction=right]:border-l data-[vaul-drawer-direction=right]:sm:max-w-sm data-[vaul-drawer-direction=right]:data-[state=open]:slide-in-from-right data-[vaul-drawer-direction=right]:data-[state=closed]:slide-out-to-right",
            "data-[vaul-drawer-direction=left]:inset-y-0 data-[vaul-drawer-direction=left]:left-0 data-[vaul-drawer-direction=left]:w-3/4 data-[vaul-drawer-direction=left]:border-r data-[vaul-drawer-direction=left]:sm:max-w-sm data-[vaul-drawer-direction=left]:data-[state=open]:slide-in-from-left data-[vaul-drawer-direction=left]:data-[state=closed]:slide-out-to-left",
            @class
          ])
        }
        {@rest}
      >
        <div
          data-slot="drawer-handle"
          data-part="handle"
          aria-hidden="true"
          class="mx-auto mt-4 hidden h-2 w-[100px] shrink-0 cursor-grab rounded-full bg-muted group-data-[vaul-drawer-direction=bottom]/drawer-content:block"
        />
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Groups the title and description. Centered for top and bottom drawers on
  small screens.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def drawer_header(assigns) do
    ~H"""
    <div
      data-slot="drawer-header"
      class={
        classes([
          "flex flex-col gap-0.5 p-4 group-data-[vaul-drawer-direction=bottom]/drawer-content:text-center group-data-[vaul-drawer-direction=top]/drawer-content:text-center md:gap-1.5 md:text-start",
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
  Holds the drawer's actions, pinned to the bottom of the panel.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def drawer_footer(assigns) do
    ~H"""
    <div
      data-slot="drawer-footer"
      class={classes(["mt-auto flex flex-col gap-2 p-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The drawer's accessible name (`aria-labelledby` of the panel).
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def drawer_title(assigns) do
    ~H"""
    <h2
      data-slot="drawer-title"
      data-part="title"
      class={classes(["font-semibold text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h2>
    """
  end

  @doc """
  The drawer's accessible description (`aria-describedby` of the panel).
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def drawer_description(assigns) do
    ~H"""
    <p
      data-slot="drawer-description"
      data-part="description"
      class={classes(["text-sm text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Closes the drawer when clicked. Wrap any element (usually a `button/1`) in
  it, the equivalent of shadcn's `<DrawerClose asChild>`.

  ## Examples

      <.drawer_close>
        <.button variant="outline" class="w-full">Cancel</.button>
      </.drawer_close>
  """
  attr :class, :string, default: nil
  attr :as, :any, default: "div", doc: "the tag (or function component) to render"
  attr :rest, :global, include: ~w(variant size)
  slot :inner_block, required: true

  def drawer_close(assigns) do
    assigns = drop_button_props(assigns)

    ~H"""
    <.dynamic
      data-slot={@rest[:"data-slot"] || "drawer-close"}
      data-part="close"
      data-action="close"
      tag={@as}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end
end
