defmodule SaladUI.Field do
  @moduledoc """
  Field components for composing accessible form fields: labels, controls,
  help text and validation messages, alone or in groups.

  This is the shadcn/ui `Field` family and the recommended way to build forms.
  It supersedes the legacy `SaladUI.Form` helpers (`form_item/1`,
  `form_label/1`, ...), which are kept for backwards compatibility.

  | Component             | Renders                                                     |
  | --------------------- | ----------------------------------------------------------- |
  | `field_set/1`         | a `<fieldset>` for semantic grouping                        |
  | `field_legend/1`      | the fieldset's `<legend>` (`legend` or `label` variant)     |
  | `field_group/1`       | a stack of fields; the container for responsive layouts     |
  | `field/1`             | one field (`role="group"`): label, control, help, error     |
  | `field_content/1`     | a column grouping label and description beside a control   |
  | `field_label/1`       | the field's label (also wraps a whole field as choice card) |
  | `field_title/1`       | label-styled title for content without a `<label>`          |
  | `field_description/1` | helper text                                                 |
  | `field_separator/1`   | a divider between fields, with optional inline text         |
  | `field_error/1`       | the validation message(s), `role="alert"`                   |

  ## Examples

      <.field_set>
        <.field_legend>Profile</.field_legend>
        <.field_description>This appears on invoices and emails.</.field_description>
        <.field_group>
          <.field>
            <.field_label for="name">Full name</.field_label>
            <.input id="name" autocomplete="off" placeholder="Evil Rabbit" />
            <.field_description>This appears on invoices and emails.</.field_description>
          </.field>
          <.field invalid>
            <.field_label for="username">Username</.field_label>
            <.input id="username" autocomplete="off" aria-invalid="true" />
            <.field_error>Choose another username.</.field_error>
          </.field>
          <.field orientation="horizontal">
            <.switch id="newsletter" />
            <.field_label for="newsletter-input">Subscribe to the newsletter</.field_label>
          </.field>
        </.field_group>
      </.field_set>

  ## With a Phoenix form

  Pass the same `Phoenix.HTML.FormField` to `field/1`, `field_label/1`, the
  control and `field_error/1`. The field turns red (`data-invalid`), the label
  points at the control, the control gets `aria-invalid`, and the error shows
  the field's translated messages. Like the controls, errors on a field the user
  has not interacted with yet are ignored (see
  `Phoenix.Component.used_input?/1`).

      <.form for={@form} phx-change="validate" phx-submit="save">
        <.field_group>
          <.field field={@form[:email]}>
            <.field_label field={@form[:email]}>Email</.field_label>
            <.input field={@form[:email]} type="email" />
            <.field_description>We never share your email.</.field_description>
            <.field_error field={@form[:email]} />
          </.field>
          <.field orientation="horizontal">
            <.button type="submit">Save</.button>
          </.field>
        </.field_group>
      </.form>

  ## Orientation

  `field/1` stacks its children by default (`vertical`). `horizontal` puts
  the label and control side by side; pair it with `field_content/1` to keep a
  description under the label. `responsive` stacks on narrow containers and
  switches to horizontal once the surrounding `field_group/1` is at least
  `@md` wide (a container query, not a viewport breakpoint).
  """
  use SaladUI, :component

  alias Phoenix.HTML.FormField

  @doc """
  Renders a `<fieldset>` that groups related fields under a `field_legend/1`.

  ## Examples

      <.field_set>
        <.field_legend>Delivery</.field_legend>
        <.field_group>...</.field_group>
      </.field_set>
  """
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form name)
  slot :inner_block, required: true

  def field_set(assigns) do
    ~H"""
    <fieldset
      data-slot="field-set"
      class={
        classes([
          "flex flex-col gap-6",
          "has-[>[data-slot=checkbox-group]]:gap-3 has-[>[data-slot=radio-group]]:gap-3",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </fieldset>
    """
  end

  @doc """
  Renders the `<legend>` of a `field_set/1`.

  The `label` variant uses label sizing, handy for a fieldset nested in a
  field group.

  ## Examples

      <.field_legend>Payment Method</.field_legend>
      <.field_legend variant="label">Notification Preferences</.field_legend>
  """
  attr :variant, :string, default: "legend", values: ~w(legend label), doc: "`legend` (text-base) or `label` (text-sm)"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def field_legend(assigns) do
    ~H"""
    <legend
      data-slot="field-legend"
      data-variant={@variant}
      class={
        classes([
          "mb-3 font-medium",
          "data-[variant=legend]:text-base",
          "data-[variant=label]:text-sm",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </legend>
    """
  end

  @doc """
  Stacks `field/1` components (and nested groups or fieldsets).

  It is also the `@container/field-group` that `orientation="responsive"`
  fields measure. Pass `data-slot="checkbox-group"` for the tighter spacing of
  a checkbox list.

  ## Examples

      <.field_group>
        <.field>...</.field>
        <.field_separator />
        <.field>...</.field>
      </.field_group>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def field_group(assigns) do
    assigns = put_data_slot(assigns, "field-group")

    ~H"""
    <div
      class={
        classes([
          "group/field-group @container/field-group flex w-full flex-col gap-7 data-[slot=checkbox-group]:gap-3 [&>[data-slot=field-group]]:gap-4",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  # The `[data-slot=select]` rules: SaladUI's select wraps its trigger in a root
  # <div> (Radix renders the trigger directly), so `[&>*]:w-full` alone would
  # leave the trigger at `w-fit` where shadcn's fills the field.
  @field_orientation %{
    "vertical" => "flex-col [&>*]:w-full [&>.sr-only]:w-auto [&>[data-slot=select]>[data-slot=select-trigger]]:w-full",
    "horizontal" =>
      "flex-row items-center [&>[data-slot=field-label]]:flex-auto has-[>[data-slot=field-content]]:items-start has-[>[data-slot=field-content]]:[&>[role=checkbox],[role=radio],[data-slot=checkbox],[data-slot=radio-group-item]]:mt-px",
    "responsive" =>
      "flex-col @md/field-group:flex-row @md/field-group:items-center [&>*]:w-full @md/field-group:[&>*]:w-auto [&>.sr-only]:w-auto [&>[data-slot=select]>[data-slot=select-trigger]]:w-full @md/field-group:[&>[data-slot=select]>[data-slot=select-trigger]]:w-auto @md/field-group:[&>[data-slot=field-label]]:flex-auto @md/field-group:has-[>[data-slot=field-content]]:items-start @md/field-group:has-[>[data-slot=field-content]]:[&>[role=checkbox],[role=radio],[data-slot=checkbox],[data-slot=radio-group-item]]:mt-px"
  }

  @doc """
  Renders one field: a `role="group"` wrapper for a label, a control, helper
  text and an error.

  The field switches to its error state (`data-invalid="true"`, destructive
  text) when `invalid` is set, when `data-invalid` is passed, or when `field`
  has errors the user can see.

  ## Examples

      <.field>
        <.field_label for="email">Email</.field_label>
        <.input id="email" type="email" />
      </.field>

      <.field orientation="horizontal">
        <.checkbox id="terms" />
        <.field_label for="terms">Accept terms</.field_label>
      </.field>

      <.field field={@form[:email]}>
        <.field_label field={@form[:email]}>Email</.field_label>
        <.input field={@form[:email]} type="email" />
        <.field_error field={@form[:email]} />
      </.field>
  """
  attr :orientation, :string,
    default: "vertical",
    values: ~w(vertical horizontal responsive),
    doc: "stack (`vertical`), side by side (`horizontal`), or stack until the field group is `@md` wide (`responsive`)"

  attr :invalid, :boolean, default: false, doc: "puts the field in its error state"

  attr :field, FormField,
    default: nil,
    doc: "a form field struct, for example `@form[:email]`; its visible errors set the error state"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def field(assigns) do
    {data_invalid, rest} = Map.pop(assigns.rest, :"data-invalid")
    invalid = assigns.invalid or data_invalid in [true, "true"] or field_invalid?(assigns.field)

    assigns =
      assigns
      |> assign(:rest, rest)
      |> assign(:data_invalid, invalid && "true")
      |> assign(:orientation_class, Map.fetch!(@field_orientation, assigns.orientation))

    ~H"""
    <div
      role="group"
      data-slot="field"
      data-orientation={@orientation}
      data-invalid={@data_invalid}
      class={
        classes([
          "group/field flex w-full gap-3 data-[invalid=true]:text-destructive",
          @orientation_class,
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
  Groups a label and description in a column, for horizontal fields where the
  control sits beside them.

  ## Examples

      <.field orientation="horizontal">
        <.checkbox id="notifications" />
        <.field_content>
          <.field_label for="notifications">Notifications</.field_label>
          <.field_description>Email, SMS, and push options.</.field_description>
        </.field_content>
      </.field>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def field_content(assigns) do
    ~H"""
    <div
      data-slot="field-content"
      class={classes(["group/field-content flex flex-1 flex-col gap-1.5 leading-snug", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the field's `<label>`.

  Wrap a whole `field/1` in it to make a selectable choice card: the card
  gets a border, and a primary border and tint once its radio item or
  switch is checked.

  ## Examples

      <.field_label for="email">Email</.field_label>
      <.field_label field={@form[:email]}>Email</.field_label>

      <.field_label for="plan-pro">
        <.field orientation="horizontal">
          <.field_content>
            <.field_title>Pro</.field_title>
            <.field_description>For growing teams.</.field_description>
          </.field_content>
          <.radio_group_item id="plan-pro" value="pro" />
        </.field>
      </.field_label>
  """
  attr :for, :string, default: nil, doc: "id of the labelled control"

  attr :field, FormField,
    default: nil,
    doc: "a form field struct, for example `@form[:email]`; `for` defaults to its id"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def field_label(assigns) do
    assigns = assign(assigns, :for, assigns.for || (assigns.field && assigns.field.id))

    ~H"""
    <SaladUI.Label.label
      data-slot="field-label"
      for={@for}
      class={
        classes([
          "group/field-label peer/field-label flex w-fit gap-2 leading-snug group-data-[disabled=true]/field:opacity-50",
          "has-[>[data-slot=field]]:w-full has-[>[data-slot=field]]:flex-col has-[>[data-slot=field]]:rounded-md has-[>[data-slot=field]]:border [&>*]:data-[slot=field]:p-4",
          "has-data-[state=checked]:border-primary has-data-[state=checked]:bg-primary/5 dark:has-data-[state=checked]:bg-primary/10",
          "has-[[data-slot=checkbox]:checked]:border-primary has-[[data-slot=checkbox]:checked]:bg-primary/5 dark:has-[[data-slot=checkbox]:checked]:bg-primary/10",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </SaladUI.Label.label>
    """
  end

  @doc """
  Renders a title styled like `field_label/1`, for content that has no
  control to label (e.g. inside a choice card, or above a slider).

  ## Examples

      <.field_content>
        <.field_title>Enable Touch ID</.field_title>
        <.field_description>Unlock your device faster.</.field_description>
      </.field_content>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def field_title(assigns) do
    ~H"""
    <div
      data-slot="field-label"
      class={
        classes([
          "flex w-fit items-center gap-2 text-sm leading-snug font-medium group-data-[disabled=true]/field:opacity-50",
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
  Renders helper text for a field or fieldset. Links inside are underlined.

  ## Examples

      <.field_description>We never share your email with anyone.</.field_description>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def field_description(assigns) do
    ~H"""
    <p
      data-slot="field-description"
      class={
        classes([
          "text-sm leading-normal font-normal text-muted-foreground group-has-[[data-orientation=horizontal]]/field:text-balance",
          "last:mt-0 nth-last-2:-mt-1 [[data-variant=legend]+&]:-mt-1.5",
          "[&>a]:underline [&>a]:underline-offset-4 [&>a:hover]:text-primary",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a horizontal divider between fields, optionally with text centred
  on the line.

  ## Examples

      <.field_separator />
      <.field_separator>Or continue with</.field_separator>
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def field_separator(assigns) do
    assigns = assign(assigns, :content, assigns.inner_block != [])

    ~H"""
    <div
      data-slot="field-separator"
      data-content={to_string(@content)}
      class={
        classes([
          "relative -my-2 h-5 text-sm group-data-[variant=outline]/field-group:-mb-2",
          @class
        ])
      }
      {@rest}
    >
      <SaladUI.Separator.separator class="absolute inset-0 top-1/2" />
      <span
        :if={@content}
        class="relative mx-auto block w-fit bg-background px-2 text-muted-foreground"
        data-slot="field-separator-content"
      >
        {render_slot(@inner_block)}
      </span>
    </div>
    """
  end

  @doc """
  Renders a field's validation message in a `role="alert"` container.

  Shows, in order of precedence: the inner block; the `errors` list; the
  visible errors of `field` (only once the user has interacted with it).
  Duplicate messages are dropped, and several messages render as a bulleted
  list. Renders nothing when there is nothing to show.

  ## Examples

      <.field_error>Choose another username.</.field_error>
      <.field_error field={@form[:username]} />
      <.field_error errors={["Too short", "Must contain a number"]} />
  """
  attr :field, FormField,
    default: nil,
    doc: "a form field struct, for example `@form[:email]`; shows its translated errors once the field is used"

  attr :errors, :list,
    default: [],
    doc: "error messages: strings, `{msg, opts}` tuples, or maps with a `:message` key; `nil`s are skipped"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def field_error(assigns) do
    messages =
      case assigns.errors do
        [] -> if field_invalid?(assigns.field), do: field_errors(assigns.field), else: []
        errors -> errors |> Enum.map(&error_message/1) |> Enum.reject(&(&1 in [nil, ""]))
      end

    assigns = assign(assigns, :messages, Enum.uniq(messages))

    ~H"""
    <div
      :if={@inner_block != [] or @messages != []}
      role="alert"
      data-slot="field-error"
      class={classes(["text-sm font-normal text-destructive", @class])}
      {@rest}
    >
      <%= cond do %>
        <% @inner_block != [] -> %>
          {render_slot(@inner_block)}
        <% match?([_], @messages) -> %>
          {hd(@messages)}
        <% true -> %>
          <ul class="ml-4 flex list-disc flex-col gap-1">
            <li :for={message <- @messages}>{message}</li>
          </ul>
      <% end %>
    </div>
    """
  end

  defp error_message(nil), do: nil
  defp error_message(message) when is_binary(message), do: message
  defp error_message({_msg, opts} = error) when is_list(opts), do: translate_form_error(error)
  defp error_message(%{message: message}), do: error_message(message)
  defp error_message(%{"message" => message}), do: error_message(message)
end
