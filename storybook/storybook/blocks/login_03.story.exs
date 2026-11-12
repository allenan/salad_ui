defmodule Storybook.Blocks.Login03 do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  def doc do
    "shadcn/ui's login-03 block: a login page with a muted background, a logo, Apple and Google buttons and an email/password form."
  end

  def extra_sources, do: ["../../lib/salad_storybook_web/blocks/login_03.ex"]

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <SaladStorybookWeb.Blocks.preview slug="login-03" />
    """
  end
end
