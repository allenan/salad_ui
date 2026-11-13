defmodule SaladUI.Checkbox do
  @moduledoc """
  Implementation of checkbox component from https://ui.shadcn.com/docs/components/checkbox

  ## Examples:

      <.checkbox name="terms" id="terms" />

      <div class="flex items-center space-x-2">
        <.checkbox id="terms" name="terms" />
        <.label for="terms">Accept terms and conditions</.label>
      </div>

      <div class="flex items-center gap-2">
        <.checkbox id="remember_me" name="remember_me" />
        <.label for="remember_me">Remember me</.label>
      </div>

      <%!-- A group submitting tags[] = ["elixir", ...] --%>
      <.checkbox
        :for={tag <- ~w(elixir erlang gleam)}
        id={"tag-\#{tag}"}
        name="tags[]"
        checked_value={tag}
        unchecked_value={nil}
        checked={tag in @tags}
      />

      <.form for={@form} as={:user} phx-change="validate">
        <div class="flex items-center gap-2">
          <.checkbox field={@form[:accept_terms]} />
          <.label for={@form[:accept_terms].id}>I accept the terms and conditions</.label>
        </div>
      </.form>
  """
  use SaladUI, :component

  @doc """
  Renders a checkbox input with SaladUI styling.

  ## Options

  * `:id` - The id to apply to the checkbox
  * `:name` - The name to apply to the input field
  * `:value` - Whether the checkbox is checked (normalized like Phoenix's
    checkbox input: `true`/`"true"` check it). Not the submitted value; see
    `:checked_value`.
  * `:checked` - Explicit checked state; overrides `:value`.
  * `:checked_value` - Value submitted when checked. Defaults to `"true"`.
  * `:unchecked_value` - Value of the hidden input submitted when unchecked.
    Defaults to `"false"`; `nil` omits the hidden input, as needed for a
    checkbox group sharing a `name="tags[]"`.
  * `:default-value` - The default value of the checkbox, either `true`, `false`, "true", "false"
  * `:disabled` - Whether the checkbox is disabled
  * `:field` - A Phoenix form field
  * `:class` - Additional classes to add to the checkbox
  * `:aria-invalid` - rendered as `aria-invalid="true"` automatically when `:field` has errors, which applies the destructive error styling; pass it explicitly to override
  * `:indeterminate` - `true` shows the "some selected" dash, as on a select-all
    checkbox when only some rows are selected. Requires an `:id`. Leave it `nil`
    (the default) for an ordinary two-state checkbox.

  ## Indeterminate

  `indeterminate` is a DOM property with no HTML attribute, so passing
  `indeterminate={true}` or `indeterminate={false}` attaches the SaladUI hook
  (`data-component="checkbox"`), which sets the property on mount and after
  every LiveView patch. The browser then applies the `indeterminate:` styles
  and reports the checkbox as "mixed" to screen readers. A click clears it, as
  in any browser; the server's next render decides the new state. Keep passing
  a boolean (not `nil`) for as long as the checkbox can become indeterminate,
  so the hook stays attached.

      <.checkbox
        id="select-all"
        value={@selection == true}
        indeterminate={@selection == :indeterminate}
        aria-label="Select all"
        phx-click="toggle_all"
      />

  ## Differences from shadcn

  The checkbox is a native `<input type="checkbox">`, not Radix's `<button>`, so
  it has no `data-state` attribute and no `checkbox-indicator` child. Style the
  checked state with Tailwind's `checked:` variant where shadcn examples use
  `data-[state=checked]:`, for example
  `class="checked:border-blue-600 checked:bg-blue-600 checked:text-white"`.
  """
  attr :name, :any, default: nil
  attr :value, :any, default: nil
  attr :checked, :boolean, default: nil
  attr :checked_value, :any, default: "true"
  attr :unchecked_value, :any, default: "false"
  attr :"default-value", :any, values: [true, false, "true", "false"], default: false
  attr :field, Phoenix.HTML.FormField

  attr :indeterminate, :boolean,
    default: nil,
    doc: "`true` renders the indeterminate (dash) state; any boolean attaches the hook that syncs it. Requires `id`."

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form required)

  def checkbox(assigns) do
    assigns =
      assigns
      |> prepare_assign()
      |> put_aria_invalid()

    assigns =
      if is_nil(assigns.checked) do
        assign(assigns, :checked, Phoenix.HTML.Form.normalize_value("checkbox", assigns.value))
      else
        assigns
      end

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
    <input :if={!is_nil(@unchecked_value)} type="hidden" name={@name} value={@unchecked_value} />
    <input
      type="checkbox"
      data-slot="checkbox"
      class={
        classes([
          "peer size-4 shrink-0 rounded-[4px] border border-input bg-transparent shadow-xs transition-shadow outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 checked:border-primary checked:bg-primary checked:text-primary-foreground dark:bg-input/30 dark:aria-invalid:ring-destructive/40 dark:checked:bg-primary",
          "indeterminate:border-primary indeterminate:bg-primary indeterminate:text-primary-foreground dark:indeterminate:bg-primary",
          "inline-grid appearance-none place-content-center checked:bg-none indeterminate:bg-none focus:ring-0 focus:ring-offset-0",
          "before:size-3.5 before:bg-current before:opacity-0 checked:before:opacity-100 indeterminate:before:opacity-100",
          "before:[mask-image:url(data:image/svg+xml,%3Csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%2024%2024%27%20fill=%27none%27%20stroke=%27black%27%20stroke-width=%272%27%20stroke-linecap=%27round%27%20stroke-linejoin=%27round%27%3E%3Cpath%20d=%27M20%206%209%2017l-5-5%27/%3E%3C/svg%3E)] indeterminate:before:[mask-image:url(data:image/svg+xml,%3Csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%2024%2024%27%20fill=%27none%27%20stroke=%27black%27%20stroke-width=%272%27%20stroke-linecap=%27round%27%20stroke-linejoin=%27round%27%3E%3Cpath%20d=%27M5%2012h14%27/%3E%3C/svg%3E)]",
          @class
        ])
      }
      name={@name}
      value={@checked_value}
      checked={@checked}
      phx-hook={hooked?(@indeterminate) && "SaladUI"}
      data-component={hooked?(@indeterminate) && "checkbox"}
      data-part={hooked?(@indeterminate) && "root"}
      data-indeterminate={hooked?(@indeterminate) && to_string(@indeterminate)}
      {@rest}
    />
    """
  end

  defp hooked?(indeterminate), do: is_boolean(indeterminate)
end
