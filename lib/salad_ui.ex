defmodule SaladUI do
  @moduledoc """
  SaladUI - A comprehensive UI component library for Phoenix LiveView applications.

  SaladUI provides a collection of accessible, customizable UI components that combine
  server-side rendering with client-side interactivity. Built specifically for Phoenix
  LiveView, it offers seamless integration between Elixir and JavaScript.

  ## Features

  - **40+ UI Components** - Buttons, forms, overlays, navigation, and data display
  - **Accessibility First** - ARIA compliant with keyboard navigation and screen reader support
  - **LiveView Integration** - Two-way communication between server and client
  - **Customizable** - Tailwind CSS based with variant support
  - **Type Safe** - Full attribute validation and documentation

  ## Quick Start

  Add SaladUI to your Phoenix application:

      # In your core components module
      use SaladUI

      # In templates
      <.button phx-click="save">
        Save Changes
      </.button>

  ## Component Categories

  ### Layout & Structure
  - `card/1` - Content containers with headers and footers
  - `separator/1` - Visual dividers between content sections
  - `scroll_area/1` - Custom scrollable containers
  - `aspect_ratio/1` - Content constrained to a width/height ratio
  - `item/1`, `item_group/1` - Flexible rows with media, title, description and actions
  - `resizable_panel_group/1`, `resizable_panel/1`, `resizable_handle/1` - Resizable panel layouts

  ### Forms & Input
  - `button/1` - Interactive buttons with multiple variants
  - `button_group/1` - Groups of joined buttons, inputs and selects
  - `input/1` - Text inputs with validation support
  - `input_group/1` - Inputs with icon, text and button addons
  - `input_otp/1` - One-time password inputs with copy-paste support
  - `textarea/1` - Multi-line text input areas
  - `checkbox/1` - Binary choice inputs
  - `radio_group/1` - Single choice from multiple options
  - `select/1` - Dropdown selection menus
  - `combobox/1` - Autocomplete input with a filtered list, single or multiple (chips)
  - `native_select/1` - Styled native `<select>` with options and optgroups
  - `slider/1` - Range value selection
  - `calendar/1` - Month grid for picking a date, dates or a range
  - `date_picker/1` - Popover + calendar date picker
  - `switch/1` - Toggle controls
  - `questionnaire/1` - Multi-step single, multiple, freeform and skippable questions
  - `field/1`, `field_set/1`, `field_group/1`, `field_label/1`, `field_error/1` - Form field structure and validation
  - `form_item/1`, `form_label/1`, `form_message/1` - Legacy form helpers (prefer `field/1`)

  ### Navigation
  - `tabs/1` - Tabbed content navigation
  - `breadcrumb/1` - Hierarchical navigation paths
  - `navigation_menu/1` - Site navigation with hover/keyboard dropdown panels
  - `menubar/1` - Desktop-style application menu bar
  - `pagination/1` - Page navigation controls
  - `sidebar/1` - Application navigation sidebars

  ### Overlays & Dialogs
  - `dialog/1` - Modal dialogs and confirmations
  - `alert_dialog/1` - Alert and confirmation dialogs
  - `sheet/1` - Slide-out panels
  - `drawer/1` - Draggable bottom/side drawers with snap points
  - `popover/1` - Contextual popup content
  - `tooltip/1` - Hover information displays
  - `hover_card/1` - Rich hover content
  - `dropdown_menu/1` - Contextual action menus
  - `context_menu/1` - Right-click / long-press menus

  ### Feedback & Status
  - `alert/1` - Status messages and notifications
  - `badge/1` - Labels and status indicators
  - `progress/1` - Progress bars and loading states
  - `skeleton/1` - Loading placeholder content
  - `spinner/1` - Animated loading indicator
  - `empty/1` - Empty states with media, title, description and actions

  ### Data Display
  - `table/1` - Data tables with sorting and selection
  - `data_table_column_header/1`, `data_table_view_options/1`, `data_table_pagination/1` - Data table parts; state helpers in `SaladUI.DataTable`
  - `chart/1` - Data visualization charts
  - `code_block/1` - Code, terminal output and diffs with line numbers and a copy button
  - `avatar/1` - User profile images
  - `accordion/1` - Collapsible content sections
  - `kbd/1`, `kbd_group/1` - Keyboard keys and shortcuts
  - `typography_h1/1`, `typography_p/1`, ... - Headings, paragraphs, lists and text styles
  - `carousel/1` - Scroll-snapping slide carousels

  ### Chat
  - `message/1`, `message_group/1` - Chat message layout with avatar, header and footer
  - `message_scroller/1` - Chat transcript scroller: turn anchoring, follow-output, history prepends, jumps
  - `bubble/1`, `bubble_group/1` - Chat bubbles with variants, alignment and reactions
  - `marker/1` - Inline notes, statuses and dividers between turns
  - `attachment/1`, `attachment_upload_entry/1` - File cards, including LiveView upload entries
  - `trace/1`, `trace_collapsible/1` - Agent steps: reasoning, tool calls and sources

  ### Utility
  - `toggle/1`, `toggle_group/1` - Toggle controls and groups
  - `collapsible/1` - Expandable content areas
  - `command/1` - Command palette interfaces (not imported by `use SaladUI`;
    `import SaladUI.Command`, since `command/1` collides with the Lucide icon)
  - `direction_provider/1` - Right-to-left (`dir="rtl"`) support for a subtree

  ## Architecture

  SaladUI uses a hybrid architecture combining:

  - **Phoenix Function Components** - Server-side rendering with HEEx templates
  - **JavaScript State Machines** - Client-side behavior and interactivity
  - **LiveView Hooks** - Seamless server-client communication
  - **Automatic ARIA** - Accessibility attributes managed by the framework

  ## Usage Patterns

  ### Basic Component Usage

      <.button variant="outline" size="lg">
        Large Outline Button
      </.button>

  ### Form Integration

      <.form for={@form} phx-change="validate" phx-submit="save">
        <.field field={@form[:email]}>
          <.field_label field={@form[:email]}>Email</.field_label>
          <.input field={@form[:email]} type="email" />
          <.field_error field={@form[:email]} />
        </.field>
      </.form>

  ### Interactive Components with Events

      <.dialog id="user-dialog" on-open={JS.push("dialog_opened")}>
        <.dialog_trigger>
          <.button>Edit Profile</.button>
        </.dialog_trigger>
        <.dialog_content>
          <!-- Dialog content -->
        </.dialog_content>
      </.dialog>

  ### Server-Client Communication

      # Send commands to components from LiveView
      def handle_event("open_dialog", _params, socket) do
        socket = SaladUI.LiveView.send_command(socket, "user-dialog", "open")
        {:noreply, socket}
      end

  ## Importing components

  `use SaladUI` imports every component module (except `SaladUI.Command`) and
  the helpers. When names clash with your own (`sidebar/1`, `message/1`,
  `json/1`, ...), narrow the imports with `only:` or `except:`. Both take
  component modules, `name: arity` pairs and bare function names (every
  arity):

      use SaladUI, except: [SaladUI.Sidebar, :json, message: 1]
      use SaladUI, only: [SaladUI.Button, SaladUI.Dialog, SaladUI.Command]

  ## Customization

  Components support extensive customization through:

  - **Variants** - Pre-defined style variations (e.g., `variant="destructive"`)
  - **Classes** - Custom CSS classes via the `class` attribute
  - **Slots** - Flexible content areas within components
  - **Attributes** - Comprehensive configuration options

  ## Accessibility

  All components include:

  - Proper ARIA attributes and roles
  - Keyboard navigation support
  - Focus management for overlays
  - Screen reader announcements
  - High contrast support

  ## Development

  When extending SaladUI:

  1. **Follow naming conventions** - Use `kebab-case` for data attributes
  2. **Implement state machines** - Define clear states and transitions
  3. **Handle accessibility** - Include ARIA configuration
  4. **Test thoroughly** - Verify keyboard and screen reader usage
  5. **Document examples** - Provide clear usage examples
  """

  def component do
    quote do
      use Phoenix.Component

      import SaladUI.Helpers

      alias Phoenix.LiveView.JS

      defp classes(input) do
        tw_merge(input)
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate macro.

  `use SaladUI` imports the components; `only:` and `except:` narrow the
  imports (see "Importing components" above).
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__(opts) when is_list(opts) do
    case Keyword.keys(opts) -- [:only, :except] do
      [] -> :ok
      keys -> raise ArgumentError, "unknown options #{inspect(keys)} for `use #{inspect(__MODULE__)}`"
    end

    only = expand_import_opts(opts[:only], __CALLER__)
    except = expand_import_opts(opts[:except] || [], __CALLER__)

    if is_nil(only) and except == [],
      do: default_imports(),
      else: filter_imports(default_imports(), only, except)
  end

  # The modules `use SaladUI` imports. `mix salad.add` rewrites this list in
  # a local copy, so keep it a plain list of imports.
  defp default_imports do
    quote do
      import SaladUI.Accordion
      import SaladUI.Alert
      import SaladUI.AlertDialog
      import SaladUI.AspectRatio
      import SaladUI.Attachment
      import SaladUI.Avatar
      import SaladUI.Badge
      import SaladUI.Breadcrumb
      import SaladUI.Bubble
      import SaladUI.Button
      import SaladUI.ButtonGroup
      import SaladUI.Calendar
      import SaladUI.Card
      import SaladUI.Carousel
      import SaladUI.Chart
      import SaladUI.Checkbox
      import SaladUI.CodeBlock
      import SaladUI.Collapsible
      import SaladUI.Combobox
      # SaladUI.Command is not imported: its command/1 collides with the
      # Lucide `command` icon. Add `import SaladUI.Command` where needed.
      import SaladUI.ContextMenu

      import SaladUI.DataTable,
        only: [data_table_column_header: 1, data_table_pagination: 1, data_table_view_options: 1]

      import SaladUI.DatePicker
      import SaladUI.Dialog
      import SaladUI.Direction
      import SaladUI.Drawer
      import SaladUI.DropdownMenu
      import SaladUI.Empty
      import SaladUI.Field
      import SaladUI.Form
      import SaladUI.Helpers
      import SaladUI.HoverCard
      import SaladUI.Icon
      import SaladUI.Input
      import SaladUI.InputGroup
      import SaladUI.InputOTP
      import SaladUI.Item
      import SaladUI.Kbd
      import SaladUI.Label
      import SaladUI.Marker
      import SaladUI.Menu
      import SaladUI.Menubar
      import SaladUI.Message
      import SaladUI.MessageScroller
      import SaladUI.NativeSelect
      import SaladUI.NavigationMenu
      import SaladUI.Pagination
      import SaladUI.Popover
      import SaladUI.Progress
      import SaladUI.Questionnaire
      import SaladUI.RadioGroup
      import SaladUI.Resizable
      import SaladUI.ScrollArea
      import SaladUI.Select
      import SaladUI.Separator
      import SaladUI.Sheet
      import SaladUI.Sidebar
      import SaladUI.Skeleton
      import SaladUI.Slider
      import SaladUI.Spinner
      import SaladUI.Switch
      import SaladUI.Table
      import SaladUI.Tabs
      import SaladUI.Textarea
      import SaladUI.Toast
      import SaladUI.Toggle
      import SaladUI.ToggleGroup
      import SaladUI.Tooltip
      import SaladUI.Trace
      import SaladUI.Typography
    end
  end

  defp expand_import_opts(nil, _env), do: nil

  defp expand_import_opts(list, env) when is_list(list) do
    Enum.map(list, fn
      {name, arity} when is_atom(name) and is_integer(arity) -> {name, arity}
      entry -> import_entry(Macro.expand(entry, env))
    end)
  end

  defp expand_import_opts(other, _env) do
    raise ArgumentError, "`only:` and `except:` take a list, got: #{Macro.to_string(other)}"
  end

  # A module (`SaladUI.Sidebar`) or a function name (`:sidebar`, any arity).
  defp import_entry(atom) when is_atom(atom) do
    if match?("Elixir." <> _, Atom.to_string(atom)), do: {:module, atom}, else: {atom, :any}
  end

  defp import_entry(other) do
    raise ArgumentError,
          "`only:` and `except:` take modules, `name: arity` pairs or function names, " <>
            "got: #{Macro.to_string(other)}"
  end

  defp filter_imports({:__block__, _, nodes}, only, except) do
    defaults =
      Enum.map(nodes, fn {:import, _, [{:__aliases__, _, parts} | opts]} ->
        {Module.concat(parts), List.first(opts, [])}
      end)

    default_modules = Enum.map(defaults, &elem(&1, 0))
    {only_modules, only_functions} = split_import_entries(only || [])
    {except_modules, except_functions} = split_import_entries(except)

    for module <- except_modules, module not in default_modules do
      raise ArgumentError, "`use #{inspect(__MODULE__)}, except:` names #{inspect(module)}, which it doesn't import"
    end

    selected =
      if is_nil(only) do
        Enum.reject(defaults, fn {module, _} -> module in except_modules end)
      else
        whole = Enum.filter(defaults, fn {module, _} -> module in only_modules end)
        extra = for module <- only_modules, module not in default_modules, do: {Code.ensure_compiled!(module), []}

        partial =
          for {module, _} <- defaults,
              module not in only_modules,
              funs = matching_functions(module, only_functions),
              funs != [],
              do: {module, [only: funs]}

        check_matched!(only_functions, Enum.flat_map(partial, fn {_, opts} -> opts[:only] end), :only)
        whole ++ extra ++ partial
      end

    dropped = Map.new(selected, fn {module, _} -> {module, matching_functions(module, except_functions)} end)
    check_matched!(except_functions, dropped |> Map.values() |> List.flatten(), :except)

    imports =
      for {module, opts} <- selected,
          opts = drop_functions(opts, Map.fetch!(dropped, module)),
          opts != :none,
          do: quote(do: import(unquote(module), unquote(opts)))

    {:__block__, [], imports}
  end

  defp split_import_entries(entries) do
    {modules, functions} = Enum.split_with(entries, &match?({:module, _}, &1))
    {Enum.map(modules, &elem(&1, 1)), functions}
  end

  defp matching_functions(_module, []), do: []

  defp matching_functions(module, entries) do
    for {name, arity} = fun <- Code.ensure_compiled!(module).__info__(:functions),
        Enum.any?(entries, fn {n, a} -> n == name and a in [arity, :any] end),
        do: fun
  end

  defp check_matched!(entries, found, option) do
    for {name, arity} <- entries,
        not Enum.any?(found, fn {n, a} -> n == name and arity in [a, :any] end) do
      raise ArgumentError,
            "`use #{inspect(__MODULE__)}, #{option}:` names #{name}/#{if arity == :any, do: "*", else: arity}, " <>
              "which no imported module defines"
    end
  end

  defp drop_functions(opts, []), do: opts

  defp drop_functions(opts, funs) do
    case Keyword.fetch(opts, :only) do
      {:ok, only} -> if only -- funs == [], do: :none, else: [only: only -- funs]
      :error -> Keyword.update(opts, :except, funs, &(&1 ++ funs))
    end
  end
end
