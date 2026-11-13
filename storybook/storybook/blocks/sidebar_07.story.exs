defmodule Storybook.Blocks.Sidebar07 do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  def doc do
    "shadcn/ui's sidebar-07 block: a sidebar that collapses to icons, with a team switcher, collapsible navigation, a projects list with per-item menus and a user menu. Toggle it with the trigger or the rail."
  end

  def extra_sources, do: ["../../lib/salad_storybook_web/blocks/sidebar_07.ex"]

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <SaladStorybookWeb.Blocks.preview slug="sidebar-07" />
    """
  end
end
