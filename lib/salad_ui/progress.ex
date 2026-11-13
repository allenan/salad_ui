defmodule SaladUI.Progress do
  @moduledoc """
  Implementation of Progress component for displaying completion percentages or loading states.

  Progress bars visually represent the completion status of an operation, providing
  immediate feedback about how far along a task or process is.

  ## Examples:

      <.progress value={50} />
      <.progress value={75} class="w-[60%]" />

      <.field class="w-full max-w-sm">
        <.field_label for="progress-upload">
          <span>Upload progress</span>
          <span class="ms-auto">66%</span>
        </.field_label>
        <.progress value={66} id="progress-upload" />
      </.field>
  """
  use SaladUI, :component

  @doc """
  Renders a progress bar.

  ## Options

  * `:value` - The current progress value (0-100)
  * `:max` - The maximum value. Defaults to `100`.
  * `:indeterminate` - Render an animated bar with no `aria-valuenow`.
  * `:class` - Additional CSS classes
  """
  attr :class, :string, default: nil
  attr :value, :integer, default: 0, doc: "Current progress value (0-100)"
  attr :max, :integer, default: 100, doc: "Maximum value"
  attr :indeterminate, :boolean, default: false, doc: "Whether the progress is indeterminate"
  attr :rest, :global

  def progress(assigns) do
    # Normalize and clamp value between 0 and 100
    value = normalize_integer(assigns[:value] || 0)
    value = min(max(value, 0), assigns[:max] || 100)

    assigns = assign(assigns, :value, value)

    ~H"""
    <div
      data-slot="progress"
      role="progressbar"
      aria-valuemin="0"
      aria-valuemax={@max || 100}
      aria-valuenow={if @indeterminate, do: nil, else: @value}
      class={classes(["relative h-2 w-full overflow-hidden rounded-full bg-primary/20", @class])}
      data-indeterminate={to_string(@indeterminate)}
      {@rest}
    >
      <div
        data-slot="progress-indicator"
        class={
          classes([
            "h-full w-full flex-1 bg-primary transition-all",
            @indeterminate && "animate-indeterminate-progress"
          ])
        }
        style={if @indeterminate, do: nil, else: "transform: translateX(-#{100 - @value}%)"}
      >
      </div>
    </div>
    """
  end

  defp normalize_integer(value) when is_integer(value), do: value

  defp normalize_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, _} -> integer
      _ -> nil
    end
  end

  defp normalize_integer(_), do: nil
end
