defmodule SaladUI.DatePickerTest do
  use ComponentCase

  import SaladUI.DatePicker

  @today ~D[2025-06-12]

  defp render_picker(attrs) do
    render_component(&date_picker/1, Map.merge(%{id: "dp", today: @today}, Map.new(attrs)))
  end

  defp trigger(html) do
    [tag] = Regex.run(~r/<button[^>]*data-slot="popover-trigger"[^>]*>.*?<\/button>/s, html)
    tag
  end

  test "renders a popover with an outline trigger and a calendar inside" do
    html = render_picker(%{})

    assert html =~ ~s(data-slot="date-picker")
    assert html =~ ~s(id="dp-popover")
    assert html =~ ~s(data-component="popover")
    assert html =~ ~s(id="dp-calendar")
    assert html =~ ~s(data-component="calendar")

    trigger = trigger(html)
    assert trigger =~ ~s(id="dp-trigger")
    assert trigger =~ ~s(data-empty="true")
    assert trigger =~ "data-[empty=true]:text-muted-foreground"
    assert trigger =~ "border bg-background"
    assert trigger =~ "lucide-calendar"
    assert trigger =~ "Pick a date"

    assert html =~ ~s(data-slot="popover-content")
    assert html =~ "w-auto overflow-hidden p-0"
    assert html =~ ~s(data-align="start")
  end

  test "single mode closes on select by default" do
    assert render_picker(%{}) =~ "closeOnSelect&quot;:true"
    assert render_picker(%{"close-on-select": false}) =~ "closeOnSelect&quot;:false"
    assert render_picker(%{mode: "range"}) =~ "closeOnSelect&quot;:false"
  end

  test "trigger label for a single date" do
    trigger = trigger(render_picker(%{value: ~D[2025-06-03]}))

    assert trigger =~ ~s(data-empty="false")
    assert trigger =~ "June 3rd, 2025"
  end

  test "trigger label for a range" do
    html = render_picker(%{mode: "range", value: %{from: ~D[2025-01-20], to: ~D[2025-02-09]}})
    assert trigger(html) =~ "Jan 20, 2025 - Feb 09, 2025"

    html = render_picker(%{mode: "range", value: %{from: ~D[2025-01-20], to: nil}})
    assert trigger(html) =~ "Jan 20, 2025"
  end

  test "trigger label for multiple dates" do
    assert trigger(render_picker(%{mode: "multiple", value: [~D[2025-01-20]]})) =~ "January 20th, 2025"
    assert trigger(render_picker(%{mode: "multiple", value: [~D[2025-01-20], ~D[2025-01-21]]})) =~ "2 dates selected"
  end

  test "format accepts strftime strings and functions" do
    assert trigger(render_picker(%{value: ~D[2025-06-03], format: "%d/%m/%Y"})) =~ "03/06/2025"
    assert trigger(render_picker(%{value: ~D[2025-06-03], format: &Date.to_iso8601/1})) =~ "2025-06-03"
  end

  test "chevron icon and custom placeholder" do
    trigger = trigger(render_picker(%{icon: "chevron", placeholder: "Select date"}))

    assert trigger =~ "lucide-chevron-down"
    refute trigger =~ "lucide-calendar"
    assert trigger =~ "justify-between"
    assert trigger =~ "Select date"
  end

  test "trigger slot" do
    html =
      render_picker(%{
        value: ~D[2025-06-03],
        trigger: [%{__slot__: :trigger, inner_block: fn _changed, picker -> "When: #{picker.value}" end}]
      })

    assert trigger(html) =~ "When: 2025-06-03"
  end

  test "hidden inputs live outside the popover" do
    form = Phoenix.Component.to_form(%{"due" => "2025-06-03"}, as: :task)
    html = render_picker(%{field: form[:due]})

    [_, after_popover] = String.split(html, ~s(id="dp-calendar-value"))
    assert after_popover =~ ~s(<input type="hidden" name="task[due]" value="2025-06-03">)
    # The inputs come after the popover root has closed.
    [before_inputs, _] = String.split(html, ~s(id="dp-calendar-value"))
    assert count_substring(before_inputs, "<input") == 0
  end

  test "an invalid field marks the trigger" do
    form = Phoenix.Component.to_form(%{"due" => ""}, as: :task, errors: [due: {"can't be blank", []}])
    assert trigger(render_picker(%{field: form[:due]})) =~ ~s(aria-invalid="true")
  end

  test "calendar options are passed through" do
    html = render_picker(%{"number-of-months": 2, "caption-layout": "dropdown", "calendar-class": "rounded-md border"})

    assert count_substring(html, ~s(data-slot="calendar-month")) == 2
    assert html =~ ~s(aria-label="Choose the Year")
    assert html =~ "rounded-md border"
  end
end
