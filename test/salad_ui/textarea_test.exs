defmodule SaladUI.TextareaTest do
  use ComponentCase

  import SaladUI.Textarea

  test "passes through standard textarea attributes" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.textarea
        id="bio"
        name="bio"
        placeholder="Tell us about yourself"
        required
        readonly
        maxlength="200"
        minlength="10"
        rows="4"
        autocomplete="off"
        wrap="soft"
      />
      """)

    assert html =~ ~s(id="bio")
    assert html =~ ~s(name="bio")
    assert html =~ ~s(placeholder="Tell us about yourself")
    assert html =~ "required"
    assert html =~ "readonly"
    assert html =~ ~s(maxlength="200")
    assert html =~ ~s(minlength="10")
    assert html =~ ~s(rows="4")
    assert html =~ ~s(autocomplete="off")
    assert html =~ ~s(wrap="soft")
  end

  test "renders the value as content" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.textarea name="bio" value="hello" />
      """)

    assert html =~ ">hello</textarea>" or html =~ ">\nhello</textarea>"
  end
end
