defmodule Storybook.SaladUIComponents.Marker do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Marker

  def function, do: &Marker.marker/1
  def layout, do: :one_column

  def imports,
    do: [
      {Marker, [marker_icon: 1, marker_content: 1]},
      {SaladUI.Spinner, [spinner: 1]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :demo,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.marker>
            <.marker_icon><.icon name="hero-arrows-right-left" class="size-4" /></.marker_icon>
            <.marker_content>Switched to a new branch</.marker_content>
          </.marker>
          <.marker role="status">
            <.marker_icon><.spinner /></.marker_icon>
            <.marker_content class="shimmer">Thinking...</.marker_content>
          </.marker>
          <.marker variant="separator">
            <.marker_content>Conversation compacted</.marker_content>
          </.marker>
          <.marker>
            <.marker_icon><.icon name="hero-magnifying-glass" class="size-4" /></.marker_icon>
            <.marker_content>Explored 4 files</.marker_content>
          </.marker>
        </div>
        """
      },
      %Variation{
        id: :variants,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.marker>
            <.marker_content>A default marker for inline notes.</.marker_content>
          </.marker>
          <.marker variant="separator">
            <.marker_content>A separator marker</.marker_content>
          </.marker>
          <.marker variant="border">
            <.marker_content>A border marker for row boundaries.</.marker_content>
          </.marker>
        </div>
        """
      },
      %Variation{
        id: :status,
        description: "Give a marker that reports ongoing work `role=\"status\"`.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.marker role="status">
            <.marker_icon><.spinner /></.marker_icon>
            <.marker_content>Compacting conversation</.marker_content>
          </.marker>
          <.marker variant="separator" role="status">
            <.marker_icon><.spinner /></.marker_icon>
            <.marker_content>Running tests</.marker_content>
          </.marker>
        </div>
        """
      },
      %Variation{
        id: :shimmer,
        description: "The `shimmer` utility ships in `salad_ui.css`.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.marker role="status">
            <.marker_content class="shimmer">Thinking...</.marker_content>
          </.marker>
          <.marker variant="separator" role="status">
            <.marker_content class="shimmer">Reading 4 files</.marker_content>
          </.marker>
        </div>
        """
      },
      %Variation{
        id: :separator,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.marker variant="separator">
            <.marker_content>Today</.marker_content>
          </.marker>
          <.marker variant="separator">
            <.marker_content>Worked for 42s</.marker_content>
          </.marker>
          <.marker variant="separator">
            <.marker_content>Conversation compacted</.marker_content>
          </.marker>
        </div>
        """
      },
      %Variation{
        id: :border,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-3 py-12">
          <.marker variant="border">
            <.marker_icon><.icon name="hero-arrows-right-left" class="size-4" /></.marker_icon>
            <.marker_content>Switched to release-candidate</.marker_content>
          </.marker>
          <.marker variant="border">
            <.marker_icon><.icon name="hero-magnifying-glass" class="size-4" /></.marker_icon>
            <.marker_content>Reviewed 8 related files</.marker_content>
          </.marker>
          <.marker variant="border">
            <.marker_icon><.icon name="hero-document-text" class="size-4" /></.marker_icon>
            <.marker_content>Opened implementation notes</.marker_content>
          </.marker>
        </div>
        """
      },
      %Variation{
        id: :icon,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-12 py-12">
          <.marker>
            <.marker_icon><.icon name="hero-arrows-right-left" class="size-4" /></.marker_icon>
            <.marker_content>Switched to a new branch</.marker_content>
          </.marker>
          <.marker variant="separator">
            <.marker_icon><.icon name="hero-magnifying-glass" class="size-4" /></.marker_icon>
            <.marker_content>Explored 4 files</.marker_content>
          </.marker>
          <.marker class="flex-col">
            <.marker_icon><.icon name="hero-book-open" class="size-4" /></.marker_icon>
            <.marker_content>Syncing completed</.marker_content>
          </.marker>
        </div>
        """
      },
      %Variation{
        id: :link_button,
        description: "`as=\"a\"` and `as=\"button\"` render the marker as a link or button.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.marker as="a" href="#links-and-buttons">
            <.marker_icon><.icon name="hero-arrows-right-left" class="size-4" /></.marker_icon>
            <.marker_content>View the pull request</.marker_content>
          </.marker>
          <.marker as="button" class="transition-colors hover:text-foreground">
            <.marker_icon><.icon name="hero-arrow-uturn-left" class="size-4" /></.marker_icon>
            <.marker_content>Revert this change</.marker_content>
          </.marker>
        </div>
        """
      }
    ]
  end
end
