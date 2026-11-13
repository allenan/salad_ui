defmodule Storybook.SaladUIComponents.RadioGroup do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.RadioGroup.radio_group/1

  def imports,
    do: [
      {SaladUI.Label, [{:label, 1}]},
      {SaladUI.RadioGroup, [radio_group_item: 1]},
      {SaladUI.Field,
       [field: 1, field_set: 1, field_legend: 1, field_content: 1, field_label: 1, field_title: 1, field_description: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default radio group with no preselected option",
        slots: [
          """
          <div class="flex flex-col space-y-2">
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-one" id="option-one" />
              <.label for="option-one">Option One</.label>
            </div>
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-two" id="option-two" />
              <.label for="option-two">Option Two</.label>
            </div>
          </div>
          """
        ],
        attributes: %{
          name: "question-1",
          "aria-label": "Question 1"
        }
      },
      %Variation{
        id: :with_value,
        description: "Radio group with a preselected option via value attribute",
        slots: [
          """
          <div class="flex flex-col space-y-2">
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-one" id="option-one-value" />
              <.label for="option-one-value">Option One</.label>
            </div>
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-two" id="option-two-value" />
              <.label for="option-two-value">Option Two</.label>
            </div>
          </div>
          """
        ],
        attributes: %{
          name: "question-2",
          value: "option-two",
          "aria-label": "Question 2"
        }
      },
      %Variation{
        id: :with_default_value,
        description: "Radio group with a preselected option via default-value attribute",
        slots: [
          """
          <div class="flex flex-col space-y-2">
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-one" id="option-one-default" />
              <.label for="option-one-default">Option One</.label>
            </div>
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-two" id="option-two-default" />
              <.label for="option-two-default">Option Two</.label>
            </div>
          </div>
          """
        ],
        attributes: %{
          name: "question-3",
          "default-value": "option-one",
          "aria-label": "Question 3"
        }
      },
      %Variation{
        id: :with_disabled_option,
        description: "Radio group with a disabled option",
        slots: [
          """
          <div class="flex flex-col space-y-2">
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-one" id="option-one-disabled" />
              <.label for="option-one-disabled">Option One</.label>
            </div>
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-two" id="option-two-disabled" disabled />
              <.label for="option-two-disabled" class="opacity-50">Option Two (Disabled)</.label>
            </div>
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-three" id="option-three-disabled" />
              <.label for="option-three-disabled">Option Three</.label>
            </div>
          </div>
          """
        ],
        attributes: %{
          name: "question-4",
          value: "option-one",
          "aria-label": "Question 4"
        }
      },
      %Variation{
        id: :horizontal_layout,
        description: "Radio group with horizontal layout",
        slots: [
          """
          <div class="flex space-x-6">
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-one" id="option-one-horizontal" />
              <.label for="option-one-horizontal">Option One</.label>
            </div>
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-two" id="option-two-horizontal" />
              <.label for="option-two-horizontal">Option Two</.label>
            </div>
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-three" id="option-three-horizontal" />
              <.label for="option-three-horizontal">Option Three</.label>
            </div>
          </div>
          """
        ],
        attributes: %{
          name: "question-5",
          value: "option-two",
          "aria-label": "Question 5"
        }
      },
      %Variation{
        id: :with_event_handler,
        description: "Radio group with event handler for value changes",
        slots: [
          """
          <div class="flex flex-col space-y-2">
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-one" id="option-one-event" />
              <.label for="option-one-event">Option One</.label>
            </div>
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-two" id="option-two-event" />
              <.label for="option-two-event">Option Two</.label>
            </div>
          </div>
          """
        ],
        attributes: %{
          name: "question-6",
          value: "option-one",
          "on-value-changed": "handle_radio_group_change",
          "aria-label": "Question 6"
        }
      },
      %Variation{
        id: :description,
        description: "shadcn radio-group-description: each option has a label and description.",
        template: """
        <.radio_group id="radio-group-description" name="spacing" default-value="comfortable" class="w-fit">
          <.field orientation="horizontal">
            <.radio_group_item value="default" id="desc-r1" />
            <.field_content>
              <.field_label for="desc-r1">Default</.field_label>
              <.field_description>Standard spacing for most use cases.</.field_description>
            </.field_content>
          </.field>
          <.field orientation="horizontal">
            <.radio_group_item value="comfortable" id="desc-r2" />
            <.field_content>
              <.field_label for="desc-r2">Comfortable</.field_label>
              <.field_description>More space between elements.</.field_description>
            </.field_content>
          </.field>
          <.field orientation="horizontal">
            <.radio_group_item value="compact" id="desc-r3" />
            <.field_content>
              <.field_label for="desc-r3">Compact</.field_label>
              <.field_description>Minimal spacing for dense layouts.</.field_description>
            </.field_content>
          </.field>
        </.radio_group>
        """
      },
      %Variation{
        id: :choice_card,
        description: "shadcn radio-group-choice-card: wrap a `field` in `field_label` to make a selectable card.",
        template: """
        <.radio_group id="radio-group-choice-card" name="plan" default-value="plus" class="max-w-sm">
          <.field_label for="plus-plan">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>Plus</.field_title>
                <.field_description>For individuals and small teams.</.field_description>
              </.field_content>
              <.radio_group_item value="plus" id="plus-plan" />
            </.field>
          </.field_label>
          <.field_label for="pro-plan">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>Pro</.field_title>
                <.field_description>For growing businesses.</.field_description>
              </.field_content>
              <.radio_group_item value="pro" id="pro-plan" />
            </.field>
          </.field_label>
          <.field_label for="enterprise-plan">
            <.field orientation="horizontal">
              <.field_content>
                <.field_title>Enterprise</.field_title>
                <.field_description>For large teams and enterprises.</.field_description>
              </.field_content>
              <.radio_group_item value="enterprise" id="enterprise-plan" />
            </.field>
          </.field_label>
        </.radio_group>
        """
      },
      %Variation{
        id: :fieldset,
        description: "shadcn radio-group-fieldset: a legend and description above the group.",
        template: """
        <.field_set class="w-full max-w-xs">
          <.field_legend variant="label">Subscription Plan</.field_legend>
          <.field_description>
            Yearly and lifetime plans offer significant savings.
          </.field_description>
          <.radio_group id="radio-group-fieldset" name="subscription" default-value="monthly">
            <.field orientation="horizontal">
              <.radio_group_item value="monthly" id="plan-monthly" />
              <.field_label for="plan-monthly" class="font-normal">Monthly ($9.99/month)</.field_label>
            </.field>
            <.field orientation="horizontal">
              <.radio_group_item value="yearly" id="plan-yearly" />
              <.field_label for="plan-yearly" class="font-normal">Yearly ($99.99/year)</.field_label>
            </.field>
            <.field orientation="horizontal">
              <.radio_group_item value="lifetime" id="plan-lifetime" />
              <.field_label for="plan-lifetime" class="font-normal">Lifetime ($299.99)</.field_label>
            </.field>
          </.radio_group>
        </.field_set>
        """
      },
      %Variation{
        id: :disabled,
        description: "shadcn radio-group-disabled: a disabled item; `data-disabled` on its field dims the label.",
        template: """
        <.radio_group id="radio-group-disabled" name="disabled-demo" default-value="option2" class="w-fit">
          <.field orientation="horizontal" data-disabled>
            <.radio_group_item value="option1" id="disabled-1" disabled />
            <.field_label for="disabled-1" class="font-normal">Disabled</.field_label>
          </.field>
          <.field orientation="horizontal">
            <.radio_group_item value="option2" id="disabled-2" />
            <.field_label for="disabled-2" class="font-normal">Option 2</.field_label>
          </.field>
          <.field orientation="horizontal">
            <.radio_group_item value="option3" id="disabled-3" />
            <.field_label for="disabled-3" class="font-normal">Option 3</.field_label>
          </.field>
        </.radio_group>
        """
      },
      %Variation{
        id: :invalid,
        description: ~s|Error styling via aria-invalid on the group (set automatically when a form field has errors)|,
        slots: [
          """
          <div class="flex flex-col space-y-2">
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-one" id="option-one-invalid" />
              <.label for="option-one-invalid">Option One</.label>
            </div>
            <div class="flex items-center space-x-2">
              <.radio_group_item value="option-two" id="option-two-invalid" />
              <.label for="option-two-invalid">Option Two</.label>
            </div>
          </div>
          """
        ],
        attributes: %{
          name: "question-7",
          "aria-label": "Question 7",
          "aria-invalid": "true"
        }
      }
    ]
  end
end
