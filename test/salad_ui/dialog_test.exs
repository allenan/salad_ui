defmodule SaladUI.DialogTest do
  use ComponentCase

  import SaladUI.Button
  import SaladUI.Dialog
  import SaladUI.Input
  import SaladUI.Label

  describe "Test Dialog" do
    test "content is centered without a transform" do
      # A transform would make the panel the containing block of fixed-position
      # popovers inside it (combobox, date picker), offsetting them.
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog id="d">
          <.dialog_content>Body</.dialog_content>
        </.dialog>
        """)

      assert html =~ ~r/data-slot="dialog-content"[^>]*class="[^"]*fixed inset-0 z-50 m-auto grid h-fit/
      refute html =~ "translate-x-[-50%]"
    end

    test "It renders dialog header correctly" do
      assigns = %{}

      html =
        ~H"""
        <.dialog_header>This is the content of the header</.dialog_header>
        """
        |> rendered_to_string()
        |> clean_string()

      for class <- ~w(flex text-center flex-col gap-2 sm:text-start) do
        assert html =~ class
      end

      assert html =~ "This is the content of the header"

      for css_class <- ~w(flex flex-col gap-2 text-center sm:text-start) do
        assert html =~ css_class
      end
    end

    test "It renders dialog title correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_title>Edit profile</.dialog_title>
        """)

      assert html =~ "Edit profile\n</h3>"
      assert html =~ ~s(data-part="title")

      for css_class <- ~w(text-lg font-semibold leading-none) do
        assert html =~ css_class
      end
    end

    test "It renders dialog description correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_description>
          Make changes to your profile here click save when you're done
        </.dialog_description>
        """)

      assert html =~ "Make changes to your profile here click save when you're done\n\n</p>"
      assert html =~ ~s(data-part="description")

      for css_class <- ~w(text-sm text-muted-foreground) do
        assert html =~ css_class
      end
    end

    test "It renders dialog footer correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_footer>The footer is here</.dialog_footer>
        """)

      assert html =~ "The footer is here"

      for css_class <- ~w(flex flex-col-reverse gap-2 sm:flex-row sm:justify-end) do
        assert html =~ css_class
      end
    end

    test "It renders dialog correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button phx-click={SaladUI.JS.dispatch_command(%Phoenix.LiveView.JS{}, "open", to: "#my-modal")}>
          Open modal
        </.button>

        <.dialog id="my-modal" on_cancel={Phoenix.LiveView.JS.navigate("")} class="w-[700px]">
          <.dialog_header>
            <.dialog_title>Edit profile</.dialog_title>

            <.dialog_description>
              Make changes to your profile here click save when you're done
            </.dialog_description>
          </.dialog_header>

          <div class="grid gap-4 py-4">
            <div class="grid grid-cols-4 items-center gap-4">
              <.label html-for="name" class="text-right">
                Name
              </.label>
              <.input id="name" value="Dzung Nguyen" class="col-span-3" />
            </div>

            <div class="grid grid-cols-4 items-center gap-4">
              <.label html-for="username" class="text-right">
                Username
              </.label>
              <.input id="username" value="@bluzky" class="col-span-3" />
            </div>
          </div>

          <.dialog_footer>
            <.button type="submit">save changes</.button>
          </.dialog_footer>
        </.dialog>
        """)

      assert html =~ "Edit profile"
      assert html =~ "save changes\n<\/button>"
      assert html =~ "Make changes to your profile here click save when you're done"
    end

    test "dialog_content renders the corner close button by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_content>
          <p>Body</p>
        </.dialog_content>
        """)

      assert html =~ ~s(data-part="close-trigger")
      assert html =~ ~s(<span class="sr-only">Close</span>)
      assert html =~ "max-w-[calc(100%-2rem)]"
      assert html =~ "bg-black/50"
    end

    test "dialog_content show_close_button={false} hides the corner close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_content show_close_button={false}>
          <p>Body</p>
        </.dialog_content>
        """)

      refute html =~ "close-trigger"
      refute html =~ "dialog-close"
      assert html =~ "Body"
    end

    test "dialog_close wraps its content in a close action" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_close class="extra">
          <.button type="button">Close</.button>
        </.dialog_close>
        <.dialog_close as="button" type="button">Dismiss</.dialog_close>
        """)

      assert html =~ ~r/<div[^>]*data-action="close"/
      assert html =~ ~r/<button[^>]*data-action="close"[^>]*>\s*Dismiss/
      assert html =~ ~s(data-slot="dialog-close")
      assert html =~ ~s(data-part="close")
      assert html =~ ~s(class="extra")
      assert html =~ ~s(type="button")
      # the built-in "Close dialog" label targets close-trigger only, so the
      # wrapped element keeps its own accessible name
      refute html =~ "close-trigger"
    end

    test "dialog_footer show_close_button appends an outline Close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_footer show_close_button>
          <.button>Save</.button>
        </.dialog_footer>
        """)

      assert html =~ ~r/<button[^>]*data-action="close"[^>]*>\s*Close\s*<\/button>/
      assert html =~ "bg-background shadow-xs"
    end

    test "dialog_footer can hold only the built-in Close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dialog_footer show_close_button />
        """)

      assert html =~ ~r/<button[^>]*data-action="close"[^>]*>\s*Close\s*<\/button>/
    end
  end
end
