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
      {SaladUI.Avatar, [avatar: 1, avatar_image: 1, avatar_fallback: 1]},
      {SaladUI.Helpers, [as_child: 1]},
      {SaladStorybookWeb.CoreComponents, [icon: 1]}
    ]

  # Lucide icons, inlined as bare `<svg>`s like shadcn's examples, so the
  # items' `[&_svg]` rules size and mute them.
  @lucide %{
    user: ~s(<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" />),
    credit_card: ~s(<rect width="20" height="14" x="2" y="5" rx="2" /><line x1="2" x2="22" y1="10" y2="10" />),
    settings:
      ~s(<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" /><circle cx="12" cy="12" r="3" />),
    log_out: ~s(<path d="m16 17 5-5-5-5" /><path d="M21 12H9" /><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />),
    mail: ~s(<rect width="20" height="16" x="2" y="4" rx="2" /><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />),
    message_square: ~s(<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />),
    bell: ~s(<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9" /><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0" />),
    pencil:
      ~s(<path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z" /><path d="m15 5 4 4" />),
    share:
      ~s(<path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" /><polyline points="16 6 12 2 8 6" /><line x1="12" x2="12" y1="2" y2="15" />),
    trash:
      ~s(<path d="M3 6h18" /><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" /><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" />),
    badge_check:
      ~s(<path d="M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 4 0 0 1 0-6.76Z" /><path d="m9 12 2 2 4-4" />)
  }

  defp lucide(name) do
    ~s(<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">) <>
      Map.fetch!(@lucide, name) <> "</svg>"
  end

  def variations do
    [
      %Variation{
        id: :basic,
        description: "shadcn dropdown-menu-basic: a label, a group, a separator and a disabled item",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-basic">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Open
            </.as_child>
            <.dropdown_menu_content>
              <.dropdown_menu_group>
                <.dropdown_menu_label>My Account</.dropdown_menu_label>
                <.dropdown_menu_item>Profile</.dropdown_menu_item>
                <.dropdown_menu_item>Billing</.dropdown_menu_item>
                <.dropdown_menu_item>Settings</.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_item>GitHub</.dropdown_menu_item>
              <.dropdown_menu_item>Support</.dropdown_menu_item>
              <.dropdown_menu_item disabled>API</.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :shortcuts,
        description: "shadcn dropdown-menu-shortcuts: dropdown_menu_shortcut pushes a hint to the end of an item",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-shortcuts">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Open
            </.as_child>
            <.dropdown_menu_content>
              <.dropdown_menu_group>
                <.dropdown_menu_label>My Account</.dropdown_menu_label>
                <.dropdown_menu_item>
                  Profile <.dropdown_menu_shortcut>⇧⌘P</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_item>
                  Billing <.dropdown_menu_shortcut>⌘B</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_item>
                  Settings <.dropdown_menu_shortcut>⌘S</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
              </.dropdown_menu_group>
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
        id: :icons,
        description:
          "shadcn dropdown-menu-icons: a bare <svg> in an item is sized size-4 and muted; destructive items tint it",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-icons">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Open
            </.as_child>
            <.dropdown_menu_content>
              <.dropdown_menu_item>#{lucide(:user)} Profile</.dropdown_menu_item>
              <.dropdown_menu_item>#{lucide(:credit_card)} Billing</.dropdown_menu_item>
              <.dropdown_menu_item>#{lucide(:settings)} Settings</.dropdown_menu_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_item variant="destructive">#{lucide(:log_out)} Log out</.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :checkboxes,
        description:
          "shadcn dropdown-menu-checkboxes: picking a checkbox item toggles it and closes the menu, as in Radix",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-checkboxes">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Open
            </.as_child>
            <.dropdown_menu_content class="w-40">
              <.dropdown_menu_group>
                <.dropdown_menu_label>Appearance</.dropdown_menu_label>
                <.dropdown_menu_checkbox_item checked value="status-bar" on-checked-change="toggle_status_bar">
                  Status Bar
                </.dropdown_menu_checkbox_item>
                <.dropdown_menu_checkbox_item disabled value="activity-bar">
                  Activity Bar
                </.dropdown_menu_checkbox_item>
                <.dropdown_menu_checkbox_item value="panel" on-checked-change="toggle_panel">
                  Panel
                </.dropdown_menu_checkbox_item>
              </.dropdown_menu_group>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :checkboxes_icons,
        description:
          "shadcn dropdown-menu-checkboxes-icons: checkbox items with icons; close-on-select={false} keeps the menu open so several can be flipped",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-checkboxes-icons">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Notifications
            </.as_child>
            <.dropdown_menu_content class="w-48">
              <.dropdown_menu_group>
                <.dropdown_menu_label>Notification Preferences</.dropdown_menu_label>
                <.dropdown_menu_checkbox_item checked value="email" close-on-select={false}>
                  #{lucide(:mail)} Email notifications
                </.dropdown_menu_checkbox_item>
                <.dropdown_menu_checkbox_item value="sms" close-on-select={false}>
                  #{lucide(:message_square)} SMS notifications
                </.dropdown_menu_checkbox_item>
                <.dropdown_menu_checkbox_item checked value="push" close-on-select={false}>
                  #{lucide(:bell)} Push notifications
                </.dropdown_menu_checkbox_item>
              </.dropdown_menu_group>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :destructive,
        description: "shadcn dropdown-menu-destructive: variant=\"destructive\" tints the item and its icon",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-destructive">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Actions
            </.as_child>
            <.dropdown_menu_content>
              <.dropdown_menu_group>
                <.dropdown_menu_item>#{lucide(:pencil)} Edit</.dropdown_menu_item>
                <.dropdown_menu_item>#{lucide(:share)} Share</.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_group>
                <.dropdown_menu_item variant="destructive">#{lucide(:trash)} Delete</.dropdown_menu_item>
              </.dropdown_menu_group>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :avatar,
        description: "shadcn dropdown-menu-avatar: an avatar button trigger with the content aligned to its end",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-avatar">
            <.as_child
              tag={&dropdown_menu_trigger/1}
              child={&button/1}
              variant="ghost"
              size="icon"
              class="rounded-full"
            >
              <.avatar>
                <.avatar_image src="https://github.com/shadcn.png" alt="shadcn" />
                <.avatar_fallback>LR</.avatar_fallback>
              </.avatar>
            </.as_child>
            <.dropdown_menu_content align="end">
              <.dropdown_menu_group>
                <.dropdown_menu_item>#{lucide(:badge_check)} Account</.dropdown_menu_item>
                <.dropdown_menu_item>#{lucide(:credit_card)} Billing</.dropdown_menu_item>
                <.dropdown_menu_item>#{lucide(:bell)} Notifications</.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_item>#{lucide(:log_out)} Sign Out</.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :long,
        description: "A long menu: its height is capped at the room beside the trigger, so it scrolls",
        template: """
        <div class="p-24 flex justify-center">
          <.dropdown_menu id="dropdown-long">
            <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="outline">
              Pick a country
            </.as_child>
            <.dropdown_menu_content class="w-48">
              <.dropdown_menu_label>Countries</.dropdown_menu_label>
              <.dropdown_menu_item :for={country <- ~w(Argentina Australia Austria Belgium Brazil Canada Chile China Denmark Egypt Finland France Germany Greece India Ireland Italy Japan Kenya Mexico Netherlands Norway Peru Poland Portugal Spain Sweden Switzerland Turkey Uruguay)}>
                {country}
              </.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
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
                  <.icon name="hero-user" class="size-4" />
                  <span>Profile</span>
                  <.dropdown_menu_shortcut>⌘P</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_item on-select="on_command">
                  <.icon name="hero-cog-6-tooth" class="size-4" />
                  <span>Settings</span>
                  <.dropdown_menu_shortcut>⌘S</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
                <.dropdown_menu_item on-select="on_command">
                  <.icon name="hero-banknotes" class="size-4" />
                  <span>Billing</span>
                  <.dropdown_menu_shortcut>⌘B</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_group>
                <.dropdown_menu_item on-select="on_command">
                  <.icon name="hero-users" class="size-4" />
                  <span>Team</span>
                </.dropdown_menu_item>
                <.dropdown_menu_item disabled>
                  <.icon name="hero-plus" class="size-4" />
                  <span>New Team</span>
                  <.dropdown_menu_shortcut>⌘T</.dropdown_menu_shortcut>
                </.dropdown_menu_item>
              </.dropdown_menu_group>
              <.dropdown_menu_separator />
              <.dropdown_menu_item on-select="on_command">
                <.icon name="hero-arrow-left-on-rectangle" class="size-4" />
                <span>Log out</span>
              </.dropdown_menu_item>
            </.dropdown_menu_content>
          </.dropdown_menu>
        </div>
        """
      },
      %Variation{
        id: :checkbox_item,
        description: "Checkbox items toggle independently; picking one closes the menu, as in Radix",
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
                <.icon name="hero-book-open" class="size-4" />
                <span>Documentation</span>
              </.dropdown_menu_link_item>
              <.dropdown_menu_link_item href="https://github.com">
                <.icon name="hero-code-bracket" class="size-4" />
                <span>GitHub</span>
              </.dropdown_menu_link_item>
              <.dropdown_menu_separator />
              <.dropdown_menu_link_item disabled href="/changelog">
                <.icon name="hero-clock" class="size-4" />
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
        description: "Radio items: one checked per group; picking one fires on-value-changed and closes the menu",
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
                  <.icon name="hero-document" class="size-4" /> New File
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
                <.icon name="hero-arrow-right-on-rectangle" class="size-4" /> Sign Out
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
