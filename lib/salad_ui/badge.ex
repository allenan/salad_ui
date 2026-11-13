defmodule SaladUI.Badge do
  @moduledoc """
  Implementation of badge component for displaying short labels, statuses, or counts.

  Badges are small UI elements typically used to highlight status, categories, or counts
  in a compact format. They are designed to be visually distinct and draw attention to
  important information.

  ## Examples:

      <.badge>New</.badge>
      <.badge variant="secondary">Beta</.badge>
      <.badge variant="destructive">Error</.badge>
      <.badge variant="outline">Version 1.0</.badge>

      <.badge href="#link">Open Link</.badge>

      <div class="flex gap-2">
        <.badge>Default</.badge>
        <.badge variant="secondary">Secondary</.badge>
        <.badge variant="destructive">Destructive</.badge>
        <.badge variant="outline">Outline</.badge>
      </div>
  """
  use SaladUI, :component

  @base_class "inline-flex w-fit shrink-0 items-center justify-center gap-1 overflow-hidden rounded-full border border-transparent px-2 py-0.5 text-xs font-medium whitespace-nowrap transition-[color,box-shadow] focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 [&>svg]:pointer-events-none [&>svg]:size-3"

  @doc """
  Renders a badge component.

  ## Options

  * `:class` - Additional CSS classes to apply to the badge.
  * `:variant` - The visual style of the badge. Available variants:
    * `"default"` - Primary color with white text (default)
    * `"secondary"` - Secondary color with contrasting text
    * `"destructive"` - Typically red, for warning or error states
    * `"outline"` - Bordered style with no background
    * `"ghost"` - No background or border
    * `"link"` - Styled like a link
  * `:href`, `:navigate`, `:patch` - When any is set the badge renders as a
    link (`<a>` via `Phoenix.Component.link/1`), which also enables the
    variant's hover styles. This is the SaladUI equivalent of shadcn's
    `<Badge asChild><a /></Badge>`.

  ## Examples

      <.badge>Badge</.badge>
      <.badge variant="destructive">Warning</.badge>
      <.badge variant="outline" class="text-sm">Custom</.badge>
      <.badge variant="ghost">Ghost</.badge>
      <.badge variant="link" navigate="/changelog">Changelog</.badge>
  """
  attr :class, :string, default: nil

  attr :variant, :string,
    values: ~w(default secondary destructive outline ghost link),
    default: "default",
    doc: "the badge variant style"

  attr :href, :string, default: nil, doc: "renders the badge as a link to this URL"
  attr :navigate, :string, default: nil, doc: "renders the badge as a LiveView `navigate` link"
  attr :patch, :string, default: nil, doc: "renders the badge as a LiveView `patch` link"

  attr :rest, :global, include: ~w(method download hreflang referrerpolicy rel target replace)
  slot :inner_block, required: true

  def badge(%{href: href, navigate: navigate, patch: patch} = assigns)
      when not is_nil(href) or not is_nil(navigate) or not is_nil(patch) do
    assigns = assign(assigns, base_class: @base_class, variant_class: variant(assigns))

    ~H"""
    <.link
      href={@href}
      navigate={@navigate}
      patch={@patch}
      data-slot="badge"
      data-variant={@variant}
      class={classes([@base_class, @variant_class, @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  def badge(assigns) do
    assigns = assign(assigns, base_class: @base_class, variant_class: variant(assigns))

    ~H"""
    <span
      data-slot="badge"
      data-variant={@variant}
      class={classes([@base_class, @variant_class, @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @variants %{
    variant: %{
      "default" => "bg-primary text-primary-foreground [a&]:hover:bg-primary/90",
      "secondary" => "bg-secondary text-secondary-foreground [a&]:hover:bg-secondary/90",
      "destructive" =>
        "bg-destructive text-white focus-visible:ring-destructive/20 dark:bg-destructive/60 dark:focus-visible:ring-destructive/40 [a&]:hover:bg-destructive/90",
      "outline" => "border-border text-foreground [a&]:hover:bg-accent [a&]:hover:text-accent-foreground",
      "ghost" => "[a&]:hover:bg-accent [a&]:hover:text-accent-foreground",
      "link" => "text-primary underline-offset-4 [a&]:hover:underline"
    }
  }

  @default_variants %{
    variant: "default"
  }

  defp variant(props) do
    variants = Map.merge(@default_variants, Map.take(props, Map.keys(@default_variants)))

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end
end
