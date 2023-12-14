defmodule ExStatusCheck.Workers.ClearCache do
  use Oban.Worker, queue: :default

  import Ex2ms

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"interval" => interval}}) do
    interval = String.to_existing_atom(interval)
    today = Date.utc_today() |> Date.to_string()

    # we only need to aggressively bust the cache for the given day, past days don't change
    ExStatusCheck.Cache.delete_all(
      fun do
        {_, {_, ^interval, date, _}, _, _, _}
        when is_nil(date) or date == ^today ->
          true
      end
    )

    :ok
  end
end
