defmodule SaladChatWeb.UploadController do
  @moduledoc "Serves files attached in the composer, and the `/as/:handle` shortcut."
  use SaladChatWeb, :controller

  alias SaladChatWeb.Uploads

  def show(conn, %{"name" => name}) do
    path = Uploads.path(name)

    if Uploads.valid_name?(name) and File.regular?(path) do
      conn
      |> put_resp_content_type(MIME.from_path(name))
      |> put_resp_header("cache-control", "private, max-age=3600")
      |> send_file(200, path)
    else
      send_resp(conn, 404, "Not found")
    end
  end

  def home(conn, %{"handle" => handle}) do
    redirect(conn, to: SaladChatWeb.Paths.channel_path(handle, "general"))
  end
end
