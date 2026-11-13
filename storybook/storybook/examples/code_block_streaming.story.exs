defmodule Storybook.Examples.CodeBlockStreaming do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Button
  import SaladUI.CodeBlock

  def doc do
    """
    shadcn's code-block streaming example on a LiveView. Replay clears the blocks and the server
    appends one line per tick (`Process.send_after/3`), re-rendering the block that is being
    written: line numbers, Makeup highlighting, diff and highlighted lines all follow the
    partial code. The copy button stays disabled until a block is complete.
    """
  end

  @blocks [
    %{
      title: "lib/my_app_web/live/search_live.ex",
      language: "elixir",
      line_numbers: true,
      code: ~S"""
      def handle_event("search", %{"query" => query}, socket) do
        if timer = socket.assigns.debounce, do: Process.cancel_timer(timer)
        timer = Process.send_after(self(), {:run_search, query}, 300)

        {:noreply, assign(socket, :debounce, timer)}
      end
      """
    },
    %{
      language: nil,
      code: "mix igniter.install salad_ui"
    },
    %{
      title: "lib/my_app_web/live/search_live.ex",
      language: "elixir",
      line_numbers: true,
      diff: true,
      code: ~S'''
       def render(assigns) do
         ~H"""
      -  <.input name="query" value={@query} phx-change="search" />
      +  <.input name="query" value={@query} phx-change="search" phx-debounce="300" />
      +  <.search_results results={@results} />
         """
       end
      '''
    },
    %{
      title: "lib/my_app_web/router.ex",
      language: "elixir",
      line_numbers: true,
      highlight: [6, 7, 8, 9],
      code: ~S"""
      scope "/", MyAppWeb do
        pipe_through :browser

        live "/", HomeLive

        live_session :chat,
          on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}] do
          live "/chat", ChatLive
        end
      end
      """
    },
    %{
      title: ".env",
      language: nil,
      code: "SECRET_KEY_BASE=your-secret"
    }
  ]

  @tick_ms 90

  @doc false
  def blocks do
    {blocks, _offset} =
      Enum.map_reduce(@blocks, 0, fn block, offset ->
        lines = block.code |> String.trim_trailing("\n") |> String.split("\n")
        {Map.merge(block, %{lines: lines, offset: offset}), offset + length(lines)}
      end)

    blocks
  end

  @doc false
  def total_lines, do: Enum.reduce(blocks(), 0, &(length(&1.lines) + &2))

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, blocks: blocks(), total: total_lines(), shown: total_lines())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex w-full max-w-md flex-col gap-4 py-6">
      <%= for {block, index} <- Enum.with_index(@blocks), @shown > block.offset do %>
        <.streaming_block id={"streaming-#{index}"} block={block} shown={@shown - block.offset} />
      <% end %>
      <.button
        id="code-block-streaming-replay"
        variant="outline"
        size="sm"
        class="self-start"
        disabled={@shown < @total}
        phx-click="replay"
      >
        <Lucideicons.rotate_ccw /> Replay
      </.button>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :block, :map, required: true
  attr :shown, :integer, required: true

  defp streaming_block(assigns) do
    lines = Enum.take(assigns.block.lines, assigns.shown)
    complete? = length(lines) == length(assigns.block.lines)
    # A diff row starts with +, - or a space. The marker is not part of the copied code.
    source =
      if assigns.block[:diff],
        do: Enum.map_join(assigns.block.lines, "\n", &String.slice(&1, 1..-1//1)),
        else: Enum.join(assigns.block.lines, "\n")

    assigns = assign(assigns, code: Enum.join(lines, "\n"), complete?: complete?, source: source)

    ~H"""
    <.code_block id={@id} data-complete={@complete?}>
      <.code_block_header :if={@block[:title]}>
        <.code_block_title>{@block.title}</.code_block_title>
        <.code_block_actions>
          <.code_block_copy_button id={"#{@id}-copy"} value={@source} disabled={not @complete?} />
        </.code_block_actions>
      </.code_block_header>
      <.code_block_content
        code={@code}
        language={@block.language}
        line_numbers={@block[:line_numbers] || false}
        diff={@block[:diff] || false}
        highlight={@block[:highlight] || []}
      />
    </.code_block>
    """
  end

  @impl true
  def handle_event("replay", _params, socket) do
    if socket.assigns.shown >= socket.assigns.total, do: Process.send_after(self(), :tick, @tick_ms)
    {:noreply, assign(socket, :shown, 0)}
  end

  @impl true
  def handle_info(:tick, socket) do
    shown = min(socket.assigns.shown + 1, socket.assigns.total)
    if shown < socket.assigns.total, do: Process.send_after(self(), :tick, @tick_ms)
    {:noreply, assign(socket, :shown, shown)}
  end
end
