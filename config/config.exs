# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ex_status_check,
  ecto_repos: [ExStatusCheck.Repo],
  generators: [timestamp_type: :utc_datetime]

config :ex_status_check, Oban,
  repo: ExStatusCheck.Repo,
  engine: Oban.Engines.Lite,
  queues: [default: 10, checks: 1000],
  plugins: [
    Oban.Plugins.Pruner,
    {
      Oban.Plugins.Cron,
      crontab: [
        {"0 0 * * *", ExStatusCheck.Workers.ClearCache, args: %{interval: :day}},
        {"0 * * * *", ExStatusCheck.Workers.ClearCache, args: %{interval: :hour}},
        {"* * * * *", ExStatusCheck.Workers.ClearCache, args: %{interval: :minute}},
        {"0 0 * * *", ExStatusCheck.Workers.ClearChecks, args: %{days_ago: 30}}
      ]
    }
  ]

config :ex_status_check, ExStatusCheck.Cache,
  gc_interval: :timer.hours(12),
  # Max 200 mb of memory
  allocated_memory: 200_000_000,
  # GC min timeout: 10 sec
  gc_cleanup_min_timeout: :timer.seconds(10),
  # GC max timeout: 10 min
  gc_cleanup_max_timeout: :timer.minutes(10)

# we don't need constant updates and saves some memory
config :tzdata, :autoupdate, :disabled

# Configures the endpoint
config :ex_status_check, ExStatusCheckWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ExStatusCheckWeb.ErrorHTML, json: ExStatusCheckWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ExStatusCheck.PubSub,
  live_view: [signing_salt: "XToIwKov"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
