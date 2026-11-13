defmodule Storybook.SaladUIComponents.Command do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Command

  def function, do: &Command.command/1
  def layout, do: :one_column

  def imports,
    do: [
      {Command,
       [
         command_input: 1,
         command_list: 1,
         command_empty: 1,
         command_group: 1,
         command_item: 1,
         command_shortcut: 1,
         command_separator: 1,
         command_dialog: 1
       ]},
      {Lucideicons, [earth: 1, calendar: 1, calculator: 1, user: 1, credit_card: 1, settings: 1]},
      {SaladUI.Button, [button: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :command,
        template: """
        <.command id="command-2" class="rounded-lg border border-border shadow-md md:min-w-[450px] w-full lg:max-w-[600px]">
          <.command_input placeholder="Type a command or search..." />
          <.command_empty>
            <span>No results found</span>
          </.command_empty>
          <.command_list>
            <.command_group heading="Suggestions">
              <.command_item phx-value-name="calendar" phx-click="select_command">
                <.calendar/>
                <span>Calendar</span>
              </.command_item>
              <.command_item phx-value-name="global-map" phx-click="select_command">
                <.earth/>
                <span>Global map</span>
              </.command_item>
              <.command_item disabled={true}>
                <.calculator/>
                <span>Calculator</span>
              </.command_item>
            </.command_group>
            <.command_separator />
            <.command_group heading="Settings">
              <.command_item phx-value-name="profile" phx-click="select_command">
                <.user/>
                <span>Profile</span>
                <.command_shortcut>⌘P</.command_shortcut>
              </.command_item>
              <.command_item phx-value-name="billing" phx-click="select_command">
                <.credit_card/>
                <span>Billing</span>
                <.command_shortcut>⌘B</.command_shortcut>
              </.command_item>
              <.command_item value="settings" phx-click="select_command">
                <.settings class="size-4"/>
                <span>Settings</span>
                <.command_shortcut>⌘,</.command_shortcut>
              </.command_item>
            </.command_group>
          </.command_list>
        </.command>
        """,
        attributes: %{}
      },
      %Variation{
        id: :shortcuts,
        description: "shadcn command-shortcuts: items with keyboard shortcuts, in a command dialog.",
        template: """
        <div class="flex flex-col gap-4">
          <.button
            variant="outline"
            class="w-fit"
            phx-click={%JS{} |> SaladUI.JS.dispatch_command("open", to: "#command-shortcuts_dialog")}
          >
            Open Menu
          </.button>
          <.command_dialog id="command-shortcuts">
            <.command_input placeholder="Type a command or search..." />
            <.command_list>
              <.command_empty>No results found.</.command_empty>
              <.command_group heading="Settings">
                <.command_item>
                  <Lucideicons.user />
                  <span>Profile</span>
                  <.command_shortcut>⌘P</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.credit_card />
                  <span>Billing</span>
                  <.command_shortcut>⌘B</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.settings />
                  <span>Settings</span>
                  <.command_shortcut>⌘S</.command_shortcut>
                </.command_item>
              </.command_group>
            </.command_list>
          </.command_dialog>
        </div>
        """
      },
      %Variation{
        id: :groups,
        description: "shadcn command-groups: headed groups split by a separator, in a command dialog.",
        template: """
        <div class="flex flex-col gap-4">
          <.button
            variant="outline"
            class="w-fit"
            phx-click={%JS{} |> SaladUI.JS.dispatch_command("open", to: "#command-groups_dialog")}
          >
            Open Menu
          </.button>
          <.command_dialog id="command-groups">
            <.command_input placeholder="Type a command or search..." />
            <.command_list>
              <.command_empty>No results found.</.command_empty>
              <.command_group heading="Suggestions">
                <.command_item>
                  <Lucideicons.calendar />
                  <span>Calendar</span>
                </.command_item>
                <.command_item>
                  <Lucideicons.smile />
                  <span>Search Emoji</span>
                </.command_item>
                <.command_item>
                  <Lucideicons.calculator />
                  <span>Calculator</span>
                </.command_item>
              </.command_group>
              <.command_separator />
              <.command_group heading="Settings">
                <.command_item>
                  <Lucideicons.user />
                  <span>Profile</span>
                  <.command_shortcut>⌘P</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.credit_card />
                  <span>Billing</span>
                  <.command_shortcut>⌘B</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.settings />
                  <span>Settings</span>
                  <.command_shortcut>⌘S</.command_shortcut>
                </.command_item>
              </.command_group>
            </.command_list>
          </.command_dialog>
        </div>
        """
      },
      %Variation{
        id: :scrollable,
        description: "shadcn command-scrollable: enough items that the list scrolls, in a command dialog.",
        template: """
        <div class="flex flex-col gap-4">
          <.button
            variant="outline"
            class="w-fit"
            phx-click={%JS{} |> SaladUI.JS.dispatch_command("open", to: "#command-scrollable_dialog")}
          >
            Open Menu
          </.button>
          <.command_dialog id="command-scrollable">
            <.command_input placeholder="Type a command or search..." />
            <.command_list>
              <.command_empty>No results found.</.command_empty>
              <.command_group heading="Navigation">
                <.command_item>
                  <Lucideicons.house />
                  <span>Home</span>
                  <.command_shortcut>⌘H</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.inbox />
                  <span>Inbox</span>
                  <.command_shortcut>⌘I</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.file_text />
                  <span>Documents</span>
                  <.command_shortcut>⌘D</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.folder />
                  <span>Folders</span>
                  <.command_shortcut>⌘F</.command_shortcut>
                </.command_item>
              </.command_group>
              <.command_separator />
              <.command_group heading="Actions">
                <.command_item>
                  <Lucideicons.plus />
                  <span>New File</span>
                  <.command_shortcut>⌘N</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.folder_plus />
                  <span>New Folder</span>
                  <.command_shortcut>⇧⌘N</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.copy />
                  <span>Copy</span>
                  <.command_shortcut>⌘C</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.scissors />
                  <span>Cut</span>
                  <.command_shortcut>⌘X</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.clipboard_paste />
                  <span>Paste</span>
                  <.command_shortcut>⌘V</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.trash />
                  <span>Delete</span>
                  <.command_shortcut>⌫</.command_shortcut>
                </.command_item>
              </.command_group>
              <.command_separator />
              <.command_group heading="View">
                <.command_item>
                  <Lucideicons.layout_grid />
                  <span>Grid View</span>
                </.command_item>
                <.command_item>
                  <Lucideicons.list />
                  <span>List View</span>
                </.command_item>
                <.command_item>
                  <Lucideicons.zoom_in />
                  <span>Zoom In</span>
                  <.command_shortcut>⌘+</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.zoom_out />
                  <span>Zoom Out</span>
                  <.command_shortcut>⌘-</.command_shortcut>
                </.command_item>
              </.command_group>
              <.command_separator />
              <.command_group heading="Account">
                <.command_item>
                  <Lucideicons.user />
                  <span>Profile</span>
                  <.command_shortcut>⌘P</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.credit_card />
                  <span>Billing</span>
                  <.command_shortcut>⌘B</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.settings />
                  <span>Settings</span>
                  <.command_shortcut>⌘S</.command_shortcut>
                </.command_item>
                <.command_item>
                  <Lucideicons.bell />
                  <span>Notifications</span>
                </.command_item>
                <.command_item>
                  <Lucideicons.circle_help />
                  <span>Help &amp; Support</span>
                </.command_item>
              </.command_group>
              <.command_separator />
              <.command_group heading="Tools">
                <.command_item>
                  <Lucideicons.calculator />
                  <span>Calculator</span>
                </.command_item>
                <.command_item>
                  <Lucideicons.calendar />
                  <span>Calendar</span>
                </.command_item>
                <.command_item>
                  <Lucideicons.image />
                  <span>Image Editor</span>
                </.command_item>
                <.command_item>
                  <Lucideicons.code />
                  <span>Code Editor</span>
                </.command_item>
              </.command_group>
            </.command_list>
          </.command_dialog>
        </div>
        """
      }
    ]
  end
end
