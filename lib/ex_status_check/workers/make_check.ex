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
    with %Pages.Page{url: url} <- page,
         {:ok, _} <- Pages.update_page_with_oban_job_id(page, job.id),
         {:request, _, {:ok, %Req.Response{status: status}}} <-
           {:request, attempt == 3, Req.get(url, retry: false, connect_options: [timeout: 5000])} do
      result(page, status < 500)
      :ok
    else
      nil ->
        Oban.cancel_job(job)
        {:cancel, "page deleted"}

      {:request, true, {:error, %Mint.TransportError{reason: :ehostunreach}}} ->
        Pages.delete_page(page)
        Oban.cancel_job(job)
        {:cancel, "ehostunreach"}

      {:request, _, _} ->
        result(page, false)

      err ->
        err
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
