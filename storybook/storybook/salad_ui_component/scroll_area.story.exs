defmodule Storybook.SaladUIComponents.ScrollArea do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.ScrollArea.scroll_area/1

  def imports, do: [{SaladUI.Separator, [separator: 1]}]

  def variations do
    [
      %Variation{
        id: :scroll_area,
        template: """
        <.scroll_area class="h-72 w-48 rounded-md border border-border">
          <div class="p-4">
            <h4 class="mb-4 text-sm font-medium leading-none">Tags</h4>
            <%= for tag <- 1..50 do %>
              <div class="text-sm">
                v1.2.0-beta.<%= tag %>
              </div>
              <.separator class="my-2" />
            <% end %>
          </div>
        </.scroll_area>
        """
      },
      %Variation{
        id: :horizontal,
        description: ~s|`orientation="horizontal"` (shadcn's `<ScrollBar orientation="horizontal" />`).|,
        template: """
        <.scroll_area orientation="horizontal" class="w-96 rounded-md border whitespace-nowrap">
          <div class="flex w-max space-x-4 p-4">
            <figure
              :for={
                {artist, art} <- [
                  {"Ornella Binni", "https://images.unsplash.com/photo-1465869185982-5a1a7522cbcb?auto=format&fit=crop&w=300&q=80"},
                  {"Tom Byrom", "https://images.unsplash.com/photo-1548516173-3cabfa4607e9?auto=format&fit=crop&w=300&q=80"},
                  {"Vladimir Malyavko", "https://images.unsplash.com/photo-1494337480532-3725c85fd2ab?auto=format&fit=crop&w=300&q=80"}
                ]
              }
              class="shrink-0"
            >
              <div class="overflow-hidden rounded-md">
                <img
                  src={art}
                  alt={"Photo by " <> artist}
                  class="aspect-[3/4] h-fit w-fit object-cover"
                  width="300"
                  height="400"
                />
              </div>
              <figcaption class="pt-2 text-xs text-muted-foreground">
                Photo by <span class="font-semibold text-foreground">{artist}</span>
              </figcaption>
            </figure>
          </div>
        </.scroll_area>
        """
      },
      %Variation{
        id: :both,
        description: ~s|`orientation="both"` scrolls in both directions.|,
        template: """
        <.scroll_area orientation="both" class="h-48 w-72 rounded-md border">
          <div class="w-[40rem] p-4 text-sm">
            <p :for={row <- 1..20} class="whitespace-nowrap">
              Row {row}: a long line of content that is wider than the scroll area viewport.
            </p>
          </div>
        </.scroll_area>
        """
      }
    ]
  end
end
