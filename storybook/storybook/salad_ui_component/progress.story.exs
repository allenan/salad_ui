defmodule Storybook.SaladUIComponents.Progress do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Progress.progress/1

  def imports, do: [{SaladUI.Field, [field: 1, field_label: 1]}]

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          value: 50
        }
      },
      %Variation{
        id: :progress_bar,
        attributes: %{
          value: 20,
          class: "w-[60%]"
        }
      },
      %Variation{
        id: :high_progress,
        attributes: %{
          value: 80,
          class: "w-[60%]"
        }
      },
      %Variation{
        id: :custom_max,
        attributes: %{
          value: 35,
          max: 50,
          class: "w-[60%]"
        }
      },
      %Variation{
        id: :indeterminate,
        attributes: %{
          indeterminate: true,
          class: "w-[60%]"
        },
        description: "Used when progress value is unknown"
      },
      %Variation{
        id: :progress_label,
        description: "shadcn progress-label: a progress bar with a field label.",
        template: """
        <.field class="w-full max-w-sm">
          <.field_label for="progress-upload">
            <span>Upload progress</span>
            <span class="ml-auto">66%</span>
          </.field_label>
          <.progress value={66} id="progress-upload" />
        </.field>
        """
      }
    ]
  end
end
