defmodule Storybook.SaladUIComponents.Pagination do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Pagination

  def function, do: &Pagination.pagination/1

  def imports,
    do: [
      {Pagination,
       [
         pagination_content: 1,
         pagination_item: 1,
         pagination_link: 1,
         pagination_ellipsis: 1,
         pagination_next: 1,
         pagination_previous: 1
       ]},
      {SaladUI.Field, [field: 1, field_label: 1]},
      {SaladUI.Select,
       [select: 1, select_trigger: 1, select_content: 1, select_group: 1, select_item: 1, select_value: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :pagination,
        template: """
        <.pagination>
          <.pagination_content>
            <.pagination_item>
              <.pagination_previous href="#" />
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="">1</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="" is-active="true">2</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="">3</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_ellipsis />
            </.pagination_item>
            <.pagination_item>
              <.pagination_next href="#" />
            </.pagination_item>
          </.pagination_content>
        </.pagination>
        """,
        attributes: %{}
      },
      %Variation{
        id: :pagination_simple,
        description: "Only page numbers.",
        template: """
        <.pagination>
          <.pagination_content>
            <.pagination_item>
              <.pagination_link href="#">1</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="#" is-active>2</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="#">3</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="#">4</.pagination_link>
            </.pagination_item>
            <.pagination_item>
              <.pagination_link href="#">5</.pagination_link>
            </.pagination_item>
          </.pagination_content>
        </.pagination>
        """,
        attributes: %{}
      },
      %Variation{
        id: :pagination_icons_only,
        description:
          "Just the previous and next buttons, beside a rows-per-page select. Below the sm breakpoint they show only their chevrons.",
        template: """
        <div class="flex items-center justify-between gap-4">
          <.field orientation="horizontal" class="w-fit">
            <.field_label for="select-rows-per-page">Rows per page</.field_label>
            <.select id="rows-per-page" default-value="25">
              <.select_trigger class="w-20" id="select-rows-per-page">
                <.select_value />
              </.select_trigger>
              <.select_content align="start">
                <.select_group>
                  <.select_item value="10">10</.select_item>
                  <.select_item value="25">25</.select_item>
                  <.select_item value="50">50</.select_item>
                  <.select_item value="100">100</.select_item>
                </.select_group>
              </.select_content>
            </.select>
          </.field>
          <.pagination class="mx-0 w-auto">
            <.pagination_content>
              <.pagination_item>
                <.pagination_previous href="#" />
              </.pagination_item>
              <.pagination_item>
                <.pagination_next href="#" />
              </.pagination_item>
            </.pagination_content>
          </.pagination>
        </div>
        """,
        attributes: %{}
      }
    ]
  end
end
