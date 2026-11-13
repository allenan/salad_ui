defmodule SaladUI.TraceTest do
  use ComponentCase

  import SaladUI.Trace

  test "trace renders lines with icon, title and description" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.trace class="max-w-sm">
        <.trace_line>
          <.trace_icon><svg></svg></.trace_icon>
          <.trace_title>Ran pnpm test</.trace_title>
          <.trace_description>14s</.trace_description>
        </.trace_line>
      </.trace>
      """)

    assert html =~ ~s(data-slot="trace")

    assert html =~ "*:has-[&gt;[data-slot=trace-line]]:focus-visible:ring-3" or
             html =~ "*:has-[>[data-slot=trace-line]]:focus-visible:ring-3"

    assert html =~ "max-w-sm"
    assert html =~ ~r/<span data-slot="trace-line"/
    refute html =~ "data-status"
    assert html =~ ~s(data-slot="trace-icon" aria-hidden="true")
    assert html =~ ~s(data-slot="trace-title")
    assert html =~ "motion-reduce:shimmer-none"
    assert html =~ ~s(data-slot="trace-description")
    assert html =~ "tabular-nums"
  end

  test "trace_line status" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.trace_line status="running">
        <.trace_title>Running</.trace_title>
      </.trace_line>
      """)

    assert html =~ ~s(data-status="running")
    assert html =~ "data-[status=running]:*:data-[slot=trace-title]:shimmer"
    assert html =~ "data-[status=error]:text-destructive"
    assert html =~ "data-[status=pending]:opacity-60"
  end

  test "trace_collapsible builds on the collapsible JS component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.trace_collapsible id="row" open on-open="opened">
        <.trace_collapsible_trigger>
          <.trace_line>
            <.trace_title>Ran node --version</.trace_title>
          </.trace_line>
        </.trace_collapsible_trigger>
        <.trace_collapsible_content class="whitespace-pre-wrap">v24.18.0</.trace_collapsible_content>
      </.trace_collapsible>
      """)

    assert html =~ ~s(id="row")
    assert html =~ ~s(data-slot="trace-collapsible")
    assert html =~ ~s(data-component="collapsible")
    assert html =~ ~s(data-state="open")
    assert html =~ ~s(phx-hook="SaladUI")
    assert html =~ ~s(data-part="root")
    assert html =~ "&quot;open&quot;:true"
    assert html =~ "&quot;open&quot;:&quot;opened&quot;"

    assert html =~
             ~s(<button type="button" data-slot="trace-collapsible-trigger" data-part="trigger" data-action="toggle")

    assert html =~ "group/trace-collapsible-trigger"
    assert html =~ "group-aria-expanded/trace-collapsible-trigger:rotate-90"
    assert html =~ ~s(<path d="m9 18 6-6-6-6")

    assert html =~ ~s(data-slot="trace-collapsible-content" data-part="content" hidden)
    assert html =~ ~s(data-slot="trace-collapsible-content-inner")
    assert html =~ "border-l"
    assert html =~ "whitespace-pre-wrap"
  end

  test "trace_collapsible starts closed" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.trace_collapsible id="row">
        <.trace_collapsible_trigger>
          <.trace_line>
            <.trace_title>T</.trace_title>
          </.trace_line>
        </.trace_collapsible_trigger>
        <.trace_collapsible_content>C</.trace_collapsible_content>
      </.trace_collapsible>
      """)

    assert html =~ ~s(data-state="closed")
    assert html =~ "&quot;open&quot;:false"
  end
end
