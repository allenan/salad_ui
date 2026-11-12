defmodule SaladUI.NavigationMenu do
  @moduledoc """
  A collection of links for navigating websites, with dropdown panels that open
  on hover, click or keyboard.

  Mirrors shadcn/ui's `NavigationMenu` (Radix Navigation Menu). By default every
  open panel is rendered inside a shared *viewport* below the list, which
  animates its width and height as the user moves between triggers. Pass
  `viewport={false}` to render each panel directly below its own trigger
  instead.

  ## Examples:

      <.navigation_menu id="main-nav">
        <.navigation_menu_list>
          <.navigation_menu_item>
            <.navigation_menu_trigger>Getting started</.navigation_menu_trigger>
            <.navigation_menu_content>
              <ul class="grid w-[400px] gap-2 md:grid-cols-2">
                <li>
                  <.navigation_menu_link href="/docs">
                    <div class="text-sm leading-none font-medium">Introduction</div>
                    <p class="line-clamp-2 text-sm leading-snug text-muted-foreground">
                      Re-usable components built with Phoenix LiveView.
                    </p>
                  </.navigation_menu_link>
                </li>
                <li>
                  <.navigation_menu_link navigate="/docs/installation">
                    <div class="text-sm leading-none font-medium">Installation</div>
                    <p class="line-clamp-2 text-sm leading-snug text-muted-foreground">
                      How to install dependencies and structure your app.
                    </p>
                  </.navigation_menu_link>
                </li>
              </ul>
            </.navigation_menu_content>
          </.navigation_menu_item>
          <.navigation_menu_item>
            <.navigation_menu_link href="/docs" class={navigation_menu_trigger_style()}>
              Documentation
            </.navigation_menu_link>
          </.navigation_menu_item>
        </.navigation_menu_list>
        <.navigation_menu_indicator />
      </.navigation_menu>

  ## Interaction

  * Hovering a trigger opens its panel after `delay-duration` ms. While a panel
    is open (and for `skip-delay-duration` ms after it closes) moving to another
    trigger switches immediately, and the content slides in from the side the
    pointer came from.
  * Clicking a trigger (or pressing `Enter` / `Space`) toggles its panel.
  * `ArrowLeft` / `ArrowRight` / `Home` / `End` move focus between the top-level
    triggers and links. `ArrowDown` or `Tab` on an open trigger moves focus into
    its panel, where the arrow keys move between links. `Escape` closes the
    panel and returns focus to its trigger.
  * Clicking a link, clicking outside, or moving focus out of the menu closes it.

  ## Component events

  * `:on-value-changed` - Maps the `value-changed` event. Fired with
    `%{"value" => value}` whenever the open item changes (`""` when closed).

  ## Commands

  `SaladUI.LiveView.send_command/4` accepts `"open"` (with `%{value: item_value}`;
  defaults to the first item with a trigger) and `"close"`.
  """
  use SaladUI, :component

  @trigger_style "group inline-flex h-9 w-max items-center justify-center rounded-md bg-background px-4 py-2 text-sm font-medium transition-[color,box-shadow] outline-none hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1 disabled:pointer-events-none disabled:opacity-50 data-[state=open]:bg-accent/50 data-[state=open]:text-accent-foreground data-[state=open]:hover:bg-accent data-[state=open]:focus:bg-accent"

  @doc """
  The trigger classes, for styling a top-level `navigation_menu_link/1` like a
  trigger (shadcn's `navigationMenuTriggerStyle()`).

      <.navigation_menu_link href="/docs" class={navigation_menu_trigger_style()}>
        Docs
      </.navigation_menu_link>
  """
  def navigation_menu_trigger_style, do: @trigger_style

  @doc """
  The root of the navigation menu. Renders a `<nav>` and, unless
  `viewport={false}`, the shared `navigation_menu_viewport/1` after its children.

  ## Options

  * `:id` - Required unique identifier.
  * `:viewport` - Render open panels inside a shared, animated viewport. Defaults to `true`.
  * `:delay-duration` - Hover delay in ms before the first panel opens. Defaults to `200`.
  * `:skip-delay-duration` - How long (ms) after closing a panel hovering another
    trigger opens it without delay. Defaults to `300`.
  * `:on-value-changed` - Handler for the `value-changed` event.
  * `:class` - Additional CSS classes.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the navigation menu"
  attr :viewport, :boolean, default: true, doc: "Render open content inside the shared animated viewport"
  attr :"delay-duration", :integer, default: 200, doc: "Hover delay in ms before a panel opens"

  attr :"skip-delay-duration", :integer,
    default: 300,
    doc: "Window in ms after closing during which hovering another trigger opens it instantly"

  attr :"on-value-changed", :any, default: nil, doc: "Handler fired when the open item changes"
  attr :"aria-label", :string, default: "Main", doc: "Accessible name of the `<nav>` landmark"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu(assigns) do
    assigns =
      assigns
      |> assign(:event_map, json(event_mappings(assigns)))
      |> assign(
        :options,
        json(%{
          delayDuration: assigns[:"delay-duration"],
          skipDelayDuration: assigns[:"skip-delay-duration"],
          viewport: assigns.viewport
        })
      )

    ~H"""
    <nav
      id={@id}
      data-slot="navigation-menu"
      data-viewport={to_string(@viewport)}
      data-orientation="horizontal"
      data-component="navigation-menu"
      data-part="root"
      data-state="closed"
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      aria-label={assigns[:"aria-label"]}
      class={
        classes([
          "group/navigation-menu relative flex max-w-max flex-1 items-center justify-center",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
      <.navigation_menu_viewport :if={@viewport} />
    </nav>
    """
  end

  @doc """
  The list of top-level items.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_list(assigns) do
    ~H"""
    <ul
      data-slot="navigation-menu-list"
      data-part="list"
      data-orientation="horizontal"
      class={classes(["group flex flex-1 list-none items-center justify-center gap-1", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  A top-level item. Holds either a trigger + content pair or a single link.

  ## Options

  * `:value` - Identifies the item in `value-changed` events and the `"open"`
    command. Defaults to `"item-<index>"`.
  """
  attr :value, :string, default: nil, doc: "Item identifier; defaults to item-<index>"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_item(assigns) do
    ~H"""
    <li
      data-slot="navigation-menu-item"
      data-part="item"
      data-value={@value}
      class={classes(["relative", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc """
  The button that toggles its item's content. Appends a chevron that rotates
  while open. Supports the standard `disabled` attribute.
  """
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled)
  slot :inner_block, required: true

  def navigation_menu_trigger(assigns) do
    assigns = assign(assigns, :trigger_style, @trigger_style)

    ~H"""
    <button
      type="button"
      data-slot="navigation-menu-trigger"
      data-part="trigger"
      data-state="closed"
      aria-expanded="false"
      class={classes([@trigger_style, "group", @class])}
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
        class="lucide lucide-chevron-down relative top-[1px] ml-1 size-3 transition duration-300 group-data-[state=open]:rotate-180"
        aria-hidden="true"
      >
        <path d="m6 9 6 6 6-6" />
      </svg>
    </button>
    """
  end

  @doc """
  The panel shown when its item's trigger is open. With the viewport enabled it
  is moved into the viewport while open; otherwise it is positioned below its
  trigger.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def navigation_menu_content(assigns) do
    ~H"""
    <div
      data-slot="navigation-menu-content"
      data-part="content"
      data-state="closed"
      hidden
      class={
        classes([
          "top-0 left-0 w-full p-2 pr-2.5 data-[motion=from-end]:slide-in-from-right-52 data-[motion=from-start]:slide-in-from-left-52 data-[motion=to-end]:slide-out-to-right-52 data-[motion=to-start]:slide-out-to-left-52 data-[motion^=from-]:animate-in data-[motion^=from-]:fade-in data-[motion^=to-]:animate-out data-[motion^=to-]:fade-out md:absolute md:w-auto",
          "group-data-[viewport=false]/navigation-menu:top-full group-data-[viewport=false]/navigation-menu:mt-1.5 group-data-[viewport=false]/navigation-menu:overflow-hidden group-data-[viewport=false]/navigation-menu:rounded-md group-data-[viewport=false]/navigation-menu:border group-data-[viewport=false]/navigation-menu:bg-popover group-data-[viewport=false]/navigation-menu:text-popover-foreground group-data-[viewport=false]/navigation-menu:shadow group-data-[viewport=false]/navigation-menu:duration-200 **:data-[slot=navigation-menu-link]:focus:ring-0 **:data-[slot=navigation-menu-link]:focus:outline-none group-data-[viewport=false]/navigation-menu:data-[state=closed]:animate-out group-data-[viewport=false]/navigation-menu:data-[state=closed]:fade-out-0 group-data-[viewport=false]/navigation-menu:data-[state=closed]:zoom-out-95 group-data-[viewport=false]/navigation-menu:data-[state=open]:animate-in group-data-[viewport=false]/navigation-menu:data-[state=open]:fade-in-0 group-data-[viewport=false]/navigation-menu:data-[state=open]:zoom-in-95",
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
  The shared container open content is rendered into. `navigation_menu/1`
  renders it automatically (unless `viewport={false}`), so you rarely call it
  directly.

  Its width and height follow the active content through the
  `--navigation-menu-viewport-width` / `--navigation-menu-viewport-height`
  custom properties and animate between panels.
  """
  attr :class, :string, default: nil
  attr :rest, :global

  def navigation_menu_viewport(assigns) do
    ~H"""
    <div
      data-part="viewport-position"
      class="absolute top-full left-0 isolate z-50 flex justify-center"
    >
      <div
        data-slot="navigation-menu-viewport"
        data-part="viewport"
        data-state="closed"
        data-orientation="horizontal"
        hidden
        class={
          classes([
            "origin-top-center relative mt-1.5 h-(--navigation-menu-viewport-height) w-full overflow-hidden rounded-md border bg-popover text-popover-foreground shadow [transition:width_300ms_ease,height_300ms_ease] data-[state=closed]:animate-out data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:zoom-in-90 md:w-(--navigation-menu-viewport-width)",
            @class
          ])
        }
        {@rest}
      >
      </div>
    </div>
    """
  end

  @doc """
  A navigation link, rendered with `Phoenix.Component.link/1` so `href`,
  `navigate` and `patch` all work. Clicking a link closes the menu.

  ## Options

  * `:active` - Marks the link as the current page (`data-active` + `aria-current="page"`).
  * `:class` - Additional CSS classes. Use `navigation_menu_trigger_style/0` for a
    top-level link that looks like a trigger.
  """
  attr :active, :boolean, default: false, doc: "Whether the link points at the current page"
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch replace method csrf_token download hreflang referrerpolicy rel target type)

  slot :inner_block, required: true

  def navigation_menu_link(assigns) do
    ~H"""
    <.link
      data-slot="navigation-menu-link"
      data-part="link"
      data-active={@active && "true"}
      aria-current={@active && "page"}
      class={
        classes([
          "flex flex-col gap-1 rounded-sm p-2 text-sm transition-all outline-none hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1 data-[active=true]:bg-accent/50 data-[active=true]:text-accent-foreground data-[active=true]:hover:bg-accent data-[active=true]:focus:bg-accent [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  An arrow below the list that tracks the open trigger. Place it inside
  `navigation_menu/1`, after `navigation_menu_list/1`.
  """
  attr :class, :string, default: nil
  attr :rest, :global

  def navigation_menu_indicator(assigns) do
    ~H"""
    <div
      data-slot="navigation-menu-indicator"
      data-part="indicator"
      data-state="hidden"
      data-orientation="horizontal"
      aria-hidden="true"
      hidden
      class={
        classes([
          "top-full z-[1] flex h-1.5 items-end justify-center overflow-hidden data-[state=hidden]:animate-out data-[state=hidden]:fade-out data-[state=visible]:animate-in data-[state=visible]:fade-in",
          @class
        ])
      }
      {@rest}
    >
      <div class="relative top-[60%] h-2 w-2 rotate-45 rounded-tl-sm bg-border shadow-md"></div>
    </div>
    """
  end
end
