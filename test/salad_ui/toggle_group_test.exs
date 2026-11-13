defmodule SaladUI.ToggleGroupTest do
  use ComponentCase

  import SaladUI.ToggleGroup

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField

  defp items(html) do
    ~r/<button[^>]*data-slot="toggle-group-item"[^>]*>/
    |> Regex.scan(html)
    |> List.flatten()
  end

  defp item(html, value), do: Enum.find(items(html), &(&1 =~ ~s(data-value="#{value}")))

  describe "toggle_group/1" do
    test "renders the v4 root with data attributes, gap and hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg" type="multiple" variant="outline" size="sm">
          <.toggle_group_item value="a" builder={builder}>A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(id="tg")
      assert html =~ ~s(role="group")
      assert html =~ ~s(data-slot="toggle-group")
      assert html =~ ~s(data-component="toggle-group")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(data-size="sm")
      assert html =~ ~s(data-spacing="0")
      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ ~s(style="--gap: 0")
      assert html =~ "group/toggle-group flex w-fit items-center gap-[--spacing(var(--gap))] rounded-md"
      assert html =~ "data-[spacing=default]:data-[variant=outline]:shadow-xs"
      assert html =~ ~s(&quot;type&quot;:&quot;multiple&quot;)
      assert html =~ ~s(&quot;loop&quot;:true)
      refute html =~ "gap-1 "
    end

    test "spacing, orientation and loop reach the root and options" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group
          :let={builder}
          id="tg"
          spacing={2}
          orientation="vertical"
          loop={false}
          style="color: red"
        >
          <.toggle_group_item value="a" builder={builder}>A</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(data-spacing="2")
      assert html =~ ~s(style="--gap: 2; color: red")
      assert html =~ ~s(data-orientation="vertical")
      assert html =~ "data-[orientation=vertical]:flex-col"
      assert html =~ ~s(&quot;orientation&quot;:&quot;vertical&quot;)
      assert html =~ ~s(&quot;loop&quot;:false)
      assert item(html, "a") =~ ~s(data-spacing="2")
      assert item(html, "a") =~ ~s(data-orientation="vertical")
    end

    test "a multiple group bound to a field submits a list" do
      assigns = %{
        field: %FormField{
          id: "styles",
          name: "styles",
          errors: [],
          field: :styles,
          form: %Form{params: %{}},
          value: [:bold]
        }
      }

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} field={@field} type="multiple">
          <.toggle_group_item value="bold" builder={builder}>B</.toggle_group_item>
          <.toggle_group_item value="italic" builder={builder}>I</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~s(id="styles")
      assert html =~ ~r/<input type="checkbox"[^>]*name="styles\[\]"[^>]*value="bold"[^>]*checked/
      assert item(html, "italic") =~ ~s(aria-pressed="false")
      refute html =~ ~s(type="hidden")
    end

    test "a single group submits an empty value when nothing is pressed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg" name="align">
          <.toggle_group_item value="left" builder={builder}>L</.toggle_group_item>
        </.toggle_group>
        """)

      # The empty hidden input comes first, so a pressed radio overrides it.
      assert html =~ ~r/<input type="hidden" name="align" value="">.*<input type="radio"[^>]*name="align"/s
    end

    test "a single group without a name renders no hidden input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg">
          <.toggle_group_item value="left" builder={builder}>L</.toggle_group_item>
        </.toggle_group>
        """)

      refute html =~ ~s(type="hidden")
    end

    test "a multiple group with a plain name submits a list" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg" name="styles" type="multiple">
          <.toggle_group_item value="bold" builder={builder}>B</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~r/<input type="checkbox"[^>]*name="styles\[\]"/
    end

    test "raises for a non-list value in multiple mode" do
      assigns = %{}

      assert_raise ArgumentError, fn ->
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg" type="multiple" value="a">
          <.toggle_group_item value="a" builder={builder}>A</.toggle_group_item>
        </.toggle_group>
        """)
      end
    end
  end

  describe "toggle_group_item/1" do
    test "single items are radios with aria-checked and data-state" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg" type="single" name="align" value="left">
          <.toggle_group_item value="left" builder={builder} aria-label="Left">L</.toggle_group_item>
          <.toggle_group_item value="right" builder={builder} aria-label="Right">R</.toggle_group_item>
        </.toggle_group>
        """)

      left = item(html, "left")
      right = item(html, "right")

      assert left =~ ~s(role="radio")
      assert left =~ ~s(aria-checked="true")
      assert left =~ ~s(data-state="on")
      assert left =~ ~s(aria-label="Left")
      refute left =~ "aria-pressed"
      assert right =~ ~s(aria-checked="false")
      assert right =~ ~s(data-state="off")
      assert html =~ ~r/<input type="radio"[^>]*name="align"[^>]*value="left"[^>]*checked/
    end

    test "multiple items use aria-pressed" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg" type="multiple" value={["bold"]}>
          <.toggle_group_item value="bold" builder={builder}>B</.toggle_group_item>
          <.toggle_group_item value="italic" builder={builder}>I</.toggle_group_item>
        </.toggle_group>
        """)

      assert item(html, "bold") =~ ~s(aria-pressed="true")
      assert item(html, "bold") =~ ~s(data-state="on")
      assert item(html, "italic") =~ ~s(aria-pressed="false")
      refute item(html, "bold") =~ "role="
      assert html =~ ~s(type="checkbox")
    end

    test "the legacy multiple attr still selects multiple mode" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg" multiple value={["a"]}>
          <.toggle_group_item value="a" builder={builder}>A</.toggle_group_item>
        </.toggle_group>
        """)

      assert item(html, "a") =~ ~s(aria-pressed="true")
    end

    test "items take variant, size and spacing from the builder plus the v4 item classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg" variant="outline" size="lg">
          <.toggle_group_item value="a" builder={builder}>A</.toggle_group_item>
        </.toggle_group>
        """)

      a = item(html, "a")
      assert a =~ ~s(data-variant="outline")
      assert a =~ ~s(data-size="lg")
      assert a =~ ~s(data-spacing="0")
      assert a =~ ~s(data-orientation="horizontal")
      assert a =~ "w-auto min-w-0 shrink-0 px-3 focus:z-10 focus-visible:z-10"
      assert a =~ "h-10"
      refute a =~ "min-w-10"
      assert a =~ "data-[spacing=0]:rounded-none data-[spacing=0]:shadow-none"
      assert a =~ "data-[spacing=0]:data-[orientation=horizontal]:first:rounded-s-md"
      assert a =~ "data-[spacing=0]:data-[orientation=vertical]:last:rounded-b-md"
      assert a =~ "data-[spacing=0]:data-[orientation=horizontal]:data-[variant=outline]:border-s-0"
      assert a =~ "data-[state=on]:bg-accent"
      assert a =~ "aria-invalid:border-destructive"
    end

    test "an item variant applies when the group sets none" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg">
          <.toggle_group_item value="a" variant="outline" builder={builder}>A</.toggle_group_item>
        </.toggle_group>
        """)

      assert item(html, "a") =~ ~s(data-variant="outline")
    end

    test "disabled group disables every item" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} id="tg" disabled>
          <.toggle_group_item value="a" builder={builder}>A</.toggle_group_item>
          <.toggle_group_item value="b" builder={builder}>B</.toggle_group_item>
        </.toggle_group>
        """)

      for value <- ~w(a b), do: assert(item(html, value) =~ ~r/ disabled[ >]/)
    end

    test "field errors mark the group and its items invalid" do
      assigns = %{
        field: %FormField{
          id: "style",
          name: "style",
          errors: [{"is invalid", []}],
          field: :style,
          form: %Form{params: %{"style" => "bold"}},
          value: "bold"
        }
      }

      html =
        rendered_to_string(~H"""
        <.toggle_group :let={builder} field={@field}>
          <.toggle_group_item value="bold" builder={builder}>B</.toggle_group_item>
        </.toggle_group>
        """)

      assert html =~ ~r/<div id="style"[^>]*aria-invalid="true"/
      assert html =~ ~s(name="style")
      assert item(html, "bold") =~ ~s(aria-invalid="true")
      assert item(html, "bold") =~ ~s(data-state="on")
    end
  end

  describe "controlled" do
    test "value or a field makes the group controlled, default-value does not" do
      assigns = %{}

      controlled =
        rendered_to_string(~H"""
        <.toggle_group :let={b} id="g1" value="a">
          <.toggle_group_item builder={b} value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      uncontrolled =
        rendered_to_string(~H"""
        <.toggle_group :let={b} id="g2" default-value="a">
          <.toggle_group_item builder={b} value="a">A</.toggle_group_item>
        </.toggle_group>
        """)

      assert controlled =~ ~s(&quot;controlled&quot;:true)
      assert uncontrolled =~ ~s(&quot;controlled&quot;:false)
    end
  end
end
