defmodule Storybook.Examples.CodeBlockMarkdown do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Bubble
  import SaladUI.Button
  import SaladUI.CodeBlock
  import SaladUI.Message

  def doc do
    """
    shadcn's code-block markdown example on a LiveView. The assistant's reply streams in from the
    server as markdown; fenced code renders as a `code_block` (titled with its language) and
    inline code stays inline. The reply sits in a `typeset` container, so paragraphs get their
    rhythm while the code block keeps its own styles. The copy button stays disabled until the
    closing fence arrives.
    """
  end

  @question "How do I debounce a search input in LiveView?"

  @response ~S'''
  Add `phx-debounce` to the input. LiveView waits until typing stops for that many milliseconds before it sends the `phx-change` event.

  ```heex
  <.form for={@form} phx-change="search">
    <.input field={@form[:query]} phx-debounce="300" />
  </.form>
  ```

  Then run the query in `handle_event/3` with the debounced value instead of on every keystroke.
  '''

  @chunk_ms 30

  @doc false
  def response, do: @response

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, question: @question, text: @response, pending: [])}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, blocks: parse(assigns.text), busy?: assigns.pending != [])

    ~H"""
    <div class="flex min-h-112 w-full max-w-md flex-col gap-4 py-6 text-sm">
      <.message align="end">
        <.message_content>
          <.bubble align="end" variant="muted">
            <.bubble_content>{@question}</.bubble_content>
          </.bubble>
        </.message_content>
      </.message>
      <.message :if={@text != ""}>
        <.message_content>
          <div id="code-block-markdown-reply" class="typeset [--typeset-flow:1em]">
            <%= for {block, index} <- Enum.with_index(@blocks) do %>
              <%= case block do %>
                <% {:paragraph, parts} -> %>
                  <p><.inline parts={parts} /></p>
                <% {:code, language, code, complete?} -> %>
                  <.code_block id={"markdown-code-#{index}"}>
                    <.code_block_header>
                      <.code_block_title>{language || "text"}</.code_block_title>
                      <.code_block_actions>
                        <.code_block_copy_button
                          id={"markdown-code-#{index}-copy"}
                          value={code}
                          disabled={not complete?}
                        />
                      </.code_block_actions>
                    </.code_block_header>
                    <.code_block_content code={code} language={language} />
                  </.code_block>
              <% end %>
            <% end %>
          </div>
        </.message_content>
      </.message>
      <.button
        :if={not @busy?}
        id="code-block-markdown-replay"
        variant="outline"
        size="sm"
        class="mt-auto self-start"
        phx-click="replay"
      >
        Replay
      </.button>
    </div>
    """
  end

  attr :parts, :list, required: true

  defp inline(assigns) do
    ~H"<%= for part <- @parts do %>
  <%= case part do %>
    <% {:code, text} -> %>
      <code>{text}</code>
    <% text -> %>
      {text}
  <% end %>
<% end %>"
  end

  @impl true
  def handle_event("replay", _params, %{assigns: %{pending: []}} = socket) do
    Process.send_after(self(), :chunk, @chunk_ms)
    {:noreply, assign(socket, text: "", pending: String.split(@response, ~r/(?<=\s)/))}
  end

  def handle_event("replay", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_info(:chunk, %{assigns: %{pending: [word | rest]}} = socket) do
    if rest != [], do: Process.send_after(self(), :chunk, @chunk_ms)
    {:noreply, assign(socket, text: socket.assigns.text <> word, pending: rest)}
  end

  def handle_info(:chunk, socket), do: {:noreply, socket}

  @doc """
  A small streaming-safe markdown reader: blank-line separated paragraphs with
  inline code, and fenced code blocks. A fence whose closing line has not
  arrived yet is returned as incomplete, so the copy button can wait for it.
  """
  def parse(text) do
    {blocks, paragraph, fence} =
      text |> String.split("\n") |> Enum.reduce({[], [], nil}, &step/2)

    blocks = flush(blocks, paragraph)

    blocks =
      case fence do
        nil -> blocks
        {language, lines} -> [{:code, language, join(lines), false} | blocks]
      end

    Enum.reverse(blocks)
  end

  defp step(line, {blocks, paragraph, nil}) do
    cond do
      String.starts_with?(line, "```") -> {flush(blocks, paragraph), [], {language(line), []}}
      String.trim(line) == "" -> {flush(blocks, paragraph), [], nil}
      true -> {blocks, [line | paragraph], nil}
    end
  end

  defp step(line, {blocks, [], {language, lines}}) do
    if String.trim(line) == "```",
      do: {[{:code, language, join(lines), true} | blocks], [], nil},
      else: {blocks, [], {language, [line | lines]}}
  end

  defp language("```" <> rest) do
    case String.trim(rest) do
      "" -> nil
      language -> language
    end
  end

  defp join(reversed_lines), do: reversed_lines |> Enum.reverse() |> Enum.join("\n")

  defp flush(blocks, []), do: blocks

  defp flush(blocks, paragraph),
    do: [{:paragraph, paragraph |> join() |> String.replace("\n", " ") |> inline_parts()} | blocks]

  # Odd segments between backticks are inline code; an unclosed one streams as code too.
  defp inline_parts(text) do
    text
    |> String.split("`")
    |> Enum.with_index()
    |> Enum.map(fn {part, index} -> if rem(index, 2) == 1, do: {:code, part}, else: part end)
    |> Enum.reject(&(&1 == ""))
  end
end
