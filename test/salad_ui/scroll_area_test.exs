defmodule SaladUi.ScrollAreaTest do
  use ComponentCase

  import SaladUI.ScrollArea
  import SaladUI.Separator

  describe "Test scroll_area" do
    test "It renders scroll_area correctly" do
      assigns = %{}

      html =
        ~H"""
        <.scroll_area>
          <div class="p-4">
            <h4 class="mb-4 text-sm font-medium leading-none">Tags</h4>
            <%= for tag <- 1..50 do %>
              <div class="text-sm">
                v1.2.0-beta.{tag}
              </div>
              <.separator class="my-2" />
            <% end %>
          </div>
        </.scroll_area>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(<div data-slot="scroll-area" data-orientation="vertical" class="relative">)
      assert html =~ "<div class=\"p-4\">"
      assert html =~ "<h4 class=\"mb-4 text-sm font-medium leading-none\">Tags</h4>"
      assert html =~ ~s(data-slot="scroll-area-viewport")

      for class <-
            ~w|size-full rounded-[inherit] [scrollbar-width:thin] [scrollbar-color:var(--border)_transparent] overflow-x-hidden overflow-y-auto| do
        assert html =~ class
      end

      for tag <- 1..50 do
        assert html =~ "v1.2.0-beta.#{tag}"
      end
    end

    test "It scrolls horizontally with orientation=horizontal" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area orientation="horizontal" class="w-96 whitespace-nowrap">
          <div class="flex w-max space-x-4 p-4">Wide</div>
        </.scroll_area>
        """)

      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ "overflow-x-auto overflow-y-hidden"
      refute html =~ "overflow-x-hidden"
      assert html =~ "w-96 whitespace-nowrap"
    end

    test "It scrolls both axes with orientation=both" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.scroll_area orientation="both">Content</.scroll_area>
        """)

      assert html =~ ~s(data-orientation="both")
      assert html =~ "overflow-auto"
      refute html =~ "overflow-x-hidden"
      refute html =~ "overflow-y-hidden"
    end
  end
end
