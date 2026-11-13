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

      for class <- ~w(flex rounded-full bg-primary text-white items-center justify-center size-full) do
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

      for class <- ~w(flex rounded-full bg-primary text-white items-center justify-center size-full) do
        assert html =~ class
      end

      assert html =~ "CN"
    end

    test "It renders every avatar size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.avatar size="sm">
          <.avatar_fallback>S</.avatar_fallback>
        </.avatar>
        <.avatar>
          <.avatar_fallback>D</.avatar_fallback>
        </.avatar>
        <.avatar size="lg">
          <.avatar_fallback>L</.avatar_fallback>
        </.avatar>
        """)

      for size <- ~w(sm default lg) do
        assert html =~ ~s(data-size="#{size}")
      end

      for class <-
            ~w(group/avatar relative flex size-8 shrink-0 rounded-full data-[size=lg]:size-10 data-[size=sm]:size-6 group-data-[size=sm]/avatar:text-xs) do
        assert html =~ class
      end

      # the badge must not be clipped by the avatar root
      refute html =~ "overflow-hidden"
    end

    test "It renders avatar_badge inside an avatar" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.avatar>
          <.avatar_fallback>ER</.avatar_fallback>
          <.avatar_badge class="bg-green-600 dark:bg-green-800" />
        </.avatar>
        """)

      assert html =~ ~s(data-slot="avatar-badge")

      for class <-
            ~w(absolute right-0 bottom-0 z-10 rounded-full ring-2 ring-background bg-green-600 dark:bg-green-800 group-data-[size=default]/avatar:size-2.5 group-data-[size=sm]/avatar:size-2 group-data-[size=lg]/avatar:size-3) do
        assert html =~ class
      end

      refute html =~ "bg-primary"
    end

    test "It renders avatar_group with a count" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.avatar_group class="grayscale">
          <.avatar size="lg">
            <.avatar_fallback>CN</.avatar_fallback>
          </.avatar>
          <.avatar size="lg">
            <.avatar_fallback>LR</.avatar_fallback>
          </.avatar>
          <.avatar_group_count>+3</.avatar_group_count>
        </.avatar_group>
        """)

      assert html =~ ~s(data-slot="avatar-group")
      assert html =~ ~s(data-slot="avatar-group-count")
      assert html =~ "+3"

      for class <-
            ~w(group/avatar-group flex -space-x-2 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background grayscale group-has-data-[size=lg]/avatar-group:size-10 group-has-data-[size=sm]/avatar-group:size-6) do
        assert html =~ class
      end
    end
  end
end
