defmodule Storybook.Examples.DatePickerInput do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Calendar
  import SaladUI.Field
  import SaladUI.InputGroup
  import SaladUI.Popover

  alias SaladUI.JS

  def doc do
    "shadcn's date picker input and natural-language examples: a text input next to a calendar popover. Typing a date (\"June 01, 2025\", \"2025-06-01\", \"tomorrow\", \"in 3 days\") moves the calendar; picking a day fills the input. ArrowDown in the input opens the popover."
  end

  @impl true
  def mount(_params, _session, socket) do
    date = Date.add(Date.utc_today(), 2)
    {:ok, assign(socket, date: date, month: Date.beginning_of_month(date), text: "In 2 days")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-xs py-8">
      <form phx-change="typed" phx-submit="typed">
        <.field>
          <.field_label for="date-input">Schedule Date</.field_label>
          <.input_group id="date-input-group">
            <.input_group_input
              id="date-input"
              name="text"
              value={@text}
              placeholder="Tomorrow or next week"
              autocomplete="off"
              phx-debounce="200"
              phx-keydown={JS.dispatch_command("open", to: "#date-input-popover")}
              phx-key="ArrowDown"
            />
            <.input_group_addon align="inline-end">
              <.popover id="date-input-popover">
                <.popover_trigger
                  as={&input_group_button/1}
                  aria-label="Select date"
                  {%{variant: "ghost", size: "icon-xs"}}
                >
                  <Lucideicons.calendar />
                  <span class="sr-only">Select date</span>
                </.popover_trigger>
                <.popover_content class="w-auto overflow-hidden p-0" align="end" side-offset={8}>
                  <.calendar
                    id="date-input-calendar"
                    value={@date}
                    month={@month}
                    caption-layout="dropdown"
                    on-select="picked"
                    close-on-select
                  />
                </.popover_content>
              </.popover>
            </.input_group_addon>
          </.input_group>
          <div class="px-1 text-sm text-muted-foreground">
            Your post will be published on <span class="font-medium">{format_date(@date)}</span>.
          </div>
        </.field>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("typed", %{"text" => text}, socket) do
    case parse_date(text, Date.utc_today()) do
      nil -> {:noreply, assign(socket, text: text)}
      date -> {:noreply, assign(socket, text: text, date: date, month: Date.beginning_of_month(date))}
    end
  end

  def handle_event("picked", %{"value" => iso}, socket) do
    case iso && Date.from_iso8601(iso) do
      {:ok, date} -> {:noreply, assign(socket, date: date, text: format_date(date))}
      _ -> {:noreply, assign(socket, date: nil, text: "")}
    end
  end

  @months ~w(january february march april may june july august september october november december)

  defp format_date(nil), do: "-"
  defp format_date(date), do: Calendar.strftime(date, "%B %d, %Y")

  # A tiny stand-in for chrono-node.
  defp parse_date(text, today) do
    text = text |> String.trim() |> String.downcase()

    cond do
      text == "today" -> today
      text == "tomorrow" -> Date.add(today, 1)
      text == "yesterday" -> Date.add(today, -1)
      text == "next week" -> Date.add(today, 7)
      match = Regex.run(~r/^in (\d+) (day|week)s?$/, text) -> relative(match, today)
      match = Regex.run(~r/^([a-z]+) (\d{1,2}),? (\d{4})$/, text) -> named(match)
      true -> iso(text)
    end
  end

  defp relative([_, n, "day"], today), do: Date.add(today, String.to_integer(n))
  defp relative([_, n, "week"], today), do: Date.add(today, 7 * String.to_integer(n))

  defp named([_, month, day, year]) do
    with index when is_integer(index) <- Enum.find_index(@months, &String.starts_with?(&1, month)),
         {:ok, date} <- Date.new(String.to_integer(year), index + 1, String.to_integer(day)) do
      date
    else
      _ -> nil
    end
  end

  defp iso(text) do
    case Date.from_iso8601(text) do
      {:ok, date} -> date
      _ -> nil
    end
  end
end
