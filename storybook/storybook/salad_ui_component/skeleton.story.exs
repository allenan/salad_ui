defmodule Storybook.SaladUIComponents.Skeleton do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Skeleton.skeleton/1

  def variations do
    [
      %Variation{
        id: :skeleton,
        template: """
        <div class="flex items-center space-x-4">
          <.skeleton class="size-12 rounded-full" />
          <div class="space-y-2">
            <.skeleton class="h-4 w-[250px]" />
            <.skeleton class="h-4 w-[200px]" />
          </div>
        </div>
        """
      },
      %Variation{
        id: :skeleton_card,
        template: """
        <div class="space-y-2 w-full">
          <.skeleton class="h-32 w-full rounded-lg" />
          <.skeleton class="h-4 w-2/3" />
          <.skeleton class="h-4 w-full" />
          <.skeleton class="h-4 w-full" />
        </div>
        """
      },
      %Variation{
        id: :avatar,
        description: "shadcn skeleton-avatar.",
        template: """
        <div class="flex w-fit items-center gap-4">
          <.skeleton class="size-10 shrink-0 rounded-full" />
          <div class="grid gap-2">
            <.skeleton class="h-4 w-[150px]" />
            <.skeleton class="h-4 w-[100px]" />
          </div>
        </div>
        """
      },
      %Variation{
        id: :text,
        description: "shadcn skeleton-text.",
        template: """
        <div class="flex w-full max-w-xs flex-col gap-2">
          <.skeleton class="h-4 w-full" />
          <.skeleton class="h-4 w-full" />
          <.skeleton class="h-4 w-3/4" />
        </div>
        """
      },
      %Variation{
        id: :form,
        description: "shadcn skeleton-form.",
        template: """
        <div class="flex w-full max-w-xs flex-col gap-7">
          <div class="flex flex-col gap-3">
            <.skeleton class="h-4 w-20" />
            <.skeleton class="h-8 w-full" />
          </div>
          <div class="flex flex-col gap-3">
            <.skeleton class="h-4 w-24" />
            <.skeleton class="h-8 w-full" />
          </div>
          <.skeleton class="h-8 w-24" />
        </div>
        """
      },
      %Variation{
        id: :table,
        description: "shadcn skeleton-table.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-2">
          <div :for={_ <- 1..5} class="flex gap-4">
            <.skeleton class="h-4 flex-1" />
            <.skeleton class="h-4 w-24" />
            <.skeleton class="h-4 w-20" />
          </div>
        </div>
        """
      }
    ]
  end
end
