defmodule SaladUI.Switch do
  @moduledoc """
  Implementation of a switch/toggle component.

  A switch is a control that allows users to toggle between checked and not checked states.

  ## Component events

  * `:on-checked-changed` - Maps the `checked-changed` event. Fired when the switch is toggled.

  ## Server commands

  * `"toggle"` - Toggles the switch between checked and unchecked.
  """
  use SaladUI, :component

  @doc """
  Renders a switch component.

  ## Props
    * `:id` - The id to be applied to the input element
    * `:name` - The name to be applied to the input element
    * `:class` - Additional CSS classes
    * `:value` - The current value of the switch
    * `:default-value` - The default value of the switch
    * `:field` - Phoenix form field
    * `:disabled` - Whether the switch is disabled
    * `:size` - `"default"` or `"sm"`
    * `:on-checked-changed` - Handler for value change event
    * `:aria-invalid` - rendered as `aria-invalid="true"` automatically when `:field` has errors, which applies the destructive error styling; pass it explicitly to override

  ## Component events

  * `:on-checked-changed` - Fired when the switch is toggled.

  ## Server commands

  * `"toggle"` - Toggles the switch between checked and unchecked.
  """
  attr :id, :string, default: nil
  attr :name, :string, default: nil
  attr :class, :string, default: nil
  attr :value, :any, default: nil
  attr :"default-value", :any, values: [true, false, "true", "false"], default: false
  attr :checked, :boolean
  attr :disabled, :boolean, default: false
  attr :size, :string, values: ~w(default sm), default: "default", doc: "the switch size"
  attr :"on-checked-changed", :any, default: nil, doc: "Handler for value change event"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:active]"
  attr :rest, :global

  def switch(assigns) do
    assigns =
      assigns
      |> prepare_assign()
      |> put_aria_invalid()

    # Normalize value for boolean
    assigns = assign_new(assigns, :checked, fn -> normalize_boolean(assigns.value) end)

    # Collect event mappings
    event_map = event_mappings(assigns)

    assigns =
      assigns
      |> assign(:event_map, json(event_map))
      |> assign(:initial_state, if(assigns.checked, do: "checked", else: "unchecked"))
      |> assign(
        :options,
        json(%{
          disabled: assigns.disabled
        })
      )

    ~H"""
    <div
      id={@id}
      data-component="switch"
      data-state={@initial_state}
      data-options={@options}
      data-event-mappings={@event_map}
      data-part="root"
      data-slot="switch"
      data-size={@size}
      phx-hook="SaladUI"
      data-disabled={@disabled}
      role="switch"
      aria-checked={to_string(@checked)}
      class={
        classes([
          "switch-root peer group/switch inline-flex shrink-0 cursor-pointer items-center rounded-full border border-transparent shadow-xs transition-all outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 data-[disabled]:cursor-not-allowed data-[disabled]:opacity-50 data-[size=default]:h-[1.15rem] data-[size=default]:w-8 data-[size=sm]:h-3.5 data-[size=sm]:w-6 data-[state=checked]:bg-primary data-[state=unchecked]:bg-input dark:data-[state=unchecked]:bg-input/80",
          "aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
          @class
        ])
      }
      tabindex={if @disabled, do: "-1", else: "0"}
      {@rest}
    >
      <input :if={!@disabled} type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        id={"#{@id}-input"}
        name={@name}
        value="true"
        class="sr-only"
        checked={@checked}
        disabled={@disabled}
        aria-checked={to_string(@checked)}
        data-part="input"
      />
      <span
        data-part="thumb"
        data-slot="switch-thumb"
        data-state={@initial_state}
        class="pointer-events-none block rounded-full bg-background ring-0 transition-transform group-data-[size=default]/switch:size-4 group-data-[size=sm]/switch:size-3 data-[state=checked]:translate-x-[calc(100%-2px)] data-[state=unchecked]:translate-x-0 rtl:data-[state=checked]:-translate-x-[calc(100%-2px)] dark:data-[state=checked]:bg-primary-foreground dark:data-[state=unchecked]:bg-foreground"
      />
    </div>
    """
  end

  defp normalize_boolean(value) do
    case value do
      "true" -> true
      "false" -> false
      true -> true
      false -> false
      _ -> false
    end
  end
end
