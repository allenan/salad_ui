defmodule SaladUI.Sidebar do
  @moduledoc """
  A composable, themeable and customizable sidebar, ported from shadcn/ui.

  `sidebar_provider/1` carries a small JS hook (`data-component="sidebar"`)
  that plays the role of shadcn's `SidebarProvider`:

    * **Collapsing** – the trigger, the rail, `Cmd+B` / `Ctrl+B` and the
      `open` / `close` / `toggle` commands expand or collapse the sidebar.
      The state is written to each sidebar's `data-state` /
      `data-collapsible`, so the shadcn Tailwind classes
      (`group-data-[collapsible=icon]:hidden`, …) follow client-side toggles.
    * **Mobile** – below 768px (the same `matchMedia` check as shadcn's
      `useIsMobile`) the sidebar becomes an offcanvas sheet (`data-mobile="true"`,
      18rem wide, with an overlay, Escape / outside click to close, a
      focus trap and, like shadcn's modal Sheet, a page scroll lock while it
      is open). No server-side `is_mobile` is needed; pass `is_mobile` only
      to force one layout.
    * **Persistence** – every desktop toggle writes a `sidebar_state` cookie
      (`path=/`, 7 days). Read it on the server to render the last state, see
      "Persisting the state" below.
    * **Patches** – the expanded/collapsed state lives on the client and is
      kept across LiveView patches. `default_open` only sets the initial
      state; use `open` to control it from the server.

  ## Composition

  ```text
  sidebar_provider
  ├── sidebar
  │   ├── sidebar_header
  │   ├── sidebar_content
  │   │   └── sidebar_group
  │   │       ├── sidebar_group_label
  │   │       ├── sidebar_group_action
  │   │       └── sidebar_group_content
  │   │           └── sidebar_menu
  │   │               └── sidebar_menu_item
  │   │                   ├── sidebar_menu_button
  │   │                   ├── sidebar_menu_action
  │   │                   ├── sidebar_menu_badge
  │   │                   └── sidebar_menu_sub
  │   │                       └── sidebar_menu_sub_item
  │   │                           └── sidebar_menu_sub_button
  │   ├── sidebar_footer
  │   └── sidebar_rail
  └── sidebar_inset
      └── sidebar_trigger
  ```

  ## Example

  ```heex
  <.sidebar_provider id="app-sidebar-provider">
    <.sidebar id="app-sidebar" collapsible="icon">
      <.sidebar_header>Acme Inc</.sidebar_header>
      <.sidebar_content>
        <.sidebar_group>
          <.sidebar_group_label>Application</.sidebar_group_label>
          <.sidebar_group_content>
            <.sidebar_menu>
              <.sidebar_menu_item>
                <.sidebar_menu_button as="a" href="#" is_active tooltip="Home">
                  <Lucideicons.house /> <span>Home</span>
                </.sidebar_menu_button>
              </.sidebar_menu_item>
            </.sidebar_menu>
          </.sidebar_group_content>
        </.sidebar_group>
      </.sidebar_content>
      <.sidebar_rail />
    </.sidebar>
    <.sidebar_inset>
      <header class="flex h-16 items-center gap-2 px-4">
        <.sidebar_trigger class="-ms-1" />
      </header>
    </.sidebar_inset>
  </.sidebar_provider>
  ```

  ## Persisting the state

  The hook writes `sidebar_state=true|false` on every desktop toggle. Copy
  the cookie into the session for the first (dead) render and read it in
  `on_mount` to pick the initial `default_open`:

  ```elixir
  # router.ex, in the :browser pipeline (after :fetch_session)
  plug :put_sidebar_state

  defp put_sidebar_state(conn, _opts) do
    conn = fetch_cookies(conn)
    put_session(conn, "sidebar_state", conn.cookies["sidebar_state"])
  end

  # live_session :default, on_mount: [{MyAppWeb.SidebarState, :default}]
  defmodule MyAppWeb.SidebarState do
    import Phoenix.Component, only: [assign: 3]

    def on_mount(:default, _params, session, socket) do
      {:cont, assign(socket, :sidebar_open, session["sidebar_state"] != "false")}
    end
  end
  ```

  ```heex
  <.sidebar_provider id="app" default_open={@sidebar_open}>
    <.sidebar id="app-sidebar" state={if @sidebar_open, do: "expanded", else: "collapsed"}>
  ```

  The session is only refreshed on full page loads; to also pick up toggles
  made before a live navigation, send the cookie as a connect param
  (`params: {sidebar_state: document.cookie.match(/sidebar_state=(\\w+)/)?.[1]}`)
  and prefer `get_connect_params(socket)["sidebar_state"]` when connected.

  Passing the same state to `sidebar` keeps the server-rendered markup in step
  with the provider (function components have no context to share it), so the
  page does not flash before the hook mounts.

  ## Controlled sidebar

  ```heex
  <.sidebar_provider id="controlled" open={@open} on-open-change="sidebar_open_change">
  ```

  ```elixir
  def handle_event("sidebar_open_change", %{"open" => open}, socket) do
    {:noreply, assign(socket, :open, open)}
  end
  ```

  The client applies a toggle right away and reports it; a changed `open`
  from the server is applied on the next patch.

  ## Component events

  * `:on-open-change` - `open-change`, fired when the desktop sidebar expands
    or collapses. Payload: `%{"open" => boolean}`.
  * `:on-open-mobile-change` - `open-mobile-change`, fired when the mobile
    sheet opens or closes. Payload: `%{"open" => boolean}`.

  ## Commands

  Send to the provider's id with `SaladUI.LiveView.send_command/4`, or with
  `SaladUI.JS.dispatch_command/3` to the provider or a sidebar's id
  (`toggle_sidebar/2`, `open_sidebar/2` and `close_sidebar/2` build these):

  * `"toggle"` - toggles the mobile sheet on mobile, the sidebar otherwise.
  * `"open"` / `"close"` - opens/closes the mobile sheet on mobile, expands/
    collapses the sidebar otherwise.
  * `"expand"` / `"collapse"` - always the desktop sidebar.
  """
  use SaladUI, :component

  import SaladUI.Input
  import SaladUI.Separator
  import SaladUI.Skeleton

  @sidebar_width "16rem"
  @sidebar_width_mobile "18rem"
  @sidebar_width_icon "3rem"
  @cookie_name "sidebar_state"

  @doc """
  Provides the sidebar state to every `sidebar`, `sidebar_trigger` and
  `sidebar_rail` inside it. Wrap the whole layout in it.

  Set `--sidebar-width`, `--sidebar-width-mobile` or `--sidebar-width-icon`
  through `style` to resize the sidebar.
  """
  attr :id, :string,
    default: "sidebar-provider",
    doc: "Id of the provider (the hook's element). Give each provider on a page its own id."

  attr :default_open, :boolean, default: true, doc: "Initial open state of the desktop sidebar."

  attr :open, :boolean,
    default: nil,
    doc: "Controlled open state. When set, a changed value from the server is applied on the next patch."

  attr :is_mobile, :boolean,
    default: nil,
    doc: "Force the mobile (`true`) or desktop (`false`) layout. `nil` follows a 768px media query."

  attr :keyboard_shortcut, :boolean, default: true, doc: "Toggle the sidebar with Cmd+B / Ctrl+B."

  attr :cookie, :any,
    default: @cookie_name,
    doc: "Name of the cookie that stores the open state. `nil` or `false` disables it."

  attr :"on-open-change", :any, default: nil, doc: "Handler for the `open-change` event"
  attr :"on-open-mobile-change", :any, default: nil, doc: "Handler for the `open-mobile-change` event"
  attr(:class, :string, default: nil)
  attr :style, :map, default: %{}
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_provider(assigns) do
    open = if is_nil(assigns.open), do: assigns.default_open, else: assigns.open

    assigns =
      assign(assigns,
        sidebar_width: @sidebar_width,
        sidebar_width_mobile: @sidebar_width_mobile,
        sidebar_width_icon: @sidebar_width_icon,
        initial_state: if(open, do: "expanded", else: "collapsed"),
        event_map: json(event_mappings(assigns)),
        options:
          json(%{
            isMobile: assigns.is_mobile,
            keyboardShortcut: assigns.keyboard_shortcut,
            cookieName: assigns.cookie
          })
      )

    ~H"""
    <div
      id={@id}
      data-slot="sidebar-wrapper"
      data-component="sidebar"
      data-state={@initial_state}
      data-open={if !is_nil(@open), do: to_string(@open)}
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      style={
        style([
          %{
            "--sidebar-width": @sidebar_width,
            "--sidebar-width-mobile": @sidebar_width_mobile,
            "--sidebar-width-icon": @sidebar_width_icon
          },
          @style
        ])
      }
      class={
        classes([
          "group/sidebar-wrapper flex min-h-svh w-full has-[[data-variant=inset]]:bg-sidebar",
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
  The sidebar panel. Must sit inside `sidebar_provider/1`.

  On desktop it renders shadcn's fixed sidebar (gap + container + inner). On
  mobile the provider's hook turns the same markup into an offcanvas sheet:
  `data-mobile="true"`, `data-state` `open`/`closed`, 18rem wide
  (`--sidebar-width-mobile`), with an overlay.
  """
  attr :id, :string,
    default: nil,
    doc: "Id of the sidebar. `dispatch_command/3` and `sidebar_trigger`'s `target` can address it."

  attr :side, :string,
    values: ~w(left right),
    default: "left",
    doc: "Physical side of the viewport. Under RTL pick `\"right\"` to keep the sidebar at the start, as shadcn does."

  attr :dir, :string,
    values: [nil, "ltr", "rtl"],
    default: nil,
    doc: "Reading direction of the sidebar."

  attr :variant, :string, values: ~w(sidebar floating inset), default: "sidebar"

  attr :collapsible, :string,
    values: ~w(offcanvas icon none),
    default: "offcanvas",
    doc: "`offcanvas` slides out, `icon` collapses to icons, `none` never collapses."

  attr :is_mobile, :boolean,
    default: nil,
    doc: "Force the mobile (`true`) or desktop (`false`) layout. Prefer `is_mobile` on the provider."

  attr :state, :string,
    values: ~w(expanded collapsed),
    default: "expanded",
    doc: "Server-rendered state before the hook mounts. Pass the provider's `default_open` state to avoid a flash."

  attr(:class, :string, default: nil)
  attr :style, :map, default: %{}
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar(%{collapsible: "none"} = assigns) do
    ~H"""
    <div
      id={@id}
      data-slot="sidebar"
      class={
        classes([
          "flex h-full w-(--sidebar-width) flex-col bg-sidebar text-sidebar-foreground",
          @class
        ])
      }
      data-variant={@variant}
      dir={@dir}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  def sidebar(assigns) do
    mobile = assigns.is_mobile == true

    assigns =
      assign(assigns,
        mobile: mobile,
        data_state: if(mobile, do: "closed", else: assigns.state),
        data_collapsible:
          cond do
            mobile -> "offcanvas"
            assigns.state == "collapsed" -> assigns.collapsible
            true -> ""
          end,
        inset_or_floating: assigns.variant in ["floating", "inset"],
        root_style: style([assigns.style])
      )

    ~H"""
    <div
      id={@id}
      data-slot="sidebar"
      class="group peer hidden text-sidebar-foreground md:block data-[mobile=true]:block data-[mobile=true]:[--sidebar-width:var(--sidebar-width-mobile)]"
      data-state={@data_state}
      data-collapsible={@data_collapsible}
      data-variant={!@mobile && @variant}
      data-side={@side}
      data-mobile={@mobile && "true"}
      data-is-mobile={!is_nil(@is_mobile) && to_string(@is_mobile)}
      data-collapsible-mode={@collapsible}
      data-sidebar-variant={@variant}
      dir={@dir}
      style={@root_style != "" && @root_style}
    >
      <div
        data-slot="sidebar-overlay"
        data-sidebar="overlay"
        data-action="close"
        aria-hidden="true"
        class="invisible fixed inset-0 z-50 hidden bg-black/50 opacity-0 transition-[opacity,visibility] duration-200 ease-linear group-data-[mobile=true]:block group-data-[state=open]:visible group-data-[state=open]:opacity-100"
      />
      <div
        data-slot="sidebar-gap"
        class={
          classes([
            "relative w-(--sidebar-width) bg-transparent transition-[width] duration-200 ease-linear",
            "group-data-[collapsible=offcanvas]:w-0",
            "group-data-[side=right]:rotate-180",
            "group-data-[mobile=true]:hidden",
            (@inset_or_floating &&
               "group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4)))]") ||
              "group-data-[collapsible=icon]:w-(--sidebar-width-icon)"
          ])
        }
      />
      <div
        data-slot="sidebar-container"
        data-side={@side}
        inert={@mobile}
        class={
          classes([
            "fixed inset-y-0 z-10 hidden h-svh w-(--sidebar-width) transition-[left,right,width] duration-200 ease-linear md:flex data-[side=left]:left-0 data-[side=right]:right-0 data-[side=left]:group-data-[collapsible=offcanvas]:left-[calc(var(--sidebar-width)*-1)] data-[side=right]:group-data-[collapsible=offcanvas]:right-[calc(var(--sidebar-width)*-1)]",
            (@inset_or_floating &&
               "p-2 group-data-[collapsible=icon]:w-[calc(var(--sidebar-width-icon)+(--spacing(4))+2px)]") ||
              "group-data-[collapsible=icon]:w-(--sidebar-width-icon) group-data-[side=left]:border-r group-data-[side=right]:border-l",
            "group-data-[mobile=true]:z-50 group-data-[mobile=true]:flex group-data-[mobile=true]:p-0 group-data-[mobile=true]:shadow-lg",
            @class
          ])
        }
        {@rest}
      >
        <div
          data-slot="sidebar-inner"
          data-sidebar="sidebar"
          class="flex size-full flex-col bg-sidebar group-data-[variant=floating]:rounded-lg group-data-[variant=floating]:border group-data-[variant=floating]:border-sidebar-border group-data-[variant=floating]:shadow-sm"
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  A button that toggles the sidebar (the mobile sheet on mobile). Inside
  `sidebar_provider/1` it needs no attributes.

  Outside the provider, pass `target` (the provider's or a sidebar's id), or
  build your own trigger with `phx-click={toggle_sidebar("provider-id")}`.
  """
  attr(:class, :string, default: nil)

  attr :target, :string,
    default: nil,
    doc: "Id of the provider or sidebar to toggle. Only needed outside the provider."

  attr :as, :any, default: nil, doc: "Tag or function component to render. Defaults to a ghost icon `button`."
  attr(:rest, :global)
  slot :inner_block

  def sidebar_trigger(%{as: nil} = assigns) do
    ~H"""
    <button
      type="button"
      data-slot="sidebar-trigger"
      data-sidebar="trigger"
      data-variant="ghost"
      data-size="icon"
      data-action={is_nil(@target) && "toggle"}
      phx-click={@target && toggle_sidebar(@target)}
      class={classes([button_variant(%{variant: "ghost", size: "icon"}), "size-7", @class])}
      {@rest}
    >
      <.sidebar_trigger_icon />
      {render_slot(@inner_block)}
    </button>
    """
  end

  def sidebar_trigger(assigns) do
    ~H"""
    <.dynamic
      data-slot="sidebar-trigger"
      tag={@as}
      data-sidebar="trigger"
      data-action={is_nil(@target) && "toggle"}
      phx-click={@target && toggle_sidebar(@target)}
      variant="ghost"
      size="icon"
      class={classes(["size-7", @class])}
      {@rest}
    >
      <.sidebar_trigger_icon />
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  defp sidebar_trigger_icon(assigns) do
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
      class="size-4 rtl:rotate-180"
    >
      <rect width="18" height="18" x="3" y="3" rx="2"></rect>
      <path d="M9 3v18"></path>
    </svg>
    <span class="sr-only">Toggle Sidebar</span>
    """
  end

  @doc """
  A thin hit area on the sidebar's edge that toggles it. Hidden on mobile.
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def sidebar_rail(assigns) do
    ~H"""
    <button
      type="button"
      data-slot="sidebar-rail"
      data-sidebar="rail"
      data-action="toggle"
      aria-label="Toggle Sidebar"
      tabindex={-1}
      title="Toggle Sidebar"
      class={
        classes([
          "absolute inset-y-0 z-20 hidden w-4 -translate-x-1/2 transition-all ease-linear group-data-[side=left]:-right-4 group-data-[side=right]:left-0 after:absolute after:inset-y-0 after:left-1/2 after:w-[2px] hover:after:bg-sidebar-border sm:flex",
          "[[data-side=left]_&]:cursor-w-resize [[data-side=right]_&]:cursor-e-resize",
          "[[data-side=left][data-state=collapsed]_&]:cursor-e-resize [[data-side=right][data-state=collapsed]_&]:cursor-w-resize",
          "group-data-[collapsible=offcanvas]:translate-x-0 group-data-[collapsible=offcanvas]:after:left-full hover:group-data-[collapsible=offcanvas]:bg-sidebar",
          "[[data-side=left][data-collapsible=offcanvas]_&]:-right-2",
          "[[data-side=right][data-collapsible=offcanvas]_&]:-left-2",
          "group-data-[mobile=true]:hidden",
          @class
        ])
      }
      {@rest}
    />
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot :inner_block, required: true

  def sidebar_inset(assigns) do
    ~H"""
    <main
      data-slot="sidebar-inset"
      class={
        classes([
          "relative flex min-h-svh flex-1 flex-col bg-background",
          "peer-data-[variant=inset]:min-h-[calc(100svh_-_1rem)] md:peer-data-[variant=inset]:m-2 md:peer-data-[state=collapsed]:peer-data-[variant=inset]:ms-2 md:peer-data-[variant=inset]:ms-0 md:peer-data-[variant=inset]:rounded-xl md:peer-data-[variant=inset]:shadow-sm",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </main>
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global, include: ~w(placeholder))

  def sidebar_input(assigns) do
    ~H"""
    <.input
      data-slot="sidebar-input"
      data-sidebar="input"
      class={
        classes([
          "h-8 w-full bg-background shadow-none",
          @class
        ])
      }
      {@rest}
    />
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_header(assigns) do
    ~H"""
    <div
      data-slot="sidebar-header"
      data-sidebar="header"
      class={
        classes([
          "flex flex-col gap-2 p-2",
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
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot :inner_block, required: true

  def sidebar_footer(assigns) do
    ~H"""
    <div
      data-slot="sidebar-footer"
      data-sidebar="footer"
      class={
        classes([
          "flex flex-col gap-2 p-2",
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
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def sidebar_separator(assigns) do
    ~H"""
    <.separator
      data-slot="sidebar-separator"
      data-sidebar="separator"
      class={classes(["mx-2 w-auto bg-sidebar-border", @class])}
      {@rest}
    />
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_content(assigns) do
    ~H"""
    <div
      data-slot="sidebar-content"
      data-sidebar="content"
      class={
        classes([
          "salad-scroll-area",
          "flex min-h-0 flex-1 flex-col gap-2 overflow-auto group-data-[collapsible=icon]:overflow-hidden",
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
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_group(assigns) do
    ~H"""
    <div
      data-slot="sidebar-group"
      data-sidebar="group"
      class={
        classes([
          "relative flex w-full min-w-0 flex-col p-2",
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
  Render
  TODO: class merge not work well here
  """
  attr(:class, :string, default: nil)
  attr :as, :any, default: "div"
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_group_label(assigns) do
    ~H"""
    <.dynamic
      data-slot="sidebar-group-label"
      data-sidebar="group-label"
      tag={@as}
      class={
        Enum.join(
          [
            "duration-200 flex h-8 shrink-0 items-center rounded-md px-2 font-medium text-sidebar-foreground/70 outline-hidden ring-sidebar-ring transition-[margin,opa] ease-linear focus-visible:ring-2 [&>svg]:size-4 [&>svg]:shrink-0 text-xs",
            "group-data-[collapsible=icon]:-mt-8 group-data-[collapsible=icon]:opacity-0",
            @class
          ],
          " "
        )
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_group_action(assigns) do
    ~H"""
    <button
      data-slot="sidebar-group-action"
      data-sidebar="group-action"
      class={
        classes([
          "absolute end-3 top-3.5 flex aspect-square w-5 items-center justify-center rounded-md p-0 text-sidebar-foreground outline-hidden ring-sidebar-ring transition-transform hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 [&>svg]:size-4 [&>svg]:shrink-0",
          "after:absolute after:-inset-2 after:md:hidden",
          "group-data-[collapsible=icon]:hidden",
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
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_group_content(assigns) do
    ~H"""
    <div
      data-slot="sidebar-group-content"
      data-sidebar="group-content"
      class={
        classes([
          "w-full text-sm",
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
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_menu(assigns) do
    ~H"""
    <ul
      data-slot="sidebar-menu"
      data-sidebar="menu"
      class={
        classes([
          "flex w-full min-w-0 flex-col gap-1",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_menu_item(assigns) do
    ~H"""
    <li
      data-slot="sidebar-menu-item"
      data-sidebar="menu-item"
      class={
        classes([
          "group/menu-item relative",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc """
  The button of a `sidebar_menu_item`.

  With `tooltip`, the label is rendered after the button (hidden), and the
  provider's hook shows it on hover or focus only if the sidebar is collapsed
  and not mobile when it opens, so it follows client-side toggles. It is a
  sibling rather than a wrapper, so `sidebar_menu_action` /
  `sidebar_menu_badge` (styled through `peer/menu-button`) and an outer
  component's trigger (`as_child` with `collapsible_trigger` or
  `dropdown_menu_trigger`) keep working on the button.
  """
  attr :variant, :string, values: ~w(default outline), default: "default"
  attr :size, :string, values: ~w(default sm lg), default: "default"
  attr :is_active, :boolean, default: false
  attr(:class, :string, default: nil)

  attr :is_mobile, :boolean,
    default: false,
    doc: "Skip the tooltip entirely. Not needed for the mobile sheet, which hides it already."

  attr :state, :string, default: nil, doc: "Deprecated: the tooltip follows the sidebar's client-side state."
  attr :as, :any, default: "button"
  attr :tooltip, :string, default: nil, doc: "Label shown in a tooltip while the sidebar is collapsed."

  attr :tooltip_side, :string,
    values: ~w(top right bottom left),
    default: "right",
    doc: "Side of the tooltip."

  attr(:rest, :global, include: ~w(href navigate patch target rel method download replace type disabled))
  slot(:inner_block, required: true)

  def sidebar_menu_button(assigns) do
    ~H"""
    <.dynamic
      data-slot="sidebar-menu-button"
      tag={@as}
      data-sidebar="menu-button"
      data-size={@size}
      data-active={"#{@is_active}"}
      class={classes([sidebar_button_variant(%{variant: @variant, size: @size}), @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    <div
      :if={@tooltip && !@is_mobile}
      data-slot="tooltip-content"
      data-sidebar="menu-tooltip"
      role="tooltip"
      data-state="closed"
      data-side={@tooltip_side}
      data-align="center"
      data-side-offset="8"
      class="group/tooltip z-50 w-fit animate-in rounded-md bg-foreground px-3 py-1.5 text-xs text-balance text-background fade-in-0 zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2"
      hidden
    >
      {@tooltip}
      <span
        aria-hidden="true"
        class={[
          "pointer-events-none absolute",
          "group-data-[side=top]/tooltip:top-full group-data-[side=top]/tooltip:left-1/2 group-data-[side=top]/tooltip:-translate-x-1/2",
          "group-data-[side=bottom]/tooltip:bottom-full group-data-[side=bottom]/tooltip:left-1/2 group-data-[side=bottom]/tooltip:-translate-x-1/2 group-data-[side=bottom]/tooltip:rotate-180",
          "group-data-[side=left]/tooltip:top-1/2 group-data-[side=left]/tooltip:left-full group-data-[side=left]/tooltip:-translate-y-1/2 group-data-[side=left]/tooltip:-rotate-90",
          "group-data-[side=right]/tooltip:top-1/2 group-data-[side=right]/tooltip:right-full group-data-[side=right]/tooltip:-translate-y-1/2 group-data-[side=right]/tooltip:rotate-90"
        ]}
      >
        <span class="z-50 block size-2.5 translate-y-[calc(-50%_-_2px)] rotate-45 rounded-[2px] bg-foreground fill-foreground"></span>
      </span>
    </div>
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr :show_on_hover, :boolean, default: false
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_menu_action(assigns) do
    ~H"""
    <button
      data-slot="sidebar-menu-action"
      data-sidebar="menu-action"
      class={
        classes([
          "absolute end-1 top-1.5 flex aspect-square w-5 items-center justify-center rounded-md p-0 text-sidebar-foreground outline-hidden ring-sidebar-ring transition-transform hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 peer-hover/menu-button:text-sidebar-accent-foreground [&>svg]:size-4 [&>svg]:shrink-0",
          "after:absolute after:-inset-2 after:md:hidden",
          "peer-data-[size=sm]/menu-button:top-1",
          "peer-data-[size=default]/menu-button:top-1.5",
          "peer-data-[size=lg]/menu-button:top-2.5",
          "group-data-[collapsible=icon]:hidden",
          @show_on_hover &&
            "group-focus-within/menu-item:opacity-100 group-hover/menu-item:opacity-100 data-[state=open]:opacity-100 peer-data-[active=true]/menu-button:text-sidebar-accent-foreground md:opacity-0",
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
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_menu_badge(assigns) do
    ~H"""
    <div
      data-slot="sidebar-menu-badge"
      data-sidebar="menu-badge"
      class={
        classes([
          "absolute end-1 flex h-5 min-w-5 items-center justify-center rounded-md px-1 text-xs font-medium tabular-nums text-sidebar-foreground select-none pointer-events-none",
          "peer-hover/menu-button:text-sidebar-accent-foreground peer-data-[active=true]/menu-button:text-sidebar-accent-foreground",
          "peer-data-[size=sm]/menu-button:top-1",
          "peer-data-[size=default]/menu-button:top-1.5",
          "peer-data-[size=lg]/menu-button:top-2.5",
          "group-data-[collapsible=icon]:hidden",
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
  Render
  """
  attr(:class, :string, default: nil)
  attr :show_icon, :boolean, default: false
  attr(:rest, :global)

  def sidebar_menu_skeleton(assigns) do
    assigns = assign(assigns, :width, "70%")

    ~H"""
    <div
      data-slot="sidebar-menu-skeleton"
      data-sidebar="menu-skeleton"
      class={classes(["rounded-md h-8 flex gap-2 px-2 items-center", @class])}
      {@rest}
    >
      <.skeleton :if={@show_icon} class="size-4 rounded-md" data-sidebar="menu-skeleton-icon" />
      <.skeleton
        class="h-4 flex-1 max-w-(--skeleton-width)"
        data-sidebar="menu-skeleton-text"
        style={
          style([
            %{
              "--skeleton-width": @width
            }
          ])
        }
      />
    </div>
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_menu_sub(assigns) do
    ~H"""
    <ul
      data-slot="sidebar-menu-sub"
      data-sidebar="menu-sub"
      class={
        classes([
          "mx-3.5 flex min-w-0 translate-x-px flex-col gap-1 border-s border-sidebar-border rtl:-translate-x-px px-2.5 py-0.5",
          "group-data-[collapsible=icon]:hidden",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def sidebar_menu_sub_item(assigns) do
    ~H"""
    <li
      data-slot="sidebar-menu-sub-item"
      class={
        classes([
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc """
  Render
  """
  attr :size, :string, values: ~w(sm md), default: "md"
  attr :is_active, :boolean, default: false
  attr(:class, :string, default: nil)
  attr :as, :any, default: "a"
  attr(:rest, :global, include: ~w(href navigate patch target rel method download replace))
  slot(:inner_block, required: true)

  def sidebar_menu_sub_button(assigns) do
    ~H"""
    <.dynamic
      data-slot="sidebar-menu-sub-button"
      tag={@as}
      data-sidebar="menu-sub-button"
      data-size={@size}
      data-active={"#{@is_active}"}
      class={
        classes([
          "flex h-7 min-w-0 -translate-x-px items-center gap-2 rtl:translate-x-px overflow-hidden rounded-md px-2 text-sidebar-foreground outline-hidden ring-sidebar-ring hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 aria-disabled:pointer-events-none aria-disabled:opacity-50 [&>span:last-child]:truncate [&>svg]:size-4 [&>svg]:shrink-0 [&>svg]:text-sidebar-accent-foreground",
          "data-[active=true]:bg-sidebar-accent data-[active=true]:text-sidebar-accent-foreground",
          @size == "sm" && "text-xs",
          @size == "md" && "text-sm",
          "group-data-[collapsible=icon]:hidden",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @variant_config %{
    variants: %{
      variant: %{
        default: "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
        outline:
          "bg-background shadow-[0_0_0_1px_var(--sidebar-border)] hover:bg-sidebar-accent hover:text-sidebar-accent-foreground hover:shadow-[0_0_0_1px_var(--sidebar-accent)]"
      },
      size: %{
        default: "h-8 text-sm",
        sm: "h-7 text-xs",
        lg: "h-12 text-sm group-data-[collapsible=icon]:!p-0"
      }
    },
    default_variants: %{
      variant: "default",
      size: "default"
    }
  }
  @shared_classes "peer/menu-button flex w-full items-center gap-2 overflow-hidden rounded-md p-2 text-start text-sm outline-hidden ring-sidebar-ring transition-[width,height,padding] hover:bg-sidebar-accent hover:text-sidebar-accent-foreground focus-visible:ring-2 active:bg-sidebar-accent active:text-sidebar-accent-foreground disabled:pointer-events-none disabled:opacity-50 group-has-[[data-sidebar=menu-action]]/menu-item:pe-8 aria-disabled:pointer-events-none aria-disabled:opacity-50 data-[active=true]:bg-sidebar-accent data-[active=true]:font-medium data-[active=true]:text-sidebar-accent-foreground data-[state=open]:hover:bg-sidebar-accent data-[state=open]:hover:text-sidebar-accent-foreground group-data-[collapsible=icon]:!size-8 group-data-[collapsible=icon]:!p-2 [&>span:last-child]:truncate [&>svg]:size-4 [&>svg]:shrink-0"
  defp sidebar_button_variant(input) do
    @shared_classes <> " " <> variant_class(@variant_config, input)
  end

  @doc """
  A `Phoenix.LiveView.JS` command that toggles the sidebar of the provider
  (or sidebar) with id `id`. Use it to build a custom trigger:

      <button phx-click={toggle_sidebar("app-sidebar-provider")}>Toggle</button>
  """
  def toggle_sidebar(js \\ %JS{}, id), do: sidebar_command(js, "toggle", id)

  @doc "Like `toggle_sidebar/2`, but opens the sidebar (the sheet on mobile)."
  def open_sidebar(js \\ %JS{}, id), do: sidebar_command(js, "open", id)

  @doc "Like `toggle_sidebar/2`, but closes the sidebar (the sheet on mobile)."
  def close_sidebar(js \\ %JS{}, id), do: sidebar_command(js, "close", id)

  defp sidebar_command(js, command, id) do
    SaladUI.JS.dispatch_command(js, command, to: "#" <> id)
  end
end
