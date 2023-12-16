defmodule ExStatusCheck.Pages do
  @moduledoc """
  The Pages context.
  """
  use Nebulex.Caching

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias ExStatusCheck.{Cache, Repo}
  alias ExStatusCheck.Pages.Page
  alias ExStatusCheck.Workers.Check, as: CheckWorker

  @doc """
  Returns the list of pages.

  ## Examples

      iex> list_pages()
      [%Page{}, ...]

  """
  @decorate cacheable(
              cache: Cache,
              key: :pages,
              opts: [ttl: :timer.hours(12)]
            )
  def list_pages, do: Repo.all(Page)

  @doc """
  Gets a single page.
  """
  @decorate cacheable(
              cache: Cache,
              key: {:page, id},
              opts: [ttl: :timer.hours(12)]
            )
  def get_page(id), do: Repo.get(Page, id)

  def get_page!(id), do: Repo.get!(Page, id)

  @decorate cacheable(
              cache: Cache,
              key: {:page, slug},
              references: &{:page, &1.id},
              opts: [ttl: :timer.hours(12)]
            )
  def get_page_by_slug!(slug), do: Repo.get_by!(Page, slug: slug)

  @doc """
  Creates a page.

  ## Examples

      iex> create_page(%{field: value})
      {:ok, %Page{}}

      iex> create_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @decorate cache_evict(
              cache: Cache,
              key: :pages
            )
  def create_page(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(
      :page,
      Page.changeset_with_uri(%Page{}, attrs)
    )
    |> Oban.insert(
      :check_job,
      fn %{page: page} ->
        datetime = DateTime.utc_now()
        time_start = Timex.Time.new!(datetime.hour, datetime.minute + 1, 10)

        # next minute 10 sec
        scheduled_at =
          datetime
          |> DateTime.to_date()
          |> Timex.DateTime.new!(time_start)

        CheckWorker.new(%{page_id: page.id}, scheduled_at: scheduled_at)
      end
    )
    |> Multi.update(
      :complete_page,
      fn %{page: page, check_job: job} ->
        Page.oban_job_id_changeset(page, %{oban_job_id: job.id})
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{complete_page: page}} -> {:ok, page}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def update_page_with_oban_job_id(%Page{oban_job_id: oban_job_id} = page, oban_job_id),
    do: {:ok, page}

  def update_page_with_oban_job_id(%Page{} = page, oban_job_id) do
    page
    |> Page.oban_job_id_changeset(%{oban_job_id: oban_job_id})
    |> Repo.update()
  end

  @doc """
  Deletes a page.

  ## Examples

      iex> delete_page(page)
      {:ok, %Page{}}

      iex> delete_page(page)
      {:error, %Ecto.Changeset{}}

  """
  @decorate cache_evict(
              cache: Cache,
              keys: [:pages, {:page, page.id}]
            )
  def delete_page(%Page{} = page) do
    Repo.delete(page)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking page changes.

  ## Examples

      iex> change_page(page)
      %Ecto.Changeset{data: %Page{}}

  """
  def change_page(%Page{} = page, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end

  # helpers
  def topic_name(page), do: "page:#{page.id}"
end
