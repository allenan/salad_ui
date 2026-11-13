defmodule SaladUI.Resizable do
  @moduledoc """
  Accessible resizable panel groups and layouts with keyboard support.

  A port of shadcn/ui's `Resizable` (built on `react-resizable-panels`). A
  `resizable_panel_group/1` lays its `resizable_panel/1` children out in a row
  (or a column) and every `resizable_handle/1` between two panels can be
  dragged with a pointer or moved with the keyboard to resize them.

  Sizes are percentages of the group. Each panel accepts `default-size`,
  `min-size` and `max-size` (numbers like `25` or strings like `"25%"`);
  panels without a `default-size` share whatever space is left.

  Groups nest: put another `resizable_panel_group/1` inside a panel. Every
  group needs its own unique `id`.

  ## Examples:

      <.resizable_panel_group id="demo" orientation="horizontal" class="max-w-md rounded-lg border">
        <.resizable_panel default-size="50%">
          <div class="flex h-[200px] items-center justify-center p-6">
            <span class="font-semibold">One</span>
          </div>
        </.resizable_panel>
        <.resizable_handle />
        <.resizable_panel default-size="50%">
          <.resizable_panel_group id="demo-nested" orientation="vertical">
            <.resizable_panel default-size="25%">
              <div class="flex h-full items-center justify-center p-6">
                <span class="font-semibold">Two</span>
              </div>
            </.resizable_panel>
            <.resizable_handle />
            <.resizable_panel default-size="75%">
              <div class="flex h-full items-center justify-center p-6">
                <span class="font-semibold">Three</span>
              </div>
            </.resizable_panel>
          </.resizable_panel_group>
        </.resizable_panel>
      </.resizable_panel_group>

      <.resizable_panel_group id="sidebar-layout" auto-save-id="sidebar-layout" class="min-h-[200px] rounded-lg border">
        <.resizable_panel default-size={25} min-size={15} max-size={40}>Sidebar</.resizable_panel>
        <.resizable_handle with_handle />
        <.resizable_panel default-size={75}>Content</.resizable_panel>
      </.resizable_panel_group>

  ## Keyboard interactions

  A focused handle responds to:

  * `ArrowLeft` / `ArrowRight` (horizontal groups) or `ArrowUp` / `ArrowDown`
    (vertical groups) - resize by `keyboard-resize-by` percent.
  * `Home` / `End` - shrink / grow the panel before the handle as far as the
    constraints allow.
  * `Enter` - collapse the panel before the handle, or expand it to its
    `min-size`, when it is `collapsible`.
  * `F6` / `Shift+F6` - move focus to the next / previous handle in the group.

  ## Collapsible panels

  As in react-resizable-panels, a `collapsible` panel can shrink below its
  `min-size` to its `collapsed-size` (default 0): dragged past halfway between
  the two it snaps closed, otherwise it stays at `min-size`. A collapsed panel
  gets `data-collapsed`. The arrow keys collapse a panel at its min size and
  expand a collapsed one to its min size in one step.

      <.resizable_panel_group id="layout" auto-save-id="layout">
        <.resizable_panel default-size={75}>Main</.resizable_panel>
        <.resizable_handle />
        <.resizable_panel id="side-pane" default-size={25} min-size={15} collapsible>
          Side
        </.resizable_panel>
      </.resizable_panel_group>

  `collapse` and `expand` commands take the panel's `id` (or its index) as
  `panel`. `expand` restores the size the panel had before it collapsed (by
  `collapse`, a drag or the keyboard), else its `default-size`, else its
  `min-size`:

      SaladUI.LiveView.send_command(socket, "layout", "collapse", %{panel: "side-pane"})

  A panel collapsed to size 0 is `inert`: its content leaves the tab order and
  the accessibility tree until it expands (focus inside it moves to the
  adjacent handle). A panel with a `collapsed-size` above 0, such as an icon
  rail, stays interactive.

  ### Collapsed from the first paint

  The JS restores a layout when it mounts, after the first paint. To render a
  panel collapsed from the start, keep its state on the server and pass it as
  `collapsed`: the panel is rendered at its `collapsed-size`, with
  `data-collapsed` (and `inert` at size 0). When the server changes
  `collapsed`, the panel collapses or expands. The user can still drag or
  press Enter, and the group reports each change with `on-collapse` /
  `on-expand`, so the server can keep its state in step:

      <.resizable_panel_group
        id="layout"
        auto-save-id="layout"
        on-collapse="side_pane"
        on-expand="side_pane"
      >
        <.resizable_panel default-size={75}>Main</.resizable_panel>
        <.resizable_handle />
        <.resizable_panel
          id="side-pane"
          default-size={25}
          min-size={15}
          collapsible
          collapsed={@side_collapsed}
        >
          Side
        </.resizable_panel>
      </.resizable_panel_group>

      def handle_event("side_pane", %{"collapsed" => collapsed}, socket) do
        {:noreply, assign(socket, :side_collapsed, collapsed)}
      end

  Where the state lives is up to the app: the session or the database, or a
  cookie read in `mount/3` (react-resizable-panels recommends a cookie for
  server rendering). A button that toggles the panel can change the assign, or
  send `collapse` / `expand` commands. With `auto-save-id`, the size to expand
  back to is stored with the layout, so it survives reloads.

  ## Styling at a breakpoint

  A panel's size is the inline custom property `--panel-size`, read by the
  panel's `flex-[var(--panel-size,1)_1_0px]` class, so ordinary CSS overrides
  it without `!important`. For example, one full-width panel at a time on
  small screens:

      @media (max-width: 1023px) {
        #layout > [data-slot="resizable-panel"] { flex: 1 1 auto; }
      }

  ## Component events

  * `:on-layout-change` - Maps the `layout-change` event. Fired when a drag
    ends or a keyboard resize happens, with `%{"layout" => [sizes...]}`.
  * `:on-collapse` / `:on-expand` - Map the `collapse` / `expand` events.
    Fired when a collapsible panel collapses or expands by a drag, the
    keyboard or a command (not when it follows its `collapsed` attribute),
    with `%{"panel" => id, "index" => index, "collapsed" => boolean,
    "layout" => [sizes...]}`.

  ## Server commands

  * `"setLayout"` - Sets the layout. Requires a `:layout` param: a list of
    percentages, one per panel (e.g. `%{layout: [30, 70]}`).
  * `"collapse"` / `"expand"` - Collapse or expand a `collapsible` panel.
    Requires a `:panel` param: the panel's `id` (or its index).
  """
  use SaladUI, :component

  @doc """
  Renders a group of resizable panels.

  ## Options

  * `:id` - Required unique identifier for the group.
  * `:orientation` - `"horizontal"` (default, panels side by side) or
    `"vertical"` (panels stacked).
  * `:direction` - Alias for `:orientation` (the name used by shadcn/ui before
    react-resizable-panels v4).
  * `:auto-save-id` - When set, the layout is persisted to `localStorage`
    under this key.
  * `:keyboard-resize-by` - Percentage moved per arrow-key press (default 10).
  * `:disabled` - Disables resizing for every handle in the group.
  * `:on-layout-change` - Handler for the `layout-change` event.
  * `:on-collapse` / `:on-expand` - Handlers for the `collapse` / `expand`
    events (see "Collapsed from the first paint").
  * `:class` - Additional CSS classes.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the panel group"

  attr :orientation, :string,
    values: ~w(horizontal vertical),
    default: "horizontal",
    doc: "Layout axis of the panels"

  attr :direction, :string,
    values: [nil | ~w(horizontal vertical)],
    default: nil,
    doc: "Alias for orientation (shadcn/ui v3 name); wins when set"

  attr :"auto-save-id", :string, default: nil, doc: "localStorage key used to persist the layout"
  attr :"keyboard-resize-by", :any, default: 10, doc: "Percentage moved per arrow-key press"
  attr :disabled, :boolean, default: false, doc: "Whether resizing is disabled"
  attr :"on-layout-change", :any, default: nil, doc: "Handler for the layout-change event"
  attr :"on-collapse", :any, default: nil, doc: "Handler for the collapse event"
  attr :"on-expand", :any, default: nil, doc: "Handler for the expand event"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def resizable_panel_group(assigns) do
    orientation = assigns.direction || assigns.orientation

    options = %{
      orientation: orientation,
      autoSaveId: assigns[:"auto-save-id"],
      keyboardResizeBy: parse_size(assigns[:"keyboard-resize-by"]),
      disabled: assigns.disabled
    }

    assigns =
      assigns
      |> assign(:orientation, orientation)
      |> assign(:options, json(options))
      |> assign(:event_map, json(event_mappings(assigns)))

    ~H"""
    <div
      id={@id}
      data-slot="resizable-panel-group"
      data-component="resizable"
      data-part="root"
      data-state="idle"
      data-orientation={@orientation}
      data-disabled={@disabled}
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      class={classes(["flex h-full w-full data-[orientation=vertical]:flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a single resizable panel. Must be a child of `resizable_panel_group/1`.

  ## Options

  * `:id` - Optional id; when present, adjacent handles reference it with
    `aria-controls`.
  * `:default-size` - Initial size in percent (`50` or `"50%"`).
  * `:min-size` - Minimum size in percent (default 0).
  * `:max-size` - Maximum size in percent (default 100).
  * `:collapsible` - Whether the panel can collapse below `min-size` to
    `collapsed-size` (see "Collapsible panels").
  * `:collapsed-size` - Size in percent of the collapsed panel (default 0).
  * `:collapsed` - The server's collapsed state for a `collapsible` panel
    (see "Collapsed from the first paint"). `nil` (default) leaves it to the
    client.
  * `:class` - Additional CSS classes.
  """
  attr :id, :string, default: nil
  attr :"default-size", :any, default: nil, doc: "Initial size in percent, e.g. 50 or \"50%\""
  attr :"min-size", :any, default: nil, doc: "Minimum size in percent"
  attr :"max-size", :any, default: nil, doc: "Maximum size in percent"
  attr :collapsible, :boolean, default: false, doc: "Whether the panel can collapse below its min size"
  attr :"collapsed-size", :any, default: nil, doc: "Size in percent when collapsed (default 0)"

  attr :collapsed, :boolean,
    default: nil,
    doc: "Server-controlled collapsed state of a collapsible panel; nil leaves it to the client"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def resizable_panel(assigns) do
    default_size = parse_size(assigns[:"default-size"])
    collapsed_size = parse_size(assigns[:"collapsed-size"])
    collapsed = assigns.collapsed

    if is_boolean(collapsed) and !assigns.collapsible do
      raise ArgumentError, "SaladUI.Resizable: `collapsed` needs a `collapsible` panel"
    end

    # Pre-JS approximation of the layout (flex-grow ratios); the JS component
    # takes over on mount. A collapsed panel starts at its collapsed size, so
    # it does not show for a moment before the JS collapses it.
    size = if collapsed, do: collapsed_size || 0, else: default_size || 1

    assigns =
      assigns
      |> assign(:default_size, default_size)
      |> assign(:min_size, parse_size(assigns[:"min-size"]))
      |> assign(:max_size, parse_size(assigns[:"max-size"]))
      |> assign(:collapsed_size, collapsed_size)
      |> assign(:server_collapsed, if(is_boolean(collapsed), do: to_string(collapsed)))
      |> assign(:inert, collapsed == true and (collapsed_size || 0) == 0)
      |> assign(:style, "--panel-size: #{size};")

    ~H"""
    <div
      id={@id}
      data-slot="resizable-panel"
      data-part="panel"
      data-default-size={@default_size}
      data-min-size={@min_size}
      data-max-size={@max_size}
      data-collapsible={@collapsible && "true"}
      data-collapsed-size={@collapsed_size}
      data-server-collapsed={@server_collapsed}
      data-collapsed={@collapsed == true}
      inert={@inert}
      style={@style}
      class={
        classes([
          # The size is a custom property read by a class, not an inline flex,
          # so app CSS can override it (e.g. at a breakpoint). `overflow: clip`,
          # not hidden: a hidden panel is a scroll container, so focusing an
          # input inside it (iOS Safari, scrollIntoView) can scroll the panel
          # itself, and nothing lets the user scroll it back. A clipped panel
          # is not a scroll container, so its min size is its content's:
          # min-w-0/min-h-0 let it shrink to its size (and to 0 collapsed).
          "flex-[var(--panel-size,1)_1_0px] overflow-clip min-h-0 min-w-0",
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
  Renders the handle between two panels. Must be a child of
  `resizable_panel_group/1`, placed between two `resizable_panel/1`s.

  ## Options

  * `:with_handle` - Show a visible grip in the middle of the handle.
  * `:disabled` - Disables this handle.
  * `:class` - Additional CSS classes.
  """
  attr :with_handle, :boolean, default: false, doc: "Show a visible grip"
  attr :disabled, :boolean, default: false, doc: "Whether this handle is disabled"
  attr :class, :any, default: nil
  attr :rest, :global

  def resizable_handle(assigns) do
    ~H"""
    <div
      data-slot="resizable-handle"
      data-part="handle"
      role="separator"
      tabindex={if @disabled, do: "-1", else: "0"}
      data-disabled={@disabled}
      class={
        classes([
          "relative flex w-px items-center justify-center bg-border after:absolute after:inset-y-0 after:left-1/2 after:w-1 after:-translate-x-1/2 focus-visible:ring-1 focus-visible:ring-ring focus-visible:ring-offset-1 focus-visible:outline-hidden aria-[orientation=horizontal]:h-px aria-[orientation=horizontal]:w-full aria-[orientation=horizontal]:after:left-0 aria-[orientation=horizontal]:after:h-1 aria-[orientation=horizontal]:after:w-full aria-[orientation=horizontal]:after:translate-x-0 aria-[orientation=horizontal]:after:-translate-y-1/2 [&[aria-orientation=horizontal]>div]:rotate-90",
          "cursor-col-resize touch-none select-none aria-[orientation=horizontal]:cursor-row-resize aria-disabled:cursor-default",
          @class
        ])
      }
      {@rest}
    >
      <div
        :if={@with_handle}
        class="z-10 flex h-4 w-3 items-center justify-center rounded-xs border bg-border"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="lucide lucide-grip-vertical size-2.5"
          aria-hidden="true"
        >
          <circle cx="9" cy="12" r="1" /><circle cx="9" cy="5" r="1" /><circle cx="9" cy="19" r="1" />
          <circle cx="15" cy="12" r="1" /><circle cx="15" cy="5" r="1" /><circle
            cx="15"
            cy="19"
            r="1"
          />
        </svg>
      </div>
    </div>
    """
  end

  # Sizes are percentages: accept 25, 25.5, "25" or "25%".
  defp parse_size(nil), do: nil
  defp parse_size(size) when is_integer(size), do: size
  defp parse_size(size) when is_float(size), do: normalize_number(size)

  defp parse_size(size) when is_binary(size) do
    trimmed = size |> String.trim() |> String.trim_trailing("%") |> String.trim()

    case Float.parse(trimmed) do
      {number, ""} ->
        normalize_number(number)

      _ ->
        raise ArgumentError,
              "SaladUI.Resizable sizes are percentages (e.g. 25 or \"25%\"), got: #{inspect(size)}"
    end
  end

  defp normalize_number(number) when number == trunc(number), do: trunc(number)
  defp normalize_number(number), do: number
end
