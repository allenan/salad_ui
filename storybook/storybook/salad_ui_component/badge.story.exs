defmodule Storybook.SaladUIComponents.Badge do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  # def function, do: &SaladStorybookWeb.SaladUIComponents.button/1
  def function, do: &SaladUI.Badge.badge/1

  def variations do
    [
      %Variation{
        id: :default,
        slots: ["Badge"]
      },
      %VariationGroup{
        id: :badge_variants,
        description: "Color variations with `variant` attribute.",
        variations: [
          %Variation{
            id: :color_default,
            slots: ["Default"]
          },
          %Variation{
            id: :color_secondary,
            attributes: %{
              variant: "secondary"
            },
            slots: ["Secondary"]
          },
          %Variation{
            id: :color_destructive,
            attributes: %{
              variant: "destructive"
            },
            slots: ["Destructive"]
          },
          %Variation{
            id: :color_outline,
            attributes: %{
              variant: "outline"
            },
            slots: ["Outline"]
          },
          %Variation{
            id: :color_ghost,
            attributes: %{
              variant: "ghost"
            },
            slots: ["Ghost"]
          },
          %Variation{
            id: :color_link,
            attributes: %{
              variant: "link"
            },
            slots: ["Link"]
          }
        ]
      },
      %Variation{
        id: :with_icon,
        template: """
        <div class="flex flex-wrap gap-2">
          <.badge variant="secondary">
            <Lucideicons.badge_check /> Verified
          </.badge>
          <.badge variant="outline">
            Bookmark <Lucideicons.bookmark />
          </.badge>
        </div>
        """
      },
      %Variation{
        id: :with_spinner,
        template: """
        <div class="flex flex-wrap gap-2">
          <.badge variant="destructive">
            <Lucideicons.loader_circle class="animate-spin" /> Deleting
          </.badge>
          <.badge variant="secondary">
            Generating <Lucideicons.loader_circle class="animate-spin" />
          </.badge>
        </div>
        """
      },
      %Variation{
        id: :link,
        description: ~s|`href`, `navigate` or `patch` render an `<a>`, which also enables the variant's hover styles.|,
        template: """
        <div class="flex flex-wrap gap-2">
          <.badge href="#link">
            Open Link <Lucideicons.arrow_up_right />
          </.badge>
          <.badge variant="outline" href="#link">Outline link</.badge>
          <.badge variant="ghost" href="#link">Ghost link</.badge>
          <.badge variant="link" href="#link">Link</.badge>
        </div>
        """
      },
      %Variation{
        id: :custom_colors,
        template: """
        <div class="flex flex-wrap gap-2">
          <.badge class="bg-blue-50 text-blue-700 dark:bg-blue-950 dark:text-blue-300">Blue</.badge>
          <.badge class="bg-green-50 text-green-700 dark:bg-green-950 dark:text-green-300">Green</.badge>
          <.badge class="bg-sky-50 text-sky-700 dark:bg-sky-950 dark:text-sky-300">Sky</.badge>
          <.badge class="bg-purple-50 text-purple-700 dark:bg-purple-950 dark:text-purple-300">Purple</.badge>
          <.badge class="bg-red-50 text-red-700 dark:bg-red-950 dark:text-red-300">Red</.badge>
        </div>
        """
      }
    ]
  end
end
