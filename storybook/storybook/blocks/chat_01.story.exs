defmodule Storybook.Blocks.Chat01 do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  def doc do
    "A chat block ported from shadcn/ui's Simple Chat card: a message scroller, a Thinking... marker while the reply is pending, a streamed reply with a stop button, and a prompt input with an attachments menu. The prompt is pre-filled with the next scripted message; press send."
  end

  def extra_sources, do: ["../../lib/salad_storybook_web/blocks/chat_01.ex"]

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <SaladStorybookWeb.Blocks.preview slug="chat-01" />
    """
  end
end
