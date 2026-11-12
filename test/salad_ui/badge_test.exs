defmodule SaladUI.BadgeTest do
  use ComponentCase

  import SaladUI.Badge

  describe "Test Badge" do
    test "It renders a badge default variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge>Badge</.badge>
        """)

      for class <-
            ~w(inline-flex w-fit shrink-0 rounded-full border px-2 py-0.5 text-xs font-medium focus-visible:ring-[3px] aria-invalid:border-destructive bg-primary text-primary-foreground [a&amp;]:hover:bg-primary/90) do
        assert html =~ class
      end

      assert html =~ ~s(<span data-slot="badge" data-variant="default")
      refute html =~ "focus:ring"
      assert html =~ "Badge"
    end

    test "It renders a badge with secondary variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge variant="secondary">Secondary</.badge>
        """)

      for class <- ~w(border-transparent bg-secondary text-secondary-foreground [a&amp;]:hover:bg-secondary/90) do
        assert html =~ class
      end
    end

    test "It renders a badge with the destructive variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge variant="destructive">Destructive</.badge>
        """)

      for class <-
            ~w(border-transparent bg-destructive text-white [a&amp;]:hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:bg-destructive/60 dark:focus-visible:ring-destructive/40) do
        assert html =~ class
      end

      assert html =~ "Destructive"
    end

    test "it renders a badge with the outlined variant" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge variant="outline">Outline</.badge>
        """)

      for class <- ~w(border-border text-foreground) do
        assert html =~ class
      end

      refute html =~ "border-transparent"
      assert html =~ "Outline"
    end

    test "it renders the ghost and link variants" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.badge variant="ghost">Ghost</.badge>
        <.badge variant="link">Link</.badge>
        """)

      assert html =~ ~s(data-variant="ghost")
      assert html =~ "[a&amp;]:hover:bg-accent"
      assert html =~ ~s(data-variant="link")
      assert html =~ "text-primary underline-offset-4"
    end
  end
end
