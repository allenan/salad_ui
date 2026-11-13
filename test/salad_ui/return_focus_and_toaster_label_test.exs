defmodule SaladUI.ReturnFocusAndToasterLabelTest do
  use ComponentCase

  import SaladUI.AlertDialog
  import SaladUI.Dialog
  import SaladUI.Drawer
  import SaladUI.Sheet
  import SaladUI.Toast

  defp options(html) do
    [_, json] = Regex.run(~r/data-options="([^"]*)"/, html)
    json |> String.replace("&quot;", ~s(")) |> Jason.decode!()
  end

  describe "return-focus" do
    test "dialog, alert dialog, sheet and drawer pass it to the client" do
      assigns = %{}

      for html <- [
            rendered_to_string(~H|<.dialog id="d" return-focus="#invite-link">x</.dialog>|),
            rendered_to_string(~H|<.alert_dialog id="a" return-focus="#invite-link">x</.alert_dialog>|),
            rendered_to_string(~H|<.sheet id="s" return-focus="#invite-link">x</.sheet>|),
            rendered_to_string(~H|<.drawer id="r" return-focus="#invite-link">x</.drawer>|)
          ] do
        assert options(html)["returnFocus"] == "#invite-link"
      end
    end

    test "defaults to nil" do
      assigns = %{}
      html = rendered_to_string(~H|<.dialog id="d">x</.dialog>|)
      assert options(html)["returnFocus"] == nil
    end
  end

  describe "toaster label and attributes" do
    test "label replaces the landmark name; the hotkey is appended" do
      assigns = %{}
      html = rendered_to_string(~H|<.toaster label="Benachrichtigungen" />|)
      assert_tag(html, "section", [{"aria-label", "Benachrichtigungen Alt+T"}])
    end

    test "defaults to Sonner's name and passes global attributes through" do
      assigns = %{}
      html = rendered_to_string(~H|<.toaster hotkey={nil} data-testid="toasts" />|)
      assert_tag(html, "section", [{"aria-label", "Notifications"}, {"data-testid", "toasts"}])
      assert duplicate_attrs(html) == []
    end
  end
end
