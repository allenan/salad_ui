defmodule SaladUI.BubbleTest do
  use ComponentCase

  import SaladUI.Bubble

  test "bubble defaults to the primary variant at the start" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.bubble>
        <.bubble_content>Hello</.bubble_content>
      </.bubble>
      """)

    assert html =~ ~s(data-slot="bubble" data-variant="default" data-align="start")
    assert html =~ "group/bubble"
    assert html =~ "max-w-[80%]"
    assert html =~ "*:data-[slot=bubble-content]:bg-primary"
    assert html =~ ~r/<div[^>]*data-slot="bubble-content"/
    refute html =~ ~s(name=)
    assert html =~ "rounded-xl"
    assert html =~ "[button,a]:focus-visible:ring-3"
  end

  for {variant, class} <- [
        {"secondary", "*:data-[slot=bubble-content]:bg-secondary"},
        {"muted", "*:data-[slot=bubble-content]:bg-muted"},
        {"tinted", "*:data-[slot=bubble-content]:bg-[oklch(from_var(--primary)_0.93_calc(c*0.4)_h)]"},
        {"outline", "*:data-[slot=bubble-content]:border-border"},
        {"ghost", "*:data-[slot=bubble-content]:bg-transparent"},
        {"destructive", "*:data-[slot=bubble-content]:text-destructive"}
      ] do
    test "bubble #{variant} variant" do
      assigns = %{variant: unquote(variant)}

      html =
        rendered_to_string(~H"""
        <.bubble variant={@variant} align="end">
          <.bubble_content>Hi</.bubble_content>
        </.bubble>
        """)

      assert html =~ ~s(data-variant="#{unquote(variant)}" data-align="end")
      assert html =~ unquote(class)
    end
  end

  test "bubble_content renders as a button or a link" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.bubble_content as="button" phx-click="choose">Pick</.bubble_content>
      """)

    assert html =~ ~r/^<button[^>]*data-slot="bubble-content"/
    assert html =~ ~s(type="button")
    assert html =~ ~s(phx-click="choose")

    html =
      rendered_to_string(~H"""
      <.bubble_content as="button" type="submit">Send</.bubble_content>
      """)

    assert html =~ ~s(type="submit")
    refute html =~ ~s(type="button")

    html =
      rendered_to_string(~H"""
      <.bubble_content as="a" href="/help">Help</.bubble_content>
      """)

    assert html =~ ~r/^<a[^>]*href="\/help"/
    refute html =~ "type="
  end

  test "bubble_reactions positions by side and align" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.bubble_group>
        <.bubble>
          <.bubble_content>Hi</.bubble_content>
          <.bubble_reactions role="img" aria-label="Reactions: thumbs up">
            <span>👍</span>
          </.bubble_reactions>
          <.bubble_reactions side="top" align="start"><span>🎉</span></.bubble_reactions>
        </.bubble>
      </.bubble_group>
      """)

    assert html =~ ~s(data-slot="bubble-group")
    assert html =~ ~s(data-slot="bubble-reactions" data-align="end" data-side="bottom")
    assert html =~ "bottom-0 translate-y-3/4"
    assert html =~ "end-3"
    assert html =~ ~s(data-align="start" data-side="top")
    assert html =~ "top-0 -translate-y-3/4"
    assert html =~ "start-3"
    assert html =~ "ring-3 ring-card"
    assert html =~ ~s(aria-label="Reactions: thumbs up")
  end
end
