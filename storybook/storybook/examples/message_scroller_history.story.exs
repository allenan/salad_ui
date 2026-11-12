defmodule Storybook.Examples.MessageScrollerHistory do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Bubble
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Marker
  import SaladUI.Message
  import SaladUI.MessageScroller

  def doc do
    """
    shadcn's load-history and opening-position examples on a LiveView stream. "Load history"
    prepends the earlier messages with `stream_insert(..., at: 0)` and the row you are reading
    stays put. The opening-position buttons remount the scroller with another
    `default_scroll_position`.
    """
  end

  @history [
    {:user, "The deploy finished but error rates jumped on the queue workers. What changed?"},
    {:assistant,
     "The new release raised retry concurrency from 4 to 16. Under load, failed jobs now retry in parallel and saturate the database pool, which surfaces as timeouts on unrelated jobs."},
    {:user, "Should we roll back?"},
    {:assistant,
     "Not yet. Lower retry concurrency back to 4 with the runtime flag first; it takes effect without a deploy and isolates the cause."},
    {:user, "Flag is flipped. Error rate is dropping."},
    {:assistant,
     "Good. Queue depth should recover over the next few minutes as the backlog drains. Watch the oldest pending job age rather than the total count."},
    {:user, "Oldest job is at eight minutes and falling."},
    {:assistant,
     "That's the trend you want. Once it's under two minutes the backlog is effectively clear. Keep the flag at 4 until we add a per-queue limit."},
    {:user, "Can you draft the follow-up ticket?"},
    {:assistant,
     "Title: Cap retry concurrency per queue. Context: global retry concurrency of 16 saturated the database pool during the release. Proposal: per-queue retry limits with a default of 4 and a hard ceiling tied to pool size."},
    {:user, "Is the queue healthy now?"},
    {:assistant,
     "Not yet. Queue depth is recovering after we reduced retry concurrency, and the oldest pending job is now under five minutes old.\n\nKeep rollback ready if the queue starts climbing again, but the current trend points toward recovery."}
  ]

  @initial_visible 5

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(position: "end", generation: 0) |> load_initial()}
  end

  defp messages do
    @history
    |> Enum.with_index(1)
    |> Enum.map(fn {{role, text}, index} -> %{id: "h-#{index}", role: role, text: text} end)
  end

  defp load_initial(socket) do
    visible = Enum.take(messages(), -@initial_visible)
    end_marker = %{id: "h-end", role: :marker, text: "End of Conversation"}

    socket
    |> assign(loaded?: false)
    |> stream(:messages, visible ++ [end_marker], reset: true)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex w-full flex-col gap-4 py-6">
      <.card class="mx-auto h-[35rem] w-full max-w-sm gap-0">
        <.card_header class="gap-1 border-b">
          <.card_title>Load History</.card_title>
          <.card_description>Prepended messages keep your place.</.card_description>
          <.card_action>
            <.button variant="outline" size="sm" phx-click="reset" disabled={not @loaded?}>Reset</.button>
          </.card_action>
        </.card_header>
        <.card_content class="flex-1 overflow-hidden p-0">
          <.message_scroller
            id={"ms-history-#{@generation}"}
            default_scroll_position={@position}
          >
            <.message_scroller_viewport>
              <.message_scroller_content
                id={"ms-history-messages-#{@generation}"}
                phx-update="stream"
                class="p-(--card-spacing)"
              >
                <.message_scroller_item
                  :for={{dom_id, m} <- @streams.messages}
                  id={dom_id}
                  message_id={if m.role != :marker, do: m.id}
                  scroll_anchor={m.role == :user}
                >
                  <%= if m.role == :marker do %>
                    <.marker variant="separator">
                      <.marker_content>{m.text}</.marker_content>
                    </.marker>
                  <% else %>
                    <.message align={if m.role == :user, do: "end", else: "start"}>
                      <.message_content>
                        <.bubble variant={if m.role == :user, do: "muted", else: "ghost"}>
                          <.bubble_content class="space-y-2">
                            <p :for={p <- String.split(m.text, "\n\n")} class="whitespace-pre-wrap">
                              {p}
                            </p>
                          </.bubble_content>
                        </.bubble>
                      </.message_content>
                    </.message>
                  <% end %>
                </.message_scroller_item>
              </.message_scroller_content>
            </.message_scroller_viewport>
            <.message_scroller_button />
          </.message_scroller>
        </.card_content>
        <div class="flex flex-col items-center gap-2 border-t p-4">
          <.button class="w-full" variant="secondary" phx-click="load" disabled={@loaded?}>
            {if @loaded?, do: "History Loaded", else: "Load History"}
          </.button>
          <p class="text-xs text-muted-foreground">
            Restore earlier messages while keeping your place.
          </p>
        </div>
      </.card>

      <div class="mx-auto flex w-full max-w-sm items-center justify-between gap-2 text-sm">
        <span class="text-muted-foreground">Opening position</span>
        <div class="flex gap-1">
          <.button
            :for={position <- ~w(start end last-anchor)}
            size="sm"
            variant={if @position == position, do: "secondary", else: "outline"}
            phx-click="position"
            phx-value-position={position}
          >
            {position}
          </.button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("load", _params, %{assigns: %{loaded?: false}} = socket) do
    earlier = Enum.drop(messages(), -@initial_visible)

    socket =
      earlier
      |> Enum.reverse()
      |> Enum.reduce(socket, fn message, acc -> stream_insert(acc, :messages, message, at: 0) end)

    {:noreply, assign(socket, :loaded?, true)}
  end

  def handle_event("load", _params, socket), do: {:noreply, socket}

  def handle_event("reset", _params, socket), do: {:noreply, load_initial(socket)}

  def handle_event("position", %{"position" => position}, socket) when position in ~w(start end last-anchor) do
    {:noreply,
     socket
     |> assign(position: position, generation: socket.assigns.generation + 1)
     |> load_initial()}
  end
end
