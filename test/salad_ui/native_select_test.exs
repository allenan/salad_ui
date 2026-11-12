defmodule SaladUI.NativeSelectTest do
  use ComponentCase

  import SaladUI.NativeSelect

  alias Phoenix.HTML.FormField

  defp form_field(errors, value \\ "editor", params \\ %{"role" => "editor"}) do
    %FormField{
      id: "user_role",
      name: "user[role]",
      value: value,
      errors: errors,
      field: :role,
      form: %Phoenix.HTML.Form{params: params}
    }
  end

  test "renders a wrapped select with a chevron icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.native_select id="status" name="status" class="w-48" required>
        <.native_select_option value="">Select status</.native_select_option>
        <.native_select_option value="todo">Todo</.native_select_option>
      </.native_select>
      """)

    assert html =~ ~s(data-slot="native-select-wrapper")
    assert html =~ "has-[select:disabled]:opacity-50"
    assert html =~ ~s(<select id="status" name="status" data-slot="native-select" data-size="default")
    assert html =~ "appearance-none"
    assert html =~ "bg-transparent"
    assert html =~ "bg-none"
    assert html =~ "w-48"
    assert html =~ "required"
    assert html =~ ~s(data-slot="native-select-icon")
    assert html =~ ~s(aria-hidden="true")
    assert html =~ ~s(<option data-slot="native-select-option" value="todo" class="bg-[Canvas] text-[CanvasText]">)
    refute html =~ "multiple"
  end

  test "supports the sm size and disabled state" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.native_select name="p" size="sm" disabled>
        <.native_select_option value="low">Low</.native_select_option>
      </.native_select>
      """)

    assert html =~ ~s(data-size="sm")
    assert html =~ "data-[size=sm]:h-8"
    assert html =~ "disabled"
  end

  test "renders optgroups and option attributes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.native_select name="dept">
        <.native_select_optgroup label="Engineering" disabled>
          <.native_select_option value="frontend" selected>Frontend</.native_select_option>
          <.native_select_option value="backend" disabled>Backend</.native_select_option>
        </.native_select_optgroup>
      </.native_select>
      """)

    assert html =~ ~s(<optgroup data-slot="native-select-optgroup" label="Engineering")
    assert html =~ ~r/<optgroup[^>]*disabled/
    assert html =~ ~r/value="frontend"[^>]*selected/
    assert html =~ ~r/value="backend"[^>]*disabled/
  end

  test "generates options, groups and a prompt from the options attribute" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.native_select
        name="dept"
        value="backend"
        prompt="Select department"
        options={[
          {"Engineering", [{"Frontend", "frontend"}, {"Backend", "backend"}]},
          {"Sales", ["Sales Rep", [key: "Director", value: "director", disabled: true]]},
          {"Other", "other"}
        ]}
      />
      """)

    assert html =~ ~r/<option[^>]*value=""[^>]*>\s*Select department/
    assert html =~ ~s(label="Engineering")
    assert html =~ ~s(label="Sales")
    assert html =~ ~r/value="backend"[^>]*selected[^>]*>\s*Backend/
    refute html =~ ~r/value="frontend"[^>]*selected/
    assert html =~ ~r/value="Sales Rep"[^>]*>\s*Sales Rep/
    assert html =~ ~r/value="director"[^>]*disabled[^>]*>\s*Director/
    assert html =~ ~r/value="other"[^>]*>\s*Other/
    assert count_substring(html, "<optgroup") == 2
  end

  test "selects several values when multiple" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.native_select name="tags[]" multiple value={["a", "c"]} options={~w(a b c)} />
      """)

    assert html =~ "multiple"
    assert html =~ ~r/value="a"[^>]*selected/
    refute html =~ ~r/value="b"[^>]*selected/
    assert html =~ ~r/value="c"[^>]*selected/
  end

  test "takes id, name, value and errors from a form field" do
    assigns = %{f: form_field([{"is invalid", []}])}

    html =
      rendered_to_string(~H"""
      <.native_select field={@f} options={[{"Admin", "admin"}, {"Editor", "editor"}]} />
      """)

    assert html =~ ~s(id="user_role")
    assert html =~ ~s(name="user[role]")
    assert html =~ ~r/value="editor"[^>]*selected/
    assert html =~ ~s(aria-invalid="true")
  end

  test "no aria-invalid for a valid or untouched field; explicit aria-invalid wins" do
    assigns = %{
      valid: form_field([]),
      untouched: form_field([{"is invalid", []}], nil, %{"other" => "x"})
    }

    refute rendered_to_string(~H"<.native_select field={@valid} options={[]} />") =~ "aria-invalid="
    refute rendered_to_string(~H"<.native_select field={@untouched} options={[]} />") =~ "aria-invalid="

    assert rendered_to_string(~H|<.native_select name="x" aria-invalid="true" options={[]} />|) =~
             ~s(aria-invalid="true")
  end
end
