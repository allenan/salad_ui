defmodule SaladUI.DropdownMenu do
  @moduledoc """
  Implementation of dropdown menu component for SaladUI framework.

  Dropdown menus display a list of options when a trigger element is clicked.
  They provide a way to select from multiple options while conserving screen space.

  ## Examples:

      <.dropdown_menu id="user-menu">
        <.dropdown_menu_trigger as={&SaladUI.Button.button/1} variant="outline">
          Open Menu
        </.dropdown_menu_trigger>
        <.dropdown_menu_content class="w-56">
          <.dropdown_menu_label>My Account</.dropdown_menu_label>
          <.dropdown_menu_separator />
          <.dropdown_menu_group>
            <.dropdown_menu_item on-select={JS.push("profile_selected")}>
              Profile
              <.dropdown_menu_shortcut>⇧⌘P</.dropdown_menu_shortcut>
            </.dropdown_menu_item>
            <.dropdown_menu_item on-select={JS.push("settings_selected")}>
              Settings
              <.dropdown_menu_shortcut>⌘S</.dropdown_menu_shortcut>
            </.dropdown_menu_item>
            <.dropdown_menu_item disabled>
              Disabled Option
            </.dropdown_menu_item>
          </.dropdown_menu_group>
          <.dropdown_menu_separator />
          <.dropdown_menu_item variant="destructive" on-select={JS.push("logout")}>
            Log out
          </.dropdown_menu_item>
        </.dropdown_menu_content>
      </.dropdown_menu>

  Icons go straight into an item; they are sized `size-4` and muted unless they
  carry their own `size-*` / `text-*` class:

      <.dropdown_menu_item>
        <.icon name="hero-user" /> Profile
      </.dropdown_menu_item>

  ## Example with checkbox items

      <.dropdown_menu id="options-menu">
        <.dropdown_menu_trigger as={&SaladUI.Button.button/1} variant="outline">
          Options
        </.dropdown_menu_trigger>
        <.dropdown_menu_content>
          <.dropdown_menu_checkbox_item
            checked={@is_bold}
            on-checked-change={JS.push("toggle_bold")}
          >
            Bold
          </.dropdown_menu_checkbox_item>
          <.dropdown_menu_checkbox_item
            checked={@is_italic}
            close-on-select={false}
            on-checked-change={JS.push("toggle_italic")}
          >
            Italic (keeps the menu open)
          </.dropdown_menu_checkbox_item>
        </.dropdown_menu_content>
      </.dropdown_menu>

  ## Example with a radio group

      <.dropdown_menu id="position-menu">
        <.dropdown_menu_trigger as={&SaladUI.Button.button/1} variant="outline">
          Open
        </.dropdown_menu_trigger>
        <.dropdown_menu_content class="w-56">
          <.dropdown_menu_label>Panel Position</.dropdown_menu_label>
          <.dropdown_menu_separator />
          <.dropdown_menu_radio_group value={@position} on-value-changed="set_position">
            <.dropdown_menu_radio_item value="top">Top</.dropdown_menu_radio_item>
            <.dropdown_menu_radio_item value="bottom">Bottom</.dropdown_menu_radio_item>
            <.dropdown_menu_radio_item value="right">Right</.dropdown_menu_radio_item>
          </.dropdown_menu_radio_group>
        </.dropdown_menu_content>
      </.dropdown_menu>

  ## Example with a sub-menu

      <.dropdown_menu id="team-menu">
        <.dropdown_menu_trigger as={&SaladUI.Button.button/1} variant="outline">
          Open
        </.dropdown_menu_trigger>
        <.dropdown_menu_content>
          <.dropdown_menu_item>Team</.dropdown_menu_item>
          <.dropdown_menu_sub>
            <.dropdown_menu_sub_trigger>Invite users</.dropdown_menu_sub_trigger>
            <.dropdown_menu_sub_content>
              <.dropdown_menu_item on-select="invite_email">Email</.dropdown_menu_item>
              <.dropdown_menu_item on-select="invite_message">Message</.dropdown_menu_item>
            </.dropdown_menu_sub_content>
          </.dropdown_menu_sub>
        </.dropdown_menu_content>
      </.dropdown_menu>

  ## Selecting items

  Picking any item closes the menu, checkbox and radio items included (as in
  Radix). Set `close-on-select={false}` on an item to keep the menu open when
  it is picked, e.g. to let the user flip several checkbox items in a row
  (Radix's `onSelect={(e) => e.preventDefault()}`).

  ## Focus

  Opening with the pointer focuses the menu panel itself, so no item is
  highlighted until the pointer hovers one or `ArrowDown`/typeahead picks one.
  The pointer leaving an item (or resting on a disabled one) moves focus back
  to the panel. Opening from the keyboard (`Enter`, `Space` or `ArrowDown` on
  the trigger) focuses the first item. The panel is labelled by its trigger
  (`aria-labelledby`).

  ## Keyboard

  Follows the WAI-ARIA menu pattern: `ArrowUp`/`ArrowDown`/`Home`/`End` move
  between items, `Enter`/`Space` activate, `ArrowRight` opens a sub-menu and
  `ArrowLeft` closes it (mirrored under `dir="rtl"`), `Escape` closes the menu.
  `Tab` does nothing while the menu is open, so focus stays in it (as in Radix).

  Typeahead: typing moves focus to the next enabled item whose text starts
  with what was typed (the search clears after 1s; typing one letter
  repeatedly cycles through the items starting with it). Each sub-menu
  searches only its own items. Match on other text than the item's label with
  `data-text-value`:

      <.dropdown_menu_item data-text-value="Settings">
        <span aria-hidden="true">⚙</span> Settings
      </.dropdown_menu_item>

  ## Long menus

  The panel's height is capped at the room the viewport leaves beside the
  trigger (`max-h-(--dropdown-menu-content-available-height)`), so a long menu
  near the viewport edge scrolls.

  ## Modal behaviour

  As with Radix's DropdownMenu, a menu is modal by default (`modal={true}`).
  While it is open, clicks outside it never reach the page: `<body>` gets
  `pointer-events: none` and the menu `pointer-events: auto`, so the first
  click outside only closes the menu (a second one then activates what is
  underneath). Everything outside the menu is `aria-hidden`, wheel and touch
  scrolling outside it are cancelled, and page scrolling is locked (the
  scrollbar is hidden and `<body>` padded by its width; see "Scroll lock" in
  `SaladUI.Dialog`). The page is unblocked as soon as the menu starts
  closing. A menu opened inside a dialog takes over from the dialog until it
  closes.

  Pass `modal={false}` to leave the page interactive, readable and scrollable
  while the menu is open; a click outside then closes the menu and also
  reaches what was clicked.

  ## Component events

  * `:on-open` - Maps the `open` event. Fired when the dropdown menu enters open state.
  * `:on-close` - Maps the `close` event. Fired when the dropdown menu enters closed state.
  * `:on-select` - Maps the `select` event on a `dropdown_menu_item`. Fired when the item is activated.
  * `:on-checked-change` - Maps the `checked-change` event on a `dropdown_menu_checkbox_item`.
  * `:on-value-changed` - Maps the `value-changed` event on a `dropdown_menu_radio_group`.
    Fired with `%{"value" => value}` when a different radio item is picked.

  ## Server commands

  * `"open"` - Opens the dropdown menu.
  * `"close"` - Closes the dropdown menu.
  * `"toggle"` - Toggles the dropdown menu.

  ## Re-renders

  A LiveView re-render keeps an open menu open, with its open sub-menus and
  focus, also with `use-portal` (the portaled panel is moved back into the
  root for the patch and portaled again after it). Closing fires `on-close`
  and returns focus as soon as the menu starts closing, so a re-render during
  the exit animation (such as the reply to an item's `on-select`) cannot drop
  them.
  """
  use SaladUI, :component

  alias SaladUI.MenuParts

  @content_class "z-50 max-h-(--dropdown-menu-content-available-height) min-w-[8rem] overflow-x-hidden overflow-y-auto rounded-md border bg-popover p-1 text-popover-foreground shadow-md outline-hidden data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95"
  @item_class "relative flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 data-[inset]:ps-8 data-[variant=destructive]:text-destructive data-[variant=destructive]:focus:bg-destructive/10 data-[variant=destructive]:focus:text-destructive dark:data-[variant=destructive]:focus:bg-destructive/20 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground data-[variant=destructive]:*:[svg]:text-destructive!"
  @checkable_class "relative flex cursor-default items-center gap-2 rounded-sm py-1.5 pe-2 ps-8 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4"
  @label_class "px-2 py-1.5 text-sm font-medium data-[inset]:ps-8"
  @sub_trigger_class "flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[inset]:ps-8 data-[state=open]:bg-accent data-[state=open]:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground"
  @sub_content_class "z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-lg outline-hidden data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95"

  @doc """
  The main dropdown menu component that manages state and positioning.

  ## Options

  * `:id` - Required unique identifier for the dropdown menu.
  * `:open` - Whether the dropdown is initially open. Defaults to `false`.
  * `:use-portal` - Whether to render the dropdown in a portal. Defaults to `false`.
    Item `on-select` handlers keep working when portaled to `document.body`; plain
    `phx-*` bindings inside the content need a `:portal-container` inside the
    LiveView (see `SaladUI.Popover`).
  * `:portal-container` - CSS selector for the portal container. Defaults to `nil`.
  * `:modal` - Whether the open menu blocks, hides and scroll-locks the page. Defaults to `true`.
  * `:on-open` - Handler for dropdown menu open event.
  * `:on-close` - Handler for dropdown menu close event.
  * `:class` - Additional CSS classes.

  ## Component events

  * `:on-open` - Fired when the dropdown menu opens.
  * `:on-close` - Fired when the dropdown menu closes.

  ## Server commands

  * `"open"` - Opens the dropdown menu.
  * `"close"` - Closes the dropdown menu.
  * `"toggle"` - Toggles the dropdown menu.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the dropdown menu"
  attr :open, :boolean, default: false, doc: "Whether the dropdown menu is initially open"
  attr :"use-portal", :boolean, default: false, doc: "Whether to render the content in a portal"
  attr :"portal-container", :string, default: nil, doc: "CSS selector for the portal container"

  attr :modal, :boolean,
    default: true,
    doc: "block, hide and scroll-lock the page while open; `false` leaves the page interactive"

  attr :"on-open", :any, default: nil, doc: "Handler for dropdown menu open event"
  attr :"on-close", :any, default: nil, doc: "Handler for dropdown menu close event"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu(assigns) do
    # Collect event mappings
    event_map = event_mappings(assigns)

    # Convert kebab-case attributes to snake_case for use in the template
    assigns =
      assigns
      |> assign(:event_map, json(event_map))
      |> assign(:initial_state, if(assigns.open, do: "open", else: "closed"))
      |> assign(:use_portal, assigns[:"use-portal"])
      |> assign(:portal_container, assigns[:"portal-container"])
      |> assign(
        :options,
        json(%{
          usePortal: assigns[:"use-portal"],
          portalContainer: assigns[:"portal-container"],
          modal: assigns.modal,
          animations: get_animation_config()
        })
      )

    ~H"""
    <div
      data-slot="dropdown-menu"
      id={@id}
      class={classes(["relative inline-block", @class])}
      data-component="dropdown-menu"
      data-state={@initial_state}
      data-event-mappings={@event_map}
      data-options={@options}
      data-part="root"
      phx-hook="SaladUI"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The trigger element that toggles the dropdown menu.

  Renders a native `<button type="button">` by default. Set `:as` to an
  HTML tag or function component to render another trigger root.

  ## Options

  * `:class` - Additional CSS classes.
  * `:as` - The HTML tag or function component to use for the trigger. Defaults to `"button"`.
  """
  attr :as, :any, default: "button"
  attr :type, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(variant size)
  slot :inner_block, required: true

  def dropdown_menu_trigger(assigns) do
    assigns = drop_button_props(assigns)

    assigns =
      if is_function(assigns.as, 1) && is_nil(assigns.type) do
        assign(assigns, :type, "button")
      else
        assigns
      end

    ~H"""
    <button
      :if={@as == "button"}
      data-slot="dropdown-menu-trigger"
      type={@type || "button"}
      data-part="trigger"
      aria-haspopup="menu"
      aria-expanded="false"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    <.dynamic
      :if={@as != "button"}
      data-slot={@rest[:"data-slot"] || "dropdown-menu-trigger"}
      tag={@as}
      type={@type}
      data-part="trigger"
      aria-haspopup="menu"
      aria-expanded="false"
      tabindex="0"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  The dropdown menu content that appears when triggered.

  Its height is capped at the room the viewport leaves beside the trigger,
  so a long menu scrolls.

  ## Options

  * `:side` - Placement of the dropdown menu relative to the trigger (top, right, bottom, left). Defaults to `"bottom"`.
  * `:align` - Alignment of the dropdown menu (start, center, end). Defaults to `"center"`, as in shadcn/ui.
    `start`/`end` mirror under `dir="rtl"` for `top`/`bottom` sides.
  * `:side-offset` - Distance from the trigger in pixels. Defaults to `4`.
  * `:align-offset` - Offset along the alignment axis. Defaults to `0`.
  * `:collision-padding` - Distance in pixels kept from the viewport edges when
    the content flips or shifts to stay visible. Defaults to `0`, as in Radix.
  * `:loop` - Whether `ArrowDown`/`ArrowUp` wrap from the last item to the
    first (and back). Defaults to `false`, as in Radix.
  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :side, :string, values: ~w(top right bottom left), default: "bottom"
  attr :align, :string, values: ~w(start center end), default: "center"
  attr :"side-offset", :integer, default: 4, doc: "Distance from the trigger in pixels"
  attr :"align-offset", :integer, default: 0, doc: "Offset along the alignment axis"
  attr :"collision-padding", :integer, default: 0, doc: "Distance kept from the viewport edges"
  attr :loop, :boolean, default: false, doc: "Wrap keyboard navigation from the last item to the first and back"
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_content(assigns) do
    assigns =
      assign(assigns, %{
        base: @content_class,
        side_offset: assigns[:"side-offset"],
        align_offset: assigns[:"align-offset"],
        collision_padding: assigns[:"collision-padding"]
      })

    ~H"""
    <div
      data-part="positioner"
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      data-align-offset={@align_offset}
      data-collision-padding={@collision_padding}
      class="absolute z-50"
      style="min-width: var(--salad-reference-width)"
      hidden
    >
      <div
        data-slot="dropdown-menu-content"
        data-part="content"
        data-side={@side}
        data-align={@align}
        data-loop={@loop && "true"}
        role="menu"
        tabindex="-1"
        class={classes([@base, @class])}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  A group of related dropdown menu items.

  ## Options

  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_group(assigns) do
    assigns |> assign(:slot, "dropdown-menu-group") |> MenuParts.group()
  end

  @doc """
  A label for a section in the dropdown menu.

  ## Options

  * `:inset` - Indent to line up with checkbox/radio items (`data-inset`). Defaults to `false`.
  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :inset, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_label(assigns) do
    assigns |> assign(slot: "dropdown-menu-label", base: @label_class) |> MenuParts.label()
  end

  @doc """
  An item in the dropdown menu. Picking it fires `on-select` and closes the menu.

  ## Options

  * `:variant` - `"default"` or `"destructive"` (`data-variant`).
  * `:inset` - Indent to line up with checkbox/radio items (`data-inset`). Defaults to `false`.
  * `:disabled` - Whether the item is disabled. Defaults to `false`.
  * `:value` - Sent as `value` in the `select` event payload. Defaults to the item's text.
  * `:close-on-select` - Set to `false` to keep the menu open when the item is picked. Defaults to `true`.
  * `:on-select` - Handler for item selection.
  * `:as` - Tag or function component to render. Defaults to `"div"`.
  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :value, :string, default: nil
  attr :variant, :string, values: ~w(default destructive), default: "default"
  attr :inset, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :"close-on-select", :boolean, default: true, doc: "Close the menu when the item is picked"
  attr :"on-select", :any, default: nil, doc: "Handler for item selection"
  attr :as, :any, default: "div"
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_item(assigns) do
    assigns |> assign(slot: "dropdown-menu-item", base: @item_class) |> MenuParts.item()
  end

  @doc """
  A dropdown menu item rendered as a `Phoenix.Component.link/1`.

  ## Options

  * `:href` / `:navigate` / `:patch` / `:method` - Passed to `link/1`.
  * `:variant` - `"default"` or `"destructive"` (`data-variant`).
  * `:inset` - Indent to line up with checkbox/radio items (`data-inset`). Defaults to `false`.
  * `:disabled` - Whether the item is disabled. Defaults to `false`.
  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :value, :string, default: nil
  attr :variant, :string, values: ~w(default destructive), default: "default"
  attr :inset, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :rest, :global, include: ~w(href navigate patch method replace)
  slot :inner_block, required: true

  def dropdown_menu_link_item(assigns) do
    assigns = assign(assigns, :base, @item_class)

    ~H"""
    <.link
      data-slot="dropdown-menu-item"
      data-part="item"
      role="menuitem"
      data-value={@value}
      data-inset={@inset}
      data-variant={@variant}
      data-disabled={@disabled}
      aria-disabled={@disabled && "true"}
      class={classes([@base, @class])}
      tabindex="-1"
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  A checkbox item in the dropdown menu that can be toggled on/off. Toggling
  it closes the menu, unless `close-on-select={false}`.

  ## Options

  * `:checked` - Whether the item is checked. Defaults to `false`.
  * `:disabled` - Whether the item is disabled. Defaults to `false`.
  * `:close-on-select` - Set to `false` to keep the menu open on toggle. Defaults to `true`.
  * `:on-checked-change` - Fired with `%{"value" => value, "checked" => checked}`.
  * `:on-select` - Handler for item selection.
  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :value, :string, default: nil
  attr :checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :"close-on-select", :boolean, default: true, doc: "Close the menu when the item is toggled"
  attr :"on-select", :any, default: nil, doc: "Handler for item selected event"
  attr :"on-checked-change", :any, default: nil, doc: "Handler for when checked state changes"

  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_checkbox_item(assigns) do
    assigns
    |> assign(slot: "dropdown-menu-checkbox-item", base: @checkable_class)
    |> MenuParts.checkbox_item()
  end

  @doc """
  A group of mutually exclusive `dropdown_menu_radio_item/1`s.

  The group owns the selected value: the item whose `value` equals the
  group's `value` is rendered checked. Picking another item updates the
  checked item on the client, fires `on-value-changed` and closes the menu
  (unless that item has `close-on-select={false}`). Pass the new value back
  as `value` from your LiveView to keep server state in sync.

  ## Options

  * `:value` - The currently selected value. Defaults to `nil` (nothing checked).
  * `:on-value-changed` - Handler fired when the user picks a different item.
    A string event name receives `%{"value" => value}`; a `Phoenix.LiveView.JS`
    command is executed as-is.
  * `:class` - Additional CSS classes.

  ## Examples

      <.dropdown_menu_radio_group value={@position} on-value-changed="set_position">
        <.dropdown_menu_radio_item value="top">Top</.dropdown_menu_radio_item>
        <.dropdown_menu_radio_item value="bottom">Bottom</.dropdown_menu_radio_item>
        <.dropdown_menu_radio_item value="right">Right</.dropdown_menu_radio_item>
      </.dropdown_menu_radio_group>
  """
  attr :value, :string, default: nil, doc: "The currently selected value"

  attr :"on-value-changed", :any,
    default: nil,
    doc: "Handler fired with `%{\"value\" => value}` when the selected item changes"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_radio_group(assigns) do
    assigns |> assign(:slot, "dropdown-menu-radio-group") |> MenuParts.radio_group()
  end

  @doc """
  A radio item inside a `dropdown_menu_radio_group/1`.

  Its checked state comes from the enclosing group's `value` once the menu is
  mounted. `checked` only marks it checked in the initial (dead) render,
  e.g. `checked={@position == "top"}`; a group rendered without a `value`
  adopts the item rendered `checked`.

  ## Options

  * `:value` - Required. The value this item selects.
  * `:checked` - Render the item checked before the menu mounts. Defaults to `false`.
  * `:disabled` - Whether the item is disabled. Defaults to `false`.
  * `:close-on-select` - Set to `false` to keep the menu open when the item is picked. Defaults to `true`.
  * `:on-select` - Handler fired whenever the item is activated, even if it is already checked.
  * `:class` - Additional CSS classes.
  """
  attr :value, :string, required: true, doc: "The value this item selects"
  attr :checked, :boolean, default: false, doc: "Render the item checked before the menu mounts"
  attr :disabled, :boolean, default: false
  attr :"close-on-select", :boolean, default: true, doc: "Close the menu when the item is picked"
  attr :"on-select", :any, default: nil, doc: "Handler for item selected event"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_radio_item(assigns) do
    assigns
    |> assign(slot: "dropdown-menu-radio-item", base: @checkable_class)
    |> MenuParts.radio_item()
  end

  @doc """
  Wraps a sub-menu: one `dropdown_menu_sub_trigger/1` followed by one
  `dropdown_menu_sub_content/1`. Sub-menus can be nested.

  Keyboard (WAI-ARIA menu pattern): `ArrowRight`, `Enter` or `Space` on the
  sub-trigger opens the sub-menu and focuses its first item; `ArrowLeft`
  inside it closes it and returns focus to the sub-trigger (mirrored when an
  ancestor has `dir="rtl"`). `Escape` closes the whole menu. Hovering the
  sub-trigger opens the sub-menu; hovering a sibling item closes it, except
  while the pointer is travelling from the sub-trigger toward the sub-menu.
  Open sub-menus and focus survive LiveView re-renders.

  ## Examples

      <.dropdown_menu_sub>
        <.dropdown_menu_sub_trigger>Invite users</.dropdown_menu_sub_trigger>
        <.dropdown_menu_sub_content>
          <.dropdown_menu_item on-select="invite_email">Email</.dropdown_menu_item>
          <.dropdown_menu_item on-select="invite_message">Message</.dropdown_menu_item>
        </.dropdown_menu_sub_content>
      </.dropdown_menu_sub>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_sub(assigns) do
    assigns |> assign(:slot, "dropdown-menu-sub") |> MenuParts.sub()
  end

  @doc """
  The item that opens a sub-menu. Renders a trailing chevron.

  ## Options

  * `:inset` - Adds left padding to line up with checkbox/radio items. Defaults to `false`.
  * `:disabled` - Whether the sub-trigger is disabled. Defaults to `false`.
  * `:class` - Additional CSS classes.
  """
  attr :inset, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_sub_trigger(assigns) do
    assigns
    |> assign(
      slot: "dropdown-menu-sub-trigger",
      base: @sub_trigger_class,
      chevron_class: "ms-auto size-4 rtl:rotate-180"
    )
    |> MenuParts.sub_trigger()
  end

  @doc """
  The floating panel of a sub-menu. It accepts the same children as
  `dropdown_menu_content/1`, including nested `dropdown_menu_sub/1`s.

  ## Options

  * `:side` - Placement relative to the sub-trigger (`right` or `left`). Defaults to `"right"`;
    mirrored automatically under `dir="rtl"`.
  * `:align` - Alignment along the sub-trigger (start, center, end). Defaults to `"start"`.
  * `:side-offset` - Distance from the sub-trigger in pixels. Defaults to `0`.
  * `:align-offset` - Offset along the alignment axis. Defaults to `0`.
  * `:loop` - Whether `ArrowDown`/`ArrowUp` wrap from the last item to the
    first (and back). Defaults to `false`, as in Radix.
  * `:class` - Additional CSS classes.
  """
  attr :side, :string, values: ~w(right left), default: "right"
  attr :align, :string, values: ~w(start center end), default: "start"
  attr :"side-offset", :integer, default: 0, doc: "Distance from the sub-trigger in pixels"
  attr :"align-offset", :integer, default: 0, doc: "Offset along the alignment axis"
  attr :loop, :boolean, default: false, doc: "Wrap keyboard navigation from the last item to the first and back"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_sub_content(assigns) do
    assigns
    |> assign(
      slot: "dropdown-menu-sub-content",
      base: @sub_content_class,
      side_offset: assigns[:"side-offset"],
      align_offset: assigns[:"align-offset"]
    )
    |> MenuParts.sub_content()
  end

  @doc """
  A separator for visually dividing sections of the dropdown menu.

  ## Options

  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :rest, :global

  def dropdown_menu_separator(assigns) do
    assigns |> assign(:slot, "dropdown-menu-separator") |> MenuParts.separator()
  end

  @doc """
  A keyboard shortcut hint displayed in a dropdown menu item.

  ## Options

  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_shortcut(assigns) do
    assigns |> assign(:slot, "dropdown-menu-shortcut") |> MenuParts.shortcut()
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
