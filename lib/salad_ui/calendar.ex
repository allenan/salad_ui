defmodule SaladUI.Calendar do
  @moduledoc """
  Implementation of the calendar component from https://ui.shadcn.com/docs/components/calendar

  A month grid for picking a single date, several dates, or a date range. The
  grid is rendered on the server: `calendar/1` renders a LiveComponent
  (`SaladUI.Calendar.LiveComponent`) that keeps the visible month and the
  selection, so month navigation and day clicks re-render the grid over the
  LiveView socket. A small JS hook adds the keyboard grid navigation and focus
  management. Because it is a LiveComponent, the calendar must be rendered
  inside a LiveView.

  Dates are plain `Date` structs, so there is no time zone offset to worry
  about. Wherever a date is accepted you may also pass an ISO 8601 string
  (`"2025-06-12"`).

  ## Examples

      <.calendar id="calendar" class="rounded-lg border" />

      <.calendar id="dob" caption-layout="dropdown" value={~D[1990-04-12]} />

      <.calendar
        id="trip"
        mode="range"
        number-of-months={2}
        value={%{from: ~D[2025-01-12], to: ~D[2025-02-11]}}
        disabled={fn date -> Date.after?(date, Date.utc_today()) end}
      />

      <.calendar id="days-off" mode="multiple" week-starts-on={1} show-week-number />

  ## Forms

  Pass a `field` (or a `name`) and the selection is submitted as ISO 8601 date
  strings in hidden inputs:

  * `single` - `name=2025-06-12` (`""` when empty).
  * `multiple` - `name[]=2025-06-12&name[]=2025-06-14` (`name=""` when empty).
  * `range` - `name[from]=2025-06-12&name[to]=2025-06-20`.

  After each selection made by the user the hook fires an `input` event on the
  hidden input, so the surrounding form's `phx-change` runs. Values coming back
  from the form params (ISO strings) are parsed again, so
  `<.calendar field={@form[:date]} />` round-trips without extra code.

      <.form for={@form} phx-change="validate">
        <.calendar id="booking-date" field={@form[:date]} />
      </.form>

  ## Disabled dates and modifiers

  `disabled`, `min`/`max` and the entries of `modifiers` take *matchers*. A
  matcher is any of:

  * a `Date` (or ISO string) or a list of matchers,
  * a `Date.Range`,
  * `%{from: date, to: date}` - an inclusive range,
  * `%{before: date}` / `%{after: date}` - every day before/after a date,
  * `%{day_of_week: [0, 6]}` - weekdays, `0` is Sunday,
  * a 1-arity function returning a boolean,
  * `true` - matches every day.

  `modifiers` names extra day states; each named day gets `data-<name>="true"`
  and the classes in `modifiers-class`:

      <.calendar
        id="booked"
        disabled={@booked}
        modifiers={%{booked: @booked}}
        modifiers-class={%{booked: "[&>button]:line-through opacity-100"}}
      />

  ## Custom day content

  The `day` slot replaces the content of every day button. It receives a map
  with `:date`, `:outside`, `:today`, `:selected`, `:disabled`, `:range_start`,
  `:range_middle` and `:range_end`:

      <.calendar id="prices" class="[--cell-size:--spacing(12)]">
        <:day :let={day}>
          {day.date.day}
          <span :if={!day.outside}>{if Date.day_of_week(day.date) > 5, do: "$120", else: "$100"}</span>
        </:day>
      </.calendar>

  ## Cell size

  The grid sizes itself from the `--cell-size` CSS variable, which you can
  override (also per breakpoint) through `class`:
  `class="[--cell-size:--spacing(11)] md:[--cell-size:--spacing(12)]"`.

  ## Keyboard

  Arrow keys move by day/week, `PageUp`/`PageDown` by month (with `Shift`, by
  year), `Home`/`End` to the start/end of the week, `Enter`/`Space` select.
  Moving past the visible months navigates. Disabled days are skipped. Arrow
  keys are mirrored under `dir="rtl"`.

  ## Component events

  * `:on-select` - Maps the `select` event, fired after the user changes the
    selection. The payload is `%{"id" => id, "value" => value}` where `value`
    is an ISO date string (or `nil`), a list of them, or
    `%{"from" => ..., "to" => ...}`. A string is pushed to the parent LiveView
    (or the parent LiveComponent), a `Phoenix.LiveView.JS` command is executed.
  """
  use SaladUI, :component

  @doc """
  Renders a calendar.

  ## Options

  * `:id` - Required unique identifier (also the LiveComponent id).
  * `:mode` - `single` (default), `multiple` or `range`.
  * `:value` - The selection: a date, a list of dates, or `%{from:, to:}` (also a `Date.Range`).
    When the value passed in changes, it replaces the selection.
  * `:field` - A `Phoenix.HTML.FormField`; provides name, value and errors.
  * `:name` - Name for the hidden inputs.
  * `:month` - The month to show. When it changes, the calendar navigates to it.
  * `:default-month` - The month to show first. Defaults to the selection, then today.
  * `:min` / `:max` - Earliest/latest selectable date; also limits navigation.
  * `:start-month` / `:end-month` - Limit navigation (and the year dropdown) without disabling days.
  * `:disabled` - Matcher for days that cannot be selected, or `true` to disable the whole calendar.
  * `:required` - Prevents clearing the selection by clicking a selected day.
  * `:week-starts-on` - `0` (Sunday, default) to `6`.
  * `:number-of-months` - Months shown side by side. Defaults to `1`.
  * `:show-outside-days` - Show days of the adjacent months. Defaults to `true`.
  * `:fixed-weeks` - Always render six weeks.
  * `:show-week-number` - Add a week-number column.
  * `:caption-layout` - `label` (default), `dropdown`, `dropdown-months` or `dropdown-years`.
  * `:modifiers` / `:modifiers-class` - Extra day states and their classes (see moduledoc).
  * `:presets` - Quick picks rendered as buttons under the grid: a list of `%{label:, value:}`,
    where `value` is a day offset from today (integer), a date, a list or a range.
  * `:close-on-select` - Close the surrounding `popover/1` when a date (single) or a full range is picked.
  * `:today` - Overrides today's date, e.g. to use the user's time zone.
  * `:month-names` - 12 month names, for localization.
  * `:month-dropdown-format` - `short` (default, `Jun`) or `long` (`June`) names in the month dropdown.
  * `:weekday-names` - 7 short weekday names starting on Sunday, for localization.
  * `:button-variant` - Button variant for the navigation buttons. Defaults to `ghost`.
  * `:on-select` - Handler for the `select` event.
  * `:class` - Additional CSS classes.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the calendar"
  attr :mode, :string, values: ~w(single multiple range), default: "single", doc: "Selection mode"
  attr :value, :any, default: nil, doc: "Selected date(s): Date, list of dates or %{from:, to:}"
  attr :field, Phoenix.HTML.FormField, doc: "A form field struct, for example: @form[:date]"
  attr :name, :string, default: nil, doc: "Name of the hidden inputs"
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
  attr :"close-on-select", :boolean, default: false, doc: "Close the surrounding popover after a pick"
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

  slot :day, doc: "Custom day content; receives the day map"

  def calendar(assigns) do
    assigns = assign(assigns, :opts, component_opts(assigns))

    ~H"""
    <.live_component
      module={SaladUI.Calendar.LiveComponent}
      id={@id}
      kind="calendar"
      opts={@opts}
      day={@day}
    />
    """
  end

  @doc false
  # Shared by calendar/1 and SaladUI.DatePicker.date_picker/1: resolves the form
  # field and collects every option the LiveComponent needs into one map.
  def component_opts(assigns) do
    assigns = prepare_assign(assigns)

    assigns
    |> Map.drop([:__changed__, :id, :day, :field, :inner_block, :trigger])
    |> Map.put(:invalid, invalid?(assigns))
    |> Map.put(:event_map, event_mappings(assigns))
  end
end

defmodule SaladUI.Calendar.LiveComponent do
  @moduledoc """
  The LiveComponent behind `SaladUI.Calendar.calendar/1` and
  `SaladUI.DatePicker.date_picker/1`. It keeps the visible month and the
  selection and renders the month grid. Render it through those function
  components rather than directly.
  """
  use Phoenix.LiveComponent

  import SaladUI.Button
  import SaladUI.Helpers
  import SaladUI.Popover

  @month_names ~w(January February March April May June July August September October November December)
  @weekday_names ~w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
  @weekday_short ~w(Su Mo Tu We Th Fr Sa)

  defp weekday_name(dow), do: Enum.at(@weekday_names, dow)

  defp classes(input), do: TwMerge.merge(List.flatten(input))

  # -- lifecycle ---------------------------------------------------------------

  @impl true
  def update(%{opts: raw} = assigns, socket) do
    o = normalize_opts(raw)
    first? = not Map.has_key?(socket.assigns, :selected)
    raw_value = Map.get(raw, :value)
    raw_month = o.month

    selected =
      if first? or raw_value != socket.assigns.value_in,
        do: normalize_value(o.mode, raw_value),
        else: socket.assigns.selected

    month = visible_month(first?, raw_month, selected, o, socket.assigns)

    socket =
      socket
      |> assign(Map.take(assigns, [:id, :kind]))
      |> assign(:day_slot, Map.get(assigns, :day, []))
      |> assign(:trigger_slot, Map.get(assigns, :trigger, []))
      |> assign(:o, o)
      |> assign(:value_in, raw_value)
      |> assign(:month_in, raw_month)
      |> assign(:selected, selected)
      |> assign(:month, clamp_month(month, o))
      |> assign_new(:focus, fn -> nil end)

    {:ok, socket}
  end

  # The month to show after an update: the requested one on mount, or when the
  # controlled `month` changed; otherwise wherever the user navigated to.
  defp visible_month(true, _raw_month, selected, o, _assigns) do
    Enum.find([o.month, o.default_month, first_selected(o.mode, selected)], o.today, & &1)
  end

  defp visible_month(false, nil, _selected, _o, assigns), do: assigns.month
  defp visible_month(false, raw_month, _selected, _o, %{month_in: raw_month} = assigns), do: assigns.month
  defp visible_month(false, raw_month, _selected, _o, _assigns), do: raw_month

  @impl true
  def handle_event("select", %{"date" => iso}, socket) do
    o = socket.assigns.o

    case to_date(iso) do
      %Date{} = date ->
        if disabled?(date, o) do
          {:noreply, socket}
        else
          selected = toggle(o.mode, socket.assigns.selected, date, o.required)
          {:noreply, assign(socket, selected: selected, focus: date)}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("navigate", %{"offset" => offset}, socket) do
    offset = to_int(offset)
    o = socket.assigns.o
    target = shift_month(socket.assigns.month, offset)

    if navigable?(target, o) do
      {:noreply, assign(socket, month: clamp_month(target, o), focus: nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("goto", %{"month" => month} = params, socket) do
    o = socket.assigns.o

    case to_month(month) do
      %Date{} = target ->
        target = shift_month(target, -to_int(params["index"] || 0))
        {:noreply, assign(socket, month: clamp_month(target, o), focus: nil)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("focus", %{"date" => iso} = params, socket) do
    o = socket.assigns.o
    dir = if to_int(params["dir"] || 1) < 0, do: -1, else: 1

    case to_date(iso) do
      %Date{} = date ->
        date = date |> clamp_date(o) |> skip_disabled(dir, o)
        month = month_showing(date, socket.assigns.month, o.number_of_months)
        {:noreply, assign(socket, month: clamp_month(month, o), focus: date)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("preset", %{"index" => index}, socket) do
    o = socket.assigns.o

    case Enum.at(o.presets, to_int(index)) do
      nil ->
        {:noreply, socket}

      preset ->
        selected = preset_value(o.mode, preset_field(preset, :value), o.today)

        month =
          case first_selected(o.mode, selected) do
            nil -> socket.assigns.month
            date -> month_showing(date, socket.assigns.month, o.number_of_months)
          end

        {:noreply,
         assign(socket,
           selected: selected,
           month: clamp_month(month, o),
           focus: first_selected(o.mode, selected)
         )}
    end
  end

  # -- rendering ---------------------------------------------------------------

  @impl true
  def render(%{kind: "date-picker"} = assigns) do
    calendar_id = "#{assigns.id}-calendar"

    assigns =
      assigns
      |> assign(:g, grid(assigns, calendar_id, assigns.o.calendar_class, %{}))
      |> assign(:label, picker_label(assigns.o, assigns.selected))

    ~H"""
    <div id={@id} data-slot="date-picker" class={classes(["inline-block", @o.class])} {@o.rest}>
      <.popover id={"#{@id}-popover"}>
        <.popover_trigger
          as={&button/1}
          id={"#{@id}-trigger"}
          data-empty={if is_nil(@label), do: "true", else: "false"}
          aria-invalid={@o.invalid && "true"}
          {%{variant: "outline", disabled: @o.disabled == true}}
          class={
            classes([
              "w-[240px] justify-start text-left font-normal data-[empty=true]:text-muted-foreground",
              @o.icon == "chevron" && "justify-between",
              @o.trigger_class
            ])
          }
        >
          <%= if @trigger_slot != [] do %>
            {render_slot(@trigger_slot, %{label: @label, value: value_payload(@o.mode, @selected)})}
          <% else %>
            <.calendar_icon :if={@o.icon == "calendar"} />
            <span class="truncate">{@label || @o.placeholder}</span>
            <.chevron_icon :if={@o.icon == "chevron"} direction="down" class="text-muted-foreground" />
          <% end %>
        </.popover_trigger>
        <.popover_content
          align={@o.align}
          side={@o.side}
          class={classes(["w-auto overflow-hidden p-0", @o.content_class])}
        >
          <div {@g.root_attrs}>
            <.calendar_body g={@g} o={@o} selected={@selected} myself={@myself} day_slot={@day_slot} />
          </div>
        </.popover_content>
      </.popover>
      <.hidden_inputs id={"#{@g.id}-value"} o={@o} selected={@selected} />
    </div>
    """
  end

  def render(assigns) do
    assigns = assign(assigns, :g, grid(assigns, assigns.id, assigns.o.class, assigns.o.rest))

    ~H"""
    <div {@g.root_attrs}>
      <.calendar_body g={@g} o={@o} selected={@selected} myself={@myself} day_slot={@day_slot} />
      <.hidden_inputs id={"#{@g.id}-value"} o={@o} selected={@selected} />
    </div>
    """
  end

  # Everything the month grid needs, plus the attributes of the calendar root.
  defp grid(assigns, id, class, rest) do
    %{o: o, month: month, selected: selected, focus: focus} = assigns
    months = Enum.map(0..(o.number_of_months - 1), &shift_month(month, &1))
    visible = {List.first(months), Date.end_of_month(List.last(months))}

    js_options = %{
      mode: o.mode,
      weekStartsOn: o.week_starts_on,
      closeOnSelect: o.close_on_select,
      min: o.min && Date.to_iso8601(o.min),
      max: o.max && Date.to_iso8601(o.max),
      inputs: "#{id}-value"
    }

    root_attrs =
      Map.merge(rest, %{
        id: id,
        "data-slot": "calendar",
        "data-component": "calendar",
        "data-part": "root",
        "data-state": "idle",
        "data-mode": o.mode,
        "data-value": json(value_payload(o.mode, selected)),
        "data-options": json(js_options),
        "data-event-mappings": json(o.event_map),
        "phx-hook": "SaladUI",
        class:
          classes([
            "group/calendar w-fit bg-background p-3 [--cell-size:--spacing(8)] [[data-slot=card-content]_&]:bg-transparent [[data-slot=popover-content]_&]:bg-transparent",
            class
          ])
      })

    %{
      id: id,
      root_attrs: root_attrs,
      months: months,
      tab_date: tab_date(focus, selected, visible, o),
      prev_disabled: not navigable?(shift_month(month, -1), o),
      next_disabled: not navigable?(shift_month(month, 1), o),
      nav_class: nav_button_class(o.button_variant),
      day_button_class: day_button_class()
    }
  end

  attr :g, :map, required: true
  attr :o, :map, required: true
  attr :selected, :any
  attr :myself, :any
  attr :day_slot, :list

  defp calendar_body(assigns) do
    ~H"""
    <div data-slot="calendar-months" class="relative flex flex-col gap-4 md:flex-row">
      <nav
        data-slot="calendar-nav"
        aria-label="Navigation bar"
        class="absolute inset-x-0 top-0 flex w-full items-center justify-between gap-1"
      >
        <button
          type="button"
          data-slot="calendar-previous"
          data-part="previous"
          aria-label="Go to the Previous Month"
          aria-disabled={@g.prev_disabled && "true"}
          phx-click={!@g.prev_disabled && "navigate"}
          phx-value-offset="-1"
          phx-target={@myself}
          class={@g.nav_class}
        >
          <.chevron_icon direction="left" class="size-4 rtl:rotate-180" />
        </button>
        <button
          type="button"
          data-slot="calendar-next"
          data-part="next"
          aria-label="Go to the Next Month"
          aria-disabled={@g.next_disabled && "true"}
          phx-click={!@g.next_disabled && "navigate"}
          phx-value-offset="1"
          phx-target={@myself}
          class={@g.nav_class}
        >
          <.chevron_icon direction="right" class="size-4 rtl:rotate-180" />
        </button>
      </nav>
      <div
        :for={{month, index} <- Enum.with_index(@g.months)}
        data-slot="calendar-month"
        class="flex w-full flex-col gap-4"
      >
        <.caption o={@o} month={month} index={index} />
        <table
          role="grid"
          data-part="grid"
          aria-label={month_caption(month, @o)}
          aria-multiselectable={@o.mode != "single" && "true"}
          class="w-full border-collapse"
        >
          <thead aria-hidden="true">
            <tr class="flex">
              <th :if={@o.show_week_number} class="w-(--cell-size) select-none"></th>
              <th
                :for={dow <- weekdays(@o.week_starts_on)}
                scope="col"
                aria-label={weekday_name(dow)}
                class="flex-1 rounded-md text-[0.8rem] font-normal text-muted-foreground select-none"
              >
                {Enum.at(@o.weekday_names, dow)}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              :for={week <- month_weeks(month, @o.week_starts_on, @o.fixed_weeks)}
              class="mt-2 flex w-full"
            >
              <td :if={@o.show_week_number} class="text-[0.8rem] text-muted-foreground select-none">
                <div class="flex size-(--cell-size) items-center justify-center text-center">
                  {week_number(hd(week), @o.week_starts_on)}
                </div>
              </td>
              <.day
                :for={date <- week}
                day={day_info(date, month, @selected, @o)}
                o={@o}
                tab_date={@g.tab_date}
                myself={@myself}
                day_slot={@day_slot}
                button_class={@g.day_button_class}
              />
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <div
      :if={@o.presets != []}
      data-slot="calendar-presets"
      class="mt-3 flex w-0 min-w-full flex-wrap gap-2 border-t pt-3"
    >
      <.button
        :for={{preset, index} <- Enum.with_index(@o.presets)}
        type="button"
        variant="outline"
        size="sm"
        class="flex-1"
        data-preset={index}
        phx-click="preset"
        phx-value-index={index}
        phx-target={@myself}
        disabled={@o.disabled == true}
      >
        {preset_field(preset, :label)}
      </.button>
    </div>
    """
  end

  attr :o, :map
  attr :month, Date
  attr :index, :integer

  defp caption(%{o: %{caption_layout: "label"}} = assigns) do
    ~H"""
    <div
      data-slot="calendar-caption"
      class="flex h-(--cell-size) w-full items-center justify-center px-(--cell-size)"
    >
      <span role="status" aria-live="polite" class="text-sm font-medium select-none">
        {month_caption(@month, @o)}
      </span>
    </div>
    """
  end

  defp caption(assigns) do
    o = assigns.o
    {start_month, end_month} = nav_bounds(o)
    years = Enum.to_list(start_month.year..end_month.year)

    assigns =
      assigns
      |> assign(:years, years)
      |> assign(:start_month, start_month)
      |> assign(:end_month, end_month)
      |> assign(:show_months, o.caption_layout in ["dropdown", "dropdown-months"])
      |> assign(:show_years, o.caption_layout in ["dropdown", "dropdown-years"])

    ~H"""
    <div
      data-slot="calendar-caption"
      class="flex h-(--cell-size) w-full items-center justify-center px-(--cell-size)"
    >
      <span role="status" aria-live="polite" class="sr-only">{month_caption(@month, @o)}</span>
      <div
        data-slot="calendar-dropdowns"
        class="flex h-(--cell-size) w-full items-center justify-center gap-1.5 text-sm font-medium"
      >
        <span
          :if={@show_months}
          data-slot="calendar-dropdown"
          class="relative rounded-md border border-input shadow-xs has-focus:border-ring has-focus:ring-[3px] has-focus:ring-ring/50"
        >
          <select
            data-part="month-select"
            data-index={@index}
            data-year={@month.year}
            aria-label="Choose the Month"
            class="absolute inset-0 bg-popover opacity-0"
          >
            <option
              :for={m <- 1..12}
              value={m}
              selected={m == @month.month}
              disabled={not month_in_bounds?(Date.new!(@month.year, m, 1), @start_month, @end_month)}
            >
              {dropdown_month(m, @o)}
            </option>
          </select>
          <span
            aria-hidden="true"
            class="flex h-8 items-center gap-1 rounded-md pr-1 pl-2 text-sm font-medium select-none [&>svg]:size-3.5 [&>svg]:text-muted-foreground"
          >
            {dropdown_month(@month.month, @o)}<.chevron_icon direction="down" />
          </span>
        </span>
        <span :if={!@show_months} class="text-sm font-medium select-none">{month_name(
          @month.month,
          @o
        )}</span>
        <span
          :if={@show_years}
          data-slot="calendar-dropdown"
          class="relative rounded-md border border-input shadow-xs has-focus:border-ring has-focus:ring-[3px] has-focus:ring-ring/50"
        >
          <select
            data-part="year-select"
            data-index={@index}
            data-month={@month.month}
            aria-label="Choose the Year"
            class="absolute inset-0 bg-popover opacity-0"
          >
            <option :for={y <- @years} value={y} selected={y == @month.year}>{y}</option>
          </select>
          <span
            aria-hidden="true"
            class="flex h-8 items-center gap-1 rounded-md pr-1 pl-2 text-sm font-medium select-none [&>svg]:size-3.5 [&>svg]:text-muted-foreground"
          >
            {@month.year}<.chevron_icon direction="down" />
          </span>
        </span>
        <span :if={!@show_years} class="text-sm font-medium select-none">{@month.year}</span>
      </div>
    </div>
    """
  end

  attr :day, :map
  attr :o, :map
  attr :tab_date, :any
  attr :myself, :any
  attr :day_slot, :list
  attr :button_class, :string

  defp day(assigns) do
    day = assigns.day
    o = assigns.o

    selected_single =
      day.selected and not day.range_start and not day.range_end and not day.range_middle

    assigns =
      assigns
      |> assign(:iso, Date.to_iso8601(day.date))
      |> assign(:selected_single, selected_single)
      |> assign(:td_class, day_cell_class(day, o))
      |> assign(:modifier_attrs, Map.new(day.modifiers, &{:"data-#{&1}", "true"}))

    ~H"""
    <td
      role="gridcell"
      data-day={@iso}
      data-selected={@day.selected && "true"}
      data-disabled={@day.disabled && "true"}
      data-outside={@day.outside && "true"}
      data-hidden={@day.hidden && "true"}
      data-today={@day.today && "true"}
      aria-selected={@day.selected && "true"}
      class={@td_class}
      {@modifier_attrs}
    >
      <button
        :if={!@day.hidden}
        type="button"
        data-slot="calendar-day-button"
        data-day={@iso}
        data-selected-single={@selected_single && "true"}
        data-range-start={@day.range_start && "true"}
        data-range-end={@day.range_end && "true"}
        data-range-middle={@day.range_middle && "true"}
        tabindex={if @day.date == @tab_date, do: "0", else: "-1"}
        disabled={@day.disabled}
        aria-label={day_label(@day, @o)}
        phx-click="select"
        phx-value-date={@iso}
        phx-target={@myself}
        class={@button_class}
      >
        <%= if @day_slot != [] do %>
          {render_slot(@day_slot, @day)}
        <% else %>
          {@day.date.day}
        <% end %>
      </button>
    </td>
    """
  end

  attr :id, :string
  attr :o, :map
  attr :selected, :any

  defp hidden_inputs(%{o: %{name: nil}} = assigns) do
    ~H""
  end

  defp hidden_inputs(assigns) do
    ~H"""
    <div id={@id} data-slot="calendar-value" hidden>
      <%= case @o.mode do %>
        <% "single" -> %>
          <input type="hidden" name={@o.name} value={iso(@selected)} />
        <% "multiple" -> %>
          <input :if={@selected in [nil, []]} type="hidden" name={@o.name} value="" />
          <input
            :for={date <- @selected || []}
            type="hidden"
            name={@o.name <> "[]"}
            value={iso(date)}
          />
        <% "range" -> %>
          <input type="hidden" name={@o.name <> "[from]"} value={iso(@selected && @selected.from)} />
          <input type="hidden" name={@o.name <> "[to]"} value={iso(@selected && @selected.to)} />
      <% end %>
    </div>
    """
  end

  attr :direction, :string, values: ~w(left right down)
  attr :class, :string, default: nil

  defp chevron_icon(assigns) do
    assigns =
      assign(assigns, :path, %{"left" => "m15 18-6-6 6-6", "right" => "m9 18 6-6-6-6", "down" => "m6 9 6 6 6-6"})

    ~H"""
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
      class={["lucide lucide-chevron-#{@direction}", @class]}
    >
      <path d={@path[@direction]} />
    </svg>
    """
  end

  defp calendar_icon(assigns) do
    ~H"""
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
      class="lucide lucide-calendar"
    >
      <path d="M8 2v4" /><path d="M16 2v4" /><rect width="18" height="18" x="3" y="4" rx="2" /><path d="M3 10h18" />
    </svg>
    """
  end

  # -- classes -----------------------------------------------------------------

  defp nav_button_class(variant) do
    classes([
      button_variant(%{variant: variant}),
      "size-[var(--cell-size)] p-0 select-none aria-disabled:opacity-50"
    ])
  end

  defp day_button_class do
    classes([
      button_variant(%{variant: "ghost", size: "icon"}),
      "flex aspect-square size-auto w-full min-w-(--cell-size) flex-col gap-1 leading-none font-normal group-data-[focused=true]/day:relative group-data-[focused=true]/day:z-10 group-data-[focused=true]/day:border-ring group-data-[focused=true]/day:ring-[3px] group-data-[focused=true]/day:ring-ring/50 data-[range-end=true]:rounded-md data-[range-end=true]:rounded-e-md data-[range-end=true]:bg-primary data-[range-end=true]:text-primary-foreground data-[range-middle=true]:rounded-none data-[range-middle=true]:bg-accent data-[range-middle=true]:text-accent-foreground data-[range-start=true]:rounded-md data-[range-start=true]:rounded-s-md data-[range-start=true]:bg-primary data-[range-start=true]:text-primary-foreground data-[selected-single=true]:bg-primary data-[selected-single=true]:text-primary-foreground dark:hover:text-accent-foreground [&>span]:text-xs [&>span]:opacity-70"
    ])
  end

  # Mirrors react-day-picker: modifier classes are appended in order, not
  # tw-merged, so CSS source order decides between e.g. today and range_start.
  defp day_cell_class(day, o) do
    [
      "group/day relative aspect-square h-full w-full p-0 text-center select-none [&:last-child[data-selected=true]_button]:rounded-e-md",
      if(o.show_week_number,
        do: "[&:nth-child(2)[data-selected=true]_button]:rounded-s-md",
        else: "[&:first-child[data-selected=true]_button]:rounded-s-md"
      ),
      day.range_start && "rounded-s-md bg-accent",
      day.range_middle && "rounded-none",
      day.range_end && "rounded-e-md bg-accent",
      day.today && "rounded-md bg-accent text-accent-foreground data-[selected=true]:rounded-none",
      day.outside && "text-muted-foreground aria-selected:text-muted-foreground",
      day.disabled && "text-muted-foreground opacity-50",
      day.hidden && "invisible"
      | Enum.map(day.modifiers, &modifier_class(o, &1))
    ]
    |> Enum.filter(&is_binary/1)
    |> Enum.join(" ")
  end

  defp modifier_class(o, name) do
    Map.get(o.modifiers_class, name) || Map.get(o.modifiers_class, to_string(name))
  end

  # -- options -----------------------------------------------------------------

  @doc false
  def normalize_opts(raw) do
    %{
      mode: opt(raw, :mode, "single"),
      name: raw[:name],
      today: raw[:today] |> to_date() |> opt_date(Date.utc_today()),
      month: to_month(raw[:month]),
      default_month: to_month(raw[:"default-month"]),
      min: to_date(raw[:min]),
      max: to_date(raw[:max]),
      start_month: to_month(raw[:"start-month"]),
      end_month: to_month(raw[:"end-month"]),
      disabled: raw[:disabled],
      required: raw[:required] == true,
      week_starts_on: opt(raw, :"week-starts-on", 0),
      number_of_months: max(opt(raw, :"number-of-months", 1), 1),
      show_outside_days: raw[:"show-outside-days"] != false,
      fixed_weeks: raw[:"fixed-weeks"] == true,
      show_week_number: raw[:"show-week-number"] == true,
      caption_layout: opt(raw, :"caption-layout", "label"),
      modifiers: opt(raw, :modifiers, %{}),
      modifiers_class: opt(raw, :"modifiers-class", %{}),
      presets: opt(raw, :presets, []),
      close_on_select: close_on_select(raw),
      month_names: opt(raw, :"month-names", @month_names),
      month_dropdown_format: opt(raw, :"month-dropdown-format", "short"),
      weekday_names: opt(raw, :"weekday-names", @weekday_short),
      button_variant: opt(raw, :"button-variant", "ghost"),
      event_map: opt(raw, :event_map, %{}),
      invalid: raw[:invalid] == true,
      class: raw[:class],
      rest: opt(raw, :rest, %{}),
      # date picker only
      placeholder: opt(raw, :placeholder, "Pick a date"),
      format: raw[:format],
      icon: opt(raw, :icon, "calendar"),
      align: opt(raw, :align, "start"),
      side: opt(raw, :side, "bottom"),
      trigger_class: raw[:"trigger-class"],
      content_class: raw[:"content-class"],
      calendar_class: raw[:"calendar-class"]
    }
  end

  defp opt_date(nil, default), do: default
  defp opt_date(date, _default), do: date

  defp opt(raw, key, default) do
    case raw[key] do
      nil -> default
      value -> value
    end
  end

  defp close_on_select(raw) do
    case raw[:"close-on-select"] do
      nil -> false
      value -> value == true
    end
  end

  # -- dates -------------------------------------------------------------------

  @doc false
  def to_date(%Date{} = date), do: date
  def to_date(%DateTime{} = dt), do: DateTime.to_date(dt)
  def to_date(%NaiveDateTime{} = dt), do: NaiveDateTime.to_date(dt)

  def to_date(value) when is_binary(value) do
    case Date.from_iso8601(String.slice(value, 0, 10)) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  def to_date(_), do: nil

  @doc false
  def to_month(nil), do: nil

  def to_month(value) when is_binary(value) and byte_size(value) == 7, do: to_month(value <> "-01")

  def to_month(value) do
    case to_date(value) do
      nil -> nil
      date -> Date.beginning_of_month(date)
    end
  end

  defp iso(nil), do: ""
  defp iso(%Date{} = date), do: Date.to_iso8601(date)

  defp to_int(value) when is_integer(value), do: value

  defp to_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> 0
    end
  end

  defp to_int(_), do: 0

  @doc false
  def shift_month(%Date{} = month, offset) do
    total = month.year * 12 + month.month - 1 + offset
    Date.new!(div(total, 12), rem(total, 12) + 1, 1)
  end

  # 0 = Sunday .. 6 = Saturday
  defp dow(date), do: rem(Date.day_of_week(date), 7)

  defp weekdays(week_start), do: Enum.map(0..6, &rem(&1 + week_start, 7))

  @doc false
  def month_weeks(month, week_start, fixed?) do
    first = Date.beginning_of_month(month)
    last = Date.end_of_month(month)
    from = Date.add(first, -rem(dow(first) - week_start + 7, 7))
    to = Date.add(last, rem(week_start + 6 - dow(last) + 7, 7))
    weeks = from |> Date.range(to) |> Enum.chunk_every(7)

    if fixed? and length(weeks) < 6 do
      extra_from = Date.add(to, 1)
      extra = extra_from |> Date.range(Date.add(extra_from, 7 * (6 - length(weeks)) - 1)) |> Enum.chunk_every(7)
      weeks ++ extra
    else
      weeks
    end
  end

  # ISO weeks when the week starts on Monday; otherwise the week containing
  # January 1st is week 1 (date-fns' default for en-US).
  @doc false
  def week_number(week_first_day, 1) do
    {_year, week} = :calendar.iso_week_number(Date.to_erl(week_first_day))
    week
  end

  def week_number(week_first_day, week_start) do
    year = Date.add(week_first_day, 6).year
    year_start = start_of_week(Date.new!(year, 1, 1), week_start)

    year_start =
      if Date.before?(week_first_day, year_start),
        do: start_of_week(Date.new!(year - 1, 1, 1), week_start),
        else: year_start

    div(Date.diff(week_first_day, year_start), 7) + 1
  end

  defp start_of_week(date, week_start), do: Date.add(date, -rem(dow(date) - week_start + 7, 7))

  # -- navigation bounds -------------------------------------------------------

  defp nav_bounds(o) do
    years? = o.caption_layout in ["dropdown", "dropdown-years"]
    # react-day-picker's year dropdown runs from 100 years ago to this year;
    # without dropdowns navigation is effectively unbounded.
    last_year = if years?, do: o.today.year, else: o.today.year + 100

    {
      Enum.find([o.start_month, month_of(o.min)], Date.new!(o.today.year - 100, 1, 1), & &1),
      Enum.find([o.end_month, month_of(o.max)], Date.new!(last_year, 12, 1), & &1)
    }
  end

  defp month_of(nil), do: nil
  defp month_of(date), do: Date.beginning_of_month(date)

  defp month_in_bounds?(month, start_month, end_month) do
    not Date.before?(month, start_month) and not Date.after?(month, end_month)
  end

  defp navigable?(month, o) do
    {start_month, end_month} = nav_bounds(o)
    last = shift_month(month, o.number_of_months - 1)
    not Date.before?(month, start_month) and not Date.after?(last, end_month)
  end

  @doc false
  def clamp_month(month, o) do
    {start_month, end_month} = nav_bounds(o)
    month = Date.beginning_of_month(month)
    latest_first = shift_month(end_month, -(o.number_of_months - 1))

    cond do
      Date.after?(month, latest_first) and not Date.before?(latest_first, start_month) -> latest_first
      Date.before?(month, start_month) -> start_month
      true -> month
    end
  end

  # The first visible month to show `date`, moving as little as possible.
  defp month_showing(date, current, count) do
    target = Date.beginning_of_month(date)
    last = shift_month(current, count - 1)

    cond do
      Date.before?(target, current) -> target
      Date.after?(target, last) -> shift_month(target, -(count - 1))
      true -> current
    end
  end

  defp clamp_date(date, o) do
    cond do
      o.min && Date.before?(date, o.min) -> o.min
      o.max && Date.after?(date, o.max) -> o.max
      true -> date
    end
  end

  defp skip_disabled(date, dir, o, tries \\ 366)
  defp skip_disabled(date, _dir, _o, 0), do: date

  defp skip_disabled(date, dir, o, tries) do
    if disabled?(date, o) do
      next = Date.add(date, dir)
      if clamp_date(next, o) == next, do: skip_disabled(next, dir, o, tries - 1), else: date
    else
      date
    end
  end

  # -- matchers & selection ----------------------------------------------------

  @doc false
  def disabled?(date, o) do
    (o.min && Date.before?(date, o.min)) || (o.max && Date.after?(date, o.max)) ||
      matches?(date, o.disabled) || false
  end

  @doc false
  def matches?(_date, nil), do: false
  def matches?(_date, false), do: false
  def matches?(_date, true), do: true
  def matches?(date, %Date{} = other), do: date == other
  def matches?(date, %Date.Range{} = range), do: date in range
  def matches?(date, fun) when is_function(fun, 1), do: fun.(date) == true
  def matches?(date, list) when is_list(list), do: Enum.any?(list, &matches?(date, &1))
  def matches?(date, value) when is_binary(value), do: date == to_date(value)

  def matches?(date, %{} = matcher) do
    cond do
      Map.has_key?(matcher, :before) -> Date.before?(date, to_date(matcher.before))
      Map.has_key?(matcher, :after) -> Date.after?(date, to_date(matcher.after))
      Map.has_key?(matcher, :day_of_week) -> dow(date) in List.wrap(matcher.day_of_week)
      Map.has_key?(matcher, :from) -> in_range?(date, to_date(matcher.from), to_date(matcher[:to]))
      true -> false
    end
  end

  def matches?(_date, _), do: false

  defp in_range?(date, from, nil), do: date == from
  defp in_range?(_date, nil, _to), do: false
  defp in_range?(date, from, to), do: not Date.before?(date, from) and not Date.after?(date, to)

  @doc false
  def normalize_value(_mode, nil), do: nil

  def normalize_value("single", value) do
    case value do
      [first | _] -> to_date(first)
      %{} = map when not is_struct(map) -> to_date(get(map, :from))
      other -> to_date(other)
    end
  end

  def normalize_value("multiple", value) do
    value
    |> List.wrap()
    |> Enum.map(&to_date/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort(Date)
  end

  def normalize_value("range", %Date.Range{first: first, last: last}), do: order_range(first, last)

  def normalize_value("range", {from, to}), do: order_range(to_date(from), to_date(to))

  def normalize_value("range", %{} = map) when not is_struct(map) do
    order_range(to_date(get(map, :from)), to_date(get(map, :to)))
  end

  def normalize_value("range", value) do
    case to_date(value) do
      nil -> nil
      date -> %{from: date, to: date}
    end
  end

  defp get(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp order_range(nil, nil), do: nil
  defp order_range(nil, to), do: %{from: to, to: nil}
  defp order_range(from, nil), do: %{from: from, to: nil}

  defp order_range(from, to) do
    if Date.after?(from, to), do: %{from: to, to: from}, else: %{from: from, to: to}
  end

  @doc false
  # Mirrors react-day-picker's single/multiple selection and `addToRange`.
  def toggle("single", selected, date, required) do
    if selected == date and not required, do: nil, else: date
  end

  def toggle("multiple", selected, date, required) do
    selected = selected || []

    cond do
      date not in selected -> Enum.sort([date | selected], Date)
      required and length(selected) == 1 -> selected
      true -> List.delete(selected, date)
    end
  end

  def toggle("range", nil, date, _required), do: %{from: date, to: date}
  def toggle("range", %{from: from, to: nil}, date, _required), do: order_range(from, date)
  def toggle("range", %{from: date, to: date} = selected, date, required), do: if(required, do: selected)
  def toggle("range", %{from: from, to: to}, date, _required), do: extend_range(from, to, date)

  defp extend_range(from, _to, from), do: %{from: from, to: from}
  defp extend_range(_from, to, to), do: %{from: to, to: to}

  defp extend_range(from, to, date) do
    if Date.before?(date, from), do: %{from: date, to: to}, else: %{from: from, to: date}
  end

  defp first_selected(_mode, nil), do: nil
  defp first_selected("single", date), do: date
  defp first_selected("multiple", []), do: nil
  defp first_selected("multiple", [date | _]), do: date
  defp first_selected("range", %{from: from}), do: from

  defp selected?(_mode, nil, _date), do: false
  defp selected?("single", selected, date), do: selected == date
  defp selected?("multiple", selected, date), do: date in selected
  defp selected?("range", %{from: from, to: to}, date), do: in_range?(date, from, to)

  defp preset_field(preset, key) when is_map(preset), do: get(preset, key)
  defp preset_field({label, _value}, :label), do: label
  defp preset_field({_label, value}, :value), do: value

  @doc false
  def preset_value(mode, offset, today) when is_integer(offset) do
    date = Date.add(today, offset)

    case mode do
      "single" -> date
      "multiple" -> [date]
      "range" -> order_range(today, date)
    end
  end

  def preset_value(mode, value, _today), do: normalize_value(mode, value)

  # The single day button that is reachable with Tab (roving tabindex).
  defp tab_date(focus, selected, {first, last} = visible, o) do
    candidates =
      [focus] ++ selected_dates(selected) ++ [o.today]

    Enum.find(candidates, fn date ->
      date && in_range?(date, first, last) && !disabled?(date, o)
    end) || first |> Date.range(last) |> Enum.find(&(!disabled?(&1, o))) || elem(visible, 0)
  end

  defp selected_dates(nil), do: []
  defp selected_dates(%Date{} = date), do: [date]
  defp selected_dates(list) when is_list(list), do: list
  defp selected_dates(%{from: from, to: to}), do: Enum.reject([from, to], &is_nil/1)

  defp day_info(date, month, selected, o) do
    outside = date.month != month.month
    mode = o.mode
    selected? = selected?(mode, selected, date)

    {range_start, range_end, range_middle} =
      case {mode, selected} do
        {"range", %{from: from, to: to}} ->
          to = to || from
          start? = date == from
          end? = date == to
          {start?, end?, selected? and not start? and not end?}

        _ ->
          {false, false, false}
      end

    %{
      date: date,
      outside: outside,
      hidden: outside and not o.show_outside_days,
      today: date == o.today,
      selected: selected?,
      disabled: disabled?(date, o),
      range_start: range_start,
      range_end: range_end,
      range_middle: range_middle,
      modifiers: for({name, matcher} <- o.modifiers, matches?(date, matcher), do: name)
    }
  end

  @doc false
  def value_payload(_mode, nil), do: nil
  def value_payload("single", date), do: Date.to_iso8601(date)
  def value_payload("multiple", dates), do: Enum.map(dates, &Date.to_iso8601/1)

  def value_payload("range", %{from: from, to: to}) do
    %{from: from && Date.to_iso8601(from), to: to && Date.to_iso8601(to)}
  end

  # -- labels ------------------------------------------------------------------

  defp month_name(month, o), do: Enum.at(o.month_names, month - 1)
  defp short_month(month, o), do: month |> month_name(o) |> String.slice(0, 3)
  defp dropdown_month(month, %{month_dropdown_format: "long"} = o), do: month_name(month, o)
  defp dropdown_month(month, o), do: short_month(month, o)
  defp month_caption(date, o), do: "#{month_name(date.month, o)} #{date.year}"

  defp day_label(day, o) do
    date = day.date

    [
      day.today && "Today, ",
      Enum.at(@weekday_names, dow(date)),
      ", ",
      long_date(date, o),
      day.selected && ", selected"
    ]
    |> Enum.filter(&is_binary/1)
    |> Enum.join()
  end

  defp long_date(date, o), do: "#{month_name(date.month, o)} #{ordinal(date.day)}, #{date.year}"

  defp ordinal(day) when day in 11..13, do: "#{day}th"

  defp ordinal(day) do
    case rem(day, 10) do
      1 -> "#{day}st"
      2 -> "#{day}nd"
      3 -> "#{day}rd"
      _ -> "#{day}th"
    end
  end

  @doc false
  # The date picker trigger label: nil when nothing is selected.
  def picker_label(_o, nil), do: nil
  def picker_label(_o, []), do: nil
  def picker_label(o, %Date{} = date), do: format_date(date, o.format, &long_date(&1, o))

  def picker_label(o, dates) when is_list(dates) do
    case dates do
      [date] -> picker_label(o, date)
      dates -> "#{length(dates)} dates selected"
    end
  end

  def picker_label(o, %{from: from, to: to}) do
    short = &format_date(&1, o.format, fn d -> "#{short_month(d.month, o)} #{pad(d.day)}, #{d.year}" end)

    if to && to != from, do: "#{short.(from)} - #{short.(to)}", else: short.(from)
  end

  defp format_date(date, nil, default), do: default.(date)
  defp format_date(date, fun, _default) when is_function(fun, 1), do: fun.(date)
  defp format_date(date, format, _default) when is_binary(format), do: Calendar.strftime(date, format)

  defp pad(day), do: day |> Integer.to_string() |> String.pad_leading(2, "0")
end
