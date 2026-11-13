defmodule SaladUI.FieldTest do
  use ComponentCase

  import SaladUI.Field
  import SaladUI.Input

  alias Phoenix.HTML.FormField

  defp form_field(errors, params \\ %{"email" => "x"}) do
    %FormField{
      id: "user_email",
      name: "user[email]",
      value: nil,
      errors: errors,
      field: :email,
      form: %Phoenix.HTML.Form{params: params}
    }
  end

  describe "field_set/1 and field_legend/1" do
    test "renders a fieldset with a legend" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.field_set class="max-w-md" disabled>
          <.field_legend>Profile</.field_legend>
          <.field_legend variant="label">Nested</.field_legend>
        </.field_set>
        """)

      assert html =~ ~s(<fieldset data-slot="field-set")
      assert html =~ "flex flex-col gap-6"
      assert html =~ "max-w-md"
      assert html =~ "disabled"
      assert html =~ ~s(data-slot="field-legend" data-variant="legend")
      assert html =~ ~s(data-variant="label")
      assert html =~ "data-[variant=label]:text-sm"
    end
  end

  describe "field_group/1" do
    test "is the field-group container" do
      assigns = %{}
      html = rendered_to_string(~H"<.field_group>x</.field_group>")

      assert html =~ ~s(data-slot="field-group")
      assert html =~ "@container/field-group"
    end

    test "can be re-labelled as a checkbox group without a duplicate data-slot" do
      assigns = %{}
      html = rendered_to_string(~H|<.field_group data-slot="checkbox-group">x</.field_group>|)

      assert html =~ ~s(data-slot="checkbox-group")
      assert length(Regex.scan(~r/\sdata-slot=/, html)) == 1
    end
  end

  describe "field/1" do
    test "defaults to a vertical group" do
      assigns = %{}
      html = rendered_to_string(~H"<.field>x</.field>")

      assert html =~ ~s(role="group")
      assert html =~ ~s(data-slot="field")
      assert html =~ ~s(data-orientation="vertical")
      assert html =~ "flex-col [&amp;&gt;*]:w-full"
      refute html =~ "data-invalid"
    end

    test "supports horizontal and responsive orientations" do
      assigns = %{}

      horizontal = rendered_to_string(~H|<.field orientation="horizontal">x</.field>|)
      assert horizontal =~ ~s(data-orientation="horizontal")
      assert horizontal =~ "flex-row items-center"

      responsive = rendered_to_string(~H|<.field orientation="responsive">x</.field>|)
      assert responsive =~ ~s(data-orientation="responsive")
      assert responsive =~ "@md/field-group:flex-row"
    end

    test "invalid and a bare data-invalid both render data-invalid=\"true\"" do
      assigns = %{}

      assert rendered_to_string(~H"<.field invalid>x</.field>") =~ ~s(data-invalid="true")

      html = rendered_to_string(~H"<.field data-invalid>x</.field>")
      assert html =~ ~s(data-invalid="true")
      assert count_substring(html, "data-invalid") == 1
    end

    test "takes its error state from a used form field with errors" do
      assigns = %{invalid: form_field([{"can't be blank", []}]), valid: form_field([])}

      assert rendered_to_string(~H"<.field field={@invalid}>x</.field>") =~ ~s(data-invalid="true")
      refute rendered_to_string(~H"<.field field={@valid}>x</.field>") =~ "data-invalid"
    end

    test "ignores errors on a field the user has not touched" do
      assigns = %{f: form_field([{"can't be blank", []}], %{"other" => "x"})}

      refute rendered_to_string(~H"<.field field={@f}>x</.field>") =~ "data-invalid"
    end
  end

  describe "field_content/1, field_title/1 and field_description/1" do
    test "render their slots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.field_content>
          <.field_title>Enable Touch ID</.field_title>
          <.field_description>Unlock faster. <a href="#">More</a></.field_description>
        </.field_content>
        """)

      assert html =~ ~s(data-slot="field-content")
      assert html =~ ~r/<div data-slot="field-label"[^>]*>\s*Enable Touch ID/
      assert html =~ ~s(<p data-slot="field-description")
      assert html =~ "[&amp;&gt;a]:underline"
    end
  end

  describe "field_label/1" do
    test "renders a label with the field-label slot" do
      assigns = %{}
      html = rendered_to_string(~H|<.field_label for="email" class="font-normal">Email</.field_label>|)

      assert html =~ ~s(<label)
      assert html =~ ~s(for="email")
      assert html =~ ~s(data-slot="field-label")
      assert html =~ "font-normal"
      refute html =~ "font-medium"
      assert length(Regex.scan(~r/\sdata-slot=/, html)) == 1
    end

    test "points at the form field's control" do
      assigns = %{f: form_field([])}

      assert rendered_to_string(~H"<.field_label field={@f}>Email</.field_label>") =~ ~s(for="user_email")
    end
  end

  describe "field_separator/1" do
    test "renders a bare line" do
      assigns = %{}
      html = rendered_to_string(~H"<.field_separator />")

      assert html =~ ~s(data-slot="field-separator")
      assert html =~ ~s(data-content="false")
      assert html =~ ~s(data-slot="separator")
      refute html =~ "field-separator-content"
    end

    test "renders inline content" do
      assigns = %{}
      html = rendered_to_string(~H"<.field_separator>Or continue with</.field_separator>")

      assert html =~ ~s(data-content="true")
      assert html =~ ~r/data-slot="field-separator-content"[^>]*>\s*Or continue with/
    end
  end

  describe "field_error/1" do
    test "renders nothing without content" do
      assigns = %{f: form_field([])}

      assert rendered_to_string(~H"<.field_error />") == ""
      assert rendered_to_string(~H"<.field_error field={@f} />") == ""
      assert rendered_to_string(~H"<.field_error errors={[nil]} />") == ""
    end

    test "renders its inner block as an alert" do
      assigns = %{}
      html = rendered_to_string(~H"<.field_error>Choose another username.</.field_error>")

      assert html =~ ~s(role="alert")
      assert html =~ ~s(data-slot="field-error")
      assert html =~ "text-destructive"
      assert html =~ "Choose another username."
    end

    test "renders a single error as text and several as a deduplicated list" do
      assigns = %{}

      single = rendered_to_string(~H|<.field_error errors={["Too short", "Too short"]} />|)
      assert single =~ "Too short"
      refute single =~ "<ul"

      many =
        rendered_to_string(~H"""
        <.field_error errors={[
          "Too short",
          %{message: "Needs a digit"},
          {"max %{count}", [count: 3]},
          "Too short"
        ]} />
        """)

      assert many =~ ~s(<ul class="ms-4 flex list-disc flex-col gap-1">)
      assert count_substring(many, "<li>") == 3
      assert many =~ "Needs a digit"
      assert many =~ "max 3"
    end

    test "shows a used form field's translated errors" do
      assigns = %{f: form_field([{"should be at least %{count} character(s)", [count: 3]}])}

      html = rendered_to_string(~H"<.field_error field={@f} />")
      assert html =~ "should be at least 3 character(s)"
    end

    test "hides errors on a field the user has not touched" do
      assigns = %{f: form_field([{"can't be blank", []}], %{"other" => "x"})}

      assert rendered_to_string(~H"<.field_error field={@f} />") == ""
    end
  end

  test "composes with a form field end to end" do
    assigns = %{f: form_field([{"can't be blank", []}])}

    html =
      rendered_to_string(~H"""
      <.field field={@f}>
        <.field_label field={@f}>Email</.field_label>
        <.input field={@f} type="email" />
        <.field_error field={@f} />
      </.field>
      """)

    assert html =~ ~s(data-invalid="true")
    assert html =~ ~s(for="user_email")
    assert html =~ ~s(aria-invalid="true")
    assert html =~ "can&#39;t be blank"
  end

  test "follows a real form's used-input tracking" do
    errors = [email: {"is invalid", []}, name: {"can't be blank", []}]
    assigns = %{f: to_form(%{"email" => "rabbit"}, errors: errors)}

    html =
      rendered_to_string(~H"""
      <.field field={@f[:email]}><.field_error field={@f[:email]} /></.field>
      <.field field={@f[:name]}><.field_error field={@f[:name]} /></.field>
      """)

    assert count_substring(html, ~s(data-invalid="true")) == 1
    assert html =~ "is invalid"
    refute html =~ "blank"
  end
end
