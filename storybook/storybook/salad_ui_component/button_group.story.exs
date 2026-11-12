defmodule Storybook.SaladUIComponents.ButtonGroup do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.ButtonGroup

  def function, do: &ButtonGroup.button_group/1

  def imports,
    do: [
      {ButtonGroup, [button_group_separator: 1, button_group_text: 1]},
      {SaladUI.Button, [button: 1]},
      {SaladUI.DropdownMenu,
       [
         dropdown_menu: 1,
         dropdown_menu_trigger: 1,
         dropdown_menu_content: 1,
         dropdown_menu_group: 1,
         dropdown_menu_item: 1,
         dropdown_menu_separator: 1,
         dropdown_menu_radio_group: 1,
         dropdown_menu_radio_item: 1,
         dropdown_menu_sub: 1,
         dropdown_menu_sub_trigger: 1,
         dropdown_menu_sub_content: 1
       ]},
      {SaladUI.Input, [input: 1]},
      {SaladUI.InputGroup, [input_group: 1, input_group_addon: 1, input_group_button: 1, input_group_input: 1]},
      {SaladUI.Popover, [popover: 1, popover_trigger: 1, popover_content: 1]},
      {SaladUI.Select, [select: 1, select_trigger: 1, select_value: 1, select_content: 1, select_item: 1]},
      {SaladUI.Separator, [separator: 1]},
      {SaladUI.Textarea, [textarea: 1]},
      {SaladUI.Tooltip, [tooltip: 1, tooltip_trigger: 1, tooltip_content: 1]},
      {SaladUI.Helpers, [as_child: 1]}
    ]

  def description do
    """
    A container that groups related buttons together with consistent styling.
    Use `button_group` for actions and `toggle_group` for toggling state.
    """
  end

  def variations do
    [
      %Variation{
        id: :demo,
        template: """
        <.button_group aria-label="Message actions">
          <.button_group class="hidden sm:flex">
            <.button variant="outline" size="icon" aria-label="Go Back">
              <Lucideicons.arrow_left />
            </.button>
          </.button_group>
          <.button_group>
            <.button variant="outline">Archive</.button>
            <.button variant="outline">Report</.button>
          </.button_group>
          <.button_group>
            <.button variant="outline">Snooze</.button>
            <.dropdown_menu id="bg-demo-more">
              <.as_child
                tag={&dropdown_menu_trigger/1}
                child={&button/1}
                variant="outline"
                size="icon"
                aria-label="More Options"
              >
                <Lucideicons.ellipsis />
              </.as_child>
              <.dropdown_menu_content align="end" class="w-52">
                <.dropdown_menu_group>
                  <.dropdown_menu_item><Lucideicons.mail_check /> Mark as Read</.dropdown_menu_item>
                  <.dropdown_menu_item><Lucideicons.archive /> Archive</.dropdown_menu_item>
                </.dropdown_menu_group>
                <.dropdown_menu_separator />
                <.dropdown_menu_group>
                  <.dropdown_menu_item><Lucideicons.clock /> Snooze</.dropdown_menu_item>
                  <.dropdown_menu_item><Lucideicons.calendar_plus /> Add to Calendar</.dropdown_menu_item>
                  <.dropdown_menu_item><Lucideicons.list_filter /> Add to List</.dropdown_menu_item>
                  <.dropdown_menu_sub>
                    <.dropdown_menu_sub_trigger><Lucideicons.tag /> Label As...</.dropdown_menu_sub_trigger>
                    <.dropdown_menu_sub_content>
                      <.dropdown_menu_radio_group value="personal">
                        <.dropdown_menu_radio_item value="personal">Personal</.dropdown_menu_radio_item>
                        <.dropdown_menu_radio_item value="work">Work</.dropdown_menu_radio_item>
                        <.dropdown_menu_radio_item value="other">Other</.dropdown_menu_radio_item>
                      </.dropdown_menu_radio_group>
                    </.dropdown_menu_sub_content>
                  </.dropdown_menu_sub>
                </.dropdown_menu_group>
                <.dropdown_menu_separator />
                <.dropdown_menu_group>
                  <.dropdown_menu_item variant="destructive"><Lucideicons.trash_2 /> Trash</.dropdown_menu_item>
                </.dropdown_menu_group>
              </.dropdown_menu_content>
            </.dropdown_menu>
          </.button_group>
        </.button_group>
        """
      },
      %Variation{
        id: :orientation,
        description: ~s|`orientation="vertical"` stacks the buttons.|,
        template: """
        <.button_group orientation="vertical" aria-label="Media controls" class="h-fit">
          <.button variant="outline" size="icon" aria-label="Increase"><Lucideicons.plus /></.button>
          <.button variant="outline" size="icon" aria-label="Decrease"><Lucideicons.minus /></.button>
        </.button_group>
        """
      },
      %Variation{
        id: :size,
        description: "Size the buttons themselves with `size`.",
        template: """
        <div class="flex flex-col items-start gap-8">
          <.button_group>
            <.button variant="outline" size="sm">Small</.button>
            <.button variant="outline" size="sm">Button</.button>
            <.button variant="outline" size="sm">Group</.button>
            <.button variant="outline" size="icon-sm" aria-label="Add"><Lucideicons.plus /></.button>
          </.button_group>
          <.button_group>
            <.button variant="outline">Default</.button>
            <.button variant="outline">Button</.button>
            <.button variant="outline">Group</.button>
            <.button variant="outline" size="icon" aria-label="Add"><Lucideicons.plus /></.button>
          </.button_group>
          <.button_group>
            <.button variant="outline" size="lg">Large</.button>
            <.button variant="outline" size="lg">Button</.button>
            <.button variant="outline" size="lg">Group</.button>
            <.button variant="outline" size="icon-lg" aria-label="Add"><Lucideicons.plus /></.button>
          </.button_group>
        </div>
        """
      },
      %Variation{
        id: :nested,
        description: "Nested button groups are spaced apart.",
        template: """
        <.button_group>
          <.button_group>
            <.button variant="outline" size="sm">1</.button>
            <.button variant="outline" size="sm">2</.button>
            <.button variant="outline" size="sm">3</.button>
            <.button variant="outline" size="sm">4</.button>
            <.button variant="outline" size="sm">5</.button>
          </.button_group>
          <.button_group>
            <.button variant="outline" size="icon-sm" aria-label="Previous"><Lucideicons.arrow_left /></.button>
            <.button variant="outline" size="icon-sm" aria-label="Next"><Lucideicons.arrow_right /></.button>
          </.button_group>
        </.button_group>
        """
      },
      %Variation{
        id: :separator,
        description: "`button_group_separator` divides buttons that have no border of their own.",
        template: """
        <.button_group>
          <.button variant="secondary" size="sm">Copy</.button>
          <.button_group_separator />
          <.button variant="secondary" size="sm">Paste</.button>
        </.button_group>
        """
      },
      %Variation{
        id: :split,
        template: """
        <.button_group>
          <.button variant="secondary">Button</.button>
          <.button_group_separator />
          <.button size="icon" variant="secondary" aria-label="Add"><Lucideicons.plus /></.button>
        </.button_group>
        """
      },
      %Variation{
        id: :input,
        template: """
        <.button_group>
          <.input placeholder="Search..." />
          <.button variant="outline" aria-label="Search"><Lucideicons.search /></.button>
        </.button_group>
        """
      },
      %Variation{
        id: :input_group,
        template: """
        <.button_group class="[--radius:9999rem]">
          <.button_group>
            <.button variant="outline" size="icon" aria-label="Add"><Lucideicons.plus /></.button>
          </.button_group>
          <.button_group>
            <.input_group id="bg-input-group">
              <.input_group_input placeholder="Send a message..." />
              <.input_group_addon align="inline-end">
                <.tooltip id="bg-voice-tooltip">
                  <.tooltip_trigger>
                    <.input_group_button
                      size="icon-xs"
                      aria-label="Voice Mode"
                      aria-pressed="false"
                      class="aria-pressed:bg-orange-100 aria-pressed:text-orange-700 dark:aria-pressed:bg-orange-800 dark:aria-pressed:text-orange-100"
                      phx-click={Phoenix.LiveView.JS.toggle_attribute({"aria-pressed", "true", "false"})}
                    >
                      <Lucideicons.audio_lines />
                    </.input_group_button>
                  </.tooltip_trigger>
                  <.tooltip_content>Voice Mode</.tooltip_content>
                </.tooltip>
              </.input_group_addon>
            </.input_group>
          </.button_group>
        </.button_group>
        """
      },
      %Variation{
        id: :dropdown_menu,
        description:
          "A split button with a dropdown menu. The group joins the trigger inside the dropdown's root element.",
        template: """
        <.button_group>
          <.button variant="outline">Follow</.button>
          <.dropdown_menu id="bg-dropdown">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline" class="pl-2!" aria-label="More">
              <Lucideicons.chevron_down />
            </.as_child>
            <.dropdown_menu_content align="end">
              <.dropdown_menu_group>
                <.dropdown_menu_item><Lucideicons.volume_off /> Mute Conversation</.dropdown_menu_item>
                <.dropdown_menu_item><Lucideicons.check /> Mark as Read</.dropdown_menu_item>
                <.dropdown_menu_item><Lucideicons.triangle_alert /> Report Conversation</.dropdown_menu_item>
                <.dropdown_menu_item><Lucideicons.user_round_x /> Block User</.dropdown_menu_item>
                <.dropdown_menu_item><Lucideicons.share /> Share Conversation</.dropdown_menu_item>
                <.dropdown_menu_item><Lucideicons.copy /> Copy Conversation</.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_group>
                <.dropdown_menu_item variant="destructive"><Lucideicons.trash_2 /> Delete Conversation</.dropdown_menu_item>
              </.dropdown_menu_group>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </.button_group>
        """
      },
      %Variation{
        id: :select,
        template: """
        <.button_group>
          <.button_group>
            <.select id="bg-currency" name="currency" value="$">
              <.select_trigger class="font-mono">
                <.select_value placeholder="$" />
              </.select_trigger>
              <.select_content class="min-w-24">
                <.select_item value="$">$ <span class="text-muted-foreground">US Dollar</span></.select_item>
                <.select_item value="€">€ <span class="text-muted-foreground">Euro</span></.select_item>
                <.select_item value="£">£ <span class="text-muted-foreground">British Pound</span></.select_item>
              </.select_content>
            </.select>
            <.input placeholder="10.00" pattern="[0-9]*" />
          </.button_group>
          <.button_group>
            <.button aria-label="Send" size="icon" variant="outline"><Lucideicons.arrow_right /></.button>
          </.button_group>
        </.button_group>
        """
      },
      %Variation{
        id: :popover,
        template: """
        <.button_group>
          <.button variant="outline"><Lucideicons.bot /> Copilot</.button>
          <.popover id="bg-popover">
            <.as_child tag={&popover_trigger/1} child={&button/1} variant="outline" size="icon" aria-label="Open Popover">
              <Lucideicons.chevron_down />
            </.as_child>
            <.popover_content align="end" class="rounded-xl p-0 text-sm">
              <div class="px-4 py-3">
                <div class="text-sm font-medium">Agent Tasks</div>
              </div>
              <.separator />
              <div class="p-4 text-sm *:[p:not(:last-child)]:mb-2">
                <.textarea placeholder="Describe your task in natural language." class="mb-4 resize-none" />
                <p class="font-medium">Start a new task with Copilot</p>
                <p class="text-muted-foreground">
                  Describe your task in natural language. Copilot will work in the
                  background and open a pull request for your review.
                </p>
              </div>
            </.popover_content>
          </.popover>
        </.button_group>
        """
      },
      %Variation{
        id: :text,
        description: ~s|`button_group_text` adds text; `as="label"` labels an input (shadcn's `asChild` + `Label`).|,
        template: """
        <div class="grid gap-6">
          <.button_group>
            <.button_group_text>Text</.button_group_text>
            <.button variant="outline">Button</.button>
          </.button_group>
          <.button_group>
            <.button_group_text as="label" for="bg-text-name">Text</.button_group_text>
            <.input placeholder="Type something here..." id="bg-text-name" />
          </.button_group>
        </div>
        """
      }
    ]
  end
end
