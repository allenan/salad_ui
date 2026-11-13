defmodule Storybook.SaladUIComponents.Item do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Avatar
  alias SaladUI.Button
  alias SaladUI.DropdownMenu
  alias SaladUI.Item
  alias SaladUI.Progress
  alias SaladUI.Spinner

  def function, do: &Item.item/1
  def layout, do: :one_column

  def imports,
    do: [
      {Item,
       [
         item_group: 1,
         item_separator: 1,
         item_media: 1,
         item_content: 1,
         item_title: 1,
         item_description: 1,
         item_actions: 1,
         item_header: 1,
         item_footer: 1
       ]},
      {Avatar, [avatar: 1, avatar_image: 1, avatar_fallback: 1]},
      {Button, [button: 1]},
      {DropdownMenu, [dropdown_menu: 1, dropdown_menu_trigger: 1, dropdown_menu_content: 1, dropdown_menu_item: 1]},
      {Progress, [progress: 1]},
      {Spinner, [spinner: 1]},
      {SaladUI.Helpers, [as_child: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :demo,
        template: """
        <div class="flex w-full max-w-md flex-col gap-6">
          <.item variant="outline">
            <.item_content>
              <.item_title>Basic Item</.item_title>
              <.item_description>A simple item with title and description.</.item_description>
            </.item_content>
            <.item_actions>
              <.button variant="outline" size="sm">Action</.button>
            </.item_actions>
          </.item>
          <.item variant="outline" size="sm" href="#">
            <.item_media>
              <Lucideicons.badge_check class="size-5" />
            </.item_media>
            <.item_content>
              <.item_title>Your profile has been verified.</.item_title>
            </.item_content>
            <.item_actions>
              <Lucideicons.chevron_right class="size-4" />
            </.item_actions>
          </.item>
        </div>
        """
      },
      %Variation{
        id: :variant,
        description: "`variant`: default, outline or muted.",
        template: """
        <div class="flex flex-col gap-6">
          <.item>
            <.item_content>
              <.item_title>Default Variant</.item_title>
              <.item_description>Standard styling with subtle background and borders.</.item_description>
            </.item_content>
            <.item_actions><.button variant="outline" size="sm">Open</.button></.item_actions>
          </.item>
          <.item variant="outline">
            <.item_content>
              <.item_title>Outline Variant</.item_title>
              <.item_description>Outlined style with clear borders and transparent background.</.item_description>
            </.item_content>
            <.item_actions><.button variant="outline" size="sm">Open</.button></.item_actions>
          </.item>
          <.item variant="muted">
            <.item_content>
              <.item_title>Muted Variant</.item_title>
              <.item_description>Subdued appearance with muted colors for secondary content.</.item_description>
            </.item_content>
            <.item_actions><.button variant="outline" size="sm">Open</.button></.item_actions>
          </.item>
        </div>
        """
      },
      %Variation{
        id: :size,
        description: "`size`: default, sm or xs.",
        template: """
        <div class="flex w-full max-w-md flex-col gap-6">
          <.item variant="outline">
            <.item_content>
              <.item_title>Basic Item</.item_title>
              <.item_description>A simple item with title and description.</.item_description>
            </.item_content>
            <.item_actions><.button variant="outline" size="sm">Action</.button></.item_actions>
          </.item>
          <.item variant="outline" size="sm" href="#">
            <.item_media><Lucideicons.badge_check class="size-5" /></.item_media>
            <.item_content><.item_title>Your profile has been verified.</.item_title></.item_content>
            <.item_actions><Lucideicons.chevron_right class="size-4" /></.item_actions>
          </.item>
          <.item variant="outline" size="xs" href="#">
            <.item_media><Lucideicons.badge_check class="size-4" /></.item_media>
            <.item_content><.item_title>Extra small item.</.item_title></.item_content>
            <.item_actions><Lucideicons.chevron_right class="size-4" /></.item_actions>
          </.item>
        </div>
        """
      },
      %Variation{
        id: :icon,
        description: ~s|`item_media variant="icon"` displays an icon.|,
        template: """
        <div class="flex w-full max-w-lg flex-col gap-6">
          <.item variant="outline">
            <.item_media variant="icon">
              <Lucideicons.shield_alert />
            </.item_media>
            <.item_content>
              <.item_title>Security Alert</.item_title>
              <.item_description>New login detected from unknown device.</.item_description>
            </.item_content>
            <.item_actions>
              <.button size="sm" variant="outline">Review</.button>
            </.item_actions>
          </.item>
        </div>
        """
      },
      %Variation{
        id: :avatar,
        template: """
        <div class="flex w-full max-w-lg flex-col gap-6">
          <.item variant="outline">
            <.item_media>
              <.avatar class="size-10">
                <.avatar_image src="https://github.com/evilrabbit.png" />
                <.avatar_fallback>ER</.avatar_fallback>
              </.avatar>
            </.item_media>
            <.item_content>
              <.item_title>Evil Rabbit</.item_title>
              <.item_description>Last seen 5 months ago</.item_description>
            </.item_content>
            <.item_actions>
              <.button size="icon-sm" variant="outline" class="rounded-full" aria-label="Invite">
                <Lucideicons.plus />
              </.button>
            </.item_actions>
          </.item>
          <.item variant="outline">
            <.item_media>
              <div class="flex -space-x-2 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background *:data-[slot=avatar]:grayscale">
                <.avatar class="hidden sm:flex">
                  <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
                  <.avatar_fallback>CN</.avatar_fallback>
                </.avatar>
                <.avatar class="hidden sm:flex">
                  <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
                  <.avatar_fallback>LR</.avatar_fallback>
                </.avatar>
                <.avatar>
                  <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
                  <.avatar_fallback>ER</.avatar_fallback>
                </.avatar>
              </div>
            </.item_media>
            <.item_content>
              <.item_title>No Team Members</.item_title>
              <.item_description>Invite your team to collaborate on this project.</.item_description>
            </.item_content>
            <.item_actions>
              <.button size="sm" variant="outline">Invite</.button>
            </.item_actions>
          </.item>
        </div>
        """
      },
      %Variation{
        id: :image,
        description: ~s|`item_media variant="image"` crops an image; a second `item_content` shrinks to fit.|,
        template: """
        <div class="flex w-full max-w-md flex-col gap-6">
          <.item_group class="gap-4">
            <.item
              :for={
                {title, artist, album, duration} <- [
                  {"Midnight City Lights", "Neon Dreams", "Electric Nights", "3:45"},
                  {"Coffee Shop Conversations", "The Morning Brew", "Urban Stories", "4:05"},
                  {"Digital Rain", "Cyber Symphony", "Binary Beats", "3:30"}
                ]
              }
              variant="outline"
              href="#"
              role="listitem"
            >
              <.item_media variant="image">
                <img src={"https://avatar.vercel.sh/" <> title} alt={title} width="32" height="32" class="object-cover grayscale" />
              </.item_media>
              <.item_content>
                <.item_title class="line-clamp-1">
                  {title} - <span class="text-muted-foreground">{album}</span>
                </.item_title>
                <.item_description>{artist}</.item_description>
              </.item_content>
              <.item_content class="flex-none text-center">
                <.item_description>{duration}</.item_description>
              </.item_content>
            </.item>
          </.item_group>
        </div>
        """
      },
      %Variation{
        id: :group,
        description: "`item_group` with `item_separator` between items.",
        template: """
        <div class="flex w-full max-w-md flex-col gap-6">
          <.item_group>
            <%= for {{username, email}, index} <- Enum.with_index([{"shadcn", "shadcn@vercel.com"}, {"maxleiter", "maxleiter@vercel.com"}, {"evilrabbit", "evilrabbit@vercel.com"}]) do %>
              <.item>
                <.item_media>
                  <.avatar>
                    <.avatar_image src={"https://github.com/" <> username <> ".png"} class="grayscale" />
                    <.avatar_fallback>{String.first(username)}</.avatar_fallback>
                  </.avatar>
                </.item_media>
                <.item_content class="gap-1">
                  <.item_title>{username}</.item_title>
                  <.item_description>{email}</.item_description>
                </.item_content>
                <.item_actions>
                  <.button variant="ghost" size="icon" class="rounded-full" aria-label="Add">
                    <Lucideicons.plus />
                  </.button>
                </.item_actions>
              </.item>
              <.item_separator :if={index != 2} />
            <% end %>
          </.item_group>
        </div>
        """
      },
      %Variation{
        id: :header,
        description: "`item_header` adds a full-width row above the content.",
        template: """
        <div class="flex w-full max-w-xl flex-col gap-6">
          <.item_group class="grid grid-cols-3 gap-4">
            <.item
              :for={
                {name, description, image} <- [
                  {"v0-1.5-sm", "Everyday tasks and UI generation.", "https://images.unsplash.com/photo-1650804068570-7fb2e3dbf888?q=80&w=640&auto=format&fit=crop"},
                  {"v0-1.5-lg", "Advanced thinking or reasoning.", "https://images.unsplash.com/photo-1610280777472-54133d004c8c?q=80&w=640&auto=format&fit=crop"},
                  {"v0-2.0-mini", "Open Source model for everyone.", "https://images.unsplash.com/photo-1602146057681-08560aee8cde?q=80&w=640&auto=format&fit=crop"}
                ]
              }
              variant="outline"
            >
              <.item_header>
                <img src={image} alt={name} width="128" height="128" class="aspect-square w-full rounded-sm object-cover" />
              </.item_header>
              <.item_content>
                <.item_title>{name}</.item_title>
                <.item_description>{description}</.item_description>
              </.item_content>
            </.item>
          </.item_group>
        </div>
        """
      },
      %Variation{
        id: :link,
        description: "`href`, `navigate` or `patch` render the item as an `<a>` with hover and focus styles.",
        template: """
        <div class="flex w-full max-w-md flex-col gap-4">
          <.item href="#">
            <.item_content>
              <.item_title>Visit our documentation</.item_title>
              <.item_description>Learn how to get started with our components.</.item_description>
            </.item_content>
            <.item_actions><Lucideicons.chevron_right class="size-4" /></.item_actions>
          </.item>
          <.item variant="outline" href="#" target="_blank" rel="noopener noreferrer">
            <.item_content>
              <.item_title>External resource</.item_title>
              <.item_description>Opens in a new tab with security attributes.</.item_description>
            </.item_content>
            <.item_actions><Lucideicons.external_link class="size-4" /></.item_actions>
          </.item>
        </div>
        """
      },
      %Variation{
        id: :dropdown,
        template: """
        <div class="flex min-h-64 w-full max-w-md flex-col items-center gap-6">
          <.dropdown_menu id="item-dropdown">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline" size="sm" class="w-fit">
              Select <Lucideicons.chevron_down />
            </.as_child>
            <.dropdown_menu_content class="w-72 [--radius:0.65rem]" align="end">
              <.dropdown_menu_item
                :for={
                  {username, email} <- [
                    {"shadcn", "shadcn@vercel.com"},
                    {"maxleiter", "maxleiter@vercel.com"},
                    {"evilrabbit", "evilrabbit@vercel.com"}
                  ]
                }
                class="p-0"
              >
                <.item size="sm" class="w-full p-2">
                  <.item_media>
                    <.avatar class="size-8">
                      <.avatar_image src={"https://github.com/" <> username <> ".png"} class="grayscale" />
                      <.avatar_fallback>{String.first(username)}</.avatar_fallback>
                    </.avatar>
                  </.item_media>
                  <.item_content class="gap-0.5">
                    <.item_title>{username}</.item_title>
                    <.item_description>{email}</.item_description>
                  </.item_content>
                </.item>
              </.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :footer_with_spinner,
        description: "`item_footer` adds a full-width row below the content.",
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
