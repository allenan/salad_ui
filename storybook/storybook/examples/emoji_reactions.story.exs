defmodule Storybook.Examples.EmojiReactions do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Button
  import SaladUI.DropZone
  import SaladUI.EmojiPicker

  def doc do
    "One emoji picker for every message: each opener pushes `react` with its message id. " <>
      "Files dragged over the list go to the upload below it."
  end

  @messages [
    %{id: 1, author: "Priya", body: "Shipped the new onboarding flow."},
    %{id: 2, author: "Sam", body: "Retro notes are in the doc, comments welcome."},
    %{id: 3, author: "Lee", body: "Lunch at noon?"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:messages, @messages)
      |> assign(:reactions, %{1 => ["🎉"], 2 => [], 3 => ["👍", "🍜"]})
      |> allow_upload(:files, accept: :any, max_entries: 5, max_file_size: 10_000_000)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex w-full max-w-lg flex-col gap-4 py-8">
      <div id="emoji-reactions-list" class="flex flex-col gap-3 rounded-xl border bg-card p-4">
        <div :for={message <- @messages} class="flex flex-col gap-1.5">
          <p class="text-sm"><span class="font-medium">{message.author}</span> {message.body}</p>
          <div class="flex flex-wrap items-center gap-1">
            <span
              :for={emoji <- @reactions[message.id]}
              class="rounded-full border px-2 py-0.5 text-sm leading-none"
            >
              {emoji}
            </span>
            <.button
              id={"emoji-reactions-add-#{message.id}"}
              variant="ghost"
              size="sm"
              data-emoji-picker="emoji-reactions-picker"
              data-emoji-event="react"
              data-emoji-value-message-id={message.id}
              aria-label={"Add a reaction to #{message.author}'s message"}
            >
              <span aria-hidden="true">😊</span> React
            </.button>
          </div>
        </div>
        <.drop_zone
          id="emoji-reactions-drop"
          for="#emoji-reactions-list"
          input="#emoji-reactions-upload input[type=file]"
          label="Drop files to attach"
          description="Up to 5 files, 10 MB each"
        />
      </div>

      <form
        id="emoji-reactions-upload"
        phx-change="validate"
        phx-submit="validate"
        class="flex flex-col gap-2"
      >
        <.live_file_input upload={@uploads.files} class="text-sm" />
        <ul class="text-sm text-muted-foreground">
          <li :for={entry <- @uploads.files.entries}>{entry.client_name}</li>
        </ul>
      </form>

      <.emoji_picker id="emoji-reactions-picker" />
    </div>
    """
  end

  @impl true
  def handle_event("react", %{"message_id" => id, "emoji" => emoji}, socket) do
    id = String.to_integer(id)

    reactions =
      Map.update(socket.assigns.reactions, id, [emoji], fn list ->
        if emoji in list, do: List.delete(list, emoji), else: list ++ [emoji]
      end)

    {:noreply, assign(socket, :reactions, reactions)}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}
end
