defmodule Storybook.SaladUIComponents.Spinner do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Badge
  alias SaladUI.Button
  alias SaladUI.Empty
  alias SaladUI.Input
  alias SaladUI.Item
  alias SaladUI.Progress
  alias SaladUI.Spinner
  alias SaladUI.Textarea

  def function, do: &Spinner.spinner/1

  def imports,
    do: [
      {Badge, [badge: 1]},
      {Button, [button: 1]},
      {Empty, [empty: 1, empty_header: 1, empty_media: 1, empty_title: 1, empty_description: 1, empty_content: 1]},
      {Input, [input: 1]},
      {Item,
       [item: 1, item_media: 1, item_content: 1, item_title: 1, item_description: 1, item_actions: 1, item_footer: 1]},
      {Progress, [progress: 1]},
      {Textarea, [textarea: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :basic,
        attributes: %{}
      },
      %Variation{
        id: :demo,
        template: """
        <div class="flex w-full max-w-xs flex-col gap-4 [--radius:1rem]">
          <.item variant="muted">
            <.item_media>
              <.spinner />
            </.item_media>
            <.item_content>
              <.item_title class="line-clamp-1">Processing payment...</.item_title>
            </.item_content>
            <.item_content class="flex-none justify-end">
              <span class="text-sm tabular-nums">$100.00</span>
            </.item_content>
          </.item>
        </div>
        """
      },
      %Variation{
        id: :custom,
        description: "Pass any icon as the inner block to spin it instead of the default.",
        template: """
        <div class="flex items-center gap-4">
          <.spinner>
            <Lucideicons.loader />
          </.spinner>
        </div>
        """
      },
      %Variation{
        id: :size,
        description: "Use `size-*` utilities.",
        template: """
        <div class="flex items-center gap-6">
          <.spinner class="size-3" />
          <.spinner class="size-4" />
          <.spinner class="size-6" />
          <.spinner class="size-8" />
        </div>
        """
      },
      %Variation{
        id: :color,
        description: "Use `text-*` utilities.",
        template: """
        <div class="flex items-center gap-6">
          <.spinner class="size-6 text-red-500" />
          <.spinner class="size-6 text-green-500" />
          <.spinner class="size-6 text-blue-500" />
          <.spinner class="size-6 text-yellow-500" />
          <.spinner class="size-6 text-purple-500" />
        </div>
        """
      },
      %Variation{
        id: :button,
        template: """
        <div class="flex flex-col items-center gap-4">
          <.button disabled size="sm">
            <.spinner data-icon="inline-start" /> Loading...
          </.button>
          <.button variant="outline" disabled size="sm">
            <.spinner data-icon="inline-start" /> Please wait
          </.button>
          <.button variant="secondary" disabled size="sm">
            <.spinner data-icon="inline-start" /> Processing
          </.button>
        </div>
        """
      },
      %Variation{
        id: :badge,
        template: """
        <div class="flex items-center gap-4 [--radius:1.2rem]">
          <.badge><.spinner /> Syncing</.badge>
          <.badge variant="secondary"><.spinner /> Updating</.badge>
          <.badge variant="outline"><.spinner /> Processing</.badge>
        </div>
        """
      },
      %Variation{
        id: :input_group,
        description:
          "SaladUI has no `input_group` yet; these are composed from `input`/`textarea` and positioned addons.",
        template: """
        <div class="flex w-full max-w-md flex-col gap-4">
          <div class="relative">
            <.input id="spinner-input" name="message" placeholder="Send a message..." disabled class="pr-9" />
            <.spinner class="absolute top-1/2 right-3 -translate-y-1/2 text-muted-foreground" />
          </div>
          <div class="rounded-md border border-input shadow-xs">
            <.textarea id="spinner-textarea" name="message" placeholder="Send a message..." disabled class="resize-none border-0 shadow-none focus-visible:ring-0" />
            <div class="flex items-center gap-2 px-3 pb-3 text-sm text-muted-foreground">
              <.spinner /> Validating...
              <.button size="icon-xs" class="ml-auto rounded-full">
                <Lucideicons.arrow_up />
                <span class="sr-only">Send</span>
              </.button>
            </div>
          </div>
        </div>
        """
      },
      %Variation{
        id: :empty,
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
      },
      %Variation{
        id: :item,
        template: """
        <div class="flex w-full max-w-md flex-col gap-4 [--radius:1rem]">
          <.item variant="outline">
            <.item_media variant="icon">
              <.spinner />
            </.item_media>
            <.item_content>
              <.item_title>Downloading...</.item_title>
              <.item_description>129 MB / 1000 MB</.item_description>
            </.item_content>
            <.item_actions class="hidden sm:flex">
              <.button variant="outline" size="sm">Cancel</.button>
            </.item_actions>
            <.item_footer>
              <.progress value={75} />
            </.item_footer>
          </.item>
        </div>
        """
      }
    ]
  end
end
