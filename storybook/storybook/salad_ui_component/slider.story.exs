defmodule Storybook.SaladUIComponents.Slider do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Slider.slider/1
  def imports, do: [{SaladUI.Label, [{:label, 1}]}]

  def template do
    """
    <.form class="w-full" phx-change="validate">
      <.psb-variation />
    </.form>
    """
  end

  def variations do
    [
      %Variation{
        id: :default_slider,
        description: "Single value",
        attributes: %{
          id: "slider-demo",
          value: 75,
          max: 100,
          step: 1,
          class: "mx-auto w-full max-w-xs",
          name: "demo"
        }
      },
      %Variation{
        id: :range_slider,
        description: "Range: a list with two values renders two thumbs",
        attributes: %{
          id: "slider-range",
          value: [25, 50],
          max: 100,
          step: 5,
          class: "mx-auto w-full max-w-xs",
          name: "range"
        }
      },
      %Variation{
        id: :multiple_slider,
        description: "Multiple thumbs: one thumb per value",
        attributes: %{
          id: "slider-multiple",
          value: [10, 20, 70],
          max: 100,
          step: 10,
          class: "mx-auto w-full max-w-xs",
          name: "multiple"
        }
      },
      %Variation{
        id: :vertical_slider,
        description: ~s|Vertical: orientation="vertical"|,
        template: """
        <div class="mx-auto flex w-full max-w-xs items-center justify-center gap-6">
          <.slider id="slider-vertical-1" value={50} max={100} step={1} orientation="vertical" class="h-40" />
          <.slider id="slider-vertical-2" value={25} max={100} step={1} orientation="vertical" class="h-40" />
        </div>
        """
      },
      %Variation{
        id: :controlled_slider,
        description: "Fractional step with a live value readout (updates when a drag or key press commits)",
        template: """
        <div class="mx-auto grid w-full max-w-xs gap-3">
          <div class="flex items-center justify-between gap-2">
            <.label for="slider-demo-temperature">Temperature</.label>
            <span id="slider-demo-temperature-value" class="text-sm text-muted-foreground">0.3, 0.7</span>
          </div>
          <.slider
            id="slider-demo-temperature"
            value={[0.3, 0.7]}
            min={0}
            max={1}
            step={0.1}
            onchange="document.getElementById('slider-demo-temperature-value').textContent = this.dataset.value.split(',').join(', ')"
          />
        </div>
        """
      },
      %Variation{
        id: :disabled_slider,
        description: "Disabled",
        attributes: %{
          id: "slider-disabled",
          value: 50,
          max: 100,
          step: 1,
          disabled: true,
          class: "mx-auto w-full max-w-xs",
          name: "disabled-slider"
        }
      },
      %Variation{
        id: :rtl_slider,
        description: ~s|RTL: dir="rtl" starts the slider at the right and flips the arrow keys|,
        attributes: %{
          id: "slider-rtl",
          value: 75,
          max: 100,
          step: 1,
          dir: "rtl",
          class: "mx-auto w-full max-w-xs",
          name: "rtl"
        }
      },
      %Variation{
        id: :event_slider,
        description: "Server event on value change",
        attributes: %{
          id: "slider-events",
          value: 50,
          min: 0,
          max: 100,
          class: "mx-auto w-full max-w-xs",
          name: "volume",
          "on-value-changed": "handle_slider_change"
        }
      }
    ]
  end
end
