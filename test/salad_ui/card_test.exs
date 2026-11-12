defmodule SaladUI.CardTest do
  use ComponentCase

  import SaladUI.Button
  import SaladUI.Card

  describe "Test Card" do
    test "It renders card header correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_header>The card header</.card_header>
        """)

      assert html =~ "The card header"

      for class <-
            ~w|grid auto-rows-min items-start gap-2 px-[var(--card-spacing)] has-data-[slot=card-action]:grid-cols-[1fr_auto]| do
        assert html =~ class
      end
    end

    test "It renders card title correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_title>Card title</.card_title>
        """)

      assert html =~ "Card title"

      for class <- ~w(leading-none font-semibold) do
        assert html =~ class
      end
    end

    test "It renders card description correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_description>Card Description Body</.card_description>
        """)

      assert html =~ "Card Description Body"

      for class <- ~w(text-sm text-muted-foreground) do
        assert html =~ class
      end
    end

    test "It renders card content correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_content>Card Content available</.card_content>
        """)

      assert html =~ "Card Content available"

      for class <- ~w|px-[var(--card-spacing)]| do
        assert html =~ class
      end
    end

    test "It renders card footer correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_footer>Card footer</.card_footer>
        """)

      assert html =~ "Card footer"

      for class <- ~w|flex items-center px-[var(--card-spacing)] [.border-t]:pt-[var(--card-spacing)]| do
        assert html =~ class
      end
    end

    test "It renders card correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card>
          <.card_header>
            <.card_title>Card title</.card_title>

            <.card_description>Card subtitle</.card_description>
          </.card_header>

          <.card_content>
            Card text
          </.card_content>

          <.card_footer>
            <.button>Button</.button>
          </.card_footer>
        </.card>
        """)

      assert html =~ "Card title"
      assert html =~ "Card subtitle"
      assert html =~ "Card text"
      assert html =~ "<button"
      assert html =~ "Button"
      assert html =~ ~s(data-slot="card" data-size="default")
      assert html =~ "[--card-spacing:--spacing(6)]"
      assert html =~ "data-[size=sm]:[--card-spacing:--spacing(4)]"
    end

    test "It renders card_action in the header grid" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card_header>
          <.card_title>Login</.card_title>
          <.card_action class="extra-action">
            <.button variant="link">Sign Up</.button>
          </.card_action>
        </.card_header>
        """)

      assert html =~ ~s(data-slot="card-action")
      assert html =~ "Sign Up"

      for class <- ~w(col-start-2 row-span-2 row-start-1 self-start justify-self-end extra-action) do
        assert html =~ class
      end
    end

    test "It renders a small card" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card size="sm">
          <.card_title>Small</.card_title>
        </.card>
        """)

      assert html =~ ~s(data-size="sm")
      assert html =~ "group-data-[size=sm]/card:text-sm"
    end

    test "A custom --card-spacing replaces the default" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.card class="[--card-spacing:--spacing(3)]">Spaced</.card>
        """)

      assert html =~ "[--card-spacing:--spacing(3)]"
      refute html =~ "[--card-spacing:--spacing(6)]"
    end
  end
end
