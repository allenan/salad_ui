defmodule Storybook.SaladUIComponents.Popover do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Popover

  def function, do: &Popover.popover/1

  def imports do
    [
      {Popover,
       [
         popover_trigger: 1,
         popover_content: 1,
         popover_anchor: 1,
         popover_header: 1,
         popover_title: 1,
         popover_description: 1
       ]},
      {SaladUI.Button, [button: 1]},
      {SaladUI.Card, [card: 1, card_content: 1, card_description: 1, card_header: 1, card_title: 1]},
      {SaladUI.Input, [input: 1]},
      {SaladUI.Label, [label: 1]}
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          id: "popover-default"
        },
        slots: [
          """
          <.popover_trigger as={&button/1} variant="outline">
            Open popover
          </.popover_trigger>
          <.popover_content side="top" align="center" side-offset={8} class="w-96 border-0 bg-transparent p-0 shadow-none">
            <.card>
              <.card_header class="p-4 pb-3">
                <.card_title class="text-base">Dimensions</.card_title>
                <.card_description>
                  Set the dimensions for the layer.
                </.card_description>
              </.card_header>
              <.card_content class="p-4 pt-0">
              <div class="space-y-3">
                <div class="flex items-center gap-3">
                  <.label for="width" class="w-20 shrink-0">
                    Width
                  </.label>
                  <.input id="width" default-value="100%" class="h-8 min-w-0 flex-1"></.input>
                </div>
                <div class="flex items-center gap-3">
                  <.label for="maxWidth" class="w-20 shrink-0">
                    Max. width
                  </.label>
                  <.input id="maxWidth" default-value="300px" class="h-8 min-w-0 flex-1"></.input>
                </div>
                <div class="flex items-center gap-3">
                  <.label for="height" class="w-20 shrink-0">
                    Height
                  </.label>
                  <.input id="height" default-value="25px" class="h-8 min-w-0 flex-1"></.input>
                </div>
                <div class="flex items-center gap-3">
                  <.label for="maxHeight" class="w-20 shrink-0">
                    Max. height
                  </.label>
                  <.input id="maxHeight" default-value="none" class="h-8 min-w-0 flex-1"></.input>
                </div>
              </div>
              </.card_content>
            </.card>
          </.popover_content>
          """
        ]
      },
      %Variation{
        id: :basic,
        description: "A simple popover with a header, title, and description.",
        attributes: %{id: "popover-basic"},
        slots: [
          """
          <.popover_trigger as={&button/1} variant="outline">Open Popover</.popover_trigger>
          <.popover_content align="start">
            <.popover_header>
              <.popover_title>Dimensions</.popover_title>
              <.popover_description>
                Set the dimensions for the layer.
              </.popover_description>
            </.popover_header>
          </.popover_content>
          """
        ]
      },
      %Variation{
        id: :with_form,
        description: "A popover with form fields inside.",
        attributes: %{id: "popover-form"},
        slots: [
          """
          <.popover_trigger as={&button/1} variant="outline">Open Popover</.popover_trigger>
          <.popover_content class="w-64" align="start">
            <.popover_header>
              <.popover_title>Dimensions</.popover_title>
              <.popover_description>
                Set the dimensions for the layer.
              </.popover_description>
            </.popover_header>
            <div class="mt-4 flex flex-col gap-4">
              <div class="flex items-center gap-3">
                <.label for="popover-form-width" class="w-1/2">Width</.label>
                <.input id="popover-form-width" value="100%" />
              </div>
              <div class="flex items-center gap-3">
                <.label for="popover-form-height" class="w-1/2">Height</.label>
                <.input id="popover-form-height" value="25px" />
              </div>
            </div>
          </.popover_content>
          """
        ]
      },
      %Variation{
        id: :anchor,
        description: "popover_anchor positions the content against another element; the trigger still toggles it.",
        attributes: %{id: "popover-anchor", class: "flex flex-col items-start gap-3"},
        slots: [
          """
          <.popover_anchor class="w-72 rounded-md border border-dashed p-3 text-sm text-muted-foreground">
            The content is positioned against this box.
          </.popover_anchor>
          <.popover_trigger as={&button/1} variant="outline" size="sm">Open</.popover_trigger>
          <.popover_content side="bottom" align="start">
            <.popover_header>
              <.popover_title>Anchored</.popover_title>
              <.popover_description>Opened by the button, placed by the anchor.</.popover_description>
            </.popover_header>
          </.popover_content>
          """
        ]
      },
      %VariationGroup{
        id: :placement_examples,
        description: "Popover placement relative to its trigger.",
        variations: [
          %Variation{
            id: :top,
            attributes: %{id: "top-popover"},
            slots: [
              """
              <.popover_trigger as={&button/1} variant="outline">Top</.popover_trigger>
              <.popover_content side="top" align="center" side-offset={8} class="w-64">
                <p class="text-sm">Appears above trigger.</p>
              </.popover_content>
              """
            ]
          },
          %Variation{
            id: :right,
            attributes: %{id: "right-popover"},
            slots: [
              """
              <.popover_trigger as={&button/1} variant="outline">Right</.popover_trigger>
              <.popover_content side="right" align="center" side-offset={8} class="w-64">
                <p class="text-sm">Appears right of trigger.</p>
              </.popover_content>
              """
            ]
          },
          %Variation{
            id: :bottom,
            attributes: %{id: "bottom-popover"},
            slots: [
              """
              <.popover_trigger as={&button/1} variant="outline">Bottom</.popover_trigger>
              <.popover_content side="bottom" align="center" side-offset={8} class="w-64">
                <p class="text-sm">Appears below trigger.</p>
              </.popover_content>
              """
            ]
          },
          %Variation{
            id: :left,
            attributes: %{id: "left-popover"},
            slots: [
              """
              <.popover_trigger as={&button/1} variant="outline">Left</.popover_trigger>
              <.popover_content side="left" align="center" side-offset={8} class="w-64">
                <p class="text-sm">Appears left of trigger.</p>
              </.popover_content>
              """
            ]
          }
        ]
      },
      %Variation{
        id: :portal_container,
        attributes: %{
          "portal-container" => "#popover-portal-target",
          "use-portal" => true,
          id: "portal-container-popover"
        },
        slots: [
          """
          <div id="popover-portal-target"></div>
          <.popover_trigger as={&button/1} variant="outline">
            Open in portal
          </.popover_trigger>
          <.popover_content side="bottom" align="start" class="w-64">
            <div class="space-y-2">
              <h4 class="font-medium leading-none">Custom portal container</h4>
              <p class="text-sm text-muted-foreground">
                This content is moved into <code>#popover-portal-target</code> while open.
              </p>
            </div>
          </.popover_content>
          """
        ]
      },
      %VariationGroup{
        id: :alignment_examples,
        description: "Cross-axis alignment for bottom-placed popovers.",
        variations: [
          %Variation{
            id: :start,
            attributes: %{id: "start-align-popover"},
            slots: [
              """
              <.popover_trigger as={&button/1} variant="outline">Start</.popover_trigger>
              <.popover_content side="bottom" align="start" side-offset={8} class="w-64">
                <p class="text-sm">Aligned to trigger start.</p>
              </.popover_content>
              """
            ]
          },
          %Variation{
            id: :center,
            attributes: %{id: "center-align-popover"},
            slots: [
              """
              <.popover_trigger as={&button/1} variant="outline">Center</.popover_trigger>
              <.popover_content side="bottom" align="center" side-offset={8} class="w-64">
                <p class="text-sm">Centered on trigger.</p>
              </.popover_content>
              """
            ]
          },
          %Variation{
            id: :end,
            attributes: %{id: "end-align-popover"},
            slots: [
              """
              <.popover_trigger as={&button/1} variant="outline">End</.popover_trigger>
              <.popover_content side="bottom" align="end" side-offset={8} class="w-64">
                <p class="text-sm">Aligned to trigger end.</p>
              </.popover_content>
              """
            ]
          }
        ]
      }
    ]
  end
end
