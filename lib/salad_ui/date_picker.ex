defmodule SaladUI.DatePicker do
  @moduledoc """
  A date picker: a `popover/1` whose trigger shows the selection and whose
  content is a `calendar/1`. See https://ui.shadcn.com/docs/components/date-picker

  shadcn has no date picker component, only the composition. `date_picker/1`
  ships that composition ready-made: the trigger label follows the selection
  without any LiveView code, and the value is submitted in ISO 8601 hidden
  inputs (rendered outside the popover, so they stay inside your form). It
  takes every option of `SaladUI.Calendar.calendar/1`, and must be rendered
  inside a LiveView.

  ## Examples

      <.date_picker id="due-date" />

      <.date_picker id="dob" caption-layout="dropdown" placeholder="Select date" />

      <.date_picker
        id="stay"
        mode="range"
        number-of-months={2}
        field={@form[:stay]}
        trigger-class="w-[300px]"
      />

      <.date_picker
        id="deadline"
        presets={[%{label: "Today", value: 0}, %{label: "Tomorrow", value: 1}, %{label: "In a week", value: 7}]}
      />

  The trigger can be replaced with the `trigger` slot, which receives
  `%{label: label_or_nil, value: iso_value}`:

      <.date_picker id="when">
        <:trigger :let={picker}>{picker.label || "Whenever"}</:trigger>
      </.date_picker>

  ## Composing it yourself

  As in shadcn, you can also build one from `popover/1` and `calendar/1`;
  then the trigger label comes from your own assigns (for example the form
  field value after `phx-change`, or an `on-select` handler):

      <.popover id="date-popover">
        <.popover_trigger as={&button/1} variant="outline" class="w-[212px] justify-between font-normal">
          {if @date, do: Calendar.strftime(@date, "%B %-d, %Y"), else: "Pick a date"}
        </.popover_trigger>
        <.popover_content class="w-auto p-0" align="start">
          <.calendar id="date-calendar" value={@date} on-select="date_picked" close-on-select />
        </.popover_content>
      </.popover>

  ## Component events

  * `:on-select` - See `SaladUI.Calendar`.
  """
  use SaladUI, :component

  @doc """
  Renders a date picker.

  Accepts every option of `SaladUI.Calendar.calendar/1`, plus:

  * `:placeholder` - Trigger text when nothing is selected. Defaults to `"Pick a date"`.
  * `:format` - A `Calendar.strftime/2` format or a 1-arity function formatting each date in the trigger.
    Defaults to `"January 5th, 2025"` for one date and `"Jan 05, 2025 - Jan 25, 2025"` for a range.
  * `:icon` - `calendar` (leading icon, default), `chevron` (trailing chevron) or `none`.
  * `:close-on-select` - Close the popover after a pick. Defaults to `true` in `single` mode.
  * `:align` / `:side` - Popover placement. Defaults to `start` / `bottom`.
  * `:trigger-class`, `:content-class`, `:calendar-class` - Classes for the trigger, popover content and calendar.
  * `:class` - Classes for the wrapper.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the date picker"
  attr :mode, :string, values: ~w(single multiple range), default: "single", doc: "Selection mode"
  attr :value, :any, default: nil, doc: "Selected date(s): Date, list of dates or %{from:, to:}"
  attr :field, Phoenix.HTML.FormField, doc: "A form field struct, for example: @form[:date]"
  attr :name, :string, default: nil, doc: "Name of the hidden inputs"
  attr :placeholder, :string, default: "Pick a date", doc: "Trigger text when nothing is selected"
  attr :format, :any, default: nil, doc: "strftime format or function for the trigger label"
  attr :icon, :string, values: ~w(calendar chevron none), default: "calendar", doc: "Trigger icon"
  attr :"close-on-select", :boolean, default: nil, doc: "Close the popover after a pick"
  attr :align, :string, values: ~w(start center end), default: "start"
  attr :side, :string, values: ~w(top right bottom left), default: "bottom"
  attr :"trigger-class", :any, default: nil
  attr :"content-class", :any, default: nil
  attr :"calendar-class", :any, default: nil
  attr :month, :any, default: nil, doc: "Visible month (controlled)"
  attr :"default-month", :any, default: nil, doc: "Initially visible month"
  attr :min, :any, default: nil, doc: "Earliest selectable date"
  attr :max, :any, default: nil, doc: "Latest selectable date"
  attr :"start-month", :any, default: nil, doc: "Earliest month to navigate to"
  attr :"end-month", :any, default: nil, doc: "Latest month to navigate to"
  attr :disabled, :any, default: nil, doc: "Matcher for disabled days, or true"
  attr :required, :boolean, default: false, doc: "Whether the selection can be cleared"
  attr :"week-starts-on", :integer, default: 0, values: 0..6, doc: "First day of the week, 0 is Sunday"
  attr :"number-of-months", :integer, default: 1, doc: "Number of months to show"
  attr :"show-outside-days", :boolean, default: true, doc: "Show days of adjacent months"
  attr :"fixed-weeks", :boolean, default: false, doc: "Always render six weeks"
  attr :"show-week-number", :boolean, default: false, doc: "Show week numbers"

  attr :"caption-layout", :string,
    values: ~w(label dropdown dropdown-months dropdown-years),
    default: "label",
    doc: "Month caption: a label or month/year dropdowns"

  attr :modifiers, :map, default: %{}, doc: "Named day matchers"
  attr :"modifiers-class", :map, default: %{}, doc: "Classes per modifier name"
  attr :presets, :list, default: [], doc: "Quick-pick buttons: [%{label:, value:}]"
  attr :today, :any, default: nil, doc: "Override today's date"
  attr :"month-names", :list, default: nil, doc: "12 month names"

  attr :"month-dropdown-format", :string,
    values: ~w(short long),
    default: "short",
    doc: "Month names in the month dropdown"

  attr :"weekday-names", :list, default: nil, doc: "7 short weekday names, Sunday first"
  attr :"button-variant", :string, default: "ghost", doc: "Variant of the navigation buttons"
  attr :"on-select", :any, default: nil, doc: "Handler for the select event"
  attr :class, :string, default: nil
  attr :rest, :global

  slot :trigger, doc: "Custom trigger content; receives %{label:, value:}"
  slot :day, doc: "Custom day content; receives the day map"

  def date_picker(assigns) do
    close? =
      case assigns[:"close-on-select"] do
        nil -> assigns.mode == "single"
        value -> value
      end

    opts =
      assigns
      |> assign(:"close-on-select", close?)
      |> SaladUI.Calendar.component_opts()

    assigns = assign(assigns, :opts, opts)

    ~H"""
    <.live_component
      module={SaladUI.Calendar.LiveComponent}
      id={@id}
      kind="date-picker"
      opts={@opts}
      day={@day}
      trigger={@trigger}
    />
    """
  end
end
