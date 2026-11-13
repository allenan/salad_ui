defmodule SaladUI.Menubar do
  @moduledoc """
  A visually persistent row of menus, as in desktop applications.

  Each `menubar_menu/1` pairs a `menubar_trigger/1` with a
  `menubar_content/1`. The content takes the same children as a dropdown
  menu (items, checkbox and radio items, labels, separators, shortcuts and
  nested sub-menus), driven by the same `menu.js` internals.

  ## Examples

      <.menubar id="app-menubar" class="w-72">
        <.menubar_menu value="file">
          <.menubar_trigger>File</.menubar_trigger>
          <.menubar_content>
            <.menubar_group>
              <.menubar_item on-select="new_tab">
                New Tab <.menubar_shortcut>⌘T</.menubar_shortcut>
              </.menubar_item>
              <.menubar_item disabled>New Incognito Window</.menubar_item>
            </.menubar_group>
            <.menubar_separator />
            <.menubar_sub>
              <.menubar_sub_trigger>Share</.menubar_sub_trigger>
              <.menubar_sub_content>
                <.menubar_item>Email link</.menubar_item>
                <.menubar_item>Messages</.menubar_item>
              </.menubar_sub_content>
            </.menubar_sub>
          </.menubar_content>
        </.menubar_menu>
        <.menubar_menu value="view">
          <.menubar_trigger>View</.menubar_trigger>
          <.menubar_content>
            <.menubar_checkbox_item checked={@full_urls} on-checked-change="toggle_full_urls">
              Always Show Full URLs
            </.menubar_checkbox_item>
            <.menubar_separator />
            <.menubar_radio_group value={@profile} on-value-changed="set_profile">
              <.menubar_radio_item value="andy">Andy</.menubar_radio_item>
              <.menubar_radio_item value="benoit">Benoit</.menubar_radio_item>
            </.menubar_radio_group>
          </.menubar_content>
        </.menubar_menu>
      </.menubar>

  ## Interaction

  * Clicking a trigger opens its menu (or closes it when it is open). While a
    menu is open, hovering another trigger switches to that menu.
  * The triggers form one tab stop. `ArrowLeft`/`ArrowRight` move between them
    (`Home`/`End` jump to the ends), and switch the open menu along when one is
    open. `Enter`, `Space` or `ArrowDown` open a menu and focus its first item;
    `ArrowUp` focuses its last item.
  * Inside a menu, `ArrowUp`/`ArrowDown`/`Home`/`End` move between items,
    `ArrowRight` opens a sub-menu and `ArrowLeft` closes it. On any other item
    `ArrowRight`/`ArrowLeft` open the next/previous menu. `Escape` closes the
    menu and returns focus to its trigger. All horizontal keys are mirrored
    under `dir="rtl"`.
  * Typing inside a menu jumps to the next enabled item whose text starts with
    what was typed (per menu panel; an item's `data-text-value` overrides its
    text), as in `SaladUI.DropdownMenu`.

  ## Component events

  * `:on-value-changed` on `menubar/1` - fired with `%{"value" => value}` when
    a menu opens, switches or closes (`""` when every menu is closed).
  * `:on-select` on items, `:on-checked-change` on checkbox items and
    `:on-value-changed` on radio groups, as in `SaladUI.DropdownMenu`.

  ## Server commands

  * `"open"` - Opens the menu named by `%{value: value}` (the first menu by default).
  * `"close"` - Closes the open menu.
  """
  use SaladUI, :component

  alias SaladUI.MenuParts

  @content_class "z-50 min-w-[12rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-md outline-hidden data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95"
  @item_class "relative flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 data-[inset]:ps-8 data-[variant=destructive]:text-destructive data-[variant=destructive]:focus:bg-destructive/10 data-[variant=destructive]:focus:text-destructive dark:data-[variant=destructive]:focus:bg-destructive/20 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground data-[variant=destructive]:*:[svg]:text-destructive!"
  @checkable_class "relative flex cursor-default items-center gap-2 rounded-xs py-1.5 pe-2 ps-8 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4"
  @label_class "px-2 py-1.5 text-sm font-medium data-[inset]:ps-8"
  @sub_trigger_class "flex cursor-default items-center rounded-sm px-2 py-1.5 text-sm outline-none select-none focus:bg-accent focus:text-accent-foreground data-[inset]:ps-8 data-[state=open]:bg-accent data-[state=open]:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50"
  @sub_content_class "z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-lg outline-hidden data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95"

  @doc """
  The menubar root (`role="menubar"`). Holds `menubar_menu/1`s.

  ## Options

  * `:id` - Required unique identifier.
  * `:loop` - Whether arrow keys wrap around from the last menu to the first. Defaults to `true`.
  * `:use-portal` - Render open menus in a portal (`document.body` by default). Defaults to `false`.
  * `:portal-container` - CSS selector for the portal container.
  * `:on-value-changed` - Handler fired with `%{"value" => value}` when the open menu changes.
  """
  attr :id, :string, required: true
  attr :loop, :boolean, default: true, doc: "Wrap arrow-key navigation between the first and last menu"
  attr :"use-portal", :boolean, default: false, doc: "Render open menus in a portal"
  attr :"portal-container", :string, default: nil, doc: "CSS selector for the portal container"
  attr :"on-value-changed", :any, default: nil, doc: "Handler fired when the open menu changes"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar(assigns) do
    assigns =
      assigns
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(
        :options,
        json(%{
          loop: assigns.loop,
          usePortal: assigns[:"use-portal"],
          portalContainer: assigns[:"portal-container"]
        })
      )

    ~H"""
    <div
      id={@id}
      data-slot="menubar"
      data-component="menubar"
      data-part="root"
      data-state="closed"
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      role="menubar"
      class={
        classes([
          "flex h-9 items-center gap-1 rounded-md border bg-background p-1 shadow-xs",
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
  One menu of the menubar: a `menubar_trigger/1` and its `menubar_content/1`.

  ## Options

  * `:value` - Identifies the menu in `on-value-changed` and the `"open"`
    command. Defaults to `"menu-<index>"`.
  """
  attr :value, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_menu(assigns) do
    ~H"""
    <div
      data-slot="menubar-menu"
      data-part="menu"
      data-value={@value}
      role="none"
      class={classes(["contents", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The button that opens its menu.

  ## Options

  * `:disabled` - Skip the trigger in keyboard navigation and ignore clicks. Defaults to `false`.
  """
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_trigger(assigns) do
    ~H"""
    <button
      type="button"
      data-slot="menubar-trigger"
      data-part="trigger"
      role="menuitem"
      aria-haspopup="menu"
      aria-expanded="false"
      data-state="closed"
      data-disabled={@disabled}
      disabled={@disabled}
      tabindex="-1"
      class={
        classes([
          "flex items-center rounded-sm px-2 py-1 text-sm font-medium outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[state=open]:bg-accent data-[state=open]:text-accent-foreground disabled:pointer-events-none disabled:opacity-50",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  The menu panel, placed below its trigger.

  ## Options

  * `:side` - `top`, `right`, `bottom` or `left` of the trigger. Defaults to `"bottom"`; flips when it would overflow.
  * `:align` - `start`, `center` or `end`. Defaults to `"start"`.
  * `:side-offset` - Distance from the trigger in pixels. Defaults to `8`.
  * `:align-offset` - Offset along the alignment axis. Defaults to `-4`.
  * `:loop` - Whether `ArrowDown`/`ArrowUp` wrap from the last item to the
    first (and back). Defaults to `false`, as in Radix. (The menubar's own `loop`, for
    moving between triggers, defaults to `true`.)
  """
  attr :side, :string, values: ~w(top right bottom left), default: "bottom"
  attr :align, :string, values: ~w(start center end), default: "start"
  attr :"side-offset", :integer, default: 8
  attr :"align-offset", :integer, default: -4
  attr :loop, :boolean, default: false, doc: "Wrap keyboard navigation from the last item to the first and back"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_content(assigns) do
    assigns =
      assign(assigns,
        base: @content_class,
        side_offset: assigns[:"side-offset"],
        align_offset: assigns[:"align-offset"]
      )

    ~H"""
    <div
      data-part="positioner"
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      data-align-offset={@align_offset}
      class="absolute z-50"
      hidden
    >
      <div
        data-slot="menubar-content"
        data-part="content"
        data-side={@side}
        data-align={@align}
        data-loop={@loop && "true"}
        data-state="closed"
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

  @doc "Groups related items (`role=\"group\"`)."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_group(assigns) do
    assigns |> assign(:slot, "menubar-group") |> MenuParts.group()
  end

  @doc """
  A non-interactive section heading.

  ## Options

  * `:inset` - Indent to line up with checkbox/radio items. Defaults to `false`.
  """
  attr :inset, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_label(assigns) do
    assigns |> assign(slot: "menubar-label", base: @label_class) |> MenuParts.label()
  end

  @doc """
  A menu item. Activating it fires `on-select`, closes the menu and returns
  focus to its trigger.

  ## Options

  * `:variant` - `"default"` or `"destructive"`.
  * `:inset` - Indent to line up with checkbox/radio items. Defaults to `false`.
  * `:disabled` - Skip the item in keyboard navigation and ignore clicks.
  * `:value` - Sent as `value` in the `select` event payload. Defaults to the item's text.
  * `:close-on-select` - Set to `false` to keep the menu open when the item is picked. Defaults to `true`.
  * `:on-select` - Handler for item selection.
  * `:as` - Tag or function component to render. Defaults to `"div"`.
  """
  attr :value, :string, default: nil
  attr :variant, :string, values: ~w(default destructive), default: "default"
  attr :inset, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :"close-on-select", :boolean, default: true, doc: "Close the menu when the item is picked"
  attr :"on-select", :any, default: nil, doc: "Handler for item selection"
  attr :as, :any, default: "div"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href navigate patch method)
  slot :inner_block, required: true

  def menubar_item(assigns) do
    assigns |> assign(slot: "menubar-item", base: @item_class) |> MenuParts.item()
  end

  @doc """
  An item that toggles on and off. Toggling closes the menu, unless
  `close-on-select={false}`.

  ## Options

  * `:checked` - Whether the item is checked. Defaults to `false`.
  * `:disabled` - Whether the item is disabled. Defaults to `false`.
  * `:close-on-select` - Set to `false` to keep the menu open when the item is picked. Defaults to `true`.
  * `:on-checked-change` - Fired with `%{"value" => value, "checked" => checked}`.
  * `:on-select` - Fired whenever the item is activated.
  """
  attr :value, :string, default: nil
  attr :checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :"close-on-select", :boolean, default: true, doc: "Close the menu when the item is picked"
  attr :"on-select", :any, default: nil, doc: "Handler for item activation"
  attr :"on-checked-change", :any, default: nil, doc: "Handler for checked state changes"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_checkbox_item(assigns) do
    assigns
    |> assign(slot: "menubar-checkbox-item", base: @checkable_class)
    |> MenuParts.checkbox_item()
  end

  @doc """
  A group of mutually exclusive `menubar_radio_item/1`s. The item whose
  `value` equals the group's `value` is checked; picking another fires
  `on-value-changed` with `%{"value" => value}` and closes the menu (unless
  the item has `close-on-select={false}`).
  """
  attr :value, :string, default: nil, doc: "The selected value"
  attr :"on-value-changed", :any, default: nil, doc: "Handler fired when the selected item changes"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_radio_group(assigns) do
    assigns |> assign(:slot, "menubar-radio-group") |> MenuParts.radio_group()
  end

  @doc """
  A radio item inside a `menubar_radio_group/1`.

  ## Options

  * `:value` - Required. The value this item selects.
  * `:disabled` - Whether the item is disabled. Defaults to `false`.
  * `:close-on-select` - Set to `false` to keep the menu open when the item is picked. Defaults to `true`.
  * `:on-select` - Fired whenever the item is activated, even if already checked.
  """
  attr :value, :string, required: true
  attr :disabled, :boolean, default: false
  attr :"close-on-select", :boolean, default: true, doc: "Close the menu when the item is picked"
  attr :"on-select", :any, default: nil, doc: "Handler for item activation"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_radio_item(assigns) do
    assigns
    |> assign(slot: "menubar-radio-item", base: @checkable_class)
    |> MenuParts.radio_item()
  end

  @doc """
  Wraps a sub-menu: one `menubar_sub_trigger/1` followed by one
  `menubar_sub_content/1`. Sub-menus can be nested.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_sub(assigns) do
    assigns |> assign(:slot, "menubar-sub") |> MenuParts.sub()
  end

  @doc """
  The item that opens a sub-menu, on hover, click, `Enter`, `Space` or
  `ArrowRight`. Renders a trailing chevron.

  ## Options

  * `:inset` - Indent to line up with checkbox/radio items. Defaults to `false`.
  * `:disabled` - Whether the sub-trigger is disabled. Defaults to `false`.
  """
  attr :inset, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_sub_trigger(assigns) do
    assigns
    |> assign(slot: "menubar-sub-trigger", base: @sub_trigger_class, chevron_class: "ms-auto h-4 w-4 rtl:rotate-180")
    |> MenuParts.sub_trigger()
  end

  @doc """
  The floating panel of a sub-menu. Accepts the same children as
  `menubar_content/1`.

  ## Options

  * `:side` - `right` or `left` of the sub-trigger. Defaults to `"right"`; mirrored under `dir="rtl"`.
  * `:align` - `start`, `center` or `end`. Defaults to `"start"`.
  * `:side-offset` / `:align-offset` - Offsets in pixels. Default to `0`.
  * `:loop` - Whether `ArrowDown`/`ArrowUp` wrap from the last item to the
    first (and back). Defaults to `false`, as in Radix.
  """
  attr :side, :string, values: ~w(right left), default: "right"
  attr :align, :string, values: ~w(start center end), default: "start"
  attr :"side-offset", :integer, default: 0
  attr :"align-offset", :integer, default: 0
  attr :loop, :boolean, default: false, doc: "Wrap keyboard navigation from the last item to the first and back"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_sub_content(assigns) do
    assigns
    |> assign(
      slot: "menubar-sub-content",
      base: @sub_content_class,
      side_offset: assigns[:"side-offset"],
      align_offset: assigns[:"align-offset"]
    )
    |> MenuParts.sub_content()
  end

  @doc "A horizontal rule between groups of items."
  attr :class, :string, default: nil
  attr :rest, :global

  def menubar_separator(assigns) do
    assigns |> assign(:slot, "menubar-separator") |> MenuParts.separator()
  end

  @doc "A keyboard shortcut hint, pushed to the end of an item."
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def menubar_shortcut(assigns) do
    assigns |> assign(:slot, "menubar-shortcut") |> MenuParts.shortcut()
  end
end
