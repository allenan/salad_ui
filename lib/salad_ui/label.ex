defmodule SaladUI.Label do
  @moduledoc """
  Implementation of the Label component, an accessible `<label>` for form controls.

  ## Examples:

      <div class="flex items-center gap-2">
        <.checkbox id="terms" />
        <.label for="terms">Accept terms and conditions</.label>
      </div>

  The label is a `flex items-center gap-2` row, so an icon or a second span can
  sit beside the text. It dims when a preceding `peer` control is disabled, or
  when it is inside a `group` with `data-disabled="true"` (as a `field/1` is).
  """
  use SaladUI, :component

  @doc """
  Renders a label.

  ## Options

  * `:for` - The id of the control this label is for.
  * `:class` - Additional CSS classes.

  ## Examples

      <.label for="email">Email</.label>
  """
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value for)
  slot :inner_block, required: true

  def label(assigns) do
    assigns = put_data_slot(assigns, "label")

    ~H"""
    <label
      class={
        classes([
          "flex items-center gap-2 text-sm leading-none font-medium select-none group-data-[disabled=true]:pointer-events-none group-data-[disabled=true]:opacity-50 peer-disabled:cursor-not-allowed peer-disabled:opacity-50",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </label>
    """
  end
end
