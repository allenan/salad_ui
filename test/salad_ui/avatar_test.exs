defmodule SaladUI.AvatarTest do
  use ComponentCase

  import SaladUI.Avatar

  describe "Test Avatar" do
    test "It renders avatar image correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.avatar_image src="https://github.com/shadcn.png" />
        """)

      for class <- ~w(absolute inset-0 aspect-square size-full) do
        assert html =~ class
      end

      assert html =~ ~s(src="https://github.com/shadcn.png")
      # phx-update="ignore" without an id raises inside a LiveView
      refute html =~ "phx-update"
    end

    test "It renders fallback correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.avatar_fallback class="bg-primary text-white">CN</.avatar_fallback>
        """)

      for class <- ~w(flex rounded-full bg-primary text-white items-center justify-center w-full h-full) do
        assert html =~ class
      end

      assert html =~ "CN"
    end

    test "It renders avatar correctly" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.avatar>
          <.avatar_image src="https://github.com/shadcn.png" />
          <.avatar_fallback class="bg-primary text-white">CN</.avatar_fallback>
        </.avatar>
        """)

      for class <- ~w(flex rounded-full bg-primary text-white items-center justify-center w-full h-full) do
        assert html =~ class
      end

      assert html =~ "CN"
    end
  end
end
