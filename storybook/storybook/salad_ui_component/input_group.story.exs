defmodule Storybook.SaladUIComponents.InputGroup do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.InputGroup

  def function, do: &InputGroup.input_group/1

  def imports,
    do: [
      {InputGroup,
       [input_group_addon: 1, input_group_button: 1, input_group_text: 1, input_group_input: 1, input_group_textarea: 1]},
      {SaladUI.ButtonGroup, [button_group: 1, button_group_text: 1]},
      {SaladUI.DropdownMenu,
       [dropdown_menu: 1, dropdown_menu_trigger: 1, dropdown_menu_content: 1, dropdown_menu_item: 1]},
      {SaladUI.Kbd, [kbd: 1]},
      {SaladUI.Label, [label: 1]},
      {SaladUI.Popover, [popover: 1, popover_trigger: 1, popover_content: 1]},
      {SaladUI.Separator, [separator: 1]},
      {SaladUI.Spinner, [spinner: 1]},
      {SaladUI.Tooltip, [tooltip: 1, tooltip_trigger: 1, tooltip_content: 1]},
      {SaladUI.Helpers, [as_child: 1]}
    ]

  def description do
    """
    Add addons, buttons, and helper content to inputs. Place addons after the
    control and position them with `align`; clicking an addon focuses the control.
    """
  end

  def variations do
    [
      %Variation{
        id: :demo,
        template: """
        <div class="grid w-full max-w-sm gap-6">
          <.input_group id="ig-demo-search">
            <.input_group_input placeholder="Search..." />
            <.input_group_addon>
              <Lucideicons.search />
            </.input_group_addon>
            <.input_group_addon align="inline-end">12 results</.input_group_addon>
          </.input_group>
          <.input_group id="ig-demo-url">
            <.input_group_input placeholder="example.com" class="pl-1!" />
            <.input_group_addon>
              <.input_group_text>https://</.input_group_text>
            </.input_group_addon>
            <.input_group_addon align="inline-end">
              <.tooltip id="ig-demo-tooltip">
                <.tooltip_trigger>
                  <.input_group_button class="rounded-full" size="icon-xs" aria-label="Info">
                    <Lucideicons.info />
                  </.input_group_button>
                </.tooltip_trigger>
                <.tooltip_content>This is content in a tooltip.</.tooltip_content>
              </.tooltip>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-demo-chat">
            <.input_group_textarea placeholder="Ask, Search or Chat..." />
            <.input_group_addon align="block-end">
              <.input_group_button variant="outline" class="rounded-full" size="icon-xs" aria-label="Add">
                <Lucideicons.plus />
              </.input_group_button>
              <.dropdown_menu id="ig-demo-mode">
                <.as_child tag={&dropdown_menu_trigger/1} child={&input_group_button/1} variant="ghost">
                  Auto
                </.as_child>
                <.dropdown_menu_content side="top" align="start">
                  <.dropdown_menu_item>Auto</.dropdown_menu_item>
                  <.dropdown_menu_item>Agent</.dropdown_menu_item>
                  <.dropdown_menu_item>Manual</.dropdown_menu_item>
                </.dropdown_menu_content>
              </.dropdown_menu>
              <.input_group_text class="ml-auto">52% used</.input_group_text>
              <.separator orientation="vertical" class="h-4!" />
              <.input_group_button variant="default" class="rounded-full" size="icon-xs" disabled>
                <Lucideicons.arrow_up />
                <span class="sr-only">Send</span>
              </.input_group_button>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-demo-handle">
            <.input_group_input placeholder="@shadcn" />
            <.input_group_addon align="inline-end">
              <div class="flex size-4 items-center justify-center rounded-full bg-primary text-primary-foreground">
                <Lucideicons.check class="size-3" />
              </div>
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :inline_start,
        description: ~s|`align="inline-start"` (the default) puts the addon before the input.|,
        template: """
        <div class="grid max-w-sm gap-2">
          <.label for="inline-start-input">Input</.label>
          <.input_group id="ig-inline-start">
            <.input_group_input id="inline-start-input" placeholder="Search..." />
            <.input_group_addon align="inline-start">
              <Lucideicons.search class="text-muted-foreground" />
            </.input_group_addon>
          </.input_group>
          <p class="text-sm text-muted-foreground">Icon positioned at the start.</p>
        </div>
        """
      },
      %Variation{
        id: :inline_end,
        description: ~s|`align="inline-end"` puts the addon after the input.|,
        template: """
        <div class="grid max-w-sm gap-2">
          <.label for="inline-end-input">Input</.label>
          <.input_group id="ig-inline-end">
            <.input_group_input id="inline-end-input" type="password" placeholder="Enter password" />
            <.input_group_addon align="inline-end">
              <Lucideicons.eye_off />
            </.input_group_addon>
          </.input_group>
          <p class="text-sm text-muted-foreground">Icon positioned at the end.</p>
        </div>
        """
      },
      %Variation{
        id: :block_start,
        description: ~s|`align="block-start"` puts the addon above the input or textarea.|,
        template: """
        <div class="grid max-w-sm gap-6">
          <div class="grid gap-2">
            <.label for="block-start-input">Input</.label>
            <.input_group id="ig-block-start-input" class="h-auto">
              <.input_group_input id="block-start-input" placeholder="Enter your name" />
              <.input_group_addon align="block-start">
                <.input_group_text>Full Name</.input_group_text>
              </.input_group_addon>
            </.input_group>
            <p class="text-sm text-muted-foreground">Header positioned above the input.</p>
          </div>
          <div class="grid gap-2">
            <.label for="block-start-textarea">Textarea</.label>
            <.input_group id="ig-block-start-textarea">
              <.input_group_textarea
                id="block-start-textarea"
                placeholder="console.log('Hello, world!');"
                class="font-mono text-sm"
              />
              <.input_group_addon align="block-start">
                <Lucideicons.file_code class="text-muted-foreground" />
                <.input_group_text class="font-mono">script.js</.input_group_text>
                <.input_group_button size="icon-xs" class="ml-auto">
                  <Lucideicons.copy />
                  <span class="sr-only">Copy</span>
                </.input_group_button>
              </.input_group_addon>
            </.input_group>
            <p class="text-sm text-muted-foreground">Header positioned above the textarea.</p>
          </div>
        </div>
        """
      },
      %Variation{
        id: :block_end,
        description: ~s|`align="block-end"` puts the addon below the input or textarea.|,
        template: """
        <div class="grid max-w-sm gap-6">
          <div class="grid gap-2">
            <.label for="block-end-input">Input</.label>
            <.input_group id="ig-block-end-input" class="h-auto">
              <.input_group_input id="block-end-input" placeholder="Enter amount" />
              <.input_group_addon align="block-end">
                <.input_group_text>USD</.input_group_text>
              </.input_group_addon>
            </.input_group>
            <p class="text-sm text-muted-foreground">Footer positioned below the input.</p>
          </div>
          <div class="grid gap-2">
            <.label for="block-end-textarea">Textarea</.label>
            <.input_group id="ig-block-end-textarea">
              <.input_group_textarea id="block-end-textarea" placeholder="Write a comment..." />
              <.input_group_addon align="block-end">
                <.input_group_text>0/280</.input_group_text>
                <.input_group_button variant="default" size="sm" class="ml-auto">Post</.input_group_button>
              </.input_group_addon>
            </.input_group>
            <p class="text-sm text-muted-foreground">Footer positioned below the textarea.</p>
          </div>
        </div>
        """
      },
      %Variation{
        id: :icon,
        template: """
        <div class="grid w-full max-w-sm gap-6">
          <.input_group id="ig-icon-search">
            <.input_group_input placeholder="Search..." />
            <.input_group_addon>
              <Lucideicons.search />
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-icon-mail">
            <.input_group_input type="email" placeholder="Enter your email" />
            <.input_group_addon>
              <Lucideicons.mail />
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-icon-card">
            <.input_group_input placeholder="Card number" />
            <.input_group_addon>
              <Lucideicons.credit_card />
            </.input_group_addon>
            <.input_group_addon align="inline-end">
              <Lucideicons.check />
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-icon-two">
            <.input_group_input placeholder="Card number" />
            <.input_group_addon align="inline-end">
              <Lucideicons.star />
              <Lucideicons.info />
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :text,
        template: """
        <div class="grid w-full max-w-sm gap-6">
          <.input_group id="ig-text-amount">
            <.input_group_addon>
              <.input_group_text>$</.input_group_text>
            </.input_group_addon>
            <.input_group_input placeholder="0.00" />
            <.input_group_addon align="inline-end">
              <.input_group_text>USD</.input_group_text>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-text-url">
            <.input_group_addon>
              <.input_group_text>https://</.input_group_text>
            </.input_group_addon>
            <.input_group_input placeholder="example.com" class="pl-0.5!" />
            <.input_group_addon align="inline-end">
              <.input_group_text>.com</.input_group_text>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-text-username">
            <.input_group_input placeholder="Enter your username" />
            <.input_group_addon align="inline-end">
              <.input_group_text>@company.com</.input_group_text>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-text-message">
            <.input_group_textarea placeholder="Enter your message" />
            <.input_group_addon align="block-end">
              <.input_group_text class="text-xs text-muted-foreground">120 characters left</.input_group_text>
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :button,
        template: """
        <div class="grid w-full max-w-sm gap-6">
          <.input_group id="ig-button-copy">
            <.input_group_input placeholder="https://x.com/shadcn" readonly />
            <.input_group_addon align="inline-end">
              <.input_group_button aria-label="Copy" title="Copy" size="icon-xs">
                <Lucideicons.copy />
              </.input_group_button>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-button-secure" class="[--radius:9999px]">
            <.input_group_input id="input-secure-19" />
            <.input_group_addon>
              <.popover id="ig-button-popover">
                <.as_child
                  tag={&popover_trigger/1}
                  child={&input_group_button/1}
                  variant="secondary"
                  size="icon-xs"
                  aria-label="Connection info"
                >
                  <Lucideicons.info />
                </.as_child>
                <.popover_content align="start" class="flex flex-col gap-1 rounded-xl text-sm">
                  <p class="font-medium">Your connection is not secure.</p>
                  <p>You should not enter any sensitive information on this site.</p>
                </.popover_content>
              </.popover>
            </.input_group_addon>
            <.input_group_addon class="pl-1.5 text-muted-foreground">https://</.input_group_addon>
            <.input_group_addon align="inline-end">
              <.input_group_button
                size="icon-xs"
                aria-label="Favorite"
                aria-pressed="false"
                class="aria-pressed:[&_svg]:fill-blue-600 aria-pressed:[&_svg]:stroke-blue-600"
                phx-click={Phoenix.LiveView.JS.toggle_attribute({"aria-pressed", "true", "false"})}
              >
                <Lucideicons.star />
              </.input_group_button>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-button-search">
            <.input_group_input placeholder="Type to search..." />
            <.input_group_addon align="inline-end">
              <.input_group_button variant="secondary">Search</.input_group_button>
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :kbd,
        description: "Keyboard hints in an addon get a tighter radius and margin.",
        template: """
        <.input_group id="ig-kbd" class="max-w-sm">
          <.input_group_input placeholder="Search..." />
          <.input_group_addon>
            <Lucideicons.search class="text-muted-foreground" />
          </.input_group_addon>
          <.input_group_addon align="inline-end">
            <.kbd>⌘K</.kbd>
          </.input_group_addon>
        </.input_group>
        """
      },
      %Variation{
        id: :dropdown,
        template: """
        <div class="grid w-full max-w-sm gap-4">
          <.input_group id="ig-dropdown-file">
            <.input_group_input placeholder="Enter file name" />
            <.input_group_addon align="inline-end">
              <.dropdown_menu id="ig-dropdown-file-menu">
                <.as_child
                  tag={&dropdown_menu_trigger/1}
                  child={&input_group_button/1}
                  variant="ghost"
                  aria-label="More"
                  size="icon-xs"
                >
                  <Lucideicons.ellipsis />
                </.as_child>
                <.dropdown_menu_content align="end">
                  <.dropdown_menu_item>Settings</.dropdown_menu_item>
                  <.dropdown_menu_item>Copy path</.dropdown_menu_item>
                  <.dropdown_menu_item>Open location</.dropdown_menu_item>
                </.dropdown_menu_content>
              </.dropdown_menu>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-dropdown-search" class="[--radius:1rem]">
            <.input_group_input placeholder="Enter search query" />
            <.input_group_addon align="inline-end">
              <.dropdown_menu id="ig-dropdown-search-menu">
                <.as_child
                  tag={&dropdown_menu_trigger/1}
                  child={&input_group_button/1}
                  variant="ghost"
                  class="pr-1.5! text-xs"
                >
                  Search In... <Lucideicons.chevron_down class="size-3" />
                </.as_child>
                <.dropdown_menu_content align="end">
                  <.dropdown_menu_item>Documentation</.dropdown_menu_item>
                  <.dropdown_menu_item>Blog Posts</.dropdown_menu_item>
                  <.dropdown_menu_item>Changelog</.dropdown_menu_item>
                </.dropdown_menu_content>
              </.dropdown_menu>
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :spinner,
        description: ~s|`disabled` on the group dims the addons; disable the control too.|,
        template: """
        <div class="grid w-full max-w-sm gap-4">
          <.input_group id="ig-spinner-search" disabled>
            <.input_group_input placeholder="Searching..." disabled />
            <.input_group_addon align="inline-end">
              <.spinner />
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-spinner-processing" disabled>
            <.input_group_input placeholder="Processing..." disabled />
            <.input_group_addon>
              <.spinner />
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-spinner-saving" disabled>
            <.input_group_input placeholder="Saving changes..." disabled />
            <.input_group_addon align="inline-end">
              <.input_group_text>Saving...</.input_group_text>
              <.spinner />
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-spinner-refreshing" disabled>
            <.input_group_input placeholder="Refreshing data..." disabled />
            <.input_group_addon>
              <Lucideicons.loader class="animate-spin" />
            </.input_group_addon>
            <.input_group_addon align="inline-end">
              <.input_group_text class="text-muted-foreground">Please wait...</.input_group_text>
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :textarea,
        template: """
        <div class="grid w-full max-w-md gap-4">
          <.input_group id="ig-textarea-code">
            <.input_group_textarea
              id="textarea-code-32"
              placeholder="console.log('Hello, world!');"
              class="min-h-[200px]"
            />
            <.input_group_addon align="block-end" class="border-t">
              <.input_group_text>Line 1, Column 1</.input_group_text>
              <.input_group_button size="sm" class="ml-auto" variant="default">
                Run <Lucideicons.corner_down_left />
              </.input_group_button>
            </.input_group_addon>
            <.input_group_addon align="block-start" class="border-b">
              <.input_group_text class="font-mono font-medium">
                <Lucideicons.file_code /> script.js
              </.input_group_text>
              <.input_group_button class="ml-auto" size="icon-xs" aria-label="Refresh">
                <Lucideicons.refresh_cw />
              </.input_group_button>
              <.input_group_button variant="ghost" size="icon-xs" aria-label="Copy">
                <Lucideicons.copy />
              </.input_group_button>
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :custom_input,
        description:
          ~s|Add `data-slot="input-group-control"` to a custom control for the group's focus styling and addon click-to-focus. Here a native auto-growing textarea (`field-sizing-content`).|,
        template: """
        <div class="grid w-full max-w-sm gap-6">
          <.input_group id="ig-custom">
            <textarea
              data-slot="input-group-control"
              class="flex field-sizing-content min-h-16 w-full resize-none rounded-md bg-transparent px-3 py-2.5 text-base transition-[color,box-shadow] outline-none md:text-sm"
              placeholder="Autoresize textarea..."
            ></textarea>
            <.input_group_addon align="block-end">
              <.input_group_button class="ml-auto" size="sm" variant="default">Submit</.input_group_button>
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :label,
        template: """
        <div class="grid w-full max-w-sm gap-4">
          <.input_group id="ig-label-at">
            <.input_group_input id="email" placeholder="shadcn" />
            <.input_group_addon>
              <.label for="email">@</.label>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-label-block">
            <.input_group_input id="email-2" placeholder="shadcn@vercel.com" />
            <.input_group_addon align="block-start">
              <.label for="email-2" class="text-foreground">Email</.label>
              <.tooltip id="ig-label-tooltip" class="ml-auto">
                <.tooltip_trigger>
                  <.input_group_button variant="ghost" aria-label="Help" class="rounded-full" size="icon-xs">
                    <Lucideicons.info />
                  </.input_group_button>
                </.tooltip_trigger>
                <.tooltip_content>
                  <p>We'll use this to send you notifications</p>
                </.tooltip_content>
              </.tooltip>
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :tooltip,
        template: """
        <div class="grid w-full max-w-sm gap-4">
          <.input_group id="ig-tooltip-password">
            <.input_group_input placeholder="Enter password" type="password" />
            <.input_group_addon align="inline-end">
              <.tooltip id="ig-tooltip-password-tip">
                <.tooltip_trigger>
                  <.input_group_button variant="ghost" aria-label="Info" size="icon-xs">
                    <Lucideicons.info />
                  </.input_group_button>
                </.tooltip_trigger>
                <.tooltip_content>
                  <p>Password must be at least 8 characters</p>
                </.tooltip_content>
              </.tooltip>
            </.input_group_addon>
          </.input_group>
          <.input_group id="ig-tooltip-email">
            <.input_group_input placeholder="Your email address" />
            <.input_group_addon align="inline-end">
              <.tooltip id="ig-tooltip-email-tip">
                <.tooltip_trigger>
                  <.input_group_button variant="ghost" aria-label="Help" size="icon-xs">
                    <Lucideicons.circle_help />
                  </.input_group_button>
                </.tooltip_trigger>
                <.tooltip_content>
                  <p>We'll use this to send you notifications</p>
                </.tooltip_content>
              </.tooltip>
            </.input_group_addon>
          </.input_group>
        </div>
        """
      },
      %Variation{
        id: :in_button_group,
        description: "An input group inside a button group, between two `button_group_text`s.",
        template: """
        <div class="grid w-full max-w-sm gap-6">
          <.button_group>
            <.button_group_text as="label" for="url">https://</.button_group_text>
            <.input_group id="ig-button-group">
              <.input_group_input id="url" />
              <.input_group_addon align="inline-end">
                <Lucideicons.link_2 />
              </.input_group_addon>
            </.input_group>
            <.button_group_text>.com</.button_group_text>
          </.button_group>
        </div>
        """
      }
    ]
  end
end
