defmodule SaladUI.CarouselTest do
  use ComponentCase

  import SaladUI.Carousel

  alias Phoenix.LiveView.JS

  defp render_demo(assigns) do
    rendered_to_string(~H"""
    <.carousel id="demo" class="w-full max-w-xs" {@opts}>
      <.carousel_content class={@content_class}>
        <.carousel_item :for={i <- 1..3} class={@item_class}>Slide {i}</.carousel_item>
      </.carousel_content>
      <.carousel_previous />
      <.carousel_next />
    </.carousel>
    """)
  end

  defp demo(opts \\ %{}, content_class \\ nil, item_class \\ nil) do
    render_demo(%{opts: opts, content_class: content_class, item_class: item_class})
  end

  describe "carousel/1" do
    test "renders the root with hook, region role and shadcn slot" do
      html = demo()

      assert html =~ ~s(id="demo")
      assert html =~ ~s(data-slot="carousel")
      assert html =~ ~s(data-component="carousel")
      assert html =~ ~s(data-part="root")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-roledescription="carousel")
      assert html =~ ~s(data-orientation="horizontal")
      assert html =~ ~s(data-align="start")
      assert html =~ ~s(class="relative w-full max-w-xs")
    end

    test "encodes orientation, align, loop and autoplay into data-options" do
      html = demo(%{orientation: "vertical", align: "center", loop: true, autoplay: 2000})

      assert html =~ ~s(data-orientation="vertical")
      assert html =~ ~s(data-align="center")
      assert html =~ ~s(&quot;orientation&quot;:&quot;vertical&quot;)
      assert html =~ ~s(&quot;align&quot;:&quot;center&quot;)
      assert html =~ ~s(&quot;loop&quot;:true)
      assert html =~ ~s(&quot;autoplay&quot;:2000)
    end

    test "maps on-select into data-event-mappings" do
      html = demo(%{"on-select": "carousel_selected"})
      assert html =~ ~s(&quot;select&quot;:&quot;carousel_selected&quot;)

      html = demo(%{"on-select": JS.push("picked")})
      assert html =~ ~s(&quot;select&quot;:[[&quot;push&quot;)
    end
  end

  describe "carousel_content/1" do
    test "renders a snapping viewport around the track" do
      html = demo()

      assert html =~ ~s(data-slot="carousel-content")
      assert html =~ ~s(data-part="viewport")
      assert html =~ ~s(data-part="content")
      assert html =~ "[:where([data-slot=carousel][data-orientation=horizontal]&gt;&amp;)]:snap-x"
      assert html =~ "[:where([data-slot=carousel][data-orientation=vertical]&gt;&amp;)]:overflow-y-auto"
    end

    test "class goes on the inner track alongside the default gutter" do
      html = demo(%{}, "-ms-1 h-[200px]")

      assert html =~ ~r/data-part="content" class="flex [^"]*:-ms-4 [^"]*-ms-1 h-\[200px\]"/
    end
  end

  describe "carousel_item/1" do
    test "renders a slide group with shadcn's basis and gutter" do
      html = demo(%{}, nil, "md:basis-1/2 lg:basis-1/3")

      assert count_substring(html, ~s(data-slot="carousel-item")) == 3
      assert html =~ ~s(role="group")
      assert html =~ ~s(aria-roledescription="slide")
      assert html =~ "min-w-0 shrink-0 grow-0 basis-full"
      assert html =~ ":ps-4"
      assert html =~ ":pt-4"
      assert html =~ ":snap-start"
      assert html =~ "md:basis-1/2 lg:basis-1/3"
    end
  end

  describe "carousel_previous/1 and carousel_next/1" do
    test "render disabled outline icon buttons with sr-only labels" do
      html = demo()

      assert html =~ ~s(data-slot="carousel-previous")
      assert html =~ ~s(data-slot="carousel-next")
      assert html =~ ~s(data-part="previous")
      assert html =~ ~s(data-part="next")
      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(data-size="icon")
      assert count_substring(html, ~s(type="button")) == 2
      assert count_substring(html, ~s( disabled>)) == 2
      assert html =~ ~s(<span class="sr-only">Previous slide</span>)
      assert html =~ ~s(<span class="sr-only">Next slide</span>)
      assert html =~ "absolute size-8 rounded-full"
      refute html =~ "size-9"
      assert html =~ ":-start-12"
      assert html =~ ":-end-12"
      assert html =~ ":rotate-90"
    end

    test "accept variant, size, class and custom content" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.carousel_previous variant="ghost" class="rtl:rotate-180">Back</.carousel_previous>
        """)

      assert html =~ ~s(data-variant="ghost")
      assert html =~ "rtl:rotate-180"
      assert html =~ "Back"
      refute html =~ "Previous slide"
    end
  end
end
