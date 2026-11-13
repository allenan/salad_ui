defmodule SaladUI.CommandTest do
  use ComponentCase

  import SaladUI.Command

  describe "command/1" do
    test "renders the root command container with id and class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command id="my-command" class="custom-class">
          <span>Content</span>
        </.command>
        """)

      assert html =~ ~s(id="my-command")
      assert html =~ "custom-class"
      assert html =~ "data-component=\"command\""
      assert html =~ "<span>Content</span>"
    end
  end

  describe "command_dialog/1" do
    test "renders a dialog with command inside" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_dialog id="cmd-dialog" open={true}>
          <.command_input placeholder="Type..." />
        </.command_dialog>
        """)

      assert html =~ "cmd-dialog_dialog"
      assert html =~ "data-component=\"command\""
      assert html =~ "placeholder=\"Type...\""
    end

    test "has an sr-only header with default title and description, and a close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_dialog id="cmd-dialog" class="extra-class">
          <.command_input />
        </.command_dialog>
        """)

      assert html =~ ~r/data-slot="dialog-header" class="[^"]*sr-only/
      assert html =~ ~r/data-slot="dialog-title"[^>]*>\s*Command Palette\s*</
      assert html =~ ~r/data-slot="dialog-description"[^>]*>\s*Search for a command to run...\s*</
      assert html =~ ~s(data-slot="dialog-close")
      assert html =~ "overflow-hidden p-0"
      assert html =~ "extra-class"
      assert html =~ "**:data-[slot=command-input-wrapper]:h-12"
      assert html =~ "**:data-[slot=command-item]:py-3"
    end

    test "accepts a custom title and description and can hide the close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_dialog
          id="cmd-dialog"
          title="Search"
          description="Find anything"
          show_close_button={false}
        >
          <.command_input />
        </.command_dialog>
        """)

      assert html =~ ~r/data-slot="dialog-title"[^>]*>\s*Search\s*</
      assert html =~ ~r/data-slot="dialog-description"[^>]*>\s*Find anything\s*</
      refute html =~ "Command Palette"
      refute html =~ ~s(data-slot="dialog-close")
    end
  end

  describe "command_input/1" do
    test "renders input with class and placeholder" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_input class="input-class" placeholder="Search..." />
        """)

      assert html =~ "input-class"
      assert html =~ "placeholder=\"Search...\""
      assert html =~ "data-part=\"input\""
      assert html =~ "<input"
    end
  end

  describe "command_list/1" do
    test "renders the command list container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_list class="list-class">
          <span>List Content</span>
        </.command_list>
        """)

      assert html =~ "data-part=\"list\""
      assert html =~ "list-class"
      assert html =~ "List Content"
    end
  end

  describe "command_empty/1" do
    test "renders the empty message" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_empty class="empty-class">
          <span>No results</span>
        </.command_empty>
        """)

      assert html =~ "data-part=\"empty\""
      assert html =~ "empty-class"
      assert html =~ "No results"
    end
  end

  describe "command_group/1" do
    test "renders a group with heading and items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_group heading="Group Heading">
          <.command_item>Item 1</.command_item>
        </.command_group>
        """)

      assert html =~ "Group Heading"
      assert html =~ "role=\"group\""
      assert html =~ "Item 1"

      assert html =~
               ~s(data-slot="command-group-heading" aria-hidden="true" class="px-2 py-1.5 text-xs font-medium text-muted-foreground")

      assert html =~ "overflow-hidden p-1 text-foreground"
    end
  end

  describe "command_item/1" do
    test "renders a command item button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_item>
          <span>Item</span>
        </.command_item>
        """)

      assert html =~ "<button"
      assert html =~ "data-part=\"item\""
      assert html =~ "<span>Item</span>"
    end

    test "renders with disabled and selected attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_item disabled={true} selected={true}>
          <span>Item</span>
        </.command_item>
        """)

      assert html =~ " disabled>"
      assert html =~ " data-selected "
      assert html =~ " aria-selected "
    end

    test "uses the v4 item classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_item class="item-class" disabled>Item</.command_item>
        """)

      for class <-
            ~w|relative flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 data-[selected=true]:bg-accent data-[selected=true]:text-accent-foreground [&amp;_svg]:pointer-events-none [&amp;_svg]:shrink-0 item-class| do
        assert html =~ class
      end

      assert html =~ "[&amp;_svg:not([class*=&#39;size-&#39;])]:size-4"
      assert html =~ ~s(data-disabled="true")
      refute html =~ "rounded-xs"
    end
  end

  describe "command_shortcut/1" do
    test "renders a shortcut span" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_shortcut class="shortcut-class">⌘P</.command_shortcut>
        """)

      assert html =~ "data-part=\"shortcut\""
      assert html =~ "shortcut-class"
      assert html =~ "⌘P"
    end
  end

  describe "integration: full command palette" do
    test "renders a complete command palette structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command id="cmd">
          <.command_input placeholder="Type a command..." />
          <.command_empty>No results found</.command_empty>
          <.command_list>
            <.command_group heading="Actions">
              <.command_item>
                <span>Action 1</span>
                <.command_shortcut>⌘A</.command_shortcut>
              </.command_item>
              <.command_item disabled>
                <span>Action 2</span>
                <.command_shortcut>⌘B</.command_shortcut>
              </.command_item>
            </.command_group>
          </.command_list>
        </.command>
        """)

      assert html =~ "data-component=\"command\""
      assert html =~ "placeholder=\"Type a command...\""
      assert html =~ "No results found"
      assert html =~ "Actions"
      assert html =~ "Action 1"
      assert html =~ "⌘A"
      assert html =~ "Action 2"
      assert html =~ "⌘B"
      assert html =~ " disabled>"
    end

    test "It renders command_separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_separator class="my-1" />
        <.command_separator always_render />
        """)

      assert html =~ ~s(data-slot="command-separator")
      assert html =~ ~s(data-part="separator")
      # Decorative: a listbox may not contain a separator (axe
      # aria-required-children).
      assert html =~ ~s(role="none")
      refute html =~ ~s(role="separator")
      assert html =~ "-mx-1 h-px bg-border data-[visible=false]:hidden my-1"
      assert html =~ ~s(data-always-render="true")
      assert length(String.split(html, "data-always-render")) == 2
    end

    test "command_separator takes a role override without a duplicate attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_separator role="separator" />
        """)

      assert html =~ ~s(role="separator")
      assert length(String.split(html, "role=")) == 2
    end
  end
end
