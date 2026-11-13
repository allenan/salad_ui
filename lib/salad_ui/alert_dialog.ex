defmodule SaladUI.AlertDialog do
  @moduledoc """
  Implementation of Alert Dialog component for SaladUI framework.

  Alert Dialogs are modal dialogs that require a user action before they can be dismissed,
  used to confirm user decisions or provide critical information.

  ## Examples:

      <.alert_dialog id="delete-confirmation">
        <.alert_dialog_trigger>
          <.button variant="destructive">Delete Account</.button>
        </.alert_dialog_trigger>
        <.alert_dialog_content>
          <.alert_dialog_header>
            <.alert_dialog_title>Are you absolutely sure?</.alert_dialog_title>
            <.alert_dialog_description>
              This action cannot be undone. This will permanently delete your
              account and remove your data from our servers.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action>Continue</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </.alert_dialog>

  With an icon and a compact layout:

      <.alert_dialog id="share-project">
        <.alert_dialog_trigger>
          <.button variant="outline">Share Project</.button>
        </.alert_dialog_trigger>
        <.alert_dialog_content size="sm">
          <.alert_dialog_header>
            <.alert_dialog_media>
              <.icon name="hero-share" class="size-8" />
            </.alert_dialog_media>
            <.alert_dialog_title>Share this project?</.alert_dialog_title>
            <.alert_dialog_description>
              Anyone with the link will be able to view and edit this project.
            </.alert_dialog_description>
          </.alert_dialog_header>
          <.alert_dialog_footer>
            <.alert_dialog_cancel>Cancel</.alert_dialog_cancel>
            <.alert_dialog_action>Share</.alert_dialog_action>
          </.alert_dialog_footer>
        </.alert_dialog_content>
      </.alert_dialog>

  ## Component events

  * `:on-open` - Maps the `open` event. Fired when dialog enters open state.
  * `:on-close` - Maps the `close` event. Fired when dialog enters closed state.

  ## Server commands

  * `"open"` - Opens the dialog.
  * `"close"` - Closes the dialog.

  ## Re-renders

  A LiveView re-render keeps an alert dialog the user opened open, with focus
  where it was and without firing `on-open` again. Changing the rendered
  `open` value opens or closes it; changing other options rebuilds it from the
  new markup.

  ## Modal behaviour

  An alert dialog is always modal, as Radix's is (it takes no `modal`
  option): while it is open, clicks outside it never reach the page (and do
  not close it either), everything outside it is `aria-hidden`, and wheel and
  touch scrolling outside it are cancelled. See "Modal behaviour" in
  `SaladUI.Dialog`.

  ## Scroll lock

  An open alert dialog locks page scrolling, as Radix's does, and pads
  `<body>` by the scrollbar's width so the page does not shift. The lock is
  shared with dialogs, sheets and drawers and counted, so an alert dialog
  opened from a dialog leaves the page locked until both have closed. See
  `SaladUI.Dialog` for details.
  """
  use SaladUI, :component

  @doc """
  The main alert dialog component.

  ## Options

  * `:id` - Required unique identifier for the alert dialog.
  * `:open` - Whether the alert dialog is initially open. Defaults to `false`.
  * `:on-open` - Handler for `open` event. Accepts a server event name or `%Phoenix.LiveView.JS{}`.
  * `:on-close` - Handler for `close` event. Accepts a server event name or `%Phoenix.LiveView.JS{}`.
  * `:class` - Additional CSS classes.

  ## Component events

  * `:on-open` - Fired when the dialog opens.
  * `:on-close` - Fired when the dialog closes.

  ## Server commands

  * `"open"` - Opens the dialog.
  * `"close"` - Closes the dialog.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the alert dialog"
  attr :open, :boolean, default: false, doc: "Whether the alert dialog is initially open"
  attr :"on-open", :any, default: nil, doc: "Handler for alert dialog open event"
  attr :"on-close", :any, default: nil, doc: "Handler for alert dialog close event"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def alert_dialog(assigns) do
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
          closeOnEscape: false,
          closeOnOutsideClick: false,
          modal: true,
          role: "alertdialog"
        })
      )

    ~H"""
    <div
      data-slot="alert-dialog"
      id={@id}
      class={classes(["relative z-50 group/alert-dialog", @class])}
      data-component="dialog"
      data-options={@options}
      data-state={@initial_state}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      data-part="root"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The trigger element that opens the alert dialog.
  """
  attr :class, :string, default: nil
  attr :as, :any, default: "div"
  slot :inner_block, required: true
  attr :rest, :global, include: ~w(variant size)

  def alert_dialog_trigger(assigns) do
    assigns = drop_button_props(assigns)

    ~H"""
    <.dynamic
      data-slot="alert-dialog-trigger"
      data-part="trigger"
      data-action="open"
      tag={@as}
      class={classes(["", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  The content container of the alert dialog.

  ## Options

  * `:size` - `"default"` or `"sm"`. The small size is narrower (`max-w-xs`),
    keeps the header centered and lays the footer buttons out in two columns.
  """
  attr :class, :string, default: nil
  attr :size, :string, values: ~w(default sm), default: "default", doc: "the alert dialog size"
  attr :"aria-label", :string, default: "Alert dialog"
  slot :inner_block, required: true
  attr :rest, :global

  def alert_dialog_content(assigns) do
    ~H"""
    <div data-slot="alert-dialog-portal" data-part="content" tabindex="0" hidden class="z-50">
      <div
        data-slot="alert-dialog-overlay"
        data-part="overlay"
        class="fixed inset-0 z-50 bg-black/50 duration-200 data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fill-mode-forwards data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
      />
      <div
        data-slot="alert-dialog-content"
        data-part="content-panel"
        data-size={@size}
        class={
          classes([
            "group/alert-dialog-content fixed inset-0 z-50 m-auto grid h-fit w-full max-w-[calc(100%-2rem)] gap-4 rounded-lg border bg-background p-6 shadow-lg duration-200 data-[size=sm]:max-w-xs data-[state=closed]:animate-out data-[state=closed]:fill-mode-forwards data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95 data-[size=default]:sm:max-w-lg",
            @class
          ])
        }
        aria-label={assigns[:"aria-label"]}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  The header section of the alert dialog.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def alert_dialog_header(assigns) do
    ~H"""
    <div
      data-slot="alert-dialog-header"
      class={
        classes([
          "grid grid-rows-[auto_1fr] place-items-center gap-1.5 text-center has-data-[slot=alert-dialog-media]:grid-rows-[auto_auto_1fr] has-data-[slot=alert-dialog-media]:gap-x-6 sm:group-data-[size=default]/alert-dialog-content:place-items-start sm:group-data-[size=default]/alert-dialog-content:text-left sm:group-data-[size=default]/alert-dialog-content:has-data-[slot=alert-dialog-media]:grid-rows-[auto_1fr]",
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
  The title of the alert dialog.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def alert_dialog_title(assigns) do
    ~H"""
    <h2
      data-slot="alert-dialog-title"
      data-part="title"
      class={
        classes([
          "text-lg font-semibold sm:group-data-[size=default]/alert-dialog-content:group-has-data-[slot=alert-dialog-media]/alert-dialog-content:col-start-2",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </h2>
    """
  end

  @doc """
  The description of the alert dialog.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def alert_dialog_description(assigns) do
    ~H"""
    <p
      data-slot="alert-dialog-description"
      data-part="description"
      class={
        classes([
          "text-sm text-muted-foreground",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  An icon or image shown above the title (beside it, on wider screens, for the
  default size). Place it first inside `alert_dialog_header/1`.

  ## Examples

      <.alert_dialog_media>
        <.icon name="hero-trash" class="size-8" />
      </.alert_dialog_media>

      <.alert_dialog_media class="bg-destructive/10 text-destructive dark:bg-destructive/20">
        <.icon name="hero-trash" class="size-8" />
      </.alert_dialog_media>
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def alert_dialog_media(assigns) do
    ~H"""
    <div
      data-slot="alert-dialog-media"
      class={
        classes([
          "mb-2 inline-flex size-16 items-center justify-center rounded-md bg-muted sm:group-data-[size=default]/alert-dialog-content:row-span-2 *:[svg:not([class*='size-'])]:size-8",
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
  The footer section of the alert dialog containing action buttons.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :rest, :global

  def alert_dialog_footer(assigns) do
    ~H"""
    <div
      data-slot="alert-dialog-footer"
      class={
        classes([
          "flex flex-col-reverse gap-2 group-data-[size=sm]/alert-dialog-content:grid group-data-[size=sm]/alert-dialog-content:grid-cols-2 sm:flex-row sm:justify-end",
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
  The cancel button for the alert dialog.
  """
  attr :class, :string, default: nil
  attr :variant, :string, values: ~w(default secondary destructive outline ghost link), default: "outline"
  attr :size, :string, values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg), default: "default"
  attr :rest, :global
  slot :inner_block, required: true

  def alert_dialog_cancel(assigns) do
    assigns = assign(assigns, :variant_class, button_variant(%{variant: assigns.variant, size: assigns.size}))

    ~H"""
    <button
      data-slot="alert-dialog-cancel"
      type="button"
      data-part="cancel"
      data-action="close"
      class={
        classes([
          @variant_class,
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
  The primary action button for the alert dialog.
  """
  attr :class, :string, default: nil
  attr :variant, :string, values: ~w(default secondary destructive outline ghost link), default: "default"
  attr :size, :string, values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg), default: "default"
  attr :rest, :global
  slot :inner_block, required: true

  def alert_dialog_action(assigns) do
    assigns = assign(assigns, :variant_class, button_variant(%{variant: assigns.variant, size: assigns.size}))

    ~H"""
    <button
      data-slot="alert-dialog-action"
      type="button"
      data-part="action"
      data-action="close"
      class={
        classes([
          @variant_class,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp get_animation_config do
    %{
      "open_to_closed" => %{
        duration: 200,
        target_part: "content"
      }
    }
  end
end
