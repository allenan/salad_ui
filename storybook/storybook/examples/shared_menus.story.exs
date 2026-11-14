defmodule Storybook.Examples.SharedMenus do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladStorybookWeb.CoreComponents, only: [icon: 1]
  import SaladUI.Button
  import SaladUI.ContextMenu
  import SaladUI.DropdownMenu

  def doc do
    "Twenty rows sharing ONE dropdown menu and ONE context menu: each row's ⋮ and the row itself " <>
      "are detached triggers (`for` + `context`), so the rows carry no hook and no menu markup. " <>
      "The items show or hide by the row's context (`show-when` / `hide-when`): Pin or Unpin, " <>
      "Edit and Delete on Ada's (\"your\") messages only, Report disabled on your own; " <>
      "Copy text copies the row's body with `SaladUI.JS.copy/2`."
  end

  @authors ~w(Ada Grace Alan Barbara Edsger)
  @bodies [
    "Pushed the fix for the flaky upload test.",
    "Lunch at noon?",
    "Retro moves to Thursday.",
    "Deploy is green, watching the dashboards.",
    "Who remembers why we pinned that dependency?"
  ]

  @impl true
  def mount(_params, _session, socket) do
    messages =
      for id <- 1..20 do
        %{
          id: id,
          author: Enum.at(@authors, rem(id, 5)),
          body: Enum.at(@bodies, rem(id * 3, 5)),
          pinned: false
        }
      end

    {:ok, socket |> assign(:last_action, nil) |> stream(:messages, messages)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex w-full max-w-xl flex-col gap-3 py-8">
      <p id="shared-menus-last" class="text-sm text-muted-foreground" aria-live="polite">
        {@last_action || "Open a row's ⋮ menu, or right click a row."}
      </p>

      <div
        id="shared-menus-list"
        phx-update="stream"
        tabindex="-1"
        class="flex max-h-[28rem] flex-col overflow-y-auto rounded-xl border bg-card outline-none"
      >
        <.context_menu_trigger
          :for={{dom_id, message} <- @streams.messages}
          id={dom_id}
          as="div"
          for="shared-menus-context"
          context={row_context(message)}
          class="group relative flex items-start gap-3 border-b px-4 py-2 last:border-b-0 hover:bg-muted/50 data-[state=open]:bg-muted/50 has-[[data-state=open]]:bg-muted/50"
        >
          <div class="flex min-w-0 flex-1 flex-col">
            <span class="text-sm font-medium">
              {message.author}
              <span :if={message.pinned} class="ms-1 text-xs text-muted-foreground">pinned</span>
            </span>
            <span class="text-sm" data-body>{message.body}</span>
          </div>
          <.dropdown_menu_trigger
            for="shared-menus-more"
            context={row_context(message)}
            as={&button/1}
            variant="ghost"
            size="icon-sm"
            aria-label={"More actions for message #{message.id}"}
            class="opacity-0 group-hover:opacity-100 focus-visible:opacity-100 data-[state=open]:opacity-100"
          >
            <.icon name="hero-ellipsis-vertical" />
          </.dropdown_menu_trigger>
        </.context_menu_trigger>
      </div>

      <.dropdown_menu id="shared-menus-more">
        <.dropdown_menu_content align="end" class="w-44">
          <.dropdown_menu_item phx-click="reply">
            <.icon name="hero-arrow-uturn-left" /> Reply
          </.dropdown_menu_item>
          <.dropdown_menu_item on-select="pin" hide-when={%{pinned: true}}>
            <.icon name="hero-bookmark" /> Pin
          </.dropdown_menu_item>
          <.dropdown_menu_item on-select="unpin" show-when={%{pinned: true}}>
            <.icon name="hero-bookmark-slash" /> Unpin
          </.dropdown_menu_item>
          <.dropdown_menu_item phx-click={copy_body()}>
            <.icon name="hero-clipboard-document" /> Copy text
          </.dropdown_menu_item>
          <.dropdown_menu_item phx-click="report" disabled-when={%{own: true}}>
            <.icon name="hero-flag" /> Report
          </.dropdown_menu_item>
          <.dropdown_menu_group show-when={%{own: true}}>
            <.dropdown_menu_separator />
            <.dropdown_menu_label>Your message</.dropdown_menu_label>
            <.dropdown_menu_item phx-click="edit">
              <.icon name="hero-pencil" /> Edit
            </.dropdown_menu_item>
            <.dropdown_menu_item variant="destructive" phx-click="delete">
              <.icon name="hero-trash" /> Delete
            </.dropdown_menu_item>
          </.dropdown_menu_group>
        </.dropdown_menu_content>
      </.dropdown_menu>

      <.context_menu id="shared-menus-context">
        <.context_menu_content class="w-44">
          <.context_menu_item phx-click="reply">Reply</.context_menu_item>
          <.context_menu_item on-select="pin" hide-when={%{pinned: true}}>Pin</.context_menu_item>
          <.context_menu_item on-select="unpin" show-when={%{pinned: true}}>Unpin</.context_menu_item>
          <.context_menu_item phx-click={copy_body()}>Copy text</.context_menu_item>
          <.context_menu_item phx-click="report" disabled-when={%{own: true}}>
            Report
          </.context_menu_item>
          <.context_menu_group show-when={%{own: true}}>
            <.context_menu_separator />
            <.context_menu_item phx-click="edit">Edit</.context_menu_item>
            <.context_menu_item variant="destructive" phx-click="delete">Delete</.context_menu_item>
          </.context_menu_group>
        </.context_menu_content>
      </.context_menu>
    </div>
    """
  end

  # What a row's triggers tell the shared menus. Ada plays "you": her
  # messages offer Edit and Delete.
  defp row_context(message) do
    %{id: message.id, own: message.author == "Ada", pinned: message.pinned}
  end

  # Copies the body of the row the menu is open for: no app JS.
  defp copy_body do
    SaladUI.JS.copy(within: "[data-salad-for='shared-menus-context']", from: "[data-body]")
  end

  @impl true
  def handle_event("reply", %{"id" => id}, socket) do
    {:noreply, assign(socket, :last_action, "Reply to message #{id}")}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, assign(socket, :last_action, "Edit message #{id}")}
  end

  def handle_event("report", %{"id" => id}, socket) do
    {:noreply, assign(socket, :last_action, "Reported message #{id}")}
  end

  def handle_event("pin", %{"id" => id}, socket), do: {:noreply, set_pinned(socket, id, true)}
  def handle_event("unpin", %{"id" => id}, socket), do: {:noreply, set_pinned(socket, id, false)}

  def handle_event("delete", %{"id" => id}, socket) do
    id = to_integer(id)

    {:noreply,
     socket
     |> assign(:last_action, "Deleted message #{id}")
     |> stream_delete_by_dom_id(:messages, "messages-#{id}")}
  end

  defp set_pinned(socket, id, pinned) do
    id = to_integer(id)

    message = %{
      id: id,
      author: Enum.at(@authors, rem(id, 5)),
      body: Enum.at(@bodies, rem(id * 3, 5)),
      pinned: pinned
    }

    socket
    |> assign(:last_action, "#{if pinned, do: "Pinned", else: "Unpinned"} message #{id}")
    |> stream_insert(:messages, message)
  end

  defp to_integer(id) when is_integer(id), do: id
  defp to_integer(id) when is_binary(id), do: String.to_integer(id)
end
