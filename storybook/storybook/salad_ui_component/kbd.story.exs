defmodule Storybook.SaladUIComponents.Kbd do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Button
  alias SaladUI.Input
  alias SaladUI.Kbd
  alias SaladUI.Tooltip

  def function, do: &Kbd.kbd/1

  def imports,
    do: [
      {Kbd, [kbd_group: 1]},
      {Button, [button: 1]},
      {Input, [input: 1]},
      {Tooltip, [tooltip: 1, tooltip_trigger: 1, tooltip_content: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :default,
        slots: ["Ctrl"]
      },
      %Variation{
        id: :demo,
        template: """
        <div class="flex flex-col items-center gap-4">
          <.kbd_group>
            <.kbd>⌘</.kbd>
            <.kbd>⇧</.kbd>
            <.kbd>⌥</.kbd>
            <.kbd>⌃</.kbd>
          </.kbd_group>
          <.kbd_group>
            <.kbd>Ctrl</.kbd>
            <span>+</span>
            <.kbd>B</.kbd>
          </.kbd_group>
        </div>
        """
      },
      %Variation{
        id: :group,
        description: "`kbd_group` groups keys together.",
        template: """
        <div class="flex flex-col items-center gap-4">
          <p class="text-sm text-muted-foreground">
            Use <.kbd_group><.kbd>Ctrl + B</.kbd><.kbd>Ctrl + K</.kbd></.kbd_group> to open the command palette
          </p>
        </div>
        """
      },
      %Variation{
        id: :button,
        template: """
        <div class="flex flex-wrap items-center gap-4">
          <.button variant="outline" size="sm" class="pr-2">
            Accept <.kbd>⏎</.kbd>
          </.button>
          <.button variant="outline" size="sm" class="pr-2">
            Cancel <.kbd>Esc</.kbd>
          </.button>
        </div>
        """
      },
      %Variation{
        id: :tooltip,
        description: "Inside `tooltip_content` keys switch to a translucent style.",
        template: """
        <div class="flex flex-wrap gap-4 py-12">
          <div class="flex">
            <.tooltip id="kbd-tooltip-save">
              <.tooltip_trigger>
                <.button size="sm" variant="outline" class="rounded-r-none">Save</.button>
              </.tooltip_trigger>
              <.tooltip_content>
                Save Changes <.kbd>S</.kbd>
              </.tooltip_content>
            </.tooltip>
            <.tooltip id="kbd-tooltip-print">
              <.tooltip_trigger>
                <.button size="sm" variant="outline" class="-ml-px rounded-l-none">Print</.button>
              </.tooltip_trigger>
              <.tooltip_content>
                Print Document <.kbd_group><.kbd>Ctrl</.kbd><.kbd>P</.kbd></.kbd_group>
              </.tooltip_content>
            </.tooltip>
          </div>
        </div>
        """
      },
      %Variation{
        id: :input_group,
        description: "SaladUI has no `input_group` yet; the search field is composed from `input` and positioned keys.",
        template: """
        <div class="flex w-full max-w-xs flex-col gap-6">
          <div class="relative">
            <Lucideicons.search class="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
            <.input id="kbd-search" name="q" placeholder="Search..." class="pr-16 pl-9" />
            <div class="absolute top-1/2 right-3 flex -translate-y-1/2 gap-1">
              <.kbd>⌘</.kbd>
              <.kbd>K</.kbd>
            </div>
          </div>
        </div>
        """
      }
    ]
  end
end
