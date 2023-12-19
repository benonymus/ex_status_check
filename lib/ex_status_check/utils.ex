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

  def format_date_time(input, time_zone, type) do
    {:ok, datetime, _} = DateTime.from_iso8601(input)

    datetime
    |> Timex.Timezone.convert(time_zone)
    |> Timex.format!(datetime_formatter(type))
  end

  defp datetime_formatter(:day), do: "{YYYY}-{0M}-{D}"
  defp datetime_formatter(:hour), do: "{YYYY}-{0M}-{D} {h24}:{m}"
  defp datetime_formatter(:minute), do: "{YYYY}-{0M}-{D} {h24}:{m}"
end
