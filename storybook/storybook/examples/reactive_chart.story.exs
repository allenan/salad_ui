defmodule Storybook.Examples.ReactiveChart do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Button
  import SaladUI.Chart

  alias SaladUI.LiveView

  def doc do
    "Charts that update in place: one re-rendered from assigns, one pushed new rows with send_command/4, and a legacy raw Chart.js canvas."
  end

  @months ~w(January February March April May June July August September October November December)

  @chart_config %{
    desktop: %{label: "Desktop", color: "var(--chart-1)"},
    mobile: %{label: "Mobile", color: "var(--chart-2)"}
  }

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:chart_config, @chart_config)
      |> assign(:chart_data, random_rows())
      |> assign(:legacy_data, legacy_data())

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container flex flex-col gap-y-4">
      <.chart_container id="reactive-chart" config={@chart_config} class="min-h-[240px] w-full">
        <.chart type="bar" data={@chart_data} index="month" tick_chars={3} />
        <.chart_tooltip />
        <.chart_legend />
      </.chart_container>
      <div class="flex gap-2">
        <.button phx-click="update-chart">Update from assigns</.button>
        <.button variant="outline" phx-click="push-chart">Push with send_command</.button>
      </div>

      <.chart
        id="reactive-chart-legacy"
        name="Legacy Chart.js canvas"
        chart-type="line"
        chart-options={%{responsive: true}}
        chart-data={@legacy_data}
      />
      <.button variant="secondary" phx-click="update-legacy">Update legacy chart</.button>
    </div>
    """
  end

  @impl true
  def handle_event("update-chart", _params, socket) do
    {:noreply, assign(socket, :chart_data, random_rows())}
  end

  def handle_event("push-chart", _params, socket) do
    {:noreply, LiveView.send_command(socket, "reactive-chart", "update", %{data: random_rows()})}
  end

  def handle_event("update-legacy", _params, socket) do
    {:noreply, LiveView.send_command(socket, "reactive-chart-legacy", "update", %{data: legacy_data()})}
  end

  defp random_rows do
    Enum.map(@months, &%{month: &1, desktop: :rand.uniform(300), mobile: :rand.uniform(300)})
  end

  defp legacy_data do
    %{
      labels: ["Q1", "Q2", "Q3", "Q4"],
      datasets: [
        %{label: "Sales", data: Enum.map(1..4, fn _ -> :rand.uniform(100) end), borderColor: "rgb(0, 0, 0)", tension: 0.4}
      ]
    }
  end
end
