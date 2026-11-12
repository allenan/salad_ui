defmodule SaladUI.ComboboxTest do
  use ComponentCase

  import SaladUI.Combobox
  import SaladUI.InputGroup, only: [input_group_addon: 1]

  defp slots(html) do
    ~r/\sdata-slot="([^"]+)"/
    |> Regex.scan(html, capture: :all_but_first)
    |> List.flatten()
  end

  defp options(html) do
    [_, raw] = Regex.run(~r/data-options="([^"]+)"/, html)
    raw |> String.replace("&quot;", "\"") |> Jason.decode!()
  end

  describe "combobox/1" do
    test "renders the hooked root with options, event mappings and tracking input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox
          id="fw"
          name="framework"
          default-value="Astro"
          auto-highlight
          on-value-changed="changed"
        >
          <.combobox_input placeholder="Select a framework" />
        </.combobox>
        """)

      assert html =~ ~s(id="fw")
      assert html =~ ~s(data-slot="combobox")
      assert html =~ ~s(data-component="combobox")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-state="closed")
      assert html =~ "group/combobox contents"
      assert html =~ ~s(data-salad-ui-combobox-tracker="true")
      assert html =~ ~s(name="framework")
      assert html =~ ~s(&quot;value-changed&quot;:&quot;changed&quot;)

      assert %{
               "value" => "Astro",
               "name" => "framework",
               "multiple" => false,
               "autoHighlight" => true,
               "filter" => true,
               "disabled" => false
             } = options(html)
    end

    test "multiple values are a list of strings and the tracker submits name[]" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox id="fw" name="frameworks" multiple value={[1, "Remix"]} filter={false}>
          <.combobox_chips><.combobox_chips_input /></.combobox_chips>
        </.combobox>
        """)

      assert %{"value" => ["1", "Remix"], "multiple" => true, "filter" => false} = options(html)
      assert html =~ ~s(name="frameworks[]")
      assert html =~ ~r/data-salad-ui-combobox-tracker="true"/
      assert html =~ ~r/<input[^>]*name="frameworks\[\]"[^>]*disabled/
    end

    test "omits the tracker without a name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox id="fw"><.combobox_input /></.combobox>
        """)

      refute html =~ "data-salad-ui-combobox-tracker"
      assert %{"value" => nil, "name" => nil} = options(html)
    end

    test "takes id, name, value and the invalid state from a form field" do
      form =
        Phoenix.Component.to_form(%{"framework" => "Remix"},
          as: :project,
          errors: [framework: {"is invalid", []}]
        )

      assigns = %{form: form}

      html =
        rendered_to_string(~H"""
        <.combobox field={@form[:framework]}><.combobox_input /></.combobox>
        """)

      assert html =~ ~s(id="project_framework")
      assert html =~ ~s(name="project[framework]")
      assert html =~ ~s(data-invalid="true")
      assert %{"value" => "Remix"} = options(html)
    end

    test "disabled marks the root" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox id="fw" disabled><.combobox_input /></.combobox>
        """)

      assert html =~ ~s(data-disabled="true")
      assert %{"disabled" => true} = options(html)
    end
  end

  describe "combobox_input/1" do
    test "renders a combobox input in an input group with a trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox_input placeholder="Select a framework" aria-invalid="true" phx-debounce="300" />
        """)

      assert html =~ ~s(data-slot="input-group")
      assert html =~ "w-auto"
      assert html =~ ~s(data-slot="input-group-control")
      assert html =~ ~s(data-part="input")
      assert html =~ ~s(role="combobox")
      assert html =~ ~s(aria-autocomplete="list")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(autocomplete="off")
      assert html =~ ~s(placeholder="Select a framework")
      assert html =~ ~s(aria-invalid="true")
      assert html =~ ~s(phx-debounce="300")
      assert html =~ ~s(data-slot="combobox-trigger")
      assert html =~ ~s(data-slot="combobox-trigger-icon")
      assert html =~ ~s(data-part="trigger")
      refute html =~ ~s(data-slot="combobox-clear")
    end

    test "show-clear renders a hidden clear button and show-trigger can drop the trigger" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox_input show-clear show-trigger={false} />
        """)

      [clear] = Regex.run(~r/<button[^>]*data-slot="combobox-clear"[^>]*>/, html)
      assert clear =~ ~r/\shidden[\s>]/
      assert html =~ ~s(aria-label="Clear")
      refute html =~ ~s(data-slot="combobox-trigger")

      bare =
        rendered_to_string(~H"""
        <.combobox_input show-trigger={false} />
        """)

      refute bare =~ ~s(data-slot="input-group-addon")
    end

    test "renders extra addons inside the group" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox_input placeholder="Select a timezone">
          <.input_group_addon><span id="globe"></span></.input_group_addon>
        </.combobox_input>
        """)

      assert html =~ ~s(id="globe")
      assert html =~ ~s(data-align="inline-start")
    end

    test "disabled disables the input and its buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox_input disabled show-clear />
        """)

      assert html =~ ~s(data-disabled="true")
      assert html =~ ~r/<input[^>]*disabled/
      assert length(Regex.scan(~r/<button[^>]*disabled/, html)) == 2
    end
  end

  describe "combobox_trigger/1 and combobox_value/1" do
    test "a button-styled trigger showing the value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox_trigger variant="outline" class="w-64 justify-between font-normal">
          <.combobox_value placeholder="Select a country" />
        </.combobox_trigger>
        """)

      assert html =~ ~s(data-slot="combobox-trigger")
      assert html =~ ~s(aria-haspopup="listbox")
      assert html =~ ~s(type="button")
      assert html =~ "border bg-background"
      assert html =~ "w-64"
      assert html =~ ~s(data-slot="combobox-value")
      assert html =~ ~s(data-placeholder="Select a country")
      assert html =~ ">Select a country</span>"
    end

    test "is unstyled without a variant" do
      html = render_component(&combobox_trigger/1, %{inner_block: []})
      refute html =~ "bg-background"
    end
  end

  describe "combobox_content/1" do
    test "renders the hidden positioned popup" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox_content align="end" align-offset={-28} class="w-60">
          <.combobox_empty>No items found.</.combobox_empty>
          <.combobox_list>
            <.combobox_item value="a">A</.combobox_item>
          </.combobox_list>
        </.combobox_content>
        """)

      assert html =~ ~r/<div[^>]*data-slot="combobox-content"[^>]*hidden/
      assert html =~ ~s(data-side="bottom")
      assert html =~ ~s(data-align="end")
      assert html =~ ~s(data-side-offset="6")
      assert html =~ ~s(data-align-offset="-28")
      assert html =~ "group/combobox-content"
      assert html =~ "w-60"
      assert html =~ ~s(role="listbox")
      assert html =~ "group-data-empty/combobox-content:flex"
      assert html =~ "data-empty:p-0"
    end
  end

  describe "combobox_item/1" do
    test "renders an option with a hidden check indicator" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox_item value={42} label="Answer" disabled>The answer</.combobox_item>
        """)

      assert html =~ ~s(role="option")
      assert html =~ ~s(data-value="42")
      assert html =~ ~s(data-label="Answer")
      assert html =~ ~s(data-disabled="true")
      assert html =~ ~s(aria-disabled="true")
      assert html =~ ~s(aria-selected="false")
      assert html =~ "data-highlighted:bg-accent"
      assert html =~ ~r/data-slot="combobox-item-indicator"[^>]*hidden/
    end
  end

  describe "combobox_chips/1" do
    test "renders a chip template and the chips input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox_chips class="w-full max-w-xs">
          <.combobox_chip value="Next.js">Next.js</.combobox_chip>
          <.combobox_chips_input placeholder="Add framework" />
        </.combobox_chips>
        """)

      assert html =~ ~r/<template data-part="chip-template">\s*<div[^>]*data-slot="combobox-chip"/
      assert html =~ ~s(data-slot="combobox-chip-remove")
      assert html =~ ~s(data-slot="combobox-chip-input")
      assert html =~ ~s(data-value="Next.js")
      assert html =~ ~s(placeholder="Add framework")
      assert html =~ "max-w-xs"
    end

    test "show-remove={false} drops the remove buttons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.combobox_chips show-remove={false}><.combobox_chips_input /></.combobox_chips>
        """)

      refute html =~ ~s(data-slot="combobox-chip-remove")
    end
  end

  test "every part carries its shadcn data-slot, once" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.combobox id="c" name="c" multiple>
        <.combobox_chips><.combobox_chips_input /></.combobox_chips>
        <.combobox_trigger><.combobox_value placeholder="P" /></.combobox_trigger>
        <.combobox_content>
          <.combobox_input show-clear />
          <.combobox_empty>None</.combobox_empty>
          <.combobox_list>
            <.combobox_group>
              <.combobox_label>L</.combobox_label>
              <.combobox_item value="a">A</.combobox_item>
              <.combobox_separator />
            </.combobox_group>
          </.combobox_list>
        </.combobox_content>
      </.combobox>
      """)

    expected =
      ~w(combobox combobox-chips combobox-chip combobox-chip-remove combobox-chip-input
         combobox-trigger combobox-trigger-icon combobox-value combobox-content input-group
         input-group-control combobox-clear combobox-empty combobox-list combobox-group
         combobox-label combobox-item combobox-item-indicator combobox-separator)

    assert expected -- slots(html) == []

    duplicated =
      for [tag] <- Regex.scan(~r/<[a-zA-Z][^>]*>/, html),
          length(Regex.scan(~r/\sdata-slot=/, tag)) > 1,
          do: tag

    assert duplicated == []
  end
end
