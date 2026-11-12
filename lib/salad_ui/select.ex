defmodule SaladUI.Select do
  @moduledoc """
  Implement of select components from https://ui.shadcn.com/docs/components/select

  ## Examples:

      <form>
         <.select default="banana" id="fruit-select">
            <.select_trigger class="w-[180px]">
              <.select_value placeholder=".select a fruit"/>
            </.select_trigger>
            <.select_content>
              <.select_group>
                <.select_label>Fruits</.select_label>
                <.select_item value="apple">Apple</.select_item>
                <.select_item value="banana">Banana</.select_item>
                <.select_item value="blueberry">Blueberry</.select_item>
                <.select_separator />
                <.select_item disabled value="grapes">Grapes</.select_item>
                <.select_item value="pineapple">Pineapple</.select_item>
              </.select_group>
        </.select_content>
          </.select>

        <.button type="submit">Submit</.button>
      </form>

  ## Size

  `select_trigger/1` takes `size="sm"` for a compact (`h-8`) trigger:

      <.select id="small-select" placeholder="Theme">
        <.select_trigger size="sm" class="w-[140px]">
          <.select_value placeholder="Theme" />
        </.select_trigger>
        <.select_content>
          <.select_item value="light">Light</.select_item>
          <.select_item value="dark">Dark</.select_item>
        </.select_content>
      </.select>

  ## Scrolling

  `select_content/1` caps its height at `24rem`, or at the room left in the
  window beside the trigger when that is smaller; longer lists scroll inside
  its viewport. Like shadcn, it renders `select_scroll_up_button/1` and
  `select_scroll_down_button/1` above and below the items. The hook shows each
  one only while there is more to scroll in its direction, and hovering one
  scrolls the list.

  ## Component events

  * `:on-value-changed` - Maps the `value-changed` event. Fired when the selected value changes.
  * `:on-open` - Maps the `open` event. Fired when the select dropdown enters open state.
  * `:on-close` - Maps the `close` event. Fired when the select dropdown enters closed state.

  ## Server commands

  * `"open"` - Opens the select dropdown.
  * `"close"` - Closes the select dropdown.
  * `"toggle"` - Toggles the select dropdown.

  Changing the selected value from the server is done through the controlled
  `value` assign rather than `SaladUI.LiveView.send_command/4`.

  ## Validation

  When `field` has errors the root renders `data-invalid="true"`: the trigger
  picks up the destructive error styling and the JS hook mirrors it onto the
  trigger as `aria-invalid="true"` (and removes it again once the errors are
  fixed). You can also pass `aria-invalid` to `select_trigger/1` directly, as
  in shadcn; an explicit value wins over the field, for both the attribute and
  the styling.

  Only errors on inputs the user has interacted with count, following
  `Phoenix.Component.used_input?/1`. The trigger's `aria-invalid` is added by
  the hook, so it is missing from a dead render.

  The selected value is submitted through hidden inputs that the hook manages.
  LiveView never reports hidden-only fields as unused, and an empty select
  submits no value at all, so when `name` (or `field`) is set the root also
  renders a text input with the `hidden` attribute and the same name. For a
  single select it submits `""` ahead of the selected value, so an empty
  required select still reaches the changeset. For a multiple select it is
  `disabled` and only takes part in LiveView's used-input tracking. The hook
  dispatches its form `change` events from that input, so the select counts as
  used once the user picks a value or submits the form.
  """
  use SaladUI, :component

  @doc """
  Ready to use select component with all required parts.

  ## Component events

  * `:on-value-changed` - Fired when the selected value changes.
  * `:on-open` - Fired when the dropdown opens.
  * `:on-close` - Fired when the dropdown closes.

  ## Server commands

  * `"open"` - Opens the select dropdown.
  * `"close"` - Closes the select dropdown.
  * `"toggle"` - Toggles the select dropdown.
  """

  attr :id, :string, default: nil
  attr :name, :any, default: nil
  attr :value, :any, default: nil, doc: "The value of the select"
  attr :"default-value", :any, default: nil, doc: "The default value of the select"
  attr :multiple, :boolean, default: false, doc: "Allow multiple selection"
  attr :"use-portal", :boolean, default: false, doc: "Whether to render the content in a portal"
  attr :"portal-container", :string, default: nil, doc: "CSS selector for the portal container"
  attr :"on-value-changed", :any, default: nil, doc: "Handler for value changed event"
  attr :"on-open", :any, default: nil, doc: "Handler for select open event"
  attr :"on-close", :any, default: nil, doc: "Handler for select closed event"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :label, :string,
    default: nil,
    doc: "The display label of the select value. If not provided, the value will be used."

  attr :placeholder, :string, default: nil, doc: "The placeholder text when no value is selected."

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def select(assigns) do
    assigns = prepare_assign(assigns)

    assigns =
      assign(assigns,
        invalid: invalid?(assigns),
        tracking_name: tracking_name(assigns.name, assigns.multiple)
      )

    # Collect event mappings
    event_map = event_mappings(assigns)

    assigns =
      assigns
      |> assign(:event_map, json(event_map))
      |> assign(
        :options,
        json(%{
          defaultValue: assigns[:"default-value"],
          value: assigns.value,
          name: assigns.name,
          multiple: assigns.multiple,
          usePortal: assigns[:"use-portal"],
          portalContainer: assigns[:"portal-container"],
          animations: get_animation_config()
        })
      )

    ~H"""
    <div
      data-slot="select"
      id={@id}
      class={classes(["group/select relative inline-flex", @class])}
      data-part="root"
      data-component="select"
      data-invalid={@invalid && "true"}
      data-state="closed"
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      {@rest}
    >
      <input
        :if={@tracking_name}
        type="text"
        hidden
        name={@tracking_name}
        value=""
        disabled={@multiple}
        tabindex="-1"
        autocomplete="off"
        aria-hidden="true"
        data-salad-ui-select-tracker="true"
      />
      {render_slot(@inner_block)}
    </div>
    """
  end

  # The input that lets LiveView's used-input tracking see the select (see
  # "Validation" in the moduledoc). Mirrors `getInputName()` in select.js.
  defp tracking_name(name, _multiple) when name in [nil, ""], do: nil

  defp tracking_name(name, true) do
    name = to_string(name)
    if String.ends_with?(name, "[]"), do: name, else: name <> "[]"
  end

  defp tracking_name(name, _multiple), do: to_string(name)

  @doc """
  The button that opens the dropdown and shows the selected value.

  ## Options

  * `:size` - `"default"` (`h-9`) or `"sm"` (`h-8`).
  * `:class` - Additional CSS classes.
  """
  attr :class, :string, default: nil
  attr :size, :string, values: ~w(default sm), default: "default", doc: "the trigger height"
  slot :inner_block, required: true
  attr :rest, :global

  def select_trigger(assigns) do
    ~H"""
    <button
      type="button"
      data-part="trigger"
      data-slot="select-trigger"
      data-size={@size}
      class={
        classes([
          "flex w-fit items-center justify-between gap-2 rounded-md border border-input bg-transparent px-3 py-2 text-sm whitespace-nowrap shadow-xs transition-[color,box-shadow] outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 data-[placeholder]:text-muted-foreground data-[size=default]:h-9 data-[size=sm]:h-8 *:data-[slot=select-value]:line-clamp-1 *:data-[slot=select-value]:flex *:data-[slot=select-value]:items-center *:data-[slot=select-value]:gap-2 dark:bg-input/30 dark:hover:bg-input/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground",
          "group-data-[invalid=true]/select:not-aria-[invalid=false]:border-destructive group-data-[invalid=true]/select:not-aria-[invalid=false]:ring-destructive/20 dark:group-data-[invalid=true]/select:not-aria-[invalid=false]:ring-destructive/40",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
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
        class="lucide lucide-chevron-down size-4 opacity-50"
        aria-hidden="true"
      >
        <path d="M6 9l6 6 6-6"></path>
      </svg>
    </button>
    """
  end

  attr :placeholder, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def select_value(assigns) do
    ~H"""
    <span
      data-part="value"
      data-slot="select-value"
      class={classes(["select-value pointer-events-none", @class])}
      data-content={@placeholder}
      data-placeholder={@placeholder}
      {@rest}
    >{@placeholder}</span>
    """
  end

  @doc """
  The dropdown panel holding the items.

  Items render inside a scrollable viewport (`data-part="viewport"`) between
  a scroll-up and a scroll-down button, which the hook shows only while the
  list can scroll that way.

  ## Options

  * `:side` - Preferred side of the trigger (`"top"` or `"bottom"`). Flips when there is no room.
  * `:class` - Additional CSS classes.
  """
  attr :class, :string, default: nil
  attr :side, :string, values: ~w(top bottom), default: "bottom"
  slot :inner_block, required: true

  attr :rest, :global

  def select_content(assigns) do
    position_class =
      case assigns.side do
        "top" -> "bottom-full mb-1"
        "bottom" -> "top-full mt-1"
      end

    assigns =
      assign(assigns, :position_class, position_class)

    ~H"""
    <div
      data-slot="select-content"
      data-part="content"
      data-side={@side}
      style="min-width: var(--salad-reference-width)"
      hidden
      class={
        classes([
          "absolute flex min-w-full flex-col",
          "z-50 max-h-[min(24rem,var(--salad-select-content-available-height,24rem))] min-w-[8rem] overflow-hidden rounded-md border border-border bg-popover text-popover-foreground shadow-md data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
          @position_class,
          @class
        ])
      }
      {@rest}
    >
      <.select_scroll_up_button />
      <div
        data-part="viewport"
        class="relative min-h-0 w-full flex-1 overflow-y-auto p-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
      >
        {render_slot(@inner_block)}
      </div>
      <.select_scroll_down_button />
    </div>
    """
  end

  @doc """
  Scrolls the list up while hovered. `select_content/1` renders one for you;
  the hook hides it until the viewport is scrolled down.
  """
  attr :class, :string, default: nil
  attr :rest, :global

  def select_scroll_up_button(assigns) do
    ~H"""
    <div
      data-slot="select-scroll-up-button"
      data-part="scroll-up-button"
      aria-hidden="true"
      hidden
      class={classes(["flex cursor-default items-center justify-center py-1", @class])}
      {@rest}
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
        class="lucide lucide-chevron-up size-4"
      >
        <path d="m18 15-6-6-6 6"></path>
      </svg>
    </div>
    """
  end

  @doc """
  Scrolls the list down while hovered. `select_content/1` renders one for
  you; the hook shows it while there are items below the visible area.
  """
  attr :class, :string, default: nil
  attr :rest, :global

  def select_scroll_down_button(assigns) do
    ~H"""
    <div
      data-slot="select-scroll-down-button"
      data-part="scroll-down-button"
      aria-hidden="true"
      hidden
      class={classes(["flex cursor-default items-center justify-center py-1", @class])}
      {@rest}
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
        class="lucide lucide-chevron-down size-4"
      >
        <path d="m6 9 6 6 6-6"></path>
      </svg>
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def select_group(assigns) do
    ~H"""
    <div data-slot="select-group" data-part="group" class={classes([@class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def select_label(assigns) do
    ~H"""
    <div
      data-slot="select-label"
      data-part="label"
      class={classes(["py-1.5 pl-8 pr-2 text-sm font-semibold", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def select_item(assigns) do
    ~H"""
    <div
      data-slot="select-item"
      data-part="item"
      data-value={@value}
      data-disabled={@disabled && "true"}
      class={
        classes([
          "relative flex w-full cursor-default select-none items-center rounded-xs py-1.5 pl-8 pr-2 text-sm outline-hidden focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
          @class
        ])
      }
      tabindex={(@disabled && "-1") || "0"}
      {@rest}
    >
      <span class="absolute left-2 flex size-3.5 items-center justify-center">
        <span data-slot="select-item-indicator" data-part="item-indicator" hidden>
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
            class="size-4"
          >
            <path d="M20 6 9 17l-5-5"></path>
          </svg>
        </span>
      </span>

      <span data-part="item-text">{render_slot(@inner_block)}</span>
    </div>
    """
  end

  def select_separator(assigns) do
    ~H"""
    <div
      data-slot="select-separator"
      data-part="separator"
      class={classes(["-mx-1 my-1 h-px bg-muted"])}
    >
    </div>
    """
  end

  defp get_animation_config do
    %{
      "open_to_closed" => %{
        duration: 130,
        target_part: "content"
      }
    }
  end
end
