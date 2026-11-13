defmodule Storybook.SaladUIComponents.Avatar do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Avatar
  alias SaladUI.Button
  alias SaladUI.DropdownMenu

  def function, do: &Avatar.avatar/1

  def imports,
    do: [
      {Avatar, [avatar_image: 1, avatar_fallback: 1, avatar_badge: 1, avatar_group: 1, avatar_group_count: 1]},
      {Button, [button: 1]},
      {DropdownMenu,
       [
         dropdown_menu: 1,
         dropdown_menu_trigger: 1,
         dropdown_menu_content: 1,
         dropdown_menu_group: 1,
         dropdown_menu_item: 1,
         dropdown_menu_separator: 1
       ]},
      {SaladUI.Helpers, [as_child: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :avatar_image,
        template: """
        <.avatar>
        <.avatar_image src="https://github.com/shadcn.png" />
        <.avatar_fallback class="bg-primary text-white">CN</.avatar_fallback>
        </.avatar>
        """
      },
      %Variation{
        id: :avatar_fallback,
        template: """
        <.avatar>
        <.avatar_image src="http://example.com/badimage.png" />
        <.avatar_fallback class="bg-primary text-white">CN</.avatar_fallback>
        </.avatar>
        """
      },
      %Variation{
        id: :demo,
        template: """
        <div class="flex flex-row flex-wrap items-center gap-6 md:gap-12">
          <.avatar>
            <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" class="grayscale" />
            <.avatar_fallback>CN</.avatar_fallback>
          </.avatar>
          <.avatar>
            <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
            <.avatar_fallback>ER</.avatar_fallback>
            <.avatar_badge class="bg-green-600 dark:bg-green-800" />
          </.avatar>
          <.avatar_group class="grayscale">
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
            <.avatar_group_count>+3</.avatar_group_count>
          </.avatar_group>
        </div>
        """
      },
      %Variation{
        id: :sizes,
        description: ~s|`size="sm"`, `"default"` and `"lg"`.|,
        template: """
        <div class="flex flex-wrap items-center gap-2 grayscale">
          <.avatar :for={size <- ~w(sm default lg)} size={size}>
            <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
            <.avatar_fallback>CN</.avatar_fallback>
          </.avatar>
        </div>
        """
      },
      %Variation{
        id: :badge,
        template: """
        <div class="flex items-center gap-6">
          <.avatar>
            <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
            <.avatar_fallback>CN</.avatar_fallback>
            <.avatar_badge class="bg-green-600 dark:bg-green-800" />
          </.avatar>
          <.avatar :for={size <- ~w(sm lg)} size={size}>
            <.avatar_fallback>CN</.avatar_fallback>
            <.avatar_badge class="bg-green-600 dark:bg-green-800" />
          </.avatar>
        </div>
        """
      },
      %Variation{
        id: :badge_with_icon,
        template: """
        <.avatar class="grayscale">
          <.avatar_image src="https://github.com/pranathip.png" alt="@pranathip" />
          <.avatar_fallback>PP</.avatar_fallback>
          <.avatar_badge>
            <Lucideicons.plus />
          </.avatar_badge>
        </.avatar>
        """
      },
      %Variation{
        id: :group,
        template: """
        <.avatar_group class="grayscale">
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
        </.avatar_group>
        """
      },
      %Variation{
        id: :group_count,
        description: "The count bubble matches the size of the avatars in the group.",
        template: """
        <div class="flex flex-col gap-4">
          <.avatar_group :for={size <- ~w(sm default lg)} class="grayscale">
            <.avatar size={size}>
              <.avatar_image src="https://github.com/shadcn.png" alt="@shadcn" />
              <.avatar_fallback>CN</.avatar_fallback>
            </.avatar>
            <.avatar size={size}>
              <.avatar_image src="https://github.com/maxleiter.png" alt="@maxleiter" />
              <.avatar_fallback>LR</.avatar_fallback>
            </.avatar>
            <.avatar size={size}>
              <.avatar_image src="https://github.com/evilrabbit.png" alt="@evilrabbit" />
              <.avatar_fallback>ER</.avatar_fallback>
            </.avatar>
            <.avatar_group_count>+3</.avatar_group_count>
          </.avatar_group>
        </div>
        """
      },
      %Variation{
        id: :group_count_with_icon,
        template: """
        <.avatar_group class="grayscale">
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
          <.avatar_group_count>
            <Lucideicons.plus />
          </.avatar_group_count>
        </.avatar_group>
        """
      },
      %Variation{
        id: :dropdown,
        template: """
        <div class="flex justify-center p-24">
          <.dropdown_menu id="avatar-dropdown">
            <.as_child
              tag={&dropdown_menu_trigger/1}
              child={&button/1}
              variant="ghost"
              size="icon"
              class="rounded-full"
            >
              <.avatar>
                <.avatar_image src="https://github.com/shadcn.png" alt="shadcn" />
                <.avatar_fallback>CN</.avatar_fallback>
              </.avatar>
            </.as_child>
            <.dropdown_menu_content class="w-32">
              <.dropdown_menu_group>
                <.dropdown_menu_item>Profile</.dropdown_menu_item>
                <.dropdown_menu_item>Billing</.dropdown_menu_item>
                <.dropdown_menu_item>Settings</.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_group>
                <.dropdown_menu_item variant="destructive">Log out</.dropdown_menu_item>
              </.dropdown_menu_group>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      }
    ]
  end
end
