defmodule ExStatusCheck.Workers.ClearChecks do
  use Oban.Worker, queue: :default

  import Ecto.Query, warn: false

  alias ExStatusCheck.Repo
  alias ExStatusCheck.Checks.Check

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
