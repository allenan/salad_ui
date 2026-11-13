defmodule Storybook.SaladUIComponents.Sheet do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Button
  alias SaladUI.Input
  alias SaladUI.Label
  alias SaladUI.Sheet

  def function, do: &Sheet.sheet/1

  def imports,
    do: [
      {Sheet,
       [
         sheet_trigger: 1,
         sheet_content: 1,
         sheet_header: 1,
         sheet_title: 1,
         sheet_footer: 1,
         sheet_description: 1,
         sheet_close: 1
       ]},
      {Button, [button: 1]},
      {Input, [input: 1]},
      {Label, [label: 1]}
    ]

  @lorem "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

  def variations do
    [
      %Variation{
        id: :default,
        description: """
        shadcn sheet-demo. Sheets slide in from one of four sides: top, right, bottom, or left. Default is `right`.
        """,
        template: """
        <.sheet id="sheet-default">
          <.sheet_trigger>
            <.button variant="outline">Open</.button>
          </.sheet_trigger>
          <.sheet_content>
            <.sheet_header>
              <.sheet_title>Edit profile</.sheet_title>
              <.sheet_description>
                Make changes to your profile here. Click save when you're done.
              </.sheet_description>
            </.sheet_header>
            <div class="grid flex-1 auto-rows-min gap-6 px-4">
              <div class="grid gap-3">
                <.label for="sheet-demo-name">Name</.label>
                <.input id="sheet-demo-name" value="Pedro Duarte" />
              </div>
              <div class="grid gap-3">
                <.label for="sheet-demo-username">Username</.label>
                <.input id="sheet-demo-username" value="@peduarte" />
              </div>
            </div>
            <.sheet_footer>
              <.button type="submit">Save changes</.button>
              <.sheet_close>
                <.button variant="outline" class="w-full">Close</.button>
              </.sheet_close>
            </.sheet_footer>
          </.sheet_content>
        </.sheet>
        """
      },
      %Variation{
        id: :sheet_side,
        description: """
        shadcn sheet-side. Sheets can appear from any of the four sides of the screen.
        `data-side` lets `class` target a side, e.g. `data-[side=bottom]:max-h-[50vh]`.
        """,
        template: """
        <div class="flex flex-wrap gap-2">
          <.sheet :for={side <- ~w(top right bottom left)} id={"sheet-side-\#{side}"}>
            <.sheet_trigger>
              <.button variant="outline" class="capitalize">{side}</.button>
            </.sheet_trigger>
            <.sheet_content side={side} class="data-[side=bottom]:max-h-[50vh] data-[side=top]:max-h-[50vh]">
              <.sheet_header>
                <.sheet_title>Edit profile</.sheet_title>
                <.sheet_description>
                  Make changes to your profile here. Click save when you're done.
                </.sheet_description>
              </.sheet_header>
              <div class="no-scrollbar overflow-y-auto px-4">
                <p :for={_ <- 1..10} class="mb-2 leading-relaxed">#{@lorem}</p>
              </div>
              <.sheet_footer>
                <.button type="submit">Save changes</.button>
                <.sheet_close>
                  <.button variant="outline" class="w-full">Cancel</.button>
                </.sheet_close>
              </.sheet_footer>
            </.sheet_content>
          </.sheet>
        </div>
        """
      },
      %Variation{
        id: :sheet_no_close_button,
        description: """
        shadcn sheet-no-close-button. `show_close_button={false}` hides the top-right close button.
        """,
        template: """
        <.sheet id="sheet-no-close-button">
          <.sheet_trigger>
            <.button variant="outline">Open Sheet</.button>
          </.sheet_trigger>
          <.sheet_content show_close_button={false}>
            <.sheet_header>
              <.sheet_title>No Close Button</.sheet_title>
              <.sheet_description>
                This sheet doesn't have a close button in the top-right corner. Click outside to close.
              </.sheet_description>
            </.sheet_header>
          </.sheet_content>
        </.sheet>
        """
      },
      %Variation{
        id: :programmatic,
        description: """
        Sheets can be controlled programmatically using LiveView's JS commands.
        """,
        template: """
        <div class="space-y-4">
          <.sheet id="sheet-programmatic">
            <.sheet_content side="right">
              <.sheet_header>
                <.sheet_title>Programmatic Sheet</.sheet_title>
                <.sheet_description>
                  This sheet is controlled programmatically from outside.
                </.sheet_description>
              </.sheet_header>
              <div class="px-4">
                <p>The sheet was opened using a JS command rather than a trigger.</p>
              </div>
              <.sheet_footer>
                <.sheet_close>
                  <.button class="w-full">Close</.button>
                </.sheet_close>
              </.sheet_footer>
            </.sheet_content>
          </.sheet>

          <.button phx-click={%JS{} |> SaladUI.JS.dispatch_command("open", to: "#sheet-programmatic")}>
            Open Sheet Programmatically
          </.button>
        </div>
        """
      }
    ]
  end
end
