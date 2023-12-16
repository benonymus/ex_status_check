defmodule ExStatusCheck.Workers.ClearChecks do
  @moduledoc false
  use Oban.Worker, queue: :default

  import Ecto.Query, warn: false

  alias ExStatusCheck.Checks.Check
  alias ExStatusCheck.Repo

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"days_ago" => days}}) do
    days_ago =
      DateTime.utc_now() |> DateTime.add(-days, :day) |> DateTime.to_string()

    Check
    |> where([c], c.inserted_at < ^days_ago)
    |> Repo.delete_all()

    :ok
  end
end
