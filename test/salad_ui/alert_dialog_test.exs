defmodule SaladUI.AlertDialogTest do
  use ComponentCase

  import SaladUI.AlertDialog

  describe "alert_dialog/1" do
    test "renders with required attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="test-dialog">
          <div>Content</div>
        </.alert_dialog>
        """)

      assert html =~ ~s(id="test-dialog")
      assert html =~ "Content"
      assert html =~ ~s(class="relative z-50 group/alert-dialog")
      assert html =~ ~s(data-component="dialog")
      assert html =~ "closeOnEscape&quot;:false"
      assert html =~ "closeOnOutsideClick&quot;:false"
      assert html =~ "role&quot;:&quot;alertdialog"
    end

    test "renders with open state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="test-dialog" open={true}>
          <div>Content</div>
        </.alert_dialog>
        """)

      assert html =~ ~s(id="test-dialog")
      assert html =~ "Content"
      assert html =~ ~s(data-state="open")
    end

    test "raises when missing required inner_block" do
      assigns = %{}

      assert_raise KeyError, ~r/key :inner_block not found/, fn ->
        rendered_to_string(~H"""
        <.alert_dialog id="test-dialog" />
        """)
      end
    end
  end

  describe "alert_dialog_trigger/1" do
    test "renders trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_trigger>
          <button>Open Dialog</button>
        </.alert_dialog_trigger>
        """)

      assert html =~ "Open Dialog"
      assert html =~ ~s(data-part="trigger")
      assert html =~ ~s(data-action="open")
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_trigger class="custom-class">
          <button>Open Dialog</button>
        </.alert_dialog_trigger>
        """)

      assert html =~ "custom-class"
    end

    test "renders without a deprecated builder assign" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_trigger>
          <button>Open Dialog</button>
        </.alert_dialog_trigger>
        """)

      assert html =~ "Open Dialog"
    end
  end

  describe "alert_dialog_content/1" do
    test "renders content with closed state by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_content>
          <div>Dialog Content</div>
        </.alert_dialog_content>
        """)

      assert html =~ ~s(data-part="content")
      assert html =~ "hidden"
      assert html =~ "Dialog Content"
    end

    test "renders content structure without generic close button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_content>
          <div>Dialog Content</div>
        </.alert_dialog_content>
        """)

      assert html =~ ~s(data-part="overlay")
      assert html =~ ~s(data-part="content-panel")
      assert html =~ ~s(aria-label="Alert dialog")
      assert html =~ "data-[state=open]:animate-in"
      assert html =~ "data-[state=closed]:fill-mode-forwards"
      refute html =~ "/dialog"
      refute html =~ ~s(data-part="close-trigger")
    end

    test "uses a consumer-provided accessible name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_content aria-label="Delete confirmation">
          <div>Dialog Content</div>
        </.alert_dialog_content>
        """)

      assert html =~ ~s(aria-label="Delete confirmation")
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_content class="custom-class">
          <div>Dialog Content</div>
        </.alert_dialog_content>
        """)

      assert html =~ "custom-class"
    end
  end

  describe "alert_dialog_header/1" do
    test "renders header with content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_header>
          <h2>Header Content</h2>
        </.alert_dialog_header>
        """)

      assert html =~ "Header Content"

      for class <- ~w(grid grid-rows-[auto_1fr] place-items-center gap-1.5 text-center) do
        assert html =~ class
      end
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_header class="custom-class">
          <h2>Header Content</h2>
        </.alert_dialog_header>
        """)

      assert html =~ "custom-class"
    end
  end

  describe "alert_dialog_title/1" do
    test "renders title with content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_title>
          Dialog Title
        </.alert_dialog_title>
        """)

      assert html =~ "Dialog Title"
      assert html =~ "text-lg"
      assert html =~ "font-semibold"
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_title class="custom-class">
          Dialog Title
        </.alert_dialog_title>
        """)

      assert html =~ "custom-class"
    end
  end

  describe "alert_dialog_description/1" do
    test "renders description with content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_description>
          Dialog description text
        </.alert_dialog_description>
        """)

      assert html =~ "Dialog description text"

      for class <- ~w(text-sm text-muted-foreground) do
        assert html =~ class
      end
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_description class="custom-class">
          Dialog description text
        </.alert_dialog_description>
        """)

      assert html =~ "custom-class"
    end
  end

  describe "alert_dialog_footer/1" do
    test "renders footer with content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_footer>
          <button>Footer Button</button>
        </.alert_dialog_footer>
        """)

      assert html =~ "Footer Button"

      for class <-
            ~w(flex flex-col-reverse gap-2 group-data-[size=sm]/alert-dialog-content:grid group-data-[size=sm]/alert-dialog-content:grid-cols-2 sm:flex-row) do
        assert html =~ class
      end
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_footer class="custom-class">
          <button>Footer Button</button>
        </.alert_dialog_footer>
        """)

      assert html =~ "custom-class"
    end
  end

  describe "alert_dialog_cancel/1" do
    test "renders cancel button with content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_cancel>
          Cancel
        </.alert_dialog_cancel>
        """)

      assert html =~ "Cancel"
      assert html =~ ~s(data-part="cancel")
      assert html =~ ~s(data-action="close")

      # shadcn v4: the footer's gap-2 spaces the buttons, not a margin
      refute html =~ "mt-2"

      for class <- ~w(bg-background shadow-xs) do
        assert html =~ class
      end
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_cancel class="custom-class">
          Cancel
        </.alert_dialog_cancel>
        """)

      assert html =~ "custom-class"
    end

    test "renders without a deprecated builder assign" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_cancel>
          Cancel
        </.alert_dialog_cancel>
        """)

      assert html =~ "Cancel"
    end
  end

  describe "alert_dialog_action/1" do
    test "renders action button with content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_action>
          Continue
        </.alert_dialog_action>
        """)

      assert html =~ "Continue"
      assert html =~ ~s(data-part="action")
      assert html =~ ~s(data-action="close")
    end

    test "renders with custom class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_action class="custom-class">
          Continue
        </.alert_dialog_action>
        """)

      assert html =~ "custom-class"
    end
  end

  # Integration test for the complete alert dialog
  describe "complete alert dialog" do
    test "renders full alert dialog structure" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="test-dialog">
          <.alert_dialog_trigger>
            <button>Open Dialog</button>
          </.alert_dialog_trigger>
          <.alert_dialog_content>
            <.alert_dialog_header>
              <.alert_dialog_title>Confirmation</.alert_dialog_title>
              <.alert_dialog_description>
                Are you sure you want to continue?
              </.alert_dialog_description>
            </.alert_dialog_header>
            <.alert_dialog_footer>
              <.alert_dialog_cancel>Cancel</.alert_dialog_cancel>
              <.alert_dialog_action>Continue</.alert_dialog_action>
            </.alert_dialog_footer>
          </.alert_dialog_content>
        </.alert_dialog>
        """)

      assert html =~ "test-dialog"
      assert html =~ "Open Dialog"
      assert html =~ "Confirmation"
      assert html =~ "Are you sure you want to continue?"
      assert html =~ "Cancel"
      assert html =~ "Continue"
    end

    test "alert_dialog_content defaults to the default size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_content>Body</.alert_dialog_content>
        """)

      assert html =~ ~s(data-size="default")
      assert html =~ "group/alert-dialog-content"
      assert html =~ "data-[size=default]:sm:max-w-lg"
      assert html =~ "data-[size=sm]:max-w-xs"
    end

    test "alert_dialog_content size=sm" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_content size="sm">Body</.alert_dialog_content>
        """)

      assert html =~ ~s(data-size="sm")
    end

    test "alert_dialog_media renders an icon tile" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_header>
          <.alert_dialog_media class="bg-destructive/10 text-destructive">
            <svg viewBox="0 0 24 24"></svg>
          </.alert_dialog_media>
          <.alert_dialog_title>Delete chat?</.alert_dialog_title>
        </.alert_dialog_header>
        """)

      assert html =~ ~s(data-slot="alert-dialog-media")
      assert html =~ "<svg"

      for class <-
            ~w(mb-2 inline-flex size-16 items-center justify-center rounded-md bg-destructive/10 text-destructive sm:group-data-[size=default]/alert-dialog-content:row-span-2) do
        assert html =~ class
      end

      refute html =~ "bg-muted"
      # header and title react to the media slot
      assert html =~ "has-data-[slot=alert-dialog-media]:grid-rows-[auto_auto_1fr]"
      assert html =~ "group-has-data-[slot=alert-dialog-media]/alert-dialog-content:col-start-2"
    end

    test "cancel and action accept every button size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog_cancel size="sm">Cancel</.alert_dialog_cancel>
        <.alert_dialog_action size="xs">OK</.alert_dialog_action>
        """)

      assert html =~ "h-8 gap-1.5"
      assert html =~ "h-6 gap-1"
    end
  end

  describe "modal" do
    test "is always modal" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="a">
          <div>Content</div>
        </.alert_dialog>
        """)

      assert html =~ "modal&quot;:true"
    end
  end
end
