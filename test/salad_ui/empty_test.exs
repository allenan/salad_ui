defmodule SaladUI.EmptyTest do
  use ComponentCase

  import SaladUI.Empty

  test "renders all parts with shadcn classes and slots" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty>
        <.empty_header>
          <.empty_media variant="icon"><svg></svg></.empty_media>
          <.empty_title>No Projects Yet</.empty_title>
          <.empty_description>Get started. <a href="#">Learn more</a></.empty_description>
        </.empty_header>
        <.empty_content>
          <button>Create</button>
        </.empty_content>
      </.empty>
      """)

    assert html =~ ~s(data-slot="empty")
    assert html =~ "flex min-w-0 flex-1 flex-col items-center justify-center gap-6 rounded-lg border-dashed p-6"
    assert html =~ "md:p-12"
    assert html =~ ~s(data-slot="empty-header")
    assert html =~ "flex max-w-sm flex-col items-center gap-2 text-center"
    assert html =~ ~s(data-slot="empty-icon" data-variant="icon")
    assert html =~ "size-10 shrink-0 items-center justify-center rounded-lg bg-muted"
    assert html =~ ~s(data-slot="empty-title")
    assert html =~ "text-lg font-medium tracking-tight"
    assert html =~ ~s(data-slot="empty-description")
    assert html =~ "[&amp;&gt;a]:underline"
    assert html =~ ~s(data-slot="empty-content")
    assert html =~ "No Projects Yet"
  end

  test "default media variant is transparent" do
    assigns = %{}
    html = rendered_to_string(~H|<.empty_media>A</.empty_media>|)
    assert html =~ ~s(data-variant="default")
    assert html =~ "bg-transparent"
    refute html =~ "bg-muted"
  end

  test "custom classes are merged (outline / background)" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.empty class="border border-dashed bg-gradient-to-b from-muted/50 p-0">X</.empty>
      """)

    assert html =~ "border border-dashed"
    assert html =~ "bg-gradient-to-b"
    assert html =~ "p-0"
    refute html =~ " p-6"
  end
end
