defmodule SaladUI.SheetTest do
  use ComponentCase

  import SaladUI.Sheet

  describe "sheet/1" do
    test "renders with required attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="test-sheet">
          <div>Content</div>
        </.sheet>
        """)

      assert html =~ ~s(id="test-sheet")
      assert html =~ "Content"
      assert html =~ ~s(data-component="dialog")
      assert html =~ ~s(data-state="closed")
    end

    test "renders with open state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="test-sheet" open={true}>
          <div>Content</div>
        </.sheet>
        """)

      assert html =~ ~s(data-state="open")
    end

    test "configures dialog-compatible close animation and options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="test-sheet" close-on-outside-click={false}>
          <div>Content</div>
        </.sheet>
        """)

      assert html =~ ~s(data-component="dialog")
      assert html =~ "open_to_closed"
      assert html =~ "duration&quot;:300"
      assert html =~ "closeOnOutsideClick&quot;:false"
    end
  end

  describe "sheet_trigger/1" do
    test "renders trigger without unused target attribute" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_trigger>
          <button>Open Sheet</button>
        </.sheet_trigger>
        """)

      assert html =~ "Open Sheet"
      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(data-action="open")
      refute html =~ "data-target"
    end
  end

  describe "sheet_content/1" do
    test "renders content structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_content>
          <div>Sheet Content</div>
        </.sheet_content>
        """)

      assert html =~ ~s(data-part="content")
      assert html =~ ~s(data-part="overlay")
      assert html =~ ~s(data-part="content-panel")
      assert html =~ ~s(data-side="right")
      assert html =~ "data-[state=closed]:fill-mode-forwards"
      assert html =~ "Sheet Content"

      # v4 overlay and panel: no p-6, a flex column with gap-4
      assert html =~ "fixed inset-0 z-50 bg-black/50"
      refute html =~ "bg-black/80"

      for class <-
            ~w(fixed z-50 flex flex-col gap-4 bg-background shadow-lg transition ease-in-out data-[state=closed]:duration-300 data-[state=open]:duration-500 inset-y-0 right-0 h-full w-3/4 border-l sm:max-w-sm) do
        assert html =~ class
      end

      refute html =~ " p-6"

      # the close button is shown by default
      assert html =~ ~s(data-slot="sheet-close")
      assert html =~ "focus:ring-2 focus:ring-ring focus:ring-offset-2"
      assert html =~ ~s(class="size-4")
      assert html =~ ~s(<span class="sr-only">Close</span>)
    end

    test "show_close_button={false} omits the close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_content show_close_button={false}>
          <div>No close</div>
        </.sheet_content>
        """)

      assert html =~ "No close"
      refute html =~ ~s(data-slot="sheet-close")
      refute html =~ "sr-only"
    end

    test "top and bottom sheets are full width with auto height" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_content side="bottom" class="data-[side=bottom]:max-h-[50vh]">
          <div>Bottom</div>
        </.sheet_content>
        """)

      assert html =~ ~s(data-side="bottom")

      for class <-
            ~w(inset-x-0 bottom-0 h-auto border-t data-[state=closed]:slide-out-to-bottom data-[state=open]:slide-in-from-bottom data-[side=bottom]:max-h-[50vh]) do
        assert html =~ class
      end
    end

    test "renders side variants" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_content side="left">
          <div>Left Sheet</div>
        </.sheet_content>
        """)

      assert html =~ ~s(data-side="left")
      assert html =~ "slide-in-from-left"
      assert html =~ "slide-out-to-left"
    end
  end

  describe "sheet_header/1 and sheet_footer/1" do
    test "carry the v4 padding and layout" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_header>H</.sheet_header>
        <.sheet_footer>F</.sheet_footer>
        """)

      assert html =~ ~s(<div data-slot="sheet-header" class="flex flex-col gap-1.5 p-4">)
      assert html =~ ~s(<div data-slot="sheet-footer" class="mt-auto flex flex-col gap-2 p-4">)
    end
  end

  describe "sheet_title/1 and sheet_description/1" do
    test "render ARIA data parts" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_title>Title</.sheet_title>
        <.sheet_description>Description</.sheet_description>
        """)

      assert html =~ ~s(data-part="title")
      assert html =~ ~s(class="font-semibold text-foreground")
      assert html =~ ~s(data-part="description")
      assert html =~ ~s(class="text-sm text-muted-foreground")
      assert html =~ "Title"
      assert html =~ "Description"
    end
  end

  describe "sheet_close/1" do
    test "renders close trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet_close>
          Close
        </.sheet_close>
        """)

      assert html =~ "Close"
      assert html =~ ~s(data-part="close-trigger")
      assert html =~ ~s(data-action="close")
    end
  end

  describe "complete sheet" do
    test "renders full sheet structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.sheet id="test-sheet">
          <.sheet_trigger>
            <button>Open Sheet</button>
          </.sheet_trigger>
          <.sheet_content side="right">
            <.sheet_header>
              <.sheet_title>Edit profile</.sheet_title>
              <.sheet_description>Make changes here.</.sheet_description>
            </.sheet_header>
            <.sheet_footer>
              <.sheet_close>Close</.sheet_close>
            </.sheet_footer>
          </.sheet_content>
        </.sheet>
        """)

      assert html =~ "test-sheet"
      assert html =~ "Open Sheet"
      assert html =~ "Edit profile"
      assert html =~ "Make changes here."
      assert html =~ "Close"
    end
  end

  describe "modal" do
    test "is modal by default and accepts modal={false}" do
      assigns = %{}

      default =
        rendered_to_string(~H"""
        <.sheet id="s">
          <div>Content</div>
        </.sheet>
        """)

      non_modal =
        rendered_to_string(~H"""
        <.sheet id="s" modal={false}>
          <div>Content</div>
        </.sheet>
        """)

      assert default =~ "modal&quot;:true"
      assert non_modal =~ "modal&quot;:false"
      refute non_modal =~ ~s( modal=)
    end
  end
end
