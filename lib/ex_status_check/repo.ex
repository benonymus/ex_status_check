defmodule ExStatusCheck.Repo do
  use Ecto.Repo,
    otp_app: :ex_status_check,
    adapter: Ecto.Adapters.SQLite3
end
