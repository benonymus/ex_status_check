defmodule ExStatusCheck.Checks do
  @moduledoc """
  The Checks context.
  """

  import Ecto.Query, warn: false
  alias ExStatusCheck.Repo
  alias ExStatusCheck.Checks.Check

  @doc """
  Creates a check.

  ## Examples

      iex> create_check(%{field: value})
      {:ok, %Check{}}

      iex> create_check(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_check(attrs \\ %{}) do
    %Check{}
    |> Check.changeset(attrs)
    |> Repo.insert()
  end

  # helpers
  def get_status_for_last(id, amount, interval) do
    datetime_string =
      DateTime.utc_now()
      |> DateTime.add(amount, interval)
      |> DateTime.to_string()

    Check
    |> where(page_id: ^id)
    |> where([c], c.inserted_at > ^datetime_string)
    |> group_by([c], c.success)
    |> select([c], {c.success, count(c.id)})
    |> Repo.all()
  end

  def get_status_for_date(id, datetime) do
    start_of_day = datetime |> Timex.beginning_of_day() |> DateTime.to_string()
    end_of_day = datetime |> Timex.end_of_day() |> DateTime.to_string()

    {substr_length, padding} =
      {13, ":00:00Z"}

    Check
    |> where(page_id: ^id)
    |> where([c], c.inserted_at >= ^start_of_day and c.inserted_at <= ^end_of_day)
    |> group_by([c], [fragment("substr(?, 1, ?)", c.inserted_at, ^substr_length), c.success])
    |> select(
      [c],
      {fragment("substr(?, 1, ?)", c.inserted_at, ^substr_length), %{c.success => count(c.id)}}
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      Map.merge(acc, %{(k <> padding) => v}, fn _k, v1, v2 ->
        Map.merge(v1, v2)
      end)
    end)
  end

  def get_status_per(id, amount, interval) do
    datetime_string =
      DateTime.utc_now()
      |> DateTime.add(amount, interval)
      |> DateTime.to_string()

    {substr_length, padding} =
      case interval do
        :day ->
          {10, "T00:00:00Z"}

        :hour ->
          {13, ":00:00Z"}

        :minute ->
          {16, ":00Z"}
      end

    Check
    |> where(page_id: ^id)
    |> where([c], c.inserted_at > ^datetime_string)
    |> group_by([c], [fragment("substr(?, 1, ?)", c.inserted_at, ^substr_length), c.success])
    |> select(
      [c],
      {fragment("substr(?, 1, ?)", c.inserted_at, ^substr_length), %{c.success => count(c.id)}}
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      Map.merge(acc, %{(k <> padding) => v}, fn _k, v1, v2 ->
        Map.merge(v1, v2)
      end)
    end)
  end
end
