defmodule SaladUI.SelectTest do
  use ComponentCase

  import SaladUI.Select

  describe "select/1" do
    test "renders root with options, event mappings and tracking input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select id="fruit" name="fruit" default-value="banana" on-value-changed="changed">
          <.select_trigger>
            <.select_value placeholder="Select a fruit" />
          </.select_trigger>
          <.select_content>
            <.select_item value="banana">Banana</.select_item>
          </.select_content>
        </.select>
        """)

      assert html =~ ~s(data-slot="select")
      assert html =~ ~s(data-component="select")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(&quot;defaultValue&quot;:&quot;banana&quot;)
      assert html =~ ~s(&quot;value-changed&quot;:&quot;changed&quot;)
      assert html =~ ~s(data-salad-ui-select-tracker="true")
      assert html =~ ~s(name="fruit")
      refute html =~ "data-disabled"
      assert html =~ ~s(&quot;disabled&quot;:false)
    end

    test "disabled marks the root and options, and disables the tracking input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select id="fruit" name="fruit" disabled>
          <.select_trigger>
            <.select_value placeholder="Select a fruit" />
          </.select_trigger>
          <.select_content>
            <.select_item value="banana">Banana</.select_item>
          </.select_content>
        </.select>
        """)

      assert_tag(html, "div", [{"data-slot", "select"}, {"data-disabled", "true"}])
      assert html =~ ~s(&quot;disabled&quot;:true)
      assert html =~ ~r/<input[^>]*disabled[^>]*data-salad-ui-select-tracker/
      # The trigger picks up the disabled styling from the root.
      assert html =~ "group-data-[disabled=true]/select:opacity-50"
    end

    test ":let hands the disabled state to the trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select :let={select} id="fruit" disabled>
          <.select_trigger disabled={select.disabled}>
            <.select_value placeholder="Select a fruit" />
          </.select_trigger>
        </.select>
        """)

      assert html =~ ~r/<button[^>]*\sdisabled[\s>]/
    end
  end

  describe "select_trigger/1" do
    test "defaults to the default size" do
      html = render_component(&select_trigger/1, %{inner_block: []})

      assert html =~ ~s(data-slot="select-trigger")
      assert html =~ ~s(data-size="default")
      assert html =~ "data-[size=default]:h-9"
      assert html =~ "data-[size=sm]:h-8"
    end

    test "renders the small size" do
      html = render_component(&select_trigger/1, %{size: "sm", inner_block: []})

      assert html =~ ~s(data-size="sm")
    end

    test "a boolean aria-invalid renders as \"true\"" do
      html = render_component(&select_trigger/1, %{"aria-invalid": true, inner_block: []})

      assert html =~ ~s(aria-invalid="true")
    end

    test "passes disabled to the button" do
      html = render_component(&select_trigger/1, %{disabled: true, inner_block: []})

      assert html =~ ~r/<button[^>]*\sdisabled[\s>]/
    end
  end

  describe "select_content/1" do
    test "wraps items in a scrollable viewport between scroll buttons" do
      assigns = %{}

      html =
        ~H"""
        <.select_content class="w-64">
          <.select_item value="est">Eastern Standard Time</.select_item>
        </.select_content>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-slot="select-content")
      assert html =~ "max-h-[min(24rem,var(--salad-select-content-available-height,24rem))]"
      assert html =~ "w-64"

      [_, after_up] = String.split(html, ~s(data-slot="select-scroll-up-button"), parts: 2)
      [between, after_down] = String.split(after_up, ~s(data-slot="select-scroll-down-button"), parts: 2)

      assert between =~ ~s(data-part="viewport")
      assert between =~ "overflow-y-auto"
      assert between =~ "Eastern Standard Time"
      refute after_down =~ "Eastern Standard Time"
    end

    test "defaults to shadcn's item-aligned position, bottom side and center align" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select_content>
          <.select_item value="a">A</.select_item>
        </.select_content>
        """)

      assert html =~ ~s(data-position="item-aligned")
      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-align="center")
    end

    test "popper placement renders shadcn's popper classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select_content position="popper">
          <.select_item value="a">A</.select_item>
        </.select_content>
        """)

      assert html =~ ~s(data-position="popper")

      assert html =~
               "data-[side=bottom]:translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1 data-[side=top]:-translate-y-1"

      assert html =~
               "h-[var(--salad-select-trigger-height)] min-w-[var(--salad-select-trigger-width)] scroll-my-1"
    end

    test "item-aligned drops the popper classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select_content position="item-aligned">
          <.select_item value="a">A</.select_item>
        </.select_content>
        """)

      assert html =~ ~s(data-position="item-aligned")
      refute html =~ "translate-y-1"
      refute html =~ "--salad-select-trigger-height"
    end

    test "renders side and align" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select_content side="right" align="center">
          <.select_item value="a">A</.select_item>
        </.select_content>
        """)

      assert html =~ ~s(data-side="right")
      assert html =~ ~s(data-align="center")
      assert html =~ "left-full"
    end
  end

  describe "scroll buttons" do
    test "scroll-up button renders hidden, aria-hidden, with chevron up" do
      html = render_component(&select_scroll_up_button/1, %{class: "bg-popover"})

      assert html =~ ~s(data-slot="select-scroll-up-button")
      assert html =~ ~s(data-part="scroll-up-button")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "hidden"
      assert html =~ "lucide-chevron-up"
      assert html =~ "flex cursor-default items-center justify-center py-1 bg-popover"
    end

    test "scroll-down button renders hidden, aria-hidden, with chevron down" do
      html = render_component(&select_scroll_down_button/1, %{})

      assert html =~ ~s(data-slot="select-scroll-down-button")
      assert html =~ ~s(data-part="scroll-down-button")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ "lucide-chevron-down"
    end
  end

  describe "select_item/1" do
    test "renders value, disabled state and indicator" do
      html = render_component(&select_item/1, %{value: "grapes", disabled: true, inner_block: []})

      assert html =~ ~s(data-slot="select-item")
      assert html =~ ~s(data-value="grapes")
      assert html =~ ~s(data-disabled="true")
      assert html =~ ~s(data-slot="select-item-indicator")
    end

    test "uses shadcn's classes with the check indicator on the end side" do
      html = render_component(&select_item/1, %{value: "apple", inner_block: []})

      assert html =~
               "relative flex w-full cursor-default items-center gap-2 rounded-sm py-1.5 pe-8 ps-2 text-sm outline-hidden select-none focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 [&amp;_svg]:pointer-events-none [&amp;_svg]:shrink-0 [&amp;_svg:not([class*=&#39;size-&#39;])]:size-4 [&amp;_svg:not([class*=&#39;text-&#39;])]:text-muted-foreground *:[span]:last:flex *:[span]:last:items-center *:[span]:last:gap-2"

      assert html =~
               ~s(<span data-slot="select-item-indicator" class="absolute end-2 flex size-3.5 items-center justify-center">)

      refute html =~ "ps-8"
      refute html =~ "start-2"
      # The item text is the last span, which `*:[span]:last:flex` lays out.
      assert html =~ ~r/<span data-part="item-text"><\/span>\s*<\/div>\s*$/
    end

    test "passes data-text-value through for typeahead" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.select_item value="us" data-text-value="United States">🇺🇸 United States</.select_item>
        """)

      assert html =~ ~s(data-text-value="United States")
    end
  end

  describe "select_label/1" do
    test "uses shadcn's muted, small label classes" do
      html = render_component(&select_label/1, %{class: "extra", inner_block: []})

      assert html =~ ~s(data-slot="select-label")
      assert html =~ ~s(class="px-2 py-1.5 text-xs text-muted-foreground extra")
    end
  end

  describe "select_separator/1" do
    test "uses shadcn's classes and passes class and attributes through" do
      html = render_component(&select_separator/1, %{class: "my-2", "data-test": "sep"})

      assert html =~ ~s(data-slot="select-separator")
      assert html =~ ~s(aria-hidden="true")
      assert html =~ ~s(class="pointer-events-none -mx-1 h-px bg-border my-2")
      assert html =~ ~s(data-test="sep")
    end
  end
end
