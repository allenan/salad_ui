defmodule SaladUI.Command do
  @moduledoc """
  Command palette components for SaladUI.

  Provides a set of components to build a command palette or searchable menu, similar to those found in modern applications.

  `use SaladUI` does not import this module, because `command/1` collides with
  the Lucide `command` icon. Add `import SaladUI.Command` to the modules that
  render a command palette.

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

  ## Re-renders

  A LiveView re-render keeps the current filter and the highlighted item, and
  filters any items the server adds or replaces with the query in the input.
  """
  use SaladUI, :component

  import SaladUI.Dialog

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

  The dialog gets a screen-reader-only header (title and description), as in
  shadcn's `CommandDialog`, so the dialog has an accessible name.

  ## Attributes

    * `:id` (required) - The unique id for the command palette. The dialog's id is `"<id>_dialog"`.
    * `:open` - Whether the dialog is open.
    * `:title` - The dialog's accessible title. Defaults to `"Command Palette"`.
    * `:description` - The dialog's accessible description. Defaults to `"Search for a command to run..."`.
    * `:show_close_button` - Render the dialog's close button. Defaults to `true`.
    * `:class` - Additional classes for the dialog content.

  ## Slots

    * `:inner_block` (required) - The content of the command palette.

  ## Example

      <.command_dialog id="my-command" open={@show_command} title="Search" show_close_button={false}>
        ...
      </.command_dialog>
  """
  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :title, :string, default: "Command Palette", doc: "the dialog's accessible (sr-only) title"

  attr :description, :string,
    default: "Search for a command to run...",
    doc: "the dialog's accessible (sr-only) description"

  attr :show_close_button, :boolean, default: true, doc: "render the dialog's close button"
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def command_dialog(assigns) do
    ~H"""
    <.dialog id={@id <> "_dialog"} open={@open}>
      <.dialog_content
        class={classes(["overflow-hidden p-0", @class])}
        show_close_button={@show_close_button}
      >
        <.dialog_header class="sr-only">
          <.dialog_title>{@title}</.dialog_title>
          <.dialog_description>{@description}</.dialog_description>
        </.dialog_header>
        <.command
          id={@id}
          class="**:data-[slot=command-input-wrapper]:h-12 **:data-[slot=command-group-heading]:px-2 **:data-[slot=command-group-heading]:font-medium **:data-[slot=command-group-heading]:text-muted-foreground **:data-[slot=command-group]:px-2 [&_[data-slot=command-group]:not([data-visible=false])~[data-slot=command-group]]:pt-0 [&_[data-slot=command-input-wrapper]_svg]:h-5 [&_[data-slot=command-input-wrapper]_svg]:w-5 **:data-[slot=command-input]:h-12 **:data-[slot=command-item]:px-2 **:data-[slot=command-item]:py-3 [&_[data-slot=command-item]_svg]:h-5 [&_[data-slot=command-item]_svg]:w-5"
        >
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

  attr :rest, :global,
    default: %{},
    include: ~w(placeholder name value autofocus disabled readonly maxlength minlength)

  def command_input(assigns) do
    ~H"""
    <div
      data-slot="command-input-wrapper"
      data-part="input-wrapper"
      class="flex h-9 items-center gap-2 border-b px-3"
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
        class="size-4 shrink-0 opacity-50"
        aria-hidden="true"
      >
        <path d="m21 21-4.34-4.34" /><circle cx="11" cy="11" r="8" />
      </svg>
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
            "flex h-10 w-full rounded-md bg-transparent py-3 text-sm outline-hidden placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50",
            # cancel form-plugin input borders, padding and focus rings
            "border-none px-0 focus:ring-transparent",
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
      class={classes(["max-h-[300px] scroll-py-1 overflow-x-hidden overflow-y-auto", @class])}
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

    * `:heading` (required) - The group heading (`data-slot="command-group-heading"`).
    * `:class` - Additional classes to apply.

  ## Slots

    * `:inner_block` (required) - The command items in the group.

  ## Example

      <.command_group heading="Settings">
        <.command_item>Profile</.command_item>
      </.command_group>
  """
  attr :heading, :string, required: true
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def command_group(assigns) do
    ~H"""
    <div
      data-slot="command-group"
      role="presentation"
      data-part="group"
      class={classes(["overflow-hidden p-1 text-foreground data-[visible=false]:hidden", @class])}
    >
      <div
        data-slot="command-group-heading"
        aria-hidden="true"
        class="px-2 py-1.5 text-xs font-medium text-muted-foreground"
      >
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

    * `:disabled` - Whether the item is disabled (also sets `data-disabled="true"`).
    * `:selected` - Whether the item is selected.
    * `:class` - Additional classes to apply.
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
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def command_item(assigns) do
    ~H"""
    <button
      data-slot="command-item"
      tabindex="-1"
      role="option"
      data-part="item"
      class={
        classes([
          "relative flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 data-[selected=true]:bg-accent data-[selected=true]:text-accent-foreground [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 [&_svg:not([class*='text-'])]:text-muted-foreground",
          # SaladUI items are <button>s: fill the row, show hover, hide when filtered out
          "w-full text-left hover:bg-accent/75 data-[visible=false]:hidden",
          @class
        ])
      }
      data-selected={@selected}
      aria-selected={@selected}
      data-disabled={@disabled && "true"}
      aria-disabled={@disabled && "true"}
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
