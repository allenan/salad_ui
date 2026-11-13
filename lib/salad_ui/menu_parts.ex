defmodule SaladUI.MenuParts do
  @moduledoc false
  # Markup shared by the menu families built on the `menu.js` internals
  # (`SaladUI.ContextMenu`, `SaladUI.Menubar`). Each public component declares
  # its own attrs and shadcn classes, then renders through these functions with
  # `:slot` (the `data-slot` name) and `:base` (its shadcn class list).
  #
  # The `data-part` names are what `menu.js` binds to, so they match
  # `SaladUI.DropdownMenu`'s.
  use SaladUI, :component

  # `close-on-select={false}` on an item keeps the menu open when it is
  # picked (menu.js reads `data-close-on-select`). Only `false` is rendered.
  defp close_on_select(assigns), do: if(assigns[:"close-on-select"] == false, do: "false")

  def group(assigns) do
    ~H"""
    <div data-slot={@slot} data-part="group" role="group" class={classes([@class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def label(assigns) do
    ~H"""
    <div
      data-slot={@slot}
      data-part="label"
      data-inset={@inset}
      class={classes([@base, @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  def item(assigns) do
    assigns =
      assign(assigns, event_map: json(event_mappings(assigns)), close_on_select: close_on_select(assigns))

    ~H"""
    <.dynamic
      tag={@as}
      data-slot={@rest[:"data-slot"] || @slot}
      data-part="item"
      role="menuitem"
      data-value={@value}
      data-inset={@inset}
      data-variant={@variant}
      data-disabled={@disabled}
      aria-disabled={@disabled && "true"}
      data-close-on-select={@close_on_select}
      data-event-mappings={@event_map}
      class={classes([@base, @class])}
      tabindex="-1"
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  def checkbox_item(assigns) do
    assigns =
      assign(assigns, event_map: json(event_mappings(assigns)), close_on_select: close_on_select(assigns))

    ~H"""
    <div
      data-slot={@slot}
      data-part="checkbox-item"
      role="menuitemcheckbox"
      aria-checked={to_string(@checked)}
      data-value={@value}
      data-disabled={@disabled}
      aria-disabled={@disabled && "true"}
      data-checked={to_string(@checked)}
      data-state={(@checked && "checked") || "unchecked"}
      data-close-on-select={@close_on_select}
      data-event-mappings={@event_map}
      class={classes([@base, @class])}
      tabindex="-1"
      {@rest}
    >
      <span class="pointer-events-none absolute start-2 flex size-3.5 items-center justify-center">
        <span data-part="item-indicator" hidden={!@checked}>
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
      {render_slot(@inner_block)}
    </div>
    """
  end

  def radio_group(assigns) do
    assigns = assign(assigns, :event_map, json(event_mappings(assigns)))

    ~H"""
    <div
      data-slot={@slot}
      data-part="radio-group"
      data-value={@value}
      data-event-mappings={@event_map}
      role="group"
      class={classes([@class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # `:checked` (optional) only seeds the dead render; once mounted, menu.js
  # checks the item whose value matches its group's `value`.
  def radio_item(assigns) do
    assigns =
      assign(assigns,
        event_map: json(event_mappings(assigns)),
        close_on_select: close_on_select(assigns),
        checked: assigns[:checked] == true
      )

    ~H"""
    <div
      data-slot={@slot}
      data-part="radio-item"
      role="menuitemradio"
      aria-checked={to_string(@checked)}
      data-value={@value}
      data-disabled={@disabled}
      aria-disabled={@disabled && "true"}
      data-state={@checked && "checked"}
      data-close-on-select={@close_on_select}
      data-event-mappings={@event_map}
      class={classes([@base, @class])}
      tabindex="-1"
      {@rest}
    >
      <span class="pointer-events-none absolute start-2 flex size-3.5 items-center justify-center">
        <span data-part="item-indicator" hidden={!@checked}>
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
            class="size-2 fill-current"
          >
            <circle cx="12" cy="12" r="10"></circle>
          </svg>
        </span>
      </span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def sub(assigns) do
    ~H"""
    <div data-slot={@slot} data-part="sub" class={classes([@class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  def sub_trigger(assigns) do
    ~H"""
    <div
      data-slot={@slot}
      data-part="sub-trigger"
      role="menuitem"
      data-inset={@inset}
      data-disabled={@disabled}
      aria-disabled={@disabled && "true"}
      data-state="closed"
      aria-haspopup="menu"
      aria-expanded="false"
      class={classes([@base, @class])}
      tabindex="-1"
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
        class={@chevron_class}
      >
        <path d="m9 18 6-6-6-6"></path>
      </svg>
    </div>
    """
  end

  def sub_content(assigns) do
    ~H"""
    <div
      data-part="sub-positioner"
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      data-align-offset={@align_offset}
      class="absolute z-50"
      hidden
    >
      <div
        data-slot={@slot}
        data-part="sub-content"
        data-side={@side}
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

  def separator(assigns) do
    ~H"""
    <div
      data-slot={@slot}
      data-part="separator"
      role="separator"
      aria-orientation="horizontal"
      class={classes(["-mx-1 my-1 h-px bg-border", @class])}
      {@rest}
    />
    """
  end

  def shortcut(assigns) do
    ~H"""
    <span
      data-slot={@slot}
      data-part="shortcut"
      class={classes(["ms-auto text-xs tracking-widest text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
