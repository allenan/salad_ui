defmodule Storybook.SaladUIComponents.Select do
  @moduledoc """
  Storybook documentation for the SaladUI Select component.

  The Select component provides a dropdown menu for selecting options from a list.
  """
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Select.select/1

  def imports,
    do: [
      {SaladUI.Select,
       [
         select_trigger: 1,
         select_content: 1,
         select_group: 1,
         select_label: 1,
         select_item: 1,
         select_value: 1,
         select_separator: 1
       ]},
      {SaladUI.Button, [button: 1]}
    ]

  def description do
    """
    The Select component allows users to choose one option from a dropdown list.
    It supports single and multiple selection modes, grouping of options, and disabled states.
    """
  end

  def variations do
    [
      %Variation{
        id: :default_select,
        description: "A select component with default styling and behavior",
        attributes: %{
          id: "fruit-select",
          name: "fruit",
          "on-value-changed": "value_changed",
          "use-portal": false
        },
        slots: [
          """
            <.select_trigger class="w-[180px]">
              <.select_value placeholder="Select a fruit" />
            </.select_trigger>
            <.select_content>
              <.select_group>
                <.select_label>Fruits</.select_label>
                <.select_item value="apple">Apple</.select_item>
                <.select_item value="banana">Banana</.select_item>
                <.select_item value="blueberry">Blueberry</.select_item>
                <.select_separator />
                <.select_item disabled value="grapes">Grapes</.select_item>
                <.select_item value="pineapple">Pineapple</.select_item>
              </.select_group>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :groups,
        description: "Groups, labels and a separator",
        attributes: %{id: "groups-select", name: "food", "use-portal": false},
        slots: [
          """
            <.select_trigger class="w-full max-w-48">
              <.select_value placeholder="Select a fruit" />
            </.select_trigger>
            <.select_content>
              <.select_group>
                <.select_label>Fruits</.select_label>
                <.select_item value="apple">Apple</.select_item>
                <.select_item value="banana">Banana</.select_item>
                <.select_item value="blueberry">Blueberry</.select_item>
              </.select_group>
              <.select_separator />
              <.select_group>
                <.select_label>Vegetables</.select_label>
                <.select_item value="carrot">Carrot</.select_item>
                <.select_item value="broccoli">Broccoli</.select_item>
                <.select_item value="spinach">Spinach</.select_item>
              </.select_group>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :scrollable,
        description: "A long list scrolls inside the content; the scroll buttons appear while there is more to see",
        attributes: %{id: "timezone-select", name: "timezone", "use-portal": false},
        slots: [
          """
            <.select_trigger class="w-full max-w-64">
              <.select_value placeholder="Select a timezone" />
            </.select_trigger>
            <.select_content>
              <.select_group>
                <.select_label>North America</.select_label>
                <.select_item value="est">Eastern Standard Time</.select_item>
                <.select_item value="cst">Central Standard Time</.select_item>
                <.select_item value="mst">Mountain Standard Time</.select_item>
                <.select_item value="pst">Pacific Standard Time</.select_item>
                <.select_item value="akst">Alaska Standard Time</.select_item>
                <.select_item value="hst">Hawaii Standard Time</.select_item>
              </.select_group>
              <.select_group>
                <.select_label>Europe &amp; Africa</.select_label>
                <.select_item value="gmt">Greenwich Mean Time</.select_item>
                <.select_item value="cet">Central European Time</.select_item>
                <.select_item value="eet">Eastern European Time</.select_item>
                <.select_item value="west">Western European Summer Time</.select_item>
                <.select_item value="cat">Central Africa Time</.select_item>
                <.select_item value="eat">East Africa Time</.select_item>
              </.select_group>
              <.select_group>
                <.select_label>Asia</.select_label>
                <.select_item value="msk">Moscow Time</.select_item>
                <.select_item value="ist">India Standard Time</.select_item>
                <.select_item value="cst_china">China Standard Time</.select_item>
                <.select_item value="jst">Japan Standard Time</.select_item>
                <.select_item value="kst">Korea Standard Time</.select_item>
                <.select_item value="ist_indonesia">Indonesia Central Standard Time</.select_item>
              </.select_group>
              <.select_group>
                <.select_label>Australia &amp; Pacific</.select_label>
                <.select_item value="awst">Australian Western Standard Time</.select_item>
                <.select_item value="acst">Australian Central Standard Time</.select_item>
                <.select_item value="aest">Australian Eastern Standard Time</.select_item>
                <.select_item value="nzst">New Zealand Standard Time</.select_item>
                <.select_item value="fjt">Fiji Time</.select_item>
              </.select_group>
              <.select_group>
                <.select_label>South America</.select_label>
                <.select_item value="art">Argentina Time</.select_item>
                <.select_item value="bot">Bolivia Time</.select_item>
                <.select_item value="brt">Brasilia Time</.select_item>
                <.select_item value="clt">Chile Standard Time</.select_item>
              </.select_group>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :align_item,
        description:
          ~s|`position="item-aligned"` (shadcn's default) lines the selected item up over the trigger; `position="popper"` (SaladUI's default) opens below it|,
        template: """
        <div class="flex w-full max-w-xs flex-col gap-6">
          <div class="flex flex-col gap-2">
            <span class="text-sm font-medium">Item aligned</span>
            <.select id="align-item-select" name="fruit" default-value="banana">
              <.select_trigger class="w-full">
                <.select_value />
              </.select_trigger>
              <.select_content position="item-aligned">
                <.select_group>
                  <.select_item value="apple">Apple</.select_item>
                  <.select_item value="banana">Banana</.select_item>
                  <.select_item value="blueberry">Blueberry</.select_item>
                  <.select_item value="grapes">Grapes</.select_item>
                  <.select_item value="pineapple">Pineapple</.select_item>
                </.select_group>
              </.select_content>
            </.select>
          </div>
          <div class="flex flex-col gap-2">
            <span class="text-sm font-medium">Popper</span>
            <.select id="popper-select" name="fruit" default-value="banana">
              <.select_trigger class="w-full">
                <.select_value />
              </.select_trigger>
              <.select_content position="popper">
                <.select_group>
                  <.select_item value="apple">Apple</.select_item>
                  <.select_item value="banana">Banana</.select_item>
                  <.select_item value="blueberry">Blueberry</.select_item>
                  <.select_item value="grapes">Grapes</.select_item>
                  <.select_item value="pineapple">Pineapple</.select_item>
                </.select_group>
              </.select_content>
            </.select>
          </div>
        </div>
        """
      },
      %Variation{
        id: :side_and_align,
        description: ~s|Popper placement on another `side`, with `align`|,
        attributes: %{id: "side-select", name: "fruit", "use-portal": false},
        slots: [
          """
            <.select_trigger class="w-[180px]">
              <.select_value placeholder="Select a fruit" />
            </.select_trigger>
            <.select_content side="right" align="center">
              <.select_item value="apple">Apple</.select_item>
              <.select_item value="banana">Banana</.select_item>
              <.select_item value="blueberry">Blueberry</.select_item>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :disabled,
        description: "`disabled` on the select, and a disabled item",
        attributes: %{id: "disabled-select", name: "fruit", disabled: true, "use-portal": false},
        slots: [
          """
            <.select_trigger class="w-full max-w-48">
              <.select_value placeholder="Select a fruit" />
            </.select_trigger>
            <.select_content>
              <.select_group>
                <.select_item value="apple">Apple</.select_item>
                <.select_item value="banana">Banana</.select_item>
                <.select_item value="blueberry">Blueberry</.select_item>
                <.select_item value="grapes" disabled>Grapes</.select_item>
                <.select_item value="pineapple">Pineapple</.select_item>
              </.select_group>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :invalid,
        description:
          ~s|Error styling via aria-invalid on the trigger (a form field with errors sets data-invalid on the root, which styles and marks the trigger automatically)|,
        attributes: %{
          id: "invalid-select",
          name: "fruit",
          "use-portal": false
        },
        slots: [
          """
            <.select_trigger class="w-[180px]" aria-invalid="true">
              <.select_value placeholder="Select a fruit" />
            </.select_trigger>
            <.select_content>
              <.select_item value="apple">Apple</.select_item>
              <.select_item value="banana">Banana</.select_item>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :small,
        description: ~s|`size="sm"` on the trigger|,
        attributes: %{
          id: "small-select",
          name: "fruit",
          "use-portal": false
        },
        slots: [
          """
            <.select_trigger size="sm" class="w-[180px]">
              <.select_value placeholder="Select a fruit" />
            </.select_trigger>
            <.select_content>
              <.select_item value="apple">Apple</.select_item>
              <.select_item value="banana">Banana</.select_item>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :with_default_value,
        description: "A select component with a pre-selected default value",
        attributes: %{
          id: "preset-select",
          name: "fruit",
          value: "banana",
          "use-portal": false
        },
        slots: [
          """
            <.select_trigger class="w-[180px]">
              <.select_value />
            </.select_trigger>
            <.select_content>
              <.select_item value="apple">Apple</.select_item>
              <.select_item value="banana">Banana</.select_item>
              <.select_item value="orange">Orange</.select_item>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :in_form,
        description: "A select component used within a LiveView form with phx-change",
        attributes: %{
          id: "form-select",
          name: "fruit",
          "use-portal": false
        },
        template: """
        <form phx-change="validate" phx-submit="save" class="space-y-4">
          <div>
            <label for="form-select" class="block text-sm font-medium text-gray-700 mb-1">
              Select a fruit
            </label>
            <.psb-variation />
          </div>
          <.button type="submit">Submit</.button>
        </form>
        """,
        slots: [
          """
            <.select_trigger class="min-w-64 w-full">
              <.select_value placeholder="Choose an option" />
            </.select_trigger>
            <.select_content>
              <.select_group>
                <.select_item value="apple">Apple</.select_item>
                <.select_item value="banana">Banana</.select_item>
                <.select_item value="blueberry">Blueberry</.select_item>
              </.select_group>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :multiple_select,
        description: "A multiple select that submits list params with a [] input name",
        attributes: %{
          id: "skills-select",
          name: "skills",
          multiple: true,
          value: ["elixir"],
          "use-portal": false,
          "on-value-changed": "value_changed"
        },
        slots: [
          """
            <.select_trigger class="w-[220px]">
              <.select_value placeholder="Select skills" />
            </.select_trigger>
            <.select_content>
              <.select_group>
                <.select_label>Skills</.select_label>
                <.select_item value="elixir">Elixir</.select_item>
                <.select_item value="phoenix">Phoenix</.select_item>
                <.select_item value="liveview">LiveView</.select_item>
              </.select_group>
            </.select_content>
          """
        ]
      },
      %Variation{
        id: :rtl,
        description: "Right-to-left",
        template: """
        <div dir="rtl">
          <.select id="rtl-select" name="fruit">
            <.select_trigger class="w-32">
              <.select_value placeholder="اختر فاكهة" />
            </.select_trigger>
            <.select_content>
              <.select_group>
                <.select_label>الفواكه</.select_label>
                <.select_item value="apple">تفاح</.select_item>
                <.select_item value="banana">موز</.select_item>
                <.select_item value="blueberry">توت أزرق</.select_item>
                <.select_item value="grapes">عنب</.select_item>
                <.select_item value="pineapple">أناناس</.select_item>
              </.select_group>
              <.select_separator />
              <.select_group>
                <.select_label>الخضروات</.select_label>
                <.select_item value="carrot">جزر</.select_item>
                <.select_item value="broccoli">بروكلي</.select_item>
                <.select_item value="spinach">سبانخ</.select_item>
              </.select_group>
            </.select_content>
          </.select>
        </div>
        """
      }
    ]
  end
end
