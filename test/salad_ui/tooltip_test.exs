defmodule SaladUI.TooltipTest do
  use ComponentCase

  import SaladUI.Tooltip

  describe "tooltip" do
    test "renders root with id, hook, options, and event mappings" do
      assigns = %{}

      html =
        ~H"""
        <.tooltip id="tip" open-delay={125} close-delay={50} on-open="opened" on-close="closed">
          <.tooltip_trigger>Trigger</.tooltip_trigger>
          <.tooltip_content>Content</.tooltip_content>
        </.tooltip>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(id="tip")
      assert html =~ "data-component=\"tooltip\""
      assert html =~ "data-state=\"closed\""
      assert html =~ "phx-hook=\"SaladUI\""
      assert html =~ "data-part=\"root\""
      assert html =~ "openDelay"
      assert html =~ "125"
      assert html =~ "closeDelay"
      assert html =~ "50"
      assert html =~ "open"
      assert html =~ "opened"
      assert html =~ "close"
      assert html =~ "closed"
      refute html =~ "closed_to_open"
      assert html =~ "open_to_closed"
    end

    test "renders explicit id and trigger" do
      assigns = %{}

      html =
        ~H"""
        <.tooltip id="help-tooltip">
          <.tooltip_trigger class="text-green-500">Help</.tooltip_trigger>
          <.tooltip_content>Tooltip content</.tooltip_content>
        </.tooltip>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "id=\"help-tooltip\""
      assert html =~ "data-part=\"trigger\""
      assert html =~ "class=\"text-green-500\""
      assert html =~ "Help"
    end

    test "renders content with positioning attributes" do
      assigns = %{}

      html =
        ~H"""
        <.tooltip_content side="right" align="start" side-offset={12} align-offset={4}>
          Tooltip content
        </.tooltip_content>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-part=\"content\""
      assert html =~ "data-side=\"right\""
      assert html =~ "data-align=\"start\""
      assert html =~ "data-side-offset=\"12\""
      assert html =~ "data-align-offset=\"4\""
      assert html =~ "z-50 w-fit animate-in rounded-md bg-foreground px-3 py-1.5 text-xs text-balance text-background"
      assert html =~ "data-slot=\"tooltip-content\""
      refute html =~ "shadow-md"
      assert html =~ "data-[side=right]:slide-in-from-left-2"
      assert html =~ "hidden"
      assert html =~ "Tooltip content"
    end

    test "renders shadcn's arrow, positioned by the content's data-side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_content side="bottom">Tip</.tooltip_content>
        """)

      assert html =~ "group/tooltip z-50"
      assert html =~ ~s(data-slot="tooltip-arrow")
      assert html =~ ~s(aria-hidden="true")

      assert html =~
               "z-50 block size-2.5 translate-y-[calc(-50%_-_2px)] rotate-45 rounded-[2px] bg-foreground fill-foreground"

      for side <- ~w(top bottom left right) do
        assert html =~ "group-data-[side=#{side}]/tooltip:"
      end

      assert html =~ "group-data-[side=bottom]/tooltip:bottom-full"
      assert html =~ "group-data-[side=bottom]/tooltip:rotate-180"
      assert html =~ "group-data-[side=left]/tooltip:left-full"
      assert html =~ "group-data-[side=right]/tooltip:right-full"
    end
  end

  describe "tooltip_trigger as" do
    import SaladUI.Button

    test "renders the given component as the trigger itself" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_trigger as={&button/1} variant="outline" size="icon-sm" aria-label="Details">
          i
        </.tooltip_trigger>
        """)

      assert_tag(html, "button", [{"data-slot", "tooltip-trigger"}, {"data-part", "trigger"}, {"data-variant", "outline"}])

      refute html =~ "<div"
      assert duplicate_attrs(html) == []
    end

    test "a plain tag drops button props" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_trigger as="span" variant="outline">i</.tooltip_trigger>
        """)

      assert_tag(html, "span", [{"data-part", "trigger"}])
      refute html =~ "variant"
    end
  end

  test "content renders collision-padding for the positioner" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.tooltip id="t">
        <.tooltip_content collision-padding={6}>x</.tooltip_content>
      </.tooltip>
      """)

    assert html =~ ~s(data-collision-padding="6")
  end

  describe "shared tooltips" do
    test "tooltip_provider renders one hooked tooltip with a server-rendered content id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_provider id="tooltips" scope="#list" side="bottom" open-delay={0} />
        """)

      assert html =~ ~s(id="tooltips")
      assert html =~ ~s(data-component="tooltip-provider")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(id="tooltips-content")
      assert html =~ ~s(data-part="text")
      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-slot="tooltip-arrow")
      assert html =~ "&quot;scope&quot;:&quot;#list&quot;"
      assert html =~ "&quot;openDelay&quot;:0"
      assert html =~ "&quot;skipDelay&quot;:300"
    end

    test "a tooltip trigger with `for` is detached and leaves data-state alone" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip_trigger for="presence" context={%{id: 3}}>Ada</.tooltip_trigger>
        """)

      assert html =~ ~s(data-salad-for="presence")
      assert html =~ ~s(data-salad-context="{&quot;id&quot;:3}")
      refute html =~ ~s(data-part="trigger")
      refute html =~ "data-state"
    end

    test "tooltip passes skip-delay to the client" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip id="t" skip-delay={0}>
          <.tooltip_content>x</.tooltip_content>
        </.tooltip>
        """)

      assert html =~ "&quot;skipDelay&quot;:0"
    end
  end
end
