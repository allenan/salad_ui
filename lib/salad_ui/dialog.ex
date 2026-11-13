defmodule SaladUI.Dialog do
  @moduledoc """
  Implement of Dialog components from https://ui.shadcn.com/docs/components/dialog

  ## Component events

  * `:on-open` - Maps the `open` event. Fired when dialog enters open state.
  * `:on-close` - Maps the `close` event. Fired when dialog enters closed state.

  ## Server commands

  * `"open"` - Opens the dialog.
  * `"close"` - Closes the dialog.

  ## Parts

  `dialog/1`, `dialog_trigger/1`, `dialog_content/1`, `dialog_header/1`,
  `dialog_title/1`, `dialog_description/1`, `dialog_footer/1`, `dialog_close/1`.

  `dialog_content/1` renders a close button in the top-right corner; pass
  `show_close_button={false}` to hide it. `dialog_close/1` closes the dialog
  from any element you place inside it:

      <.dialog_footer>
        <.dialog_close>
          <.button variant="outline">Cancel</.button>
        </.dialog_close>
        <.button type="submit">Save</.button>
      </.dialog_footer>

  ## Re-renders

  A LiveView re-render (a `phx-change` form inside the dialog validating, a
  flash anywhere on the page) keeps a dialog the user opened open, with focus
  where it was and without firing `on-open` again. Changing the rendered
  `open` value opens or closes it; changing other options rebuilds it from the
  new markup.

  ## Modal behaviour

  Like Radix Dialog, a dialog is modal by default (`modal={true}`). While it
  is open:

  * Clicks outside it never reach the page. `<body>` gets
    `pointer-events: none` and the dialog's content `pointer-events: auto`, so
    a click outside can only dismiss the dialog (through its overlay).
  * Everything outside it is hidden from assistive technology and taken out
    of the tab order: the siblings of the dialog's content and of each of its
    ancestors get `aria-hidden="true"` and `inert` (and a `data-aria-hidden`
    marker). `aria-live` regions are left alone, and elements the page
    already hid stay hidden after the dialog closes.
  * Escape closes only the topmost layer: in a dialog opened from a dialog
    (or a menu or select open inside one) it closes just that one.
  * On close, focus returns to the element focused when it opened, or, when
    that was nothing (a dialog the server opened), to the dialog's trigger.
  * Wheel and touch scrolling outside it are cancelled, so the page behind
    (including a scrollable app layout) cannot scroll through the overlay.
    Scrollable areas inside the dialog still scroll, without chaining to the
    page at their ends; pinch-zoom is never blocked.
  * Page scrolling is locked (see "Scroll lock").

  The page is unblocked as soon as the dialog starts closing; the scroll lock
  holds until its exit animation ends. Content portaled out of the dialog (a
  select, popover or combobox inside it with `use-portal`) counts as part of
  it. Modals stack: a dialog, sheet, drawer or dropdown menu opened from an
  open dialog blocks the dialog too, until it closes. LiveView re-renders
  anywhere on the page re-apply all of this.

  Pass `modal={false}` for a non-modal dialog: no overlay, the page stays
  clickable, readable and scrollable, Tab is not trapped, and a click outside
  the dialog (other than on its trigger) closes it.

  ## Scroll lock

  Like Radix Dialog, an open dialog locks page scrolling: `<html>` and
  `<body>` get `overflow: hidden`, and `<body>` is padded by the scrollbar's
  width so the layout does not shift (nothing is padded when the page uses
  `scrollbar-gutter: stable`). The page's own inline styles come back when the
  dialog has finished closing. Locks are counted, so a dialog opened from
  another dialog, sheet or drawer keeps the page locked until the last one
  closes. While locked, `<body>` carries `data-scroll-locked` and the
  `--removed-body-scroll-bar-size` custom property (the padding added).

  Fixed-position elements at the right edge of the viewport would shift when
  the scrollbar goes away. As with react-remove-scroll-bar (which Radix
  uses), they opt in with a class that `salad_ui.css` styles while the page is
  locked:

  * `right-scroll-bar-position` - for elements pinned with `right: 0` (a
    floating button): `right` moves in by the scrollbar's width.
  * `width-before-scroll-bar` - for full-width elements (a fixed header): a
    right margin of the scrollbar's width.

  Or use the custom property directly:
  `body[data-scroll-locked] .my-header { padding-right: var(--removed-body-scroll-bar-size) }`.
  """
  use SaladUI, :component

  @doc """
  Dialog component

  ## Component events

  * `:on-open` - Fired when the dialog opens.
  * `:on-close` - Fired when the dialog closes.

  ## Server commands

  * `"open"` - Opens the dialog.
  * `"close"` - Closes the dialog.

  ## Examples:

      <.dialog id="pro-dialog" open={true}>
        <.dialog_trigger>Click me</.dialog_trigger>
        <.dialog_content class="sm:max-w-[425px]">
          <.dialog_header>
            <.dialog_title>Edit profile</.dialog_title>
            <.dialog_description>
              Make changes to your profile here. Click save when you're done.
            </.dialog_description>
          </.dialog_header>
          <div class="grid gap-4 py-4">
            <div class="grid grid-cols-4 items-center gap-4">
              <.label for="name" class="text-end">Name</.label>
              <.input id="name" name="name" value="Pedro Duarte" class="col-span-3" />
            </div>
            <div class="grid grid-cols-4 items-center gap-4">
              <.label for="username" class="text-end">Username</.label>
              <.input id="username" name="username" value="@peduarte" class="col-span-3" />
            </div>
          </div>
          <.dialog_footer>
            <.button type="submit">Save changes</.button>
          </.dialog_footer>
        </.dialog_content>
      </.dialog>
  """

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :class, :string, default: nil
  attr :"close-on-outside-click", :boolean, default: true

  attr :modal, :boolean,
    default: true,
    doc: "block, hide and scroll-lock the page while open; `false` makes a non-modal dialog (see Modal behaviour)"

  attr :"on-open", :any,
    default: nil,
    doc: "Handler for dialog open event. Support both server event handler and JS command struct"

  attr :"on-close", :any,
    default: nil,
    doc: "Handler for dialog closed event. Support both server event handler and JS command struct"

  slot :inner_block, required: true

  def dialog(assigns) do
    event_map = event_mappings(assigns)

    assigns =
      assigns
      |> assign(:event_map, json(event_map))
      |> assign(initial_state: if(assigns.open, do: "open", else: "closed"))
      |> assign(
        options:
          json(%{
            closeOnOutsideClick: assigns[:"close-on-outside-click"],
            modal: assigns.modal,
            animations: get_animation_config()
          })
      )

    ~H"""
    <div
      data-slot="dialog"
      id={@id}
      class="group/dialog"
      data-component="dialog"
      data-options={@options}
      data-open={to_string(@open)}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      data-part="root"
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :as, :any, default: "div"
  slot :inner_block, required: true
  attr :rest, :global, include: ~w(variant size)

  def dialog_trigger(assigns) do
    assigns = drop_button_props(assigns)

    ~H"""
    <.dynamic
      data-slot={@rest[:"data-slot"] || "dialog-trigger"}
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

  attr :class, :string, default: nil

  attr :show_close_button, :boolean,
    default: true,
    doc: "render the close button in the top-right corner"

  slot :inner_block, required: true

  def dialog_content(assigns) do
    ~H"""
    <div data-slot="dialog-portal" data-part="content" tabindex="0" hidden class="z-50">
      <div
        data-slot="dialog-overlay"
        data-part="overlay"
        class="fixed inset-0 z-50 bg-black/50 data-[state=open]/dialog:animate-in data-[state=closed]/dialog:animate-out data-[state=closed]/dialog:fade-out-0 data-[state=open]/dialog:fade-in-0"
      />

      <div
        data-slot="dialog-content"
        data-part="content-panel"
        class={
          classes([
            "fixed inset-0 z-50 m-auto grid h-fit w-full max-w-[calc(100%-2rem)] gap-4 rounded-lg border bg-background p-6 shadow-lg duration-200 outline-none data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95 data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95 sm:max-w-lg",
            @class
          ])
        }
      >
        {render_slot(@inner_block)}

        <button
          :if={@show_close_button}
          data-slot="dialog-close"
          type="button"
          data-part="close-trigger"
          data-action="close"
          class="absolute top-4 end-4 rounded-xs opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:ring-2 focus:ring-ring focus:ring-offset-2 focus:outline-hidden disabled:pointer-events-none data-[state=open]:bg-accent data-[state=open]:text-muted-foreground [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4"
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
            class="lucide lucide-x size-4"
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

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def dialog_header(assigns) do
    ~H"""
    <div
      data-slot="dialog-header"
      class={classes(["flex flex-col gap-2 text-center sm:text-start", @class])}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def dialog_title(assigns) do
    ~H"""
    <h3
      data-slot="dialog-title"
      data-part="title"
      class={classes(["text-lg leading-none font-semibold", @class])}
    >
      {render_slot(@inner_block)}
    </h3>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def dialog_description(assigns) do
    ~H"""
    <p
      data-slot="dialog-description"
      data-part="description"
      class={classes(["text-sm text-muted-foreground", @class])}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :class, :string, default: nil

  attr :show_close_button, :boolean,
    default: false,
    doc: "append an outline \"Close\" button that closes the dialog"

  slot :inner_block

  def dialog_footer(assigns) do
    # The footer may hold only the built-in Close button: `<.dialog_footer show_close_button />`
    assigns = assign_new(assigns, :inner_block, fn -> [] end)

    ~H"""
    <div
      data-slot="dialog-footer"
      class={classes(["flex flex-col-reverse gap-2 sm:flex-row sm:justify-end", @class])}
    >
      {render_slot(@inner_block)}
      <button
        :if={@show_close_button}
        type="button"
        data-slot="dialog-close"
        data-part="close"
        data-action="close"
        class={button_variant(%{variant: "outline"})}
      >
        Close
      </button>
    </div>
    """
  end

  @doc """
  Closes the dialog when clicked. Wrap any element (usually a `button/1`) in it,
  the SaladUI equivalent of shadcn's `<DialogClose asChild>`.

  Unlike the built-in top-right close button it takes no extra ARIA label, so
  the wrapped element's own text is announced.

  ## Examples

      <.dialog_close>
        <.button type="button">Close</.button>
      </.dialog_close>

      <.dialog_close as="button" type="button" class="text-sm underline">Dismiss</.dialog_close>
  """
  attr :class, :string, default: nil
  attr :as, :any, default: "div", doc: "the tag (or function component) to render"
  attr :rest, :global, include: ~w(variant size)
  slot :inner_block, required: true

  def dialog_close(assigns) do
    assigns = drop_button_props(assigns)

    ~H"""
    <.dynamic
      data-slot={@rest[:"data-slot"] || "dialog-close"}
      data-part="close"
      data-action="close"
      tag={@as}
      class={@class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  defp get_animation_config do
    %{
      "open_to_closed" => %{
        duration: 130,
        target_part: "content"
      }
    }
  end
end
