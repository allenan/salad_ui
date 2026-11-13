defmodule SaladUI.SpinnerTest do
  use ComponentCase

  import SaladUI.Spinner

  test "renders an accessible animated svg" do
    assigns = %{}
    html = rendered_to_string(~H|<.spinner />|)

    assert html =~ ~s(<svg data-slot="spinner" role="status")
    assert html =~ ~s(aria-label="Loading")
    assert html =~ "size-4 animate-spin"
    assert html =~ ~s(d="M21 12a9 9 0 1 1-6.219-8.56")
  end

  test "size and color are overridable via class" do
    assigns = %{}
    html = rendered_to_string(~H|<.spinner class="size-8 text-red-500" />|)
    assert html =~ "size-8"
    assert html =~ "text-red-500"
    refute html =~ "size-4"
  end

  test "aria-label is overridable" do
    assigns = %{}
    html = rendered_to_string(~H|<.spinner aria-label="Saving" />|)
    assert html =~ ~s(aria-label="Saving")
    refute html =~ "Loading"
  end

  test "spins a custom icon" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.spinner><svg id="custom"></svg></.spinner>
      """)

    assert html =~ ~s(<span data-slot="spinner" role="status")
    assert html =~ ~s(aria-label="Loading")
    assert html =~ "animate-spin"
    assert html =~ ~s(<svg id="custom">)
    refute html =~ "M21 12a9 9"
  end
end
