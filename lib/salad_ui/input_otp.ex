defmodule SaladUI.InputOTP do
  @moduledoc """
  Accessible one-time password input with copy-paste support, from
  https://ui.shadcn.com/docs/components/input-otp

  Like the [input-otp](https://input-otp.rodz.dev) library shadcn builds on, the
  component is backed by **one real `<input>`** stretched invisibly over the
  slots. It carries the `name`, `value`, `maxlength`, `pattern`, `inputmode` and
  `autocomplete="one-time-code"` attributes, so forms, `phx-change`, password
  managers and SMS code autofill all see an ordinary text input. The slots are
  drawn from its value by the JavaScript component, which also renders the
  active slot ring and the blinking fake caret.

  ## Examples

      <.input_otp id="otp" maxlength={6} name="code">
        <.input_otp_group>
          <.input_otp_slot index={0} />
          <.input_otp_slot index={1} />
          <.input_otp_slot index={2} />
        </.input_otp_group>
        <.input_otp_separator />
        <.input_otp_group>
          <.input_otp_slot index={3} />
          <.input_otp_slot index={4} />
          <.input_otp_slot index={5} />
        </.input_otp_group>
      </.input_otp>

  Restrict accepted characters with `pattern`, a JavaScript regular expression
  source tested against the whole value. The shadcn/input-otp constants are
  available as functions:

      <.input_otp id="pin" maxlength={4} pattern={SaladUI.InputOTP.regexp_only_digits()}>
        <.input_otp_group>
          <.input_otp_slot :for={i <- 0..3} index={i} />
        </.input_otp_group>
      </.input_otp>

  Inside a form, pass a field. The real input gets `aria-invalid="true"` when
  the field has errors and every slot picks up the destructive styling:

      <.label for="verification-input">Verification code</.label>
      <.input_otp field={@form[:code]} id="verification" maxlength={6}>
        ...
      </.input_otp>

  The real input's id is `"\#{id}-input"`; point labels at that.

  ## Behaviour

  * Typing fills the next slot; when every slot is filled, the last character is
    selected so the next keystroke replaces it.
  * `Backspace`/`Delete`, arrow keys, `Home`/`End` and text selection are the
    native input's.
  * Clicking a filled slot selects its character; clicking an empty slot puts
    the caret after the last character.
  * Pasting replaces the selection with the clipboard text (whitespace
    stripped), truncated to `maxlength`. Input that fails `pattern` is rejected.

  ## Component events

  * `:on-value-changed` - Maps the `value-changed` event. Fired with
    `%{"value" => value}` whenever the value changes.
  * `:on-complete` - Maps the `complete` event. Fired with `%{"value" => value}`
    when the last slot is filled.

  ## Server commands

  * `"setValue"` - Replaces the value. Requires a `:value` param.
  * `"clear"` - Empties the input.
  """
  use SaladUI, :component

  @doc "Accepts digits only: `^\\d+$`."
  def regexp_only_digits, do: "^\\d+$"

  @doc "Accepts ASCII letters only: `^[a-zA-Z]+$`."
  def regexp_only_chars, do: "^[a-zA-Z]+$"

  @doc "Accepts ASCII letters and digits: `^[a-zA-Z0-9]+$`."
  def regexp_only_digits_and_chars, do: "^[a-zA-Z0-9]+$"

  @doc """
  Renders the OTP input root: the slot container plus the single real input.

  `class` styles the container (shadcn's `containerClassName`); `input-class`
  styles the real input (shadcn's `className`). Other global attributes, such
  as `required`, `autofocus`, `form`, `aria-label`, `aria-describedby` or
  `phx-debounce`, go on the real input.

  ## Options

  * `:id` - Root id, required unless `:field` is given. The real input's id is `"\#{id}-input"`.
  * `:maxlength` - Number of characters (slots).
  * `:name` / `:value` / `:default-value` / `:field` - Form binding.
  * `:pattern` - JavaScript regex source the whole value must match; see `regexp_only_digits/0`.
  * `:inputmode` - Defaults to `"numeric"`, or `"text"` when `:pattern` allows non-digits.
  * `:autocomplete` - Defaults to `"one-time-code"`.
  * `:disabled` - Disables the input.
  * `:dir` - Text direction (`"ltr"` or `"rtl"`).
  * `:on-value-changed` / `:on-complete` - Client event handlers.
  * `:aria-invalid` - Set automatically when `:field` has errors; marks every slot invalid.
  """
  attr :id, :string, default: nil
  attr :name, :any, default: nil
  attr :value, :any, default: nil, doc: "the current value"
  attr :"default-value", :any, default: nil, doc: "value used when `value` is empty"
  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form, for example: @form[:code]"
  attr :maxlength, :integer, required: true, doc: "number of characters (slots)"
  attr :pattern, :string, default: nil, doc: "JavaScript regex source the whole value must match"
  attr :inputmode, :string, default: nil, doc: ~s|virtual keyboard hint; derived from `pattern` when nil|
  attr :autocomplete, :string, default: "one-time-code"
  attr :disabled, :boolean, default: false
  attr :dir, :string, default: nil, values: [nil, "ltr", "rtl"]
  attr :"on-value-changed", :any, default: nil, doc: "handler for the value-changed event"
  attr :"on-complete", :any, default: nil, doc: "handler fired when every slot is filled"
  attr :class, :any, default: nil, doc: "classes for the slot container"
  attr :"input-class", :any, default: nil, doc: "classes for the real input"
  attr :rest, :global, include: ~w(autofocus form readonly required)
  slot :inner_block, required: true

  def input_otp(assigns) do
    assigns =
      assigns
      |> prepare_assign()
      |> put_aria_invalid()

    if is_nil(assigns.id) do
      raise ArgumentError, "input_otp/1 requires an :id (or a :field to derive one from)"
    end

    value =
      case assigns.value do
        nil -> ""
        value -> value |> to_string() |> String.slice(0, assigns.maxlength)
      end

    invalid = assigns.rest[:"aria-invalid"] in [true, "true"]

    options = %{maxLength: assigns.maxlength, pattern: assigns.pattern, disabled: assigns.disabled}

    assigns =
      assigns
      |> assign(:value, value)
      |> assign(:invalid, invalid)
      |> assign(:input_class, assigns[:"input-class"])
      |> assign(:inputmode, assigns.inputmode || inputmode(assigns.pattern))
      |> assign(:options, json(options))
      |> assign(:event_map, json(event_mappings(assigns)))

    ~H"""
    <div
      id={@id}
      data-component="input-otp"
      data-part="root"
      data-state="idle"
      data-options={@options}
      data-event-mappings={@event_map}
      data-input-otp-container
      data-disabled={@disabled}
      data-invalid={@invalid && "true"}
      dir={@dir}
      phx-hook="SaladUI"
      class={
        classes([
          "flex items-center gap-2 has-disabled:opacity-50",
          "group/input-otp pointer-events-none relative select-none",
          if(@disabled, do: "cursor-default", else: "cursor-text"),
          @class
        ])
      }
    >
      {render_slot(@inner_block)}
      <div class="absolute inset-0 pointer-events-none">
        <input
          type="text"
          id={"#{@id}-input"}
          name={@name}
          value={@value}
          maxlength={@maxlength}
          pattern={@pattern}
          inputmode={@inputmode}
          autocomplete={@autocomplete}
          disabled={@disabled}
          dir={@dir}
          spellcheck="false"
          autocapitalize="off"
          data-part="input"
          data-slot="input-otp"
          data-input-otp
          class={
            classes([
              "absolute inset-0 m-0 flex size-full appearance-none rounded-none border-0 bg-transparent p-0 text-left font-mono leading-none tracking-[-.5em] tabular-nums text-transparent caret-transparent opacity-100 shadow-none outline-none pointer-events-auto [font-size:var(--root-height,2.25rem)] [-webkit-text-fill-color:transparent]",
              "focus:shadow-none focus:ring-0 focus:outline-none selection:bg-transparent selection:text-transparent",
              "autofill:border-transparent! autofill:bg-transparent! autofill:opacity-0! autofill:shadow-none!",
              "supports-[-webkit-touch-callout:none]:tracking-[-.6em]",
              "disabled:cursor-not-allowed",
              @input_class
            ])
          }
          {@rest}
        />
      </div>
    </div>
    """
  end

  defp inputmode(pattern) when pattern in [nil, "^\\d+$", "^\\d*$", "^[0-9]+$", "^[0-9]*$"], do: "numeric"
  defp inputmode(_pattern), do: "text"

  @doc """
  Groups adjacent slots so they render as one joined box.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def input_otp_group(assigns) do
    ~H"""
    <div data-slot="input-otp-group" class={classes(["flex items-center", @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders the character box for one position of the value.

  Pass `aria-invalid` to show a slot in the error state. Slots also turn
  destructive when their `input_otp` is invalid, unless given
  `aria-invalid="false"`.
  """
  attr :index, :integer, required: true, doc: "zero-based position of the character this slot shows"
  attr :class, :any, default: nil
  attr :rest, :global

  def input_otp_slot(assigns) do
    # A bare `aria-invalid` renders as `aria-invalid=""`, which `aria-invalid:`
    # (i.e. `[aria-invalid="true"]`) does not match; normalise it like React.
    assigns =
      case assigns.rest do
        %{"aria-invalid": true} -> assign(assigns, :rest, Map.put(assigns.rest, :"aria-invalid", "true"))
        _ -> assigns
      end

    ~H"""
    <div
      data-slot="input-otp-slot"
      data-part="slot"
      data-index={@index}
      data-active="false"
      class={
        classes([
          "relative flex h-9 w-9 items-center justify-center border-y border-e border-input text-sm shadow-xs transition-all outline-none first:rounded-s-md first:border-s last:rounded-e-md aria-invalid:border-destructive data-[active=true]:z-10 data-[active=true]:border-ring data-[active=true]:ring-[3px] data-[active=true]:ring-ring/50 data-[active=true]:aria-invalid:border-destructive data-[active=true]:aria-invalid:ring-destructive/20 dark:bg-input/30 dark:data-[active=true]:aria-invalid:ring-destructive/40",
          "group-data-[invalid=true]/input-otp:not-aria-[invalid=false]:border-destructive group-data-[invalid=true]/input-otp:not-aria-[invalid=false]:data-[active=true]:ring-destructive/20 dark:group-data-[invalid=true]/input-otp:not-aria-[invalid=false]:data-[active=true]:ring-destructive/40",
          @class
        ])
      }
      {@rest}
    >
      <span data-part="slot-char"></span>
      <div
        data-part="caret"
        hidden
        class="pointer-events-none absolute inset-0 flex items-center justify-center"
      >
        <div class="animate-caret-blink h-4 w-px bg-foreground duration-1000" />
      </div>
    </div>
    """
  end

  @doc """
  Renders a separator between groups. Defaults to a minus icon; pass an inner
  block to render something else.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def input_otp_separator(assigns) do
    ~H"""
    <div data-slot="input-otp-separator" role="separator" class={@class} {@rest}>
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
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
          aria-hidden="true"
        >
          <path d="M5 12h14" />
        </svg>
      <% end %>
    </div>
    """
  end
end
