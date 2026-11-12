defmodule SaladChatWeb.PageController do
  use SaladChatWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
