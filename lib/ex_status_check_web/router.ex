defmodule ExStatusCheckWeb.Router do
  use ExStatusCheckWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExStatusCheckWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", ExStatusCheckWeb do
    pipe_through :browser

    live "/", PageLive.Index, :index
    live "/pages/new", PageLive.Index, :new
    live "/pages/:slug", PageLive.Show, :show
  end
end
