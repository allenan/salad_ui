defmodule Storybook.SaladUIComponents.DatePicker do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &SaladUI.DatePicker.date_picker/1

  def imports,
    do: [
      {SaladUI.Button, [button: 1]},
      {SaladUI.Calendar, [calendar: 1]},
      {SaladUI.Field, [field: 1, field_group: 1, field_label: 1]},
      {SaladUI.Input, [input: 1]},
      {SaladUI.Popover, [popover: 1, popover_trigger: 1, popover_content: 1]}
    ]

  def description do
    """
    A popover whose content is a calendar. The trigger label follows the
    selection, and the value is submitted in ISO 8601 hidden inputs. Single
    pickers close on select. The trigger's id is `<id>-trigger`, for labels.
    """
  end

  def variations do
    year = Date.utc_today().year

    [
      %Variation{
        id: :demo,
        description: "Date picker",
        attributes: %{id: "date-picker-demo"}
      },
      %Variation{
        id: :basic,
        description: "Basic: labelled with field_label, no icon",
        template: """
        <.field class="mx-auto w-44">
          <.field_label for="date-picker-simple-trigger">Date</.field_label>
          <.date_picker id="date-picker-simple" icon="none" trigger-class="w-full" />
        </.field>
        """
      },
      %Variation{
        id: :range,
        description: ~s|Range picker: mode="range" number-of-months={2}|,
        template: """
        <.field class="mx-auto w-60">
          <.field_label for="date-picker-range-trigger">Date Picker Range</.field_label>
          <.date_picker
            id="date-picker-range"
            mode="range"
            number-of-months={2}
            value={%{from: Date.new!(#{year}, 1, 20), to: Date.add(Date.new!(#{year}, 1, 20), 20)}}
            trigger-class="w-full px-2.5"
          />
        </.field>
        """
      },
      %Variation{
        id: :dob,
        description: "Date of birth: dropdown caption, numeric format",
        template: """
        <.field class="mx-auto w-44">
          <.field_label for="date-picker-dob-trigger">Date of birth</.field_label>
          <.date_picker
            id="date-picker-dob"
            caption-layout="dropdown"
            placeholder="Select date"
            format="%-m/%-d/%Y"
            icon="none"
            trigger-class="w-full"
          />
        </.field>
        """
      },
      %Variation{
        id: :time,
        description: "Date and time: a chevron trigger next to a time input",
        template: """
        <.field_group class="mx-auto max-w-xs flex-row">
          <.field>
            <.field_label for="date-picker-optional-trigger">Date</.field_label>
            <.date_picker
              id="date-picker-optional"
              caption-layout="dropdown"
              placeholder="Select date"
              icon="chevron"
              format="%b %-d, %Y"
              trigger-class="w-32"
            />
          </.field>
          <.field class="w-32">
            <.field_label for="time-picker-optional">Time</.field_label>
            <.input
              type="time"
              id="time-picker-optional"
              name="time"
              step="1"
              value="10:30:00"
              class="appearance-none bg-background [&::-webkit-calendar-picker-indicator]:hidden [&::-webkit-calendar-picker-indicator]:appearance-none"
            />
          </.field>
        </.field_group>
        """
      },
      %Variation{
        id: :presets,
        description: "With presets: quick picks as day offsets from today",
        attributes: %{
          id: "date-picker-presets",
          presets: [
            %{label: "Today", value: 0},
            %{label: "Tomorrow", value: 1},
            %{label: "In 3 days", value: 3},
            %{label: "In a week", value: 7}
          ]
        }
      },
      %Variation{
        id: :range_presets,
        description: "Range with presets: a preset value of N selects today to N days ahead",
        attributes: %{
          id: "date-picker-range-presets",
          mode: "range",
          "number-of-months": 2,
          "trigger-class": "w-[300px]",
          presets: [
            %{label: "Next 7 days", value: 7},
            %{label: "Next 14 days", value: 14},
            %{label: "Next 30 days", value: 30}
          ]
        }
      },
      %Variation{
        id: :multiple,
        description: ~s|Several dates: mode="multiple"; the trigger shows the count|,
        attributes: %{id: "date-picker-multiple", mode: "multiple", placeholder: "Pick dates"}
      },
      %Variation{
        id: :rtl,
        description: ~s|RTL: dir="rtl" with localized names|,
        template: """
        <div dir="rtl" class="flex justify-center">
          <.date_picker
            id="date-picker-rtl"
            placeholder="اختر تاريخًا"
            align="start"
            format="%d/%m/%Y"
            month-names={~w(يناير فبراير مارس أبريل مايو يونيو يوليو أغسطس سبتمبر أكتوبر نوفمبر ديسمبر)}
            weekday-names={~w(ح ن ث ر خ ج س)}
          />
        </div>
        """
      },
      %Variation{
        id: :composed,
        description: "Composed from popover/1 + calendar/1, as in shadcn (the trigger label comes from your assigns)",
        template: """
        <.popover id="date-picker-composed-popover">
          <.popover_trigger as={&button/1} variant="outline" class="w-[212px] justify-between font-normal">
            Pick a date <Lucideicons.chevron_down class="text-muted-foreground" />
          </.popover_trigger>
          <.popover_content class="w-auto overflow-hidden p-0" align="start">
            <.calendar id="date-picker-composed-calendar" caption-layout="dropdown" close-on-select />
          </.popover_content>
        </.popover>
        """
      },
      %Variation{
        id: :form,
        description: "In a form: the hidden inputs stay inside the form while the calendar is in the popover",
        template: """
        <form phx-change="validate" class="flex justify-center">
          <.date_picker id="date-picker-form" name="due_date" value={Date.utc_today()} />
        </form>
        """
      }
    ]
  end
end
