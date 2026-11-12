defmodule Storybook.SaladUIComponents.Empty do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Avatar
  alias SaladUI.Button
  alias SaladUI.Empty
  alias SaladUI.Input
  alias SaladUI.Kbd
  alias SaladUI.Spinner

  def function, do: &Empty.empty/1
  def layout, do: :one_column

  def imports,
    do: [
      {Empty, [empty_header: 1, empty_media: 1, empty_title: 1, empty_description: 1, empty_content: 1]},
      {Avatar, [avatar: 1, avatar_image: 1, avatar_fallback: 1]},
      {Button, [button: 1]},
      {Input, [input: 1]},
      {Kbd, [kbd: 1]},
      {Spinner, [spinner: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :demo,
        template: """
        <.empty>
          <.empty_header>
            <.empty_media variant="icon">
              <Lucideicons.folder_code />
            </.empty_media>
            <.empty_title>No Projects Yet</.empty_title>
            <.empty_description>
              You haven't created any projects yet. Get started by creating your first project.
            </.empty_description>
          </.empty_header>
          <.empty_content>
            <div class="flex gap-2">
              <.button>Create Project</.button>
              <.button variant="outline">Import Project</.button>
            </div>
          </.empty_content>
          <.button variant="link" href="#" class="text-muted-foreground" size="sm">
            Learn More <Lucideicons.arrow_up_right />
          </.button>
        </.empty>
        """
      },
      %Variation{
        id: :outline,
        description: "Add `border` for an outlined empty state.",
        template: """
        <.empty class="border border-dashed">
          <.empty_header>
            <.empty_media variant="icon">
              <Lucideicons.cloud />
            </.empty_media>
            <.empty_title>Cloud Storage Empty</.empty_title>
            <.empty_description>Upload files to your cloud storage to access them anywhere.</.empty_description>
          </.empty_header>
          <.empty_content>
            <.button variant="outline" size="sm">Upload Files</.button>
          </.empty_content>
        </.empty>
        """
      },
      %Variation{
        id: :background,
        description: "Use `bg-*` and `bg-gradient-*` utilities for a background.",
        template: """
        <div class="h-96">
          <.empty class="h-full bg-gradient-to-b from-muted/50 from-30% to-background">
            <.empty_header>
              <.empty_media variant="icon">
                <Lucideicons.bell />
              </.empty_media>
              <.empty_title>No Notifications</.empty_title>
              <.empty_description>You're all caught up. New notifications will appear here.</.empty_description>
            </.empty_header>
            <.empty_content>
              <.button variant="outline" size="sm">
                <Lucideicons.refresh_ccw /> Refresh
              </.button>
            </.empty_content>
          </.empty>
        </div>
        """
      },
      %Variation{
        id: :avatar,
        template: """
        <.empty>
          <.empty_header>
            <.empty_media variant="default">
              <.avatar class="size-12">
                <.avatar_image src="https://github.com/shadcn.png" class="grayscale" />
                <.avatar_fallback>LR</.avatar_fallback>
              </.avatar>
            </.empty_media>
            <.empty_title>User Offline</.empty_title>
            <.empty_description>
              This user is currently offline. You can leave a message to notify them or try again later.
            </.empty_description>
          </.empty_header>
          <.empty_content>
            <.button size="sm">Leave Message</.button>
          </.empty_content>
        </.empty>
        """
      },
      %Variation{
        id: :avatar_group,
        template: """
        <.empty>
          <.empty_header>
            <.empty_media>
              <div class="flex -space-x-2 *:data-[slot=avatar]:size-12 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background *:data-[slot=avatar]:grayscale">
                <.avatar>
                  <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
                  <.avatar_fallback>CN</.avatar_fallback>
                </.avatar>
                <.avatar>
                  <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
                  <.avatar_fallback>LR</.avatar_fallback>
                </.avatar>
                <.avatar>
                  <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
                  <.avatar_fallback>ER</.avatar_fallback>
                </.avatar>
              </div>
            </.empty_media>
            <.empty_title>No Team Members</.empty_title>
            <.empty_description>Invite your team to collaborate on this project.</.empty_description>
          </.empty_header>
          <.empty_content>
            <.button size="sm">
              <Lucideicons.plus /> Invite Members
            </.button>
          </.empty_content>
        </.empty>
        """
      },
      %Variation{
        id: :input_group,
        description: "SaladUI has no `input_group` yet; the search field is composed from `input` and positioned icons.",
        template: """
        <.empty>
          <.empty_header>
            <.empty_title>404 - Not Found</.empty_title>
            <.empty_description>
              The page you're looking for doesn't exist. Try searching for what you need below.
            </.empty_description>
          </.empty_header>
          <.empty_content>
            <div class="relative w-full sm:w-3/4">
              <Lucideicons.search class="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
              <.input id="empty-search" name="q" placeholder="Try searching for pages..." class="pr-10 pl-9" />
              <div class="absolute top-1/2 right-3 -translate-y-1/2"><.kbd>/</.kbd></div>
            </div>
            <.empty_description>
              Need help? <a href="#">Contact support</a>
            </.empty_description>
          </.empty_content>
        </.empty>
        """
      },
      %Variation{
        id: :icon,
        template: """
        <div class="grid gap-8 md:grid-cols-2">
          <.empty>
            <.empty_header>
              <.empty_media variant="icon">
                <Lucideicons.inbox />
              </.empty_media>
              <.empty_title>No messages</.empty_title>
              <.empty_description>Your inbox is empty. New messages will appear here.</.empty_description>
            </.empty_header>
          </.empty>
          <.empty>
            <.empty_header>
              <.empty_media variant="icon">
                <Lucideicons.star />
              </.empty_media>
              <.empty_title>No favorites</.empty_title>
              <.empty_description>Items you mark as favorites will appear here.</.empty_description>
            </.empty_header>
          </.empty>
          <.empty>
            <.empty_header>
              <.empty_media variant="icon">
                <Lucideicons.heart />
              </.empty_media>
              <.empty_title>No likes yet</.empty_title>
              <.empty_description>Content you like will be saved here for easy access.</.empty_description>
            </.empty_header>
          </.empty>
          <.empty>
            <.empty_header>
              <.empty_media variant="icon">
                <Lucideicons.bookmark />
              </.empty_media>
              <.empty_title>No bookmarks</.empty_title>
              <.empty_description>Save interesting content by bookmarking it.</.empty_description>
            </.empty_header>
          </.empty>
        </div>
        """
      },
      %Variation{
        id: :spinner,
        template: """
        <.empty class="w-full">
          <.empty_header>
            <.empty_media variant="icon">
              <.spinner />
            </.empty_media>
            <.empty_title>Processing your request</.empty_title>
            <.empty_description>Please wait while we process your request. Do not refresh the page.</.empty_description>
          </.empty_header>
          <.empty_content>
            <.button variant="outline" size="sm">Cancel</.button>
          </.empty_content>
        </.empty>
        """
      }
    ]
  end
end
