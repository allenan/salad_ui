defmodule SaladUI.Sheet do
  @moduledoc """
  Implementation of Sheet component for SaladUI framework.

  Sheets are like dialogs that appear from the edge of the screen. They can be configured
  to slide in from different sides of the viewport.

  ## Examples:

      <.sheet id="user-sheet">
        <.sheet_trigger>
          <.button variant="outline">Open Sheet</.button>
        </.sheet_trigger>
        <.sheet_content side="right">
          <.sheet_header>
            <.sheet_title>Edit profile</.sheet_title>
            <.sheet_description>
              Make changes to your profile here. Click save when you're done.
            </.sheet_description>
          </.sheet_header>
          <div class="grid flex-1 auto-rows-min gap-6 px-4">
            <div class="grid gap-3">
              <.label for="name">Name</.label>
              <.input id="name" value="John Doe" />
            </div>
          </div>
          <.sheet_footer>
            <.button type="submit">Save changes</.button>
            <.sheet_close>
              <.button variant="outline" class="w-full">Close</.button>
            </.sheet_close>
          </.sheet_footer>
        </.sheet_content>
      </.sheet>

  ## Component events

  * `:on-open` - Maps the `open` event. Fired when sheet enters open state.
  * `:on-close` - Maps the `close` event. Fired when sheet enters closed state.

  ## Server commands

  * `"open"` - Opens the sheet.
  * `"close"` - Closes the sheet.

  ## Re-renders

  A LiveView re-render (a `phx-change` form inside the sheet validating, a
  flash anywhere on the page) keeps a sheet the user opened open, with focus
  where it was and without firing `on-open` again. Changing the rendered
  `open` value opens or closes it; changing other options rebuilds it from the
  new markup.

  ## Scroll lock

  An open sheet locks page scrolling, as shadcn's (Radix) Sheet does, and
  pads `<body>` by the scrollbar's width so the page does not shift. The lock
  is shared with dialogs and drawers and counted, so the page unlocks once
  the last open one has closed. See `SaladUI.Dialog` for details.
  """
  use SaladUI, :component

  @doc """
  The main sheet component that manages state and positioning.

  ## Options

  * `:id` - Required unique identifier for the sheet.
  * `:open` - Whether the sheet is initially open. Defaults to `false`.
  * `:on-open` - Handler for `open` event. Accepts a server event name or `%Phoenix.LiveView.JS{}`.
  * `:on-close` - Handler for `close` event. Accepts a server event name or `%Phoenix.LiveView.JS{}`.
  * `:"close-on-outside-click"` - Whether overlay/outside click closes the sheet. Defaults to `true`.
  * `:class` - Additional CSS classes.

  ## Component events

  * `:on-open` - Fired when the sheet opens.
  * `:on-close` - Fired when the sheet closes.

  ## Server commands

  Use `SaladUI.LiveView.send_command(socket, id, command)` with:

  * `"open"` - Opens the sheet.
  * `"close"` - Closes the sheet.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the sheet"
  attr :open, :boolean, default: false, doc: "Whether the sheet is initially open"
  attr :class, :string, default: nil
  attr :"close-on-outside-click", :boolean, default: true

  attr :"on-open", :any, default: nil, doc: "Handler for sheet open event"
  attr :"on-close", :any, default: nil, doc: "Handler for sheet close event"
  attr :rest, :global
  slot :inner_block, required: true

  def sheet(assigns) do
    # Collect event mappings
    event_map = event_mappings(assigns)

    assigns =
      assigns
      |> assign(:event_map, json(event_map))
      |> assign(:initial_state, if(assigns.open, do: "open", else: "closed"))
      |> assign(
        :options,
        json(%{
          animations: get_animation_config(),
          closeOnOutsideClick: assigns[:"close-on-outside-click"]
        })
      )

    ~H"""
    <div
      data-slot="sheet"
      id={@id}
      class={classes(["relative inline-block", @class])}
      data-component="dialog"
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
  The trigger element that opens the sheet.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sheet_trigger(assigns) do
    ~H"""
    <div
      data-slot="sheet-trigger"
      data-part="trigger"
      data-action="open"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The sheet content that appears when triggered.

  Renders the overlay and the sliding panel. The panel is a `flex flex-col gap-4`
  column with no padding of its own: `sheet_header/1` and `sheet_footer/1` carry
  `p-4`, and the footer is pushed to the bottom with `mt-auto`.

  ## Options

  * `:side` - The side from which the sheet appears (top, right, bottom, left). Defaults to `"right"`.
    Rendered as `data-side`, so `class` can target a side, e.g. `data-[side=bottom]:max-h-[50vh]`.
  * `:show_close_button` - Render the close (X) button in the top-right corner. Defaults to `true`.
  * `:class` - Additional CSS classes to customize dimensions and appearance.

  ## Examples

      <.sheet_content side="left" show_close_button={false}>
        <.sheet_header>
          <.sheet_title>No Close Button</.sheet_title>
        </.sheet_header>
      </.sheet_content>
  """
  attr :class, :string, default: nil
  attr :side, :string, values: ~w(top right bottom left), default: "right", doc: "The side from which the sheet appears"

  attr :show_close_button, :boolean,
    default: true,
    doc: "render the close button in the top-right corner"

  attr :rest, :global
  slot :inner_block, required: true

  def sheet_content(assigns) do
    assigns =
      assigns
      |> assign(:variant_class, sheet_variants(assigns))
      |> put_data_slot("sheet-content")

    ~H"""
    <div data-slot="sheet-portal" data-part="content" tabindex="0" hidden>
      <div
        data-slot="sheet-overlay"
        data-part="overlay"
        class="fixed inset-0 z-50 bg-black/50 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=closed]:fill-mode-forwards"
      />

      <div
        data-part="content-panel"
        data-side={@side}
        class={
          classes([
            "fixed z-50 flex flex-col gap-4 bg-background shadow-lg transition ease-in-out data-[state=closed]:animate-out data-[state=closed]:duration-300 data-[state=open]:animate-in data-[state=open]:duration-500",
            "data-[state=closed]:fill-mode-forwards",
            @variant_class,
            @class
          ])
        }
        {@rest}
      >
        {render_slot(@inner_block)}

        <button
          :if={@show_close_button}
          data-slot="sheet-close"
          type="button"
          data-part="close-trigger"
          data-action="close"
          class="absolute top-4 end-4 rounded-xs opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:ring-2 focus:ring-ring focus:ring-offset-2 focus:outline-hidden disabled:pointer-events-none data-[state=open]:bg-secondary"
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
            class="size-4"
            aria-hidden="true"
          >
            <path d="M18 6 6 18"></path>
            <path d="m6 6 12 12"></path>
          </svg>
          <span class="sr-only">Close</span>
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a sheet header section for title and description.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sheet_header(assigns) do
    ~H"""
    <div
      data-slot="sheet-header"
      class={classes(["flex flex-col gap-1.5 p-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a sheet title within the header section.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sheet_title(assigns) do
    ~H"""
    <h3
      data-slot="sheet-title"
      data-part="title"
      class={classes(["font-semibold text-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </h3>
    """
  end

  @doc """
  Renders a sheet description within the header section.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sheet_description(assigns) do
    ~H"""
    <p
      data-slot="sheet-description"
      data-part="description"
      class={classes(["text-sm text-muted-foreground", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a footer section for the sheet, typically containing actions.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sheet_footer(assigns) do
    ~H"""
    <div
      data-slot="sheet-footer"
      class={classes(["mt-auto flex flex-col gap-2 p-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The close button for the sheet.
  """
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def sheet_close(assigns) do
    ~H"""
    <div
      data-slot="sheet-close"
      data-part="close-trigger"
      data-action="close"
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp get_animation_config do
    %{
      "open_to_closed" => %{
        duration: 300,
        target_part: "content"
      }
    }
  end

  @variants %{
    side: %{
      "top" => "inset-x-0 top-0 h-auto border-b data-[state=closed]:slide-out-to-top data-[state=open]:slide-in-from-top",
      "bottom" =>
        "inset-x-0 bottom-0 h-auto border-t data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom",
      "left" =>
        "inset-y-0 left-0 h-full w-3/4 border-r data-[state=closed]:slide-out-to-left data-[state=open]:slide-in-from-left sm:max-w-sm",
      "right" =>
        "inset-y-0 right-0 h-full w-3/4 border-l data-[state=closed]:slide-out-to-right data-[state=open]:slide-in-from-right sm:max-w-sm"
    }
  }

  defp sheet_variants(props) do
    variants =
      Map.take(props, ~w(side)a)

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end
end
