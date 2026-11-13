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
  attr :class, :string, default: nil
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
  attr :class, :string, default: nil
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
  attr :class, :string, default: nil
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

  * `:is-active` - Whether this link represents the current page
  * `:size` - Link size variant (default, sm, lg, icon)
  """
  attr :"is-active", :boolean, default: false
  attr :size, :string, default: "icon", values: ~w(default sm lg icon)
  attr :class, :string, default: nil
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
      data-slot="pagination-link"
      aria-current={(assigns[:"is-active"] && "page") || ""}
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
  attr :class, :string, default: nil
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
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="2"
        stroke="currentColor"
        class="size-6 w-3.5 rtl:rotate-180"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
      </svg>
    </.pagination_link>
    """
  end

  @doc """
  Renders a previous page button. Like shadcn, the label is hidden below the
  `sm` breakpoint, leaving only the chevron (the `aria-label` still names
  it). Pass `text` to translate the label (e.g. for an RTL page); the
  chevron flips under `dir="rtl"`.
  """
  attr :class, :string, default: nil
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
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="2"
        stroke="currentColor"
        class="size-6 w-3.5 rtl:rotate-180"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
      </svg>
      <span class="hidden sm:block">{@text}</span>
    </.pagination_link>
    """
  end

  @doc """
  Renders an ellipsis for page ranges.
  """
  attr :class, :string, default: nil
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
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke-width="2"
        stroke="currentColor"
        class="size-4"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M6.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM12.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0ZM18.75 12a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0Z"
        />
      </svg>

      <span class="sr-only">More pages</span>
    </span>
    """
  end
end
