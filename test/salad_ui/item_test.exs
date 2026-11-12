defmodule SaladUI.ItemTest do
  use ComponentCase

  import SaladUI.Item

  describe "item/1" do
    test "renders a div with default variant and size" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.item>
          <.item_content>
            <.item_title>Title</.item_title>
            <.item_description>Description</.item_description>
          </.item_content>
        </.item>
        """)

      assert html =~ ~s(<div data-slot="item" data-variant="default" data-size="default")

      for class <-
            ~w(group/item flex flex-wrap items-center rounded-md border border-transparent text-sm focus-visible:ring-[3px] [a]:hover:bg-accent/50 bg-transparent gap-4 p-4) do
        assert html =~ class
      end

      assert html =~ ~s(data-slot="item-content")
      assert html =~ ~s(data-slot="item-title")
      assert html =~ ~s(<p data-slot="item-description")
      assert html =~ "line-clamp-2"
    end

    test "variants" do
      assigns = %{}

      outline = rendered_to_string(~H|<.item variant="outline">X</.item>|)
      muted = rendered_to_string(~H|<.item variant="muted">X</.item>|)

      assert outline =~ ~s(data-variant="outline")
      assert outline =~ "border-border"
      refute outline =~ "border-transparent"
      assert muted =~ "bg-muted/50"
    end

    test "sizes" do
      assigns = %{}

      sm = rendered_to_string(~H|<.item size="sm">X</.item>|)
      xs = rendered_to_string(~H|<.item size="xs">X</.item>|)

      assert sm =~ ~s(data-size="sm")
      assert sm =~ "gap-2.5 px-4 py-3"
      refute sm =~ "p-4 "
      assert xs =~ ~s(data-size="xs")
      assert xs =~ "gap-2 px-3 py-2"
    end

    test "renders as a link with href, navigate or patch" do
      assigns = %{}

      href =
        rendered_to_string(~H"""
        <.item variant="outline" href="https://example.com" target="_blank" rel="noopener noreferrer">
          X
        </.item>
        """)

      assert href =~ ~s(<a href="https://example.com")
      assert href =~ ~s(data-slot="item")
      assert href =~ ~s(target="_blank")
      assert href =~ ~s(rel="noopener noreferrer")
      assert href =~ "border-border"

      navigate = rendered_to_string(~H|<.item navigate="/dashboard">X</.item>|)
      assert navigate =~ ~s(href="/dashboard")
      assert navigate =~ ~s(data-phx-link="redirect")

      patch = rendered_to_string(~H|<.item patch="/dashboard">X</.item>|)
      assert patch =~ ~s(data-phx-link="patch")
    end

    test "merges custom classes" do
      assigns = %{}
      html = rendered_to_string(~H|<.item class="w-full p-2">X</.item>|)
      assert html =~ "p-2"
      refute html =~ " p-4"
    end
  end

  describe "item_media/1" do
    test "default, icon and image variants" do
      assigns = %{}

      default = rendered_to_string(~H|<.item_media>M</.item_media>|)
      icon = rendered_to_string(~H|<.item_media variant="icon">M</.item_media>|)
      image = rendered_to_string(~H|<.item_media variant="image">M</.item_media>|)

      assert default =~ ~s(data-slot="item-media" data-variant="default")
      assert default =~ "group-has-[[data-slot=item-description]]/item:self-start"
      assert icon =~ "size-8 rounded-sm border bg-muted"
      assert image =~ "size-10 overflow-hidden rounded-sm"
      assert image =~ "group-data-[size=sm]/item:size-8"
      assert image =~ "[&amp;_img]:object-cover"
    end
  end

  describe "parts" do
    test "group, separator, actions, header and footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.item_group class="gap-4">
          <.item>
            <.item_header>H</.item_header>
            <.item_actions>A</.item_actions>
            <.item_footer>F</.item_footer>
          </.item>
          <.item_separator />
          <.item>B</.item>
        </.item_group>
        """)

      assert html =~ ~s(<div role="list" data-slot="item-group")
      assert html =~ "group/item-group flex flex-col gap-4"
      assert html =~ ~s(role="separator")
      assert html =~ ~s(data-slot="item-separator")
      refute html =~ ~s(data-slot="separator")
      assert html =~ "my-0"
      assert html =~ ~s(data-slot="item-actions")
      assert html =~ ~s(data-slot="item-header")
      assert html =~ ~s(data-slot="item-footer")
      assert count_substring(html, "basis-full") == 2
    end

    test "second item_content shrinks" do
      assigns = %{}
      html = rendered_to_string(~H|<.item_content class="flex-none text-center">D</.item_content>|)
      assert html =~ "[&amp;+[data-slot=item-content]]:flex-none"
      assert html =~ "text-center"
    end
  end
end
