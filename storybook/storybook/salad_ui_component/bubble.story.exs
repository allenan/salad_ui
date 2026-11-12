defmodule Storybook.SaladUIComponents.Bubble do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Bubble
  alias SaladUI.Button
  alias SaladUI.Collapsible
  alias SaladUI.Popover
  alias SaladUI.Tooltip

  def function, do: &Bubble.bubble/1
  def layout, do: :one_column

  def imports,
    do: [
      {Bubble, [bubble_group: 1, bubble_content: 1, bubble_reactions: 1]},
      {Button, [button: 1]},
      {Collapsible, [collapsible: 1, collapsible_trigger: 1, collapsible_content: 1]},
      {Popover, [popover: 1, popover_trigger: 1, popover_content: 1, popover_header: 1, popover_title: 1, popover_description: 1]},
      {Tooltip, [tooltip: 1, tooltip_trigger: 1, tooltip_content: 1]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :demo,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.bubble align="end">
            <.bubble_content>Hey there! what's up?</.bubble_content>
          </.bubble>
          <.bubble_group>
            <.bubble variant="muted">
              <.bubble_content>Hey! Want to see chat bubbles?</.bubble_content>
            </.bubble>
            <.bubble variant="muted">
              <.bubble_content>I can group messages, switch sides, and keep the whole thread easy to scan.</.bubble_content>
              <.bubble_reactions role="img" aria-label="Reaction: thumbs up">
                <span>👍</span>
              </.bubble_reactions>
            </.bubble>
          </.bubble_group>
          <.bubble align="end">
            <.bubble_content>Sure. Hit me with your best demo.</.bubble_content>
          </.bubble>
          <.bubble variant="muted">
            <.bubble_content>Yes. You are reading a demo that is demoing itself. Very meta. Very on-brand.</.bubble_content>
            <.bubble_reactions role="img" aria-label="Reactions: thumbs up, fire, eyes, and 2 more">
              <span>👍</span>
              <span>🔥</span>
              <span>👀</span>
              <span>+2</span>
            </.bubble_reactions>
          </.bubble>
        </div>
        """
      },
      %Variation{
        id: :variants,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-12 py-12">
          <.bubble>
            <.bubble_content>This is the default primary bubble.</.bubble_content>
          </.bubble>
          <.bubble variant="secondary" align="end">
            <.bubble_content>This is the secondary variant.</.bubble_content>
          </.bubble>
          <.bubble variant="muted">
            <.bubble_content>This one is muted. It uses a lower emphasis color for the chat bubble.</.bubble_content>
            <.bubble_reactions role="img" aria-label="Reaction: thumbs up">
              <span>👍</span>
            </.bubble_reactions>
          </.bubble>
          <.bubble variant="tinted" align="end">
            <.bubble_content>This one is tinted. The tint is a softer color derived from the primary color.</.bubble_content>
          </.bubble>
          <.bubble variant="outline">
            <.bubble_content>We can also use an outlined variant.</.bubble_content>
          </.bubble>
          <.bubble variant="destructive" align="end">
            <.bubble_content>Or a destructive variant with a reaction.</.bubble_content>
            <.bubble_reactions role="img" aria-label="Reaction: fire">
              <span>🔥</span>
            </.bubble_reactions>
          </.bubble>
          <.bubble variant="ghost">
            <.bubble_content>
              <p>Ghost bubbles work for assistant text, <strong>markdown</strong>, and other content that should not be framed.</p>
              <p class="mt-2">This is perfect for assistant messages that should not have a frame and can take the full width of the container. You can also render <code class="rounded bg-muted px-1 font-mono text-xs">code</code> in it.</p>
              <p class="mt-2">Ghost bubbles are full width and can take the full width of the container.</p>
            </.bubble_content>
          </.bubble>
        </div>
        """
      },
      %Variation{
        id: :alignment,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.bubble variant="muted">
            <.bubble_content>This bubble is aligned to the start. This is the default alignment.</.bubble_content>
          </.bubble>
          <.bubble align="end">
            <.bubble_content>This bubble is aligned to the end. Use this for user messages.</.bubble_content>
          </.bubble>
        </div>
        """
      },
      %Variation{
        id: :group,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.bubble variant="muted">
            <.bubble_content>Can you tell me what's the issue?</.bubble_content>
          </.bubble>
          <.bubble_group>
            <.bubble align="end">
              <.bubble_content>You tell me!</.bubble_content>
            </.bubble>
            <.bubble align="end">
              <.bubble_content>It worked yesterday. You broke it!</.bubble_content>
            </.bubble>
            <.bubble align="end">
              <.bubble_content>Find the bug and fix it.</.bubble_content>
              <.bubble_reactions aria-label="Reactions: eyes" align="start">
                <span>👀</span>
              </.bubble_reactions>
            </.bubble>
          </.bubble_group>
          <.bubble variant="muted">
            <.bubble_content>Want me to diff yesterday's you against today's you? It's a bit embarrassing.</.bubble_content>
          </.bubble>
        </div>
        """
      },
      %Variation{
        id: :reactions,
        description: "`side` and `align` place the reactions; buttons inside drop the padding.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-12 py-12">
          <.bubble variant="muted" align="end">
            <.bubble_content>I don't need tests, I know my code works.</.bubble_content>
            <.bubble_reactions align="start" role="img" aria-label="Reactions: thumbs up, surprised">
              <span>👍</span>
              <span>😮</span>
            </.bubble_reactions>
          </.bubble>
          <.bubble variant="muted">
            <.bubble_content>Bold. Fine I'll add some tests. I'll let you know when they're done.</.bubble_content>
            <.bubble_reactions role="img" aria-label="Reactions: eyes, rocket, and 2 more">
              <span>👀</span>
              <span>🚀</span>
              <span>+2</span>
            </.bubble_reactions>
          </.bubble>
          <.bubble variant="default" align="end">
            <.bubble_content>Tests passed on the first try. All 142 of them. Looking good!</.bubble_content>
            <.bubble_reactions side="top" align="start" role="img" aria-label="Reactions: party popper, clapping hands">
              <span>🎉</span>
              <span>👏</span>
            </.bubble_reactions>
          </.bubble>
          <.bubble variant="destructive">
            <.bubble_content>Are you sure I can run this command?</.bubble_content>
            <.bubble_reactions>
              <.button variant="ghost" size="xs">Yes, run it</.button>
            </.bubble_reactions>
          </.bubble>
        </div>
        """
      },
      %Variation{
        id: :link_button,
        description: "`as=\"button\"` (or `as=\"a\"`) makes the bubble itself interactive.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.bubble variant="muted">
            <.bubble_content>How can I help you today?</.bubble_content>
          </.bubble>
          <.bubble_group>
            <.bubble variant="tinted" align="end">
              <.bubble_content as="button">I forgot my password</.bubble_content>
            </.bubble>
            <.bubble variant="tinted" align="end">
              <.bubble_content as="button">I need help with my subscription</.bubble_content>
            </.bubble>
            <.bubble variant="tinted" align="end">
              <.bubble_content as="a" href="#talk-to-a-human">Something else. Talk to a human.</.bubble_content>
            </.bubble>
          </.bubble_group>
        </div>
        """
      },
      %Variation{
        id: :collapsible,
        description: "A long bubble composes `collapsible`; the root's `data-state` swaps the preview and the label.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.bubble variant="muted">
            <.bubble_content>How can I help you today?</.bubble_content>
          </.bubble>
          <.bubble variant="muted" align="end">
            <.bubble_content class="whitespace-pre-line">
              <.collapsible id="bubble-collapsible" class="group/bubble-collapsible">
                <div class="group-data-[state=open]/bubble-collapsible:hidden">The accessibility review found two focus states that were visually too subtle in dark mode.
        I checked the dialog, menu, and drawer paths because each one renders focusable...</div>
                <.collapsible_content>The accessibility review found two focus states that were visually too subtle in dark mode.
        I checked the dialog, menu, and drawer paths because each one renders focusable controls inside a layered surface.
        The dialog and drawer are fine. The menu needs the hover and focus tokens split so keyboard focus stays visible when the pointer is not involved.
        I also recommend keeping the change in the style file instead of the primitive so the other themes can choose their own focus treatment later.</.collapsible_content>
                <.collapsible_trigger as="button" class="mt-1 inline-flex items-center gap-1 text-sm font-medium text-muted-foreground underline-offset-4 hover:underline">
                  <span class="group-data-[state=open]/bubble-collapsible:hidden">Show more</span>
                  <span class="hidden group-data-[state=open]/bubble-collapsible:inline">Show less</span>
                  <.icon name="hero-chevron-down" class="size-4 group-data-[state=open]/bubble-collapsible:rotate-180" />
                </.collapsible_trigger>
              </.collapsible>
            </.bubble_content>
          </.bubble>
        </div>
        """
      },
      %Variation{
        id: :popover,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-4 py-12">
          <.bubble align="end">
            <.bubble_content>Run the build script.</.bubble_content>
          </.bubble>
          <.bubble variant="destructive">
            <.bubble_content>Failed to run the command.</.bubble_content>
            <.bubble_reactions>
              <.popover id="bubble-popover">
                <.popover_trigger
                  as={&button/1}
                  variant="ghost"
                  size="icon-xs"
                  aria-label="Show error details"
                  class="aria-expanded:text-destructive"
                >
                  <.icon name="hero-information-circle" class="size-3" />
                </.popover_trigger>
                <.popover_content>
                  <.popover_header>
                    <.popover_title class="text-sm">Command failed with exit code 1</.popover_title>
                    <.popover_description class="text-sm">ENOENT: no such file or directory, open pnpm-lock.yaml</.popover_description>
                  </.popover_header>
                </.popover_content>
              </.popover>
            </.bubble_reactions>
          </.bubble>
        </div>
        """
      },
      %Variation{
        id: :tooltip,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-4 py-12">
          <.bubble variant="secondary">
            <.bubble_content>Did you remove the stale route?</.bubble_content>
          </.bubble>
          <.bubble align="end">
            <.bubble_content>Yes, removed it from the registry.</.bubble_content>
            <.bubble_reactions class="p-0">
              <.tooltip id="bubble-tooltip">
                <.tooltip_trigger>
                  <.button variant="ghost" size="icon-xs" aria-label="Read receipt">
                    <.icon name="hero-check" class="size-3" />
                  </.button>
                </.tooltip_trigger>
                <.tooltip_content>Read on Jan 5, 2026 at 4:32 PM</.tooltip_content>
              </.tooltip>
            </.bubble_reactions>
          </.bubble>
        </div>
        """
      }
    ]
  end
end
