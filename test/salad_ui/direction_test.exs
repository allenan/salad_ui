defmodule SaladUI.DirectionTest do
  use ComponentCase

  import SaladUI.Direction

  describe "direction_provider/1" do
    test "renders a display: contents wrapper carrying dir" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.direction_provider direction="rtl">
          <p>مرحبا</p>
        </.direction_provider>
        """)

      assert html =~ ~s(data-slot="direction-provider")
      assert html =~ ~s(dir="rtl")
      assert html =~ ~s(class="contents")
      assert html =~ "<p>مرحبا</p>"
    end

    test "accepts Radix's dir prop, with direction taking precedence" do
      assigns = %{}

      assert rendered_to_string(~H|<.direction_provider dir="rtl">x</.direction_provider>|) =~ ~s(dir="rtl")

      assert rendered_to_string(~H|<.direction_provider dir="rtl" direction="ltr">x</.direction_provider>|) =~
               ~s(dir="ltr")
    end

    test "defaults to ltr and merges classes and extra attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.direction_provider class="block" lang="ar">x</.direction_provider>
        """)

      assert html =~ ~s(dir="ltr")
      assert html =~ ~s(class="block")
      assert html =~ ~s(lang="ar")
    end
  end

  describe "rtl-aware markup in other components" do
    test "sidebar forwards dir and keys its position off data-side" do
      import SaladUI.Sidebar

      assigns = %{}

      desktop =
        rendered_to_string(~H"""
        <.sidebar id="rtl-sidebar" side="right" dir="rtl">Content</.sidebar>
        """)

      assert desktop =~ ~s(dir="rtl")
      assert desktop =~ ~r/data-slot="sidebar-container"\s+data-side="right"/
      assert desktop =~ "data-[side=right]:right-0"
      assert desktop =~ "data-[side=left]:left-0"

      mobile =
        rendered_to_string(~H"""
        <.sidebar id="rtl-sidebar-mobile" is_mobile={true} side="right" dir="rtl">Content</.sidebar>
        """)

      assert mobile =~ ~s(dir="rtl")

      trigger = rendered_to_string(~H|<.sidebar_trigger target="rtl-sidebar" />|)
      assert trigger =~ "rtl:rotate-180"
    end

    test "sub-menu chevrons flip and sit at the inline end" do
      import SaladUI.DropdownMenu

      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown_menu_sub>
          <.dropdown_menu_sub_trigger>More</.dropdown_menu_sub_trigger>
          <.dropdown_menu_sub_content>
            <.dropdown_menu_item>Item</.dropdown_menu_item>
          </.dropdown_menu_sub_content>
        </.dropdown_menu_sub>
        """)

      assert html =~ "ms-auto size-4 rtl:rotate-180"
    end

    test "pagination and breadcrumb chevrons flip under rtl" do
      import SaladUI.Breadcrumb
      import SaladUI.Pagination

      assigns = %{}

      assert rendered_to_string(~H|<.pagination_previous href="#" />|) =~ "rtl:rotate-180"
      assert rendered_to_string(~H|<.pagination_next href="#" />|) =~ "rtl:rotate-180"
      assert rendered_to_string(~H|<.breadcrumb_separator />|) =~ "rtl:rotate-180"
    end

    test "pagination previous/next take a translated label" do
      import SaladUI.Pagination

      assigns = %{}

      assert rendered_to_string(~H|<.pagination_previous href="#" />|) =~
               ~s(<span class="hidden sm:block">Previous</span>)

      assert rendered_to_string(~H|<.pagination_next href="#" text="التالي" />|) =~
               ~s(<span class="hidden sm:block">التالي</span>)

      assert rendered_to_string(~H|<.pagination_previous href="#" text="السابق" />|) =~
               ~s(<span class="hidden sm:block">السابق</span>)
    end
  end
end
