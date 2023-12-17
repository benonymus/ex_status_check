defmodule ExStatusCheck.Utils do
  @moduledoc false

  require Logger

  def validate_host(host), do: :inet.gethostbyname(Kernel.to_charlist(host))

  def healthcheck(_conn) do
    case Ecto.Adapters.SQL.query(ExStatusCheck.Repo, "select 1", []) do
      {:ok, _res} ->
        true

      {:error, _error} ->
        error_label = "Error connecting to Database on healthcheck"
        Logger.error(error_label)
        false
    end
  end
end
