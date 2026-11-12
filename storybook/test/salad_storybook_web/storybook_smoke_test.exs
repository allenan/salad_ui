defmodule SaladStorybookWeb.StorybookSmokeTest do
  @moduledoc """
  Mounts every story in the storybook. Catches stories that compile but crash
  at render time (bad attrs, removed component functions, broken examples).
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  for %{path: path} <- SaladStorybookWeb.Storybook.leaves() do
    @path path
    test "story #{path} renders", %{conn: conn} do
      assert {:ok, _view, html} = live(conn, @path)
      assert html =~ "<"
    end
  end
end
