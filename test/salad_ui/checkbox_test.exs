defmodule SaladUI.CheckboxTest do
  use ComponentCase

  import SaladUI.Checkbox

  describe "Test Checkbox" do
    test "It renders checkbox correctly" do
      assigns = %{form: [:remember_me]}

      html =
        rendered_to_string(~H"""
        <.checkbox class="!border-destructive" name="remember_me" value={true} />
        """)

      assert html =~ "name=\"remember_me\""
      assert html =~ "value=\"true\" checked>"
      assert html =~ ~s(<input type="hidden" name="remember_me" value="false">)

      for css_class <-
            ~w(peer size-4 shrink-0 rounded-[4px] border border-input shadow-xs outline-none focus:ring-0 focus:ring-offset-0 focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 checked:border-primary checked:bg-primary checked:text-primary-foreground) do
        assert html =~ css_class
      end
    end
  end

  describe "submitted values" do
    test "checked_value, unchecked_value={nil} and checked build a checkbox group" do
      assigns = %{tags: ["elixir"]}

      html =
        rendered_to_string(~H"""
        <.checkbox
          :for={tag <- ~w(elixir gleam)}
          name="tags[]"
          checked_value={tag}
          unchecked_value={nil}
          checked={tag in @tags}
        />
        """)

      refute html =~ ~s(type="hidden")
      assert html =~ ~r/name="tags\[\]" value="elixir" checked>/
      assert html =~ ~r/name="tags\[\]" value="gleam">/
    end

    test "unchecked_value sets the hidden input; checked overrides value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox name="plan" checked_value="pro" unchecked_value="free" value={true} checked={false} />
        """)

      assert html =~ ~s(<input type="hidden" name="plan" value="free">)
      assert html =~ ~r/value="pro">/
      refute html =~ "checked>"
    end
  end

  describe "indeterminate" do
    test "a boolean attaches the checkbox hook and renders data-indeterminate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="select-all" indeterminate={true} aria-label="Select all" />
        """)

      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-component="checkbox")
      assert html =~ ~s(data-part="root")
      assert html =~ ~s(data-indeterminate="true")

      html =
        rendered_to_string(~H"""
        <.checkbox id="select-all" value={true} indeterminate={false} />
        """)

      assert html =~ ~s(data-indeterminate="false")
      assert html =~ "checked"
    end

    test "nil (the default) renders a plain checkbox without the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="terms" />
        """)

      refute html =~ "phx-hook"
      refute html =~ "data-component"
      refute html =~ "data-indeterminate"
    end

    test "disabled is passed to the input, as for an empty select-all" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.checkbox id="select-all" indeterminate={false} disabled={true} />
        <.checkbox id="other" disabled={false} />
        """)

      [select_all, other] = ~r/<input type="checkbox"[^>]*>/ |> Regex.scan(html) |> List.flatten()
      assert select_all =~ ~s(id="select-all") and select_all =~ ~r/\sdisabled[\s>]/
      assert other =~ ~s(id="other")
      refute other =~ ~r/\sdisabled[\s>]/
    end
  end
end
