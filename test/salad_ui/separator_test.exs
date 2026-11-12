defmodule SaladUI.SeparatorTest do
  use ComponentCase

  import SaladUI.Separator

  describe "separator/1" do
    test "is a decorative horizontal separator by default" do
      assigns = %{}
      html = rendered_to_string(~H(<.separator class="my-4" />))

      assert html =~ ~s(data-slot="separator")
      assert html =~ ~s(role="none")
      assert html =~ ~s(data-orientation="horizontal")
      refute html =~ "aria-orientation"

      for class <-
            ~w(shrink-0 bg-border data-[orientation=horizontal]:h-px data-[orientation=horizontal]:w-full data-[orientation=vertical]:h-full data-[orientation=vertical]:w-px my-4) do
        assert html =~ class
      end
    end

    test "renders data-orientation for vertical separators" do
      assigns = %{}
      html = rendered_to_string(~H(<.separator orientation="vertical" />))

      assert html =~ ~s(data-orientation="vertical")
      assert html =~ ~s(role="none")
      refute html =~ "aria-orientation"
    end

    test "decorative={false} renders a semantic separator with aria-orientation" do
      assigns = %{}

      vertical = rendered_to_string(~H(<.separator orientation="vertical" decorative={false} />))
      assert vertical =~ ~s(role="separator")
      assert vertical =~ ~s(aria-orientation="vertical")

      horizontal = rendered_to_string(~H(<.separator decorative={false} />))
      assert horizontal =~ ~s(role="separator")
      # horizontal is the implicit aria-orientation of role=separator
      refute horizontal =~ "aria-orientation"
    end

    test "a caller-supplied data-slot wins" do
      assigns = %{}
      html = rendered_to_string(~H(<.separator data-slot="item-separator" />))

      assert html =~ ~s(data-slot="item-separator")
      refute html =~ ~s(data-slot="separator")
    end
  end
end
