defmodule SaladUI.LabelTest do
  use ComponentCase

  import SaladUI.Label

  describe "Test Label" do
    test "It should render label correctly" do
      assigns = %{}

      html =
        ~H"""
        <.label class="text-green-500">Send!</.label>
        """
        |> rendered_to_string()
        |> clean_string()

      for class <-
            ~w(flex items-center gap-2 text-green-500 font-medium leading-none text-sm select-none group-data-[disabled=true]:pointer-events-none group-data-[disabled=true]:opacity-50 peer-disabled:cursor-not-allowed peer-disabled:opacity-50) do
        assert html =~ class
      end

      assert html =~ "Send!"
      assert html =~ ~s(data-slot="label")
      refute html =~ "peer-disabled:opacity-70"
    end
  end
end
