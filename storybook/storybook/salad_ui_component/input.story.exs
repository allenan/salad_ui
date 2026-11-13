defmodule Storybook.SaladUIComponents.Input do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Field
  alias SaladUI.InputGroup
  alias SaladUI.Select

  def function, do: &SaladUI.Input.input/1

  def imports,
    do: [
      {SaladStorybookWeb.CoreComponents, [simple_form: 1]},
      {Field, [field: 1, field_group: 1, field_label: 1, field_description: 1]},
      {InputGroup, [input_group: 1, input_group_addon: 1, input_group_input: 1, input_group_text: 1]},
      {Select, [select: 1, select_trigger: 1, select_value: 1, select_content: 1, select_item: 1]},
      {SaladUI.Badge, [badge: 1]},
      {SaladUI.Button, [button: 1]},
      {SaladUI.ButtonGroup, [button_group: 1]}
    ]

  def template do
    """
    <.simple_form :let={f} for={%{}} as={:story} class="w-full">
      <.psb-variation-group/>
    </.simple_form>
    """
  end

  def variations do
    [
      %VariationGroup{
        id: :basic_inputs,
        variations:
          for type <- ~w(text number date color)a do
            %Variation{
              id: type,
              attributes: %{
                type: to_string(type),
                label: String.capitalize("#{type} input"),
                placeholder: String.capitalize("#{type} input")
              }
            }
          end
      },
      %Variation{
        id: :field,
        description: "shadcn input-field: a label and description around the input.",
        template: """
        <.field>
          <.field_label for="input-field-username">Username</.field_label>
          <.input id="input-field-username" type="text" placeholder="Enter your username" />
          <.field_description>
            Choose a unique username for your account.
          </.field_description>
        </.field>
        """
      },
      %Variation{
        id: :fieldgroup,
        description: "shadcn input-fieldgroup: stacked fields with a horizontal button row.",
        template: """
        <.field_group>
          <.field>
            <.field_label for="fieldgroup-name">Name</.field_label>
            <.input id="fieldgroup-name" placeholder="Jordan Lee" />
          </.field>
          <.field>
            <.field_label for="fieldgroup-email">Email</.field_label>
            <.input id="fieldgroup-email" type="email" placeholder="name@example.com" />
            <.field_description>
              We'll send updates to this address.
            </.field_description>
          </.field>
          <.field orientation="horizontal">
            <.button type="reset" variant="outline">Reset</.button>
            <.button type="submit">Submit</.button>
          </.field>
        </.field_group>
        """
      },
      %Variation{
        id: :disabled,
        description: "shadcn input-disabled: `data-disabled` on the field dims its label.",
        template: """
        <.field data-disabled>
          <.field_label for="input-demo-disabled">Email</.field_label>
          <.input id="input-demo-disabled" type="email" placeholder="Email" disabled />
          <.field_description>This field is currently disabled.</.field_description>
        </.field>
        """
      },
      %Variation{
        id: :file,
        description: "shadcn input-file.",
        template: """
        <.field>
          <.field_label for="picture">Picture</.field_label>
          <.input id="picture" type="file" />
          <.field_description>Select a picture to upload.</.field_description>
        </.field>
        """
      },
      %Variation{
        id: :inline,
        description: "shadcn input-inline: input and button in a horizontal field.",
        template: """
        <.field orientation="horizontal">
          <.input type="search" placeholder="Search..." />
          <.button>Search</.button>
        </.field>
        """
      },
      %Variation{
        id: :grid,
        description: "shadcn input-grid: two fields side by side.",
        template: """
        <.field_group class="grid max-w-sm grid-cols-2">
          <.field>
            <.field_label for="first-name">First Name</.field_label>
            <.input id="first-name" placeholder="Jordan" />
          </.field>
          <.field>
            <.field_label for="last-name">Last Name</.field_label>
            <.input id="last-name" placeholder="Lee" />
          </.field>
        </.field_group>
        """
      },
      %Variation{
        id: :required,
        description: "shadcn input-required.",
        template: """
        <.field>
          <.field_label for="input-required">
            Required Field <span class="text-destructive">*</span>
          </.field_label>
          <.input id="input-required" placeholder="This field is required" required />
          <.field_description>This field must be filled out.</.field_description>
        </.field>
        """
      },
      %Variation{
        id: :badge,
        description: "shadcn input-badge: a badge in the label.",
        template: """
        <.field>
          <.field_label for="input-badge">
            Webhook URL <.badge variant="secondary" class="ml-auto">Beta</.badge>
          </.field_label>
          <.input id="input-badge" type="url" placeholder="https://api.example.com/webhook" />
        </.field>
        """
      },
      %Variation{
        id: :input_group,
        description: "shadcn input-input-group: a prefix and an icon around the input.",
        template: """
        <.field>
          <.field_label for="input-group-url">Website URL</.field_label>
          <.input_group id="input-input-group">
            <.input_group_input id="input-group-url" placeholder="example.com" />
            <.input_group_addon>
              <.input_group_text>https://</.input_group_text>
            </.input_group_addon>
            <.input_group_addon align="inline-end">
              <Lucideicons.info />
            </.input_group_addon>
          </.input_group>
        </.field>
        """
      },
      %Variation{
        id: :button_group,
        description: "shadcn input-button-group: an input joined to a button.",
        template: """
        <.field>
          <.field_label for="input-button-group">Search</.field_label>
          <.button_group>
            <.input id="input-button-group" placeholder="Type to search..." />
            <.button variant="outline">Search</.button>
          </.button_group>
        </.field>
        """
      },
      %Variation{
        id: :form,
        description: "shadcn input-form: inputs and a select in a field group.",
        template: """
        <form class="w-full max-w-sm">
          <.field_group>
            <.field>
              <.field_label for="form-name">Name</.field_label>
              <.input id="form-name" type="text" placeholder="Evil Rabbit" required />
            </.field>
            <.field>
              <.field_label for="form-email">Email</.field_label>
              <.input id="form-email" type="email" placeholder="john@example.com" />
              <.field_description>
                We'll never share your email with anyone.
              </.field_description>
            </.field>
            <div class="grid grid-cols-2 gap-4">
              <.field>
                <.field_label for="form-phone">Phone</.field_label>
                <.input id="form-phone" type="tel" placeholder="+1 (555) 123-4567" />
              </.field>
              <.field>
                <.field_label for="form-country">Country</.field_label>
                <.select id="form-country-select" name="country" default-value="us">
                  <.select_trigger id="form-country">
                    <.select_value />
                  </.select_trigger>
                  <.select_content>
                    <.select_item value="us">United States</.select_item>
                    <.select_item value="uk">United Kingdom</.select_item>
                    <.select_item value="ca">Canada</.select_item>
                  </.select_content>
                </.select>
              </.field>
            </div>
            <.field>
              <.field_label for="form-address">Address</.field_label>
              <.input id="form-address" type="text" placeholder="123 Main St" />
            </.field>
            <.field orientation="horizontal">
              <.button type="button" variant="outline">Cancel</.button>
              <.button type="submit">Submit</.button>
            </.field>
          </.field_group>
        </form>
        """
      },
      %Variation{
        id: :invalid,
        description: ~s|Error styling via aria-invalid (set automatically when a form field has errors)|,
        attributes: %{
          type: "email",
          placeholder: "Email",
          "aria-invalid": "true"
        }
      }
    ]
  end
end
