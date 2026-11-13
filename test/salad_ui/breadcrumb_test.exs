defmodule SaladUI.BreadcrumbTest do
  use ComponentCase

  import SaladUI.Breadcrumb

  describe "Test breadcrumb" do
    test "It renders breadcrumb correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.breadcrumb>
          <.breadcrumb_list>
            <.breadcrumb_item>
              <.breadcrumb_link href="/">Home</.breadcrumb_link>
            </.breadcrumb_item>
            <.breadcrumb_separator />
            <.breadcrumb_item>
              <.breadcrumb_link href="">Components</.breadcrumb_link>
            </.breadcrumb_item>
            <.breadcrumb_separator />
            <.breadcrumb_item>
              <.breadcrumb_page>Breadcrumb</.breadcrumb_page>
            </.breadcrumb_item>
          </.breadcrumb_list>
        </.breadcrumb>
        """)

      # Confirm all CSS classes are available
      for class <-
            ~w(flex flex-wrap items-center gap-1.5 break-words text-sm text-muted-foreground sm:gap-2.5 inline-flex items-center gap-1.5 transition-colors hover:text-foreground font-normal text-foreground) do
        assert html =~ class
      end

      assert html =~ "Home"
      assert html =~ "<nav "
      assert html =~ "Breadcrumb"
      assert html =~ "<span "
    end

    test "separator renders a chevron by default and custom content when given" do
      assigns = %{}

      default = rendered_to_string(~H"<.breadcrumb_separator />")
      assert default =~ ~s(data-slot="breadcrumb-separator")
      assert default =~ "<svg"

      custom =
        rendered_to_string(~H"""
        <.breadcrumb_separator><span class="dot">•</span></.breadcrumb_separator>
        """)

      assert custom =~ ~s(<span class="dot">•</span>)
      refute custom =~ "<svg"
    end
  end
end
