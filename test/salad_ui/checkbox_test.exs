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
end
