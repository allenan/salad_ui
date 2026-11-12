defmodule SaladUI.ScrollArea do
  @moduledoc """
  Implementation of a scroll area component with custom styling.

  The scroll area wraps content in a scrollable viewport with thin, theme-colored
  native scrollbars (`--border` thumb on a transparent track), so it needs no
  JavaScript and keeps native scrolling, momentum and keyboard behavior.

  Scrolling is vertical by default. Set `orientation` to `"horizontal"` (the
  equivalent of shadcn's `<ScrollBar orientation="horizontal" />`) or `"both"`.

  ## Examples:

      <.scroll_area class="h-[200px]">
        <div class="p-4">
          <h4 class="mb-4 text-sm font-medium leading-none">Tags</h4>
          <%= for tag <- 1..50 do %>
            <div class="text-sm">
              v1.2.0-beta.<%= tag %>
            </div>
            <.separator class="my-2" />
          <% end %>
        </div>
      </.scroll_area>

      <.scroll_area orientation="horizontal" class="w-96 rounded-md border whitespace-nowrap">
        <div class="flex w-max space-x-4 p-4">
          <figure :for={work <- @works} class="shrink-0">...</figure>
        </div>
      </.scroll_area>
  """
  use SaladUI, :component

  @doc """
  Renders a custom scrollable area.

  ## Options

  * `:orientation` - Which axis scrolls: `"vertical"` (default), `"horizontal"`
    or `"both"`. The other axis is clipped.
  * `:class` - Additional CSS classes to apply to the scroll area container
  """
  attr :class, :string, default: nil

  attr :orientation, :string,
    values: ~w(vertical horizontal both),
    default: "vertical",
    doc: "the axis (or axes) that scroll"

  attr :rest, :global
  slot :inner_block

  def scroll_area(assigns) do
    ~H"""
    <div
      data-slot="scroll-area"
      data-orientation={@orientation}
      class={classes(["relative", @class])}
      {@rest}
    >
      <div
        data-slot="scroll-area-viewport"
        class={[
          "size-full rounded-[inherit] transition-[color,box-shadow] outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1",
          "[scrollbar-color:var(--border)_transparent] [scrollbar-width:thin]",
          overflow_class(@orientation)
        ]}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp overflow_class("vertical"), do: "overflow-x-hidden overflow-y-auto"
  defp overflow_class("horizontal"), do: "overflow-x-auto overflow-y-hidden"
  defp overflow_class("both"), do: "overflow-auto"
end
