defmodule Storybook.SaladUIComponents.Message do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Attachment
  alias SaladUI.Avatar
  alias SaladUI.Bubble
  alias SaladUI.Button
  alias SaladUI.Marker
  alias SaladUI.Message

  def function, do: &Message.message/1
  def layout, do: :one_column

  def imports,
    do: [
      {Message, [message_group: 1, message_avatar: 1, message_content: 1, message_header: 1, message_footer: 1]},
      {Bubble, [bubble_group: 1, bubble: 1, bubble_content: 1, bubble_reactions: 1]},
      {Avatar, [avatar: 1, avatar_image: 1, avatar_fallback: 1]},
      {Marker, [marker: 1, marker_content: 1]},
      {Button, [button: 1]},
      {Attachment,
       [
         attachment: 1,
         attachment_media: 1,
         attachment_content: 1,
         attachment_title: 1,
         attachment_description: 1,
         attachment_actions: 1,
         attachment_action: 1
       ]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :demo,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-6 py-12">
          <.message align="end">
            <.message_avatar>
              <.avatar>
                <.avatar_image src="https://github.com/shadcn.png" alt="@me" />
                <.avatar_fallback>ME</.avatar_fallback>
              </.avatar>
            </.message_avatar>
            <.message_content>
              <.bubble>
                <.bubble_content>Deploying to prod real quick.</.bubble_content>
              </.bubble>
            </.message_content>
          </.message>
          <.message>
            <.message_avatar>
              <.avatar>
                <.avatar_image src="https://github.com/evilrabbit.png" alt="@rabbit" />
                <.avatar_fallback>R</.avatar_fallback>
              </.avatar>
            </.message_avatar>
            <.message_content>
              <.bubble variant="muted">
                <.bubble_content>It's 4:55 PM. On a Friday.</.bubble_content>
              </.bubble>
            </.message_content>
          </.message>
          <.message align="end">
            <.message_avatar>
              <.avatar>
                <.avatar_image src="https://github.com/shadcn.png" alt="@me" />
                <.avatar_fallback>ME</.avatar_fallback>
              </.avatar>
            </.message_avatar>
            <.message_content>
              <.bubble>
                <.bubble_content>It's a one-line change.</.bubble_content>
              </.bubble>
              <.message_footer>Delivered</.message_footer>
            </.message_content>
          </.message>
          <.message>
            <.message_avatar>
              <.avatar>
                <.avatar_image src="https://github.com/evilrabbit.png" alt="@rabbit" />
                <.avatar_fallback>R</.avatar_fallback>
              </.avatar>
            </.message_avatar>
            <.message_content>
              <.bubble_group>
                <.bubble variant="muted">
                  <.bubble_content>It's always a one-line change 😭.</.bubble_content>
                </.bubble>
                <.bubble variant="muted">
                  <.bubble_content>Alright, let me take a look.</.bubble_content>
                  <.bubble_reactions role="img" aria-label="Reactions: thumbs up">
                    <span>👍</span>
                  </.bubble_reactions>
                </.bubble>
              </.bubble_group>
            </.message_content>
          </.message>
          <.marker role="status">
            <.marker_content class="shimmer">
              <span class="font-medium">Oliver</span> is typing...
            </.marker_content>
          </.marker>
        </div>
        """
      },
      %Variation{
        id: :avatar,
        description: "The avatar sits at the bottom of the row, on the side the message is aligned to.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-6 py-12">
          <.message>
            <.message_avatar>
              <.avatar>
                <.avatar_image src="https://github.com/evilrabbit.png" alt="@avatar" />
                <.avatar_fallback>R</.avatar_fallback>
              </.avatar>
            </.message_avatar>
            <.message_content>
              <.bubble variant="muted">
                <.bubble_content>The build failed during dependency installation.</.bubble_content>
              </.bubble>
            </.message_content>
          </.message>
          <.message align="end">
            <.message_avatar>
              <.avatar>
                <.avatar_image src="https://github.com/shadcn.png" alt="@avatar" />
                <.avatar_fallback>R</.avatar_fallback>
              </.avatar>
            </.message_avatar>
            <.message_content>
              <.bubble>
                <.bubble_content>Can you share the exact error?</.bubble_content>
              </.bubble>
            </.message_content>
          </.message>
          <.message>
            <.message_avatar>
              <.avatar>
                <.avatar_image src="https://github.com/evilrabbit.png" alt="@avatar" />
                <.avatar_fallback>R</.avatar_fallback>
              </.avatar>
            </.message_avatar>
            <.message_content>
              <.bubble_group>
                <.bubble variant="muted">
                  <.bubble_content>Here's the error from the logs</.bubble_content>
                </.bubble>
                <.bubble variant="muted">
                  <.bubble_content>
                    Something went wrong with the build. The libraries are not installed correctly. Try running the build again.
                  </.bubble_content>
                </.bubble>
              </.bubble_group>
            </.message_content>
          </.message>
        </div>
        """
      },
      %Variation{
        id: :group,
        description: "An empty `message_avatar` keeps the indent for a grouped message.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-6 py-12">
          <.message_group>
            <.message>
              <.message_avatar />
              <.message_content>
                <.bubble variant="muted">
                  <.bubble_content>I checked the registry addresses.</.bubble_content>
                </.bubble>
              </.message_content>
            </.message>
            <.message>
              <.message_avatar>
                <.avatar>
                  <.avatar_image src="https://github.com/shadcn.png" alt="@avatar" />
                  <.avatar_fallback>CN</.avatar_fallback>
                </.avatar>
              </.message_avatar>
              <.message_content>
                <.bubble variant="muted">
                  <.bubble_content>The component and example JSON now live under the UI registry.</.bubble_content>
                </.bubble>
              </.message_content>
            </.message>
          </.message_group>
        </div>
        """
      },
      %Variation{
        id: :header_footer,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.message>
            <.message_content>
              <.message_header>Olivia</.message_header>
              <.bubble variant="muted">
                <.bubble_content>I already checked the logs.</.bubble_content>
              </.bubble>
            </.message_content>
          </.message>
          <.message align="end">
            <.message_content>
              <.bubble>
                <.bubble_content>Send the report to the team. Ping @shadcn if you need help.</.bubble_content>
              </.bubble>
              <.message_footer>
                <div>Read <span class="font-normal">Yesterday</span></div>
              </.message_footer>
            </.message_content>
          </.message>
        </div>
        """
      },
      %Variation{
        id: :actions,
        description: "Put action buttons in the footer.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.message>
            <.message_content>
              <.bubble variant="muted">
                <.bubble_content>The install failure is coming from the workspace package.</.bubble_content>
              </.bubble>
              <.message_footer>
                <.button variant="ghost" size="icon" aria-label="Copy" title="Copy">
                  <.icon name="hero-clipboard-document" class="size-4" />
                </.button>
                <.button variant="ghost" size="icon" aria-label="Like" title="Like">
                  <.icon name="hero-hand-thumb-up" class="size-4" />
                </.button>
                <.button variant="ghost" size="icon" aria-label="Dislike" title="Dislike">
                  <.icon name="hero-hand-thumb-down" class="size-4" />
                </.button>
              </.message_footer>
            </.message_content>
          </.message>
          <.message align="end">
            <.message_content>
              <.bubble>
                <.bubble_content>Okay drop me a link. Taking a look...</.bubble_content>
              </.bubble>
              <.message_footer class="gap-2">
                <span class="font-normal text-destructive">Failed to send</span>
                <.button variant="ghost" size="icon-xs" title="Retry" aria-label="Retry">
                  <.icon name="hero-arrow-path" class="size-3" />
                </.button>
              </.message_footer>
            </.message_content>
          </.message>
        </div>
        """
      },
      %Variation{
        id: :attachment,
        template: """
        <div class="flex w-full max-w-sm flex-col gap-8 py-12">
          <.message align="end">
            <.message_content>
              <.attachment orientation="vertical">
                <.attachment_media variant="image">
                  <img
                    src="https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=900&auto=format&fit=crop&q=80"
                    alt="Workspace"
                  />
                </.attachment_media>
              </.attachment>
              <.bubble>
                <.bubble_content>Here's the image. Can you add it to the PDF? Use it for the cover page.</.bubble_content>
              </.bubble>
            </.message_content>
          </.message>
          <.message>
            <.message_content>
              <.bubble variant="muted">
                <.bubble_content>Done. Here's the PDF with the image added as the cover page.</.bubble_content>
              </.bubble>
              <.attachment>
                <.attachment_media>
                  <.icon name="hero-document-text" />
                </.attachment_media>
                <.attachment_content>
                  <.attachment_title>sales-dashboard.pdf</.attachment_title>
                  <.attachment_description>PDF · 2.4 MB</.attachment_description>
                </.attachment_content>
                <.attachment_actions>
                  <.attachment_action title="Download" aria-label="Download" size="icon-sm" variant="secondary">
                    <.icon name="hero-arrow-down-tray" class="size-4" />
                  </.attachment_action>
                </.attachment_actions>
              </.attachment>
            </.message_content>
          </.message>
          <.message align="end">
            <.message_content>
              <.bubble>
                <.bubble_content>Thanks. Looks good.</.bubble_content>
              </.bubble>
            </.message_content>
          </.message>
        </div>
        """
      }
    ]
  end
end
