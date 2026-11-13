defmodule SaladUI.Icon do
  @moduledoc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes. Icons never shrink in a flex
  row (`shrink-0`), like the `[&_svg]:shrink-0` shadcn puts on `<svg>` icons.

  Icons are extracted from your `assets/vendor/heroicons` directory and bundled
  within your compiled app.css by the icon plugin in your Tailwind config.

  Other attributes (`aria-hidden`, `aria-label`, `role`, `data-*`, ...) are
  rendered on the `<span>`.

  ## Examples
      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ms-1 size-3 animate-spin" />
      <.icon name="hero-star" aria-hidden="true" />
  """

  use SaladUI, :component

  attr :name, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={classes(["shrink-0", @name, @class])} {@rest}></span>
    """
  end
end
