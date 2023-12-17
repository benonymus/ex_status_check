defmodule ExStatusCheckWeb.Router do
  use ExStatusCheckWeb, :router
  import Phoenix.LiveDashboard.Router
  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExStatusCheckWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin do
    # would have this in env vars in a real project or no dev dashboard at all
    plug :basic_auth, username: "yuyu", password: "hakusho"
  end

  scope "/", ExStatusCheckWeb do
    pipe_through :browser

    live "/", PageLive.Index, :index
    live "/pages/:slug", PageLive.Show, :show
  end

  scope "/dev" do
    pipe_through :browser
    pipe_through :admin

    live_dashboard "/dashboard", metrics: ExStatusCheckWeb.Telemetry
  end
end
