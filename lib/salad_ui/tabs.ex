defmodule SaladUI.Tabs do
  @moduledoc """
  Implementation of tabs components from https://ui.shadcn.com/docs/components/tabs

  ## Example:

      <.tabs id="settings" default="account" on-tab-changed={JS.push("tab_changed")}>
        <.tabs_list>
          <.tabs_trigger value="account">Account</.tabs_trigger>
          <.tabs_trigger value="password">Password</.tabs_trigger>
        </.tabs_list>
        <.tabs_content value="account">
          <.card>
            <.card_content class="p-6">
              Account settings go here
            </.card_content>
          </.card>
        </.tabs_content>
        <.tabs_content value="password">
          <.card>
            <.card_content class="p-6">
              Password settings go here
            </.card_content>
          </.card>
        </.tabs_content>
      </.tabs>

  ## Orientation and variants

  Pass `orientation="vertical"` to `tabs/1` to stack the list beside the
  content; the arrow keys then become Up/Down (Left/Right for the default
  horizontal orientation) and the list gets `aria-orientation="vertical"`.
  `tabs_list/1` takes `variant="line"` for an underlined style:

      <.tabs id="vertical-tabs" default="account" orientation="vertical">
        <.tabs_list variant="line">
          <.tabs_trigger value="account">Account</.tabs_trigger>
          <.tabs_trigger value="password">Password</.tabs_trigger>
          <.tabs_trigger value="notifications">Notifications</.tabs_trigger>
        </.tabs_list>
        <.tabs_content value="account">Account settings</.tabs_content>
        <.tabs_content value="password">Password settings</.tabs_content>
        <.tabs_content value="notifications">Notification settings</.tabs_content>
      </.tabs>

  ## Server-rendered state

  `tabs/1` hands a `builder` to its slot (`:let={tabs}`). Pass it to
  `tabs_list/1`, `tabs_trigger/1` and `tabs_content/1` and the server renders
  the selected tab with its full ARIA (`role`, `aria-selected`,
  `aria-controls`, `aria-labelledby`, the roving `tabindex`, `data-state` and
  `hidden`), so the page is right before the JS runs, e.g. a tab chosen by a
  URL param:

      <.tabs :let={tabs} id="settings" value={@tab}>
        <.tabs_list builder={tabs}>
          <.tabs_trigger builder={tabs} value="account" phx-click={JS.patch(~p"/settings?tab=account")}>
            Account
          </.tabs_trigger>
          <.tabs_trigger builder={tabs} value="password" phx-click={JS.patch(~p"/settings?tab=password")}>
            Password
          </.tabs_trigger>
        </.tabs_list>
        <.tabs_content builder={tabs} value="account">...</.tabs_content>
        <.tabs_content builder={tabs} value="password">...</.tabs_content>
      </.tabs>

  Without the builder the parts still render their roles; the selected state
  appears when the JS mounts.

  ## Keyboard

  Like Radix (`activationMode="automatic"`), Left/Right (Up/Down when
  vertical), Home and End select the tab they move to. They do so by clicking
  it, so a trigger's `phx-click` runs for the keyboard as well as the mouse.

  ## Component events

  * `:on-tab-changed` - Maps the `tab-changed` event. Fired when a different tab is selected.

  ## Server commands

  Tabs does not support `SaladUI.LiveView.send_command/4`. To change the active
  tab from the server, update the `value` assign and let LiveView re-render.

  ## Re-renders

  A LiveView re-render (such as the `phx-change` round trip of a form in a
  panel) keeps the tab the user chose, and keyboard focus where it was, on a
  trigger or a field in the panel. A new `value` selects that tab; changing
  other options rebuilds the tabs from the new markup.
  """
  use SaladUI, :component

  @doc """
  Primary tabs component that serves as a container for tab triggers and content.

  ## Component events

  * `:on-tab-changed` - Fired when a different tab is selected.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the tabs component"
  attr :default, :string, default: nil, doc: "Default selected tab value"
  attr :"default-value", :string, default: nil, doc: "Alias for `default` (Radix's `defaultValue`)"
  attr :value, :string, default: nil, doc: "Currently selected tab value"

  attr :orientation, :string,
    values: ~w(horizontal vertical),
    default: "horizontal",
    doc: "Layout and arrow-key axis: horizontal (Left/Right) or vertical (Up/Down)"

  attr :class, :any, default: nil
  attr :"on-tab-changed", :any, default: nil, doc: "Handler for tab change events"
  attr :rest, :global
  slot :inner_block, required: true

  def tabs(assigns) do
    # Collect event mappings
    event_map = event_mappings(assigns)
    default = assigns[:"default-value"] || assigns.default

    builder = %{
      id: assigns.id,
      value: assigns.value || default,
      orientation: assigns.orientation
    }

    assigns =
      assigns
      |> assign(:event_map, json(event_map))
      |> assign(:builder, builder)
      |> assign(
        :options,
        json(%{
          defaultValue: default,
          value: assigns.value,
          orientation: assigns.orientation
        })
      )

    ~H"""
    <div
      data-slot="tabs"
      id={@id}
      data-orientation={@orientation}
      class={classes(["group/tabs flex gap-2 data-[orientation=horizontal]:flex-col", @class])}
      data-component="tabs"
      data-state="idle"
      data-options={@options}
      data-event-mappings={@event_map}
      data-part="root"
      phx-hook="SaladUI"
      {@rest}
    >
      {render_slot(@inner_block, @builder)}
    </div>
    """
  end

  @doc """
  Container for tab triggers that provides proper styling and ARIA attributes.

  ## Options

  * `:variant` - `"default"` (muted pill background) or `"line"` (transparent, underlined active tab).
  """
  attr :variant, :string, values: ~w(default line), default: "default", doc: "Visual style of the list"
  attr :builder, :map, default: nil, doc: "The builder `tabs/1` passes to its slot; renders `aria-orientation`"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tabs_list(assigns) do
    assigns =
      assigns
      |> assign(:variant_class, tabs_list_variant(assigns.variant))
      # Attributes passed by the caller (e.g. a `role`) win.
      |> assign(
        :rest,
        Map.merge(%{role: "tablist", "aria-orientation": assigns.builder && assigns.builder[:orientation]}, assigns.rest)
      )

    ~H"""
    <div
      data-slot="tabs-list"
      data-part="list"
      data-variant={@variant}
      class={
        classes([
          "group/tabs-list inline-flex w-fit items-center justify-center rounded-lg p-[3px] text-muted-foreground group-data-[orientation=horizontal]/tabs:h-9 group-data-[orientation=vertical]/tabs:h-fit group-data-[orientation=vertical]/tabs:flex-col data-[variant=line]:rounded-none",
          @variant_class,
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
  Individual tab button that activates its corresponding content panel.
  """
  attr :value, :string, required: true, doc: "Unique value that identifies this tab"
  attr :builder, :map, default: nil, doc: "The builder `tabs/1` passes to its slot; renders the selected state"
  attr :class, :any, default: nil
  attr :disabled, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def tabs_trigger(assigns) do
    assigns = assign_tab_state(assigns, :trigger)

    ~H"""
    <button
      data-slot="tabs-trigger"
      type="button"
      data-part="trigger"
      data-value={@value}
      data-state={if @active, do: "active", else: "inactive"}
      data-disabled={to_string(@disabled)}
      class={
        classes([
          "relative inline-flex h-[calc(100%-1px)] flex-1 items-center justify-center gap-1.5 rounded-md border border-transparent px-2 py-1 text-sm font-medium whitespace-nowrap text-foreground/60 transition-all group-data-[orientation=vertical]/tabs:w-full group-data-[orientation=vertical]/tabs:justify-start hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1 focus-visible:outline-ring disabled:pointer-events-none disabled:opacity-50 group-data-[variant=default]/tabs-list:data-[state=active]:shadow-sm group-data-[variant=line]/tabs-list:data-[state=active]:shadow-none dark:text-muted-foreground dark:hover:text-foreground [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
          "group-data-[variant=line]/tabs-list:bg-transparent group-data-[variant=line]/tabs-list:data-[state=active]:bg-transparent dark:group-data-[variant=line]/tabs-list:data-[state=active]:border-transparent dark:group-data-[variant=line]/tabs-list:data-[state=active]:bg-transparent",
          "data-[state=active]:bg-background data-[state=active]:text-foreground dark:data-[state=active]:border-input dark:data-[state=active]:bg-input/30 dark:data-[state=active]:text-foreground",
          "after:absolute after:bg-foreground after:opacity-0 after:transition-opacity group-data-[orientation=horizontal]/tabs:after:inset-x-0 group-data-[orientation=horizontal]/tabs:after:bottom-[-5px] group-data-[orientation=horizontal]/tabs:after:h-0.5 group-data-[orientation=vertical]/tabs:after:inset-y-0 group-data-[orientation=vertical]/tabs:after:-end-1 group-data-[orientation=vertical]/tabs:after:w-0.5 group-data-[variant=line]/tabs-list:data-[state=active]:after:opacity-100",
          @class
        ])
      }
      disabled={@disabled}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Content panel that corresponds to a tab trigger.
  """
  attr :value, :string, required: true, doc: "Value that matches a tab trigger"
  attr :builder, :map, default: nil, doc: "The builder `tabs/1` passes to its slot; renders the selected state"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tabs_content(assigns) do
    assigns = assign_tab_state(assigns, :content)

    ~H"""
    <div
      data-slot="tabs-content"
      data-part="content"
      data-value={@value}
      data-state={if @active, do: "active", else: "inactive"}
      class={
        classes([
          "flex-1 outline-none",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # The ARIA a trigger or panel renders; attributes passed by the caller win.
  # With the builder, a trigger and its panel know whether they are selected
  # and link to each other by id, using the ids the JS would assign
  # ("<tabs id>-trigger-<value>", "<tabs id>-content-<value>"). Without it
  # every part renders inactive (and panels hidden) until the JS mounts.
  defp assign_tab_state(assigns, part) do
    {active, attrs} = tab_state(assigns[:builder], to_string(assigns.value), part)
    assign(assigns, active: active, rest: Map.merge(attrs, assigns.rest))
  end

  defp tab_state(%{id: tabs_id} = builder, value, part) do
    selected = builder[:value] && to_string(builder[:value])
    active = value == selected
    trigger_id = "#{tabs_id}-trigger-#{value}"
    content_id = "#{tabs_id}-content-#{value}"

    attrs =
      case part do
        :trigger ->
          %{
            id: trigger_id,
            role: "tab",
            "aria-selected": to_string(active),
            "aria-controls": content_id,
            # No tab stop is known until a tab is selected; the JS picks one.
            tabindex: selected && if(active, do: "0", else: "-1")
          }

        :content ->
          %{id: content_id, role: "tabpanel", "aria-labelledby": trigger_id, tabindex: "0", hidden: !active}
      end

    {active, attrs}
  end

  defp tab_state(_builder, _value, :trigger), do: {false, %{role: "tab", "aria-selected": "false"}}
  defp tab_state(_builder, _value, :content), do: {false, %{role: "tabpanel", tabindex: "0", hidden: true}}

  defp tabs_list_variant("line"), do: "gap-1 bg-transparent"
  defp tabs_list_variant(_variant), do: "bg-muted"
end
