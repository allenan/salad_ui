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

    # A native input has no children, so shadcn's `checkbox-indicator` (a
    # size-3.5 CheckIcon in `text-primary-foreground`) is drawn as a masked
    # `::before` filled with `currentColor`.
    #
    # @tailwindcss/forms resets neutralised here:
    # - `[type=checkbox]:checked` / `:indeterminate` paint a hard-coded white
    #   tick/dash as `background-image`, invisible on the near-white dark-mode
    #   `--primary`; `bg-none` removes it.
    # - `[type=checkbox]:focus` adds a 2px blue ring with offset on mouse
    #   focus; `focus:ring-0 focus:ring-offset-0` removes it and
    #   `focus-visible:` restores shadcn's ring.
    # `appearance-none` gives the same rendering without the plugin.
    ~H"""
    <input type="hidden" name={@name} value="false" />
    <input
      type="checkbox"
      data-slot="checkbox"
      class={
        classes([
          "peer size-4 shrink-0 rounded-[4px] border border-input bg-transparent shadow-xs transition-shadow outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 checked:border-primary checked:bg-primary checked:text-primary-foreground dark:bg-input/30 dark:aria-invalid:ring-destructive/40 dark:checked:bg-primary",
          "indeterminate:border-primary indeterminate:bg-primary indeterminate:text-primary-foreground dark:indeterminate:bg-primary",
          "grid appearance-none place-content-center checked:bg-none indeterminate:bg-none focus:ring-0 focus:ring-offset-0",
          "before:size-3.5 before:bg-current before:opacity-0 checked:before:opacity-100 indeterminate:before:opacity-100",
          "before:[mask-image:url(data:image/svg+xml,%3Csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%2024%2024%27%20fill=%27none%27%20stroke=%27black%27%20stroke-width=%272%27%20stroke-linecap=%27round%27%20stroke-linejoin=%27round%27%3E%3Cpath%20d=%27M20%206%209%2017l-5-5%27/%3E%3C/svg%3E)] indeterminate:before:[mask-image:url(data:image/svg+xml,%3Csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%2024%2024%27%20fill=%27none%27%20stroke=%27black%27%20stroke-width=%272%27%20stroke-linecap=%27round%27%20stroke-linejoin=%27round%27%3E%3Cpath%20d=%27M5%2012h14%27/%3E%3C/svg%3E)]",
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
