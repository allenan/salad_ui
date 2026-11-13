defmodule Storybook.SaladUIComponents.Combobox do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Combobox

  def function, do: &Combobox.combobox/1
  def layout, do: :one_column

  def imports,
    do: [
      {Combobox,
       [
         combobox_input: 1,
         combobox_trigger: 1,
         combobox_value: 1,
         combobox_content: 1,
         combobox_list: 1,
         combobox_item: 1,
         combobox_group: 1,
         combobox_label: 1,
         combobox_separator: 1,
         combobox_empty: 1,
         combobox_chips: 1,
         combobox_chip: 1,
         combobox_chips_input: 1
       ]},
      {SaladUI.InputGroup, [input_group_addon: 1]},
      {SaladUI.Item, [item: 1, item_content: 1, item_title: 1, item_description: 1]},
      {SaladUI.Field, [field: 1, field_label: 1]},
      {Lucideicons, [globe: 1]}
    ]

  def description do
    """
    Autocomplete input with a list of suggestions. Type to filter, use the
    arrow keys and Enter to pick. See the "Combobox server filtering" example
    for filtering on the server through a form's phx-change.
    """
  end

  @frameworks ~s(["Next.js", "SvelteKit", "Nuxt.js", "Remix", "Astro"])

  @timezones """
  [
    {"Americas", ["(GMT-5) New York", "(GMT-8) Los Angeles", "(GMT-6) Chicago", "(GMT-5) Toronto", "(GMT-8) Vancouver", "(GMT-3) São Paulo"]},
    {"Europe", ["(GMT+0) London", "(GMT+1) Paris", "(GMT+1) Berlin", "(GMT+1) Rome", "(GMT+1) Madrid", "(GMT+1) Amsterdam"]},
    {"Asia/Pacific", ["(GMT+9) Tokyo", "(GMT+8) Shanghai", "(GMT+8) Singapore", "(GMT+4) Dubai", "(GMT+11) Sydney", "(GMT+9) Seoul"]}
  ]
  """

  @countries """
  [
    {"ar", "Argentina", "South America"},
    {"au", "Australia", "Oceania"},
    {"br", "Brazil", "South America"},
    {"ca", "Canada", "North America"},
    {"cn", "China", "Asia"},
    {"co", "Colombia", "South America"},
    {"eg", "Egypt", "Africa"},
    {"fr", "France", "Europe"},
    {"de", "Germany", "Europe"},
    {"it", "Italy", "Europe"},
    {"jp", "Japan", "Asia"},
    {"ke", "Kenya", "Africa"},
    {"mx", "Mexico", "North America"},
    {"nz", "New Zealand", "Oceania"},
    {"ng", "Nigeria", "Africa"},
    {"za", "South Africa", "Africa"},
    {"kr", "South Korea", "Asia"},
    {"gb", "United Kingdom", "Europe"},
    {"us", "United States", "North America"}
  ]
  """

  defp framework_list do
    """
    <.combobox_content>
      <.combobox_empty>No items found.</.combobox_empty>
      <.combobox_list>
        <.combobox_item :for={item <- #{@frameworks}} value={item}>{item}</.combobox_item>
      </.combobox_list>
    </.combobox_content>
    """
  end

  def variations do
    [
      %Variation{
        id: :basic,
        description: "A simple combobox with a list of frameworks.",
        template: """
        <.combobox id="combobox-basic" name="framework">
          <.combobox_input placeholder="Select a framework" />
          #{framework_list()}
        </.combobox>
        """
      },
      %Variation{
        id: :multiple,
        description: "Multiple selection with chips (`multiple` + `combobox_chips`).",
        template: """
        <.combobox id="combobox-multiple" name="frameworks" multiple auto-highlight default-value={["Next.js"]}>
          <.combobox_chips class="w-full max-w-xs">
            <.combobox_chips_input />
          </.combobox_chips>
          #{framework_list()}
        </.combobox>
        """
      },
      %Variation{
        id: :clear,
        description: "`show-clear` replaces the chevron with a clear button while a value is selected.",
        template: """
        <.combobox id="combobox-clear" default-value="Next.js">
          <.combobox_input placeholder="Select a framework" show-clear />
          #{framework_list()}
        </.combobox>
        """
      },
      %Variation{
        id: :groups,
        description: "Groups with labels and separators.",
        template: """
        <.combobox id="combobox-groups">
          <.combobox_input placeholder="Select a timezone" />
          <.combobox_content>
            <.combobox_empty>No timezones found.</.combobox_empty>
            <.combobox_list>
              <.combobox_group :for={{{label, zones}, index} <- Enum.with_index(#{@timezones})}>
                <.combobox_label>{label}</.combobox_label>
                <.combobox_item :for={zone <- zones} value={zone}>{zone}</.combobox_item>
                <.combobox_separator :if={index < 2} />
              </.combobox_group>
            </.combobox_list>
          </.combobox_content>
        </.combobox>
        """
      },
      %Variation{
        id: :custom_items,
        description: "Custom item content; `label` is what is matched and shown once selected.",
        template: """
        <.combobox id="combobox-custom">
          <.combobox_input placeholder="Search countries..." />
          <.combobox_content>
            <.combobox_empty>No countries found.</.combobox_empty>
            <.combobox_list>
              <.combobox_item :for={{code, label, continent} <- #{@countries}} value={code} label={label}>
                <.item size="xs" class="p-0">
                  <.item_content>
                    <.item_title class="whitespace-nowrap">{label}</.item_title>
                    <.item_description>{continent} ({code})</.item_description>
                  </.item_content>
                </.item>
              </.combobox_item>
            </.combobox_list>
          </.combobox_content>
        </.combobox>
        """
      },
      %Variation{
        id: :invalid,
        description: "`aria-invalid` on the input (a `field` with errors does the same).",
        template: """
        <.combobox id="combobox-invalid">
          <.combobox_input placeholder="Select a framework" aria-invalid="true" />
          #{framework_list()}
        </.combobox>
        """
      },
      %Variation{
        id: :disabled,
        description: "A disabled input.",
        template: """
        <.combobox id="combobox-disabled">
          <.combobox_input placeholder="Select a framework" disabled />
          #{framework_list()}
        </.combobox>
        """
      },
      %Variation{
        id: :auto_highlight,
        description: "`auto-highlight` highlights the first match while typing, so Enter picks it.",
        template: """
        <.combobox id="combobox-auto-highlight" auto-highlight>
          <.combobox_input placeholder="Select a framework" />
          #{framework_list()}
        </.combobox>
        """
      },
      %Variation{
        id: :popup,
        description: "A button opens the list; the search input sits inside the content.",
        template: """
        <.combobox id="combobox-popup" default-value="ar">
          <.combobox_trigger variant="outline" class="w-64 justify-between font-normal">
            <.combobox_value placeholder="Select a country" />
          </.combobox_trigger>
          <.combobox_content>
            <.combobox_input show-trigger={false} placeholder="Search" />
            <.combobox_empty>No items found.</.combobox_empty>
            <.combobox_list>
              <.combobox_item :for={{code, label, _continent} <- #{@countries}} value={code}>{label}</.combobox_item>
            </.combobox_list>
          </.combobox_content>
        </.combobox>
        """
      },
      %Variation{
        id: :input_group,
        description: "An addon inside the input.",
        template: """
        <.combobox id="combobox-input-group">
          <.combobox_input placeholder="Select a timezone">
            <.input_group_addon>
              <.globe />
            </.input_group_addon>
          </.combobox_input>
          <.combobox_content align-offset={-28} class="w-60">
            <.combobox_empty>No timezones found.</.combobox_empty>
            <.combobox_list>
              <.combobox_group :for={{label, zones} <- #{@timezones}}>
                <.combobox_label>{label}</.combobox_label>
                <.combobox_item :for={zone <- zones} value={zone}>{zone}</.combobox_item>
              </.combobox_group>
            </.combobox_list>
          </.combobox_content>
        </.combobox>
        """
      },
      %Variation{
        id: :rtl,
        description: "Right-to-left, inside a field.",
        template: """
        <div dir="rtl" class="w-full max-w-xs">
          <.field>
            <.field_label for="combobox-rtl-input">إطار العمل</.field_label>
            <.combobox id="combobox-rtl">
              <.combobox_input id="combobox-rtl-input" placeholder="اختر إطار عمل" />
              <.combobox_content align="end">
                <.combobox_empty>لم يتم العثور على عناصر.</.combobox_empty>
                <.combobox_list>
                  <.combobox_item :for={item <- #{@frameworks}} value={item}>{item}</.combobox_item>
                </.combobox_list>
              </.combobox_content>
            </.combobox>
          </.field>
        </div>
        """
      }
    ]
  end
end
