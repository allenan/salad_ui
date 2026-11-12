defmodule Storybook.SaladUIComponents.Button do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  # def function, do: &SaladStorybookWeb.SaladUIComponents.button/1
  def function, do: &SaladUI.Button.button/1

  def variations do
    [
      %VariationGroup{
        id: :colors,
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
      %VariationGroup{
        id: :sizes,
        description: "Sizes with the `size` attribute, including shadcn v4's `xs` and `icon-*` sizes.",
        variations: [
          %Variation{
            id: :size_xs,
            attributes: %{size: "xs", variant: "outline"},
            slots: ["Extra small"]
          },
          %Variation{
            id: :size_sm,
            attributes: %{size: "sm", variant: "outline"},
            slots: ["Small"]
          },
          %Variation{
            id: :size_default,
            attributes: %{size: "default", variant: "outline"},
            slots: ["Default"]
          },
          %Variation{
            id: :size_lg,
            attributes: %{size: "lg", variant: "outline"},
            slots: ["Large"]
          },
          %Variation{
            id: :size_icon_xs,
            attributes: %{size: "icon-xs", variant: "outline"},
            slots: ["+"]
          },
          %Variation{
            id: :size_icon_sm,
            attributes: %{size: "icon-sm", variant: "outline"},
            slots: ["+"]
          },
          %Variation{
            id: :size_icon,
            attributes: %{size: "icon", variant: "outline"},
            slots: ["+"]
          },
          %Variation{
            id: :size_icon_lg,
            attributes: %{size: "icon-lg", variant: "outline"},
            slots: ["+"]
          }
        ]
      },
      %Variation{
        id: :custom_class,
        attributes: %{
          class: "rounded-full",
          variant: "destructive",
          size: "lg"
        },
        slots: ["Disabled"]
      },
      %Variation{
        id: :disabled,
        attributes: %{
          disabled: true
        },
        slots: ["Disabled"]
      },
      %Variation{
        id: :with_icon,
        description: "Icons are sized automatically and tighten the padding.",
        attributes: %{variant: "outline", size: "sm"},
        slots: ["<Lucideicons.git_branch /> New Branch"]
      },
      %Variation{
        id: :rounded,
        description: ~s|`size="icon"` with `class="rounded-full"`.|,
        attributes: %{variant: "outline", size: "icon", class: "rounded-full", "aria-label": "Scroll up"},
        slots: ["<Lucideicons.arrow_up />"]
      },
      %Variation{
        id: :spinner,
        description: "A disabled button with a spinning icon.",
        template: """
        <div class="flex gap-2">
          <.button variant="outline" disabled>
            <Lucideicons.loader_circle class="animate-spin" /> Generating
          </.button>
          <.button variant="secondary" disabled>
            Downloading <Lucideicons.loader_circle class="animate-spin" />
          </.button>
        </div>
        """
      },
      %Variation{
        id: :as_link,
        description: ~s|`href`, `navigate` or `patch` render the button as an `<a>` (shadcn's `asChild` + `<Link>`).|,
        attributes: %{href: "#login"},
        slots: ["Login"]
      }
    ]
  end
end
