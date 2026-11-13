defmodule SaladUI.ToggleGroup do
  @moduledoc """
  Implementation of the toggle group component from https://ui.shadcn.com/docs/components/toggle-group

  A set of two-state buttons that can be toggled on or off.

  The group hands a `builder` to its slot (`:let={builder}`); pass it to every
  `toggle_group_item/1` so the items pick up the group's type, name, value,
  variant, size, spacing and orientation (shadcn does this with React context).

  ## Examples:

      <.toggle_group :let={builder} id="text-style" type="multiple" variant="outline">
        <.toggle_group_item value="bold" builder={builder} aria-label="Toggle bold">
          <.icon name="hero-bold" class="size-4" />
        </.toggle_group_item>
        <.toggle_group_item value="italic" builder={builder} aria-label="Toggle italic">
          <.icon name="hero-italic" class="size-4" />
        </.toggle_group_item>
      </.toggle_group>

      <.toggle_group :let={builder} id="align" type="single" value="left" spacing={2}>
        <.toggle_group_item value="left" builder={builder}>Left</.toggle_group_item>
        <.toggle_group_item value="right" builder={builder}>Right</.toggle_group_item>
      </.toggle_group>

  With a form field (or a `name`), a `"single"` group submits the pressed value
  under the field name and a `"multiple"` group submits a list under `name[]`.
  An unpressed radio submits nothing, so a `"single"` group also renders a
  hidden input with an empty value ahead of its items (as `SaladUI.RadioGroup`
  does): releasing the pressed item submits `""` and reaches the changeset.

      <.toggle_group :let={builder} field={@form[:style]} type="multiple">
        ...
      </.toggle_group>

  ## Keyboard

  Like Radix, the group is a single tab stop with a roving tabindex: the arrow
  keys on the group's axis move focus between the enabled items (Left/Right
  follow the reading direction, so they are mirrored under `dir="rtl"`), Home
  and End jump to the first and last item, and focus wraps around unless
  `loop={false}`. Space and Enter toggle the focused item.

  ## Component events

  * `:on-value-changed` - Maps the `value-changed` event, fired with
    `%{"value" => value}` when an item is toggled. `value` is the pressed
    item's value (or `""`) for `type="single"` and a list for `type="multiple"`.

  ## Server commands

  Toggle group does not support `SaladUI.LiveView.send_command/4`. To change the
  pressed items from the server, update the `value` assign and let LiveView re-render.

  ## Controlled and uncontrolled

  As with Radix's `value` and `defaultValue`:

  * With `value` (or a `field`) the group is controlled: every LiveView
    re-render shows the server's value, and once the server has handled the
    `on-value-changed` event (mapped to an event name) the group shows the
    server's value again even if it did not change. So the server can refuse
    a change, e.g. keep a `type="single"` group from being emptied by
    re-rendering the same value.
  * With only `default-value` the group is uncontrolled: the pressed items
    survive unrelated re-renders; while the server keeps rendering the same
    value the hook keeps what the user pressed.
  """
  use SaladUI, :component

  import SaladUI.Toggle, only: [toggle_variants: 1]

  @doc """
  Renders a toggle group.

  ## Attributes

  * `:type` - `"single"` (one item pressed at a time, the default) or `"multiple"`
  * `:value` / `:default-value` - the pressed value (`"single"`) or list of values (`"multiple"`)
  * `:variant` - `"default"` or `"outline"`, applied to every item
  * `:size` - `"default"`, `"sm"` or `"lg"`, applied to every item
  * `:spacing` - gap between the items in Tailwind spacing units; `0` (the
    default) renders connected items with shared borders
  * `:orientation` - `"horizontal"` (default) or `"vertical"`
  * `:loop` - whether keyboard focus wraps around (default `true`)
  * `:disabled` - disables every item
  """
  attr :id, :string, default: nil, doc: "the hook needs an id; one is generated when omitted"
  attr :name, :string, default: nil
  attr :type, :string, values: [nil, "single", "multiple"], default: nil, doc: ~s{"single" (default) or "multiple"}

  attr :multiple, :any,
    values: [true, false, "true", "false"],
    default: false,
    doc: "legacy alias for type=\"multiple\""

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :"default-value", :any, default: nil, doc: "The value used when `value` is empty."

  attr :value, :any,
    default: nil,
    doc: "The value of the toggle group. It's a single value for single type and a list of values for multiple type."

  attr :disabled, :boolean, default: false
  attr :variant, :string, values: [nil, "default", "outline"], default: nil
  attr :size, :string, values: [nil, "default", "sm", "lg"], default: nil
  attr :spacing, :integer, default: 0, doc: "gap between items, in Tailwind spacing units"
  attr :orientation, :string, values: ~w(horizontal vertical), default: "horizontal"
  attr :loop, :boolean, default: true, doc: "whether arrow-key focus wraps around"
  attr :"on-value-changed", :any, default: nil, doc: "handler for the value-changed event"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block

  def toggle_group(assigns) do
    multiple = assigns.type == "multiple" or assigns.multiple in [true, "true"]
    # Like Radix's `value` prop: a group given `value` (or a form field) shows
    # the server's value; one given only `default-value` keeps its own.
    controlled = not is_nil(assigns.value) or not is_nil(assigns[:field])

    assigns =
      assigns
      |> assign(:multiple, multiple)
      |> prepare_assign()
      |> put_aria_invalid()

    value = normalize_value!(assigns.value, multiple)
    id = assigns.id || "toggle-group-#{System.unique_integer([:positive])}"

    name = input_name(assigns.name, multiple)

    builder = %{
      id: id,
      name: name,
      type: if(multiple, do: "multiple", else: "single"),
      multiple: multiple,
      value: value,
      disabled: assigns.disabled,
      variant: assigns.variant,
      size: assigns.size,
      spacing: assigns.spacing,
      orientation: assigns.orientation,
      invalid: assigns.rest[:"aria-invalid"] in [true, "true"]
    }

    {style, rest} = Map.pop(assigns.rest, :style)

    assigns =
      assign(assigns,
        id: id,
        name: name,
        builder: builder,
        rest: rest,
        style: Enum.join(["--gap: #{assigns.spacing}" | List.wrap(style)], "; "),
        event_map: json(event_mappings(assigns)),
        options:
          json(%{
            type: builder.type,
            orientation: assigns.orientation,
            loop: assigns.loop,
            disabled: assigns.disabled,
            controlled: controlled
          })
      )

    ~H"""
    <div
      id={@id}
      role="group"
      data-slot="toggle-group"
      data-component="toggle-group"
      data-part="root"
      data-state="idle"
      data-variant={@variant}
      data-size={@size}
      data-spacing={@spacing}
      data-orientation={@orientation}
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      style={@style}
      class={
        classes([
          "group/toggle-group flex w-fit items-center gap-[--spacing(var(--gap))] rounded-md data-[spacing=default]:data-[variant=outline]:shadow-xs",
          "data-[orientation=vertical]:flex-col data-[orientation=vertical]:items-stretch",
          @class
        ])
      }
      {@rest}
    >
      <input :if={@name && !@multiple} type="hidden" name={@name} value="" />
      {render_slot(@inner_block, @builder)}
    </div>
    """
  end

  # A multiple group submits a list, so its checkboxes need a `name[]`.
  defp input_name(name, _multiple) when name in [nil, ""], do: nil

  defp input_name(name, true = _multiple) do
    name = to_string(name)
    if String.ends_with?(name, "[]"), do: name, else: name <> "[]"
  end

  defp input_name(name, _multiple), do: to_string(name)

  defp normalize_value!(value, true = _multiple) do
    case value do
      nil -> []
      "" -> []
      list when is_list(list) -> Enum.map(list, &to_string/1)
      _ -> raise ArgumentError, "The value of the toggle group must be a list for multiple type."
    end
  end

  defp normalize_value!(value, false = _multiple) do
    cond do
      is_nil(value) -> nil
      is_binary(value) or is_atom(value) or is_number(value) -> to_string(value)
      true -> raise ArgumentError, "The value of the toggle group must be a single value for single type."
    end
  end

  @doc """
  Renders an item of a toggle group.

  ## Attributes

  * `:builder` - the builder the group passes to its slot (required)
  * `:value` - the value the item stands for
  * `:disabled` - disables this item
  * `:variant` / `:size` - used when the group does not set them

  Every other global attribute (e.g. `aria-label`, `aria-invalid`) is rendered on the `<button>`.
  """
  attr :class, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :value, :string, default: nil
  attr :variant, :string, values: [nil, "default", "outline"], default: nil
  attr :size, :string, values: [nil, "default", "sm", "lg"], default: nil
  attr :builder, :map, required: true, doc: "The builder context of toggle group."
  attr :rest, :global
  slot :inner_block

  def toggle_group_item(assigns) do
    builder = assigns.builder
    multiple = builder[:multiple] == true
    variant = builder[:variant] || assigns.variant || "default"
    size = builder[:size] || assigns.size || "default"

    assigns =
      assign(assigns,
        multiple: multiple,
        pressed: item_pressed?(assigns.value, builder[:value], multiple),
        item_disabled: assigns.disabled || builder[:disabled] == true,
        resolved_variant: variant,
        resolved_size: size,
        spacing: builder[:spacing] || 0,
        orientation: builder[:orientation] || "horizontal",
        rest: item_rest(assigns.rest, builder[:invalid]),
        variant_class: toggle_variants(%{variant: variant, size: size})
      )

    ~H"""
    <button
      type="button"
      data-slot="toggle-group-item"
      data-part="item"
      data-value={@value}
      data-variant={@resolved_variant}
      data-size={@resolved_size}
      data-spacing={@spacing}
      data-orientation={@orientation}
      data-state={if @pressed, do: "on", else: "off"}
      data-disabled={@item_disabled && ""}
      role={if !@multiple, do: "radio"}
      aria-checked={if !@multiple, do: to_string(@pressed)}
      aria-pressed={if @multiple, do: to_string(@pressed)}
      disabled={@item_disabled}
      class={
        classes([
          @variant_class,
          "w-auto min-w-0 shrink-0 px-3 focus:z-10 focus-visible:z-10",
          "data-[spacing=0]:rounded-none data-[spacing=0]:shadow-none",
          "data-[spacing=0]:data-[orientation=horizontal]:first:rounded-s-md data-[spacing=0]:data-[orientation=horizontal]:last:rounded-e-md data-[spacing=0]:data-[orientation=horizontal]:data-[variant=outline]:border-s-0 data-[spacing=0]:data-[orientation=horizontal]:data-[variant=outline]:first:border-s",
          "data-[spacing=0]:data-[orientation=vertical]:first:rounded-t-md data-[spacing=0]:data-[orientation=vertical]:last:rounded-b-md data-[spacing=0]:data-[orientation=vertical]:data-[variant=outline]:border-t-0 data-[spacing=0]:data-[orientation=vertical]:data-[variant=outline]:first:border-t",
          @class
        ])
      }
      {@rest}
    >
      <input
        type={if @multiple, do: "checkbox", else: "radio"}
        class="hidden"
        name={@builder[:name]}
        value={@value}
        checked={@pressed}
        tabindex="-1"
      />
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp item_pressed?(nil, _group_value, _multiple), do: false
  defp item_pressed?(value, group_value, true), do: to_string(value) in List.wrap(group_value)
  defp item_pressed?(value, group_value, false), do: to_string(value) == group_value

  # Field errors on the group mark every item invalid unless the item says otherwise.
  defp item_rest(rest, true = _invalid), do: Map.put_new(rest, :"aria-invalid", "true")
  defp item_rest(rest, _invalid), do: rest
end
