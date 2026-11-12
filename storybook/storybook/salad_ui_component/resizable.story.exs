defmodule Storybook.SaladUIComponents.Resizable do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Resizable

  def function, do: &Resizable.resizable_panel_group/1

  def layout, do: :one_column

  def imports, do: [{Resizable, [resizable_panel: 1, resizable_handle: 1]}]

  def variations do
    [
      %Variation{
        id: :demo,
        description: "Horizontal group with a nested vertical group",
        attributes: %{
          id: "resizable-demo",
          orientation: "horizontal",
          class: "max-w-md rounded-lg border md:min-w-[450px]"
        },
        slots: [nested_slot("resizable-demo-nested", false)]
      },
      %Variation{
        id: :demo_with_handle,
        description: "The same layout with visible grips (with_handle)",
        attributes: %{
          id: "resizable-demo-with-handle",
          orientation: "horizontal",
          class: "max-w-md rounded-lg border md:min-w-[450px]"
        },
        slots: [nested_slot("resizable-demo-with-handle-nested", true)]
      },
      %Variation{
        id: :vertical,
        description: ~s(orientation="vertical" stacks the panels),
        attributes: %{
          id: "resizable-vertical",
          orientation: "vertical",
          class: "min-h-[200px] max-w-md rounded-lg border md:min-w-[450px]"
        },
        slots: [
          """
          <.resizable_panel default-size="25%">
            <div class="flex h-full items-center justify-center p-6">
              <span class="font-semibold">Header</span>
            </div>
          </.resizable_panel>
          <.resizable_handle />
          <.resizable_panel default-size="75%">
            <div class="flex h-full items-center justify-center p-6">
              <span class="font-semibold">Content</span>
            </div>
          </.resizable_panel>
          """
        ]
      },
      %Variation{
        id: :handle,
        description: "with_handle shows a grip on the handle",
        attributes: %{
          id: "resizable-handle",
          orientation: "horizontal",
          class: "min-h-[200px] max-w-md rounded-lg border md:min-w-[450px]"
        },
        slots: [sidebar_slot()]
      },
      %Variation{
        id: :constraints_and_persistence,
        description:
          "min-size/max-size limit the sidebar to 15-40%; auto-save-id restores the layout from localStorage after a reload",
        attributes: %{
          id: "resizable-persisted",
          orientation: "horizontal",
          "auto-save-id": "storybook-resizable",
          class: "min-h-[200px] max-w-md rounded-lg border md:min-w-[450px]"
        },
        slots: [
          """
          <.resizable_panel default-size={25} min-size={15} max-size={40}>
            <div class="flex h-full items-center justify-center p-6">
              <span class="font-semibold">Sidebar</span>
            </div>
          </.resizable_panel>
          <.resizable_handle with_handle />
          <.resizable_panel default-size={75}>
            <div class="flex h-full items-center justify-center p-6">
              <span class="font-semibold">Content</span>
            </div>
          </.resizable_panel>
          """
        ]
      },
      %Variation{
        id: :rtl,
        description: ~s(Inside dir="rtl" the first panel sits on the right and drags/arrow keys are mirrored),
        attributes: %{
          id: "resizable-rtl",
          orientation: "horizontal",
          dir: "rtl",
          class: "min-h-[200px] max-w-md rounded-lg border md:min-w-[450px]"
        },
        slots: [sidebar_slot()]
      }
    ]
  end

  defp sidebar_slot do
    """
    <.resizable_panel default-size="25%">
      <div class="flex h-full items-center justify-center p-6">
        <span class="font-semibold">Sidebar</span>
      </div>
    </.resizable_panel>
    <.resizable_handle with_handle />
    <.resizable_panel default-size="75%">
      <div class="flex h-full items-center justify-center p-6">
        <span class="font-semibold">Content</span>
      </div>
    </.resizable_panel>
    """
  end

  defp nested_slot(nested_id, with_handle) do
    """
    <.resizable_panel default-size="50%">
      <div class="flex h-[200px] items-center justify-center p-6">
        <span class="font-semibold">One</span>
      </div>
    </.resizable_panel>
    <.resizable_handle with_handle={#{with_handle}} />
    <.resizable_panel default-size="50%">
      <.resizable_panel_group id="#{nested_id}" orientation="vertical">
        <.resizable_panel default-size="25%">
          <div class="flex h-full items-center justify-center p-6">
            <span class="font-semibold">Two</span>
          </div>
        </.resizable_panel>
        <.resizable_handle with_handle={#{with_handle}} />
        <.resizable_panel default-size="75%">
          <div class="flex h-full items-center justify-center p-6">
            <span class="font-semibold">Three</span>
          </div>
        </.resizable_panel>
      </.resizable_panel_group>
    </.resizable_panel>
    """
  end
end
