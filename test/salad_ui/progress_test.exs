defmodule SaladUi.ProgressTest do
  use ComponentCase

  import SaladUI.Progress

  describe "Test Progress" do
    test "IT renders progress component correctly" do
      assigns = %{}

      html =
        ~H"""
        <.progress class="w-[60%]" value={20} />
        """
        |> rendered_to_string()
        |> clean_string()

      for class <- ~w(h-full w-full flex-1 bg-primary transition-all) do
        assert html =~ class
      end

      for class <- ~w(relative h-2 rounded-full bg-primary/20 overflow-hidden w-[60%]) do
        assert html =~ class
      end

      refute html =~ "bg-secondary"
      refute html =~ "h-4"

      assert html =~ "style=\"transform: translateX(-80%)\"></div></div>"
    end
  end
end
