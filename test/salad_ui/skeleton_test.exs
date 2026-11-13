defmodule SaladUI.SkeletonTest do
  use ComponentCase

  import SaladUI.Skeleton

  test "renders shadcn's classes, merging a custom class" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.skeleton class="h-4 w-full rounded-full" aria-busy="true" />
      """)

    assert html =~ ~s(data-slot="skeleton")
    assert html =~ ~s(class="animate-pulse bg-accent h-4 w-full rounded-full")
    assert html =~ ~s(aria-busy="true")
    refute html =~ "bg-muted"
  end
end
