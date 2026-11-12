defmodule Storybook.SaladUIComponents.Checkbox do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Checkbox.checkbox/1
  def imports, do: [{SaladUI.Label, [{:label, 1}]}]

  def variations do
    [
      %Variation{
        id: :checkbox_checked,
        template: """
        <div class="flex items-center space-x-2">
        <.checkbox id="checked" value={true}/>
        <.label for="checked">I'm a label</.label>
        </div>
        """,
        attributes: %{
          value: true
        }
      },
      %Variation{
        id: :checkbox,
        template: """
        <div class="flex items-center space-x-2">
        <.checkbox id="unchecked"/>
        <.label for="unchecked">I'm a label</.label>
        </div>
        """
      },
      %Variation{
        id: :checkbox_invalid,
        description: ~s|Error styling via aria-invalid (set automatically when a form field has errors)|,
        template: """
        <div class="flex items-center space-x-2">
        <.checkbox id="invalid" aria-invalid="true"/>
        <.label for="invalid">Accept terms and conditions</.label>
        </div>
        """
      }
    ]
  end
end
