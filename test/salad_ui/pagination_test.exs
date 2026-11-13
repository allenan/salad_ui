defmodule SaladUi.PaginationTest do
  use ComponentCase

  import SaladUI.Pagination

  describe "Test Pagination:" do
    test "pagination is a navigation landmark" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pagination>x</.pagination>
        """)

      assert html =~ ~s(role="navigation")
      assert html =~ ~s(aria-label="pagination")
    end

    test "It renders pagination_content correctly" do
      assigns = %{}

      html =
        ~H"""
        <.pagination_content>Content goes here</.pagination_content>
        """
        |> rendered_to_string()
        |> clean_string()

      for class <-
            ~w("flex items-center flex-row gap-1") do
        assert html =~ class
      end

      assert html =~ "</ul>"
      assert html =~ "Content goes here"
    end

    test "It renders pagination_item correctly" do
      assigns = %{}

      html =
        ~H"""
        <.pagination_item>
          Item writings
        </.pagination_item>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(<li data-slot="pagination-item" class="")
      assert html =~ "</li>"
      assert html =~ "Item writings"
    end

    test "It renders pagination_link" do
      assigns = %{}

      html =
        ~H"""
        <.pagination_link href="">3</.pagination_link>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~r/<a[^>]*>3<\/a>/
      refute html =~ "aria-current"
      refute html =~ "data-active"

      for css_class <-
            ~w(inline-flex rounded-md transition-all whitespace-nowrap items-center justify-center font-medium text-sm size-9 outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground) do
        assert html =~ css_class
      end
    end

    test "only the active pagination_link is the current page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.pagination_link href="#" is-active>1</.pagination_link>
        <.pagination_link href="#" is-active={false}>2</.pagination_link>
        """)

      assert html =~ ~r/<a[^>]*aria-current="page"[^>]*>\s*1\s*<\/a>/
      assert html =~ ~r/<a[^>]*data-active="true"[^>]*>\s*1\s*<\/a>/
      assert count_substring(html, "aria-current") == 1
      assert count_substring(html, "data-active") == 1
    end

    test "it renders pagination_next correctly" do
      assigns = %{}

      html =
        ~H"""
        <.pagination_next href="#" />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(aria-label="Go to next page")
      # Like shadcn, mobile shows only the chevron.
      assert html =~ ~r/<a [^>]*href="#"/
      assert html =~ ~s(<span class="hidden sm:block">Next</span><svg)
      # lucide ChevronRightIcon, decorative
      assert html =~ ~r/<svg[^>]*aria-hidden="true"[^>]*class="rtl:rotate-180"><path d="m9 18 6-6-6-6"><\/path><\/svg>/
    end

    test "pagination_next and pagination_previous take a translated text" do
      assigns = %{}

      html =
        ~H"""
        <.pagination_previous href="#" text="Précédent" />
        <.pagination_next href="#" text="Suivant" />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(<span class="hidden sm:block">Précédent</span>)
      assert html =~ ~s(<span class="hidden sm:block">Suivant</span>)
    end

    test "IT renders pagination_previous correclty" do
      assigns = %{}

      html =
        ~H"""
        <.pagination_previous href="#" />
        """
        |> rendered_to_string()
        |> clean_string()

      # lucide ChevronLeftIcon, decorative
      assert html =~
               ~r/<svg[^>]*aria-hidden="true"[^>]*><path d="m15 18-6-6 6-6"><\/path><\/svg><span class="hidden sm:block">Previous<\/span><\/a>/
    end

    test "It renders pagination_ellipsis correctly" do
      assigns = %{}

      html =
        ~H"""
        <.pagination_ellipsis />
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-slot="pagination-ellipsis")
      # lucide MoreHorizontalIcon, hidden; the sr-only label names it
      assert html =~
               ~r/<svg[^>]*aria-hidden="true"[^>]*class="size-4"><circle cx="12" cy="12" r="1"><\/circle><circle cx="19" cy="12" r="1"><\/circle><circle cx="5" cy="12" r="1"><\/circle><\/svg>/
      assert html =~ ~s(<span class="sr-only">More pages</span>)
      refute html =~ ~r/<span[^>]*data-slot="pagination-ellipsis"[^>]*aria-hidden/
    end
  end
end
