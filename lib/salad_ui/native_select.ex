defmodule SaladUI.NativeSelect do
  @moduledoc """
  A styled native HTML `<select>`.

  Use it for native browser behaviour, mobile-optimised pickers, or plain form
  submission without JavaScript. For a fully custom dropdown, see
  `SaladUI.Select`.

  Options can be written by hand with `native_select_option/1` and
  `native_select_optgroup/1`, or generated from the `options` attribute (same
  shapes as `Phoenix.HTML.Form.options_for_select/2`), in which case the
  option matching `value` (or the form field's value) is selected for you.

  ## Examples

      <.native_select name="status">
        <.native_select_option value="">Select status</.native_select_option>
        <.native_select_option value="todo">Todo</.native_select_option>
        <.native_select_option value="in-progress">In Progress</.native_select_option>
        <.native_select_option value="done">Done</.native_select_option>
      </.native_select>

      <.native_select name="department">
        <.native_select_option value="">Select department</.native_select_option>
        <.native_select_optgroup label="Engineering">
          <.native_select_option value="frontend">Frontend</.native_select_option>
          <.native_select_option value="backend">Backend</.native_select_option>
        </.native_select_optgroup>
      </.native_select>

      <.native_select
        field={@form[:role]}
        prompt="Select role"
        options={[{"Admin", "admin"}, {"Editor", "editor"}, {"Viewer", "viewer"}]}
      />

      <.native_select
        name="department"
        options={[{"Engineering", ["Frontend", "Backend"]}, {"Sales", ["Sales Rep"]}]}
      />
  """
  use SaladUI, :component

  @doc """
  Renders a native `<select>` with shadcn styling and a chevron icon.

  With a `field`, the `id`, `name`, `value` and errors come from the form;
  `aria-invalid="true"` (error styling) is set once the field has visible
  errors. Pass `aria-invalid` yourself to override.
  """
  attr :id, :any, default: nil
  attr :name, :any, default: nil
  attr :value, :any, doc: "the selected value (or list of values with `multiple`) used to mark generated `options`"

  attr :"default-value", :any, doc: "value to select when `value` is empty"

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:role]"

  attr :size, :string, default: "default", values: ~w(default sm), doc: "control height: `default` (h-9) or `sm` (h-8)"

  attr :options, :list,
    default: nil,
    doc: """
    options to render, as accepted by `Phoenix.HTML.Form.options_for_select/2`: values,
    `{label, value}` tuples, keyword lists with `:key`, `:value` and other option attributes
    (e.g. `disabled: true`), or `{group_label, options}` for an `<optgroup>`
    """

  attr :prompt, :string, default: nil, doc: "text of an empty-valued first option"
  attr :multiple, :boolean, default: false, doc: "allow selecting several options; the name gets a `[]` suffix"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(autocomplete autofocus disabled form required)
  slot :inner_block

  def native_select(assigns) do
    assigns =
      assigns
      |> prepare_assign()
      |> put_aria_invalid()

    assigns =
      assign(assigns, :selected, assigns.value |> List.wrap() |> Enum.map(&to_string/1))

    ~H"""
    <div
      class="group/native-select relative w-fit has-[select:disabled]:opacity-50"
      data-slot="native-select-wrapper"
    >
      <select
        id={@id}
        name={@name}
        multiple={@multiple}
        data-slot="native-select"
        data-size={@size}
        class={
          classes([
            "h-9 w-full min-w-0 appearance-none rounded-md border border-input bg-transparent px-3 py-2 pr-9 text-sm shadow-xs transition-[color,box-shadow] outline-none selection:bg-primary selection:text-primary-foreground placeholder:text-muted-foreground disabled:pointer-events-none disabled:cursor-not-allowed data-[size=sm]:h-8 data-[size=sm]:py-1 dark:bg-input/30 dark:hover:bg-input/50",
            "focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50",
            "aria-invalid:border-destructive aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
            # drop the chevron that @tailwindcss/forms paints on <select>; we render our own icon
            "bg-none",
            @class
          ])
        }
        {@rest}
      >
        <.native_select_option :if={@prompt} value="">{@prompt}</.native_select_option>
        <.options :if={@options} options={@options} selected={@selected} />
        {render_slot(@inner_block)}
      </select>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="24"
        height="24"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        stroke-linecap="round"
        stroke-linejoin="round"
        class="lucide lucide-chevron-down pointer-events-none absolute top-1/2 right-3.5 size-4 -translate-y-1/2 text-muted-foreground opacity-50 select-none"
        aria-hidden="true"
        data-slot="native-select-icon"
      >
        <path d="m6 9 6 6 6-6" />
      </svg>
    </div>
    """
  end

  @doc """
  Renders an `<option>` of a `native_select/1`.

  ## Examples

      <.native_select_option value="apple">Apple</.native_select_option>
      <.native_select_option value="kiwi" disabled>Kiwi</.native_select_option>
  """
  attr :value, :any, required: true
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled label selected)
  slot :inner_block, required: true

  def native_select_option(assigns) do
    ~H"""
    <option
      data-slot="native-select-option"
      value={@value}
      class={classes(["bg-[Canvas] text-[CanvasText]", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </option>
    """
  end

  @doc """
  Renders an `<optgroup>` that groups `native_select_option/1`s under a label.

  ## Examples

      <.native_select_optgroup label="Fruits">
        <.native_select_option value="apple">Apple</.native_select_option>
        <.native_select_option value="banana">Banana</.native_select_option>
      </.native_select_optgroup>
  """
  attr :label, :string, required: true
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled)
  slot :inner_block, required: true

  def native_select_optgroup(assigns) do
    ~H"""
    <optgroup
      data-slot="native-select-optgroup"
      label={@label}
      class={classes(["bg-[Canvas] text-[CanvasText]", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </optgroup>
    """
  end

  attr :options, :list, required: true
  attr :selected, :list, required: true

  defp options(assigns) do
    assigns = assign(assigns, :options, Enum.map(assigns.options, &normalize_option/1))

    ~H"""
    <%= for option <- @options do %>
      <%= case option do %>
        <% {:group, label, options} -> %>
          <.native_select_optgroup label={label}>
            <.options options={options} selected={@selected} />
          </.native_select_optgroup>
        <% {:option, label, value, attrs} -> %>
          <.native_select_option
            value={value}
            selected={to_string(value) in @selected}
            {attrs}
          >
            {label}
          </.native_select_option>
      <% end %>
    <% end %>
    """
  end

  defp normalize_option({label, options}) when is_list(options), do: {:group, to_string(label), options}

  defp normalize_option({label, value}), do: {:option, label, value, []}

  defp normalize_option(opts) when is_list(opts) do
    {value, opts} = Keyword.pop!(opts, :value)
    {key, opts} = Keyword.pop(opts, :key, value)
    {:option, key, value, opts}
  end

  defp normalize_option(value), do: {:option, value, value, []}
end
