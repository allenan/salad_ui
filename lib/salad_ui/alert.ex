defmodule SaladUI.Alert do
  @moduledoc """
  Implementation of alert component for displaying important messages to users.

  Alerts are used to communicate status, warnings, or contextual feedback to users.
  They can be configured with different variants to indicate severity and typically
  consist of a title and a description.

  ## Examples:

      <.alert>
        <.alert_title>Note</.alert_title>
        <.alert_description>This is a standard informational alert.</.alert_description>
      </.alert>

      <.alert variant="destructive">
        <.alert_title>Error</.alert_title>
        <.alert_description>
          There was a problem with your request. Please try again.
        </.alert_description>
      </.alert>

      <.alert>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" d="M9 12l2 2l4-4"></path>
        </svg>
        <.alert_title>Success</.alert_title>
        <.alert_description>Your changes have been saved successfully.</.alert_description>
      </.alert>

  ## Icons

  An icon is placed as a direct child, before the title (as in shadcn/ui). The
  alert is a two-column grid: when its first child is an `<svg>` (or a
  `<span>`, such as a heroicon `<.icon name="hero-..." />` or the older
  `<span><svg/></span>` wrapper) the icon takes a `size-4` first column and the
  title and description sit in the second. Without an icon the first column
  collapses to zero width.
  """
  use SaladUI, :component

  @doc """
  Renders an alert container.

  The alert component displays important messages or feedback to users with styling
  appropriate for the context.

  ## Options

  * `:variant` - The visual style of the alert. Available variants:
    * `"default"` - Standard alert styling (default)
    * `"destructive"` - Red-tinted styling for errors and warnings
  * `:class` - Additional CSS classes to apply to the alert container.

  ## Examples

      <.alert>
        <.alert_title>Information</.alert_title>
        <.alert_description>This is an informational message.</.alert_description>
      </.alert>

      <.alert variant="destructive" class="mt-4">
        <.alert_title>Warning</.alert_title>
        <.alert_description>This action cannot be undone.</.alert_description>
      </.alert>
  """
  attr :variant, :string, default: "default", values: ~w(default destructive)
  attr :class, :any, default: nil
  slot :inner_block, required: true
  attr :rest, :global, default: %{}

  def alert(assigns) do
    assigns = assign(assigns, :variant_class, variant(assigns))

    ~H"""
    <div
      data-slot="alert"
      role="alert"
      data-part="root"
      class={
        classes([
          "relative grid w-full grid-cols-[0_1fr] items-start gap-y-0.5 rounded-lg border px-4 py-3 text-sm has-[>svg]:grid-cols-[calc(var(--spacing)*4)_1fr] has-[>svg]:gap-x-3 [&>svg]:size-4 [&>svg]:translate-y-0.5 [&>svg]:text-current",
          # A `<span>` icon (heroicon `<.icon>`, or the pre-grid `<span><svg/></span>`
          # wrapper) gets the same first column as a bare `<svg>`.
          "has-[>span]:grid-cols-[calc(var(--spacing)*4)_1fr] has-[>span]:gap-x-3 [&>span]:size-4 [&>span]:translate-y-0.5 [&>span]:text-current [&>span>svg]:size-4",
          @variant_class,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders an alert title.

  The title component is used to provide a concise heading for the alert message.

  ## Options

  * `:class` - Additional CSS classes to apply to the title.

  ## Examples

      <.alert_title>Success</.alert_title>
      <.alert_title class="text-primary">Important Notice</.alert_title>
  """
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def alert_title(assigns) do
    ~H"""
    <div
      data-slot="alert-title"
      class={
        classes([
          "col-start-2 line-clamp-1 min-h-4 font-medium tracking-tight",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders an alert description.

  The description provides more detailed information about the alert message.

  ## Options

  * `:class` - Additional CSS classes to apply to the description.

  ## Examples

      <.alert_description>Your account has been updated successfully.</.alert_description>
      <.alert_description class="text-gray-600">
        Please review the changes before continuing.
      </.alert_description>
  """
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def alert_description(assigns) do
    ~H"""
    <div
      data-slot="alert-description"
      class={
        classes([
          "col-start-2 grid justify-items-start gap-1 text-sm text-muted-foreground [&_p]:leading-relaxed",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @variants %{
    variant: %{
      "default" => "bg-card text-card-foreground",
      "destructive" => "bg-card text-destructive *:data-[slot=alert-description]:text-destructive/90 [&>svg]:text-current"
    }
  }

  @default_variants %{
    variant: "default"
  }

  defp variant(variants) do
    variants = Map.merge(@default_variants, variants)

    Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)
  end
end
