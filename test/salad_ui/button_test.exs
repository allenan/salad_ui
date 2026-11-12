defmodule SaladUI.ButtonTest do
  use ComponentCase

  import SaladUI.Button

  describe "Test Button" do
    test "It renders default button correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button>Send!</.button>
        """)

      assert html =~ "Send!"
      assert html =~ ~s(<button data-slot="button" data-variant="default" data-size="default")
      assert html =~ ~s(class="phx-submit-loading:opacity-75 inline-flex)

      for class <-
            ~w(inline-flex shrink-0 items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 [&amp;_svg]:shrink-0 h-9 px-4 py-2 has-[&gt;svg]:px-3 bg-primary text-primary-foreground hover:bg-primary/90) do
        assert html =~ class
      end

      # shadcn v4 (pinned) gives only the outline variant a shadow
      refute html =~ "shadow-xs"
    end

    test "It renders every shadcn v4 size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button size="xs">xs</.button>
        <.button size="sm">sm</.button>
        <.button size="lg">lg</.button>
        <.button size="icon-xs">i</.button>
        <.button size="icon-sm">i</.button>
        <.button size="icon">i</.button>
        <.button size="icon-lg">i</.button>
        """)

      for size <- ~w(xs sm lg icon-xs icon-sm icon icon-lg) do
        assert html =~ ~s(data-size="#{size}")
      end

      assert html =~ "h-6 gap-1 rounded-md px-2 text-xs has-[&gt;svg]:px-1.5"
      assert html =~ "h-8 gap-1.5 rounded-md px-3 has-[&gt;svg]:px-2.5"
      assert html =~ "h-10 rounded-md px-6 has-[&gt;svg]:px-4"
      assert html =~ "size-6"
      assert html =~ "size-8"
      assert html =~ "size-9"
      assert html =~ "size-10"
    end

    test "It renders button with additional css class correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button phx-click="go" class="ml-2-additional-class">Send!</.button>
        """)

      assert html =~ "Send!"
      assert html =~ "phx-click=\"go\""
      assert html =~ "ml-2-additional-class"
    end

    test "It renders destructive button correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button phx-click="go" variant="destructive">Destructive act!</.button>
        """)

      assert html =~ "phx-click=\"go\""
      assert html =~ "Destructive act"

      for class <-
            ~w(bg-destructive text-white hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:bg-destructive/60 dark:focus-visible:ring-destructive/40) do
        assert html =~ class
      end

      refute html =~ "shadow-xs"
    end

    test "It renders outline button correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button phx-click="go" variant="outline">Outline act!</.button>
        """)

      assert html =~ "phx-click=\"go\""
      assert html =~ "Outline act"

      for class <-
            ~w(border border-border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50) do
        assert html =~ class
      end
    end

    test "It renders secondary button correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button phx-click="go" variant="secondary">secondary act!</.button>
        """)

      assert html =~ "phx-click=\"go\""
      assert html =~ "secondary act"

      for class <- ~w(bg-secondary text-secondary-foreground hover:bg-secondary/80) do
        assert html =~ class
      end

      refute html =~ "shadow-xs"
    end

    test "It renders ghost button correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button phx-click="go" variant="ghost">ghost act!</.button>
        """)

      assert html =~ "phx-click=\"go\""
      assert html =~ "ghost act"

      for class <- ~w(hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50) do
        assert html =~ class
      end
    end

    test "It renders link button correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button phx-click="go" variant="link">link act!</.button>
        """)

      assert html =~ "phx-click=\"go\""
      assert html =~ "link act"

      for class <- ~w(text-primary underline-offset-4 hover:underline) do
        assert html =~ class
      end
    end

    test "It renders as a link when href, navigate or patch is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button href="/login" class="extra">Login</.button>
        <.button navigate="/docs" variant="outline" size="sm">Docs</.button>
        <.button patch="/tab" target="_blank">Tab</.button>
        """)

      assert html =~ ~r/<a href="\/login" class="[^"]*bg-primary[^"]*extra"/
      assert html =~ ~s(data-slot="button")
      assert html =~ ~s(data-phx-link="redirect")
      assert html =~ ~s(href="/docs")
      assert html =~ ~s(data-size="sm")
      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(data-phx-link="patch")
      assert html =~ ~s(target="_blank")
      refute html =~ "<button"
      refute html =~ "phx-submit-loading"
    end
  end
end
