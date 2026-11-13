defmodule SaladChatWeb.BenchLive do
  @moduledoc """
  Benchmark: what do SaladUI hooks per message row cost?

  `/bench?variant=V&n=N` renders N message rows (from a stream) in one of:

    * `hooks`     - a realistic row: a context_menu around it, a hover_card on
                    the author, 2 tooltips and a dropdown_menu in the hover
                    toolbar (5 `phx-hook="SaladUI"` instances per row, each
                    menu's content rendered per row, as in MessageComponents).
    * `inert`     - the same markup, but the client registers a no-op
                    `SaladUI` hook (isolates SaladUI's JS from the DOM size).
    * `plain`     - the same visual row with plain buttons: no hooks, no
                    per-row menu / tooltip / hover-card markup.
    * `delegated` - `plain` plus `data-tooltip` / `data-menu` attributes and
                    ONE page-level tooltip + menu driven by document event
                    delegation (a prototype of the proposed redesign).

  Three ways to keep menu markup out of the rows. Rows carry only the
  triggers; tooltips use the page-level `data-tooltip` delegation in all
  three, so only the menu strategy differs:

    * `shared`    - (A) ONE real SaladUI dropdown_menu and context_menu on the
                    page, outside the stream, opened at the clicked row.
    * `template`  - (B) one `<template>` per menu; on open the client clones
                    it into a portal, substitutes the row id and instantiates
                    the SaladUI component on it; on close it is destroyed.
    * `server`    - (C) click -> pushEvent; the server stream_inserts the row
                    with its menu rendered, then the client opens it.

  The client side lives in assets/js/bench.js; `&auto=1` runs a plan stored
  in localStorage and collects the numbers there.
  """
  use SaladChatWeb, :live_view

  @variants ~w(hooks inert plain delegated shared template server)
  @emoji ~w(👍 👎 ✅ 🎉 😂 😍 🙏 🔥)
  @users [
    %{name: "Ada Lovelace", initials: "AL", color: "bg-rose-500"},
    %{name: "Grace Hopper", initials: "GH", color: "bg-sky-500"},
    %{name: "Alan Turing", initials: "AT", color: "bg-amber-500"},
    %{name: "Barbara Liskov", initials: "BL", color: "bg-violet-500"},
    %{name: "Edsger Dijkstra", initials: "ED", color: "bg-emerald-500"},
    %{name: "Katherine Johnson", initials: "KJ", color: "bg-fuchsia-500"}
  ]
  @bodies [
    "Pushed the fix for the flaky upload test, can someone take a look?",
    "Lunch at noon? The new ramen place opened on 3rd street.",
    "I think we should move the retro to Thursday, half the team is out tomorrow.",
    "Deploy is green. Watching the dashboards for the next half hour just in case.",
    "Does anyone remember why we pinned that dependency? The changelog mentions a breaking change in the parser but I can't find the issue.",
    "👍",
    "Sounds good to me."
  ]

  @impl true
  def mount(params, _session, socket) do
    variant = if params["variant"] in @variants, do: params["variant"], else: "hooks"
    n = params |> Map.get("n", "500") |> String.to_integer() |> min(5000)
    # Like ChatLive, rows only come with the connected mount: the dead render
    # of a hooked row is ~48 KB of HTML, which at N=500+ stalls the page for
    # seconds before the LiveView even connects.
    rows = if connected?(socket), do: Enum.map(1..n//1, &row/1), else: []

    {:ok,
     socket
     |> assign(variant: variant, n: n, oldest: 0, open_menu: nil, modal: params["modal"] != "0")
     |> assign(page_title: "Bench #{variant} #{n}")
     |> stream(:rows, rows)}
  end

  defp row(i, rev \\ 0) do
    u = Enum.at(@users, rem(i, length(@users)))
    body = Enum.at(@bodies, rem(i, length(@bodies)))
    body = if rev > 0, do: "#{body} (edited #{rev})", else: body
    minute = rem(i, 60) |> Integer.to_string() |> String.pad_leading(2, "0")

    %{id: i, user: u, body: body, time: "10:#{minute} AM", rev: rev}
  end

  @impl true
  # 50 older rows above the current oldest, as when the reader scrolls up.
  def handle_event("prepend", _params, socket) do
    oldest = socket.assigns.oldest
    rows = Enum.map((oldest - 50)..(oldest - 1)//1, &row/1)

    {:reply, %{count: 50},
     socket |> assign(oldest: oldest - 50) |> stream(:rows, Enum.reverse(rows), at: 0)}
  end

  # One row's content changes (an edit, a reaction...).
  def handle_event("update_one", %{"id" => id, "rev" => rev}, socket) do
    {:reply, %{id: id}, stream_insert(socket, :rows, row(id, rev))}
  end

  def handle_event("menu_action", _params, socket), do: {:noreply, socket}

  # C: render the row's menu, then the client opens it.
  def handle_event("open_menu", %{"id" => id, "kind" => kind}, socket)
      when kind in ~w(dropdown context) do
    socket =
      case socket.assigns.open_menu do
        {old, _} when old != id -> stream_insert(socket, :rows, row(old))
        _ -> socket
      end

    {:reply, %{},
     socket
     |> assign(open_menu: {id, String.to_existing_atom(kind)})
     |> stream_insert(:rows, row(id))}
  end

  def handle_event("close_menu", %{"id" => id}, socket) do
    case socket.assigns.open_menu do
      {^id, _} ->
        {:noreply, socket |> assign(open_menu: nil) |> stream_insert(:rows, row(id))}

      _ ->
        {:noreply, socket}
    end
  end

  # Correctness checks: the row goes away, or the stream is reset, while its
  # menu is open.
  def handle_event("delete_row", %{"id" => id}, socket) do
    {:reply, %{}, stream_delete_by_dom_id(socket, :rows, "rows-#{id}")}
  end

  def handle_event("reset_rows", _params, socket) do
    rows = Enum.map(1..socket.assigns.n//1, &row/1)
    {:reply, %{}, socket |> assign(oldest: 0) |> stream(:rows, rows, reset: true)}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :emoji, @emoji)

    ~H"""
    <div class="flex h-full flex-col">
      <header class="flex items-center gap-3 border-b px-4 py-2 text-sm">
        <strong>Bench</strong>
        <span>variant={@variant}</span>
        <span>n={@n}</span>
        <span id="bench-status" class="text-muted-foreground"></span>
      </header>
      <div id="bench-scroll" class="min-h-0 flex-1 overflow-y-auto">
        <div id="bench-rows" phx-update="stream" class="flex flex-col pb-4">
          <%= for {dom_id, row} <- @streams.rows do %>
            <.hooked_row :if={@variant in ~w(hooks inert)} id={dom_id} row={row} emoji={@emoji} />
            <.plain_row
              :if={@variant in ~w(plain delegated)}
              id={dom_id}
              row={row}
              delegated={@variant == "delegated"}
            />
            <.menu_row
              :if={@variant in ~w(shared template server)}
              id={dom_id}
              row={row}
              emoji={@emoji}
              open={open_kind(@open_menu, row.id)}
            />
          <% end %>
        </div>
      </div>
      <div id="bench-done" phx-hook="BenchDone" data-variant={@variant} data-n={@n}></div>
      <div id="bench-portal" phx-update="ignore"></div>
      <.shared_popups :if={@variant == "delegated"} emoji={@emoji} />
      <.menu_strategies
        :if={@variant in ~w(shared template server)}
        variant={@variant}
        emoji={@emoji}
        modal={@modal}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :row, :map, required: true
  attr :emoji, :list, required: true

  defp hooked_row(assigns) do
    ~H"""
    <div id={@id} class="relative" data-row={@row.id}>
      <.context_menu id={"#{@id}-context"} use-portal portal-container="#bench-portal">
        <.context_menu_trigger
          as="div"
          class="group/msg relative block px-4 pt-2 pb-0.5 transition-colors hover:bg-muted/50 has-[[data-state=open]]:bg-muted/50 data-[state=open]:bg-muted/50"
        >
          <div class="flex gap-3">
            <.avatar class="size-9 rounded-lg">
              <.avatar_fallback class={"#{@row.user.color} font-medium text-white"}>
                {@row.user.initials}
              </.avatar_fallback>
            </.avatar>
            <div class="flex min-w-0 flex-col gap-1">
              <div class="flex items-center gap-2 text-sm">
                <.hover_card id={"#{@id}-author"} open-delay={400}>
                  <.hover_card_trigger>
                    <button type="button" class="font-semibold text-foreground hover:underline">
                      {@row.user.name}
                    </button>
                  </.hover_card_trigger>
                  <.hover_card_content side="top" align="start" class="w-auto">
                    <.profile user={@row.user} />
                  </.hover_card_content>
                </.hover_card>
                <time class="text-xs text-muted-foreground">{@row.time}</time>
              </div>
              <p class="text-sm">{@row.body}</p>
            </div>
          </div>
          <div class={toolbar_class()}>
            <.button_group aria-label="Message actions">
              <.button
                :for={e <- Enum.take(@emoji, 3)}
                variant="ghost"
                size="icon-sm"
                aria-label={"React with #{e}"}
              >
                {e}
              </.button>
              <.tooltip id={"#{@id}-react-tip"}>
                <.tooltip_trigger
                  as={&button/1}
                  variant="ghost"
                  size="icon-sm"
                  aria-label="Add reaction"
                >
                  <.icon name="hero-face-smile" />
                </.tooltip_trigger>
                <.tooltip_content>Add reaction</.tooltip_content>
              </.tooltip>
              <.tooltip id={"#{@id}-reply-tip"}>
                <.tooltip_trigger
                  as={&button/1}
                  variant="ghost"
                  size="icon-sm"
                  aria-label="Reply in thread"
                >
                  <.icon name="hero-chat-bubble-left-ellipsis" />
                </.tooltip_trigger>
                <.tooltip_content>Reply in thread</.tooltip_content>
              </.tooltip>
              <.dropdown_menu id={"#{@id}-more"} use-portal portal-container="#bench-portal">
                <.dropdown_menu_trigger
                  as={&button/1}
                  variant="ghost"
                  size="icon-sm"
                  aria-label="More actions"
                >
                  <.icon name="hero-ellipsis-vertical" />
                </.dropdown_menu_trigger>
                <.dropdown_menu_content align="end" class="w-56">
                  <.dropdown_menu_sub>
                    <.dropdown_menu_sub_trigger>
                      <.icon name="hero-face-smile" /> React
                    </.dropdown_menu_sub_trigger>
                    <.dropdown_menu_sub_content class="grid w-auto min-w-0 grid-cols-4 p-1">
                      <.dropdown_menu_item
                        :for={e <- @emoji}
                        on-select={JS.push("menu_action", value: %{id: @row.id, emoji: e})}
                        class="justify-center text-lg"
                      >
                        {e}
                      </.dropdown_menu_item>
                    </.dropdown_menu_sub_content>
                  </.dropdown_menu_sub>
                  <%= for {icon, label} <- actions() do %>
                    <.dropdown_menu_item on-select={
                      JS.push("menu_action", value: %{id: @row.id, action: label})
                    }>
                      <.icon name={icon} /> {label}
                    </.dropdown_menu_item>
                  <% end %>
                </.dropdown_menu_content>
              </.dropdown_menu>
            </.button_group>
          </div>
        </.context_menu_trigger>
        <.context_menu_content class="w-56">
          <.context_menu_sub>
            <.context_menu_sub_trigger>
              <.icon name="hero-face-smile" /> React
            </.context_menu_sub_trigger>
            <.context_menu_sub_content class="grid w-auto min-w-0 grid-cols-4 p-1">
              <.context_menu_item
                :for={e <- @emoji}
                on-select={JS.push("menu_action", value: %{id: @row.id, emoji: e})}
                class="justify-center text-lg"
              >
                {e}
              </.context_menu_item>
            </.context_menu_sub_content>
          </.context_menu_sub>
          <%= for {icon, label} <- actions() do %>
            <.context_menu_item on-select={
              JS.push("menu_action", value: %{id: @row.id, action: label})
            }>
              <.icon name={icon} /> {label}
            </.context_menu_item>
          <% end %>
        </.context_menu_content>
      </.context_menu>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :row, :map, required: true
  attr :delegated, :boolean, default: false

  defp plain_row(assigns) do
    ~H"""
    <div id={@id} class="relative" data-row={@row.id} data-menu-row={@delegated && @row.id}>
      <div class="group/msg relative block px-4 pt-2 pb-0.5 transition-colors hover:bg-muted/50">
        <div class="flex gap-3">
          <.avatar class="size-9 rounded-lg">
            <.avatar_fallback class={"#{@row.user.color} font-medium text-white"}>
              {@row.user.initials}
            </.avatar_fallback>
          </.avatar>
          <div class="flex min-w-0 flex-col gap-1">
            <div class="flex items-center gap-2 text-sm">
              <button
                type="button"
                class="font-semibold text-foreground hover:underline"
                data-tooltip={@delegated && "#{@row.user.name} · Online"}
              >
                {@row.user.name}
              </button>
              <time class="text-xs text-muted-foreground">{@row.time}</time>
            </div>
            <p class="text-sm">{@row.body}</p>
          </div>
        </div>
        <div class={toolbar_class()}>
          <.button_group aria-label="Message actions">
            <.button
              :for={e <- ~w(👍 👎 ✅)}
              variant="ghost"
              size="icon-sm"
              aria-label={"React with #{e}"}
            >
              {e}
            </.button>
            <.button
              variant="ghost"
              size="icon-sm"
              aria-label="Add reaction"
              data-tooltip={@delegated && "Add reaction"}
            >
              <.icon name="hero-face-smile" />
            </.button>
            <.button
              variant="ghost"
              size="icon-sm"
              aria-label="Reply in thread"
              data-tooltip={@delegated && "Reply in thread"}
            >
              <.icon name="hero-chat-bubble-left-ellipsis" />
            </.button>
            <.button
              variant="ghost"
              size="icon-sm"
              aria-label="More actions"
              data-menu={@delegated && @row.id}
            >
              <.icon name="hero-ellipsis-vertical" />
            </.button>
          </.button_group>
        </div>
      </div>
    </div>
    """
  end

  defp open_kind({id, kind}, id), do: kind
  defp open_kind(_, _), do: nil

  attr :id, :string, required: true
  attr :row, :map, required: true
  attr :emoji, :list, required: true

  attr :open, :atom,
    default: nil,
    doc: "C only: the menu the server rendered (:dropdown, :context)"

  # A, B and C: the row carries only the triggers.
  defp menu_row(assigns) do
    ~H"""
    <div id={@id} class="relative" data-row={@row.id} data-menu-row={@row.id}>
      <%= if @open == :context do %>
        <.context_menu
          id={"#{@id}-context"}
          use-portal
          portal-container="#bench-portal"
          on-close={JS.push("close_menu", value: %{id: @row.id})}
        >
          <.context_menu_trigger as="div" class="block">
            <.menu_row_body id={@id} row={@row} open={@open} emoji={@emoji} />
          </.context_menu_trigger>
          <.context_menu_content class="w-56">
            <.context_items emoji={@emoji} cmd={&server_cmd(@row.id, &1)} />
          </.context_menu_content>
        </.context_menu>
      <% else %>
        <.menu_row_body id={@id} row={@row} open={@open} emoji={@emoji} />
      <% end %>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :row, :map, required: true
  attr :emoji, :list, required: true
  attr :open, :atom, default: nil

  defp menu_row_body(assigns) do
    ~H"""
    <div class="group/msg relative block px-4 pt-2 pb-0.5 transition-colors hover:bg-muted/50 has-[[data-state=open]]:bg-muted/50">
      <div class="flex gap-3">
        <.avatar class="size-9 rounded-lg">
          <.avatar_fallback class={"#{@row.user.color} font-medium text-white"}>
            {@row.user.initials}
          </.avatar_fallback>
        </.avatar>
        <div class="flex min-w-0 flex-col gap-1">
          <div class="flex items-center gap-2 text-sm">
            <button
              type="button"
              class="font-semibold text-foreground hover:underline"
              data-tooltip={"#{@row.user.name} · Online"}
            >
              {@row.user.name}
            </button>
            <time class="text-xs text-muted-foreground">{@row.time}</time>
          </div>
          <p class="text-sm">{@row.body}</p>
        </div>
      </div>
      <div class={toolbar_class()}>
        <.button_group aria-label="Message actions">
          <.button
            :for={e <- ~w(👍 👎 ✅)}
            variant="ghost"
            size="icon-sm"
            aria-label={"React with #{e}"}
          >
            {e}
          </.button>
          <.button
            variant="ghost"
            size="icon-sm"
            aria-label="Add reaction"
            data-tooltip="Add reaction"
          >
            <.icon name="hero-face-smile" />
          </.button>
          <.button
            variant="ghost"
            size="icon-sm"
            aria-label="Reply in thread"
            data-tooltip="Reply in thread"
          >
            <.icon name="hero-chat-bubble-left-ellipsis" />
          </.button>
          <%= if @open == :dropdown do %>
            <.dropdown_menu
              id={"#{@id}-more"}
              use-portal
              portal-container="#bench-portal"
              on-close={JS.push("close_menu", value: %{id: @row.id})}
            >
              <.dropdown_menu_trigger
                as={&button/1}
                variant="ghost"
                size="icon-sm"
                aria-label="More actions"
              >
                <.icon name="hero-ellipsis-vertical" />
              </.dropdown_menu_trigger>
              <.dropdown_menu_content align="end" class="w-56">
                <.dropdown_items emoji={@emoji} cmd={&server_cmd(@row.id, &1)} />
              </.dropdown_menu_content>
            </.dropdown_menu>
          <% else %>
            <.button
              variant="ghost"
              size="icon-sm"
              aria-label="More actions"
              aria-haspopup="menu"
              data-menu-open={@row.id}
            >
              <.icon name="hero-ellipsis-vertical" />
            </.button>
          <% end %>
        </.button_group>
      </div>
    </div>
    """
  end

  attr :variant, :string, required: true
  attr :modal, :boolean, default: true, doc: "`&modal=0`: open A without the modal layer"
  attr :emoji, :list, required: true

  # A: the one shared dropdown/context menu. B: their templates. Each menu's
  # own trigger is a hidden proxy that the client moves over the clicked row
  # button (the components anchor to their trigger).
  defp menu_strategies(assigns) do
    ~H"""
    <div id="bench-menus" phx-hook="BenchMenus" data-variant={@variant}>
      <%= if @variant == "shared" do %>
        <.dropdown_menu id="shared-more" use-portal portal-container="#bench-portal" modal={@modal}>
          <.dropdown_menu_trigger class={proxy_class()} tabindex="-1" aria-label="More actions">
            <span class="sr-only">More actions</span>
          </.dropdown_menu_trigger>
          <.dropdown_menu_content align="end" class="w-56">
            <.dropdown_items emoji={@emoji} cmd={&shared_cmd/1} />
          </.dropdown_menu_content>
        </.dropdown_menu>
        <.context_menu id="shared-context" use-portal portal-container="#bench-portal" modal={@modal}>
          <.context_menu_trigger as="div" class={proxy_class()}><span></span></.context_menu_trigger>
          <.context_menu_content class="w-56">
            <.context_items emoji={@emoji} cmd={&shared_cmd/1} />
          </.context_menu_content>
        </.context_menu>
      <% end %>
      <%= if @variant == "template" do %>
        <template id="tpl-more">
          <.dropdown_menu id="tpl-more-__ID__">
            <.dropdown_menu_trigger class={proxy_class()} tabindex="-1" aria-label="More actions">
              <span class="sr-only">More actions</span>
            </.dropdown_menu_trigger>
            <.dropdown_menu_content align="end" class="w-56">
              <.dropdown_items emoji={@emoji} cmd={&template_cmd/1} />
            </.dropdown_menu_content>
          </.dropdown_menu>
        </template>
        <template id="tpl-context">
          <.context_menu id="tpl-context-__ID__">
            <.context_menu_trigger as="div" class={proxy_class()}>
              <span></span>
            </.context_menu_trigger>
            <.context_menu_content class="w-56">
              <.context_items emoji={@emoji} cmd={&template_cmd/1} />
            </.context_menu_content>
          </.context_menu>
        </template>
        <div id="bench-tpl-portal" phx-update="ignore"></div>
      <% end %>
      <div
        data-shared-tooltip
        role="tooltip"
        hidden
        class="pointer-events-none fixed z-50 rounded-md bg-foreground px-3 py-1.5 text-xs text-background"
      >
      </div>
    </div>
    """
  end

  defp proxy_class, do: "pointer-events-none fixed top-0 left-0 size-px opacity-0"

  # What a menu item does: C knows the row; A reads it from the open menu
  # (bench.js); B gets it substituted into the cloned template.
  defp server_cmd(id, extra), do: JS.push("menu_action", value: Map.put(extra, :id, id))
  defp shared_cmd(extra), do: JS.dispatch("bench:menu-action", detail: extra)
  defp template_cmd(extra), do: JS.push("menu_action", value: Map.put(extra, :id, "__ID__"))

  attr :emoji, :list, required: true
  attr :cmd, :any, required: true

  defp dropdown_items(assigns) do
    ~H"""
    <.dropdown_menu_sub>
      <.dropdown_menu_sub_trigger>
        <.icon name="hero-face-smile" /> React
      </.dropdown_menu_sub_trigger>
      <.dropdown_menu_sub_content class="grid w-auto min-w-0 grid-cols-4 p-1">
        <.dropdown_menu_item
          :for={e <- @emoji}
          on-select={@cmd.(%{emoji: e})}
          class="justify-center text-lg"
        >
          {e}
        </.dropdown_menu_item>
      </.dropdown_menu_sub_content>
    </.dropdown_menu_sub>
    <.dropdown_menu_item :for={{icon, label} <- actions()} on-select={@cmd.(%{action: label})}>
      <.icon name={icon} /> {label}
    </.dropdown_menu_item>
    """
  end

  attr :emoji, :list, required: true
  attr :cmd, :any, required: true

  defp context_items(assigns) do
    ~H"""
    <.context_menu_sub>
      <.context_menu_sub_trigger>
        <.icon name="hero-face-smile" /> React
      </.context_menu_sub_trigger>
      <.context_menu_sub_content class="grid w-auto min-w-0 grid-cols-4 p-1">
        <.context_menu_item
          :for={e <- @emoji}
          on-select={@cmd.(%{emoji: e})}
          class="justify-center text-lg"
        >
          {e}
        </.context_menu_item>
      </.context_menu_sub_content>
    </.context_menu_sub>
    <.context_menu_item :for={{icon, label} <- actions()} on-select={@cmd.(%{action: label})}>
      <.icon name={icon} /> {label}
    </.context_menu_item>
    """
  end

  attr :user, :map, required: true

  defp profile(assigns) do
    ~H"""
    <div class="flex items-center gap-3">
      <.avatar class="size-10 rounded-lg">
        <.avatar_fallback class={"#{@user.color} font-medium text-white"}>
          {@user.initials}
        </.avatar_fallback>
      </.avatar>
      <div class="text-sm">
        <div class="font-semibold">{@user.name}</div>
        <div class="text-muted-foreground">Online</div>
      </div>
    </div>
    """
  end

  attr :emoji, :list, required: true

  # The redesign prototype: one tooltip and one menu for the whole page.
  defp shared_popups(assigns) do
    ~H"""
    <div id="bench-shared" phx-hook="BenchShared" phx-update="ignore">
      <div
        data-shared-tooltip
        role="tooltip"
        hidden
        class="pointer-events-none fixed z-50 rounded-md bg-foreground px-3 py-1.5 text-xs text-background"
      >
      </div>
      <div
        data-shared-menu
        role="menu"
        hidden
        class="fixed z-50 w-56 rounded-md border bg-popover p-1 text-popover-foreground shadow-md"
      >
        <div class="grid grid-cols-4 p-1">
          <button
            :for={e <- @emoji}
            type="button"
            role="menuitem"
            data-menu-emoji={e}
            class="rounded-sm p-1 text-lg hover:bg-accent"
          >
            {e}
          </button>
        </div>
        <button
          :for={{icon, label} <- actions()}
          type="button"
          role="menuitem"
          data-menu-action={label}
          class="flex w-full items-center gap-2 rounded-sm px-2 py-1.5 text-sm hover:bg-accent"
        >
          <.icon name={icon} class="size-4" /> {label}
        </button>
      </div>
    </div>
    """
  end

  defp toolbar_class do
    "absolute -top-4 right-4 z-10 rounded-lg border bg-background p-0.5 shadow-sm transition-opacity " <>
      "pointer-events-none opacity-0 group-hover/msg:pointer-events-auto group-hover/msg:opacity-100 " <>
      "focus-within:pointer-events-auto focus-within:opacity-100 " <>
      "has-[[data-state=open]]:pointer-events-auto has-[[data-state=open]]:opacity-100"
  end

  defp actions do
    [
      {"hero-chat-bubble-left-ellipsis", "Reply in thread"},
      {"hero-clipboard-document", "Copy text"},
      {"hero-bookmark", "Pin to channel"},
      {"hero-bell-alert", "Remind me about this"},
      {"hero-eye-slash", "Mark unread"},
      {"hero-pencil", "Edit message"},
      {"hero-trash", "Delete message"}
    ]
  end
end
