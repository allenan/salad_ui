defmodule SaladUI.CalendarTest do
  use ComponentCase

  import SaladUI.Calendar

  alias Phoenix.LiveView.Socket
  alias SaladUI.Calendar.LiveComponent

  @today ~D[2025-06-12]

  defp render_calendar(attrs) do
    render_component(&calendar/1, Map.merge(%{id: "cal", today: @today}, Map.new(attrs)))
  end

  defp opts(attrs) do
    SaladUI.Calendar.component_opts(Map.merge(%{__changed__: %{}, mode: "single", today: @today}, Map.new(attrs)))
  end

  # The LiveComponent socket after mount/update with the given calendar attrs.
  defp mount(attrs, socket \\ %Socket{}) do
    {:ok, socket} = LiveComponent.update(%{id: "cal", kind: "calendar", opts: opts(attrs)}, socket)
    socket
  end

  defp disabled_day?(html, iso), do: day_button(html, iso) =~ ~r/\sdisabled[\s>]/

  defp event(socket, name, params) do
    {:noreply, socket} = LiveComponent.handle_event(name, params, socket)
    socket
  end

  defp td(html, iso) do
    [tag] = Regex.run(~r/<td[^>]*data-day="#{iso}"[^>]*>/, html)
    tag
  end

  defp day_button(html, iso) do
    [tag] = Regex.run(~r/<button[^>]*data-slot="calendar-day-button" data-day="#{iso}"[^>]*>/, html)
    tag
  end

  # {name, value} of the inputs the calendar submits. They are text inputs with
  # the hidden attribute, so LiveView's used-input tracking sees them.
  defp value_inputs(html) do
    ~r/<input type="text" hidden name="([^"]*)" value="([^"]*)" tabindex="-1" autocomplete="off" aria-hidden="true">/
    |> Regex.scan(html, capture: :all_but_first)
    |> Enum.map(&List.to_tuple/1)
  end

  defp tabbable(html) do
    [[iso]] = Regex.scan(~r/data-day="([\d-]+)" [^>]*tabindex="0"/, html, capture: :all_but_first)
    iso
  end

  describe "calendar/1 rendering" do
    test "renders the month of today with the hook, slots and weekday header" do
      html = render_calendar(%{})

      assert html =~ ~s(id="cal")
      assert html =~ ~s(data-slot="calendar")
      assert html =~ ~s(data-component="calendar")
      assert html =~ ~s(phx-hook="SaladUI")
      assert html =~ ~s(role="grid")
      assert html =~ ~s(aria-label="June 2025")
      assert html =~ ~s(<span role="status" aria-live="polite" class="text-sm font-medium select-none">)
      assert html =~ "[--cell-size:--spacing(8)]"
      assert html =~ "[[data-slot=popover-content]_&amp;]:bg-transparent"

      # Sunday first by default; June 2025 starts on a Sunday and has 5 weeks.
      assert [_, "Su", "Mo"] = Regex.run(~r/>\s*(Su)\s*<.*?>\s*(Mo)\s*</s, html)
      assert count_substring(html, ~s(class="mt-2 flex w-full")) == 5
      assert td(html, "2025-06-12") =~ ~s(data-today="true")
      assert td(html, "2025-06-12") =~ "rounded-md bg-accent text-accent-foreground"
      assert day_button(html, "2025-06-12") =~ ~s(aria-label="Today, Thursday, June 12th, 2025")
      # Nothing selected: today is the tab stop.
      assert tabbable(html) == "2025-06-12"
    end

    test "week-starts-on shifts the grid and the header" do
      html = render_calendar(%{"week-starts-on": 1})

      assert [_, "Mo"] = Regex.run(~r/scope="col"[^>]*>\s*(\w+)/, html)
      # June 1st 2025 is a Sunday, so the first row starts on Monday May 26th.
      assert td(html, "2025-05-26") =~ ~s(data-outside="true")
      refute html =~ ~s(data-day="2025-05-25")
    end

    test "selected single date" do
      html = render_calendar(%{value: ~D[2025-06-03]})

      assert td(html, "2025-06-03") =~ ~s(data-selected="true")
      assert td(html, "2025-06-03") =~ ~s(aria-selected="true")
      assert day_button(html, "2025-06-03") =~ ~s(data-selected-single="true")
      assert day_button(html, "2025-06-03") =~ ", selected\""
      assert tabbable(html) == "2025-06-03"
      assert html =~ ~s(data-value="&quot;2025-06-03&quot;")
    end

    test "accepts ISO strings for value, month and today" do
      html = render_calendar(%{value: "2024-02-29", today: "2024-03-01"})

      assert html =~ ~s(aria-label="February 2024")
      assert td(html, "2024-02-29") =~ ~s(data-selected="true")
    end

    test "range selection marks start, middle and end" do
      html = render_calendar(%{mode: "range", value: %{from: ~D[2025-06-10], to: ~D[2025-06-13]}})

      assert day_button(html, "2025-06-10") =~ ~s(data-range-start="true")
      assert td(html, "2025-06-10") =~ "rounded-s-md bg-accent"
      assert day_button(html, "2025-06-11") =~ ~s(data-range-middle="true")
      assert day_button(html, "2025-06-13") =~ ~s(data-range-end="true")
      assert td(html, "2025-06-13") =~ "rounded-e-md bg-accent"
      refute day_button(html, "2025-06-11") =~ "data-selected-single"
      assert html =~ ~s(aria-multiselectable="true")
    end

    test "multiple selection" do
      html = render_calendar(%{mode: "multiple", value: [~D[2025-06-02], "2025-06-20"]})

      assert day_button(html, "2025-06-02") =~ ~s(data-selected-single="true")
      assert day_button(html, "2025-06-20") =~ ~s(data-selected-single="true")
      assert html =~ ~s(aria-multiselectable="true")
    end

    test "outside days can be hidden" do
      html = render_calendar(%{month: ~D[2025-07-01], "show-outside-days": false})

      # July 2025 starts on a Tuesday: June 29/30 are hidden, without buttons.
      assert td(html, "2025-06-30") =~ ~s(data-hidden="true")
      assert td(html, "2025-06-30") =~ "invisible"
      refute html =~ ~r/<button[^>]*data-day="2025-06-30"/
    end

    test "fixed weeks always renders six rows" do
      html = render_calendar(%{month: "2026-02", "fixed-weeks": true})
      assert count_substring(html, ~s(class="mt-2 flex w-full")) == 6
    end

    test "week numbers" do
      html = render_calendar(%{month: "2025-01", "show-week-number": true})

      assert html =~ ~s{<th class="w-(--cell-size) select-none"></th>}
      assert html =~ "[&amp;:nth-child(2)[data-selected=true]_button]:rounded-s-md"
      assert html =~ ~r{size-\(--cell-size\) items-center justify-center text-center">\s*1\s*<}
    end

    test "min and max disable days and limit navigation" do
      html = render_calendar(%{min: ~D[2025-06-05], max: ~D[2025-06-25]})

      assert disabled_day?(html, "2025-06-04")
      assert td(html, "2025-06-04") =~ ~s(data-disabled="true")
      assert td(html, "2025-06-04") =~ "text-muted-foreground opacity-50"
      refute disabled_day?(html, "2025-06-05")
      # Like react-day-picker, an unavailable nav button leaves the tab order.
      assert html =~ ~r/aria-label="Go to the Previous Month" aria-disabled="true" tabindex="-1"/
      refute html =~ ~r/phx-click="navigate" phx-value-offset="-1"/
    end

    test "disabled matchers" do
      html =
        render_calendar(%{
          disabled: [
            ~D[2025-06-02],
            Date.range(~D[2025-06-09], ~D[2025-06-10]),
            %{day_of_week: [6]},
            %{after: ~D[2025-06-27]},
            fn date -> date.day == 17 end
          ]
        })

      for iso <- ~w(2025-06-02 2025-06-09 2025-06-10 2025-06-14 2025-06-17 2025-06-28) do
        assert disabled_day?(html, iso), iso
      end

      for iso <- ~w(2025-06-03 2025-06-11 2025-06-16 2025-06-27) do
        refute disabled_day?(html, iso), iso
      end
    end

    test "disabled={true} disables every day" do
      html = render_calendar(%{disabled: true})
      assert count_substring(html, ~s(data-disabled="true")) == 35
    end

    test "modifiers add data attributes and classes" do
      booked = [~D[2025-06-12], ~D[2025-06-13]]

      html =
        render_calendar(%{
          modifiers: %{booked: booked},
          "modifiers-class": %{booked: "[&>button]:line-through opacity-100"}
        })

      assert td(html, "2025-06-13") =~ ~s(data-booked="true")
      assert td(html, "2025-06-13") =~ "[&amp;&gt;button]:line-through opacity-100"
      refute td(html, "2025-06-14") =~ "data-booked"
    end

    test "two months side by side" do
      html = render_calendar(%{"number-of-months": 2, month: "2025-01"})

      assert html =~ ~s(aria-label="January 2025")
      assert html =~ ~s(aria-label="February 2025")
      assert count_substring(html, ~s(data-slot="calendar-month")) == 2
      # Only one tab stop across both months.
      assert count_substring(html, ~s(tabindex="0")) == 1
    end

    test "dropdown caption renders month and year selects" do
      html = render_calendar(%{"caption-layout": "dropdown"})

      assert html =~ ~s(aria-label="Choose the Month")
      assert html =~ ~s(aria-label="Choose the Year")
      assert html =~ ~r{<option value="6" selected>\s*Jun\s*</option>}
      # react-day-picker's default range: 100 years back to the end of this year.
      assert html =~ ~s(<option value="1925">)
      assert html =~ ~s(<option value="2025" selected>)
      refute html =~ ~s(<option value="2026">)
      assert html =~ ~s(<span role="status" aria-live="polite" class="sr-only">June 2025</span>)
    end

    test "month-dropdown-format long shows full month names in the dropdown" do
      html = render_calendar(%{"caption-layout": "dropdown", "month-dropdown-format": "long"})

      assert html =~ ~r{<option value="6" selected>\s*June\s*</option>}
      assert html =~ ~r{<option value="9">\s*September\s*</option>}
    end

    test "dropdown-months keeps the year as text" do
      html = render_calendar(%{"caption-layout": "dropdown-months"})

      assert html =~ ~s(aria-label="Choose the Month")
      refute html =~ ~s(aria-label="Choose the Year")
    end

    test "month and weekday names can be localized" do
      names = ~w(enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre)
      html = render_calendar(%{"month-names": names, "weekday-names": ~w(Do Lu Ma Mi Ju Vi Sa)})

      assert html =~ "junio 2025"
      assert html =~ ~r/>\s*Lu\s*</
    end

    test "custom day content slot" do
      price = fn day ->
        assigns = %{day: day}

        ~H"""
        {@day.date.day}<span :if={!@day.outside}>$100</span>
        """
      end

      html =
        render_calendar(%{
          day: [%{__slot__: :day, inner_block: fn _changed, day -> price.(day) end}]
        })

      assert html =~ ~r{>\s*12<span>\$100</span>}
      assert count_substring(html, "<span>$100</span>") == 30
    end

    test "presets render as buttons" do
      html = render_calendar(%{presets: [%{label: "Today", value: 0}, %{label: "In a week", value: 7}]})

      assert html =~ ~s(data-slot="calendar-presets")
      assert html =~ ~s(data-preset="1")
      assert html =~ ~s(phx-click="preset")
      assert html =~ "In a week"
    end

    test "rest attributes and class reach the root" do
      html = render_calendar(%{class: "rounded-lg border", dir: "rtl"})

      assert html =~ ~s(dir="rtl")
      assert html =~ "rounded-lg border"
    end
  end

  describe "form integration" do
    test "single mode submits an ISO date" do
      html = render_calendar(%{name: "date", value: ~D[2025-06-03]})
      assert {"date", "2025-06-03"} in value_inputs(html)
      assert html =~ ~s(id="cal-value")
    end

    test "empty single mode submits an empty string" do
      html = render_calendar(%{name: "date"})
      assert {"date", ""} in value_inputs(html)
    end

    test "multiple mode submits a list" do
      html = render_calendar(%{name: "days", mode: "multiple", value: [~D[2025-06-03], ~D[2025-06-05]]})

      assert {"days[]", "2025-06-03"} in value_inputs(html)
      assert {"days[]", "2025-06-05"} in value_inputs(html)
      refute html =~ ~s(name="days" value="")

      html = render_calendar(%{name: "days", mode: "multiple"})
      assert {"days", ""} in value_inputs(html)
    end

    test "range mode submits from and to" do
      html = render_calendar(%{name: "stay", mode: "range", value: %{from: ~D[2025-06-03], to: nil}})

      assert {"stay[from]", "2025-06-03"} in value_inputs(html)
      assert {"stay[to]", ""} in value_inputs(html)
    end

    test "no name, no inputs" do
      assert value_inputs(render_calendar(%{})) == []
    end

    test "form field provides name and parses params back" do
      form = Phoenix.Component.to_form(%{"stay" => %{"from" => "2025-06-03", "to" => "2025-06-09"}}, as: :booking)

      html = render_calendar(%{mode: "range", field: form[:stay]})

      assert {"booking[stay][from]", "2025-06-03"} in value_inputs(html)
      assert day_button(html, "2025-06-05") =~ ~s(data-range-middle="true")
    end
  end

  describe "LiveComponent events" do
    test "select toggles a single date" do
      socket = mount(%{})

      socket = event(socket, "select", %{"date" => "2025-06-04"})
      assert socket.assigns.selected == ~D[2025-06-04]
      assert socket.assigns.focus == ~D[2025-06-04]

      socket = event(socket, "select", %{"date" => "2025-06-04"})
      assert socket.assigns.selected == nil
    end

    test "required keeps the selection" do
      socket = %{value: ~D[2025-06-04], required: true} |> mount() |> event("select", %{"date" => "2025-06-04"})
      assert socket.assigns.selected == ~D[2025-06-04]
    end

    test "select ignores disabled and invalid dates" do
      socket = mount(%{disabled: [~D[2025-06-04]]})

      assert event(socket, "select", %{"date" => "2025-06-04"}).assigns.selected == nil
      assert event(socket, "select", %{"date" => "nope"}).assigns.selected == nil
    end

    test "multiple toggles dates in order" do
      socket =
        %{mode: "multiple"}
        |> mount()
        |> event("select", %{"date" => "2025-06-09"})
        |> event("select", %{"date" => "2025-06-02"})

      assert socket.assigns.selected == [~D[2025-06-02], ~D[2025-06-09]]

      socket = event(socket, "select", %{"date" => "2025-06-09"})
      assert socket.assigns.selected == [~D[2025-06-02]]
    end

    test "navigate and goto move the visible month" do
      socket = mount(%{})
      assert socket.assigns.month == ~D[2025-06-01]

      socket = event(socket, "navigate", %{"offset" => "1"})
      assert socket.assigns.month == ~D[2025-07-01]

      socket = event(socket, "goto", %{"month" => "2023-02-01", "index" => "0"})
      assert socket.assigns.month == ~D[2023-02-01]

      # A dropdown in the second of two months moves the first month back one.
      socket = %{"number-of-months": 2} |> mount() |> event("goto", %{"month" => "2024-05-01", "index" => 1})
      assert socket.assigns.month == ~D[2024-04-01]
    end

    test "navigation stops at the bounds" do
      socket = mount(%{max: ~D[2025-06-30]})
      assert event(socket, "navigate", %{"offset" => "1"}).assigns.month == ~D[2025-06-01]
    end

    test "focus moves the month to show the date and skips disabled days" do
      socket = mount(%{disabled: [~D[2025-07-01]]})

      socket = event(socket, "focus", %{"date" => "2025-07-01", "dir" => 1})
      assert socket.assigns.month == ~D[2025-07-01]
      assert socket.assigns.focus == ~D[2025-07-02]

      socket = event(socket, "focus", %{"date" => "2025-06-30", "dir" => -1})
      assert socket.assigns.month == ~D[2025-06-01]
      assert socket.assigns.focus == ~D[2025-06-30]
    end

    test "focus on a month navigation cannot reach changes nothing" do
      socket = mount(%{"end-month": ~D[2025-06-01]})

      assert event(socket, "focus", %{"date" => "2025-07-01", "dir" => 1}) == socket
    end

    test "user selections bump data-selection-seq; a value from the parent does not" do
      socket = mount(%{value: ~D[2025-06-04], required: true})
      assert socket.assigns.selection_seq == 0
      assert render_calendar(%{}) =~ ~s(data-selection-seq="0")

      # A no-op pick (required) still counts, so the hook can settle its state.
      socket = event(socket, "select", %{"date" => "2025-06-04"})
      assert socket.assigns.selection_seq == 1

      socket = %{presets: [%{label: "Today", value: 0}]} |> mount(socket) |> event("preset", %{"index" => "0"})
      assert socket.assigns.selection_seq == 2

      socket = mount(%{value: ~D[2025-06-20]}, socket)
      assert socket.assigns.selection_seq == 2

      assert event(socket, "select", %{"date" => "nope"}).assigns.selection_seq == 2
    end

    test "presets set the selection and show it" do
      socket = mount(%{mode: "range", presets: [%{label: "Next 40 days", value: 40}]})

      socket = event(socket, "preset", %{"index" => "0"})
      assert socket.assigns.selected == %{from: @today, to: ~D[2025-07-22]}
      assert socket.assigns.month == ~D[2025-06-01]

      socket = %{presets: [{"Later", ~D[2026-01-15]}]} |> mount() |> event("preset", %{"index" => "0"})
      assert socket.assigns.selected == ~D[2026-01-15]
      assert socket.assigns.month == ~D[2026-01-01]
    end

    test "a changed value from the parent replaces the selection; an unchanged one does not" do
      socket = %{value: ~D[2025-06-04]} |> mount() |> event("select", %{"date" => "2025-06-10"})

      assert mount(%{value: ~D[2025-06-04]}, socket).assigns.selected == ~D[2025-06-10]
      assert mount(%{value: ~D[2025-08-01]}, socket).assigns.selected == ~D[2025-08-01]
    end

    test "a changed month from the parent navigates" do
      socket = mount(%{month: "2025-01"})
      assert socket.assigns.month == ~D[2025-01-01]

      socket = socket |> event("navigate", %{"offset" => 1}) |> then(&mount(%{month: "2025-01"}, &1))
      assert socket.assigns.month == ~D[2025-02-01]

      assert mount(%{month: "2025-09"}, socket).assigns.month == ~D[2025-09-01]
    end
  end

  describe "selection rules" do
    test "range follows react-day-picker's addToRange" do
      d = &Date.new!(2025, 6, &1)

      assert LiveComponent.toggle("range", nil, d.(10), false) == %{from: d.(10), to: d.(10)}
      assert LiveComponent.toggle("range", %{from: d.(10), to: nil}, d.(5), false) == %{from: d.(5), to: d.(10)}
      assert LiveComponent.toggle("range", %{from: d.(10), to: d.(10)}, d.(14), false) == %{from: d.(10), to: d.(14)}
      assert LiveComponent.toggle("range", %{from: d.(10), to: d.(14)}, d.(12), false) == %{from: d.(10), to: d.(12)}
      assert LiveComponent.toggle("range", %{from: d.(10), to: d.(14)}, d.(8), false) == %{from: d.(8), to: d.(14)}
      assert LiveComponent.toggle("range", %{from: d.(10), to: d.(14)}, d.(14), false) == %{from: d.(14), to: d.(14)}
      assert LiveComponent.toggle("range", %{from: d.(10), to: d.(10)}, d.(10), false) == nil
      assert LiveComponent.toggle("range", %{from: d.(10), to: d.(10)}, d.(10), true) == %{from: d.(10), to: d.(10)}
    end

    test "values are normalized from many shapes" do
      assert LiveComponent.normalize_value("range", Date.range(~D[2025-01-09], ~D[2025-01-02], -1)) ==
               %{from: ~D[2025-01-02], to: ~D[2025-01-09]}

      assert LiveComponent.normalize_value("range", %{"from" => "2025-01-02", "to" => ""}) ==
               %{from: ~D[2025-01-02], to: nil}

      assert LiveComponent.normalize_value("range", %{"from" => "", "to" => ""}) == nil
      assert LiveComponent.normalize_value("multiple", "") == []
      assert LiveComponent.normalize_value("single", "") == nil
      assert LiveComponent.normalize_value("single", ~U[2025-01-02 23:00:00Z]) == ~D[2025-01-02]
    end

    test "week numbers" do
      # ISO weeks when weeks start on Monday.
      assert LiveComponent.week_number(~D[2024-12-30], 1) == 1
      # US weeks: the week holding January 1st is week 1.
      assert LiveComponent.week_number(~D[2024-12-29], 0) == 1
      assert LiveComponent.week_number(~D[2025-01-05], 0) == 2
      assert LiveComponent.week_number(~D[2025-12-21], 0) == 52
    end
  end
end
