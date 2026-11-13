defmodule SaladUI.Combobox do
  @moduledoc """
  Autocomplete input with a list of suggestions, from
  https://ui.shadcn.com/docs/components/combobox

  A combobox is a text input that filters a listbox of options as you type.
  It supports single selection, multiple selection shown as chips, groups,
  an empty state, a clear button, server-side filtering and form fields. It
  needs the `assets/salad_ui/components/combobox.js` component.

  ## Composition

      combobox
      ├── combobox_input            (or combobox_chips + combobox_chips_input)
      └── combobox_content
          ├── combobox_empty
          └── combobox_list
              ├── combobox_group
              │   ├── combobox_label
              │   ├── combobox_item
              │   └── combobox_separator
              └── combobox_item

  shadcn's `ComboboxCollection` and the `items` render prop are not needed:
  render the items with `:for`.

  ## Examples

  Basic:

      <.combobox id="framework" name="framework">
        <.combobox_input placeholder="Select a framework" />
        <.combobox_content>
          <.combobox_empty>No items found.</.combobox_empty>
          <.combobox_list>
            <.combobox_item :for={framework <- ~w(Next.js SvelteKit Nuxt.js Remix Astro)} value={framework}>
              {framework}
            </.combobox_item>
          </.combobox_list>
        </.combobox_content>
      </.combobox>

  Multiple selection with chips. The chips are rendered by the JS component
  from the selected values, in front of the chips input:

      <.combobox id="frameworks" name="frameworks" multiple auto-highlight default-value={["Next.js"]}>
        <.combobox_chips class="w-full max-w-xs">
          <.combobox_chips_input placeholder="Add framework" />
        </.combobox_chips>
        <.combobox_content>
          <.combobox_empty>No items found.</.combobox_empty>
          <.combobox_list>
            <.combobox_item :for={framework <- @frameworks} value={framework}>{framework}</.combobox_item>
          </.combobox_list>
        </.combobox_content>
      </.combobox>

  Groups with labels and separators:

      <.combobox id="timezone">
        <.combobox_input placeholder="Select a timezone" />
        <.combobox_content>
          <.combobox_empty>No timezones found.</.combobox_empty>
          <.combobox_list>
            <.combobox_group :for={{group, index} <- Enum.with_index(@timezones)}>
              <.combobox_label>{group.label}</.combobox_label>
              <.combobox_item :for={zone <- group.items} value={zone}>{zone}</.combobox_item>
              <.combobox_separator :if={index < length(@timezones) - 1} />
            </.combobox_group>
          </.combobox_list>
        </.combobox_content>
      </.combobox>

  Popup: a button opens the list, with the search input inside the content:

      <.combobox id="country" default-value="ar">
        <.combobox_trigger variant="outline" class="w-64 justify-between font-normal">
          <.combobox_value placeholder="Select a country" />
        </.combobox_trigger>
        <.combobox_content>
          <.combobox_input show-trigger={false} placeholder="Search" />
          <.combobox_empty>No items found.</.combobox_empty>
          <.combobox_list>
            <.combobox_item :for={country <- @countries} value={country.code}>{country.label}</.combobox_item>
          </.combobox_list>
        </.combobox_content>
      </.combobox>

  ## Labels

  The text an item is matched against, and shown in the input, the chips and
  `combobox_value/1` once selected, is its `label`, falling back to its text
  content. Pass `label` when an item renders more than its name.

  ## Filtering

  By default the JS component filters the items on the client: an item stays
  visible when its label contains the typed text (case-insensitive). Groups
  with no visible items are hidden, separators are hidden while a query is
  typed, and `combobox_empty/1` is shown when nothing matches.

  ## Server filtering

  Set `filter={false}` and let the server render the matching items. Put the
  combobox in a form, name the input and debounce it; the form's `phx-change`
  receives the query with the other form params:

      <.form for={@form} phx-change="search">
        <.combobox id="user" field={@form[:user_id]} filter={false}>
          <.combobox_input name="query" value={@query} phx-debounce="300" placeholder="Search users" />
          <.combobox_content>
            <.combobox_empty>No users found.</.combobox_empty>
            <.combobox_list>
              <.combobox_item :for={user <- @users} value={user.id} label={user.name}>{user.name}</.combobox_item>
            </.combobox_list>
          </.combobox_content>
        </.combobox>
      </.form>

      def handle_event("search", %{"query" => query}, socket) do
        {:noreply, assign(socket, query: query, users: Accounts.search_users(query))}
      end

  The open popup, the highlighted item and the selection survive the patch.
  The list may also be a stream: give `combobox_list/1` an `id` and
  `phx-update="stream"`, and each item its stream `id`.
  When the query is cleared by the component (after a pick in a multiple
  combobox, or by the clear button) it dispatches an `input` event, so the
  server is asked for the unfiltered list again.

  ## Forms

  With `name` (or `field`) the selected value is submitted through hidden
  inputs the JS component keeps in sync, as `name` for a single combobox and
  `name[]` for a multiple one. Like `SaladUI.Select`, the root also renders a
  hidden text input with the same name so LiveView's used-input tracking sees
  the combobox, and the component dispatches the form's `change` event from it
  when the value changes. When the `field` has errors (on a used input) the
  input group or chips get the destructive styling and the input gets
  `aria-invalid="true"`.

  ## Keyboard

  * `ArrowDown` / `ArrowUp` - open the list, then move the highlight (wrapping).
  * `Alt+ArrowDown` / `Alt+ArrowUp` - open the list without highlighting / close it.
  * `Enter` - select the highlighted item.
  * `Escape` - close the list.
  * `Backspace` - in an empty chips input, remove the last chip.
  * `ArrowLeft` - at the start of the chips input, focus the last chip. On a
    chip, `ArrowLeft` / `ArrowRight` move between the chips and back to the
    input, `Backspace` / `Delete` remove it and `Escape` returns to the input
    (the arrows swap in a right-to-left layout).

  The input keeps focus while the list is open and points at the highlighted
  option with `aria-activedescendant`, following the WAI-ARIA combobox pattern.

  ## Component events

  * `:on-value-changed` - Maps the `value-changed` event, with `%{"value" => value}`
    (a list for a multiple combobox).
  * `:on-open` - Maps the `open` event. Fired when the list opens.
  * `:on-close` - Maps the `close` event. Fired when the list closes.

  ## Server commands

  * `"open"`, `"close"`, `"toggle"` - Open or close the list.
  * `"clear"` - Clear the selection and the query.

  A new `value` from the server replaces the client selection.
  """
  use SaladUI, :component

  # Mirrors SaladUI.InputGroup's group classes; the combobox renders its own
  # group so the input stays inside the combobox hook (a nested `input_group`
  # would carry its own hook and hide the input from the combobox).
  @input_group_class [
    "group/input-group relative flex w-full items-center rounded-md border border-input shadow-xs transition-[color,box-shadow] outline-none dark:bg-input/30",
    "h-9 min-w-0 has-[>textarea]:h-auto",
    "has-[>[data-align=inline-start]]:[&>input]:ps-2",
    "has-[>[data-align=inline-end]]:[&>input]:pe-2",
    "has-[[data-slot=input-group-control]:focus-visible]:border-ring has-[[data-slot=input-group-control]:focus-visible]:ring-[3px] has-[[data-slot=input-group-control]:focus-visible]:ring-ring/50",
    "has-[[data-slot][aria-invalid=true]]:border-destructive has-[[data-slot][aria-invalid=true]]:ring-destructive/20 dark:has-[[data-slot][aria-invalid=true]]:ring-destructive/40",
    "group-data-[invalid=true]/combobox:border-destructive group-data-[invalid=true]/combobox:ring-destructive/20 dark:group-data-[invalid=true]/combobox:ring-destructive/40",
    "data-[disabled=true]:opacity-50"
  ]

  @doc """
  The combobox root. It renders no box of its own (`display: contents`).

  ## Options

  * `:id` - Required. Identifies the combobox for the JS hook.
  * `:name` - Name of the hidden input(s) that submit the value.
  * `:value` - The selected value (a list when `multiple`). A new value from
    the server replaces the client selection.
  * `:default-value` - The initial value when `value` is not set.
  * `:field` - A `Phoenix.HTML.FormField`; sets `id`, `name`, `value` and the
    invalid state.
  * `:multiple` - Select several values, shown as chips.
  * `:auto-highlight` - Highlight the first matching item while typing, so
    `Enter` picks it.
  * `:filter` - `true` (default) filters on the client; `false` leaves the
    rendered items untouched, for server-side filtering.
  * `:disabled` - Disables the whole combobox.
  """
  attr :id, :string, required: true
  attr :name, :any, default: nil
  attr :value, :any, default: nil, doc: "the selected value (a list when multiple)"
  attr :"default-value", :any, default: nil, doc: "the initial value when value is not set"
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:framework]"
  attr :multiple, :boolean, default: false, doc: "allow selecting several values"
  attr :"auto-highlight", :boolean, default: false, doc: "highlight the first match while typing"
  attr :filter, :boolean, default: true, doc: "filter items on the client; false for server filtering"
  attr :disabled, :boolean, default: false
  attr :"on-value-changed", :any, default: nil, doc: "handler for the value-changed event"
  attr :"on-open", :any, default: nil, doc: "handler for the open event"
  attr :"on-close", :any, default: nil, doc: "handler for the close event"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox(assigns) do
    assigns = prepare_assign(assigns)

    assigns =
      assign(assigns,
        invalid: invalid?(assigns),
        tracking_name: tracking_name(assigns.name, assigns.multiple)
      )

    assigns =
      assigns
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(
        :options,
        json(%{
          value: normalize_value(assigns.value, assigns.multiple),
          name: assigns.name && to_string(assigns.name),
          multiple: assigns.multiple,
          autoHighlight: assigns[:"auto-highlight"],
          filter: assigns.filter,
          disabled: assigns.disabled,
          animations: %{"open_to_closed" => %{duration: 100, target_part: "content"}}
        })
      )

    ~H"""
    <div
      id={@id}
      data-slot="combobox"
      data-component="combobox"
      data-part="root"
      data-state="closed"
      data-invalid={@invalid && "true"}
      data-disabled={@disabled && "true"}
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      class={classes(["group/combobox contents", @class])}
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
        data-salad-ui-combobox-tracker="true"
      />
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp normalize_value(nil, true), do: []
  defp normalize_value(nil, _multiple), do: nil
  defp normalize_value(value, true), do: value |> List.wrap() |> Enum.map(&to_string/1)
  defp normalize_value([value | _], _multiple), do: to_string(value)
  defp normalize_value([], _multiple), do: nil
  defp normalize_value(value, _multiple), do: to_string(value)

  # Mirrors `getInputName()` in combobox.js.
  defp tracking_name(name, _multiple) when name in [nil, ""], do: nil

  defp tracking_name(name, true) do
    name = to_string(name)
    if String.ends_with?(name, "[]"), do: name, else: name <> "[]"
  end

  defp tracking_name(name, _multiple), do: to_string(name)

  @doc """
  The text input, inside an input group with a button that opens the list and
  an optional clear button.

  Extra children (e.g. an `SaladUI.InputGroup.input_group_addon/1` holding an
  icon) are rendered inside the input group.

  ## Options

  * `:placeholder` - Placeholder text.
  * `:disabled` - Disables the input and its buttons, and the combobox.
  * `:show-trigger` - Show the chevron button that opens the list (default `true`).
  * `:show-clear` - Show a clear button while a value is selected; it replaces
    the chevron (default `false`).
  * `:name`, `:value` - Name and initial text of the input itself, e.g. the
    query for server filtering. The selected value is submitted separately
    through the root's `name`.
  * `:rest` - Passed to the `<input>`, e.g. `aria-invalid`, `phx-debounce`.
  """
  attr :id, :string, default: nil
  attr :name, :any, default: nil
  attr :value, :any, default: nil
  attr :placeholder, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :"show-trigger", :boolean, default: true
  attr :"show-clear", :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(autofocus form maxlength minlength readonly required)
  slot :inner_block

  def combobox_input(assigns) do
    assigns =
      assign(assigns,
        group_class: classes([@input_group_class, "w-auto", assigns.class]),
        show_trigger: assigns[:"show-trigger"],
        show_clear: assigns[:"show-clear"]
      )

    ~H"""
    <div data-slot="input-group" role="group" data-disabled={@disabled && "true"} class={@group_class}>
      <SaladUI.InputGroup.input_group_input
        id={@id}
        name={@name}
        value={@value}
        placeholder={@placeholder}
        disabled={@disabled}
        data-part="input"
        role="combobox"
        aria-autocomplete="list"
        aria-expanded="false"
        autocomplete="off"
        {@rest}
      />
      <SaladUI.InputGroup.input_group_addon :if={@show_trigger or @show_clear} align="inline-end">
        <SaladUI.InputGroup.input_group_button
          :if={@show_trigger}
          size="icon-xs"
          variant="ghost"
          data-slot="combobox-trigger"
          data-part="trigger"
          tabindex="-1"
          aria-label="Open"
          disabled={@disabled}
          class="group-has-[[data-slot=combobox-clear]:not([hidden])]/input-group:hidden data-pressed:bg-transparent [&_svg:not([class*='size-'])]:size-4"
        >
          <.chevron_down_icon />
        </SaladUI.InputGroup.input_group_button>
        <SaladUI.InputGroup.input_group_button
          :if={@show_clear}
          size="icon-xs"
          variant="ghost"
          data-slot="combobox-clear"
          data-part="clear"
          tabindex="-1"
          aria-label="Clear"
          disabled={@disabled}
          hidden
        >
          <.x_icon />
        </SaladUI.InputGroup.input_group_button>
      </SaladUI.InputGroup.input_group_addon>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A button that opens the list, for a combobox whose input sits inside
  `combobox_content/1` (shadcn's popup example). Put a `combobox_value/1` in
  it to show the selection.

  ## Options

  * `:variant` / `:size` - Style it as a `SaladUI.Button` (e.g. `variant="outline"`).
    Unstyled when no variant is given.
  """
  attr :variant, :string, values: [nil | ~w(default destructive outline secondary ghost link)], default: nil
  attr :size, :string, values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg), default: "default"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled)
  slot :inner_block

  def combobox_trigger(assigns) do
    ~H"""
    <button
      type="button"
      data-slot="combobox-trigger"
      data-part="trigger"
      aria-haspopup="listbox"
      aria-expanded="false"
      class={
        classes([
          @variant && button_variant(%{variant: @variant, size: @size}),
          "[&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
      <.chevron_down_icon />
    </button>
    """
  end

  @doc """
  Shows the selected label(s) inside `combobox_trigger/1`, or the placeholder
  while nothing is selected. Filled in by the JS component.
  """
  attr :placeholder, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  def combobox_value(assigns) do
    ~H"""
    <span
      data-slot="combobox-value"
      data-part="value"
      data-placeholder={@placeholder}
      class={classes(["truncate", @class])}
      {@rest}
    >{@placeholder}</span>
    """
  end

  @doc """
  The popup holding the list. It is positioned next to the chips, the input
  group or the trigger (in that order), and is at least as wide.

  ## Options

  * `:side` - `"bottom"` (default) or `"top"`; flips when there is no room.
  * `:align` - `"start"` (default), `"center"` or `"end"`; mirrored under `dir="rtl"`.
  * `:side-offset` - Gap to the anchor in px (default `6`).
  * `:align-offset` - Shift along the anchor in px (default `0`).
  """
  attr :side, :string, values: ~w(top bottom), default: "bottom"
  attr :align, :string, values: ~w(start center end), default: "start"
  attr :"side-offset", :integer, default: 6
  attr :"align-offset", :integer, default: 0
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_content(assigns) do
    assigns = assign(assigns, side_offset: assigns[:"side-offset"], align_offset: assigns[:"align-offset"])

    ~H"""
    <div
      data-slot="combobox-content"
      data-part="content"
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      data-align-offset={@align_offset}
      hidden
      class={
        classes([
          "group/combobox-content absolute isolate z-50 flex max-h-[min(24rem,var(--salad-combobox-available-height,24rem))] w-(--salad-reference-width) max-w-[calc(100vw-1rem)] min-w-[calc(var(--salad-reference-width)+--spacing(7))] flex-col overflow-hidden rounded-md bg-popover text-popover-foreground shadow-md ring-1 ring-foreground/10 duration-100 data-[chips=true]:min-w-(--salad-reference-width) data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
          "*:data-[slot=input-group]:m-1 *:data-[slot=input-group]:mb-0 *:data-[slot=input-group]:h-8 *:data-[slot=input-group]:shrink-0 *:data-[slot=input-group]:border-input/30 *:data-[slot=input-group]:bg-input/30 *:data-[slot=input-group]:shadow-none",
          "data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The scrollable listbox holding the items and groups.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_list(assigns) do
    ~H"""
    <div
      data-slot="combobox-list"
      data-part="list"
      role="listbox"
      class={
        classes([
          "max-h-[min(21.75rem,calc(var(--salad-combobox-available-height,24rem)-2.25rem))] min-h-0 scroll-py-1 overflow-y-auto p-1 data-empty:p-0",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  An option. A check mark shows while it is selected.

  ## Options

  * `:value` - Required. The submitted value.
  * `:label` - The text matched while filtering and shown once selected.
    Defaults to the item's text content.
  * `:disabled` - The item cannot be highlighted or selected.
  """
  attr :value, :any, required: true
  attr :label, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_item(assigns) do
    ~H"""
    <div
      data-slot="combobox-item"
      data-part="item"
      role="option"
      data-value={to_string(@value)}
      data-label={@label}
      data-disabled={@disabled && "true"}
      aria-disabled={@disabled && "true"}
      aria-selected="false"
      class={
        classes([
          "relative flex w-full cursor-default items-center gap-2 rounded-sm py-1.5 pe-8 ps-2 text-sm outline-hidden select-none data-highlighted:bg-accent data-highlighted:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
      <span
        data-slot="combobox-item-indicator"
        data-part="item-indicator"
        hidden
        class="pointer-events-none absolute end-2 flex size-4 items-center justify-center"
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
          class="pointer-events-none size-4 pointer-coarse:size-5"
          aria-hidden="true"
        >
          <path d="M20 6 9 17l-5-5" />
        </svg>
      </span>
    </div>
    """
  end

  @doc """
  Groups items under a `combobox_label/1`. Hidden while none of its items match.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_group(assigns) do
    ~H"""
    <div data-slot="combobox-group" data-part="group" role="group" class={classes([@class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The heading of a `combobox_group/1`.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_label(assigns) do
    ~H"""
    <div
      data-slot="combobox-label"
      data-part="label"
      class={
        classes([
          "px-2 py-1.5 text-xs text-muted-foreground pointer-coarse:px-3 pointer-coarse:py-2 pointer-coarse:text-sm",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A line between groups. Hidden while a query is typed.
  """
  attr :class, :any, default: nil
  attr :rest, :global

  def combobox_separator(assigns) do
    ~H"""
    <div
      data-slot="combobox-separator"
      data-part="separator"
      role="separator"
      class={classes(["-mx-1 my-1 h-px bg-border", @class])}
      {@rest}
    >
    </div>
    """
  end

  @doc """
  Shown in place of the list when no item matches.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_empty(assigns) do
    ~H"""
    <div
      data-slot="combobox-empty"
      data-part="empty"
      role="status"
      class={
        classes([
          "hidden w-full justify-center py-2 text-center text-sm text-muted-foreground group-data-empty/combobox-content:flex",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The box holding the chips of a multiple combobox and its
  `combobox_chips_input/1`. The list is positioned under it.

  The JS component renders a `combobox_chip/1` for every selected value in
  front of the input. Chips rendered by the server (with `value`) are kept when
  they match the selection.

  ## Options

  * `:show-remove` - Give each chip a remove button (default `true`).
  """
  attr :"show-remove", :boolean, default: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def combobox_chips(assigns) do
    assigns = assign(assigns, :show_remove, assigns[:"show-remove"])

    ~H"""
    <div
      data-slot="combobox-chips"
      data-part="chips"
      class={
        classes([
          "flex min-h-9 flex-wrap items-center gap-1.5 rounded-md border border-input bg-transparent bg-clip-padding px-2.5 py-1.5 text-sm shadow-xs transition-[color,box-shadow] focus-within:border-ring focus-within:ring-[3px] focus-within:ring-ring/50 has-aria-invalid:border-destructive has-aria-invalid:ring-[3px] has-aria-invalid:ring-destructive/20 has-data-[slot=combobox-chip]:px-1.5 dark:bg-input/30 dark:has-aria-invalid:border-destructive/50 dark:has-aria-invalid:ring-destructive/40",
          "group-data-[invalid=true]/combobox:border-destructive group-data-[disabled=true]/combobox:opacity-50",
          @class
        ])
      }
      {@rest}
    >
      <template data-part="chip-template">
        <.combobox_chip value="" show-remove={@show_remove}></.combobox_chip>
      </template>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  A selected value inside `combobox_chips/1`, with a remove button.

  ## Options

  * `:value` - The value it stands for.
  * `:show-remove` - Render the remove button (default `true`).
  """
  attr :value, :any, default: nil
  attr :"show-remove", :boolean, default: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def combobox_chip(assigns) do
    assigns = assign(assigns, :show_remove, assigns[:"show-remove"])

    ~H"""
    <div
      data-slot="combobox-chip"
      data-part="chip"
      data-value={@value && to_string(@value)}
      tabindex="-1"
      class={
        classes([
          "flex h-[calc(--spacing(5.5))] w-fit items-center justify-center gap-1 rounded-sm bg-muted px-1.5 text-xs font-medium whitespace-nowrap text-foreground has-disabled:pointer-events-none has-disabled:cursor-not-allowed has-disabled:opacity-50 has-data-[slot=combobox-chip-remove]:pe-0",
          @class
        ])
      }
      {@rest}
    >
      <span data-part="chip-label">{render_slot(@inner_block)}</span>
      <button
        :if={@show_remove}
        type="button"
        tabindex="-1"
        aria-label="Remove"
        data-slot="combobox-chip-remove"
        data-part="chip-remove"
        class={
          classes([
            button_variant(%{variant: "ghost", size: "icon-xs"}),
            "-ms-1 opacity-50 hover:opacity-100"
          ])
        }
      >
        <.x_icon />
      </button>
    </div>
    """
  end

  @doc """
  The text input of a multiple combobox, inside `combobox_chips/1`.

  `Backspace` in the empty input removes the last chip.
  """
  attr :id, :string, default: nil
  attr :name, :any, default: nil
  attr :value, :any, default: nil
  attr :placeholder, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(autofocus form maxlength minlength readonly required)

  def combobox_chips_input(assigns) do
    ~H"""
    <input
      type="text"
      id={@id}
      name={@name}
      value={@value}
      placeholder={@placeholder}
      disabled={@disabled}
      data-slot="combobox-chip-input"
      data-part="input"
      role="combobox"
      aria-autocomplete="list"
      aria-expanded="false"
      autocomplete="off"
      class={
        classes([
          "min-w-16 flex-1 bg-transparent outline-none placeholder:text-muted-foreground",
          @class
        ])
      }
      {@rest}
    />
    """
  end

  defp chevron_down_icon(assigns) do
    ~H"""
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
      data-slot="combobox-trigger-icon"
      class="pointer-events-none size-4 text-muted-foreground"
      aria-hidden="true"
    >
      <path d="m6 9 6 6 6-6" />
    </svg>
    """
  end

  defp x_icon(assigns) do
    ~H"""
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
      class="pointer-events-none"
      aria-hidden="true"
    >
      <path d="M18 6 6 18" />
      <path d="m6 6 12 12" />
    </svg>
    """
  end
end
