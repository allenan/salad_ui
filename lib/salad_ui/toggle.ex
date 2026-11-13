defmodule SaladUI.Toggle do
  @moduledoc """
  Implementation of the toggle component from https://ui.shadcn.com/docs/components/toggle

  A two-state button that can be either on or off.

  The `<button>` carries Radix's `data-state="on|off"` and `aria-pressed`, and the
  `toggle` JS component keeps both in sync with a hidden checkbox when it is
  clicked, so the toggle submits like a checkbox inside a form. The pressed
  state survives unrelated LiveView re-renders: while the server keeps
  rendering the same `value`, the hook keeps the user's choice.

  ## Examples:

      <.toggle aria-label="Toggle bold">B</.toggle>
      <.toggle value={true} size="sm" variant="outline">Bold</.toggle>
      <.toggle field={@form[:bold]}>Bold</.toggle>

  ## Component events

  * `:on-pressed-changed` - Maps the `pressed-changed` event, fired with
    `%{"pressed" => boolean}` when the toggle is switched on or off.

  ## Server commands

  * `"toggle"` - Switches the toggle on or off.
  * `"on"` / `"off"` - Switches the toggle on / off.
  """
  use SaladUI, :component

  @doc """
  Renders a toggle button.

  ## Attributes

  * `:id` - id of the toggle `<button>` (generated when omitted; the hook needs
    one). The hidden checkbox gets `"<id>-input"`.
  * `:name` - form name; the toggle submits `"true"` when on and `"false"` when off
  * `:value` / `:default-value` - whether the toggle starts on
  * `:field` - a Phoenix form field; when it has errors (and the user has
    interacted with it), the toggle button gets `aria-invalid="true"`, which
    applies shadcn's destructive error styling
  * `:aria-invalid` - set it explicitly to override the automatic value
  * `:variant` - `"default"` or `"outline"`
  * `:size` - `"default"`, `"sm"` or `"lg"`
  * `:disabled` - disables the toggle

  Every other global attribute (e.g. `aria-label`) is rendered on the `<button>`.
  """
  attr :id, :any, default: nil
  attr :name, :any, default: nil
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :value, :any, default: nil, doc: "whether the toggle is on"
  attr :"default-value", :any, values: [true, false, "true", "false"], default: false

  attr :disabled, :boolean, default: false
  attr :variant, :string, values: ~w(default outline), default: "default"
  attr :size, :string, values: ~w(default sm lg), default: "default"
  attr :"on-pressed-changed", :any, default: nil, doc: "handler for the pressed-changed event"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def toggle(assigns) do
    assigns =
      assigns
      |> prepare_assign()
      |> put_aria_invalid()

    assigns =
      assigns
      |> assign(:id, assigns.id || "toggle-#{System.unique_integer([:positive])}")
      |> assign_new(:checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", assigns.value) end)
      |> assign(:variant_class, toggle_variants(assigns))
      |> assign(:event_map, json(event_mappings(assigns)))

    ~H"""
    <button
      id={@id}
      type="button"
      disabled={@disabled}
      data-slot="toggle"
      data-component="toggle"
      data-part="root"
      data-state={if @checked, do: "on", else: "off"}
      data-disabled={@disabled && ""}
      data-event-mappings={@event_map}
      aria-pressed={to_string(@checked)}
      phx-hook="SaladUI"
      class={classes([@variant_class, @class])}
      {@rest}
    >
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        class="hidden"
        id={"#{@id}-input"}
        name={@name}
        value="true"
        checked={@checked}
        tabindex="-1"
      />
      {render_slot(@inner_block)}
    </button>
    """
  end

  @base_class "inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium whitespace-nowrap transition-[color,box-shadow] outline-none hover:bg-muted hover:text-muted-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 data-[state=on]:bg-accent data-[state=on]:text-accent-foreground dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4"

  @variants %{
    variant: %{
      "default" => "bg-transparent",
      "outline" => "border border-input bg-transparent shadow-xs hover:bg-accent hover:text-accent-foreground"
    },
    size: %{
      "default" => "h-9 min-w-9 px-2",
      "sm" => "h-8 min-w-8 px-1.5",
      "lg" => "h-10 min-w-10 px-2.5"
    }
  }

  @default_variants %{
    variant: "default",
    size: "default"
  }

  @doc """
  Returns the toggle classes for the given `:variant` and `:size` (shadcn's
  `toggleVariants`), shared with `SaladUI.ToggleGroup`. A `nil` variant or size
  falls back to `"default"`.
  """
  def toggle_variants(props) do
    variants =
      props
      |> Map.take(~w(variant size)a)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    variants = Map.merge(@default_variants, variants)

    Enum.join([@base_class | Enum.map(variants, fn {key, value} -> @variants[key][value] end)], " ")
  end
end
