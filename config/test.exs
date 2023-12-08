import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ex_status_check, ExStatusCheck.Repo,
  database: Path.expand("../ex_status_check_test.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

config :ex_status_check, Oban, testing: :inline

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_status_check, ExStatusCheckWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "J+OCkNHgvx5BWvqSPEZ9L5Geg/0DJu0E9y0RBTrrj6ElK6mOonBrvWRGlB1/991T",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
