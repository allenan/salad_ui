defmodule SaladUI.Toast do
  @moduledoc """
  Toast notifications, parity target [Sonner](https://sonner.emilkowal.ski/).

  Unlike every other SaladUI component, `toaster/1` does not manage a single
  open/closed state machine — it mounts once per page and manages an unbounded,
  dynamically created stack of independent toast cards entirely in JavaScript
  (`assets/salad_ui/components/toast.js`).

  ## Mounting

      <.toaster id="toaster" position="bottom-right" />

  ## Triggering toasts

  Use the helpers below from any `handle_event/3`:

      def handle_event("save", _params, socket) do
        {:noreply, SaladUI.Toast.toast_success(socket, "Saved!")}
      end

  Variants mirror Sonner's types: `toast/3` (default), `toast_success/3`,
  `toast_info/3`, `toast_warning/3`, `toast_error/3` and `toast_loading/3`.
  Each non-default variant shows shadcn's lucide icon (CircleCheck, Info,
  TriangleAlert, OctagonX, and a spinning Loader2 for loading).

  Every helper also takes `description:`, `position:` (any of the toaster's
  six positions, per toast), `duration:` (ms or `:infinity`), `id:`,
  `action:`/`cancel:`, `icon:`, `color:`, `class:`, `dismissible:`,
  `close_button:` (overrides the toaster's `close-button`) and
  `toaster:` (target a `<.toaster>` other than `"toaster"`):

      toast(socket, "Event has been created",
        description: "Monday, January 3rd at 6:00pm",
        position: "top-center"
      )

  ## Loading and promise toasts

  A loading toast never times out and can't be swiped away. Resolve it in
  place, so one card morphs from loading to success or error the way Sonner's
  `toast.promise` does. With `start_async/3`:

      def handle_event("create", _params, socket) do
        {:noreply,
         socket
         |> toast_promise("create-event", loading: "Loading...")
         |> start_async(:create_event, fn -> Events.create() end)}
      end

      def handle_async(:create_event, result, socket) do
        {:noreply,
         toast_resolve(socket, "create-event", result,
           success: fn event -> "\#{event.name} has been created" end,
           error: "Error"
         )}
      end

  `toast_resolve/4` maps `{:ok, value}` to success and `{:exit, reason}`,
  `{:ok, {:error, reason}}` or `{:ok, :error}` to error. To resolve by hand,
  call `toast_update/3`:

      toast_update(socket, "create-event", variant: "success", message: "Event has been created")

  ## Rich-content toasts

  Declare a `:template` next to the toaster and reference it by name:

      <.toaster id="toaster">
        <:template name="new-follower">
          <img src={@avatar_url} class="size-8 rounded-full" />
          <p><%= @name %> followed you</p>
        </:template>
      </.toaster>

      SaladUI.Toast.toast(socket, template: "new-follower")

  ## Customization

  SaladUI ships no predefined per-variant palette — every toast renders in
  shadcn's neutral card (`border-border bg-popover text-popover-foreground`,
  `rounded-(--radius)`) unless you opt in, either toaster-wide or per call.

  Toaster-wide, applied to every card of that variant:

      <.toaster
        id="toaster"
        colors={%{success: "border-emerald-500/30 bg-emerald-50 text-emerald-900"}}
      />

  Per-toast, overriding the toaster-wide default for just this call:

      SaladUI.Toast.toast_success(socket, "Saved!",
        color: "border-emerald-500/30 bg-emerald-50 text-emerald-900"
      )

  `color`/`colors` replace the card's default border/background/text as one
  unit — the icon and title inherit the resulting text color, while the
  description keeps its own muted color. The toaster's `class` attr and a
  per-toast `class` opt instead *append* to the default classes, so reach for
  `!`-prefixed utilities there to reliably win the cascade:

      SaladUI.Toast.toast(socket, "Something broke",
        class: "!border-fuchsia-500/30 !bg-fuchsia-50 !text-fuchsia-900"
      )

  Icons are overridden with an icon class name, toaster-wide by variant or per
  toast; `icon: false` hides it:

      <.toaster id="toaster" icons={%{success: "hero-sparkles", loading: "hero-arrow-path animate-spin"}} />

      SaladUI.Toast.toast_info(socket, "Heads up", icon: "hero-bell")

  `unstyled: true` drops every built-in class, leaving bare `data-part`
  elements for `class` to style from scratch:

      SaladUI.Toast.toast(socket, "Bare toast", unstyled: true, class: "my-toast")

  `action`/`cancel` accept an optional `value` map, merged into the event
  payload pushed back to the LiveView (alongside `id`):

      SaladUI.Toast.toast(socket, "File deleted",
        action: %{label: "Undo", event: "undo_delete", value: %{file_id: file.id}},
        cancel: %{label: "Dismiss"}
      )

      def handle_event("undo_delete", %{"id" => _id, "file_id" => file_id}, socket) do
        # restore file_id
        {:noreply, socket}
      end

  ## Phoenix flash integration

  Pass `flash` to render flash messages as toasts instead of a second
  notification system:

      <.toaster id="toaster" flash={@flash} />

  ## Accessibility

  As in Sonner, the toaster is a `<section>` landmark named "Notifications"
  plus the hotkey (`aria-label="Notifications Alt+T"`) and is the polite live
  region that announces new toasts; its lists and cards carry no role.
  `important: true` on a toast makes that card an assertive live region.
  The hotkey (default `Alt+T`, Option+T on a Mac) moves focus to the front
  toast; it is matched on the physical key (`KeyboardEvent.code`).

  ## Modals

  Toasts stay clickable and announced while a modal dialog, sheet, drawer or
  dropdown menu blocks the rest of the page: the viewport is marked
  `data-salad-layer-branch`, which the modal layer always leaves interactive.
  """
  use SaladUI, :component

  @doc """
  Mounts the toast stack. Render exactly once per page (typically the root layout).

  ## Server commands

  * `"add"` - Creates and mounts a new toast card, arms its timer.
  * `"update"` - Patches an existing card in place, keyed by `id`.
  * `"dismiss"` - Plays the exit animation and removes a card (or every card if `id` is omitted).

  ## Component events

  * `:on-dismiss` - Fired whenever a toast is removed, with `%{id:, reason:}` in the payload.

  ## Right-to-left

  Positions are physical, as in Sonner: `bottom-right` stays bottom-right on
  an RTL page, and its toasts swipe away down or to the right. To dismiss
  towards the end of the line whatever the direction, set
  `swipe-direction="end"` (left under RTL). The close button sits on the
  card's inline-end corner.
  """
  attr :id, :string, default: "toaster"

  attr :position, :string,
    values: ~w(top-left top-center top-right bottom-left bottom-center bottom-right),
    default: "bottom-right"

  attr :expand, :boolean, default: false, doc: "Stack fully expanded instead of collapsed"
  attr :"visible-toasts", :integer, default: 3, doc: "Max stacked cards before overflow is collapsed"
  attr :gap, :integer, default: 14, doc: "px gap between stacked toasts when expanded"

  attr :"swipe-direction", :string,
    values: ~w(up down left right start end) ++ [nil],
    default: nil,
    doc:
      "Only direction a swipe dismisses in. Defaults to the position's edges (bottom-right: down or right). " <>
        "`start`/`end` are logical: `end` is right in LTR and left in RTL"

  attr :width, :integer, default: 356, doc: "Fixed card width in px"
  attr :offset, :any, default: 24, doc: "px gap from the viewport edge, or a %{top:, right:, bottom:, left:} map"
  attr :"mobile-offset", :any, default: 16, doc: "Same as :offset, applied below the 600px breakpoint"

  attr :hotkey, :string,
    default: "Alt+T",
    doc:
      "Keyboard shortcut that moves focus into the front toast: modifiers (Alt, Shift, Ctrl, Meta) and a key, " <>
        "matched on the physical key so Option+T works on macOS. `nil` turns it off"

  attr :duration, :any,
    default: nil,
    doc: "Default time in ms before a toast closes (Sonner's 4000 when nil), or `:infinity`"

  attr :"close-button", :boolean,
    default: false,
    doc: "Show a close button on every toast (Sonner's `closeButton`); a toast's `close_button:` overrides it"

  attr :icons, :map,
    default: %{},
    doc:
      ~S(toaster-wide icon class overrides by variant, e.g. %{success: "hero-sparkles"}. ) <>
        "Without one, success/info/warning/error/loading show shadcn's lucide icons at size-4."

  attr :colors, :map,
    default: %{},
    doc:
      ~S(per-variant toast color override, e.g. %{success: "border-emerald-500/30 bg-emerald-50 text-emerald-900"} ) <>
        "— replaces the card's default border/background/text (icon + title inherit the text color; " <>
        "description keeps its own muted color) for that variant. No variant ships with a predefined color."

  attr :class, :any,
    default: nil,
    doc:
      "extra classes merged onto every card — use `!`-prefixed utilities, e.g. " <>
        ~S("!bg-secondary", to reliably override a default color class)

  attr :flash, :map, default: nil, doc: "when given, also renders the flash-to-toast bridge (see toast_flash/1)"

  attr :"on-dismiss", :any,
    default: nil,
    doc: "Handler fired when any toast is removed. Payload includes `id` and `reason`."

  attr :label, :string,
    default: "Notifications",
    doc: "the landmark's name (Sonner's `containerAriaLabel`); the hotkey is appended, as in Sonner"

  attr :rest, :global

  slot :template, doc: "named rich-content template, referenced from `toast(socket, template: name)`" do
    attr :name, :string, required: true
  end

  def toaster(assigns) do
    event_map = event_mappings(assigns)
    offset = normalize_offset(assigns.offset)
    mobile_offset = normalize_offset(assigns[:"mobile-offset"])

    options = %{
      position: assigns.position,
      expand: assigns.expand,
      visibleToasts: assigns[:"visible-toasts"],
      gap: assigns.gap,
      swipeDirection: assigns[:"swipe-direction"],
      icons: assigns.icons,
      colors: assigns.colors,
      class: assigns.class,
      hotkey: assigns.hotkey,
      duration: if(assigns.duration == :infinity, do: "infinity", else: assigns.duration),
      closeButton: assigns[:"close-button"]
    }

    assigns =
      assigns
      |> assign(:event_map, json(event_map))
      |> assign(:options, json(options))
      |> assign(:viewport_class, viewport_class(assigns.position))
      |> assign(:viewport_style, viewport_style(assigns.width, offset, mobile_offset, assigns.gap))
      |> assign(:label, String.trim("#{assigns.label} #{assigns.hotkey}"))

    ~H"""
    <section
      id={@id}
      data-component="toast"
      data-options={@options}
      data-event-mappings={@event_map}
      phx-hook="SaladUI"
      phx-update="ignore"
      data-part="root"
      aria-label={@label}
      tabindex="-1"
      aria-live="polite"
      aria-relevant="additions text"
      aria-atomic="false"
      {@rest}
    >
      <ol
        data-part="viewport"
        data-salad-layer-branch
        data-position={@position}
        style={@viewport_style}
        class={@viewport_class}
      >
      </ol>

      <template :for={tpl <- @template} data-part="toast-template" data-name={tpl.name}>{render_slot(
        tpl
      )}</template>
    </section>

    <.toast_flash
      :if={@flash}
      id={"#{@id}-flash-bridge"}
      flash={@flash}
      toaster={@id}
    />
    """
  end

  @doc """
  Bridges `@flash` into toasts on the given `toaster` without patching the
  toaster's own DOM subtree (which would tear down its live stack/timers).

  Usually rendered implicitly via `toaster/1`'s `:flash` attribute; call it
  directly when the toaster and the LiveView holding `@flash` are mounted
  separately.
  """
  attr :id, :string, default: "toast-flash-bridge"
  attr :flash, :map, required: true
  attr :toaster, :string, default: "toaster"

  def toast_flash(assigns) do
    entries =
      for {kind, msg} <- assigns.flash,
          msg not in [nil, ""],
          do: %{kind: to_string(kind), message: flash_message_to_string(msg)}

    assigns = assign(assigns, :entries, json(entries))

    ~H"""
    <div
      id={@id}
      data-component="toast-flash"
      data-toaster={@toaster}
      data-entries={@entries}
      phx-hook="SaladUI"
      data-part="root"
      hidden
    >
    </div>
    """
  end

  @doc """
  Push a toast to a mounted `<.toaster>` (see `toaster/1`).

  `message` is either a string, used as the toast's `title`, or (for
  template-based toasts, see `toaster/1`'s `:template` slot) a keyword
  list/map of opts with no title:

      socket = SaladUI.Toast.toast(socket, "Saved!")
      socket = SaladUI.Toast.toast(socket, "Saved!", description: "Changes are live")
      socket = SaladUI.Toast.toast(socket, template: "new-follower", variant: "default")

  Pass `toaster: id` (or call `toast/4` directly) to target a `<.toaster>`
  other than the default `"toaster"` id. See the moduledoc for the full opts list.
  """
  def toast(socket, message, opts \\ [])

  def toast(socket, message, opts) when is_binary(message) or is_nil(message) do
    {toaster_id, opts} = pop_toaster(opts)
    toast(socket, toaster_id, message, opts)
  end

  # Template-based toast: `message_opts` carries the opts. Merge in `opts` so
  # the variant helpers (`toast_loading(socket, template: "upload")`) keep
  # their variant instead of silently falling back to "default".
  def toast(socket, message_opts, opts) do
    {toaster_id, message_opts} = message_opts |> Map.new() |> Map.merge(Map.new(opts)) |> pop_toaster()
    toast(socket, toaster_id, nil, message_opts)
  end

  def toast(socket, toaster_id, message, opts) do
    params =
      opts
      |> build_toast_params(message)
      |> Map.put_new(:id, generate_toast_id())
      |> Map.put_new(:variant, "default")

    SaladUI.LiveView.send_command(socket, toaster_id, "add", params)
  end

  @doc """
  Drop-in-shaped alongside `Phoenix.LiveView.put_flash/3` /
  `Phoenix.Controller.put_flash/3` — same arity, same call sites, works on both.

  On a `%Socket{}` this behaves like `toast/3` with `variant: kind`. On a
  `%Plug.Conn{}` (no toaster hook exists to push a command to — the page
  hasn't rendered yet) it falls back to `Phoenix.Controller.put_flash/3`, so a
  controller action followed by a redirect still shows *something* instead of
  silently dropping the message; once the LiveView the redirect lands on
  renders `<.toaster flash={@flash} />`, the flash bridge (`toast_flash/1`)
  picks it up and converts it to a real toast on connect.
  """
  def put_toast(conn_or_socket, kind, message, opts \\ [])

  def put_toast(%Plug.Conn{} = conn, kind, message, _opts) do
    Phoenix.Controller.put_flash(conn, kind, message)
  end

  def put_toast(%Phoenix.LiveView.Socket{} = socket, kind, message, opts) do
    toast(socket, message, Keyword.put(opts, :variant, to_string(kind)))
  end

  @doc "Same as `toast/3`, with `variant: \"success\"`."
  def toast_success(socket, message, opts \\ []), do: toast(socket, message, Keyword.put(opts, :variant, "success"))

  @doc "Same as `toast/3`, with `variant: \"error\"`."
  def toast_error(socket, message, opts \\ []), do: toast(socket, message, Keyword.put(opts, :variant, "error"))

  @doc "Same as `toast/3`, with `variant: \"warning\"`."
  def toast_warning(socket, message, opts \\ []), do: toast(socket, message, Keyword.put(opts, :variant, "warning"))

  @doc "Same as `toast/3`, with `variant: \"info\"`."
  def toast_info(socket, message, opts \\ []), do: toast(socket, message, Keyword.put(opts, :variant, "info"))

  @doc """
  Same as `toast/3`, with `variant: "loading"`: a spinning loader icon, and
  no timeout — the toast stays up (and can't be swiped away) until
  `toast_update/3`/`toast_resolve/4` turns it into another variant or
  `toast_dismiss/3` removes it.
  """
  def toast_loading(socket, message, opts \\ []), do: toast(socket, message, Keyword.put(opts, :variant, "loading"))

  @doc """
  Starts a Sonner-style promise toast: shows a loading toast under a known id,
  to be resolved in place later by `toast_resolve/4` or `toast_update/3`
  (typically from `handle_async/3`).

  The second argument is the toast id, or an opts list. `:loading` (the
  loading message) is required; every other `toast/3` opt (`description:`,
  `position:`, `toaster:`, ...) is passed through.

      socket
      |> toast_promise("export", loading: "Exporting...")
      |> start_async(:export, fn -> Reports.export() end)

  With an opts list and no `:id`, an id is generated and assigned to the
  socket as `:toast_id`, so the result handler can find it:

      socket = toast_promise(socket, loading: "Exporting...")
      socket.assigns.toast_id #=> "toast-42"
  """
  def toast_promise(socket, id_or_opts, opts \\ [])

  def toast_promise(socket, id, opts) when is_binary(id) do
    {loading, opts} = Keyword.pop(opts, :loading)

    if !is_binary(loading) do
      raise ArgumentError, "toast_promise/3 requires a :loading message, got: #{inspect(loading)}"
    end

    toast_loading(socket, loading, Keyword.put(opts, :id, id))
  end

  def toast_promise(socket, opts, more_opts) when is_list(opts) do
    opts = Keyword.merge(opts, more_opts)

    case Keyword.pop(opts, :id) do
      {nil, opts} ->
        id = generate_toast_id()

        socket
        |> toast_promise(id, opts)
        |> Phoenix.Component.assign(:toast_id, id)

      {id, opts} ->
        toast_promise(socket, id, opts)
    end
  end

  @doc """
  Resolves a promise toast (see `toast_promise/3`) from an async result, in
  place: the same card morphs from loading to success or error.

  `result` is what `handle_async/3` receives. `{:ok, value}` (or
  `{:ok, {:ok, value}}`) resolves to success; `{:exit, reason}`,
  `{:ok, {:error, reason}}` and `{:ok, :error}` resolve to error.

  `:success` and `:error` are each a message string, or a 1-arity function of
  the value/reason returning a message string or a keyword list of
  `toast_update/3` opts (e.g. `[message: "Saved", description: "..."]`). When
  the matching one is omitted, the toast is dismissed instead, as in Sonner.
  Any other opts (`description:`, `duration:`, `toaster:`, ...) are passed to
  `toast_update/3`.

      def handle_async(:export, result, socket) do
        {:noreply,
         toast_resolve(socket, "export", result,
           success: fn report -> "\#{report.name} is ready" end,
           error: fn reason -> "Export failed: \#{inspect(reason)}" end
         )}
      end
  """
  def toast_resolve(socket, id, result, opts \\ []) do
    {success, opts} = Keyword.pop(opts, :success)
    {error, opts} = Keyword.pop(opts, :error)

    case result do
      {:ok, {:error, reason}} -> settle(socket, id, "error", error, reason, opts)
      {:ok, :error} -> settle(socket, id, "error", error, :error, opts)
      {:exit, reason} -> settle(socket, id, "error", error, reason, opts)
      {:ok, {:ok, value}} -> settle(socket, id, "success", success, value, opts)
      {:ok, value} -> settle(socket, id, "success", success, value, opts)
    end
  end

  defp settle(socket, id, _variant, nil, _arg, opts) do
    {toaster_id, _opts} = pop_toaster(opts)
    toast_dismiss(socket, toaster_id, id)
  end

  defp settle(socket, id, variant, message, arg, opts) when is_function(message, 1) do
    settle(socket, id, variant, message.(arg), arg, opts)
  end

  defp settle(socket, id, variant, message, _arg, opts) when is_binary(message) do
    toast_update(socket, id, Keyword.merge(opts, variant: variant, message: message))
  end

  defp settle(socket, id, variant, message_opts, _arg, opts) when is_list(message_opts) do
    toast_update(socket, id, opts |> Keyword.merge(message_opts) |> Keyword.put(:variant, variant))
  end

  @doc """
  Patches an existing toast (by `id`) in place: the same card animates to the
  new variant/content instead of a second toast appearing. This is how a
  loading toast resolves (see `toast_promise/3`).

      toast_update(socket, "export", variant: "success", message: "Export ready")
      toast_update(socket, "export", variant: "error", message: "Export failed", description: "Try again")

  `:message` (or `:title`) sets the title. Keys left out keep their current
  value, except that changing the variant resets the duration to the default
  unless `:duration` is given — so a resolved loading toast times out
  normally. Without `:variant` the toast keeps its current one. Pass
  `toaster: id` to target a `<.toaster>` other than `"toaster"`.
  """
  def toast_update(socket, id, opts) do
    {toaster_id, opts} = pop_toaster(opts)
    {message, opts} = Keyword.pop(opts, :message)

    params =
      opts
      |> build_toast_params(message)
      |> Map.put(:id, id)

    SaladUI.LiveView.send_command(socket, toaster_id, "update", params)
  end

  @doc "Removes one toast, or every toast on the given toaster if `id` is omitted."
  def toast_dismiss(socket, toaster_id \\ "toaster", id \\ nil) do
    params = if id, do: %{id: id}, else: %{}
    SaladUI.LiveView.send_command(socket, toaster_id, "dismiss", params)
  end

  defp pop_toaster(%{} = opts) do
    {Map.get(opts, :toaster, "toaster"), Map.delete(opts, :toaster)}
  end

  defp pop_toaster(opts) when is_list(opts), do: Keyword.pop(opts, :toaster, "toaster")

  defp build_toast_params(opts, message) do
    opts
    |> Map.new()
    |> stringify(:variant)
    |> Map.update(:duration, nil, fn
      :infinity -> "infinity"
      other -> other
    end)
    |> drop_if_nil(:duration)
    |> maybe_put_title(message)
  end

  defp stringify(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when not is_nil(value) -> Map.put(map, key, to_string(value))
      _ -> Map.delete(map, key)
    end
  end

  defp drop_if_nil(map, key) do
    if Map.get(map, key) == nil, do: Map.delete(map, key), else: map
  end

  # Flash messages are commonly iodata or a Phoenix.HTML.Safe `{:safe, iodata}`
  # tuple (e.g. built with `~H`/`content_tag`), neither of which `json/1`'s
  # encoder can serialize directly. The JS bridge only ever renders this via
  # `textContent`, so flattening to a plain string here is lossless for the
  # toast's purposes.
  defp flash_message_to_string(msg) when is_binary(msg), do: msg
  defp flash_message_to_string({:safe, _} = safe), do: Phoenix.HTML.safe_to_string(safe)
  defp flash_message_to_string(msg), do: IO.iodata_to_binary(msg)

  defp maybe_put_title(params, nil), do: params
  defp maybe_put_title(params, message), do: Map.put_new(params, :title, message)

  defp generate_toast_id do
    "toast-" <> Integer.to_string(System.unique_integer([:positive, :monotonic]))
  end

  defp normalize_offset(value) when is_integer(value) or is_binary(value) do
    %{top: value, right: value, bottom: value, left: value}
  end

  defp normalize_offset(%{} = value) do
    %{
      top: Map.get(value, :top) || Map.get(value, "top") || 0,
      right: Map.get(value, :right) || Map.get(value, "right") || 0,
      bottom: Map.get(value, :bottom) || Map.get(value, "bottom") || 0,
      left: Map.get(value, :left) || Map.get(value, "left") || 0
    }
  end

  defp viewport_style(width, offset, mobile_offset, gap) do
    style([
      %{
        "--toast-width": px(width),
        "--toast-gap": px(gap),
        "--offset-t": px(offset.top),
        "--offset-r": px(offset.right),
        "--offset-b": px(offset.bottom),
        "--offset-l": px(offset.left),
        "--mobile-offset-t": px(mobile_offset.top),
        "--mobile-offset-r": px(mobile_offset.right),
        "--mobile-offset-b": px(mobile_offset.bottom),
        "--mobile-offset-l": px(mobile_offset.left),
        gap: px(gap)
      }
    ])
  end

  defp px(value) when is_binary(value), do: value
  defp px(value), do: "#{value}px"

  defp viewport_class(position) do
    classes([
      "group/toast-viewport fixed z-[9999] flex flex-col outline-hidden",
      "w-[var(--toast-width)] max-[600px]:w-[calc(100%-var(--mobile-offset-l)-var(--mobile-offset-r))]",
      vertical_class(position),
      horizontal_class(position)
    ])
  end

  defp vertical_class("top-" <> _) do
    "flex-col-reverse top-[var(--offset-t)] max-[600px]:top-[var(--mobile-offset-t)]"
  end

  defp vertical_class(_bottom_position) do
    "bottom-[var(--offset-b)] max-[600px]:bottom-[var(--mobile-offset-b)]"
  end

  defp horizontal_class(position) do
    cond do
      String.ends_with?(position, "left") ->
        "left-[var(--offset-l)] items-start rtl:items-end max-[600px]:left-[var(--mobile-offset-l)]"

      String.ends_with?(position, "right") ->
        "right-[var(--offset-r)] items-end rtl:items-start max-[600px]:right-[var(--mobile-offset-r)]"

      true ->
        "left-1/2 -translate-x-1/2 items-center"
    end
  end
end
