defmodule SaladUI.AspectRatioTest do
  use ComponentCase

  import SaladUI.AspectRatio

  test "renders a radix-style wrapper with padding-bottom" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.aspect_ratio ratio={16 / 9} class="rounded-lg bg-muted">
        <img src="/x.png" alt="x" />
      </.aspect_ratio>
      """)

    assert html =~ "position: relative; width: 100%; padding-bottom: 56.25%;"
    assert html =~ ~s(data-slot="aspect-ratio")
    assert html =~ "position: absolute; inset: 0;"
    assert html =~ ~s(class="rounded-lg bg-muted")
    assert html =~ ~s(<img src="/x.png")
  end

  test "accepts integers and strings" do
    assigns = %{}

    assert rendered_to_string(~H|<.aspect_ratio ratio={1} />|) =~ "padding-bottom: 100.0%"
    assert rendered_to_string(~H|<.aspect_ratio ratio="9/16" />|) =~ "padding-bottom: 177.7778%"
    assert rendered_to_string(~H|<.aspect_ratio ratio="4:3" />|) =~ "padding-bottom: 75.0%"
    assert rendered_to_string(~H|<.aspect_ratio ratio="2" />|) =~ "padding-bottom: 50.0%"
  end

  test "rejects invalid ratios" do
    assigns = %{}

    assert_raise ArgumentError, fn -> rendered_to_string(~H|<.aspect_ratio ratio="wide" />|) end
    assert_raise ArgumentError, fn -> rendered_to_string(~H|<.aspect_ratio ratio={0} />|) end
  end
end
