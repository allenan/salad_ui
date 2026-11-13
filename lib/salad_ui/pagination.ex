defmodule SaladUI.Pagination do
  @moduledoc """
  Implementation of pagination component for navigation between pages of content.

  ## Examples:

      <.pagination>
        <.pagination_content>
          <.pagination_item>
            <.pagination_previous href="#" />
          </.pagination_item>
          <.pagination_item>
            <.pagination_link href="#" is-active={@page == 1}>1</.pagination_link>
          </.pagination_item>
          <.pagination_item>
            <.pagination_link href="#" is-active={@page == 2}>2</.pagination_link>
          </.pagination_item>
          <.pagination_item>
            <.pagination_link href="#" is-active={@page == 3}>3</.pagination_link>
          </.pagination_item>
          <.pagination_item>
            <.pagination_ellipsis />
          </.pagination_item>
          <.pagination_item>
            <.pagination_next href="#" />
          </.pagination_item>
        </.pagination_content>
      </.pagination>

  ## Icons only

  Below the `sm` breakpoint `pagination_previous/1` and `pagination_next/1`
  show only their chevrons. For a data table footer, use them on their own:

      <.pagination class="mx-0 w-auto">
        <.pagination_content>
          <.pagination_item>
            <.pagination_previous href="#" />
          </.pagination_item>
          <.pagination_item>
            <.pagination_next href="#" />
          </.pagination_item>
        </.pagination_content>
      </.pagination>
  """
  use SaladUI, :component

  @doc """
  Renders a pagination component.
  """
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch)
  slot :inner_block, required: true

  def pagination(assigns) do
    ~H"""
    <nav
      data-slot="pagination"
      aria-label="pagination"
      role="navigation"
      class={
        classes([
          "mx-auto flex w-full justify-center",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </nav>
    """
  end

  @doc """
  Renders pagination content wrapper.
  """
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch)
  slot :inner_block, required: true

  def pagination_content(assigns) do
    ~H"""
    <ul
      data-slot="pagination-content"
      class={
        classes([
          "flex flex-row items-center gap-1",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </ul>
    """
  end

  @doc """
  Renders a pagination item container.
  """
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch)
  slot :inner_block, required: true

  def pagination_item(assigns) do
    ~H"""
    <li
      data-slot="pagination-item"
      class={
        classes([
          "",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </li>
    """
  end

  @doc """
  Renders a pagination link.

  ## Options

  * `:is-active` - Whether this link represents the current page. Only the
    active link gets `aria-current="page"` (and `data-active`).
  * `:size` - Link size variant (default, sm, lg, icon)
  """
  attr :"is-active", :boolean, default: false
  attr :size, :string, default: "icon", values: ~w(default sm lg icon)
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch)
  slot :inner_block, required: true

  def pagination_link(assigns) do
    is_active = assigns[:"is-active"] in [true, "true"]

    assigns =
      assigns
      |> assign(
        :variation_class,
        button_variant(%{size: assigns[:size], variant: (is_active && "outline") || "ghost"})
      )
      |> assign(:"is-active", is_active)

    ~H"""
    <.link
      aria-current={assigns[:"is-active"] && "page"}
      data-slot="pagination-link"
      data-active={assigns[:"is-active"] && "true"}
      class={classes([@variation_class, @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders a next page button. Like shadcn, the label is hidden below the `sm`
  breakpoint, leaving only the chevron (the `aria-label` still names it).
  Pass `text` to translate the label (e.g. for an RTL page); the chevron
  flips under `dir="rtl"`.
  """
  attr :class, :any, default: nil
  attr :text, :string, default: "Next", doc: "Visible label"
  attr :rest, :global, include: ~w(href navigate patch)

  def pagination_next(assigns) do
    ~H"""
    <.pagination_link
      aria-label="Go to next page"
      size="default"
      class={classes(["gap-1 px-2.5 sm:pe-2.5", @class])}
      {@rest}
    >
      <span class="hidden sm:block">{@text}</span>
      <.lucide_icon class="rtl:rotate-180">
        <path d="m9 18 6-6-6-6" />
      </.lucide_icon>
    </.pagination_link>
    """
  end

  @doc """
  Renders a previous page button. Like shadcn, the label is hidden below the
  `sm` breakpoint, leaving only the chevron (the `aria-label` still names
  it). Pass `text` to translate the label (e.g. for an RTL page); the
  chevron flips under `dir="rtl"`.
  """
  attr :class, :any, default: nil
  attr :text, :string, default: "Previous", doc: "Visible label"
  attr :rest, :global, include: ~w(href navigate patch)

  def pagination_previous(assigns) do
    ~H"""
    <.pagination_link
      aria-label="Go to previous page"
      size="default"
      class={classes(["gap-1 px-2.5 sm:ps-2.5", @class])}
      {@rest}
    >
      <.lucide_icon class="rtl:rotate-180">
        <path d="m15 18-6-6 6-6" />
      </.lucide_icon>
      <span class="hidden sm:block">{@text}</span>
    </.pagination_link>
    """
  end

  @doc """
  Renders an ellipsis for page ranges. The icon is hidden from assistive
  technology; screen readers announce the `text` ("More pages") instead.
  """
  attr :class, :any, default: nil
  attr :text, :string, default: "More pages", doc: "Screen-reader label"
  attr :rest, :global, include: ~w(href navigate patch)

  def pagination_ellipsis(assigns) do
    ~H"""
    <span
      data-slot="pagination-ellipsis"
      class={
        classes([
          "flex size-9 items-center justify-center",
          @class
        ])
      }
      {@rest}
    >
      <.lucide_icon class="size-4">
        <circle cx="12" cy="12" r="1" />
        <circle cx="19" cy="12" r="1" />
        <circle cx="5" cy="12" r="1" />
      </.lucide_icon>
      <span class="sr-only">{@text}</span>
    </span>
    """
  end

  # lucide-react's <svg> wrapper (ChevronLeftIcon, ChevronRightIcon,
  # MoreHorizontalIcon); decorative, so hidden from assistive technology.
  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp lucide_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
      class={@class}
    >
      {render_slot(@inner_block)}
    </svg>
    """
  end
end
