defmodule Storybook.SaladUIComponents.Carousel do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Card
  alias SaladUI.Carousel

  def function, do: &Carousel.carousel/1

  def layout, do: :one_column

  def imports,
    do: [
      {Card, [card: 1, card_content: 1]},
      {Carousel, [carousel_content: 1, carousel_item: 1, carousel_previous: 1, carousel_next: 1]}
    ]

  def container, do: {:div, class: "flex justify-center px-14 py-16"}

  def variations do
    [
      %Variation{
        id: :demo,
        description: "Five full-width slides with previous/next buttons.",
        attributes: %{id: "carousel-demo", class: "w-full max-w-xs"},
        slots: [
          """
          <.carousel_content>
            <.carousel_item :for={index <- 1..5}>
              <div class="p-1">
                <.card>
                  <.card_content class="flex aspect-square items-center justify-center p-6">
                    <span class="text-4xl font-semibold">{index}</span>
                  </.card_content>
                </.card>
              </div>
            </.carousel_item>
          </.carousel_content>
          <.carousel_previous />
          <.carousel_next />
          """
        ]
      },
      %Variation{
        id: :size,
        description: "`basis-*` on each item sets how many slides are in view (here 1, 2 on md, 3 on lg).",
        attributes: %{id: "carousel-size", align: "start", class: "w-full max-w-sm"},
        slots: [
          """
          <.carousel_content>
            <.carousel_item :for={index <- 1..5} class="md:basis-1/2 lg:basis-1/3">
              <div class="p-1">
                <.card>
                  <.card_content class="flex aspect-square items-center justify-center p-6">
                    <span class="text-3xl font-semibold">{index}</span>
                  </.card_content>
                </.card>
              </div>
            </.carousel_item>
          </.carousel_content>
          <.carousel_previous />
          <.carousel_next />
          """
        ]
      },
      %Variation{
        id: :spacing,
        description: "A smaller gap: `-ml-1` on the content and `pl-1` on each item.",
        attributes: %{id: "carousel-spacing", class: "w-full max-w-sm"},
        slots: [
          """
          <.carousel_content class="-ml-1">
            <.carousel_item :for={index <- 1..5} class="pl-1 md:basis-1/2 lg:basis-1/3">
              <div class="p-1">
                <.card>
                  <.card_content class="flex aspect-square items-center justify-center p-6">
                    <span class="text-2xl font-semibold">{index}</span>
                  </.card_content>
                </.card>
              </div>
            </.carousel_item>
          </.carousel_content>
          <.carousel_previous />
          <.carousel_next />
          """
        ]
      },
      %Variation{
        id: :orientation,
        description: ~s|`orientation="vertical"`; the content needs a height. Up/Down arrows also navigate.|,
        attributes: %{id: "carousel-orientation", orientation: "vertical", align: "start", class: "w-full max-w-xs"},
        slots: [
          """
          <.carousel_content class="-mt-1 h-[200px]">
            <.carousel_item :for={index <- 1..5} class="pt-1 md:basis-1/2">
              <div class="p-1">
                <.card>
                  <.card_content class="flex items-center justify-center p-6">
                    <span class="text-3xl font-semibold">{index}</span>
                  </.card_content>
                </.card>
              </div>
            </.carousel_item>
          </.carousel_content>
          <.carousel_previous />
          <.carousel_next />
          """
        ]
      },
      %Variation{
        id: :loop,
        description: ~s|Options: `align="start"` and `loop` (next on the last slide wraps to the first).|,
        attributes: %{id: "carousel-loop", align: "start", loop: true, class: "w-full max-w-xs"},
        slots: [
          """
          <.carousel_content>
            <.carousel_item :for={index <- 1..5}>
              <div class="p-1">
                <.card>
                  <.card_content class="flex aspect-square items-center justify-center p-6">
                    <span class="text-4xl font-semibold">{index}</span>
                  </.card_content>
                </.card>
              </div>
            </.carousel_item>
          </.carousel_content>
          <.carousel_previous />
          <.carousel_next />
          """
        ]
      },
      %Variation{
        id: :autoplay,
        description:
          "shadcn's Autoplay plugin example: `autoplay={2000}` advances every 2s, pauses on hover and stops once you navigate.",
        attributes: %{id: "carousel-autoplay", autoplay: 2000, class: "w-full max-w-xs"},
        slots: [
          """
          <.carousel_content>
            <.carousel_item :for={index <- 1..5}>
              <div class="p-1">
                <.card>
                  <.card_content class="flex aspect-square items-center justify-center p-6">
                    <span class="text-4xl font-semibold">{index}</span>
                  </.card_content>
                </.card>
              </div>
            </.carousel_item>
          </.carousel_content>
          <.carousel_previous />
          <.carousel_next />
          """
        ]
      },
      %Variation{
        id: :rtl,
        description:
          ~s|`dir="rtl"`: the track runs right to left and the arrow keys flip; `rtl:rotate-180` flips the icons.|,
        attributes: %{id: "carousel-rtl", dir: "rtl", class: "w-full max-w-xs"},
        slots: [
          """
          <.carousel_content>
            <.carousel_item :for={index <- 1..5}>
              <div class="p-1">
                <.card>
                  <.card_content class="flex aspect-square items-center justify-center p-6">
                    <span class="text-4xl font-semibold">{index}</span>
                  </.card_content>
                </.card>
              </div>
            </.carousel_item>
          </.carousel_content>
          <.carousel_previous class="rtl:rotate-180" />
          <.carousel_next class="rtl:rotate-180" />
          """
        ]
      }
    ]
  end
end
