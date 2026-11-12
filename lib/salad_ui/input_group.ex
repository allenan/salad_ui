defmodule SaladUI.InputGroup do
  @moduledoc """
  Add addons, buttons, and helper content to inputs.

  An input group wraps an `input_group_input/1` or `input_group_textarea/1` with
  one or more `input_group_addon/1`s holding icons, text (`input_group_text/1`),
  buttons (`input_group_button/1`) or other content. The group draws the border,
  focus ring and invalid state; the control inside is borderless.

  Clicking an addon (anywhere except a button or other interactive element in
  it) focuses the group's control, which needs the `assets/salad_ui/components/input_group.js`
  component and therefore an `id` on the group.

  ## Composition

      input_group
      ├── input_group_input or input_group_textarea
      ├── input_group_addon
      │   ├── input_group_button
      │   └── input_group_text

  Place addons **after** the control in the DOM so keyboard focus reaches the
  control first, and use `:align` to position them visually. Use `inline-start`
  / `inline-end` with an input and `block-start` / `block-end` with a textarea
  (or with an input inside a taller group).

  Any custom control gets the group's focus and invalid styling, and receives
  focus from addon clicks, when it carries `data-slot="input-group-control"`.

  ## Examples

      <.input_group id="search">
        <.input_group_input placeholder="Search..." />
        <.input_group_addon>
          <.icon name="hero-magnifying-glass" class="size-4" />
        </.input_group_addon>
        <.input_group_addon align="inline-end">12 results</.input_group_addon>
      </.input_group>

      <.input_group id="website">
        <.input_group_input placeholder="example.com" class="pl-0.5!" />
        <.input_group_addon>
          <.input_group_text>https://</.input_group_text>
        </.input_group_addon>
        <.input_group_addon align="inline-end">
          <.input_group_text>.com</.input_group_text>
        </.input_group_addon>
      </.input_group>

      <.input_group id="share-url">
        <.input_group_input value="https://x.com/shadcn" readonly />
        <.input_group_addon align="inline-end">
          <.input_group_button size="icon-xs" aria-label="Copy" phx-click="copy">
            <.icon name="hero-clipboard" class="size-4" />
          </.input_group_button>
        </.input_group_addon>
      </.input_group>

      <.input_group id="prompt">
        <.input_group_textarea field={@form[:prompt]} placeholder="Ask, Search or Chat..." />
        <.input_group_addon align="block-end">
          <.input_group_text class="ml-auto">52% used</.input_group_text>
          <.input_group_button variant="default" size="icon-xs" class="rounded-full" type="submit">
            <.icon name="hero-arrow-up" class="size-4" />
            <span class="sr-only">Send</span>
          </.input_group_button>
        </.input_group_addon>
      </.input_group>
  """
  use SaladUI, :component

  alias Phoenix.HTML.FormField

  @group_class [
    "group/input-group relative flex w-full items-center rounded-md border border-input shadow-xs transition-[color,box-shadow] outline-none dark:bg-input/30",
    "h-9 min-w-0 has-[>textarea]:h-auto",
    # Variants based on alignment.
    "has-[>[data-align=inline-start]]:[&>input]:pl-2",
    "has-[>[data-align=inline-end]]:[&>input]:pr-2",
    "has-[>[data-align=block-start]]:h-auto has-[>[data-align=block-start]]:flex-col has-[>[data-align=block-start]]:[&>input]:pb-3",
    "has-[>[data-align=block-end]]:h-auto has-[>[data-align=block-end]]:flex-col has-[>[data-align=block-end]]:[&>input]:pt-3",
    # Focus state.
    "has-[[data-slot=input-group-control]:focus-visible]:border-ring has-[[data-slot=input-group-control]:focus-visible]:ring-[3px] has-[[data-slot=input-group-control]:focus-visible]:ring-ring/50",
    # Error state.
    "has-[[data-slot][aria-invalid=true]]:border-destructive has-[[data-slot][aria-invalid=true]]:ring-destructive/20 dark:has-[[data-slot][aria-invalid=true]]:ring-destructive/40"
  ]

  @addon_class "flex h-auto cursor-text items-center justify-center gap-2 py-1.5 text-sm font-medium text-muted-foreground select-none group-data-[disabled=true]/input-group:opacity-50 [&>kbd]:rounded-[calc(var(--radius)-5px)] [&>svg:not([class*='size-'])]:size-4"

  @addon_align_class %{
    "inline-start" => "order-first pl-3 has-[>button]:ml-[-0.45rem] has-[>kbd]:ml-[-0.35rem]",
    "inline-end" => "order-last pr-3 has-[>button]:mr-[-0.45rem] has-[>kbd]:mr-[-0.35rem]",
    "block-start" => "order-first w-full justify-start px-3 pt-3 group-has-[>input]/input-group:pt-2.5 [.border-b]:pb-3",
    "block-end" => "order-last w-full justify-start px-3 pb-3 group-has-[>input]/input-group:pb-2.5 [.border-t]:pt-3"
  }

  @button_size_class %{
    "xs" => "h-6 gap-1 rounded-[calc(var(--radius)-5px)] px-2 has-[>svg]:px-2 [&>svg:not([class*='size-'])]:size-3.5",
    "sm" => "h-8 gap-1.5 rounded-md px-2.5 has-[>svg]:px-2.5",
    "icon-xs" => "size-6 rounded-[calc(var(--radius)-5px)] p-0 has-[>svg]:p-0",
    "icon-sm" => "size-8 p-0 has-[>svg]:p-0"
  }

  @input_rest ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  @doc """
  Renders the input group container.

  ## Options

  * `:id` - Required. Identifies the group for the SaladUI hook that focuses the
    control when an addon is clicked.
  * `:disabled` - Renders `data-disabled="true"`, which dims the addons. Disable
    the control itself too, e.g. `<.input_group_input disabled />`.
  * `:class` - Additional CSS classes.
  * `:rest` - Additional HTML attributes.

  ## Examples

      <.input_group id="amount">
        <.input_group_addon>
          <.input_group_text>$</.input_group_text>
        </.input_group_addon>
        <.input_group_input placeholder="0.00" />
        <.input_group_addon align="inline-end">
          <.input_group_text>USD</.input_group_text>
        </.input_group_addon>
      </.input_group>
  """
  attr :id, :string, required: true, doc: "Unique identifier for the input group"
  attr :disabled, :boolean, default: false, doc: "dims the addons (sets `data-disabled`)"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def input_group(assigns) do
    assigns = assign(assigns, :group_class, classes([@group_class, assigns.class]))

    ~H"""
    <div
      id={@id}
      role="group"
      data-slot="input-group"
      data-component="input-group"
      data-part="root"
      data-disabled={@disabled && "true"}
      phx-hook="SaladUI"
      class={@group_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders an addon (icons, text, buttons, keyboard hints...) next to the control.

  Place it after the control in the markup and position it with `:align`.

  ## Options

  * `:align` - Where the addon sits relative to the control:
      * `"inline-start"` (default) - before the control, on the same line
      * `"inline-end"` - after the control, on the same line
      * `"block-start"` - above the control, full width
      * `"block-end"` - below the control, full width
  * `:class` - Additional CSS classes. `border-b` on a `block-start` addon (or
    `border-t` on a `block-end` one) also adds matching padding.

  ## Examples

      <.input_group_addon align="inline-end">
        <.icon name="hero-information-circle" class="size-4" />
      </.input_group_addon>

      <.input_group_addon align="block-start" class="border-b">
        <.input_group_text class="font-mono">script.js</.input_group_text>
        <.input_group_button size="icon-xs" class="ml-auto" aria-label="Copy">
          <.icon name="hero-clipboard" class="size-3.5" />
        </.input_group_button>
      </.input_group_addon>
  """
  attr :align, :string,
    values: ~w(inline-start inline-end block-start block-end),
    default: "inline-start",
    doc: "the addon position relative to the control"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def input_group_addon(assigns) do
    assigns = assign(assigns, :addon_class, classes([@addon_class, @addon_align_class[assigns.align], assigns.class]))

    ~H"""
    <div
      role="group"
      data-slot="input-group-addon"
      data-part="addon"
      data-align={@align}
      class={@addon_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a compact button for use inside an `input_group_addon/1`.

  Clicking it does not move focus to the group's control.

  ## Options

  * `:type` - HTML button type. Defaults to `"button"` so it never submits a
    form by accident; pass `type="submit"` for send buttons.
  * `:variant` - `"ghost"` (default), `"default"`, `"secondary"`, `"outline"`,
    `"destructive"` or `"link"`. Same styles as `SaladUI.Button.button/1`.
  * `:size` - `"xs"` (default), `"sm"`, `"icon-xs"` or `"icon-sm"`.
  * `:class` - Additional CSS classes.
  * `:rest` - Additional HTML attributes, e.g. `disabled`, `aria-label`, `phx-click`.

  ## Examples

      <.input_group_button variant="secondary">Search</.input_group_button>

      <.input_group_button size="icon-xs" aria-label="Copy">
        <.icon name="hero-clipboard" class="size-3.5" />
      </.input_group_button>
  """
  attr :type, :string, default: "button"

  attr :variant, :string,
    values: ~w(default secondary destructive outline ghost link),
    default: "ghost",
    doc: "the button variant style"

  attr :size, :string, values: ~w(xs sm icon-xs icon-sm), default: "xs", doc: "the button size"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def input_group_button(assigns) do
    assigns =
      assigns
      |> put_data_slot("button")
      |> assign(
        :button_class,
        classes([
          button_variant(%{variant: assigns.variant}),
          "flex items-center gap-2 text-sm shadow-none",
          @button_size_class[assigns.size],
          assigns.class
        ])
      )

    ~H"""
    <button
      type={@type}
      data-variant={@variant}
      data-size={@size}
      class={@button_class}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders muted inline text (a prefix, suffix, counter...) inside an addon.

  ## Examples

      <.input_group_addon align="inline-end">
        <.input_group_text>@company.com</.input_group_text>
      </.input_group_addon>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def input_group_text(assigns) do
    ~H"""
    <span
      data-slot="input-group-text"
      class={
        classes([
          "flex items-center gap-2 text-sm text-muted-foreground [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  Renders the group's text input: a `SaladUI.Input.input/1` with borderless
  styling and `data-slot="input-group-control"`.

  Accepts every `SaladUI.Input.input/1` option, including `:field` (invalid
  fields get `aria-invalid`, which turns the whole group's border red).

  ## Examples

      <.input_group_input placeholder="Search..." />
      <.input_group_input field={@form[:email]} type="email" />
  """
  attr :id, :any, default: nil
  attr :name, :any, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(date datetime-local email file hidden month number password tel text time url week)

  attr :"default-value", :any
  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"
  attr :class, :any, default: nil
  attr :rest, :global, include: @input_rest

  def input_group_input(assigns) do
    assigns = assign(assigns, :control_attrs, control_attrs(assigns))

    ~H"""
    <SaladUI.Input.input
      class={
        classes([
          "flex-1 rounded-none border-0 bg-transparent shadow-none focus-visible:ring-0 dark:bg-transparent",
          @class
        ])
      }
      {@control_attrs}
    />
    """
  end

  @doc """
  Renders the group's textarea: a `SaladUI.Textarea.textarea/1` with borderless
  styling and `data-slot="input-group-control"`.

  Accepts every `SaladUI.Textarea.textarea/1` option, including `:field`.

  ## Examples

      <.input_group_textarea placeholder="Enter your message" />
      <.input_group_textarea field={@form[:body]} class="min-h-[200px]" />
  """
  attr :id, :any, default: nil
  attr :name, :any, default: nil
  attr :value, :any
  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:body]"
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(autocomplete cols dirname disabled form maxlength minlength placeholder readonly required rows wrap)

  def input_group_textarea(assigns) do
    assigns = assign(assigns, :control_attrs, control_attrs(assigns))

    ~H"""
    <SaladUI.Textarea.textarea
      class={
        classes([
          "flex-1 resize-none rounded-none border-0 bg-transparent py-3 shadow-none focus-visible:ring-0 dark:bg-transparent",
          @class
        ])
      }
      {@control_attrs}
    />
    """
  end

  defp control_attrs(assigns) do
    assigns
    |> Map.take([:id, :name, :value, :type, :field, :"default-value"])
    |> Map.merge(assigns.rest)
    |> Map.put_new(:"data-slot", "input-group-control")
  end
end
