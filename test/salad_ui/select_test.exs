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
  end
end
