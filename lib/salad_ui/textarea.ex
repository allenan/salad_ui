defmodule SaladUI.Textarea do
  @moduledoc """
  Implementation of a textarea component for multi-line text input.

  ## Examples:

      <.textarea field={f[:description]} placeholder="Type your message here" />
      <.textarea rows="6" placeholder="Add your comments" value={@description} />
  """
  use SaladUI, :component

  @doc """
  Renders a form textarea.

  ## Options

  * `:id` - The id to use for the textarea
  * `:name` - The name to use for the textarea
  * `:value` - The value to pre-populate the textarea with
  * `:field` - A form field struct to build the textarea from
  * `:class` - Additional CSS classes to apply
  * `:rows` - Number of visible text lines (passed through as rest)
  * `:placeholder` - Placeholder text (passed through as rest)
  * `:disabled` - Whether the textarea is disabled (passed through as rest)
  * `:required` - Whether the textarea is required (passed through as rest)
  * `:aria-invalid` - rendered as `aria-invalid="true"` automatically when `:field` has errors, which applies the destructive error styling; pass it explicitly to override
  """
  attr :id, :any, default: nil
  attr :name, :any, default: nil
  attr :value, :any
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled form rows cols)

  def textarea(assigns) do
    assigns =
      assigns
      |> prepare_assign()
      |> put_aria_invalid()

    ~H"""
    <textarea
      id={@id}
      name={@name}
      data-slot="textarea"
      class={
        classes([
          "flex field-sizing-content min-h-16 w-full rounded-md border border-input bg-transparent px-3 py-2 text-base shadow-xs transition-[color,box-shadow] outline-none placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 md:text-sm dark:bg-input/30 dark:aria-invalid:ring-destructive/40",
          @class
        ])
      }
      {@rest}
    ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
    """
  end
end
