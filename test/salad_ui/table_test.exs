defmodule SaladUI.TableTest do
  use ComponentCase

  import SaladUI.Checkbox
  import SaladUI.Table

  describe "table/1" do
    test "wraps the table in a horizontally scrolling container" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.table id="invoices" class="custom-class" aria-label="Invoices">
          <.table_caption>A list of your recent invoices.</.table_caption>
        </.table>
        """)

      assert html =~
               ~r/<div data-slot="table-container" class="relative w-full overflow-x-auto">\s*<table data-slot="table"/

      assert html =~ ~s(class="w-full caption-bottom text-sm custom-class")
      assert html =~ ~s(id="invoices")
      assert html =~ ~s(aria-label="Invoices")
      assert html =~ ~s(class="mt-4 text-sm text-muted-foreground")
    end
  end

  describe "table sections" do
    test "header, body, footer and row use the v4 classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.table_header>
          <.table_row>
            <.table_head>H</.table_head>
          </.table_row>
        </.table_header>
        <.table_body>
          <.table_row>
            <.table_cell>C</.table_cell>
          </.table_row>
        </.table_body>
        <.table_footer>
          <.table_row>
            <.table_cell colspan="3">Total</.table_cell>
          </.table_row>
        </.table_footer>
        """)

      assert html =~ ~s(<thead data-slot="table-header" class="[&amp;_tr]:border-b">)
      assert html =~ ~s(<tbody data-slot="table-body" class="[&amp;_tr:last-child]:border-0">)

      assert html =~
               ~s(<tfoot data-slot="table-footer" class="border-t bg-muted/50 font-medium [&amp;&gt;tr]:last:border-b-0">)

      assert html =~
               ~s(class="border-b transition-colors hover:bg-muted/50 has-aria-expanded:bg-muted/50 data-[state=selected]:bg-muted")

      assert html =~ ~s(colspan="3")
      refute html =~ "border-border"
    end

    test "table_head uses the v4 sizing and foreground color" do
      assigns = %{}

      html = rendered_to_string(~H(<.table_head class="w-[100px]">Invoice</.table_head>))

      for class <-
            ~w|h-10 px-2 text-left align-middle font-medium whitespace-nowrap text-foreground [&amp;:has([role=checkbox])]:pr-0 [&amp;&gt;[role=checkbox]]:translate-y-[2px] w-[100px]| do
        assert html =~ class
      end

      assert html =~ ~s(scope="col")
      refute html =~ "text-muted-foreground"
      refute html =~ "h-12"
    end

    test "table_cell uses the v4 padding" do
      assigns = %{}

      html = rendered_to_string(~H(<.table_cell class="font-medium">INV001</.table_cell>))

      for class <-
            ~w|p-2 align-middle whitespace-nowrap [&amp;:has([role=checkbox])]:pr-0 [&amp;&gt;[role=checkbox]]:translate-y-[2px] font-medium| do
        assert html =~ class
      end

      refute html =~ "p-4"
    end

    test "the checkbox tweaks also match SaladUI's native checkbox" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.table_cell><.checkbox id="row-1" /></.table_cell>
        """)

      # checkbox/1 renders <input type="checkbox"> (no role attribute), so the
      # [role=checkbox] selectors alone would never match it.
      assert html =~ ~s(type="checkbox")
      refute html =~ ~s(role="checkbox")
      assert html =~ "[&amp;:has([type=checkbox])]:pr-0"
      assert html =~ "[&amp;&gt;[type=checkbox]]:translate-y-[2px]"
    end
  end
end
