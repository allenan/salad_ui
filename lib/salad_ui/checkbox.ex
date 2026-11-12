defmodule SaladUI.Checkbox do
  @moduledoc """
  Implementation of checkbox component from https://ui.shadcn.com/docs/components/checkbox

  ## Examples:

      <.checkbox name="terms" id="terms" />

      <div class="flex items-center space-x-2">
        <.checkbox id="terms" name="terms" />
        <.label for="terms">Accept terms and conditions</.label>
      </div>

      <.checkbox id="remember_me" name="remember_me" label="Remember me" />

      <.form for={@form} as={:user} phx-change="validate">
        <.checkbox field={@form[:accept_terms]} label="I accept the terms and conditions" />
      </.form>
  """
  use SaladUI, :component

  @doc """
  Renders a checkbox input with SaladUI styling.

  ## Options

  * `:id` - The id to apply to the checkbox
  * `:name` - The name to apply to the input field
  * `:value` - The current value of the checkbox
  * `:default-value` - The default value of the checkbox, either `true`, `false`, "true", "false"
  * `:disabled` - Whether the checkbox is disabled
  * `:field` - A Phoenix form field
  * `:class` - Additional classes to add to the checkbox
  * `:aria-invalid` - rendered as `aria-invalid="true"` automatically when `:field` has errors, which applies the destructive error styling; pass it explicitly to override
  """
  attr :name, :any, default: nil
  attr :value, :any, default: nil
  attr :"default-value", :any, values: [true, false, "true", "false"], default: false
  attr :field, Phoenix.HTML.FormField
  attr :class, :string, default: nil
  attr :rest, :global

  def checkbox(assigns) do
    assigns =
      assigns
      |> prepare_assign()
      |> put_aria_invalid()

    assigns =
      assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", assigns.value) end)

    # `focus:ring-0 focus:ring-offset-0` neutralises @tailwindcss/forms'
    # `[type=checkbox]:focus` ring (2px blue, 2px offset), which would
    # otherwise show on mouse focus; `focus-visible:` restores shadcn's ring.
    ~H"""
    <input type="hidden" name={@name} value="false" />
    <input
      type="checkbox"
      class={
        classes([
          "peer size-4 shrink-0 rounded-[4px] border border-input bg-transparent shadow-xs transition-shadow outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 checked:border-primary checked:bg-primary checked:text-primary-foreground dark:bg-input/30 dark:aria-invalid:ring-destructive/40 dark:checked:bg-primary",
          "focus:ring-0 focus:ring-offset-0",
          @class
        ])
      }
      name={@name}
      value="true"
      checked={@checked}
      {@rest}
    />
    """
  end
end
