defmodule Storybook.Examples.SharedTooltips do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladStorybookWeb.CoreComponents, only: [icon: 1]
  import SaladUI.Button
  import SaladUI.HoverCard
  import SaladUI.Tooltip

  def doc do
    "Twenty rows with no tooltip or hover card markup of their own: the toolbar buttons are text " <>
      "tooltips (`data-salad-tooltip`, one `tooltip_provider`), each author name opens that " <>
      "author's hover card (one per author), and the status dot opens ONE shared card the server " <>
      "fills from the row's context in `on-open`."
  end

  @authors [
    %{id: 1, name: "Ada Lovelace", handle: "ada", role: "Analyst"},
    %{id: 2, name: "Grace Hopper", handle: "grace", role: "Compiler wrangler"},
    %{id: 3, name: "Alan Turing", handle: "alan", role: "Codebreaker"},
    %{id: 4, name: "Barbara Liskov", handle: "barbara", role: "Abstraction designer"},
    %{id: 5, name: "Edsger Dijkstra", handle: "edsger", role: "Path finder"}
  ]
  @bodies [
    "Pushed the fix for the flaky upload test.",
    "Lunch at noon?",
    "Retro moves to Thursday.",
    "Deploy is green, watching the dashboards.",
    "Who remembers why we pinned that dependency?"
  ]

  @impl true
  def mount(_params, _session, socket) do
    messages =
      for id <- 1..20 do
        %{id: id, author: Enum.at(@authors, rem(id, 5)), body: Enum.at(@bodies, rem(id * 3, 5))}
      end

    {:ok,
     socket
     |> assign(authors: @authors, status: nil)
     |> stream(:messages, messages)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex w-full max-w-xl flex-col gap-3 py-8">
      <div
        id="shared-tooltips-list"
        phx-update="stream"
        class="flex max-h-[28rem] flex-col overflow-y-auto rounded-xl border bg-card"
      >
        <div
          :for={{dom_id, message} <- @streams.messages}
          id={dom_id}
          class="group relative flex items-start gap-3 border-b px-4 py-2 last:border-b-0 hover:bg-muted/50"
        >
          <div class="flex min-w-0 flex-1 flex-col">
            <div class="flex items-center gap-2 text-sm">
              <.hover_card_trigger
                as="button"
                type="button"
                for={"shared-tooltips-author-#{message.author.id}"}
                class="font-medium hover:underline"
              >
                {message.author.name}
              </.hover_card_trigger>
              <.hover_card_trigger
                as="button"
                type="button"
                for="shared-tooltips-status"
                context={%{id: message.id}}
                aria-label="Delivery status"
                class="size-2 rounded-full bg-emerald-500"
              >
                <span class="sr-only">Delivered</span>
              </.hover_card_trigger>
            </div>
            <span class="text-sm">{message.body}</span>
          </div>
          <div class="flex opacity-0 group-hover:opacity-100 focus-within:opacity-100">
            <.button variant="ghost" size="icon-sm" aria-label="Reply" data-salad-tooltip="Reply">
              <.icon name="hero-arrow-uturn-left" />
            </.button>
            <.button
              variant="ghost"
              size="icon-sm"
              aria-label="Add reaction"
              data-salad-tooltip="Add reaction"
            >
              <.icon name="hero-face-smile" />
            </.button>
            <.button
              variant="ghost"
              size="icon-sm"
              aria-label="Pin"
              data-salad-tooltip="Pin to channel"
              data-salad-tooltip-side="left"
            >
              <.icon name="hero-bookmark" />
            </.button>
          </div>
        </div>
      </div>

      <.tooltip_provider id="shared-tooltips-tips" scope="#shared-tooltips-list" />

      <.hover_card :for={author <- @authors} id={"shared-tooltips-author-#{author.id}"}>
        <.hover_card_content side="top" align="start" class="w-60">
          <div class="flex flex-col gap-1">
            <span class="text-sm font-semibold">{author.name}</span>
            <span class="text-xs text-muted-foreground">@{author.handle} · {author.role}</span>
          </div>
        </.hover_card_content>
      </.hover_card>

      <.hover_card id="shared-tooltips-status" on-open="show_status" open-delay={200}>
        <.hover_card_content class="w-56">
          <p id="shared-tooltips-status-text" class="text-sm">{@status}</p>
        </.hover_card_content>
      </.hover_card>
    </div>
    """
  end

  @impl true
  def handle_event("show_status", %{"id" => id}, socket) do
    {:noreply, assign(socket, :status, "Message #{id}: delivered to everyone, read by 3")}
  end

  def handle_event("show_status", _params, socket), do: {:noreply, socket}
end
