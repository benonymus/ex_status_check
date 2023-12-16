defmodule ExStatusCheck.Checks do
  @moduledoc """
  The Checks context.
  """
  use Nebulex.Caching

  import Ecto.Query, warn: false
  alias ExStatusCheck.{Cache, Repo}
  alias ExStatusCheck.Checks.Check

  @doc """
  Creates a check.

  ## Examples

      iex> create_check(%{field: value})
      {:ok, %Check{}}

      iex> create_check(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @decorate cache_evict(
              cache: Cache,
              keys: [{attrs.page_id, :day}, {attrs.page_id, :hour}, {attrs.page_id, :minute}]
            )
  def create_check(attrs \\ %{}) do
    %Check{}
    |> Check.changeset(attrs)
    |> Repo.insert()
  end

  # helpers
  @decorate cacheable(
              cache: Cache,
              key: {id, interval},
              opts: [ttl: :timer.seconds(30)]
            )
  def get_status_for_current_interval(id, interval) do
    datetime = DateTime.utc_now()

    datetime_string =
      case interval do
        :day -> start(:hour, datetime)
        :hour -> start(:minute, datetime)
        :minute -> start(:second, datetime)
      end

    result =
      Check
      |> where(page_id: ^id)
      |> where([c], c.inserted_at > ^datetime_string)
      |> group_by([c], c.success)
      |> select([c], {c.success, count(c.id)})
      |> Repo.all()
      |> Map.new()

    %{date: datetime_string, result: result}
  end

  @decorate cacheable(
              cache: Cache,
              key: cache_key(id, interval, datetime),
              opts: [ttl: :timer.hours(12)]
            )
  def get_status_for(
        id,
        datetime,
        skip_last,
        interval,
        amount \\ nil
      ) do
    {substr_length, padding} = substr_length_and_padding(interval)
    # this is faster than subqueries
    Check
    |> where(page_id: ^id)
    |> where(
      [c],
      c.inserted_at >= ^start(interval, datetime, amount) and
        c.inserted_at <= ^finish(interval, datetime)
    )
    |> group_by([c], [fragment("substr(?, 1, ?)", c.inserted_at, ^substr_length), c.success])
    |> select(
      [c],
      %{
        fragment("concat(substr(?, 1, ?), ?)", c.inserted_at, ^substr_length, ^padding) => %{
          c.success => count(c.id)
        }
      }
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn map, acc ->
      Map.merge(acc, map, fn _k, v1, v2 ->
        Map.merge(v1, v2)
      end)
    end)
    |> Enum.sort_by(
      fn {k, _} ->
        {:ok, datetime, _} = DateTime.from_iso8601(k)
        datetime
      end,
      {:desc, DateTime}
    )
    |> then(fn result ->
      if length(result) > 0 and skip_last, do: tl(result), else: result
    end)
    |> Enum.reverse()
  end

  defp cache_key(id, :day = interval, _datetime),
    do: {id, interval, nil, nil}

  defp cache_key(id, interval, datetime),
    do:
      {id, interval, datetime |> DateTime.to_date() |> Date.to_string(),
       start(interval, datetime)}

  defp substr_length_and_padding(:day), do: {10, "T00:00:00Z"}

  defp substr_length_and_padding(:hour), do: {13, ":00:00Z"}

  defp substr_length_and_padding(:minute), do: {16, ":00Z"}

  defp start(interval, datetime, amount \\ nil)

  defp start(:day, datetime, amount) do
    datetime
    |> DateTime.add(amount, :day)
    |> DateTime.to_string()
  end

  defp start(:hour, datetime, _), do: datetime |> Timex.beginning_of_day() |> DateTime.to_string()

  defp start(:minute, datetime, _) do
    time_start = Timex.Time.new!(datetime.hour, 0, 0)

    datetime
    |> DateTime.to_date()
    |> Timex.DateTime.new!(time_start)
    |> DateTime.to_string()
  end

  defp start(:second, datetime, _) do
    time_start = Timex.Time.new!(datetime.hour, datetime.minute, 0)

    datetime
    |> DateTime.to_date()
    |> Timex.DateTime.new!(time_start)
    |> DateTime.to_string()
  end

  defp finish(:day, datetime), do: DateTime.to_string(datetime)

  defp finish(:hour, datetime), do: datetime |> Timex.end_of_day() |> DateTime.to_string()

  defp finish(:minute, datetime) do
    time_end = Timex.Time.new!(datetime.hour, 59, 59)

    datetime
    |> DateTime.to_date()
    |> Timex.DateTime.new!(time_end)
    |> DateTime.to_string()
  end
end
