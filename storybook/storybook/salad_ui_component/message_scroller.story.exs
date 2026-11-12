defmodule Storybook.SaladUIComponents.MessageScroller do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Bubble
  alias SaladUI.Button
  alias SaladUI.Card
  alias SaladUI.Marker
  alias SaladUI.Message
  alias SaladUI.MessageScroller

  def function, do: &MessageScroller.message_scroller/1
  def layout, do: :one_column

  def imports,
    do: [
      {MessageScroller,
       [message_scroller_viewport: 1, message_scroller_content: 1, message_scroller_item: 1, message_scroller_button: 1]},
      {Message, [message: 1, message_content: 1, message_header: 1]},
      {Bubble, [bubble: 1, bubble_content: 1]},
      {Marker, [marker: 1, marker_content: 1]},
      {Card, [card: 1, card_header: 1, card_title: 1, card_description: 1, card_action: 1, card_content: 1]},
      {Button, [button: 1]}
    ]

  def container, do: {:div, class: "flex w-full justify-center py-8"}

  @transcript [
    {"activation", :user, "We're seeing activation dip after workspace creation. Can you help me find the likely step?"},
    {"activation-reply", :assistant,
     "The sharpest drop is between creating the workspace and inviting the first teammate. Workspace creation is still healthy, but the invite step is where users pause."},
    {"compare", :user, "What should I compare before we change the onboarding flow?"},
    {"compare-reply", :assistant,
     "Compare three cohorts: users who choose a template before inviting teammates, users who start from a blank workspace, and users who skip invites and return within 24 hours. If template users invite faster, the fix is better first-run guidance rather than a louder invite prompt."},
    {"experiment", :user, "Can you turn that into an experiment?"},
    {"experiment-reply", :assistant,
     "Yes. Show a short checklist after workspace creation: pick a template, add one project detail, then invite a teammate once the workspace has context. Measure first invite completion, 24-hour return rate, and whether teams create a second project."},
    {"risk", :user, "What's the risk if we delay the invite prompt?"},
    {"risk-reply", :assistant,
     "The main risk is reducing team creation for accounts that already know who they want to invite. Keep the invite action visible in the header and only change the empty-state guidance, so confident teams keep a direct route."}
  ]

  defp rows do
    Enum.map_join(@transcript, "\n", fn {id, role, text} ->
      align = if role == :user, do: "end", else: "start"
      variant = if role == :user, do: "muted", else: "ghost"

      """
      <.message_scroller_item message_id="#{id}" scroll_anchor={#{role == :user}}>
        <.message align="#{align}">
          <.message_content>
            <.bubble variant="#{variant}">
              <.bubble_content>#{text}</.bubble_content>
            </.bubble>
          </.message_content>
        </.message>
      </.message_scroller_item>
      """
    end)
  end

  defp card(id, title, description, attrs, extra \\ "", footer \\ "") do
    """
    <div class="flex w-full flex-col gap-4">
      <.card class="mx-auto h-[35rem] w-full max-w-sm gap-0">
        <.card_header class="gap-1 border-b">
          <.card_title>#{title}</.card_title>
          <.card_description>#{description}</.card_description>
          #{extra}
        </.card_header>
        <.card_content class="flex-1 overflow-hidden p-0">
          <.message_scroller id="#{id}" #{attrs}>
            <.message_scroller_viewport>
              <.message_scroller_content class="p-(--card-spacing)">
                #{rows()}
              </.message_scroller_content>
            </.message_scroller_viewport>
            <.message_scroller_button />
          </.message_scroller>
        </.card_content>
      </.card>
      #{footer}
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :demo,
        description:
          "A saved transcript in a height-constrained card. It opens at the end; scroll up and the button brings you back. Streaming, anchoring and history live in the Examples section (Message Scroller *).",
        template: card("ms-demo", "Conversation", "Opens at the latest message.", "")
      },
      %Variation{
        id: :opening_last_anchor,
        description:
          ~s|`default_scroll_position="last-anchor"` reopens at the last anchored turn (the user's latest question) with the reply below it, instead of the absolute bottom.|,
        template:
          card(
            "ms-last-anchor",
            "Opening Position",
            "Reopens at the last question.",
            ~s(default_scroll_position="last-anchor")
          )
      },
      %Variation{
        id: :opening_start,
        description:
          ~s|`default_scroll_position="start"` opens at the beginning. No `data-pending-scroll` is needed, so nothing is hidden on first paint.|,
        template:
          card(
            "ms-start",
            "Opening Position",
            "Resumes at the beginning.",
            ~s(default_scroll_position="start")
          )
      },
      %Variation{
        id: :group_chat,
        description:
          "Anchoring is role-independent: here a \"Marcus joined the chat\" marker is the scroll anchor, while the typing row is not.",
        template: """
        <.card class="mx-auto h-[35rem] w-full max-w-sm gap-0">
          <.card_header class="gap-1 border-b">
            <.card_title>Group Chat</.card_title>
            <.card_description>A marker starts the turn.</.card_description>
          </.card_header>
          <.card_content class="flex-1 overflow-hidden p-0">
            <.message_scroller id="ms-group" default_scroll_position="last-anchor">
              <.message_scroller_viewport>
                <.message_scroller_content class="p-(--card-spacing)">
                  <.message_scroller_item :for={i <- 1..4} message_id={"g-\#{i}"}>
                    <.message align={if rem(i, 2) == 0, do: "end", else: "start"}>
                      <.message_content>
                        <.message_header>{if rem(i, 2) == 0, do: "You", else: "Ava"}</.message_header>
                        <.bubble variant={if rem(i, 2) == 0, do: "muted", else: "secondary"}>
                          <.bubble_content>Planning note {i}: the launch checklist is nearly done, two items left for review.</.bubble_content>
                        </.bubble>
                      </.message_content>
                    </.message>
                  </.message_scroller_item>
                  <.message_scroller_item message_id="marcus-joined" scroll_anchor>
                    <.marker variant="separator">
                      <.marker_content>Marcus joined the chat</.marker_content>
                    </.marker>
                  </.message_scroller_item>
                  <.message_scroller_item message_id="marcus-1">
                    <.message>
                      <.message_content>
                        <.message_header>Marcus</.message_header>
                        <.bubble variant="secondary">
                          <.bubble_content>Hey all, catching up now. Which two items are left?</.bubble_content>
                        </.bubble>
                      </.message_content>
                    </.message>
                  </.message_scroller_item>
                  <.message_scroller_item>
                    <.marker>
                      <.marker_content class="shimmer">Ava is typing...</.marker_content>
                    </.marker>
                  </.message_scroller_item>
                </.message_scroller_content>
              </.message_scroller_viewport>
              <.message_scroller_button />
            </.message_scroller>
          </.card_content>
        </.card>
        """
      },
      %Variation{
        id: :commands,
        description:
          "Controls outside the frame drive it with `SaladUI.JS.dispatch_command/3` (no server round trip): `scroll_to_message` with `align` and `behavior`, `scroll_to_start` and `scroll_to_end`.",
        template:
          card(
            "ms-commands",
            "Commands",
            "Drive the transcript from outside.",
            "",
            "",
            """
            <div class="mx-auto flex w-full max-w-sm flex-wrap justify-center gap-2">
              <.button
                :for={{id, label} <- [{"activation", "Activation dip"}, {"compare", "Compare"}, {"experiment", "Experiment"}, {"risk", "Risk"}]}
                size="sm"
                variant="outline"
                phx-click={SaladUI.JS.dispatch_command("scroll_to_message", to: "#ms-commands", detail: %{message_id: id, align: "start", behavior: "smooth"})}
              >
                {label}
              </.button>
              <.button size="sm" variant="secondary" phx-click={SaladUI.JS.dispatch_command("scroll_to_start", to: "#ms-commands", detail: %{behavior: "smooth"})}>
                Top
              </.button>
              <.button size="sm" variant="secondary" phx-click={SaladUI.JS.dispatch_command("scroll_to_end", to: "#ms-commands", detail: %{behavior: "smooth"})}>
                Latest
              </.button>
            </div>
            """
          )
      },
      %Variation{
        id: :buttons,
        description:
          ~s|Both directions: `direction="start"` sits at the top with a flipped arrow. Custom content replaces the icon, e.g. a "Jump to latest" pill.|,
        template: """
        <.card class="mx-auto h-[35rem] w-full max-w-sm gap-0">
          <.card_header class="gap-1 border-b">
            <.card_title>Scroll Buttons</.card_title>
            <.card_description>Inert until there is somewhere to go.</.card_description>
          </.card_header>
          <.card_content class="flex-1 overflow-hidden p-0">
            <.message_scroller id="ms-buttons" default_scroll_position="start">
              <.message_scroller_viewport>
                <.message_scroller_content class="p-(--card-spacing)">
        #{rows()}
                </.message_scroller_content>
              </.message_scroller_viewport>
              <.message_scroller_button direction="start" />
              <.message_scroller_button class="h-8 rounded-full px-3 text-sm" size="sm">
                Jump to latest
              </.message_scroller_button>
            </.message_scroller>
          </.card_content>
        </.card>
        """
      }
    ]
  end
end
