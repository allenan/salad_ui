defmodule SaladUI.MessageScroller do
  @moduledoc """
  Implementation of the message scroller component from https://ui.shadcn.com/docs/components/message-scroller

  A chat transcript scroller: it opens saved threads at the right place,
  anchors new turns near the top, follows streamed replies only while the
  reader is at the live edge, keeps the reader's place when history is
  prepended, jumps to any message, and shows a "scroll to latest" button when
  there is something below.

  The server renders the frame and the rows; the `message-scroller` JS
  component (`assets/salad_ui/components/message_scroller.js`) owns the scroll
  behavior. It treats every element child of `message_scroller_content/1` as a
  row, so it works with plain `:for` lists and with `phx-update="stream"`
  inserts at either end (`at: 0` history, `at: -1` new turns, `reset: true`,
  `limit`).

  shadcn splits the headless `MessageScrollerProvider` from the styled
  `MessageScroller` frame. In SaladUI `message_scroller/1` is both: the
  provider props are attributes on it, and controls outside the frame drive it
  with commands (see below) instead of React hooks.

  ## Example

      <div class="flex h-[500px] flex-col">
        <.message_scroller id="chat" auto_scroll>
          <.message_scroller_viewport>
            <.message_scroller_content id="chat-messages" phx-update="stream" aria-busy={@streaming}>
              <.message_scroller_item
                :for={{dom_id, message} <- @streams.messages}
                id={dom_id}
                message_id={message.id}
                scroll_anchor={message.role == :user}
              >
                <.message align={if message.role == :user, do: "end", else: "start"}>
                  <.message_content>
                    <.bubble variant={if message.role == :user, do: "muted", else: "ghost"}>
                      <.bubble_content>{message.text}</.bubble_content>
                    </.bubble>
                  </.message_content>
                </.message>
              </.message_scroller_item>
            </.message_scroller_content>
          </.message_scroller_viewport>
          <.message_scroller_button />
        </.message_scroller>
      </div>

  `message_scroller/1` fills its parent (`size-full`), so put it inside a
  height-constrained container.

  ## Anchoring turns

  Mark the row that starts a turn with `scroll_anchor` (usually the user's
  message, but a marker such as "Marcus joined the chat" works too). When a new
  anchor is appended the viewport moves it near the top, keeping
  `scroll_previous_item_peek` pixels of the previous row visible, and reserves
  room below it so the reply streams into view without pushing the turn away.

  ## Following the live edge

  With `auto_scroll`, streamed content is followed while the reader is at the
  bottom. Wheel, touch, scroll keys or dragging the scrollbar release it; the
  scroll button (or the `scroll_to_end` command) re-engages it. The root and
  viewport carry `data-autoscrolling` while a programmatic scroll to the latest
  message runs.

  ## Opening position

  `default_scroll_position` is applied once, on the first non-empty render:
  `"end"` (default), `"start"`, or `"last-anchor"` (the last anchored turn with
  its reply below; falls back to `"end"` when there is no anchor or the turn
  fits). For `"end"` and `"last-anchor"` the root renders `data-pending-scroll`
  and the viewport stays `invisible` until the position is applied, so a
  server-rendered transcript does not flash at the top. Resetting a stream
  (every row replaced) reopens at the default position.

  ## Loading earlier messages

  Rows prepended above the current transcript (`stream_insert(..., at: 0)`)
  keep the first visible row in place. Give rows a stable `message_id` so
  there is a row to preserve. Set `preserve_scroll_on_prepend={false}` on the
  viewport to opt out.

  ## Commands

  Send with `SaladUI.LiveView.send_command/4` from the server, or
  `SaladUI.JS.dispatch_command/3` from the client (e.g. a jump menu):

  * `"scroll_to_message"` - `%{message_id: id}` plus optional `align`
    (`"start"` default, `"center"`, `"end"`, `"nearest"`), `behavior`
    (`"auto"` default or `"smooth"`) and `scroll_margin`. Queued if no rows
    have rendered yet.
  * `"scroll_to_end"` / `"scroll_to_start"` - optional `behavior`.

      <.button phx-click={
        SaladUI.JS.dispatch_command("scroll_to_message",
          to: "#chat",
          detail: %{message_id: "m-42", behavior: "smooth"}
        )
      }>
        Jump to question
      </.button>

  ## Component events

  * `:on-scrollable-change` - `%{"start" => boolean, "end" => boolean}`: which
    edges the viewport can still scroll toward (`end` stays false while
    following the live edge). For styling prefer the `data-scrollable`
    attribute (`"start"`, `"end"`, `"start end"` or absent) on the root and
    viewport, e.g. `group-data-[scrollable~=end]/message-scroller:...`.
  * `:on-visibility-change` - `%{"current_anchor_id" => id | nil,
    "visible_message_ids" => [id]}`: the anchored turn the reader is in (it
    stays current after its header scrolls away) and the rows on screen, in
    document order. Visibility is only tracked when this event is mapped.

  ## Accessibility

  The viewport is a keyboard-focusable `role="region"` labelled "Messages";
  the content is a `role="log"` live region with `aria-relevant="additions"`
  (pass `aria-busy` while a turn streams to hold announcements). Scroll
  buttons are real buttons with an sr-only label; when there is nothing to
  scroll toward they are `inert`, `tabindex="-1"` and `data-active="false"`.
  """
  use SaladUI, :component

  @button_class "absolute inset-s-1/2 -translate-x-1/2 border-border bg-background text-foreground transition-[translate,scale,opacity] duration-200 hover:bg-muted hover:text-foreground data-[active=false]:pointer-events-none data-[active=false]:scale-95 data-[active=false]:opacity-0 data-[active=false]:duration-400 data-[active=false]:ease-[cubic-bezier(0.7,0,0.84,0)] data-[active=true]:translate-y-0 data-[active=true]:scale-100 data-[active=true]:opacity-100 data-[active=true]:ease-[cubic-bezier(0.23,1,0.32,1)] data-[direction=end]:bottom-4 data-[direction=end]:data-[active=false]:translate-y-full data-[direction=start]:top-4 data-[direction=start]:data-[active=false]:-translate-y-full rtl:translate-x-1/2 data-[direction=start]:[&_svg]:rotate-180"

  @doc """
  The frame and the scroll behavior (shadcn's `MessageScrollerProvider` and
  `MessageScroller` in one). Contains `message_scroller_viewport/1` and any
  `message_scroller_button/1`s.

  ## Component events

  * `:on-scrollable-change` - Fired with `start`/`end` when the edges the viewport can scroll toward change.
  * `:on-visibility-change` - Fired with `current_anchor_id`/`visible_message_ids`; enables visibility tracking.
  """
  attr :id, :string, required: true, doc: "Unique identifier, used to target commands"

  attr :auto_scroll, :boolean,
    default: false,
    doc: "Follow new content only while the reader is already at the live edge"

  attr :default_scroll_position, :string,
    values: ~w(start end last-anchor),
    default: "end",
    doc: "Opening position on the first non-empty render, applied once"

  attr :scroll_edge_threshold, :integer,
    default: 8,
    doc: "Distance from either edge (px) that still counts as being at the start or end"

  attr :scroll_margin, :integer,
    default: 0,
    doc: "Margin (px) on the aligned edge for `scroll_to_message`, visibility and anchored turns"

  attr :scroll_previous_item_peek, :integer,
    default: 64,
    doc: "Extra margin (px) above a newly anchored row so part of the previous row stays visible"

  attr :"on-scrollable-change", :any, default: nil, doc: "Handler for scrollable-edge changes"
  attr :"on-visibility-change", :any, default: nil, doc: "Handler for visibility changes (enables tracking)"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def message_scroller(assigns) do
    assigns =
      assigns
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(:pending_scroll, assigns.default_scroll_position in ~w(end last-anchor))
      |> assign(
        :options,
        json(%{
          autoScroll: assigns.auto_scroll,
          defaultScrollPosition: assigns.default_scroll_position,
          scrollEdgeThreshold: assigns.scroll_edge_threshold,
          scrollMargin: assigns.scroll_margin,
          scrollPreviousItemPeek: assigns.scroll_previous_item_peek
        })
      )

    ~H"""
    <div
      id={@id}
      data-slot="message-scroller"
      data-component="message-scroller"
      data-part="root"
      data-state="idle"
      data-options={@options}
      data-event-mappings={@event_map}
      data-pending-scroll={@pending_scroll}
      phx-hook="SaladUI"
      class={
        classes([
          "group/message-scroller relative flex size-full min-h-0 flex-col overflow-hidden",
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
  The scrollable element. Holds `message_scroller_content/1` and the internal
  tail spacer used to make room below anchored turns.
  """
  attr :preserve_scroll_on_prepend, :boolean,
    default: true,
    doc: "Keep the first visible message row stable when older rows are prepended"

  attr :role, :string, default: "region", doc: "Landmark role for the scrollable transcript"
  attr :"aria-label", :string, default: "Messages", doc: "Accessible name for the transcript"
  attr :tabindex, :any, default: 0, doc: "Makes the viewport keyboard-scrollable"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def message_scroller_viewport(assigns) do
    ~H"""
    <div
      data-slot="message-scroller-viewport"
      data-part="viewport"
      data-preserve-scroll-on-prepend={to_string(@preserve_scroll_on_prepend)}
      role={@role}
      aria-label={assigns[:"aria-label"]}
      tabindex={@tabindex}
      class={
        classes([
          "size-full min-h-0 min-w-0 scroll-fade-b scrollbar-thin scrollbar-gutter-stable overflow-y-auto overscroll-contain contain-content data-autoscrolling:scrollbar-none data-pending-scroll:invisible group-data-pending-scroll/message-scroller:invisible",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
      <div data-part="spacer" data-message-scroller-spacer aria-hidden="true" hidden></div>
    </div>
    """
  end

  @doc """
  The transcript container: a `role="log"` live region. Every direct child
  should be a `message_scroller_item/1`. Pass `phx-update="stream"` (with an
  `id`) to render a LiveView stream, and `aria-busy` while a turn streams.
  """
  attr :role, :string, default: "log", doc: "ARIA role for live announcements"
  attr :"aria-relevant", :string, default: "additions", doc: "Live-region updates to announce"

  attr :"aria-busy", :any,
    default: nil,
    doc: ~s(Marks the live region busy while a turn streams; booleans render as "true"/"false")

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(aria-live)
  slot :inner_block

  def message_scroller_content(assigns) do
    busy = assigns[:"aria-busy"]
    assigns = assign(assigns, :busy, if(is_nil(busy), do: nil, else: to_string(busy)))

    ~H"""
    <div
      data-slot="message-scroller-content"
      data-part="content"
      role={@role}
      aria-relevant={assigns[:"aria-relevant"]}
      aria-busy={@busy}
      class={classes(["flex h-max min-h-full flex-col gap-8", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  One transcript row: a message, marker, typing indicator, separator or
  "load earlier" row. Rendered items stay in the DOM but skip off-screen
  rendering work (`content-visibility: auto`).
  """
  attr :message_id, :string,
    default: nil,
    doc: "Stable row id for `scroll_to_message`, visibility and prepend preservation"

  attr :scroll_anchor, :boolean,
    default: false,
    doc: "Marks the row that starts a turn; a newly appended anchor settles near the top"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def message_scroller_item(assigns) do
    ~H"""
    <div
      data-slot="message-scroller-item"
      data-message-id={@message_id}
      data-scroll-anchor={to_string(@scroll_anchor)}
      class={
        classes([
          "min-w-0 shrink-0 [contain-intrinsic-size:auto_10rem] [content-visibility:auto]",
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
  Scrolls to the start or end of the transcript. Hidden and inert until there
  is content in its direction. Defaults to an arrow icon with an sr-only label.
  """
  attr :direction, :string, values: ~w(start end), default: "end", doc: "Transcript edge to scroll toward"

  attr :behavior, :string,
    values: ~w(smooth auto instant),
    default: "smooth",
    doc: "Native scroll behavior used when clicked"

  attr :variant, :string,
    values: ~w(default destructive outline secondary ghost link),
    default: "secondary",
    doc: "Button variant"

  attr :size, :string,
    values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg),
    default: "icon-sm",
    doc: "Button size"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "Replaces the default arrow icon and screen-reader label"

  def message_scroller_button(assigns) do
    assigns =
      assign(assigns, :button_class, [button_variant(%{variant: assigns.variant, size: assigns.size}), @button_class])

    ~H"""
    <button
      type="button"
      data-slot="message-scroller-button"
      data-part="scroll-button"
      data-direction={@direction}
      data-behavior={@behavior}
      data-variant={@variant}
      data-size={@size}
      data-active="false"
      inert
      tabindex="-1"
      class={classes([@button_class, @class])}
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
          <path d="M12 5v14" /><path d="m19 12-7 7-7-7" />
        </svg>
        <span class="sr-only">{if @direction == "end", do: "Scroll to end", else: "Scroll to start"}</span>
      <% end %>
    </button>
    """
  end
end
