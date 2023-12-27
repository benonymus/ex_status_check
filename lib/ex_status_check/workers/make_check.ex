defmodule ExStatusCheck.Workers.MakeCheck do
  @moduledoc false
  use Oban.Worker,
    queue: :checks,
    max_attempts: 3,
    unique: [period: 60, states: [:available, :scheduled]]

  alias ExStatusCheck.{Checks, Pages}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"page_id" => page_id} = args, attempt: attempt}) do
    # we are safe here for retries thanks to uniqueness
    job = Oban.insert!(__MODULE__.new(args, schedule_in: 30))

    page = Pages.get_page(page_id)
    # while I am not too happy to do this here, this is the safest
    # in case we lose the job id on the page for any reason
    with %Pages.Page{url: url} <- check_page(page, job),
         {:ok, _} <- Pages.update_page_with_oban_job_id(page, job.id),
         {:ok, %Req.Response{status: status}} <- make_request(url, attempt, page, job) do
      result(page, status < 500)
    end
  end

  defp check_page(%Pages.Page{} = page, _job), do: page

  defp check_page(_, job) do
    Oban.cancel_job(job)
    {:cancel, "page deleted"}
  end

  defp make_request(url, attempt, page, job) do
    case {attempt == 3, Req.get(url, retry: false, connect_options: [timeout: 5000])} do
      {_, {:ok, _} = res} ->
        res

      # on max attempt we cancel with this error, likely page is dead or url is wrong
      {true, {:error, %Mint.TransportError{reason: :ehostunreach}}} ->
        Pages.delete_page(page)
        Oban.cancel_job(job)
        {:cancel, "ehostunreach"}

      {_, _} ->
        result(page, false)
    end
  end

  defp result(page, success) do
    Checks.create_check!(%{page_id: page.id, success: success})

    Phoenix.PubSub.broadcast(ExStatusCheck.PubSub, Pages.topic_name(page), :new_check)
    Phoenix.PubSub.broadcast(ExStatusCheck.PubSub, "homepage", {:new_check, page.id})
    :ok
  end

  # constant backoff
  @impl Worker
  def backoff(%Oban.Job{attempt: _attempt}), do: 3
end
