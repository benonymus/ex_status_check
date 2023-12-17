defmodule ExStatusCheck.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ExStatusCheck.Release.migrate()

    children = [
      ExStatusCheckWeb.Telemetry,
      ExStatusCheck.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:ex_status_check, :ecto_repos), skip: skip_migrations?()},
      ExStatusCheck.Cache,
      {Phoenix.PubSub, name: ExStatusCheck.PubSub},
      {Oban, Application.fetch_env!(:ex_status_check, Oban)},
      ExStatusCheckWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExStatusCheck.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExStatusCheckWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations? do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
