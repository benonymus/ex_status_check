defmodule ExStatusCheck.Pages do
  @moduledoc """
  The Pages context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias ExStatusCheck.Repo
  alias ExStatusCheck.Pages.Page

  @doc """
  Returns the list of pages.

  ## Examples

      iex> list_pages()
      [%Page{}, ...]

  """
  def list_pages do
    Repo.all(Page)
  end

  @doc """
  Gets a single page.
  """
  def get_page(id), do: Repo.get(Page, id)
  def get_page_by!(clauses), do: Repo.get_by!(Page, clauses)

  @doc """
  Creates a page.

  ## Examples

      iex> create_page(%{field: value})
      {:ok, %Page{}}

      iex> create_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_page(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(
      :page,
      Page.changeset_with_uri(%Page{}, attrs)
    )
    |> Oban.insert(
      :check_job,
      fn %{page: page} ->
        ExStatusCheck.Workers.Check.new(%{page_id: page.id})
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
end
