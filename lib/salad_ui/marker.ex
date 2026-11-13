defmodule SaladUI.Marker do
  @moduledoc """
  A marker is a quiet one-line note in a conversation: a status ("Thinking…"),
  an event ("Switched to a new branch") or a divider ("Today").

  Parts: `marker/1`, `marker_icon/1`, `marker_content/1`.

  ## Variants

  * `default` - an inline note.
  * `separator` - centered between two rules, for dividers between turns.
  * `border` - a bottom border, for stacked rows.

  ## Live status

  Give a marker that reports ongoing work `role="status"` so it is announced,
  and add the `shimmer` utility (shipped in `salad_ui.css`) to its content:

      <.marker role="status">
        <.marker_icon><.spinner /></.marker_icon>
        <.marker_content class="shimmer">Thinking...</.marker_content>
      </.marker>

  ## Links and buttons

  shadcn's `<Marker asChild><a /></Marker>` is `as="a"` (with an `href`) or
  `as="button"`:

      <.marker as="a" href="#pull-request">
        <.marker_content>View the pull request</.marker_content>
      </.marker>

  ## Examples:

      <.marker>
        <.marker_icon><.icon name="hero-magnifying-glass" /></.marker_icon>
        <.marker_content>Explored 4 files</.marker_content>
      </.marker>

      <.marker variant="separator">
        <.marker_content>Conversation compacted</.marker_content>
      </.marker>
  """
  use SaladUI, :component

  @variants %{
    "default" => "",
    "separator" =>
      "before:me-1 before:h-px before:min-w-0 before:flex-1 before:bg-border after:ms-1 after:h-px after:min-w-0 after:flex-1 after:bg-border",
    "border" => "border-b border-border pb-2"
  }

  @doc """
  Renders a marker row.

  ## Options

  * `:variant` - `"default"`, `"separator"` or `"border"`.
  * `:as` - The tag to render: `"div"` (default), `"a"` or `"button"`. A
    button defaults to `type="button"`.
  * `:class` - Additional CSS classes.
  """
  attr :variant, :string, values: ~w(default separator border), default: "default", doc: "the marker style"
  attr :as, :string, values: ~w(div a button), default: "div", doc: "the element to render"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href target rel type disabled download)
  slot :inner_block, required: true

  def marker(assigns) do
    assigns =
      assigns
      |> assign(:variant_class, @variants[assigns.variant])
      |> then(fn a ->
        if a.as == "button" and is_nil(a.rest[:type]),
          do: assign(a, :rest, Map.put(a.rest, :type, "button")),
          else: a
      end)

    ~H"""
    <.dynamic_tag
      tag_name={@as}
      data-slot="marker"
      data-variant={@variant}
      class={
        classes([
          "group/marker relative flex min-h-4 w-full items-center gap-2 text-start text-sm text-muted-foreground [&_svg:not([class*='size-'])]:size-4 [a]:underline [a]:underline-offset-3 [a]:hover:text-foreground",
          @variant_class,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </.dynamic_tag>
    """
  end

  @doc """
  A decorative icon slot (hidden from assistive tech).
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def marker_icon(assigns) do
    ~H"""
    <span
      data-slot="marker-icon"
      aria-hidden="true"
      class={classes(["size-4 shrink-0 [&_svg:not([class*='size-'])]:size-4", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  The marker text. In the `separator` variant it is centered between the rules.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def marker_content(assigns) do
    ~H"""
    <span
      data-slot="marker-content"
      class={
        classes([
          "min-w-0 wrap-break-word group-data-[variant=separator]/marker:flex-none group-data-[variant=separator]/marker:text-center *:[a]:underline *:[a]:underline-offset-3 *:[a]:hover:text-foreground",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end
end
