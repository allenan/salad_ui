defmodule SaladUI.Command do
  @moduledoc """
  Command palette components for SaladUI.

  Provides a set of components to build a command palette or searchable menu, similar to those found in modern applications.

  ## Example

      <.command id="command" class="rounded-lg border border-border shadow-md md:min-w-[450px] w-full lg:max-w-[600px]">
        <.command_input placeholder="Type a command or search..." />
        <.command_empty>
          <span>No results found</span>
        </.command_empty>
        <.command_list>
          <.command_group heading="Suggestions">
            <.command_item phx-value-name="calendar" phx-click="select_command">
              <.calendar class="size-4"/>
              <span>Calendar</span>
            </.command_item>
            ...
          </.command_group>
          <.command_group heading="Settings">
            <.command_item phx-value-name="profile" phx-click="select_command">
              <.user class="size-4"/>
              <span>Profile</span>
              <.command_shortcut>⌘P</.command_shortcut>
            </.command_item>
            ...
          </.command_group>
        </.command_list>
      </.command>
  """
  use SaladUI, :component

  import SaladUI.Dialog
  import SaladUI.Icon

  @doc """
  Renders the root command palette container.

  ## Attributes

    * `:id` (required) - The unique id for the command palette.
    * `:class` - Additional classes to apply.

  ## Slots

    * `:inner_block` (required) - The content of the command palette.

  ## Example

      <.command id="my-command">
        ...
      </.command>
  """
  attr :id, :string, required: true
  attr :class, :any, default: ""
  slot :inner_block, required: true

  def command(assigns) do
    ~H"""
    <div
      data-slot="command"
      id={@id}
      tabindex="-1"
      data-component="command"
      data-part="root"
      phx-hook="SaladUI"
      class={
        classes([
          "flex size-full flex-col overflow-hidden rounded-md bg-popover text-popover-foreground",
          @class
        ])
      }
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a command palette inside a dialog.

  ## Attributes

    * `:id` (required) - The unique id for the command palette.
    * `:open` - Whether the dialog is open.

  ## Slots

    * `:inner_block` (required) - The content of the command palette.

  ## Example

      <.command_dialog id="my-command" open={@show_command}>
        ...
      </.command_dialog>
  """
  attr :id, :string, required: true
  attr :open, :boolean, default: false
  slot :inner_block, required: true

  def command_dialog(assigns) do
    ~H"""
    <.dialog id={@id <> "_dialog"} open={@open}>
      <.dialog_content class="overflow-hidden p-0">
        <.command id={@id} class="[&_[data-part='input']]:h-12">
          {render_slot(@inner_block)}
        </.command>
      </.dialog_content>
    </.dialog>
    """
  end

  @doc """
  Renders the input field for searching/filtering commands.

  ## Attributes

    * `:class` - Additional classes to apply.
    * All global attributes are passed to the `<input>` element.

  ## Example

      <.command_input placeholder="Type a command..." />
  """
  attr :class, :any, default: ""
  attr :rest, :global, default: %{}

  def command_input(assigns) do
    ~H"""
    <div
      data-slot="command-input-wrapper"
      data-part="input-wrapper"
      class="flex items-center border-b border-border px-3"
    >
      <.icon name="hero-magnifying-glass" />
      <input
        data-slot="command-input"
        type="text"
        data-part="input"
        autocomplete="off"
        autocorrect="off"
        autocapitalize="off"
        spellcheck="false"
        class={
          classes([
            "flex h-11 w-full rounded-md bg-transparent py-3 text-sm outline-hidden placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50 border-none focus:ring-transparent",
            @class
          ])
        }
        {@rest}
      />
    </div>
    """
  end

  @doc """
  Renders the list container for command items and groups.

  ## Attributes

    * `:class` - Additional classes to apply.

  ## Slots

    * `:inner_block` (required) - The content of the command list (groups/items).

  ## Example

      <.command_list>
        <.command_group heading="Actions">
          <.command_item>...</.command_item>
        </.command_group>
      </.command_list>
  """
  attr :class, :any, default: ""
  slot :inner_block, required: true

  def command_list(assigns) do
    ~H"""
    <div
      data-slot="command-list"
      data-part="list"
      tabindex="-1"
      role="listbox"
      class={classes(["max-h-[300px] overflow-y-auto overflow-x-hidden", @class])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a message when no command results are found.

  ## Attributes

    * `:class` - Additional classes to apply.

  ## Slots

    * `:inner_block` (required) - The content to display when empty.

  ## Example

      <.command_empty>
        <span>No results found</span>
      </.command_empty>
  """
  attr :class, :any, default: ""
  slot :inner_block, required: true

  def command_empty(assigns) do
    ~H"""
    <div
      data-slot="command-empty"
      data-visible="false"
      data-part="empty"
      class={classes(["py-6 text-center text-sm data-[visible=false]:hidden", @class])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a group of command items with a heading.

  ## Attributes

    * `:heading` (required) - The group heading.

  ## Slots

    * `:inner_block` (required) - The command items in the group.

  ## Example

      <.command_group heading="Settings">
        <.command_item>Profile</.command_item>
      </.command_group>
  """
  attr :heading, :string, required: true
  slot :inner_block, required: true

  def command_group(assigns) do
    ~H"""
    <div
      data-slot="command-group"
      role="presentation"
      data-part="group"
      class="overflow-hidden p-1 text-foreground data-[visible=false]:hidden"
    >
      <div class="px-2 py-1.5 text-xs font-medium text-muted-foreground">
        {@heading}
      </div>
      <div role="group" class="list-none">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a horizontal divider between command groups.

  Like cmdk, the separator is hidden while the input has a search query, so
  filtered results don't show stray dividers. Pass `always_render` to keep it.

  ## Attributes

    * `:class` - Additional classes to apply.
    * `:always_render` - Keep the separator visible while filtering.

  ## Example

      <.command_group heading="Suggestions">...</.command_group>
      <.command_separator />
      <.command_group heading="Settings">...</.command_group>
  """
  attr :class, :any, default: nil
  attr :always_render, :boolean, default: false
  attr :rest, :global

  def command_separator(assigns) do
    ~H"""
    <div
      data-slot="command-separator"
      data-part="separator"
      data-always-render={@always_render && "true"}
      role="separator"
      class={classes(["-mx-1 h-px bg-border data-[visible=false]:hidden", @class])}
      {@rest}
    />
    """
  end

  @doc """
  Renders a single command item (button).

  ## Attributes

    * `:disabled` - Whether the item is disabled.
    * `:selected` - Whether the item is selected.
    * All global attributes are passed to the `<button>` element.

  ## Slots

    * `:inner_block` (required) - The content of the command item.

  ## Example

      <.command_item phx-click="select_command">
        <.icon name="calendar" />
        <span>Calendar</span>
      </.command_item>
  """
  attr :disabled, :boolean, default: false
  attr :selected, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def command_item(assigns) do
    ~H"""
    <button
      data-slot="command-item"
      tabindex="-1"
      role="option"
      data-part="item"
      class="relative flex cursor-default w-full gap-2 select-none items-center rounded-xs px-2 py-1.5 text-sm outline-hidden disabled:pointer-events-none hover:bg-accent/75 data-[selected=true]:bg-accent data-[selected=true]:text-accent-foreground data-[visible=false]:hidden disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0"
      data-selected={@selected}
      aria-selected={@selected}
      disabled={@disabled}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders a keyboard shortcut hint for a command item.

  ## Attributes

    * `:class` - Additional classes to apply.

  ## Slots

    * `:inner_block` (required) - The shortcut text.

  ## Example

      <.command_shortcut>⌘P</.command_shortcut>
  """
  attr :class, :any, default: ""
  slot :inner_block, required: true

  def command_shortcut(assigns) do
    ~H"""
    <span
      data-slot="command-shortcut"
      data-part="shortcut"
      class={classes(["ms-auto text-xs tracking-widest text-muted-foreground", @class])}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
