defmodule Storybook.SaladUIComponents.Dialog do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Button
  alias SaladUI.Dialog
  alias SaladUI.Input
  alias SaladUI.Label

  def function, do: &Dialog.dialog/1

  def imports,
    do: [
      {Button, [button: 1]},
      {Input, [input: 1]},
      {Label, [label: 1]},
      {Dialog,
       [
         dialog_header: 1,
         dialog_title: 1,
         dialog_description: 1,
         dialog_footer: 1,
         dialog_content: 1,
         dialog_trigger: 1,
         dialog_close: 1
       ]}
    ]

  @lorem """
  Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod
  tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
  quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
  consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
  cillum dolore eu fugiat nulla pariatur.
  """

  def variations do
    [
      %Variation{
        id: :dialog,
        slots: [
          """

          <.dialog_trigger>
                  <.button>
          Open modal
          </.button>
          </.dialog_trigger>
          <.dialog_content class="sm:max-w-[425px]">
              <.dialog_header>
                <.dialog_title>Edit profile</.dialog_title>
                <.dialog_description>
                  Make changes to your profile here click save when you're done
                </.dialog_description>
              </.dialog_header>
              <div class="grid gap-4 py-4">
                <div class="grid grid-cols-4 items-center gap-4">
                  <.label html-for="name" class="text-right">
                    Name
                  </.label>
                  <.input id="name" value="Dzung Nguyen" class="col-span-3" />
                </div>
                <div class="grid grid-cols-4 items-center gap-4">
                  <.label html-for="username" class="text-right">
                    Username
                  </.label>
                  <.input id="username" value="@bluzky" class="col-span-3" />
                </div>
              </div>
              <.dialog_footer>
                <.dialog_close>
                  <.button variant="outline" type="button">Cancel</.button>
                </.dialog_close>
                <.button type="submit">save changes</.button>
              </.dialog_footer>
          </.dialog_content>
          """
        ],
        attributes: %{}
      },
      %Variation{
        id: :custom_close_button,
        description: "`dialog_close` closes the dialog from any element you wrap in it.",
        template: """
        <.dialog id="dialog-close-button">
          <.dialog_trigger>
            <.button variant="outline">Share</.button>
          </.dialog_trigger>
          <.dialog_content class="sm:max-w-md">
            <.dialog_header>
              <.dialog_title>Share link</.dialog_title>
              <.dialog_description>
                Anyone who has this link will be able to view this.
              </.dialog_description>
            </.dialog_header>
            <div class="flex items-center gap-2">
              <div class="grid flex-1 gap-2">
                <.label for="dialog-share-link" class="sr-only">Link</.label>
                <.input id="dialog-share-link" value="https://ui.shadcn.com/docs/installation" readonly />
              </div>
            </div>
            <.dialog_footer class="sm:justify-start">
              <.dialog_close>
                <.button type="button">Close</.button>
              </.dialog_close>
            </.dialog_footer>
          </.dialog_content>
        </.dialog>
        """
      },
      %Variation{
        id: :no_close_button,
        description: ~s|`show_close_button={false}` hides the top-right close button.|,
        template: """
        <.dialog id="dialog-no-close-button">
          <.dialog_trigger>
            <.button variant="outline">No Close Button</.button>
          </.dialog_trigger>
          <.dialog_content show_close_button={false}>
            <.dialog_header>
              <.dialog_title>No Close Button</.dialog_title>
              <.dialog_description>
                This dialog doesn't have a close button in the top-right corner.
              </.dialog_description>
            </.dialog_header>
          </.dialog_content>
        </.dialog>
        """
      },
      %Variation{
        id: :sticky_footer,
        description: "Only the body scrolls; the footer (with `show_close_button`) stays visible.",
        template: """
        <.dialog id="dialog-sticky-footer">
          <.dialog_trigger>
            <.button variant="outline">Sticky Footer</.button>
          </.dialog_trigger>
          <.dialog_content>
            <.dialog_header>
              <.dialog_title>Sticky Footer</.dialog_title>
              <.dialog_description>
                This dialog has a sticky footer that stays visible while the content scrolls.
              </.dialog_description>
            </.dialog_header>
            <div class="-mx-4 max-h-[50vh] overflow-y-auto px-4 [scrollbar-width:none]">
              <p :for={_ <- 1..10} class="mb-4 leading-normal">#{String.trim(@lorem)}</p>
            </div>
            <.dialog_footer show_close_button />
          </.dialog_content>
        </.dialog>
        """
      },
      %Variation{
        id: :scrollable_content,
        template: """
        <.dialog id="dialog-scrollable-content">
          <.dialog_trigger>
            <.button variant="outline">Scrollable Content</.button>
          </.dialog_trigger>
          <.dialog_content>
            <.dialog_header>
              <.dialog_title>Scrollable Content</.dialog_title>
              <.dialog_description>This is a dialog with scrollable content.</.dialog_description>
            </.dialog_header>
            <div class="-mx-4 max-h-[50vh] overflow-y-auto px-4 [scrollbar-width:none]">
              <p :for={_ <- 1..10} class="mb-4 leading-normal">#{String.trim(@lorem)}</p>
            </div>
          </.dialog_content>
        </.dialog>
        """
      }
    ]
  end
end
