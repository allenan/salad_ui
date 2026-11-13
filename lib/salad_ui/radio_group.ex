defmodule SaladUI.RadioGroup do
  @moduledoc """
  Implementation of radio group component from https://ui.shadcn.com/docs/components/radio-group

  ## Examples:

      <.radio_group
        id="subscription"
        name="subscription"
        default-value="monthly"
        on-value-changed={JS.push("plan_changed")}
        aria-label="Subscription"
      >
        <div class="flex flex-col space-y-2">
          <div class="flex items-center space-x-2">
            <.radio_group_item value="monthly" id="monthly" />
            <.label for="monthly">Monthly</.label>
          </div>
          <div class="flex items-center space-x-2">
            <.radio_group_item value="yearly" id="yearly" />
            <.label for="yearly">Yearly</.label>
          </div>
        </div>
      </.radio_group>

  ## Component events

  * `:on-value-changed` - Maps the `value-changed` event. Fired when the selected item changes.

  ## Server commands

  Radio group does not support `SaladUI.LiveView.send_command/4`. To change the
  selected value from the server, update the `value` assign and let LiveView re-render.

  ## Validation

  When `field` has errors the group renders `aria-invalid="true"` on its
  `role="radiogroup"` root and every item picks up the destructive error styling.
  Pass `aria-invalid` to the group (or a single item) to set it explicitly.

  Only errors on a group the user has interacted with count, following
  `Phoenix.Component.used_input?/1`. An unchecked radio submits nothing, so
  when `name` (or `field`) is set the group renders a hidden input with an
  empty value ahead of the radios, as Phoenix does for checkboxes: an empty
  group still submits `""`, reaches the changeset and is marked used on submit,
  while LiveView reports it as unused until the user picks an item.
  """
  use SaladUI, :component

  @doc """
  Radio group component that allows selection of one option from a set.

  ## Component events

  * `:on-value-changed` - Fired when the selected item changes.
  """
  attr :id, :string, default: nil, doc: "required unless `field` is given (the hook needs a stable id)"
  attr :name, :string, default: nil
  attr :value, :any, default: nil, doc: "The current value of the radio group"
  attr :"default-value", :any, default: nil, doc: "The default value of the radio group"
  attr :"on-value-changed", :any, default: nil, doc: "Handler for value changed event"
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def radio_group(assigns) do
    assigns =
      assigns
      |> prepare_assign()
      |> put_aria_invalid()
      |> require_id!("radio_group/1")

    # Collect event mappings
    event_map = event_mappings(assigns)

    assigns =
      assigns
      |> assign(:event_map, Jason.encode!(event_map))
      |> assign(
        :options,
        Jason.encode!(%{
          initialValue: assigns.value,
          name: assigns.name
        })
      )

    ~H"""
    <div
      id={@id}
      class={classes(["group/radio-group grid gap-3", @class])}
      data-component="radio-group"
      data-slot="radio-group"
      data-state="idle"
      data-options={@options}
      data-event-mappings={@event_map}
      data-part="root"
      phx-hook="SaladUI"
      {@rest}
    >
      <input :if={@name} type="hidden" name={@name} value="" />
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Individual radio button in a radio group.
  """
  attr :id, :string, required: true
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  def radio_group_item(assigns) do
    ~H"""
    <div
      data-part="item"
      data-slot="radio-group-item"
      data-value={@value}
      data-state="unchecked"
      data-disabled={to_string(@disabled)}
      class={
        classes([
          "group/item",
          "relative inline-flex aspect-square size-4 shrink-0 rounded-full border border-input text-primary shadow-xs transition-[color,box-shadow] outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 data-[disabled=true]:cursor-not-allowed data-[disabled=true]:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:bg-input/30 dark:aria-invalid:ring-destructive/40",
          "group-aria-invalid/radio-group:not-aria-[invalid=false]:border-destructive group-aria-invalid/radio-group:not-aria-[invalid=false]:ring-destructive/20 dark:group-aria-invalid/radio-group:not-aria-[invalid=false]:ring-destructive/40",
          @class
        ])
      }
      tabindex="-1"
      {@rest}
    >
      <input type="radio" id={@id} value={@value} disabled={@disabled} class="sr-only" tabindex="-1" />
      <span
        data-slot="radio-group-indicator"
        class="absolute inset-0 hidden group-data-[state=checked]/item:block"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="lucide lucide-circle absolute top-1/2 left-1/2 size-2 -translate-x-1/2 -translate-y-1/2 fill-primary"
        >
          <circle cx="12" cy="12" r="10"></circle>
        </svg>
      </span>
    </div>
    """
  end
end
