defmodule SaladUI.ToggleTest do
  use ComponentCase

  import SaladUI.Toggle

  describe "toggle/1" do
    test "renders an off toggle with Radix state and the toggle hook" do
      assigns = %{}

      html = rendered_to_string(~H|<.toggle id="bold" aria-label="Toggle bold">B</.toggle>|)

      assert html =~ ~s(id="bold")
      assert html =~ ~s(data-slot="toggle")
      assert html =~ ~s(data-component="toggle")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-state="off")
      assert html =~ ~s(aria-pressed="false")
      assert html =~ ~r/<button[^>]*aria-label="Toggle bold"/
      assert html =~ ~s(id="bold-input")
      assert html =~ "data-[state=on]:bg-accent"
      refute html =~ "has-[:checked]"
    end

    test "renders an on toggle from value" do
      assigns = %{}

      html = rendered_to_string(~H|<.toggle id="t" name="bold" value={true}>B</.toggle>|)

      assert html =~ ~s(data-state="on")
      assert html =~ ~s(aria-pressed="true")
      assert html =~ ~r/<input[^>]*type="checkbox"[^>]*checked/
      assert html =~ ~s(<input type="hidden" name="bold" value="false">)
    end

    test "generates an id for the hook when none is given" do
      assigns = %{}

      html = rendered_to_string(~H|<.toggle>B</.toggle>|)

      assert html =~ ~r/<button id="toggle-\d+"/
    end

    test "renders variant and size classes" do
      assigns = %{}

      html = rendered_to_string(~H|<.toggle id="t" variant="outline" size="lg" disabled>B</.toggle>|)

      assert html =~ "border-input"
      assert html =~ "shadow-xs"
      assert html =~ "h-10 min-w-10 px-2.5"
      assert html =~ ~r/<button[^>]*disabled/
      assert html =~ ~s(data-disabled)
    end

    test "maps on-pressed-changed" do
      assigns = %{}

      html = rendered_to_string(~H|<.toggle id="t" on-pressed-changed="bold_changed">B</.toggle>|)

      assert html =~ ~s(&quot;pressed-changed&quot;:&quot;bold_changed&quot;)
    end
  end

  describe "toggle_variants/1" do
    test "falls back to the default variant and size" do
      classes = toggle_variants(%{variant: nil, size: nil})

      assert classes =~ "bg-transparent"
      assert classes =~ "h-9 min-w-9 px-2"
      assert classes =~ "aria-invalid:border-destructive"
    end
  end

  describe "controlled" do
    test "value makes the toggle controlled, default-value does not" do
      assigns = %{}

      controlled = rendered_to_string(~H|<.toggle id="t1" value={false}>B</.toggle>|)
      uncontrolled = rendered_to_string(~H|<.toggle id="t2" default-value={true}>B</.toggle>|)

      assert controlled =~ ~s(data-options="{&quot;controlled&quot;:true}")
      assert uncontrolled =~ ~s(data-options="{&quot;controlled&quot;:false}")
      assert uncontrolled =~ ~s(data-state="on")
    end
  end
end
