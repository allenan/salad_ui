defmodule Storybook.SaladUIComponents.Switch do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Switch.switch/1

  def imports,
    do: [
      {SaladUI.Field, [field: 1, field_group: 1, field_content: 1, field_label: 1, field_title: 1, field_description: 1]}
    ]

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
        id: :description,
        description:
          "shadcn switch-description: label and description beside the switch. The labelable element is the switch's `<id>-input` checkbox.",
        template: """
        <.field orientation="horizontal" class="max-w-sm">
          <.field_content>
            <.field_label for="switch-focus-mode-input">Share across devices</.field_label>
            <.field_description>
              Focus is shared across devices, and turns off when you leave the app.
            </.field_description>
          </.field_content>
          <.switch id="switch-focus-mode" />
        </.field>
        """
      },
      %Variation{
        id: :choice_card,
        description: "shadcn switch-choice-card: wrap a `field` in `field_label` to make a selectable card.",
        template: """
        <.field_group class="w-full max-w-sm">
          <.field_label for="switch-share-input">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>Share across devices</.field_title>
                <.field_description>
                  Focus is shared across devices, and turns off when you leave the app.
                </.field_description>
              </.field_content>
              <.switch id="switch-share" />
            </.field>
          </.field_label>
          <.field_label for="switch-notifications-input">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>Enable notifications</.field_title>
                <.field_description>
                  Receive notifications when focus mode is enabled or disabled.
                </.field_description>
              </.field_content>
              <.switch id="switch-notifications" checked />
            </.field>
          </.field_label>
        </.field_group>
        """
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
