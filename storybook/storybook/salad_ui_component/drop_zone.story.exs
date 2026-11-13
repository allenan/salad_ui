defmodule Storybook.SaladUIComponents.DropZone do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.DropZone

  def function, do: &DropZone.drop_zone/1

  def variations do
    [
      %Variation{
        id: :default,
        description:
          "Drag files from your desktop over the card: the overlay covers it while they are over " <>
            "it. With `input` set, dropped files go to that `live_file_input` (see Examples > " <>
            "Emoji reactions and uploads).",
        template: """
        <div
          id="drop-zone-default-region"
          class="flex h-64 w-full max-w-md items-center justify-center rounded-xl border bg-card p-6 text-center text-sm text-muted-foreground"
        >
          Drag files over this card.
          <.drop_zone
            id="drop-zone-default"
            for="#drop-zone-default-region"
            label="Drop files to attach"
            description="Up to 5 files, 10 MB each"
          />
        </div>
        """
      },
      %Variation{
        id: :parent_region,
        description: "Without `for`, the region is the overlay's parent.",
        template: """
        <div class="flex h-48 w-full max-w-md items-center justify-center rounded-xl border border-dashed p-6 text-sm text-muted-foreground">
          The parent is the drop region.
          <.drop_zone id="drop-zone-parent" label="Drop to upload" />
        </div>
        """
      }
    ]
  end
end
