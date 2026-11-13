defmodule SaladChatWeb.Router do
  use SaladChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SaladChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # /bench is cross-origin isolated so performance.measureUserAgentSpecificMemory()
  # can report its heap.
  pipeline :isolated do
    plug :cross_origin_isolate
  end

  scope "/", SaladChatWeb do
    pipe_through [:browser, :isolated]

    live_session :bench do
      live "/bench", BenchLive
    end
  end

  scope "/", SaladChatWeb do
    pipe_through :browser

    live_session :chat do
      live "/", LandingLive
      live "/as/:handle/c/:channel", ChatLive
      live "/as/:handle/c/:channel/t/:thread", ChatLive
    end

    get "/as/:handle", UploadController, :home
    get "/uploads/:name", UploadController, :show
  end

  defp cross_origin_isolate(conn, _opts) do
    conn
    |> put_resp_header("cross-origin-opener-policy", "same-origin")
    |> put_resp_header("cross-origin-embedder-policy", "require-corp")
  end
end
