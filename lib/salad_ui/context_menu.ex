defmodule SaladUI.ContextMenu do
  @moduledoc """
  A menu of actions opened at the pointer by a right click on its trigger
  area, or by a long press on touch and pen devices.

  It shares its items, checkbox and radio items and sub-menus with
  `SaladUI.DropdownMenu` (the same `menu.js` internals), so everything a
  dropdown menu can hold works here too.

  ## Examples

      <.context_menu id="page-menu">
        <.context_menu_trigger class="flex aspect-video w-full max-w-xs items-center justify-center rounded-xl border border-dashed text-sm">
          Right click here
        </.context_menu_trigger>
        <.context_menu_content class="w-48">
          <.context_menu_group>
            <.context_menu_item on-select="back">
              Back <.context_menu_shortcut>⌘[</.context_menu_shortcut>
            </.context_menu_item>
            <.context_menu_item disabled>
              Forward <.context_menu_shortcut>⌘]</.context_menu_shortcut>
            </.context_menu_item>
            <.context_menu_sub>
              <.context_menu_sub_trigger>More Tools</.context_menu_sub_trigger>
              <.context_menu_sub_content class="w-44">
                <.context_menu_item>Save Page...</.context_menu_item>
                <.context_menu_separator />
                <.context_menu_item variant="destructive">Delete</.context_menu_item>
              </.context_menu_sub_content>
            </.context_menu_sub>
          </.context_menu_group>
          <.context_menu_separator />
          <.context_menu_checkbox_item checked={@show_bookmarks} on-checked-change="toggle_bookmarks">
            Show Bookmarks
          </.context_menu_checkbox_item>
          <.context_menu_separator />
          <.context_menu_radio_group value={@person} on-value-changed="set_person">
            <.context_menu_label>People</.context_menu_label>
            <.context_menu_radio_item value="pedro">Pedro Duarte</.context_menu_radio_item>
            <.context_menu_radio_item value="colm">Colm Tuite</.context_menu_radio_item>
          </.context_menu_radio_group>
        </.context_menu_content>
      </.context_menu>

  ## Opening

  * Right click (the `contextmenu` event) opens the menu at the pointer, or
    moves it there when it is already open. Right clicking elsewhere closes it.
  * On touch and pen devices, holding the trigger for 700ms opens it.
  * The keyboard context-menu key (or `Shift+F10`) on a focused element inside
    the trigger opens it at the trigger and focuses the first item.

  ## Modal behaviour

  As with Radix's ContextMenu, the menu is modal by default (`modal={true}`):
  while it is open, a click outside only closes it, everything outside the
  menu is `aria-hidden`, and page scrolling is locked. Right clicking inside
  the trigger still moves the menu to the pointer. See "Modal behaviour" in
  `SaladUI.DropdownMenu`. Pass `modal={false}` to leave the page interactive.

  ## Keyboard

  `ArrowUp`/`ArrowDown`/`Home`/`End` move between items, `Enter`/`Space`
  activate, `ArrowRight` opens a sub-menu and `ArrowLeft` closes it (mirrored
  under `dir="rtl"`), `Escape` closes the menu. Typing jumps to the next
  enabled item whose text starts with what was typed (per menu panel; an
  item's `data-text-value` overrides its text), as in `SaladUI.DropdownMenu`.

  ## Component events

  * `:on-open` / `:on-close` on `context_menu/1` - fired when the menu opens / closes.
  * `:on-select` on items - fired when the item is activated.
  * `:on-checked-change` on checkbox items - fired with `%{"value" => value, "checked" => checked}`.
  * `:on-value-changed` on radio groups - fired with `%{"value" => value}`.

  ## Server commands

  * `"open"` - Opens the menu, anchored at the trigger. Optional params:
    `anchor` (an element or CSS selector to open at instead), `x` and `y`
    (a viewport point to open at instead) and `context` (see below).
  * `"close"` - Closes the menu.
  * `"toggle"` - Toggles the menu.

  ## Shared menus

  For long lists, render one context menu for the whole list and make each
  row a *detached trigger*: a `context_menu_trigger/1` with `for` (the menu's
  id) and `context` (what the row stands for). Rows then carry no hook and
  no menu markup:

      <%!-- once per page --%>
      <.context_menu id="msg-context">
        <.context_menu_content class="w-48">
          <.context_menu_item phx-click="reply">Reply</.context_menu_item>
          <.context_menu_item on-select="pin">Pin</.context_menu_item>
        </.context_menu_content>
      </.context_menu>

      <%!-- per row --%>
      <.context_menu_trigger
        :for={{dom_id, msg} <- @streams.messages}
        id={dom_id}
        as="div"
        for="msg-context"
        context={%{id: msg.id}}
        class="data-[state=open]:bg-muted"
      >
        {msg.body}
      </.context_menu_trigger>

  The menu listens on the document for right clicks and long presses on its
  detached triggers. It opens at the pointer as usual; the row gets
  `data-state="open"` while the menu is open for it, and a right click on
  another row moves the menu there. The row's `context` reaches the items as
  in `SaladUI.DropdownMenu` (see "Shared menus" there): `phx-value-*` on the
  items for `phx-click` and `JS.push/2`, and merged into the payload of
  string event handlers. If the row leaves the page while the menu is open,
  the menu closes.

  From the server: `send_command(socket, "msg-context", "open", %{anchor:
  "#messages-42", context: %{id: 42}})` opens it at the row's bottom-left
  corner.

  Detached triggers are a SaladUI extension with no Radix equivalent; use
  them for lists, and the nested trigger everywhere else.
  """
  use SaladUI, :component

  alias SaladUI.MenuParts

  @content_class "z-50 max-h-(--context-menu-content-available-height) min-w-[8rem] overflow-x-hidden overflow-y-auto rounded-md border bg-popover p-1 text-popover-foreground shadow-md outline-hidden data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95"
  @item_class "relative flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 data-[inset]:ps-8 data-[variant=destructive]:text-destructive data-[variant=destructive]:focus:bg-destructive/10 data-[variant=destructive]:focus:text-destructive dark:data-[variant=destructive]:focus:bg-destructive/20 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground data-[variant=destructive]:*:[svg]:text-destructive!"
  @checkable_class "relative flex cursor-default items-center gap-2 rounded-sm py-1.5 pe-2 ps-8 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4"
  @label_class "px-2 py-1.5 text-sm font-medium text-foreground data-[inset]:ps-8"
  @sub_trigger_class "flex cursor-default items-center rounded-sm px-2 py-1.5 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[inset]:ps-8 data-[state=open]:bg-accent data-[state=open]:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground"
  @sub_content_class "z-50 min-w-[8rem] overflow-hidden rounded-md border bg-popover p-1 text-popover-foreground shadow-lg outline-hidden data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95"

  @doc """
  The context menu root. Wraps one `context_menu_trigger/1` and one
  `context_menu_content/1`.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the context menu"
  attr :"use-portal", :boolean, default: false, doc: "Render the open menu in a portal (`document.body` by default)"
  attr :"portal-container", :string, default: nil, doc: "CSS selector for the portal container"

  attr :modal, :boolean,
    default: true,
    doc: "block, hide and scroll-lock the page while open; `false` leaves the page interactive"

  attr :"on-open", :any, default: nil, doc: "Handler fired when the menu opens"
  attr :"on-close", :any, default: nil, doc: "Handler fired when the menu closes"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu(assigns) do
    assigns =
      assigns
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(
        :options,
        json(%{
          usePortal: assigns[:"use-portal"],
          portalContainer: assigns[:"portal-container"],
          modal: assigns.modal,
          animations: %{"open_to_closed" => %{duration: 130, target_part: "content"}}
        })
      )

    ~H"""
    <div
      id={@id}
      data-slot="context-menu"
      data-component="context-menu"
      data-part="root"
      data-state="closed"
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      class={classes(["contents", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The area that opens the menu on right click or long press.

  ## Options

  * `:disabled` - Ignore right clicks and long presses (the browser's own
    context menu shows instead). Defaults to `false`.
  * `:as` - The tag or function component to render. Defaults to `"span"`, like Radix.
  * `:for` - The id of a shared `context_menu/1` this area opens. Defaults to `nil` (the trigger
    is nested in its `context_menu/1`). See "Shared menus" in the module docs.
  * `:context` - With `for`: a map handed to the menu's items while the menu is open from this
    area, e.g. `%{id: @message.id}`.
  """
  attr :as, :any, default: "span"
  attr :disabled, :boolean, default: false
  attr :for, :string, default: nil, doc: "id of the shared context menu this detached trigger opens"
  attr :context, :map, default: nil, doc: "with `for`: the map the menu's items receive while open from this trigger"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(variant size)
  slot :inner_block, required: true

  def context_menu_trigger(assigns) do
    assigns =
      assigns
      |> drop_button_props()
      |> assign(:trigger_attrs, trigger_attrs(assigns.for, assigns.context))

    ~H"""
    <.dynamic
      tag={@as}
      data-slot={@rest[:"data-slot"] || "context-menu-trigger"}
      data-disabled={@disabled}
      class={classes(["[-webkit-touch-callout:none]", @class])}
      {@trigger_attrs}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  The menu panel. It opens with its corner at the pointer.

  ## Options

  * `:side` - Which side of the pointer the menu opens on (`top`, `right`,
    `bottom`, `left`). Defaults to `"right"`, i.e. below and to the right of the
    pointer; mirrored under `dir="rtl"`. It flips when it would overflow.
  * `:collision-padding` - Distance in pixels kept from the viewport edges when
    the content flips or shifts to stay visible. Defaults to `0`, as in Radix.
  * `:loop` - Whether `ArrowDown`/`ArrowUp` wrap from the last item to the
    first (and back). Defaults to `false`, as in Radix.
  * `:class` - Additional CSS classes.
  """
  attr :side, :string, values: ~w(top right bottom left), default: "right"
  attr :"collision-padding", :integer, default: 0, doc: "Distance kept from the viewport edges"
  attr :loop, :boolean, default: false, doc: "Wrap keyboard navigation from the last item to the first and back"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_content(assigns) do
    assigns = assign(assigns, base: @content_class, collision_padding: assigns[:"collision-padding"])

    ~H"""
    <div
      data-part="positioner"
      data-side={@side}
      data-collision-padding={@collision_padding}
      class="fixed top-0 left-0 z-50"
      hidden
    >
      <div
        data-slot="context-menu-content"
        data-part="content"
        data-side={@side}
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
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_group(assigns) do
    assigns |> assign(:slot, "context-menu-group") |> MenuParts.group()
  end

  @doc """
  A non-interactive section heading.

  ## Options

  * `:inset` - Indent to line up with checkbox/radio items. Defaults to `false`.
  """
  attr :inset, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_label(assigns) do
    assigns |> assign(slot: "context-menu-label", base: @label_class) |> MenuParts.label()
  end

  @doc """
  A menu item. Activating it fires `on-select` and closes the menu.

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
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method)
  slot :inner_block, required: true

  def context_menu_item(assigns) do
    assigns |> assign(slot: "context-menu-item", base: @item_class) |> MenuParts.item()
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
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_checkbox_item(assigns) do
    assigns
    |> assign(slot: "context-menu-checkbox-item", base: @checkable_class)
    |> MenuParts.checkbox_item()
  end

  @doc """
  A group of mutually exclusive `context_menu_radio_item/1`s. The item whose
  `value` equals the group's `value` is checked; picking another fires
  `on-value-changed` with `%{"value" => value}` and closes the menu (unless
  the item has `close-on-select={false}`).
  """
  attr :value, :string, default: nil, doc: "The selected value"
  attr :"on-value-changed", :any, default: nil, doc: "Handler fired when the selected item changes"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_radio_group(assigns) do
    assigns |> assign(:slot, "context-menu-radio-group") |> MenuParts.radio_group()
  end

  @doc """
  A radio item inside a `context_menu_radio_group/1`.

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
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_radio_item(assigns) do
    assigns
    |> assign(slot: "context-menu-radio-item", base: @checkable_class)
    |> MenuParts.radio_item()
  end

  @doc """
  Wraps a sub-menu: one `context_menu_sub_trigger/1` followed by one
  `context_menu_sub_content/1`. Sub-menus can be nested.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_sub(assigns) do
    assigns |> assign(:slot, "context-menu-sub") |> MenuParts.sub()
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
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_sub_trigger(assigns) do
    assigns
    |> assign(slot: "context-menu-sub-trigger", base: @sub_trigger_class, chevron_class: "ms-auto rtl:rotate-180")
    |> MenuParts.sub_trigger()
  end

  @doc """
  The floating panel of a sub-menu. Accepts the same children as
  `context_menu_content/1`.

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
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_sub_content(assigns) do
    assigns
    |> assign(
      slot: "context-menu-sub-content",
      base: @sub_content_class,
      side_offset: assigns[:"side-offset"],
      align_offset: assigns[:"align-offset"]
    )
    |> MenuParts.sub_content()
  end

  @doc "A horizontal rule between groups of items."
  attr :class, :any, default: nil
  attr :rest, :global

  def context_menu_separator(assigns) do
    assigns |> assign(:slot, "context-menu-separator") |> MenuParts.separator()
  end

  @doc "A keyboard shortcut hint, pushed to the end of an item."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def context_menu_shortcut(assigns) do
    assigns |> assign(:slot, "context-menu-shortcut") |> MenuParts.shortcut()
  end
end
