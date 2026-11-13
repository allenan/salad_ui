defmodule Storybook.SaladUIComponents.Textarea do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Textarea.textarea/1

  def imports, do: [{SaladUI.Field, [field: 1, field_label: 1, field_description: 1]}, {SaladUI.Button, [button: 1]}]

  def variations do
    [
      %Variation{
        id: :textarea,
        attributes: %{
          name: "my-textarea",
          placeholder: "Type your message here"
        }
      },
      %Variation{
        id: :textarea_disabled,
        attributes: %{
          name: "my-textarea",
          disabled: true,
          placeholder: "I'm disabled"
        }
      },
      %Variation{
        id: :field,
        description: "shadcn textarea-field: label and description above the textarea.",
        template: """
        <.field>
          <.field_label for="textarea-message">Message</.field_label>
          <.field_description>Enter your message below.</.field_description>
          <.textarea id="textarea-message" placeholder="Type your message here." />
        </.field>
        """
      },
      %Variation{
        id: :button,
        description: "shadcn textarea-button: a textarea with a submit button.",
        template: """
        <div class="grid w-full gap-2">
          <.textarea placeholder="Type your message here." />
          <.button>Send message</.button>
        </div>
        """
      },
      %Variation{
        id: :textarea_invalid,
        description: ~s|Error styling via aria-invalid (set automatically when a form field has errors)|,
        attributes: %{
          name: "my-textarea",
          placeholder: "Type your message here",
          "aria-invalid": "true"
        }
      }
    ]
  end
end
