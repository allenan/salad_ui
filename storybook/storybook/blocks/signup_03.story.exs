defmodule Storybook.Blocks.Signup03 do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  def doc do
    "shadcn/ui's signup-03 block: a signup page with a muted background, a logo and a name, email and password form."
  end

  def extra_sources, do: ["../../lib/salad_storybook_web/blocks/signup_03.ex"]

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <SaladStorybookWeb.Blocks.preview slug="signup-03" />
    """
  end
end
