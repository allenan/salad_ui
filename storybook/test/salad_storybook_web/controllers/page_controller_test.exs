defmodule SaladStorybookWeb.PageControllerTest do
  use SaladStorybookWeb.ConnCase

  test "GET / redirects to the storybook welcome page", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == "/welcome"
  end
end
