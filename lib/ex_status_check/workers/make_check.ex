defmodule ExStatusCheck.Workers.MakeCheck do
  @moduledoc false
  use Oban.Worker,
    queue: :checks,
    max_attempts: 3,
    unique: [period: 60, states: [:available, :scheduled]]

  alias ExStatusCheck.{Checks, Pages}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"page_id" => page_id} = args}) do
    # we are safe here for retries thanks to uniqueness
    job = Oban.insert!(__MODULE__.new(args, schedule_in: 30))

    page = Pages.get_page(page_id)
    # while I am not too happy to do this here, this is the safest
    # in case we lose the job id on the page for any reason
    with %Pages.Page{url: url} <- page,
         {:ok, _} <- Pages.update_page_with_oban_job_id(page, job.id),
         {:ok, %Req.Response{status: status}} <-
           Req.get(url, retry: false, connect_options: [timeout: 5000]),
         {:ok, _} <-
           Checks.create_check(%{page_id: page_id, success: status < 500}) do
      Phoenix.PubSub.broadcast(ExStatusCheck.PubSub, Pages.topic_name(page), :new_check)
      Phoenix.PubSub.broadcast(ExStatusCheck.PubSub, "homepage", {:new_check, page_id})
      :ok
    else
      nil ->
        Oban.cancel_job(job)
        {:cancel, "page deleted"}

      {:error, %Mint.TransportError{reason: :ehostunreach}} ->
        Pages.delete_page(page)
        Oban.cancel_job(job)
        {:cancel, "ehostunreach"}

      err ->
        err
    end
  end

  # constant backoff
  @impl Worker
  def backoff(%Oban.Job{attempt: _attempt}), do: 3
end
