defmodule SaladUI.HoverCard do
  @moduledoc """
  Implementation of hover card component with positioning and hover interactions.

  When a user hovers over the trigger element, the content card appears with a small delay.
  The card disappears when the user moves away from both the trigger and the content.

  ## Examples:

      <.hover_card id="user-hover-card">
        <.hover_card_trigger>
          <.button variant="link">@salad_ui</.button>
        </.hover_card_trigger>
        <.hover_card_content>
          <div class="flex flex-col gap-2">
            <div class="flex items-center gap-3">
              <img src="/images/avatar.png" alt="" class="size-10 rounded-full" />
              <div>
                <div class="font-semibold">SaladUI</div>
                <div class="text-sm text-muted-foreground">@salad_ui</div>
              </div>
            </div>
            <p class="text-sm">
              UI component library for modern web applications.
            </p>
          </div>
        </.hover_card_content>
      </.hover_card>

  ## Component events

  * `:on-open` - Maps the `open` event. Fired when the hover card enters open state.
  * `:on-close` - Maps the `close` event. Fired when the hover card enters closed state.

  Hover card is a pure client-side interaction (hover/focus driven) and does not
  support `SaladUI.LiveView.send_command/4`.

  ## Re-renders

  A LiveView re-render keeps an open hover card open and positioned, and a
  pending open or close still runs. Changing the options rebuilds it from the
  new markup.

  ## Shared hover cards for long lists

  A hover card per row costs a hook and the card's markup per row. A hover
  card with no nested trigger can instead serve many *detached* triggers:
  `hover_card_trigger/1` with `for` (the card's id), rendered anywhere
  outside it. The card listens on the document (no hook per trigger), opens
  at the hovered or focused trigger with the usual delays, and gives that
  trigger `aria-expanded="true"` and `data-state="open"` while open. If the
  trigger leaves the page, the card closes. The content stays server
  rendered; two patterns:

  **One card per entity** (preferred when entities are far fewer than rows,
  e.g. a chat's authors against its messages): render each card once, and
  point every row's trigger at its entity's card.

      <.hover_card :for={user <- @authors} id={"user-card-\#{user.id}"}>
        <.hover_card_content><.profile user={user} /></.hover_card_content>
      </.hover_card>

      <.hover_card_trigger as="button" type="button" for={"user-card-\#{msg.user_id}"}>
        {msg.author}
      </.hover_card_trigger>

  **One card for everything**: the server fills the card from the trigger's
  `context` in `on-open`. With a server event, the card pushes `open` with
  the context when the open delay ends and shows once the reply (and the
  content LiveView patched in for it) has arrived, so it never flashes the
  previous trigger's content:

      <.hover_card id="profile-card" on-open="show_profile">
        <.hover_card_content><.profile :if={@profile} user={@profile} /></.hover_card_content>
      </.hover_card>

      <.hover_card_trigger as="button" type="button" for="profile-card" context={%{id: user.id}}>
        {user.name}
      </.hover_card_trigger>

      def handle_event("show_profile", %{"id" => id}, socket),
        do: {:noreply, assign(socket, :profile, Accounts.get_user!(id))}

  Detached triggers are an opt-in SaladUI extension with no Radix
  equivalent; see "Shared menus" in `SaladUI.DropdownMenu`.
  """
  use SaladUI, :component

  @doc """
  The main hover card component that manages state and positioning.

  ## Options

  * `:id` - Required unique identifier for the hover card.
  * `:open-delay` - Delay in milliseconds before opening the hover card. Defaults to `300`.
  * `:close-delay` - Delay in milliseconds before closing the hover card. Defaults to `200`.
  * `:on-open` - Handler for hover card open event; with detached triggers it receives the
    trigger's `context` (see "Shared hover cards for long lists").
  * `:on-close` - Handler for hover card close event.
  * `:class` - Additional CSS classes.

  ## Component events

  * `:on-open` - Fired when the hover card opens.
  * `:on-close` - Fired when the hover card closes.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the hover card"
  attr :"open-delay", :integer, default: 300, doc: "Delay in milliseconds before opening the hover card"
  attr :"close-delay", :integer, default: 200, doc: "Delay in milliseconds before closing the hover card"
  attr :"on-open", :any, default: nil, doc: "Handler for hover card open event"
  attr :"on-close", :any, default: nil, doc: "Handler for hover card close event"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def hover_card(assigns) do
    # Collect event mappings
    event_map = event_mappings(assigns)

    assigns =
      assigns
      |> assign(:event_map, Jason.encode!(event_map))
      |> assign(
        :options,
        Jason.encode!(%{
          openDelay: assigns[:"open-delay"],
          closeDelay: assigns[:"close-delay"],
          animations: get_animation_config()
        })
      )

    ~H"""
    <div
      data-slot="hover-card"
      id={@id}
      class={classes(["inline-block relative", @class])}
      data-component="hover-card"
      data-state="closed"
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
  The trigger element that activates the hover card when hovered.

  With `for`, it is a detached trigger of the shared `hover_card/1` with that
  id, rendered anywhere outside it (see "Shared hover cards for long lists").

  ## Options

  * `:as` - Tag or function component to render. Defaults to `"div"`.
  * `:for` - The id of a shared `hover_card/1` this trigger opens. Defaults to `nil` (nested).
  * `:context` - With `for`: a map the card's `on-open` receives.
  * `:class` - Additional CSS classes.
  """
  attr :as, :any, default: "div"
  attr :for, :string, default: nil, doc: "id of the shared hover card this detached trigger opens"
  attr :context, :map, default: nil, doc: "with `for`: the map `on-open` receives"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(type variant size)
  slot :inner_block, required: true

  def hover_card_trigger(assigns) do
    assigns =
      assigns
      |> drop_button_props()
      |> assign(:trigger_attrs, trigger_attrs(assigns.for, assigns.context))
      |> assign(:detached_aria, if(assigns.for, do: %{"aria-haspopup": "dialog", "aria-expanded": "false"}, else: %{}))

    ~H"""
    <.dynamic
      tag={@as}
      data-slot={@rest[:"data-slot"] || "hover-card-trigger"}
      class={classes(["", @class])}
      {@trigger_attrs}
      {@detached_aria}
      {Map.delete(@rest, :"data-slot")}
    >
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  The hover card content that appears when triggered.

  ## Options

  * `:side` - Placement of the hover card relative to the trigger (top, right, bottom, left). Defaults to `"bottom"`, as in shadcn/ui.
  * `:align` - Alignment of the hover card (start, center, end). Defaults to `"center"`.
    `start`/`end` mirror under `dir="rtl"` for `top`/`bottom` sides.
  * `:side-offset` - Distance from the trigger in pixels. Defaults to `4`.
  * `:align-offset` - Offset along the alignment axis. Defaults to `0`.
  * `:collision-padding` - Distance in pixels kept from the viewport edges when
    the content flips or shifts to stay visible. Defaults to `0`, as in Radix.
  * `:class` - Additional CSS classes.
  """
  attr :class, :any, default: nil
  attr :side, :string, values: ~w(top right bottom left), default: "bottom"
  attr :align, :string, values: ~w(start center end), default: "center"
  attr :"side-offset", :integer, default: 4, doc: "Distance from the trigger in pixels"
  attr :"align-offset", :integer, default: 0, doc: "Offset along the alignment axis"
  attr :"collision-padding", :integer, default: 0, doc: "Distance kept from the viewport edges"
  attr :rest, :global
  slot :inner_block, required: true

  def hover_card_content(assigns) do
    assigns =
      assign(assigns,
        side_offset: assigns[:"side-offset"],
        align_offset: assigns[:"align-offset"],
        collision_padding: assigns[:"collision-padding"]
      )

    ~H"""
    <div
      data-slot="hover-card-portal"
      data-part="content"
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      data-align-offset={@align_offset}
      data-collision-padding={@collision_padding}
      class="z-50"
      hidden
      {@rest}
    >
      <div
        data-slot="hover-card-content"
        data-side={@side}
        class={
          classes([
            "z-50 w-64 rounded-md border border-border bg-popover p-4 text-popover-foreground shadow-md outline-hidden",
            "data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0 data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
            @class
          ])
        }
        data-part="content-wrapper"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
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
