defmodule SaladUI.KbdTest do
  use ComponentCase

  import SaladUI.Kbd

  test "renders a kbd element" do
    assigns = %{}
    html = rendered_to_string(~H|<.kbd>Ctrl</.kbd>|)

    assert html =~ ~s(<kbd data-slot="kbd")
    assert html =~ "Ctrl"

    for class <-
          ~w(pointer-events-none inline-flex h-5 w-fit min-w-5 rounded-sm bg-muted px-1 font-sans text-xs font-medium text-muted-foreground select-none) do
      assert html =~ class
    end

    assert html =~ "[[data-slot=tooltip-content]_&amp;]:bg-background/20"
    assert html =~ "dark:[[data-slot=tooltip-content]_&amp;]:bg-background/10"
  end

  test "renders a kbd group" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.kbd_group>
        <.kbd>⌘</.kbd>
        <.kbd>K</.kbd>
      </.kbd_group>
      """)

    assert html =~ ~s(<kbd data-slot="kbd-group" class="inline-flex items-center gap-1")
    assert count_substring(html, ~s(data-slot="kbd")) == 2
  end

  test "merges custom classes" do
    assigns = %{}
    html = rendered_to_string(~H|<.kbd class="px-2">A</.kbd>|)
    assert html =~ "px-2"
    refute html =~ "px-1"
  end
end
