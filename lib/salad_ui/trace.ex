defmodule SaladUI.Trace do
  @moduledoc """
  Trace is a list of lines for the steps an agent takes: reasoning, tool
  calls, sources, plans and file edits. Each line has an icon, a title, and an
  optional description and status. A line can expand (built on
  `SaladUI.Collapsible`), link to a page, or open a dialog or sheet.

  Parts: `trace/1`, `trace_line/1`, `trace_icon/1`, `trace_title/1`,
  `trace_description/1`, `trace_collapsible/1`,
  `trace_collapsible_trigger/1`, `trace_collapsible_content/1`.

  Use `SaladUI.Message`/`SaladUI.Bubble` for the agent's reply and
  `SaladUI.Marker` for notes and dividers between turns.

  ## Composition

      trace
      └── trace_line
          ├── trace_icon
          ├── trace_title
          ├── trace_description
          └── trace_icon

      trace
      └── trace_collapsible
          ├── trace_collapsible_trigger
          │   └── trace_line
          └── trace_collapsible_content

  `trace_line/1` is always the line. To make a line do something, wrap it in
  that thing's trigger: a `<a>`, `trace_collapsible_trigger/1`, or a
  `dialog_trigger`/`sheet_trigger` (with `as="button"` so it is focusable).
  `trace/1` styles any trigger or link that wraps a line (focus ring, fit
  width).

  ## Status

  `status` on `trace_line/1` is `"running"` (the title shimmers), `"error"`
  (destructive color) or `"pending"` (dimmed). Status is shown with color and
  motion, so say it in the title too: "Running pnpm build", "Failed to run
  pnpm lint".

  ## Open state

  Rows start closed. `open` starts a row open. Because the server re-renders
  `open` into the row, binding it to an assign makes it controlled (e.g.
  `open={@streaming}` opens a reasoning row while it streams). Control a row
  from the client with `SaladUI.JS.dispatch_command(js, "toggle", to: "#id")`
  or from the server with `SaladUI.LiveView.send_command(socket, id, "open")`,
  and listen with `on-open` / `on-close`.

  ## Accessibility

  Trace adds no roles of its own; each line gets its semantics from what wraps
  it. A bare line is a `span` and is not a tab stop. Inside
  `trace_collapsible_trigger/1` it becomes a button with `aria-expanded`.
  `trace_icon/1` is hidden from assistive tech, so `trace_title/1` is the
  accessible name. When a link opens a new tab, add
  `<span class="sr-only"> (opens in a new tab)</span>` to the title. The
  running shimmer stops when the reader prefers reduced motion.

  ## Examples:

      <.trace>
        <.trace_line>
          <.trace_icon><.icon name="hero-magnifying-glass" /></.trace_icon>
          <.trace_title>Searched for minimumReleaseAge</.trace_title>
        </.trace_line>
        <.trace_line status="running">
          <.trace_icon><.icon name="hero-command-line" /></.trace_icon>
          <.trace_title>Running pnpm build</.trace_title>
          <.trace_description>14s</.trace_description>
        </.trace_line>
      </.trace>

      <.trace_collapsible id="node-version">
        <.trace_collapsible_trigger>
          <.trace_line>
            <.trace_icon><.icon name="hero-command-line" /></.trace_icon>
            <.trace_title>Ran node --version</.trace_title>
          </.trace_line>
        </.trace_collapsible_trigger>
        <.trace_collapsible_content>v24.18.0</.trace_collapsible_content>
      </.trace_collapsible>
  """
  use SaladUI, :component

  @doc """
  A list of rows. Also styles any trigger or link that wraps a `trace_line/1`
  (a direct child, or a grandchild such as a `dialog_trigger` inside a
  `dialog` root).
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def trace(assigns) do
    ~H"""
    <div
      data-slot="trace"
      class={
        classes([
          "flex w-full min-w-0 flex-col gap-2 *:has-[>[data-slot=trace-line]]:flex *:has-[>[data-slot=trace-line]]:w-fit *:has-[>[data-slot=trace-line]]:max-w-full *:has-[>[data-slot=trace-line]]:min-w-0 *:has-[>[data-slot=trace-line]]:rounded-md *:has-[>[data-slot=trace-line]]:text-start *:has-[>[data-slot=trace-line]]:outline-none *:has-[>[data-slot=trace-line]]:focus-visible:ring-3 *:has-[>[data-slot=trace-line]]:focus-visible:ring-ring/50",
          # SaladUI overlays (dialog, sheet) render a root <div>, so their
          # trigger is a grandchild of the trace rather than a child.
          "*:*:has-[>[data-slot=trace-line]]:flex *:*:has-[>[data-slot=trace-line]]:w-fit *:*:has-[>[data-slot=trace-line]]:max-w-full *:*:has-[>[data-slot=trace-line]]:min-w-0 *:*:has-[>[data-slot=trace-line]]:rounded-md *:*:has-[>[data-slot=trace-line]]:text-start *:*:has-[>[data-slot=trace-line]]:cursor-pointer *:*:has-[>[data-slot=trace-line]]:outline-none *:*:has-[>[data-slot=trace-line]]:focus-visible:ring-3 *:*:has-[>[data-slot=trace-line]]:focus-visible:ring-ring/50",
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
  One line: an icon and a title. It is a `span`, so it is not a button or a
  tab stop; wrap it in a trigger or a link to make it do something.

  ## Options

  * `:status` - `"running"`, `"error"` or `"pending"`. Omit for done work.
  * `:class` - Additional CSS classes.
  """
  attr :status, :string, values: [nil, "running", "error", "pending"], default: nil, doc: "the state of the work"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def trace_line(assigns) do
    ~H"""
    <span
      data-slot="trace-line"
      data-status={@status}
      class={
        classes([
          "flex w-fit max-w-full min-w-0 items-center gap-2 text-sm text-muted-foreground transition-colors in-[a,button]:cursor-pointer in-[a:hover,button:hover]:text-foreground data-[status=error]:text-destructive data-[status=error]:in-[a:hover,button:hover]:text-destructive data-[status=pending]:opacity-60 data-[status=running]:*:data-[slot=trace-title]:shimmer",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  A decorative icon slot, hidden from assistive tech. Before the title it
  names the action; after it, it is the indicator (chevron, external link).
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def trace_icon(assigns) do
    ~H"""
    <span
      data-slot="trace-icon"
      aria-hidden="true"
      class={
        classes([
          "flex size-4 shrink-0 items-center justify-center [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 [&>span:not([class*='size-'])]:size-4 [[data-slot=trace-title]~&]:-ms-1",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  One sentence on one line. It truncates, and shimmers while the line is
  running.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def trace_title(assigns) do
    ~H"""
    <span
      data-slot="trace-title"
      class={classes(["min-w-0 truncate motion-reduce:shimmer-none", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Secondary text after the title, such as a diff stat, a duration or a count.
  It does not truncate.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def trace_description(assigns) do
    ~H"""
    <span
      data-slot="trace-description"
      class={classes(["shrink-0 text-muted-foreground/70 tabular-nums", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  A row that expands. Uses the `collapsible` JS component, so it supports the
  same commands (`"open"`, `"close"`, `"toggle"`) and events.

  ## Options

  * `:id` - Required unique identifier.
  * `:open` - Whether the row is open. Defaults to `false`.
  * `:on-open` / `:on-close` - Event handlers (event name or `JS` command).
  * `:class` - Additional CSS classes.
  """
  attr :id, :string, required: true, doc: "unique identifier for the row"
  attr :open, :boolean, default: false, doc: "whether the row is open"
  attr :"on-open", :any, default: nil, doc: "handler for the open event"
  attr :"on-close", :any, default: nil, doc: "handler for the close event"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def trace_collapsible(assigns) do
    assigns =
      assigns
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(:state, if(assigns.open, do: "open", else: "closed"))
      |> assign(:options, json(%{open: assigns.open, animations: animations()}))

    ~H"""
    <div
      id={@id}
      data-slot="trace-collapsible"
      data-component="collapsible"
      data-state={@state}
      data-event-mappings={@event_map}
      data-options={@options}
      data-part="root"
      phx-hook="SaladUI"
      class={classes(["flex w-full min-w-0 flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The button that opens and closes the row. Put a `trace_line/1` inside; a
  chevron is added after it and turns when the row is open.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def trace_collapsible_trigger(assigns) do
    ~H"""
    <button
      type="button"
      data-slot="trace-collapsible-trigger"
      data-part="trigger"
      data-action="toggle"
      aria-expanded="false"
      class={
        classes([
          "group/trace-collapsible-trigger flex w-fit max-w-full min-w-0 cursor-pointer items-center gap-1 rounded-md text-start text-muted-foreground transition-colors outline-none hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/50 has-[[data-status=error]]:text-destructive",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
      <.trace_icon class="transition-transform group-aria-expanded/trace-collapsible-trigger:rotate-90">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="m9 18 6-6-6-6" />
        </svg>
      </.trace_icon>
    </button>
    """
  end

  @doc """
  The detail of a row that expands: output, a nested `trace/1`, badges. Its
  text is muted; give a block with a muted background `text-foreground` to
  keep its contrast. `class` applies to the inner, indented container.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def trace_collapsible_content(assigns) do
    ~H"""
    <div
      data-slot="trace-collapsible-content"
      data-part="content"
      hidden
      class="min-w-0 overflow-hidden transition-all duration-200 ease-in-out"
      {@rest}
    >
      <div
        data-slot="trace-collapsible-content-inner"
        class={
          classes([
            "mt-2 mb-1 ms-[calc(--spacing(2)-1px)] min-w-0 border-s pe-1 ps-4 leading-relaxed wrap-break-word text-muted-foreground",
            @class
          ])
        }
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp animations do
    %{
      "closed_to_open" => %{
        animation: ["ease-out duration-200", "opacity-0", "opacity-100"],
        duration: 200,
        target_part: "content"
      },
      "open_to_closed" => %{
        animation: ["ease-out duration-200", "opacity-100", "opacity-70"],
        duration: 200,
        target_part: "content"
      }
    }
  end
end
