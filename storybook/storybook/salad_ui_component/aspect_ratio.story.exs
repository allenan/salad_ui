defmodule Storybook.SaladUIComponents.AspectRatio do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.AspectRatio

  def function, do: &AspectRatio.aspect_ratio/1

  def variations do
    [
      %Variation{
        id: :demo,
        description: "`ratio={16 / 9}`",
        template: """
        <div class="w-full max-w-md">
          <.aspect_ratio ratio={16 / 9} class="rounded-lg bg-muted">
            <img
              src="https://images.unsplash.com/photo-1588345921523-c2dcdb7f1dcd?w=800&dpr=2&q=80"
              alt="Photo by Drew Beamer"
              class="h-full w-full rounded-lg object-cover dark:brightness-[0.2] dark:grayscale"
            />
          </.aspect_ratio>
        </div>
        """
      },
      %Variation{
        id: :square,
        description: "`ratio={1}`",
        template: """
        <div class="w-full max-w-[12rem]">
          <.aspect_ratio ratio={1} class="rounded-lg bg-muted">
            <img
              src="https://images.unsplash.com/photo-1588345921523-c2dcdb7f1dcd?w=800&dpr=2&q=80"
              alt="Photo by Drew Beamer"
              class="h-full w-full rounded-lg object-cover dark:brightness-[0.2] dark:grayscale"
            />
          </.aspect_ratio>
        </div>
        """
      },
      %Variation{
        id: :portrait,
        description: ~s|`ratio="9/16"` (strings like `"4:3"` work too).|,
        template: """
        <div class="w-full max-w-[10rem]">
          <.aspect_ratio ratio="9/16" class="rounded-lg bg-muted">
            <img
              src="https://images.unsplash.com/photo-1588345921523-c2dcdb7f1dcd?w=800&dpr=2&q=80"
              alt="Photo by Drew Beamer"
              class="h-full w-full rounded-lg object-cover dark:brightness-[0.2] dark:grayscale"
            />
          </.aspect_ratio>
        </div>
        """
      }
    ]
  end
end
