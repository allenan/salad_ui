defmodule SaladUI.ButtonGroupTest do
  use ComponentCase

  import SaladUI.Button
  import SaladUI.ButtonGroup
  import SaladUI.Input

  describe "button_group/1" do
    test "renders a horizontal group by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button_group aria-label="Actions" class="hidden sm:flex">
          <.button variant="outline">Archive</.button>
          <.button variant="outline">Report</.button>
        </.button_group>
        """)

      assert html =~ ~s(role="group")
      assert html =~ ~s(data-slot="button-group")
      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ ~s(aria-label="Actions")
      assert html =~ "[&amp;&gt;*:not(:first-child)]:rounded-l-none"
      assert html =~ "[&amp;&gt;*:not(:last-child)]:rounded-r-none"
      assert html =~ "hidden sm:flex"
      refute html =~ "flex-col"
    end

    test "vertical orientation stacks and joins top/bottom" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button_group orientation="vertical">
          <.button variant="outline" size="icon">+</.button>
          <.button variant="outline" size="icon">-</.button>
        </.button_group>
        """)

      assert html =~ ~s(data-orientation="vertical")
      assert html =~ "flex-col"
      assert html =~ "[&amp;&gt;*:not(:first-child)]:rounded-t-none"
      assert html =~ "[&amp;&gt;*:not(:first-child)]:border-t-0"
      refute html =~ "rounded-l-none"
    end

    test "joins triggers wrapped by SaladUI component roots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button_group>
          <.button variant="outline">Follow</.button>
        </.button_group>
        """)

      assert html =~
               "[&amp;&gt;[data-component]:not(:first-child)&gt;[data-part=trigger]]:rounded-l-none"
    end

    test "supports nested groups" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button_group>
          <.button_group><.button>1</.button></.button_group>
          <.button_group><.button>2</.button></.button_group>
        </.button_group>
        """)

      assert count_substring(html, ~s(data-slot="button-group")) == 3
      assert html =~ "has-[&gt;[data-slot=button-group]]:gap-2"
    end
  end

  describe "button_group_text/1" do
    test "renders a div by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button_group_text>.com</.button_group_text>
        """)

      assert html =~ ~s(<div)
      assert html =~ ~s(data-slot="button-group-text")
      assert html =~ "bg-muted"
      assert html =~ ".com"
    end

    test "as=label renders a label for an input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button_group>
          <.button_group_text as="label" for="name">Text</.button_group_text>
          <.input id="name" placeholder="Type something here..." />
        </.button_group>
        """)

      assert html =~ ~r/<label[^>]*for="name"/
      assert html =~ ~r/<label[^>]*data-slot="button-group-text"/
      refute html =~ ~s(name="label")
    end
  end

  describe "button_group_separator/1" do
    test "defaults to a vertical separator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button_group_separator />
        """)

      assert html =~ ~s(role="none")
      assert html =~ ~s(data-slot="button-group-separator")
      refute html =~ ~s(data-slot="separator")
      assert html =~ ~s(data-orientation="vertical")
      # decorative by default, like shadcn's Separator: no aria-orientation
      refute html =~ "aria-orientation"
      assert length(Regex.scan(~r/data-orientation=/, html)) == 1
      assert html =~ "self-stretch"
      assert html =~ "bg-input"
      assert html =~ "data-[orientation=vertical]:h-auto"
    end

    test "horizontal orientation" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.button_group_separator orientation="horizontal" />
        """)

      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ "w-full"
    end
  end
end
