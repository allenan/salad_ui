defmodule SaladUI.MessageScrollerTest do
  use ComponentCase

  import SaladUI.MessageScroller

  alias Phoenix.LiveView.JS

  defp render_scroller(assigns) do
    rendered_to_string(~H"""
    <.message_scroller id="chat" class="flex-1" {@opts}>
      <.message_scroller_viewport {@viewport}>
        <.message_scroller_content id="chat-messages" phx-update="stream" aria-busy={@busy}>
          <.message_scroller_item
            :for={m <- @messages}
            id={"row-#{m.id}"}
            message_id={m.id}
            scroll_anchor={m.anchor}
          >
            {m.text}
          </.message_scroller_item>
        </.message_scroller_content>
      </.message_scroller_viewport>
      <.message_scroller_button />
      <.message_scroller_button direction="start" variant="outline" size="icon" behavior="auto" />
    </.message_scroller>
    """)
  end

  defp scroller(opts \\ %{}, viewport \\ %{}) do
    render_scroller(%{
      opts: opts,
      viewport: viewport,
      busy: false,
      messages: [
        %{id: "m1", anchor: true, text: "Question"},
        %{id: "m2", anchor: false, text: "Answer"}
      ]
    })
  end

  describe "message_scroller/1" do
    test "renders the frame with the hook, shadcn slot and classes" do
      html = scroller()

      assert html =~ ~s(id="chat")
      assert html =~ ~s(data-slot="message-scroller")
      assert html =~ ~s(data-component="message-scroller")
      assert html =~ ~s(data-part="root")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ "group/message-scroller relative flex size-full min-h-0 flex-col overflow-hidden flex-1"
    end

    test "encodes the provider options with shadcn defaults" do
      html = scroller()

      assert html =~ ~s(&quot;autoScroll&quot;:false)
      assert html =~ ~s(&quot;defaultScrollPosition&quot;:&quot;end&quot;)
      assert html =~ ~s(&quot;scrollEdgeThreshold&quot;:8)
      assert html =~ ~s(&quot;scrollMargin&quot;:0)
      assert html =~ ~s(&quot;scrollPreviousItemPeek&quot;:64)

      html =
        scroller(%{
          auto_scroll: true,
          default_scroll_position: "last-anchor",
          scroll_edge_threshold: 4,
          scroll_margin: 12,
          scroll_previous_item_peek: 32
        })

      assert html =~ ~s(&quot;autoScroll&quot;:true)
      assert html =~ ~s(&quot;defaultScrollPosition&quot;:&quot;last-anchor&quot;)
      assert html =~ ~s(&quot;scrollEdgeThreshold&quot;:4)
      assert html =~ ~s(&quot;scrollMargin&quot;:12)
      assert html =~ ~s(&quot;scrollPreviousItemPeek&quot;:32)
    end

    test "holds the viewport with data-pending-scroll unless opening at the start" do
      assert scroller() =~ ~r/data-slot="message-scroller"[^>]*data-pending-scroll/
      assert scroller(%{default_scroll_position: "last-anchor"}) =~ "data-pending-scroll"
      refute scroller(%{default_scroll_position: "start"}) =~ ~r/\sdata-pending-scroll[\s>]/
    end

    test "maps scrollable and visibility events" do
      html = scroller(%{"on-scrollable-change": "scrollable", "on-visibility-change": JS.push("seen")})

      assert html =~ ~s(&quot;scrollable-change&quot;:&quot;scrollable&quot;)
      assert html =~ ~s(&quot;visibility-change&quot;:[[&quot;push&quot;)
    end
  end

  describe "message_scroller_viewport/1" do
    test "is a labelled, focusable region with the shadcn classes and a tail spacer" do
      html = scroller()

      assert html =~ ~s(data-slot="message-scroller-viewport")
      assert html =~ ~s(data-part="viewport")
      assert html =~ ~s(role="region")
      assert html =~ ~s(aria-label="Messages")
      assert html =~ ~s(tabindex="0")
      assert html =~ ~s(data-preserve-scroll-on-prepend="true")

      assert html =~
               "size-full min-h-0 min-w-0 scroll-fade-b scrollbar-thin scrollbar-gutter-stable overflow-y-auto overscroll-contain contain-content data-autoscrolling:scrollbar-none data-pending-scroll:invisible group-data-pending-scroll/message-scroller:invisible"

      assert html =~ ~r/<div data-part="spacer" data-message-scroller-spacer aria-hidden="true" hidden><\/div>/
    end

    test "accepts preserve_scroll_on_prepend and a custom label" do
      html = scroller(%{}, %{preserve_scroll_on_prepend: false, "aria-label": "Thread"})

      assert html =~ ~s(data-preserve-scroll-on-prepend="false")
      assert html =~ ~s(aria-label="Thread")
    end
  end

  describe "message_scroller_content/1" do
    test "is a log live region that passes stream attributes through" do
      html = scroller()

      assert html =~ ~s(data-slot="message-scroller-content")
      assert html =~ ~s(data-part="content")
      assert html =~ ~s(role="log")
      assert html =~ ~s(aria-relevant="additions")
      assert html =~ ~s(id="chat-messages")
      assert html =~ ~s(phx-update="stream")
      assert html =~ ~s(aria-busy="false")
      assert html =~ "flex h-max min-h-full flex-col gap-8"
    end
  end

  describe "message_scroller_item/1" do
    test "mirrors message_id and scroll_anchor" do
      html = scroller()

      assert html =~ ~s(data-slot="message-scroller-item")
      assert html =~ ~s(id="row-m1")
      assert html =~ ~s(data-message-id="m1")
      assert html =~ ~s(data-scroll-anchor="true")
      assert html =~ ~s(data-message-id="m2")
      assert html =~ ~s(data-scroll-anchor="false")
      assert html =~ "min-w-0 shrink-0 [contain-intrinsic-size:auto_10rem] [content-visibility:auto]"
    end

    test "omits data-message-id without a message_id" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.message_scroller_item>Typing</.message_scroller_item>
        """)

      refute html =~ "data-message-id"
      assert html =~ ~s(data-scroll-anchor="false")
    end
  end

  describe "message_scroller_button/1" do
    test "renders an inert end button with an icon and sr-only label" do
      html = scroller()

      assert html =~ ~s(data-slot="message-scroller-button")
      assert html =~ ~s(data-part="scroll-button")
      assert html =~ ~s(data-direction="end")
      assert html =~ ~s(data-behavior="smooth")
      assert html =~ ~s(data-variant="secondary")
      assert html =~ ~s(data-size="icon-sm")
      assert html =~ ~s(data-active="false")
      assert html =~ ~r/data-slot="message-scroller-button"[^>]*inert/
      assert html =~ ~s(tabindex="-1")
      assert html =~ ~s(<span class="sr-only">Scroll to end</span>)
      assert html =~ "data-[direction=end]:bottom-4"
      assert html =~ "data-[active=false]:opacity-0"
    end

    test "supports the start direction and button variants" do
      html = scroller()

      assert html =~ ~s(data-direction="start")
      assert html =~ ~s(data-behavior="auto")
      assert html =~ ~s(data-variant="outline")
      assert html =~ ~s(<span class="sr-only">Scroll to start</span>)
    end

    test "custom content replaces the icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.message_scroller_button class="rounded-full">Jump to latest</.message_scroller_button>
        """)

      assert html =~ "Jump to latest"
      refute html =~ "<svg"
      assert html =~ "rounded-full"
    end
  end
end
