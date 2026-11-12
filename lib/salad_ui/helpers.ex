defmodule SaladUI.Helpers do
  @moduledoc false
  use Phoenix.Component

  import Phoenix.Component

  alias Phoenix.HTML.FormField

  @doc """
  Prepares form-related assigns for use in an input component.

  When a `:field` (a `%Phoenix.HTML.FormField{}`) is given, `:id`, `:name`, `:value`,
  and `:errors` are derived from it, though explicit assigns still take precedence.
  `:used_input` records `Phoenix.Component.used_input?/1` for the field, so
  `invalid?/1` only flags inputs the user has interacted with.

  In all cases, falls back to `:"default-value"` when the resulting value is `nil`,
  `""`, or `[]`.
  """
  def prepare_assign(%{field: %FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns[:id] || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign(:used_input, field_used?(field))
    |> assign(:name, assigns[:name] || if(assigns[:multiple], do: field.name <> "[]", else: field.name))
    |> assign(:value, if(is_nil(assigns[:value]), do: field.value, else: assigns[:value]))
    |> prepare_assign()
  end

  # use default value if value is not provided or empty
  def prepare_assign(assigns) do
    value =
      if assigns[:value] in [nil, "", []] do
        assigns[:"default-value"]
      else
        assigns[:value]
      end

    assign(assigns, value: value)
  end

  @doc """
  Returns `true` when the user has interacted with the form field, following
  `Phoenix.Component.used_input?/1`.

  Hand-built fields (e.g. in tests) may have no form or params; they count as used.

  `Phoenix.Component.used_input?/1` only sees what the browser submits, so
  controls that keep their value in hidden inputs (select) or submit nothing when
  empty (radio group) render an extra input to take part in LiveView's
  used-input tracking. See `SaladUI.Select` and `SaladUI.RadioGroup`.
  """
  def field_used?(%FormField{form: %{params: params}} = field) when is_map(params) do
    Phoenix.Component.used_input?(field)
  end

  def field_used?(_field), do: true

  @doc """
  Returns `true` when the form field has errors and the user has interacted
  with it (see `field_used?/1`). This is the field-level counterpart of
  `invalid?/1`, used by `SaladUI.Form.form_label/1` and
  `SaladUI.Form.form_message/1` so labels and messages agree with the controls.
  """
  def field_invalid?(%FormField{} = field), do: has_error?(field) and field_used?(field)
  def field_invalid?(_field), do: false

  @doc """
  Returns the translated error messages for a form field.

  Returns `[]` when given anything other than a `%Phoenix.HTML.FormField{}`.
  """
  def field_errors(%FormField{} = field) do
    Enum.map(field.errors, &translate_error(&1))
  end

  def field_errors(_), do: []

  @doc """
  Returns `true` when the given form field has one or more errors.
  """
  def has_error?(%FormField{} = field) do
    not Enum.empty?(field.errors)
  end

  def has_error?(_field), do: false

  @doc """
  Returns `true` when the assigns carry one or more errors, as populated by
  `prepare_assign/1` from a `%Phoenix.HTML.FormField{}`.

  Like Phoenix's generated `core_components`, errors on a field the user has
  not interacted with yet (see `Phoenix.Component.used_input?/1`) don't count,
  so a `phx-change` validation doesn't flag every untouched input at once.
  """
  def invalid?(assigns) do
    assigns[:errors] not in [nil, []] and Map.get(assigns, :used_input, true)
  end

  @doc """
  Adds `aria-invalid="true"` to the `:rest` global attributes when the assigns
  carry errors (see `invalid?/1`), so form controls pick up shadcn's
  `aria-invalid:` error styling automatically when given a `field` with errors.

  An explicitly passed `aria-invalid` attribute always wins.
  """
  def put_aria_invalid(assigns) do
    if invalid?(assigns) do
      assign(assigns, :rest, Map.put_new(assigns[:rest] || %{}, :"aria-invalid", "true"))
    else
      assigns
    end
  end

  @doc """
  Sets shadcn's `data-slot` on the `:rest` global attributes unless the caller
  already passed one.

  Use it in components that other components wrap and re-label, the way shadcn
  does (e.g. `sidebar_separator` renders `separator` with
  `data-slot="sidebar-separator"`). A literal `data-slot` in the template would
  render the attribute twice, and the browser keeps the first one.
  """
  def put_data_slot(assigns, slot) do
    assign(assigns, :rest, Map.put_new(assigns[:rest] || %{}, :"data-slot", slot))
  end

  @doc """
  Builds a map of client event mappings from all assigned `on-*` attributes.

  Each `on-*` attribute (e.g. `on-open`, `on-value-changed`) is mapped to its bare
  event name (`"open"`, `"value-changed"`) for JSON-encoding into the
  `data-event-mappings` attribute consumed by the SaladUI JS hook. Attributes whose
  value is `nil` or `false` are skipped.
  """
  def event_mappings(assigns) do
    Enum.reduce(assigns, %{}, fn
      {key, value}, event_map when is_atom(key) and value not in [nil, false] ->
        case Atom.to_string(key) do
          "on-" <> event -> Map.put(event_map, event, value)
          _ -> event_map
        end

      _, event_map ->
        event_map
    end)
  end

  @doc """
  Encodes `data` to JSON using the application's configured `Phoenix.json_library/0`.

  Used to serialize the `data-options` and `data-event-mappings` attributes.
  """
  def json(data) do
    Phoenix.json_library().encode!(data)
  end

  @variants %{
    variant: %{
      "default" => "bg-primary text-primary-foreground hover:bg-primary/90",
      "destructive" =>
        "bg-destructive text-white hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:bg-destructive/60 dark:focus-visible:ring-destructive/40",
      "outline" =>
        "border border-border bg-background shadow-xs hover:bg-accent hover:text-accent-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50",
      "secondary" => "bg-secondary text-secondary-foreground hover:bg-secondary/80",
      "ghost" => "hover:bg-accent hover:text-accent-foreground dark:hover:bg-accent/50",
      "link" => "text-primary underline-offset-4 hover:underline"
    },
    size: %{
      "default" => "h-9 px-4 py-2 has-[>svg]:px-3",
      "xs" => "h-6 gap-1 rounded-md px-2 text-xs has-[>svg]:px-1.5 [&_svg:not([class*='size-'])]:size-3",
      "sm" => "h-8 gap-1.5 rounded-md px-3 has-[>svg]:px-2.5",
      "lg" => "h-10 rounded-md px-6 has-[>svg]:px-4",
      "icon" => "size-9",
      "icon-xs" => "size-6 rounded-md [&_svg:not([class*='size-'])]:size-3",
      "icon-sm" => "size-8",
      "icon-lg" => "size-10"
    }
  }

  @default_variants %{
    variant: "default",
    size: "default"
  }

  @doc """
  Reusable button variant helper. Supports two variant kinds:
  - size: `default|xs|sm|lg|icon|icon-xs|icon-sm|icon-lg`
  - variant: `default|destructive|outline|secondary|ghost|link`
  """
  def button_variant(props \\ %{}) do
    variants = Map.take(props, ~w(variant size)a)
    variants = Map.merge(@default_variants, variants)

    variation_classes = Enum.map_join(variants, " ", fn {key, value} -> @variants[key][value] end)

    shared_classes =
      "inline-flex shrink-0 items-center justify-center gap-2 rounded-md text-sm font-medium whitespace-nowrap transition-all outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4"

    "#{shared_classes} #{variation_classes}"
  end

  @doc """
  Builds a CSS class string from a variant config and the selected variant values,
  falling back to `default_variants` for any key not present in `class_input`.

  ## Examples

  ```elixir
  config =
  %{
    variants: %{
      variant: %{
        default: "hover:bg-sidebar-accent hover:text-sidebar-accent-foreground",
        outline:
          "bg-background shadow-[0_0_0_1px_var(--sidebar-border)] hover:bg-sidebar-accent hover:text-sidebar-accent-foreground hover:shadow-[0_0_0_1px_var(--sidebar-accent)]",
      },
      size: %{
        default: "h-8 text-sm",
        sm: "h-7 text-xs",
        lg: "h-12 text-sm group-data-[collapsible=icon]:!p-0",
      },
    },
    default_variants: %{
      variant: "default",
      size: "default",
    },
  }

  class_input = %{variant: "outline", size: "lg"}
  variant_class(config, class_input)
  ```

  """
  def variant_class(config, class_input) do
    variants = Map.get(config, :variants, %{})
    default_variants = Map.get(config, :default_variants, %{})

    variants
    |> Map.keys()
    |> Enum.map(fn variant_key ->
      # Get the variant value from input or use default
      variant_value =
        Map.get(class_input, variant_key) ||
          Map.get(default_variants, variant_key)

      # Get the variant options map
      variant_options = Map.get(variants, variant_key, %{})

      # Get the CSS classes for this variant value
      Map.get(variant_options, String.to_existing_atom(variant_value))
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  @doc """
  Builds a CSS `style` attribute string from a list of style maps and/or raw
  declaration strings. Map entries are merged together (later maps win on
  conflicting keys) and rendered before raw strings, which keep their given order.

  ## Examples

  ```elixir
  css_style = %{
    "background-color": "red",
    "color": "white",
    "font-size": "16px",
  }

  style(css_style)

  # => "background-color: red; color: white; font-size: 16px;"
  ```
  """
  def style(items) when is_list(items) do
    {acc_map, acc_list} =
      Enum.reduce(items, {%{}, []}, fn item, {acc_map, acc_list} ->
        if is_map(item) do
          {Map.merge(acc_map, item), acc_list}
        else
          {acc_map, [item | acc_list]}
        end
      end)

    map_declarations = Enum.map(acc_map, fn {k, v} -> "#{k}: #{v}" end)
    declarations = map_declarations ++ Enum.reverse(acc_list)

    case declarations do
      [] -> ""
      _ -> Enum.join(declarations, "; ") <> ";"
    end
  end

  @doc """
  Renders a dynamic tag based on the `tag` attribute, which can be a string or a
  function component.

  Wraps Phoenix LiveView's `dynamic_tag/1`, which only supports string tags.

  ## Examples

  ```heex
  <.dynamic tag={@tag} class="bg-primary text-primary-foreground">
     Hello World
  </.dynamic>
  ```
  """
  def dynamic(%{tag: name} = assigns) when is_function(name, 1) do
    assigns = Map.delete(assigns, :tag)
    name.(assigns)
  end

  def dynamic(assigns) do
    name = assigns[:tag] || "div"

    # Only `tag_name`: LiveView >= 1.0 renders an assigned `name` as an HTML
    # attribute, so a `name` here would leak as `name="div"` (and clobber a
    # caller's real `name`).
    assigns =
      assigns
      |> Map.delete(:tag)
      |> assign(:tag_name, name)

    dynamic_tag(assigns)
  end

  @doc """
  Mimics the behavior of shadcn/ui's `asChild` attribute.

  Passes all attributes given to `as_child` through to the `tag` function
  component, and passes `child` as that component's `as` attribute.

  The `tag` function component must accept an `:as` attribute to render the
  child component in its place.

  ## Examples

  ```heex
  <.as_child tag={&dropdown_menu_trigger/1} child={&sidebar_menu_button/1} class="bg-primary text-primary-foreground">
     Hello World
  </.as_child>
  ```

  This is equivalent to using `dropdown_menu_trigger` directly, but calling it
  directly would trigger a compiler warning for the unrecognized `:as` attribute:

  ```heex
  <.dropdown_menu_trigger as={&sidebar_menu_button/1} class="bg-primary text-primary-foreground">
     Hello World
  </.dropdown_menu_trigger>
  ```
  """
  def as_child(%{tag: tag, child: child_tag} = assigns) when is_function(tag, 1) do
    assigns
    |> Map.drop([:tag, :child])
    |> assign(:as, child_tag)
    |> tag.()
  end

  # Translate error message
  # borrowed from https://github.com/petalframework/petal_components/blob/main/lib/petal_components/field.ex#L414
  defp translate_error({msg, opts}) do
    config_translator = get_translator_from_config() || (&fallback_translate_error/1)

    config_translator.({msg, opts})
  end

  defp fallback_translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      try do
        String.replace(acc, "%{#{key}}", to_string(value))
      rescue
        e ->
          IO.warn(
            """
            the fallback message translator for the form_field_error function cannot handle the given value.

            Hint: you can set up the `error_translator_function` to route all errors to your application helpers:

              config :salad_ui, :error_translator_function, {MyAppWeb.CoreComponents, :translate_error}

            Given value: #{inspect(value)}

            Exception: #{Exception.message(e)}
            """,
            __STACKTRACE__
          )

          "invalid value"
      end
    end)
  end

  defp get_translator_from_config do
    case Application.get_env(:salad_ui, :error_translator_function) do
      {module, function} -> &apply(module, function, [&1])
      nil -> nil
    end
  end
end
