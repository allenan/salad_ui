defmodule SaladUI.MarkerTest do
  use ComponentCase

  import SaladUI.Marker

  test "marker renders icon and content" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.marker role="status">
        <.marker_icon><svg></svg></.marker_icon>
        <.marker_content class="shimmer">Thinking...</.marker_content>
      </.marker>
      """)

    assert html =~ ~r/^<div[^>]*data-slot="marker" data-variant="default"/
    refute html =~ ~s(name=)
    assert html =~ "group/marker"
    assert html =~ ~s(role="status")
    assert html =~ ~s(data-slot="marker-icon" aria-hidden="true")
    assert html =~ ~s(data-slot="marker-content")
    assert html =~ "shimmer"
  end

  test "separator and border variants" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.marker variant="separator">
        <.marker_content>Today</.marker_content>
      </.marker>
      <.marker variant="border">
        <.marker_content>Row</.marker_content>
      </.marker>
      """)

    assert html =~ ~s(data-variant="separator")
    assert html =~ "before:h-px"
    assert html =~ "after:bg-border"
    assert html =~ ~s(data-variant="border")
    assert html =~ "border-b border-border pb-2"
    assert html =~ "group-data-[variant=separator]/marker:text-center"
  end

  test "marker renders as a link or a button" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.marker as="a" href="#pr">
        <.marker_content>View</.marker_content>
      </.marker>
      """)

    assert html =~ ~r/^<a[^>]*href="#pr"/

    html =
      rendered_to_string(~H"""
      <.marker as="button">
        <.marker_content>Revert</.marker_content>
      </.marker>
      """)

    assert html =~ ~r/^<button[^>]*type="button"/
  end
end
