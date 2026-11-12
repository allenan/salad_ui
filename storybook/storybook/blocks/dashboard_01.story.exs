defmodule Storybook.Blocks.Dashboard01 do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  def doc do
    "shadcn/ui's dashboard-01 block: an inset sidebar, a site header, KPI cards, an interactive area chart (time range toggle) and a data table with row selection, column visibility, pagination, inline edits and a row drawer."
  end

  def extra_sources, do: ["../../lib/salad_storybook_web/blocks/dashboard_01.ex"]

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <SaladStorybookWeb.Blocks.preview slug="dashboard-01" />
    """
  end
end
