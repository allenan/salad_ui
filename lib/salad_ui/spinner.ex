defmodule SaladUI.Spinner do
  @moduledoc """
  An indicator that shows a loading state. Renders an animated
  `loader-circle` icon with `role="status"` and `aria-label="Loading"`.

  Size it with `size-*` utilities and color it with `text-*` utilities. To use
  a different icon, pass it as the inner block: the icon is wrapped in a
  spinning, accessible container.

  ## Examples

      <.spinner />
      <.spinner class="size-8 text-blue-500" />
      <.spinner aria-label="Saving" />

      <.button disabled size="sm">
        <.spinner /> Loading...
      </.button>

      <.badge variant="secondary">
        <.spinner /> Updating
      </.badge>

      <%!-- Custom icon --%>
      <.spinner>
        <.icon name="hero-arrow-path" />
      </.spinner>
  """
  use SaladUI, :component

  @doc """
  Renders a spinner.

  ## Attributes

  * `:class` - Additional CSS classes (e.g. `size-6`, `text-red-500`).
  * `:rest` - Other HTML attributes. `aria-label` overrides the default `"Loading"`.
  * `inner_block` - Optional custom icon to spin in place of the default.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, doc: "a custom icon to spin instead of the default loader"

  def spinner(%{inner_block: [_ | _]} = assigns) do
    assigns = put_default_label(assigns)

    ~H"""
    <span
      data-slot="spinner"
      role="status"
      class={
        classes([
          "inline-flex size-4 shrink-0 animate-spin items-center justify-center [&>svg]:size-full",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  def spinner(assigns) do
    assigns = put_default_label(assigns)

    ~H"""
    <svg
      data-slot="spinner"
      role="status"
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class={classes(["size-4 animate-spin", @class])}
      {@rest}
    ><path d="M21 12a9 9 0 1 1-6.219-8.56" /></svg>
    """
  end

  defp put_default_label(assigns) do
    assign(assigns, :rest, Map.put_new(assigns.rest, :"aria-label", "Loading"))
  end
end
