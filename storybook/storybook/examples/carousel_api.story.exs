defmodule Storybook.Examples.CarouselApi do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Carousel

  def doc do
    "shadcn's carousel API example: `on-select` reports the selected slide to the server, which renders \"Slide x of y\". The buttons below drive it with `SaladUI.LiveView.send_command/4`."
  end

  @slides 5

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, current: 1, count: @slides)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-xs px-14 py-8">
      <.carousel id="carousel-api" class="w-full max-w-xs" on-select="carousel_selected">
        <.carousel_content>
          <.carousel_item :for={index <- 1..5}>
            <.card>
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-4xl font-semibold">{index}</span>
              </.card_content>
            </.card>
          </.carousel_item>
        </.carousel_content>
        <.carousel_previous />
        <.carousel_next />
      </.carousel>
      <div class="py-2 text-center text-sm text-muted-foreground">
        Slide {@current} of {@count}
      </div>
      <div class="flex justify-center gap-2">
        <.button variant="outline" size="sm" phx-click="go_first">First</.button>
        <.button variant="outline" size="sm" phx-click="go_last">Last</.button>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("carousel_selected", %{"index" => index, "count" => count}, socket) do
    {:noreply, assign(socket, current: index + 1, count: max(count, 1))}
  end

  def handle_event("go_first", _params, socket) do
    {:noreply, SaladUI.LiveView.send_command(socket, "carousel-api", "scroll_to", %{index: 0})}
  end

  def handle_event("go_last", _params, socket) do
    {:noreply, SaladUI.LiveView.send_command(socket, "carousel-api", "scroll_to", %{index: @slides - 1})}
  end
end
