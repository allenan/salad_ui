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
end
