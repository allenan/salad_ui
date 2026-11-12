defmodule Storybook.SaladUIComponents.Switch do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Switch.switch/1

  def variations do
    [
      %VariationGroup{
        id: :basic,
        variations: [
          %Variation{
            id: :default,
            attributes: %{
              id: "switch-default"
            }
          },
          %Variation{
            id: :checked,
            attributes: %{
              id: "switch-checked",
              checked: true
            }
          },
          %Variation{
            id: :disabled,
            attributes: %{
              id: "switch-disabled",
              disabled: true
            }
          },
          %Variation{
            id: :checked_disabled,
            attributes: %{
              id: "switch-checked-disabled",
              checked: true,
              disabled: true
            }
          },
          %Variation{
            id: :small,
            description: ~s|`size="sm"`|,
            attributes: %{
              id: "switch-small",
              size: "sm",
              checked: true
            }
          },
          %Variation{
            id: :invalid,
            description: ~s|Error styling via aria-invalid (set automatically when a form field has errors)|,
            attributes: %{
              id: "switch-invalid",
              "aria-invalid": "true"
            }
          }
        ]
      },
      %Variation{
        id: :with_label,
        template: """
        <div class="flex items-center space-x-2">
          <.psb-variation />
          <label for="switch-with-label-input">Click me</label>
        </div>
        """,
        attributes: %{
          id: "switch-with-label",
          checked: true,
          "on-checked-changed": "on_checked"
        }
      },
      %Variation{
        id: :sizes,
        description: ~s|`size="sm"` and `size="default"`|,
        template: """
        <div class="flex w-full max-w-[10rem] flex-col gap-4">
          <div class="flex items-center gap-2">
            <.switch id="switch-size-sm" size="sm" />
            <label for="switch-size-sm-input" class="text-sm font-medium">Small</label>
          </div>
          <div class="flex items-center gap-2">
            <.switch id="switch-size-default" size="default" />
            <label for="switch-size-default-input" class="text-sm font-medium">Default</label>
          </div>
        </div>
        """
      }
    ]
  end
end
