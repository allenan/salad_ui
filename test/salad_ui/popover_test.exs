defmodule SaladUI.PopoverTest do
  use ComponentCase

  import SaladUI.Button
  import SaladUI.Popover

  describe "popover/1" do
    test "renders closed root with component options" do
      assigns = %{id: "profile-popover"}

      html =
        ~H"""
        <.popover id={@id}>Popover</.popover>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "id=\"profile-popover\""
      assert html =~ "class=\"relative inline-block\""
      assert html =~ "data-component=\"popover\""
      assert html =~ "data-state=\"closed\""
      assert html =~ "data-event-mappings=\"{}\""
      assert html =~ "data-options="
      assert html =~ "portalContainer"
      assert html =~ ~r/usePortal.{0,20}false/
      assert html =~ "phx-hook=\"SaladUI\""
    end

    test "renders open root state and custom portal container" do
      assigns = %{id: "profile-popover"}

      html =
        ~H"""
        <.popover id={@id} open use-portal portal-container="#overlay">Popover</.popover>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-state=\"open\""
      assert html =~ "#overlay"
      assert html =~ ~r/usePortal.{0,20}true/
    end
  end

  describe "popover_trigger/1" do
    test "renders native button trigger and forwards global attributes" do
      assigns = %{}

      html =
        ~H"""
        <.popover_trigger class="text-green-500" target="popover-id">Popover</.popover_trigger>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "<button"
      assert html =~ "type=\"button\""
      assert html =~ "data-part=\"trigger\""
      assert html =~ "data-action=\"toggle\""
      assert html =~ "class=\"text-green-500\""
      assert html =~ "target=\"popover-id\""
      assert html =~ "Popover"
    end

    test "renders configured function component as trigger root" do
      assigns = %{}

      html =
        ~H"""
        <.popover_trigger as={&button/1} variant="outline">Popover</.popover_trigger>
        """
        |> rendered_to_string()
        |> clean_string()

      assert count_substring(html, "<button") == 1
      assert html =~ "type=\"button\""
      assert html =~ "data-part=\"trigger\""
      assert html =~ "data-action=\"toggle\""
      assert html =~ "Popover"
    end

    test "renders configured HTML tag as trigger root" do
      assigns = %{}

      html =
        ~H"""
        <.popover_trigger as="a" href="/profile">Profile</.popover_trigger>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "<a"
      assert html =~ "href=\"/profile\""
      assert html =~ "data-part=\"trigger\""
      refute html =~ "type=\"button\""
    end
  end

  describe "popover_content/1" do
    test "renders configured positioner and forwards content attributes" do
      assigns = %{id: "popover-content"}

      html =
        ~H"""
        <.popover_content
          id={@id}
          side="right"
          align="end"
          side-offset={12}
          align-offset={-4}
          class="w-80"
        >
          Popover Content
        </.popover_content>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ "data-part=\"positioner\""
      assert html =~ "data-side=\"right\""
      assert html =~ "data-align=\"end\""
      assert html =~ "data-side-offset=\"12\""
      assert html =~ "data-align-offset=\"-4\""
      assert html =~ "class=\"absolute z-50\""
      assert html =~ "hidden"
      assert html =~ "data-part=\"content\""
      assert html =~ "id=\"popover-content\""
      assert html =~ "w-80"
      assert html =~ "data-[state=open]:animate-in"
      assert html =~ "data-[side=right]:slide-in-from-left-2"
      assert html =~ "Popover Content"
    end
  end

  describe "popover_anchor/1" do
    test "renders anchor part with slot and classes" do
      assigns = %{}

      html =
        ~H"""
        <.popover_anchor class="w-64" id="anchor">Anchor here</.popover_anchor>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-slot="popover-anchor")
      assert html =~ ~s(data-part="anchor")
      assert html =~ ~s(class="w-64")
      assert html =~ ~s(id="anchor")
      assert html =~ "Anchor here"
    end
  end

  describe "popover header parts" do
    test "render shadcn slots and classes" do
      assigns = %{}

      html =
        ~H"""
        <.popover_header class="mb-2">
          <.popover_title>Dimensions</.popover_title>
          <.popover_description class="text-xs">Set the dimensions for the layer.</.popover_description>
        </.popover_header>
        """
        |> rendered_to_string()
        |> clean_string()

      assert html =~ ~s(data-slot="popover-header" class="flex flex-col gap-1 text-sm mb-2")
      assert html =~ ~s(<div data-slot="popover-title" class="font-medium">)
      assert html =~ ~s(<p data-slot="popover-description" class="text-muted-foreground text-xs">)
      assert html =~ "Dimensions"
      assert html =~ "Set the dimensions for the layer."
    end
  end

  describe "server state and collision padding" do
    test "the root renders the server's open as data-open" do
      assigns = %{}

      closed =
        rendered_to_string(~H"""
        <.popover id="p1">
          <.popover_trigger>Open</.popover_trigger><.popover_content>x</.popover_content>
        </.popover>
        """)

      open =
        rendered_to_string(~H"""
        <.popover id="p2" open>
          <.popover_trigger>Open</.popover_trigger><.popover_content>x</.popover_content>
        </.popover>
        """)

      assert closed =~ ~s(data-open="false")
      assert open =~ ~s(data-open="true")
    end

    test "collision-padding is rendered on the positioner, 0 by default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.popover id="p">
          <.popover_content collision-padding={8}>x</.popover_content>
        </.popover>
        """)

      default =
        rendered_to_string(~H"""
        <.popover id="p">
          <.popover_content>x</.popover_content>
        </.popover>
        """)

      assert html =~ ~s(data-collision-padding="8")
      assert default =~ ~s(data-collision-padding="0")
    end
  end
end
