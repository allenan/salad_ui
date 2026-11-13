defmodule Storybook.SaladUIComponents.Calendar do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.Calendar.calendar/1

  def imports,
    do: [
      {SaladUI.Card, [card: 1, card_content: 1, card_footer: 1]},
      {SaladUI.Field, [field: 1, field_group: 1, field_label: 1]},
      {SaladUI.InputGroup, [input_group: 1, input_group_input: 1, input_group_addon: 1]}
    ]

  def description do
    """
    A month grid for picking a date, several dates or a range. The grid is
    rendered on the server; a small hook adds keyboard navigation (arrows,
    PageUp/PageDown, Home/End). Selections are submitted as ISO 8601 dates.
    """
  end

  def variations do
    year = Date.utc_today().year

    [
      %Variation{
        id: :demo,
        description: ~s|Single date with month/year dropdowns: caption-layout="dropdown"|,
        attributes: %{
          id: "calendar-demo",
          value: Date.utc_today(),
          "caption-layout": "dropdown",
          class: "rounded-md border shadow-sm"
        }
      },
      %Variation{
        id: :basic,
        description: "Basic calendar",
        attributes: %{id: "calendar-basic", class: "rounded-lg border"}
      },
      %Variation{
        id: :multiple,
        description: ~s|Several dates: mode="multiple"|,
        template: """
        <.card class="mx-auto w-fit p-0">
          <.card_content class="p-0">
            <.calendar id="calendar-multiple" mode="multiple" />
          </.card_content>
        </.card>
        """
      },
      %Variation{
        id: :range,
        description: ~s|Range over two months, future dates disabled: mode="range" number-of-months={2}|,
        template: """
        <.card class="mx-auto w-fit p-0">
          <.card_content class="p-0">
            <.calendar
              id="calendar-range"
              mode="range"
              number-of-months={2}
              value={%{from: Date.new!(#{year}, 1, 12), to: Date.add(Date.new!(#{year}, 1, 12), 30)}}
              disabled={[%{after: Date.utc_today()}, %{before: ~D[1900-01-01]}]}
            />
          </.card_content>
        </.card>
        """
      },
      %Variation{
        id: :caption,
        description: "Month and year selector",
        attributes: %{id: "calendar-caption", "caption-layout": "dropdown", class: "rounded-lg border"}
      },
      %Variation{
        id: :presets,
        description: "Presets: quick picks as day offsets from today, under a fixed six-week grid",
        template: """
        <.card class="mx-auto w-fit max-w-[300px]" size="sm">
          <.card_content>
            <.calendar
              id="calendar-presets"
              value={Date.new!(#{year}, 2, 12)}
              fixed-weeks
              class="p-0 [--cell-size:--spacing(9.5)]"
              presets={[
                %{label: "Today", value: 0},
                %{label: "Tomorrow", value: 1},
                %{label: "In 3 days", value: 3},
                %{label: "In a week", value: 7},
                %{label: "In 2 weeks", value: 14}
              ]}
            />
          </.card_content>
        </.card>
        """
      },
      %Variation{
        id: :time,
        description: "Date and time picker",
        template: """
        <.card size="sm" class="mx-auto w-fit">
          <.card_content>
            <.calendar id="calendar-time" value={Date.new!(#{year}, Date.utc_today().month, 12)} class="p-0" />
          </.card_content>
          <.card_footer class="border-t bg-card">
            <.field_group>
              <.field>
                <.field_label for="time-from">Start Time</.field_label>
                <.input_group id="calendar-time-from">
                  <.input_group_input
                    id="time-from"
                    type="time"
                    step="1"
                    value="10:30:00"
                    class="appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
                  />
                  <.input_group_addon>
                    <Lucideicons.clock_2 class="text-muted-foreground" />
                  </.input_group_addon>
                </.input_group>
              </.field>
              <.field>
                <.field_label for="time-to">End Time</.field_label>
                <.input_group id="calendar-time-to">
                  <.input_group_input
                    id="time-to"
                    type="time"
                    step="1"
                    value="12:30:00"
                    class="appearance-none [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
                  />
                  <.input_group_addon>
                    <Lucideicons.clock_2 class="text-muted-foreground" />
                  </.input_group_addon>
                </.input_group>
              </.field>
            </.field_group>
          </.card_footer>
        </.card>
        """
      },
      %Variation{
        id: :booked_dates,
        description: "Booked dates: disabled, plus a booked modifier that strikes them through",
        template: """
        <.card class="mx-auto w-fit p-0">
          <.card_content class="p-0">
            <.calendar
              id="calendar-booked"
              value={Date.new!(#{year}, 2, 3)}
              disabled={%{from: Date.new!(#{year}, 2, 12), to: Date.new!(#{year}, 2, 26)}}
              modifiers={%{booked: %{from: Date.new!(#{year}, 2, 12), to: Date.new!(#{year}, 2, 26)}}}
              modifiers-class={%{booked: "[&>button]:line-through opacity-100"}}
            />
          </.card_content>
        </.card>
        """
      },
      %Variation{
        id: :custom_days,
        description: "Custom cell size (responsive) and day content through the day slot",
        template: """
        <.card class="mx-auto w-fit p-0">
          <.card_content class="p-0">
            <.calendar
              id="calendar-custom-days"
              mode="range"
              value={%{from: Date.new!(#{year}, 12, 8), to: Date.new!(#{year}, 12, 18)}}
              caption-layout="dropdown"
              month-dropdown-format="long"
              class="[--cell-size:--spacing(10)] md:[--cell-size:--spacing(12)]"
            >
              <:day :let={day}>
                {day.date.day}
                <span :if={!day.outside}>{if Date.day_of_week(day.date) in [6, 7], do: "$120", else: "$100"}</span>
              </:day>
            </.calendar>
          </.card_content>
        </.card>
        """
      },
      %Variation{
        id: :week_numbers,
        description: "Week numbers: show-week-number",
        template: """
        <.card class="mx-auto w-fit p-0">
          <.card_content class="p-0">
            <.calendar id="calendar-week-numbers" value={Date.new!(#{year}, 2, 3)} show-week-number />
          </.card_content>
        </.card>
        """
      },
      %Variation{
        id: :week_starts_on,
        description: "Week starting on Monday with ISO week numbers, limited to this quarter with min/max",
        template: """
        <.calendar
          id="calendar-week-start"
          week-starts-on={1}
          show-week-number
          min={Date.beginning_of_month(Date.utc_today())}
          max={Date.end_of_month(Date.add(Date.end_of_month(Date.utc_today()), 40))}
          class="rounded-lg border"
        />
        """
      },
      %Variation{
        id: :rtl,
        description: ~s|RTL with localized names: dir="rtl", month-names and weekday-names|,
        template: """
        <.calendar
          id="calendar-rtl"
          dir="rtl"
          value={Date.utc_today()}
          caption-layout="dropdown"
          month-dropdown-format="long"
          month-names={~w(يناير فبراير مارس أبريل مايو يونيو يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر)}
          weekday-names={~w(ح ن ث ر خ ج س)}
          class="rounded-lg border [--cell-size:--spacing(9)]"
        />
        """
      },
      %Variation{
        id: :form,
        description: "In a form: a range submitted as name[from] / name[to] ISO dates",
        template: """
        <form phx-change="validate" class="flex flex-col items-center gap-2">
          <.calendar
            id="calendar-form"
            mode="range"
            name="stay"
            class="rounded-lg border"
          />
        </form>
        """
      }
    ]
  end
end
