defmodule Storybook.SaladUIComponents.Separator do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Separator.separator/1

  def variations do
    [
      %Variation{
        id: :separator,
        description: "shadcn separator-demo.",
        template: """
        <div class="flex max-w-sm flex-col gap-4 text-sm">
          <div class="flex flex-col gap-1.5">
            <div class="leading-none font-medium">shadcn/ui</div>
            <div class="text-muted-foreground">The Foundation for your Design System</div>
          </div>
          <.separator />
          <div>
            A set of beautifully designed components that you can customize, extend, and build on.
          </div>
        </div>
        """
      },
      %Variation{
        id: :separator_vertical,
        description: "shadcn separator-vertical.",
        template: """
        <div class="flex h-5 items-center gap-4 text-sm">
          <div>Blog</div>
          <.separator orientation="vertical" />
          <div>Docs</div>
          <.separator orientation="vertical" />
          <div>Source</div>
        </div>
        """
      },
      %Variation{
        id: :separator_menu,
        description:
          "shadcn separator-menu. The row is `items-center`, so the vertical separators add `self-stretch` to span its height.",
        template: """
        <div class="flex items-center gap-2 text-sm md:gap-4">
          <div class="flex flex-col gap-1">
            <span class="font-medium">Settings</span>
            <span class="text-xs text-muted-foreground">Manage preferences</span>
          </div>
          <.separator orientation="vertical" class="self-stretch" />
          <div class="flex flex-col gap-1">
            <span class="font-medium">Account</span>
            <span class="text-xs text-muted-foreground">Profile & security</span>
          </div>
          <.separator orientation="vertical" class="hidden self-stretch md:block" />
          <div class="hidden flex-col gap-1 md:flex">
            <span class="font-medium">Help</span>
            <span class="text-xs text-muted-foreground">Support & docs</span>
          </div>
        </div>
        """
      },
      %Variation{
        id: :separator_list,
        description: "shadcn separator-list.",
        template: """
        <div class="flex w-full max-w-sm flex-col gap-2 text-sm">
          <dl class="flex items-center justify-between">
            <dt>Item 1</dt>
            <dd class="text-muted-foreground">Value 1</dd>
          </dl>
          <.separator />
          <dl class="flex items-center justify-between">
            <dt>Item 2</dt>
            <dd class="text-muted-foreground">Value 2</dd>
          </dl>
          <.separator />
          <dl class="flex items-center justify-between">
            <dt>Item 3</dt>
            <dd class="text-muted-foreground">Value 3</dd>
          </dl>
        </div>
        """
      },
      %Variation{
        id: :semantic,
        description: "`decorative={false}` renders `role=\"separator\"` for assistive technology.",
        template: """
        <div class="flex h-5 items-center gap-4 text-sm">
          <div>Previous</div>
          <.separator orientation="vertical" decorative={false} />
          <div>Next</div>
        </div>
        """
      }
    ]
  end
end
