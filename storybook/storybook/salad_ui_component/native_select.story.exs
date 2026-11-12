defmodule Storybook.SaladUIComponents.NativeSelect do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Field
  alias SaladUI.NativeSelect

  def function, do: &NativeSelect.native_select/1

  def imports,
    do: [
      {NativeSelect, [native_select_option: 1, native_select_optgroup: 1]},
      {Field, [field: 1, field_label: 1, field_error: 1]}
    ]

  def variations do
    [
      %Variation{
        id: :demo,
        attributes: %{name: "status"},
        slots: [
          """
          <.native_select_option value="">Select status</.native_select_option>
          <.native_select_option value="todo">Todo</.native_select_option>
          <.native_select_option value="in-progress">In Progress</.native_select_option>
          <.native_select_option value="done">Done</.native_select_option>
          <.native_select_option value="cancelled">Cancelled</.native_select_option>
          """
        ]
      },
      %Variation{
        id: :groups,
        description: "`native_select_optgroup` organizes options into categories.",
        attributes: %{name: "department"},
        slots: [
          """
          <.native_select_option value="">Select department</.native_select_option>
          <.native_select_optgroup label="Engineering">
            <.native_select_option value="frontend">Frontend</.native_select_option>
            <.native_select_option value="backend">Backend</.native_select_option>
            <.native_select_option value="devops">DevOps</.native_select_option>
          </.native_select_optgroup>
          <.native_select_optgroup label="Sales">
            <.native_select_option value="sales-rep">Sales Rep</.native_select_option>
            <.native_select_option value="account-manager">Account Manager</.native_select_option>
            <.native_select_option value="sales-director">Sales Director</.native_select_option>
          </.native_select_optgroup>
          <.native_select_optgroup label="Operations">
            <.native_select_option value="support">Customer Support</.native_select_option>
            <.native_select_option value="product-manager">Product Manager</.native_select_option>
            <.native_select_option value="ops-manager">Operations Manager</.native_select_option>
          </.native_select_optgroup>
          """
        ]
      },
      %Variation{
        id: :options,
        description:
          "Generate options and optgroups from `options` (same shapes as `options_for_select/2`); `value` marks the selection.",
        attributes: %{
          name: "department",
          value: "backend",
          prompt: "Select department",
          options: [
            {"Engineering", [{"Frontend", "frontend"}, {"Backend", "backend"}]},
            {"Sales", [{"Sales Rep", "sales-rep"}, [key: "Sales Director", value: "sales-director", disabled: true]]}
          ]
        }
      },
      %Variation{
        id: :disabled,
        attributes: %{name: "priority", disabled: true},
        slots: [
          """
          <.native_select_option value="">Select priority</.native_select_option>
          <.native_select_option value="low">Low</.native_select_option>
          <.native_select_option value="medium">Medium</.native_select_option>
          <.native_select_option value="high">High</.native_select_option>
          <.native_select_option value="critical">Critical</.native_select_option>
          """
        ]
      },
      %Variation{
        id: :invalid,
        description: "`aria-invalid` shows the error styling (set automatically from a form field with errors).",
        attributes: %{name: "role", "aria-invalid": "true"},
        slots: [
          """
          <.native_select_option value="">Select role</.native_select_option>
          <.native_select_option value="admin">Admin</.native_select_option>
          <.native_select_option value="editor">Editor</.native_select_option>
          <.native_select_option value="viewer">Viewer</.native_select_option>
          <.native_select_option value="guest">Guest</.native_select_option>
          """
        ]
      },
      %Variation{
        id: :small,
        attributes: %{name: "size", size: "sm", options: ["Small", "Medium", "Large"]}
      },
      %Variation{
        id: :in_field,
        description: "Inside an invalid `field`, with a label and error.",
        template: """
        <.field invalid class="max-w-xs">
          <.field_label for="native-select-in-field">Role</.field_label>
          <.native_select
            id="native-select-in-field"
            name="role"
            prompt="Select role"
            aria-invalid="true"
            options={[{"Admin", "admin"}, {"Editor", "editor"}, {"Viewer", "viewer"}]}
          />
          <.field_error>Select a role.</.field_error>
        </.field>
        """
      }
    ]
  end
end
