defmodule Storybook.SaladUIComponents.Label do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Label.label/1

  def imports, do: [{SaladUI.Checkbox, [checkbox: 1]}]

  def variations do
    [
      %Variation{
        id: :label,
        attributes: %{
          for: "some_id"
        },
        slots: ["I'm a label"]
      },
      %Variation{
        id: :label_demo,
        description: "shadcn label-demo: a label beside a checkbox.",
        template: """
        <div class="flex gap-2">
          <.checkbox id="terms" />
          <.label for="terms">Accept terms and conditions</.label>
        </div>
        """
      },
      %Variation{
        id: :disabled_peer,
        description: "The label dims after a disabled `peer` control.",
        template: """
        <div class="flex gap-2">
          <.checkbox id="terms-disabled" disabled />
          <.label for="terms-disabled">Accept terms and conditions</.label>
        </div>
        """
      }
    ]
  end
end
