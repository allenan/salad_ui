defmodule Storybook.SaladUIComponents.HoverCard do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.HoverCard

  def function, do: &HoverCard.hover_card/1

  def imports,
    do: [
      {HoverCard, [hover_card_trigger: 1, hover_card_content: 1]},
      {SaladUI.Button, [button: 1]},
      {SaladUI.Avatar, [avatar: 1, avatar_image: 1, avatar_fallback: 1]}
    ]

  def descriptions do
    """
    The `HoverCard` component displays content when hovering over a trigger element.
    It's perfect for showing additional information like user profiles, previews, or tooltips without requiring a click.

    The component handles hover interactions, timing delays, and positioning automatically.
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default hover card with user profile",
        attributes: %{
          id: "default-hover-card",
          "open-delay": 300,
          "close-delay": 200
        },
        slots: [
          """
          <.hover_card_trigger>
            <.button variant="link">@salad_ui</.button>
          </.hover_card_trigger>
          <.hover_card_content side="bottom" align="center">
            <div class="flex justify-between space-x-4">
              <.avatar>
                <.avatar_image src="https://github.com/vercel.png">
                </.avatar_image>
                <.avatar_fallback>
                  VC
                </.avatar_fallback>
              </.avatar>
              <div class="space-y-1">
                <h4 class="text-sm font-semibold">
                  @salad_ui
                </h4>
                <p class="text-sm">LiveView component library inspired by shadcn</p>
                <div class="flex items-center pt-2">
                  <span class="text-xs text-muted-foreground">
                    Joined May 2024
                  </span>
                </div>
              </div>
            </div>
          </.hover_card_content>
          """
        ]
      },
      %Variation{
        id: :sides,
        description: "shadcn hover-card-sides: `side` places the content on any side of the trigger.",
        template: """
        <div class="flex flex-wrap justify-center gap-2">
          <.hover_card id="hover-card-side-left" open-delay={100} close-delay={100}>
            <.hover_card_trigger>
              <.button variant="outline" class="capitalize">left</.button>
            </.hover_card_trigger>
            <.hover_card_content side="left">
              <div class="flex flex-col gap-1">
                <h4 class="font-medium">Hover Card</h4>
                <p>This hover card appears on the left side of the trigger.</p>
              </div>
            </.hover_card_content>
          </.hover_card>
          <.hover_card id="hover-card-side-top" open-delay={100} close-delay={100}>
            <.hover_card_trigger>
              <.button variant="outline" class="capitalize">top</.button>
            </.hover_card_trigger>
            <.hover_card_content side="top">
              <div class="flex flex-col gap-1">
                <h4 class="font-medium">Hover Card</h4>
                <p>This hover card appears on the top side of the trigger.</p>
              </div>
            </.hover_card_content>
          </.hover_card>
          <.hover_card id="hover-card-side-bottom" open-delay={100} close-delay={100}>
            <.hover_card_trigger>
              <.button variant="outline" class="capitalize">bottom</.button>
            </.hover_card_trigger>
            <.hover_card_content side="bottom">
              <div class="flex flex-col gap-1">
                <h4 class="font-medium">Hover Card</h4>
                <p>This hover card appears on the bottom side of the trigger.</p>
              </div>
            </.hover_card_content>
          </.hover_card>
          <.hover_card id="hover-card-side-right" open-delay={100} close-delay={100}>
            <.hover_card_trigger>
              <.button variant="outline" class="capitalize">right</.button>
            </.hover_card_trigger>
            <.hover_card_content side="right">
              <div class="flex flex-col gap-1">
                <h4 class="font-medium">Hover Card</h4>
                <p>This hover card appears on the right side of the trigger.</p>
              </div>
            </.hover_card_content>
          </.hover_card>
        </div>
        """
      },
      %Variation{
        id: :alignment_variations,
        description: "Different alignment options (start, center, end)",
        attributes: %{
          id: "alignment-hover-card",
          class: "flex justify-around items-center gap-8"
        },
        slots: [
          """
          <div>
            <.hover_card id="bottom-start-card">
              <.hover_card_trigger>
                <.button variant="outline" size="sm">Bottom Start</.button>
              </.hover_card_trigger>
              <.hover_card_content side="bottom" align="start">
                <p class="text-sm">Aligned to the bottom start</p>
              </.hover_card_content>
            </.hover_card>
          </div>

          <div>
            <.hover_card id="bottom-center-card">
              <.hover_card_trigger>
                <.button variant="outline" size="sm">Bottom Center</.button>
              </.hover_card_trigger>
              <.hover_card_content side="bottom" align="center">
                <p class="text-sm">Aligned to the bottom center</p>
              </.hover_card_content>
            </.hover_card>
          </div>

          <div>
            <.hover_card id="bottom-end-card">
              <.hover_card_trigger>
                <.button variant="outline" size="sm">Bottom End</.button>
              </.hover_card_trigger>
              <.hover_card_content side="bottom" align="end">
                <p class="text-sm">Aligned to the bottom end</p>
              </.hover_card_content>
            </.hover_card>
          </div>
          """
        ]
      }
    ]
  end
end
