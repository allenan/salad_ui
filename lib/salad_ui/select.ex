defmodule SaladUI.Select do
  @moduledoc """
  Implement of select components from https://ui.shadcn.com/docs/components/select

  ## Examples:

      <form>
        <.select id="fruit-select" name="fruit" default-value="banana">
          <.select_trigger class="w-[180px]">
            <.select_value placeholder="Select a fruit" />
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

  ## Typeahead

  While the list is open, typing highlights the next enabled item whose text
  starts with what was typed. Typing on the focused trigger while the list is
  closed selects that item directly (single selects only). The search clears
  after 1s, and typing one letter repeatedly cycles through the items starting
  with it. Match on other text than the item's label with `data-text-value`:

      <.select_item value="us" data-text-value="United States">🇺🇸 United States</.select_item>

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

  ## Disabled

  `disabled` on `select/1` disables the whole select, like Radix's
  `<Select disabled>`: the root renders `data-disabled="true"`, the trigger
  gets the disabled styling, the hook sets `disabled` on the trigger button
  and on the hidden inputs (so, like a disabled native select, nothing is
  submitted) and refuses to open, whether from a click, the keyboard or an
  `"open"`/`"toggle"` command.

      <.select id="disabled-select" name="fruit" disabled>
        <.select_trigger class="w-full max-w-48">
          <.select_value placeholder="Select a fruit" />
        </.select_trigger>
        <.select_content>
          <.select_item value="apple">Apple</.select_item>
          <.select_item value="grapes" disabled>Grapes</.select_item>
        </.select_content>
      </.select>

  ## Position

  `select_content/1` takes Radix's two positioning modes:

  * `position="item-aligned"` (the default, as in shadcn/ui and Radix) places the
    panel over the trigger so the selected item (or the first enabled one)
    sits exactly where the trigger shows its value, scrolling a long list so
    it can. `side` and `align` are ignored; when the panel cannot line up
    without leaving the window (the trigger is close to an edge), it falls
    back to popper placement. The item is lined up each time the dropdown
    opens; while it stays open the panel just follows the trigger, so page
    scrolls and LiveView patches keep the list where the user scrolled it.
  * `position="popper"` places the panel beside the trigger, on `side` (`top`,
    `right`, `bottom` or `left`, flipping when there is no room) with `align`
    (`start`, `center` or `end`). It is at least as wide as the trigger.

      <.select id="fruit" default-value="banana">
        <.select_trigger class="w-[180px]">
          <.select_value />
        </.select_trigger>
        <.select_content position="popper">
          <.select_item value="apple">Apple</.select_item>
          <.select_item value="banana">Banana</.select_item>
          <.select_item value="blueberry">Blueberry</.select_item>
        </.select_content>
      </.select>

  ## Modal behaviour

  As in Radix's Select, the open list is always modal: a click outside only
  closes it, everything outside the list is `aria-hidden`, and page scrolling
  is locked. See "Modal behaviour" in `SaladUI.DropdownMenu`.

  ## Validation

  When `field` has errors the root renders `data-invalid="true"`: the trigger
  picks up the destructive error styling and the JS hook mirrors it onto the
  trigger as `aria-invalid="true"` (and removes it again once the errors are
  fixed). You can also pass `aria-invalid` to `select_trigger/1` directly, as
  in shadcn; an explicit value wins over the field, for both the attribute and
  the styling.

  Only errors on inputs the user has interacted with count, following
  `Phoenix.Component.used_input?/1`.

  To render the trigger's `aria-invalid` (and `disabled`) on the server too,
  so they are already there in the dead render and before the hook mounts,
  take the select's state with `:let` and hand it to the trigger:

      <.select :let={select} field={@form[:fruit]}>
        <.select_trigger aria-invalid={select.invalid} disabled={select.disabled}>
          <.select_value placeholder="Select a fruit" />
        </.select_trigger>
        <.select_content>
          <.select_item value="apple">Apple</.select_item>
        </.select_content>
      </.select>

  The selected value is submitted through hidden inputs that the hook manages.
  LiveView never reports hidden-only fields as unused, and an empty select
  submits no value at all, so when `name` (or `field`) is set the root also
  renders a text input with the `hidden` attribute and the same name. For a
  single select it submits `""` ahead of the selected value, so an empty
  required select still reaches the changeset. For a multiple select it
  submits `name=""` (without `[]`) while nothing is selected, so clearing a
  multiple select reaches the changeset as an empty value and an empty
  required one is flagged after a submit; once something is selected it is
  `disabled`, named `name[]`, and only takes part in LiveView's used-input
  tracking. The hook dispatches its form `change` events from that input, so
  the select counts as used once the user picks a value or submits the form.

  ## Re-renders

  A LiveView re-render (such as the `phx-change` round trip of the surrounding
  form) keeps an open dropdown open, with its highlighted item and selection,
  and without firing `on-open` again; items the server adds or removes are
  picked up. A new `value` is selected in place without firing
  `on-value-changed`. A new `position`, `side` or `align` on `select_content/1`
  re-places an open dropdown. Changing other options (including `disabled`)
  rebuilds the select from the new markup.
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

  attr :disabled, :boolean,
    default: false,
    doc: "Disable the select: the trigger and hidden inputs are disabled and it cannot be opened"

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

  slot :inner_block,
    required: true,
    doc: "Receives `%{invalid: boolean, disabled: boolean}` via `:let`, to hand on to `select_trigger/1`"

  attr :rest, :global

  def select(assigns) do
    assigns = prepare_assign(assigns)

    assigns =
      assign(assigns,
        invalid: invalid?(assigns),
        tracking_name: tracking_name(assigns.name, assigns.multiple, assigns.value),
        tracking_disabled: assigns.disabled or (assigns.multiple and not empty_value?(assigns.value))
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
          disabled: assigns.disabled,
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
      data-disabled={@disabled && "true"}
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
        disabled={@tracking_disabled}
        tabindex="-1"
        autocomplete="off"
        aria-hidden="true"
        data-salad-ui-select-tracker="true"
      />
      {render_slot(@inner_block, %{invalid: @invalid, disabled: @disabled})}
    </div>
    """
  end

  # The input that lets LiveView's used-input tracking see the select (see
  # "Validation" in the moduledoc). Mirrors `syncTrackingInput()` in
  # select.js: an empty multiple select submits `name=""`, otherwise the
  # tracker is disabled and named like the hidden inputs (`name[]`).
  defp tracking_name(name, _multiple, _value) when name in [nil, ""], do: nil

  defp tracking_name(name, true, value) do
    base = name |> to_string() |> String.replace_suffix("[]", "")
    if empty_value?(value), do: base, else: base <> "[]"
  end

  defp tracking_name(name, _multiple, _value), do: to_string(name)

  defp empty_value?(value), do: value in [nil, "", []]

  @doc """
  The button that opens the dropdown and shows the selected value.

  ## Options

  * `:size` - `"default"` (`h-9`) or `"sm"` (`h-8`).
  * `:aria-invalid` - Error state. The hook mirrors a `field` error onto the
    trigger; pass `aria-invalid={select.invalid}` (from `:let` on `select/1`)
    to render it on the server too. `true` renders as `"true"`.
  * `:disabled` - Disables the button. `disabled` on `select/1` already does
    this from the hook; pass `disabled={select.disabled}` to render it on the
    server too.
  * `:class` - Additional CSS classes.
  """
  attr :class, :string, default: nil
  attr :size, :string, values: ~w(default sm), default: "default", doc: "the trigger height"
  slot :inner_block, required: true
  attr :rest, :global, include: ~w(disabled form name value)

  def select_trigger(assigns) do
    # A boolean `aria-invalid` renders as `aria-invalid=""`, which the
    # `aria-invalid:` variant (`[aria-invalid="true"]`) does not match.
    assigns =
      case assigns.rest do
        %{"aria-invalid": true} -> assign(assigns, :rest, Map.put(assigns.rest, :"aria-invalid", "true"))
        _ -> assigns
      end

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
          "group-data-[disabled=true]/select:cursor-not-allowed group-data-[disabled=true]/select:opacity-50",
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

  * `:position` - `"item-aligned"` (default, as in shadcn/ui) places the panel
    over the trigger with the selected item lined up on the trigger's value,
    falling back to popper near the window edges; `"popper"` places it beside
    the trigger, on `side` with `align`. See "Position" in `SaladUI.Select`.
  * `:side` - Preferred side of the trigger in popper mode (`"top"`,
    `"right"`, `"bottom"` or `"left"`). Flips when there is no room.
  * `:align` - Alignment against the trigger in popper mode (`"start"`,
    `"center"` or `"end"`). Defaults to `"center"`, as in shadcn/ui (it only
    matters when the panel is wider than the trigger).
  * `:collision-padding` - Distance in pixels kept from the viewport edges when
    the popper panel flips or shifts to stay visible. Defaults to `0`, as in
    Radix (the item-aligned panel keeps its own margin).
  * `:class` - Additional CSS classes.
  """
  attr :class, :string, default: nil
  attr :position, :string, values: ~w(popper item-aligned), default: "item-aligned"
  attr :side, :string, values: ~w(top right bottom left), default: "bottom"
  attr :align, :string, values: ~w(start center end), default: "center"
  attr :"collision-padding", :integer, default: 0, doc: "Distance kept from the viewport edges"
  slot :inner_block, required: true

  attr :rest, :global

  def select_content(assigns) do
    # Where the panel sits before the hook positions it (it is hidden until
    # then, so this only matters without JS).
    position_class =
      case assigns.side do
        "top" -> "bottom-full mb-1"
        "bottom" -> "top-full mt-1"
        "left" -> "right-full top-0 mr-1"
        "right" -> "left-full top-0 ml-1"
      end

    assigns = assign(assigns, position_class: position_class, collision_padding: assigns[:"collision-padding"])

    ~H"""
    <div
      data-slot="select-content"
      data-part="content"
      data-position={@position}
      data-side={@side}
      data-align={@align}
      data-collision-padding={@collision_padding}
      style="min-width: var(--salad-reference-width)"
      hidden
      class={
        classes([
          "absolute flex min-w-full flex-col",
          "z-50 max-h-[min(24rem,var(--salad-select-content-available-height,24rem))] min-w-[8rem] overflow-hidden rounded-md border border-border bg-popover text-popover-foreground shadow-md data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
          @position == "popper" &&
            "data-[side=bottom]:translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1 data-[side=top]:-translate-y-1",
          @position_class,
          @class
        ])
      }
      {@rest}
    >
      <.select_scroll_up_button />
      <div
        data-part="viewport"
        class={
          classes([
            "relative min-h-0 w-full flex-1 overflow-y-auto p-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden",
            @position == "popper" &&
              "h-[var(--salad-select-trigger-height)] min-w-[var(--salad-select-trigger-width)] scroll-my-1"
          ])
        }
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
      class={classes(["px-2 py-1.5 text-xs text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  An option in the list.

  Like shadcn, the check that marks the selected item sits on the end side
  (right, or left under `dir="rtl"`), and the item text is a flex row, so an
  icon or swatch placed before the label lines up with it:

      <.select_item value="online">
        <span class="size-2 rounded-full bg-green-500"></span> Online
      </.select_item>

  ## Options

  * `:value` - The value submitted when this item is selected (required).
  * `:disabled` - Makes the item unselectable and skipped by the keyboard.
  * `:class` - Additional CSS classes.
  """
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
          "relative flex w-full cursor-default items-center gap-2 rounded-sm py-1.5 pe-8 ps-2 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground *:[span]:last:flex *:[span]:last:items-center *:[span]:last:gap-2",
          @class
        ])
      }
      tabindex={(@disabled && "-1") || "0"}
      {@rest}
    >
      <span
        data-slot="select-item-indicator"
        class="absolute end-2 flex size-3.5 items-center justify-center"
      >
        <span data-part="item-indicator" hidden>
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

  @doc """
  A horizontal rule between items or groups.
  """
  attr :class, :string, default: nil
  attr :rest, :global

  def select_separator(assigns) do
    ~H"""
    <div
      data-slot="select-separator"
      data-part="separator"
      aria-hidden="true"
      class={classes(["pointer-events-none -mx-1 my-1 h-px bg-border", @class])}
      {@rest}
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
