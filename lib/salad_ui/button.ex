defmodule SaladUI.Button do
  @moduledoc """
  Button component for user interactions.

  Provides a versatile button component with various styles, sizes, and states
  to handle user interactions throughout the application.
  """
  use SaladUI, :component

  @doc """
  Renders a button with configurable styles and behaviors.

  ## Attributes

  * `:type` - HTML button type attribute (e.g., "button", "submit")
  * `:class` - Additional CSS classes
  * `:variant` - Visual style variant of the button:
      * `"default"` - Primary action button
      * `"secondary"` - Secondary action button
      * `"destructive"` - Buttons for destructive actions
      * `"outline"` - Button with outline style
      * `"ghost"` - Button with minimal styling
      * `"link"` - Button that appears as a link
  * `:size` - Size of the button:
      * `"default"` - Standard size
      * `"xs"` - Extra small size
      * `"sm"` - Small size
      * `"lg"` - Large size
      * `"icon"` - Square button optimized for icons
      * `"icon-xs"`, `"icon-sm"`, `"icon-lg"` - Smaller and larger square icon buttons
  * `:href`, `:navigate`, `:patch` - When any is set the button renders as a
    link (`<a>` via `Phoenix.Component.link/1`) with the same styles. This is
    the SaladUI equivalent of shadcn's `<Button asChild><a /></Button>`.
  * `:rest` - Additional HTML attributes including `disabled`, `form`, `name`, `value`

  ## Examples

      <.button>Send</.button>
      <.button variant="destructive" phx-click="delete">Delete</.button>
      <.button variant="outline" size="sm">Cancel</.button>
      <.button variant="ghost" size="icon">
        <.icon name="hero-x-mark" />
      </.button>
      <.button type="submit" phx-disable-with="Saving...">Save Changes</.button>
      <.button navigate="/login">Login</.button>
      <.button variant="outline" size="icon" class="rounded-full" aria-label="Scroll up">
        <.icon name="hero-arrow-up" />
      </.button>
  """
  attr :type, :string, default: nil
  attr :class, :any, default: nil

  attr :variant, :string,
    values: ~w(default secondary destructive outline ghost link),
    default: "default",
    doc: "the button variant style"

  attr :size, :string, values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg), default: "default"
  attr :href, :string, default: nil, doc: "renders the button as a link to this URL"
  attr :navigate, :string, default: nil, doc: "renders the button as a LiveView `navigate` link"
  attr :patch, :string, default: nil, doc: "renders the button as a LiveView `patch` link"

  attr :rest, :global, include: ~w(disabled form name value method download hreflang referrerpolicy rel target replace)

  slot :inner_block, required: true

  def button(%{href: href, navigate: navigate, patch: patch} = assigns)
      when not is_nil(href) or not is_nil(navigate) or not is_nil(patch) do
    assigns = assigns |> assign(:variant_class, button_variant(assigns)) |> put_button_attrs()

    ~H"""
    <.link
      href={@href}
      navigate={@navigate}
      patch={@patch}
      data-slot={@own_attrs[:"data-slot"]}
      data-variant={@own_attrs[:"data-variant"]}
      data-size={@own_attrs[:"data-size"]}
      class={classes([@variant_class, @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  def button(assigns) do
    assigns = assigns |> assign(:variant_class, button_variant(assigns)) |> put_button_attrs()

    ~H"""
    <button
      type={@type}
      data-slot={@own_attrs[:"data-slot"]}
      data-variant={@own_attrs[:"data-variant"]}
      data-size={@own_attrs[:"data-size"]}
      class={
        classes([
          "phx-submit-loading:opacity-75",
          @variant_class,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  # A component rendering the button via `as` (e.g. `dropdown_menu_item
  # as={&button/1}`) re-labels these instead of doubling them.
  defp put_button_attrs(assigns) do
    put_own_attrs(assigns, "data-slot": "button", "data-variant": assigns.variant, "data-size": assigns.size)
  end
end
