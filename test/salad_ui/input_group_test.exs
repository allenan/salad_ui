defmodule SaladUI.InputGroupTest do
  use ComponentCase

  import SaladUI.InputGroup

  alias Phoenix.HTML.FormField

  describe "input_group/1" do
    test "renders a group wired to the SaladUI hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_group id="search" class="max-w-sm" aria-label="Search">
          <.input_group_input placeholder="Search..." />
        </.input_group>
        """)

      assert html =~ ~s(id="search")
      assert html =~ ~s(role="group")
      assert html =~ ~s(data-slot="input-group")
      assert html =~ ~s(data-component="input-group")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(aria-label="Search")
      assert html =~ "group/input-group"
      assert html =~ "max-w-sm"
      refute html =~ "data-disabled"
    end

    test "disabled sets data-disabled=true for the addon opacity selector" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_group id="busy" disabled>
          <.input_group_input disabled />
          <.input_group_addon>...</.input_group_addon>
        </.input_group>
        """)

      assert html =~ ~s(data-disabled="true")
      assert html =~ "group-data-[disabled=true]/input-group:opacity-50"
    end
  end

  describe "input_group_addon/1" do
    test "defaults to inline-start" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_group_addon>@</.input_group_addon>
        """)

      assert html =~ ~s(data-slot="input-group-addon")
      assert html =~ ~s(data-part="addon")
      assert html =~ ~s(data-align="inline-start")
      assert html =~ ~s(role="group")
      assert html =~ "order-first ps-3"
    end

    test "each alignment renders its classes" do
      for {align, class} <- [
            {"inline-end", "order-last pe-3"},
            {"block-start", "order-first w-full justify-start px-3 pt-3"},
            {"block-end", "order-last w-full justify-start px-3 pb-3"}
          ] do
        assigns = %{align: align}

        html =
          rendered_to_string(~H"""
          <.input_group_addon align={@align}>x</.input_group_addon>
          """)

        assert html =~ ~s(data-align="#{align}")
        assert html =~ class
        # block alignments replace justify-center with justify-start
        if String.starts_with?(align, "block"), do: refute(html =~ "justify-center")
      end
    end

    test "custom classes merge" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_group_addon align="block-end" class="border-t">x</.input_group_addon>
        """)

      assert html =~ "border-t"
      assert html =~ "[.border-t]:pt-3"
    end
  end

  describe "input_group_button/1" do
    test "defaults to a ghost xs type=button button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_group_button>Search</.input_group_button>
        """)

      assert html =~ ~s(type="button")
      assert html =~ ~s(data-slot="button")
      assert html =~ ~s(data-variant="ghost")
      assert html =~ ~s(data-size="xs")
      assert html =~ "h-6"
      assert html =~ "shadow-none"
      refute html =~ "h-9"
    end

    test "variant, size and attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_group_button
          variant="default"
          size="icon-xs"
          type="submit"
          aria-label="Send"
          disabled
          class="rounded-full"
        >
          ↑
        </.input_group_button>
        """)

      assert html =~ ~s(type="submit")
      assert html =~ ~s(data-variant="default")
      assert html =~ ~s(data-size="icon-xs")
      assert html =~ "bg-primary"
      assert html =~ "size-6"
      assert html =~ "rounded-full"
      refute html =~ "rounded-[calc(var(--radius)-5px)]"
      assert html =~ ~s(aria-label="Send")
      assert html =~ "disabled"
    end

    test "sm size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_group_button size="sm">Run</.input_group_button>
        """)

      assert html =~ "h-8"
      assert html =~ "px-2.5"
    end
  end

  test "input_group_text/1 renders a muted span" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_group_text class="font-mono">https://</.input_group_text>
      """)

    assert html =~ ~s(<span data-slot="input-group-text")
    assert html =~ "text-muted-foreground"
    assert html =~ "font-mono"
    assert html =~ "https://"
  end

  describe "input_group_input/1" do
    test "renders a borderless input tagged as the group control" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_group_input id="q" name="q" type="email" placeholder="Search..." value="hi" class="pl-1!" />
        """)

      assert html =~ ~s(data-slot="input-group-control")
      refute html =~ ~s(data-slot="input")
      assert html =~ ~s(id="q")
      assert html =~ ~s(name="q")
      assert html =~ ~s(type="email")
      assert html =~ ~s(value="hi")
      assert html =~ ~s(placeholder="Search...")
      assert html =~ "border-0"
      assert html =~ "rounded-none"
      assert html =~ "focus-visible:ring-0"
      assert html =~ "pl-1!"
      refute html =~ "rounded-md"
      refute html =~ "focus-visible:ring-[3px]"
    end

    test "builds from a form field and flags invalid fields" do
      assigns = %{
        field: %FormField{
          id: "user_email",
          name: "user[email]",
          value: "nope",
          errors: [{"is invalid", []}],
          field: :email,
          form: %Phoenix.HTML.Form{params: %{"email" => "nope"}}
        }
      }

      html =
        rendered_to_string(~H"""
        <.input_group_input field={@field} />
        """)

      assert html =~ ~s(id="user_email")
      assert html =~ ~s(name="user[email]")
      assert html =~ ~s(value="nope")
      assert html =~ ~s(aria-invalid="true")
    end
  end

  describe "input_group_textarea/1" do
    test "renders a borderless textarea tagged as the group control" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.input_group_textarea id="msg" name="msg" rows="4" placeholder="Message" value="Hello" />
        """)

      assert html =~ ~s(data-slot="input-group-control")
      refute html =~ ~s(data-slot="textarea")
      assert html =~ ~s(id="msg")
      assert html =~ ~s(rows="4")
      assert html =~ "resize-none"
      assert html =~ "py-3"
      assert html =~ "border-0"
      assert html =~ "Hello</textarea>"
    end
  end

  test "renders a full group" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.input_group id="url">
        <.input_group_input placeholder="example.com" />
        <.input_group_addon>
          <.input_group_text>https://</.input_group_text>
        </.input_group_addon>
        <.input_group_addon align="inline-end">
          <.input_group_button size="icon-xs" aria-label="Copy">C</.input_group_button>
        </.input_group_addon>
      </.input_group>
      """)

    assert count_substring(html, ~s(data-slot="input-group-addon")) == 2
    assert count_substring(html, ~s(data-slot="input-group-control")) == 1
  end
end
