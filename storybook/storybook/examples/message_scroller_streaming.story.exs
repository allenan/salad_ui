defmodule Storybook.Examples.MessageScrollerStreaming do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Bubble
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Message
  import SaladUI.MessageScroller

  def doc do
    """
    shadcn's streaming, anchoring, previous-context and animation examples on a LiveView stream.
    Send appends the next scripted user message (`stream_insert/3`) and streams the reply in
    chunks by re-inserting the same row. Toggle auto-scroll, the anchored role and the peek,
    then send; scroll away mid-stream and the button takes you back.
    """
  end

  @script [
    {"I'm building a chat for our app and the scroll behavior is driving me nuts. Every time the AI streams a reply, the whole thread jumps around.",
     "That's the classic streaming scroll problem. Wrap your message list in a message scroller and turn on auto_scroll: the viewport follows the bottom as tokens arrive, so readers see the latest text land in place.\n\nThe important part: it only follows while the reader is already at the bottom. The moment they scroll up to read something earlier, it backs off and their position is preserved."},
    {"Okay, but when someone sends a new message the view still feels jarring, like the whole conversation reloads from the top.",
     "Turn anchoring fixes that. Set scroll_anchor on the row that starts a turn and it settles near the top instead of snapping to the document bottom.\n\nIt also leaves a small peek of the previous exchange visible above the anchor, so context isn't lost. The reply starts in view without the disorienting jump of a plain overflow container."},
    {"And if they've scrolled up to re-read an older answer? I don't want to yank them back down.",
     "You won't. Following only runs when the viewport is already at the bottom, so scrolling up is a deliberate opt-out: their place stays put even as new tokens keep arriving below.\n\nWhen there is content they haven't seen yet, the scroll button appears at the bottom of the viewport. One tap jumps them back to the newest message and re-engages auto-scroll."},
    {"Last one: does this work with assistive tech?",
     ~s(The content is a role="log" live region with aria-relevant="additions", so new rows are announced, and aria-busy holds announcements while a reply streams.\n\nThe scroll button is a real button with an sr-only label, and it's removed from the tab order when you're already at the bottom: no ghost focus stops.)}
  ]

  @chunk_ms 30

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(auto_scroll: true, anchor_role: :user, peek: 64, animate: true)
     |> reset_conversation()}
  end

  defp reset_conversation(socket) do
    socket
    |> assign(turn: 0, streaming: nil, empty?: true)
    |> stream(:messages, [], reset: true)
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :next, Enum.at(script(), assigns.turn))

    ~H"""
    <div class="flex w-full flex-col gap-4 py-6">
      <.card class="mx-auto h-[35rem] w-full max-w-sm gap-0">
        <.card_header class="gap-1 border-b">
          <.card_title>Streaming Messages</.card_title>
          <.card_description>Auto-scroll follows the live edge.</.card_description>
          <.card_action>
            <.button
              variant="outline"
              size="sm"
              phx-click="reset"
              disabled={@empty? or not is_nil(@streaming)}
            >
              Reset
            </.button>
          </.card_action>
        </.card_header>
        <.card_content class="relative flex-1 overflow-hidden p-0">
          <div
            :if={@empty?}
            class="absolute inset-0 flex items-center justify-center p-6 text-center text-sm text-muted-foreground"
          >
            Press send to stream a scripted conversation.
          </div>
          <.message_scroller
            id="ms-streaming"
            auto_scroll={@auto_scroll}
            scroll_previous_item_peek={@peek}
          >
            <.message_scroller_viewport>
              <.message_scroller_content
                id="ms-streaming-messages"
                phx-update="stream"
                aria-busy={not is_nil(@streaming)}
                class="p-(--card-spacing)"
              >
                <.message_scroller_item
                  :for={{dom_id, m} <- @streams.messages}
                  id={dom_id}
                  message_id={m.id}
                  scroll_anchor={m.role == @anchor_role}
                  class={
                    if @animate and m.role == :user,
                      do:
                        "motion-safe:animate-in motion-safe:fade-in motion-safe:slide-in-from-bottom-2 motion-safe:duration-300"
                  }
                >
                  <.message align={if m.role == :user, do: "end", else: "start"}>
                    <.message_content>
                      <.bubble variant={if m.role == :user, do: "muted", else: "ghost"}>
                        <.bubble_content class="space-y-2">
                          <p :for={p <- paragraphs(m.text)} class="whitespace-pre-wrap">{p}</p>
                        </.bubble_content>
                      </.bubble>
                    </.message_content>
                  </.message>
                </.message_scroller_item>
              </.message_scroller_content>
            </.message_scroller_viewport>
            <.message_scroller_button />
          </.message_scroller>
        </.card_content>
        <div class="flex flex-col gap-3 border-t p-4">
          <p class="line-clamp-2 min-h-10 text-sm">
            <%= if @next do %>
              {elem(@next, 0)}
            <% else %>
              <span class="text-muted-foreground">No messages queued. Reset the conversation.</span>
            <% end %>
          </p>
          <.button phx-click="send" disabled={is_nil(@next) or not is_nil(@streaming)}>Send</.button>
        </div>
      </.card>

      <div class="mx-auto flex w-full max-w-sm flex-col gap-3 text-sm">
        <div class="flex items-center justify-between gap-2">
          <span class="text-muted-foreground">Auto-scroll</span>
          <.button
            size="sm"
            variant={if @auto_scroll, do: "secondary", else: "outline"}
            phx-click="toggle_auto_scroll"
          >
            {if @auto_scroll, do: "On", else: "Off"}
          </.button>
        </div>
        <div class="flex items-center justify-between gap-2">
          <span class="text-muted-foreground">Anchor (resets)</span>
          <div class="flex gap-1">
            <.button
              :for={role <- [:user, :assistant]}
              size="sm"
              variant={if @anchor_role == role, do: "secondary", else: "outline"}
              phx-click="anchor"
              phx-value-role={role}
            >
              {if role == :user, do: "User", else: "Assistant"}
            </.button>
          </div>
        </div>
        <div class="flex items-center justify-between gap-2">
          <span class="text-muted-foreground">Previous item peek</span>
          <div class="flex gap-1">
            <.button
              :for={peek <- [0, 32, 64, 128]}
              size="sm"
              variant={if @peek == peek, do: "secondary", else: "outline"}
              phx-click="peek"
              phx-value-peek={peek}
            >
              {peek}px
            </.button>
          </div>
        </div>
        <div class="flex items-center justify-between gap-2">
          <span class="text-muted-foreground">Animate sent messages</span>
          <.button
            size="sm"
            variant={if @animate, do: "secondary", else: "outline"}
            phx-click="toggle_animate"
          >
            {if @animate, do: "On", else: "Off"}
          </.button>
        </div>
      </div>
    </div>
    """
  end

  defp script, do: @script

  defp paragraphs(text) do
    text |> String.split(~r/\n\s*\n/) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
  end

  @impl true
  def handle_event("send", _params, %{assigns: %{streaming: nil}} = socket) do
    case Enum.at(script(), socket.assigns.turn) do
      nil ->
        {:noreply, socket}

      {question, answer} ->
        turn = socket.assigns.turn
        user = %{id: "turn-#{turn}-user", role: :user, text: question}
        reply = %{id: "turn-#{turn}-reply", role: :assistant, text: ""}
        Process.send_after(self(), :chunk, 400)

        {:noreply,
         socket
         |> assign(turn: turn + 1, streaming: {reply, String.split(answer, ~r/(?<=\s)/)}, empty?: false)
         |> stream_insert(:messages, user)}
    end
  end

  def handle_event("send", _params, socket), do: {:noreply, socket}

  def handle_event("reset", _params, socket), do: {:noreply, reset_conversation(socket)}

  def handle_event("toggle_auto_scroll", _params, socket),
    do: {:noreply, assign(socket, :auto_scroll, !socket.assigns.auto_scroll)}

  def handle_event("toggle_animate", _params, socket), do: {:noreply, assign(socket, :animate, !socket.assigns.animate)}

  def handle_event("anchor", %{"role" => role}, %{assigns: %{streaming: nil}} = socket) do
    role = if role == "assistant", do: :assistant, else: :user
    {:noreply, socket |> assign(:anchor_role, role) |> reset_conversation()}
  end

  def handle_event("anchor", _params, socket), do: {:noreply, socket}

  def handle_event("peek", %{"peek" => peek}, socket), do: {:noreply, assign(socket, :peek, String.to_integer(peek))}

  @impl true
  def handle_info(:chunk, %{assigns: %{streaming: {reply, [word | rest]}}} = socket) do
    reply = %{reply | text: reply.text <> word}
    Process.send_after(self(), :chunk, @chunk_ms)
    {:noreply, socket |> assign(:streaming, {reply, rest}) |> stream_insert(:messages, reply)}
  end

  def handle_info(:chunk, socket), do: {:noreply, assign(socket, :streaming, nil)}
end
