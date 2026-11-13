defmodule SaladUI.HoverCardTest do
  use ComponentCase

  import SaladUI.HoverCard

  describe "hover_card" do
    test "renders root with JS hook, options, and event mappings" do
      assigns = %{}

      html =
        ~H"""
        <.hover_card id="user-card" open-delay={150} close-delay={75} on-open="opened" on-close="closed">
          <.hover_card_trigger>Trigger</.hover_card_trigger>
          <.hover_card_content>Content</.hover_card_content>
        </.hover_card>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "id=\"user-card\""
      assert html =~ "data-component=\"hover-card\""
      assert html =~ "data-state=\"closed\""
      assert html =~ "phx-hook=\"SaladUI\""
      assert html =~ "data-part=\"root\""
      assert html =~ "openDelay"
      assert html =~ "150"
      assert html =~ "closeDelay"
      assert html =~ "75"
      assert html =~ "open"
      assert html =~ "opened"
      assert html =~ "close"
      assert html =~ "closed"
    end

    test "renders trigger" do
      assigns = %{}

      html =
        ~H"""
        <.hover_card_trigger class="text-green-500">Hover Card</.hover_card_trigger>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-part=\"trigger\""
      assert html =~ "class=\"text-green-500\""
      assert html =~ "Hover Card"
    end

    test "renders content with default positioning attributes" do
      assigns = %{}

      html =
        ~H"""
        <.hover_card_content>Hover Card Content</.hover_card_content>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-part=\"content\""
      assert html =~ "data-side=\"bottom\""
      assert html =~ "data-align=\"center\""
      assert html =~ "data-side-offset=\"4\""
      assert html =~ "data-align-offset=\"0\""
      assert html =~ "class=\"z-50\""
      assert html =~ "hidden"
      refute html =~ "postion"
      assert html =~ "data-part=\"content-wrapper\""
      assert html =~ "w-64 rounded-md border border-border bg-popover p-4"
      assert html =~ "data-[side=top]:slide-in-from-bottom-2"
      assert html =~ "Hover Card Content"
    end

    test "renders content side and alignment attrs" do
      assigns = %{}

      html =
        ~H"""
        <.hover_card_content side="right" align="start" side-offset={12} align-offset={4}>
          Hover Card Content
        </.hover_card_content>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-side=\"right\""
      assert html =~ "data-align=\"start\""
      assert html =~ "data-side-offset=\"12\""
      assert html =~ "data-align-offset=\"4\""
      assert html =~ "data-side=\"right\" class=\"z-50 w-64"
      assert html =~ "data-part=\"content-wrapper\""
      assert html =~ "Hover Card Content"
    end
  end

  test "content renders collision-padding for the positioner" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.hover_card id="h">
        <.hover_card_content collision-padding={6}>x</.hover_card_content>
      </.hover_card>
      """)

    assert html =~ ~s(data-collision-padding="6")
  end

  describe "shared hover cards" do
    test "a trigger with `for` is detached, with the hover card ARIA" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_trigger as="button" type="button" for="user-card-7" context={%{id: 7}}>
          Ada
        </.hover_card_trigger>
        """)

      assert html =~ ~s(<button)
      assert html =~ ~s(type="button")
      assert html =~ ~s(data-salad-for="user-card-7")
      assert html =~ ~s(data-salad-context="{&quot;id&quot;:7}")
      assert html =~ ~s(aria-haspopup="dialog")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(data-state="closed")
      assert html =~ ~s(data-slot="hover-card-trigger")
      refute html =~ ~s(data-part="trigger")
    end

    test "a nested trigger renders as before" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card_trigger>Ada</.hover_card_trigger>
        """)

      assert html =~ ~s(<div)
      assert html =~ ~s(data-part="trigger")
      refute html =~ "data-salad-for"
      refute html =~ "aria-expanded"
    end
  end
end
