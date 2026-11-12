defmodule Storybook.SaladUIComponents.DropdownMenu do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.DropdownMenu

  def function, do: &DropdownMenu.dropdown_menu/1

  def imports,
    do: [
      {DropdownMenu,
       [
         dropdown_menu_trigger: 1,
         dropdown_menu_content: 1,
         dropdown_menu_label: 1,
         dropdown_menu_separator: 1,
         dropdown_menu_item: 1,
         dropdown_menu_link_item: 1,
         dropdown_menu_shortcut: 1,
         dropdown_menu_group: 1,
         dropdown_menu_checkbox_item: 1,
         dropdown_menu_radio_group: 1,
         dropdown_menu_radio_item: 1,
         dropdown_menu_sub: 1,
         dropdown_menu_sub_trigger: 1,
         dropdown_menu_sub_content: 1
       ]},
      {SaladUI.Button, [button: 1]},
      {SaladUI.Helpers, [as_child: 1]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default dropdown menu with various options",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-default">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Open Menu
            </.as_child>
            <.dropdown_menu_content class="w-56">
              <.dropdown_menu_label>Account</.dropdown_menu_label>
              <.dropdown_menu_separator />
              <.dropdown_menu_group>
                <.dropdown_menu_item on-select="on_command" value="profile">
                  <.icon name="hero-user" class="mr-2 size-4" />
                  <span>Profile</span>
                  <.dropdown_menu_shortcut>⌘P</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_item on-select="on_command">
                  <.icon name="hero-cog-6-tooth" class="mr-2 size-4" />
                  <span>Settings</span>
                  <.dropdown_menu_shortcut>⌘S</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_item on-select="on_command">
                  <.icon name="hero-banknotes" class="mr-2 size-4" />
                  <span>Billing</span>
                  <.dropdown_menu_shortcut>⌘B</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_group>
                <.dropdown_menu_item on-select="on_command">
                  <.icon name="hero-users" class="mr-2 size-4" />
                  <span>Team</span>
                </.dropdown_menu_item>
                <.dropdown_menu_item disabled>
                  <.icon name="hero-plus" class="mr-2 size-4" />
                  <span>New Team</span>
                  <.dropdown_menu_shortcut>⌘T</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_item on-select="on_command">
                <.icon name="hero-arrow-left-on-rectangle" class="mr-2 size-4" />
                <span>Log out</span>
              </.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :checkbox_item,
        description:
          "Checkbox items toggle independently and keep the menu open, so you can flip several without reopening it",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="text-formatting">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Format
            </.as_child>
            <.dropdown_menu_content class="w-48">
              <.dropdown_menu_checkbox_item checked value="bold" on-checked-change="toggle_bold">
                <span class="font-bold">Bold</span>
              </.dropdown_menu_checkbox_item>
              <.dropdown_menu_checkbox_item value="italic" on-checked-change="toggle_italic">
                <span class="italic">Italic</span>
              </.dropdown_menu_checkbox_item>
              <.dropdown_menu_checkbox_item value="underline" on-checked-change="toggle_underline">
                <span class="underline">Underline</span>
              </.dropdown_menu_checkbox_item>
              <.dropdown_menu_checkbox_item disabled value="strikethrough">
                <span class="line-through">Strikethrough</span>
              </.dropdown_menu_checkbox_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :link_item,
        description: "Items rendered as links, for menus that navigate instead of dispatching actions",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-links">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Help
            </.as_child>
            <.dropdown_menu_content class="w-56">
              <.dropdown_menu_link_item href="/docs">
                <.icon name="hero-book-open" class="mr-2 size-4" />
                <span>Documentation</span>
              </.dropdown_menu_link_item>
              <.dropdown_menu_link_item href="https://github.com">
                <.icon name="hero-code-bracket" class="mr-2 size-4" />
                <span>GitHub</span>
              </.dropdown_menu_link_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_link_item disabled href="/changelog">
                <.icon name="hero-clock" class="mr-2 size-4" />
                <span>Changelog</span>
              </.dropdown_menu_link_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :demo,
        description: "shadcn demo: shortcuts, groups, a disabled item and an \"Invite users\" sub-menu",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-demo">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Open
            </.as_child>
            <.dropdown_menu_content class="w-56" align="start">
              <.dropdown_menu_label>My Account</.dropdown_menu_label>
              <.dropdown_menu_group>
                <.dropdown_menu_item>
                  Profile <.dropdown_menu_shortcut>⇧⌘P</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_item>
                  Billing <.dropdown_menu_shortcut>⌘B</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_item>
                  Settings <.dropdown_menu_shortcut>⌘S</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_item>
                  Keyboard shortcuts <.dropdown_menu_shortcut>⌘K</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_group>
                <.dropdown_menu_item>Team</.dropdown_menu_item>
                <.dropdown_menu_sub>
                  <.dropdown_menu_sub_trigger>Invite users</.dropdown_menu_sub_trigger>
                  <.dropdown_menu_sub_content>
                    <.dropdown_menu_item>Email</.dropdown_menu_item>
                    <.dropdown_menu_item>Message</.dropdown_menu_item>
                    <.dropdown_menu_separator />
                    <.dropdown_menu_item>More...</.dropdown_menu_item>
                  </.dropdown_menu_sub_content>
                </.dropdown_menu_sub>
                <.dropdown_menu_item>
                  New Team <.dropdown_menu_shortcut>⌘+T</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_item>GitHub</.dropdown_menu_item>
              <.dropdown_menu_item>Support</.dropdown_menu_item>
              <.dropdown_menu_item disabled>API</.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item>
                Log out <.dropdown_menu_shortcut>⇧⌘Q</.dropdown_menu_shortcut>
              </.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :submenu,
        description:
          "Nested sub-menus. ArrowRight (or hover) opens a sub-menu, ArrowLeft closes it, Escape closes everything",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-submenu">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Open
            </.as_child>
            <.dropdown_menu_content>
              <.dropdown_menu_group>
                <.dropdown_menu_item>Team</.dropdown_menu_item>
                <.dropdown_menu_sub>
                  <.dropdown_menu_sub_trigger>Invite users</.dropdown_menu_sub_trigger>
                  <.dropdown_menu_sub_content>
                    <.dropdown_menu_item>Email</.dropdown_menu_item>
                    <.dropdown_menu_item>Message</.dropdown_menu_item>
                    <.dropdown_menu_sub>
                      <.dropdown_menu_sub_trigger>More options</.dropdown_menu_sub_trigger>
                      <.dropdown_menu_sub_content>
                        <.dropdown_menu_item>Calendly</.dropdown_menu_item>
                        <.dropdown_menu_item>Slack</.dropdown_menu_item>
                        <.dropdown_menu_separator />
                        <.dropdown_menu_item>Webhook</.dropdown_menu_item>
                      </.dropdown_menu_sub_content>
                    </.dropdown_menu_sub>
                    <.dropdown_menu_separator />
                    <.dropdown_menu_item>Advanced...</.dropdown_menu_item>
                  </.dropdown_menu_sub_content>
                </.dropdown_menu_sub>
                <.dropdown_menu_item>
                  New Team <.dropdown_menu_shortcut>⌘+T</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
              </.dropdown_menu_group>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :radio_group,
        description: "Radio items: one checked per group; picking one fires on-value-changed and keeps the menu open",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-radio-group">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Open
            </.as_child>
            <.dropdown_menu_content class="w-56">
              <.dropdown_menu_label>Panel Position</.dropdown_menu_label>
              <.dropdown_menu_separator />
              <.dropdown_menu_radio_group value="bottom" on-value-changed="set_position">
                <.dropdown_menu_radio_item value="top">Top</.dropdown_menu_radio_item>
                <.dropdown_menu_radio_item value="bottom">Bottom</.dropdown_menu_radio_item>
                <.dropdown_menu_radio_item value="right">Right</.dropdown_menu_radio_item>
              </.dropdown_menu_radio_group>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :radio_icons,
        description: "Radio items with icons",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-radio-icons">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Payment Method
            </.as_child>
            <.dropdown_menu_content class="min-w-56">
              <.dropdown_menu_group>
                <.dropdown_menu_label>Select Payment Method</.dropdown_menu_label>
                <.dropdown_menu_radio_group value="card" on-value-changed="set_payment_method">
                  <.dropdown_menu_radio_item value="card">
                    <.icon name="hero-credit-card" class="size-4" /> Credit Card
                  </.dropdown_menu_radio_item>
                  <.dropdown_menu_radio_item value="paypal">
                    <.icon name="hero-wallet" class="size-4" /> PayPal
                  </.dropdown_menu_radio_item>
                  <.dropdown_menu_radio_item value="bank">
                    <.icon name="hero-building-library" class="size-4" /> Bank Transfer
                  </.dropdown_menu_radio_item>
                </.dropdown_menu_radio_group>
              </.dropdown_menu_group>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :complex,
        description: "Groups, icons, checkbox items, and sub-menus holding nested sub-menus and a radio group",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-complex">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Complex Menu
            </.as_child>
            <.dropdown_menu_content class="w-44">
              <.dropdown_menu_group>
                <.dropdown_menu_label>File</.dropdown_menu_label>
                <.dropdown_menu_item>
                  <.icon name="hero-document" class="mr-2 size-4" /> New File
                  <.dropdown_menu_shortcut>⌘N</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_sub>
                  <.dropdown_menu_sub_trigger>
                    <.icon name="hero-folder-open" class="size-4" /> Open Recent
                  </.dropdown_menu_sub_trigger>
                  <.dropdown_menu_sub_content>
                    <.dropdown_menu_group>
                      <.dropdown_menu_label>Recent Projects</.dropdown_menu_label>
                      <.dropdown_menu_item>Project Alpha</.dropdown_menu_item>
                      <.dropdown_menu_item>Project Beta</.dropdown_menu_item>
                      <.dropdown_menu_sub>
                        <.dropdown_menu_sub_trigger>More Projects</.dropdown_menu_sub_trigger>
                        <.dropdown_menu_sub_content>
                          <.dropdown_menu_item>Project Gamma</.dropdown_menu_item>
                          <.dropdown_menu_item>Project Delta</.dropdown_menu_item>
                        </.dropdown_menu_sub_content>
                      </.dropdown_menu_sub>
                    </.dropdown_menu_group>
                    <.dropdown_menu_separator />
                    <.dropdown_menu_item>Browse...</.dropdown_menu_item>
                  </.dropdown_menu_sub_content>
                </.dropdown_menu_sub>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_group>
                <.dropdown_menu_label>View</.dropdown_menu_label>
                <.dropdown_menu_checkbox_item checked value="sidebar">
                  Show Sidebar
                </.dropdown_menu_checkbox_item>
                <.dropdown_menu_checkbox_item value="status-bar">
                  Show Status Bar
                </.dropdown_menu_checkbox_item>
                <.dropdown_menu_sub>
                  <.dropdown_menu_sub_trigger>
                    <.icon name="hero-swatch" class="size-4" /> Theme
                  </.dropdown_menu_sub_trigger>
                  <.dropdown_menu_sub_content>
                    <.dropdown_menu_label>Appearance</.dropdown_menu_label>
                    <.dropdown_menu_radio_group value="light" on-value-changed="set_theme">
                      <.dropdown_menu_radio_item value="light">Light</.dropdown_menu_radio_item>
                      <.dropdown_menu_radio_item value="dark">Dark</.dropdown_menu_radio_item>
                      <.dropdown_menu_radio_item value="system">System</.dropdown_menu_radio_item>
                    </.dropdown_menu_radio_group>
                  </.dropdown_menu_sub_content>
                </.dropdown_menu_sub>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_item variant="destructive">
                <.icon name="hero-arrow-right-on-rectangle" class="mr-2 size-4" /> Sign Out
                <.dropdown_menu_shortcut>⇧⌘Q</.dropdown_menu_shortcut>
              </.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      }
    ]
  end
end
