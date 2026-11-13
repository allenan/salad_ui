defmodule Storybook.SaladUIComponents.Checkbox do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Checkbox.checkbox/1

  def imports,
    do: [
      {SaladUI.Label, [{:label, 1}]},
      {SaladUI.Field,
       [field: 1, field_set: 1, field_legend: 1, field_group: 1, field_content: 1, field_label: 1, field_description: 1]},
      {SaladUI.Table, [table: 1, table_header: 1, table_body: 1, table_row: 1, table_head: 1, table_cell: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :checkbox_checked,
        template: """
        <div class="flex items-center space-x-2">
        <.checkbox id="checked" value={true}/>
        <.label for="checked">I'm a label</.label>
        </div>
        """,
        attributes: %{
          value: true
        }
      },
      %Variation{
        id: :checkbox,
        template: """
        <div class="flex items-center space-x-2">
        <.checkbox id="unchecked"/>
        <.label for="unchecked">I'm a label</.label>
        </div>
        """
      },
      %Variation{
        id: :description,
        description: "shadcn checkbox-description: label and description in a `field_content`.",
        template: """
        <.field_group class="mx-auto w-72">
          <.field orientation="horizontal">
            <.checkbox id="terms-checkbox-desc" name="terms-checkbox-desc" value={true} />
            <.field_content>
              <.field_label for="terms-checkbox-desc">Accept terms and conditions</.field_label>
              <.field_description>
                By clicking this checkbox, you agree to the terms and conditions.
              </.field_description>
            </.field_content>
          </.field>
        </.field_group>
        """
      },
      %Variation{
        id: :disabled,
        description: "shadcn checkbox-disabled: `data-disabled` on the field dims its label.",
        template: """
        <.field_group class="mx-auto w-56">
          <.field orientation="horizontal" data-disabled>
            <.checkbox id="toggle-checkbox-disabled" name="toggle-checkbox-disabled" disabled />
            <.field_label for="toggle-checkbox-disabled">Enable notifications</.field_label>
          </.field>
        </.field_group>
        """
      },
      %Variation{
        id: :group,
        description: "shadcn checkbox-group: a fieldset of checkboxes.",
        template: """
        <.field_set>
          <.field_legend variant="label">Show these items on the desktop:</.field_legend>
          <.field_description>Select the items you want to show on the desktop.</.field_description>
          <.field_group class="gap-3">
            <.field orientation="horizontal">
              <.checkbox id="finder-pref-hard-disks-checkbox" name="finder-pref-hard-disks-checkbox" value={true} />
              <.field_label for="finder-pref-hard-disks-checkbox" class="font-normal">Hard disks</.field_label>
            </.field>
            <.field orientation="horizontal">
              <.checkbox id="finder-pref-external-disks-checkbox" name="finder-pref-external-disks-checkbox" value={true} />
              <.field_label for="finder-pref-external-disks-checkbox" class="font-normal">External disks</.field_label>
            </.field>
            <.field orientation="horizontal">
              <.checkbox id="finder-pref-cds-dvds-checkbox" name="finder-pref-cds-dvds-checkbox" />
              <.field_label for="finder-pref-cds-dvds-checkbox" class="font-normal">CDs, DVDs, and iPods</.field_label>
            </.field>
            <.field orientation="horizontal">
              <.checkbox id="finder-pref-connected-servers-checkbox" name="finder-pref-connected-servers-checkbox" />
              <.field_label for="finder-pref-connected-servers-checkbox" class="font-normal">Connected servers</.field_label>
            </.field>
          </.field_group>
        </.field_set>
        """
      },
      %Variation{
        id: :table,
        description: """
        shadcn checkbox-table: row selection checkboxes; a selected row carries `data-state="selected"`.
        Selection state lives on the server, so wire `phx-click` to update `value` and the row's `data-state`.
        """,
        template: """
        <.table>
          <.table_header>
            <.table_row>
              <.table_head class="w-8">
                <.checkbox id="select-all-checkbox" name="select-all-checkbox" aria-label="Select all" />
              </.table_head>
              <.table_head>Name</.table_head>
              <.table_head>Email</.table_head>
              <.table_head>Role</.table_head>
            </.table_row>
          </.table_header>
          <.table_body>
            <.table_row data-state="selected">
              <.table_cell>
                <.checkbox id="row-1-checkbox" name="row-1-checkbox" value={true} />
              </.table_cell>
              <.table_cell class="font-medium">Sarah Chen</.table_cell>
              <.table_cell>sarah.chen@example.com</.table_cell>
              <.table_cell>Admin</.table_cell>
            </.table_row>
            <.table_row>
              <.table_cell>
                <.checkbox id="row-2-checkbox" name="row-2-checkbox" />
              </.table_cell>
              <.table_cell class="font-medium">Marcus Rodriguez</.table_cell>
              <.table_cell>marcus.rodriguez@example.com</.table_cell>
              <.table_cell>User</.table_cell>
            </.table_row>
            <.table_row>
              <.table_cell>
                <.checkbox id="row-3-checkbox" name="row-3-checkbox" />
              </.table_cell>
              <.table_cell class="font-medium">Priya Patel</.table_cell>
              <.table_cell>priya.patel@example.com</.table_cell>
              <.table_cell>User</.table_cell>
            </.table_row>
            <.table_row>
              <.table_cell>
                <.checkbox id="row-4-checkbox" name="row-4-checkbox" />
              </.table_cell>
              <.table_cell class="font-medium">David Kim</.table_cell>
              <.table_cell>david.kim@example.com</.table_cell>
              <.table_cell>Editor</.table_cell>
            </.table_row>
          </.table_body>
        </.table>
        """
      },
      %Variation{
        id: :checkbox_invalid,
        description: ~s|Error styling via aria-invalid (set automatically when a form field has errors)|,
        template: """
        <div class="flex items-center space-x-2">
        <.checkbox id="invalid" aria-invalid="true"/>
        <.label for="invalid">Accept terms and conditions</.label>
        </div>
        """
      }
    ]
  end
end
