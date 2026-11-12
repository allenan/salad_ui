defmodule SaladStorybookWeb.Blocks.Chat01 do
  @moduledoc """
  A chat block, ported from shadcn/ui's "Simple Chat" preview card: a card
  holding a message scroller, a "Thinking..." marker while a reply is pending,
  a streamed reply, and a prompt input with an attachments menu.

  The conversation is scripted: the prompt is pre-filled with the next user
  message, and each send gets the next canned reply. Replace `reply/2` with a
  call to your model and stream the chunks the same way.
  """
  use SaladStorybookWeb, :demo_view

  import SaladUI.Bubble
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.DropdownMenu
  import SaladUI.Helpers, only: [as_child: 1]
  import SaladUI.InputGroup
  import SaladUI.Marker
  import SaladUI.Message
  import SaladUI.MessageScroller
  import SaladUI.Spinner

  @script [
    {"Write me a haiku about centering a div and how it's done.",
     "One box in the void / Twenty wrappers, still offset / `margin: 0 auto`"},
    {"Is this conversation actually happening? I've been sitting here wondering if you're really reading this.",
     "You're in a preview block. I'm four hardcoded replies and a LiveView. Real enough for the demo; philosophically, we're both props."},
    {"Okay, how do I make my loading spinner feel faster? Tell me in detail about the technique.",
     "Add text that says “Almost there…” and never update it. Users assume progress. Ethically dubious. Statistically effective."},
    {"Can you at least pretend to be surprised?", "\u{1F62E} WOW! I had no idea you would ask that!"}
  ]

  @fallback "This demo only knows the scripted turns. Press + to start a new chat."
  @thinking_ms 1200
  @chunk_ms 30

  @impl true
  def mount(_params, _session, socket) do
    {:ok, new_chat(socket)}
  end

  defp new_chat(socket) do
    socket
    |> assign(turn: 0, status: :ready, pending: nil, draft: next_prompt(0))
    |> stream(:messages, [], reset: true)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-svh w-full justify-center bg-muted p-6 md:p-10">
      <div class="flex w-full max-w-md flex-col justify-center">
        <.card class="max-h-140 min-h-0 flex-1">
          <.card_header>
            <.card_title>What can I help you with today?</.card_title>
            <.card_description>A simple chat example.</.card_description>
            <.card_action>
              <.button variant="outline" size="icon" phx-click="new_chat" disabled={@status != :ready}>
                <Lucideicons.plus />
                <span class="sr-only">New chat</span>
              </.button>
            </.card_action>
          </.card_header>
          <.card_content class="flex-1 overflow-hidden p-0">
            <.message_scroller id="chat-01-scroller">
              <.message_scroller_viewport>
                <.message_scroller_content
                  id="chat-01-messages"
                  phx-update="stream"
                  aria-busy={@status != :ready}
                  class="p-(--card-spacing)"
                >
                  <.message_scroller_item
                    :for={{dom_id, message} <- @streams.messages}
                    id={dom_id}
                    message_id={message.id}
                    scroll_anchor={message.role == :user}
                  >
                    <%= if message.role == :thinking do %>
                      <.marker role="status">
                        <.marker_icon><.spinner /></.marker_icon>
                        <.marker_content>Thinking...</.marker_content>
                      </.marker>
                    <% else %>
                      <.message
                        align={if message.role == :user, do: "end", else: "start"}
                        data-role={message.role}
                      >
                        <.message_content>
                          <.bubble variant={if message.role == :user, do: "default", else: "ghost"}>
                            <.bubble_content>
                              <p class="whitespace-pre-wrap">{message.text}</p>
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
          <.card_footer>
            <.prompt_input value={@draft} status={@status} />
          </.card_footer>
        </.card>
      </div>
    </div>
    """
  end

  attr :value, :string, default: ""
  attr :status, :atom, required: true

  def prompt_input(assigns) do
    ~H"""
    <form id="chat-form" class="w-full" phx-change="draft" phx-submit="send">
      <div data-slot="field-group" class="flex w-full flex-col gap-1">
        <.input_group id="chat-01-prompt">
          <.input_group_textarea
            id="chat-01-input"
            name="prompt"
            value={@value}
            placeholder="Ask me anything..."
            aria-label="Message"
            class="h-10 min-h-10 overflow-y-auto transition-all"
          />
          <.input_group_addon align="block-end" class="p-2">
            <.dropdown_menu id="chat-01-add">
              <.as_child tag={&dropdown_menu_trigger/1} child={&input_group_button/1} size="icon-sm">
                <Lucideicons.plus />
                <span class="sr-only">Add</span>
              </.as_child>
              <.dropdown_menu_content class="w-fit" side="top">
                <.dropdown_menu_group>
                  <.dropdown_menu_item>
                    <Lucideicons.paperclip /> Add Photos and Files
                  </.dropdown_menu_item>
                  <.dropdown_menu_item>
                    <Lucideicons.monitor /> Take a Screenshot
                  </.dropdown_menu_item>
                </.dropdown_menu_group>
                <.dropdown_menu_separator />
                <.dropdown_menu_group>
                  <.dropdown_menu_item>
                    <Lucideicons.image /> Create Image
                  </.dropdown_menu_item>
                  <.dropdown_menu_item>
                    <Lucideicons.brain /> Deep Research
                  </.dropdown_menu_item>
                  <.dropdown_menu_item>
                    <Lucideicons.globe /> Web Search
                  </.dropdown_menu_item>
                </.dropdown_menu_group>
                <.dropdown_menu_separator />
                <.dropdown_menu_group>
                  <.dropdown_menu_sub>
                    <.dropdown_menu_sub_trigger>
                      <Lucideicons.ellipsis /> More
                    </.dropdown_menu_sub_trigger>
                    <.dropdown_menu_sub_content>
                      <.dropdown_menu_item>
                        <Lucideicons.bot /> Agent Mode
                      </.dropdown_menu_item>
                      <.dropdown_menu_item>
                        <Lucideicons.book_open /> Add Sources
                      </.dropdown_menu_item>
                      <.dropdown_menu_item>
                        <Lucideicons.check /> Create Tasks
                      </.dropdown_menu_item>
                    </.dropdown_menu_sub_content>
                  </.dropdown_menu_sub>
                </.dropdown_menu_group>
              </.dropdown_menu_content>
            </.dropdown_menu>
            <.input_group_button
              :if={@status != :streaming}
              variant="default"
              size="icon-sm"
              type="submit"
              disabled={@status != :ready or String.trim(@value) == ""}
              class="ml-auto"
            >
              <Lucideicons.arrow_up />
              <span class="sr-only">Send</span>
            </.input_group_button>
            <.input_group_button
              :if={@status == :streaming}
              variant="default"
              size="icon-sm"
              phx-click="stop"
              class="ml-auto"
            >
              <Lucideicons.square class="fill-current" />
              <span class="sr-only">Stop</span>
            </.input_group_button>
          </.input_group_addon>
        </.input_group>
      </div>
    </form>
    """
  end

  @impl true
  def handle_event("draft", %{"prompt" => prompt}, socket) do
    {:noreply, assign(socket, :draft, prompt)}
  end

  def handle_event("send", %{"prompt" => prompt}, %{assigns: %{status: :ready}} = socket) do
    case String.trim(prompt) do
      "" ->
        {:noreply, socket}

      text ->
        turn = socket.assigns.turn
        user = %{id: "turn-#{turn}-user", role: :user, text: text}
        thinking = %{id: "turn-#{turn}-thinking", role: :thinking, text: ""}
        Process.send_after(self(), {:reply, turn}, @thinking_ms)

        {:noreply,
         socket
         |> assign(status: :submitted, draft: "")
         |> stream_insert(:messages, user)
         |> stream_insert(:messages, thinking)}
    end
  end

  def handle_event("send", _params, socket), do: {:noreply, socket}

  def handle_event("stop", _params, socket), do: {:noreply, finish(socket)}

  def handle_event("new_chat", _params, %{assigns: %{status: :ready}} = socket), do: {:noreply, new_chat(socket)}
  def handle_event("new_chat", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:reply, turn}, %{assigns: %{status: :submitted, turn: turn}} = socket) do
    reply = %{id: "turn-#{turn}-assistant", role: :assistant, text: ""}
    send(self(), {:chunk, turn})

    {:noreply,
     socket
     |> assign(status: :streaming, pending: {reply, String.split(reply(turn), ~r/(?<=\s)/)})
     |> stream_delete(:messages, %{id: "turn-#{turn}-thinking"})
     |> stream_insert(:messages, reply)}
  end

  def handle_info({:chunk, turn}, %{assigns: %{status: :streaming, turn: turn, pending: {reply, [word | rest]}}} = socket) do
    reply = %{reply | text: reply.text <> word}
    Process.send_after(self(), {:chunk, turn}, @chunk_ms)
    {:noreply, socket |> assign(:pending, {reply, rest}) |> stream_insert(:messages, reply)}
  end

  def handle_info({:chunk, turn}, %{assigns: %{status: :streaming, turn: turn}} = socket), do: {:noreply, finish(socket)}

  def handle_info(_message, socket), do: {:noreply, socket}

  defp finish(socket) do
    turn = socket.assigns.turn + 1
    assign(socket, status: :ready, pending: nil, turn: turn, draft: next_prompt(turn))
  end

  defp reply(turn) do
    case Enum.at(@script, turn) do
      {_prompt, reply} -> reply
      nil -> @fallback
    end
  end

  defp next_prompt(turn) do
    case Enum.at(@script, turn) do
      {prompt, _reply} -> prompt
      nil -> ""
    end
  end
end
