defmodule Storybook.Examples.MessageScrollerNavigation do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Bubble
  import SaladUI.Button
  import SaladUI.Card
  import SaladUI.Message
  import SaladUI.MessageScroller

  def doc do
    """
    shadcn's commands, visibility and scrollable examples. The outline jumps with
    `SaladUI.LiveView.send_command/4` (`scroll_to_message`) and highlights the current turn
    from `on-visibility-change`; the footer reports `on-scrollable-change`.
    """
  end

  @transcript [
    {"nav-activation", :user,
     "We're seeing activation dip after workspace creation. Can you help me find the likely step?"},
    {"nav-activation-reply", :assistant,
     "The sharpest drop is between creating the workspace and inviting the first teammate.\n\nWorkspace creation is still healthy, but the invite step is where users pause. That suggests the product is asking for collaboration before the user has enough confidence in the workspace."},
    {"nav-compare", :user, "What should I compare before we change the onboarding flow?"},
    {"nav-compare-reply", :assistant,
     "Compare three cohorts:\n\n1. Users who choose a template before inviting teammates.\n2. Users who start from a blank workspace.\n3. Users who skip invites and return within 24 hours.\n\nIf template users invite faster, the fix is probably better first-run guidance rather than a louder invite prompt."},
    {"nav-experiment", :user, "Can you turn that into an experiment?"},
    {"nav-experiment-reply", :assistant,
     "Yes. Create a variant that shows a short checklist after workspace creation:\n\n- Pick a template.\n- Add one project detail.\n- Invite a teammate when the workspace has context.\n\nMeasure first invite completion, 24-hour return rate, and whether teams create a second project."},
    {"nav-risk", :user, "What's the risk if we delay the invite prompt?"},
    {"nav-risk-reply", :assistant,
     "The main risk is reducing team creation for accounts that already know who they want to invite.\n\nTo protect that path, keep the invite action visible in the header and only change the primary empty-state guidance."}
  ]

  @impl true
  def mount(_params, _session, socket) do
    messages = Enum.map(@transcript, fn {id, role, text} -> %{id: id, role: role, text: text} end)

    {:ok,
     socket
     |> assign(current: nil, scrollable: %{"start" => false, "end" => true})
     |> assign(outline: Enum.filter(messages, &(&1.role == :user)))
     |> stream(:messages, messages)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex w-full flex-col gap-4 py-6">
      <.card class="mx-auto h-[35rem] w-full max-w-sm gap-0">
        <.card_header class="gap-1 border-b">
          <.card_title>Transcript</.card_title>
          <.card_description>Jump between turns as you read.</.card_description>
        </.card_header>
        <.card_content class="flex-1 overflow-hidden p-0">
          <.message_scroller
            id="ms-navigation"
            default_scroll_position="start"
            scroll_margin={12}
            on-visibility-change="visibility"
            on-scrollable-change="scrollable"
          >
            <.message_scroller_viewport>
              <.message_scroller_content
                id="ms-navigation-messages"
                phx-update="stream"
                class="p-(--card-spacing)"
              >
                <.message_scroller_item
                  :for={{dom_id, m} <- @streams.messages}
                  id={dom_id}
                  message_id={m.id}
                  scroll_anchor={m.role == :user}
                >
                  <.message align={if m.role == :user, do: "end", else: "start"}>
                    <.message_content>
                      <.bubble variant={if m.role == :user, do: "muted", else: "ghost"}>
                        <.bubble_content class="space-y-2">
                          <p :for={p <- String.split(m.text, "\n\n")} class="whitespace-pre-wrap">
                            {p}
                          </p>
                        </.bubble_content>
                      </.bubble>
                    </.message_content>
                  </.message>
                </.message_scroller_item>
              </.message_scroller_content>
            </.message_scroller_viewport>
            <.message_scroller_button />
          </.message_scroller>
        </.card_content>
        <div class="border-t px-4 py-3 text-center text-sm text-muted-foreground">
          {scroll_status(@scrollable)}
        </div>
      </.card>

      <nav aria-label="Transcript outline" class="mx-auto flex w-full max-w-sm flex-col gap-1">
        <button
          :for={m <- @outline}
          type="button"
          phx-click="jump"
          phx-value-id={m.id}
          aria-current={if @current == m.id, do: "location"}
          class="flex min-h-7 items-center rounded-xl px-2 py-1.5 text-left text-sm transition-colors outline-none hover:bg-accent hover:text-accent-foreground focus-visible:bg-accent aria-current:bg-accent aria-current:text-accent-foreground"
        >
          <span class="line-clamp-1 min-w-0">{m.text}</span>
        </button>
        <div class="flex justify-center gap-2 pt-2">
          <.button size="sm" variant="outline" phx-click="start">Scroll to start</.button>
          <.button size="sm" variant="outline" phx-click="end">Scroll to end</.button>
        </div>
      </nav>
    </div>
    """
  end

  defp scroll_status(%{"start" => true, "end" => true}), do: "You can scroll both ways."
  defp scroll_status(%{"end" => true}), do: "You are at the top. You can only scroll down."
  defp scroll_status(%{"start" => true}), do: "You are at the bottom. You can only scroll up."
  defp scroll_status(_), do: "All messages fit in the viewport."

  @impl true
  def handle_event("jump", %{"id" => id}, socket) do
    {:noreply,
     SaladUI.LiveView.send_command(socket, "ms-navigation", "scroll_to_message", %{
       message_id: id,
       align: "start",
       behavior: "smooth"
     })}
  end

  def handle_event("start", _params, socket),
    do: {:noreply, SaladUI.LiveView.send_command(socket, "ms-navigation", "scroll_to_start", %{behavior: "smooth"})}

  def handle_event("end", _params, socket),
    do: {:noreply, SaladUI.LiveView.send_command(socket, "ms-navigation", "scroll_to_end", %{behavior: "smooth"})}

  def handle_event("visibility", %{"current_anchor_id" => current}, socket),
    do: {:noreply, assign(socket, :current, current)}

  def handle_event("scrollable", params, socket),
    do: {:noreply, assign(socket, :scrollable, Map.take(params, ["start", "end"]))}
end
