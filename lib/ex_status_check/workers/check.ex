defmodule ExStatusCheck.Workers.Check do
  use Oban.Worker,
    queue: :checks,
    max_attempts: 3,
    unique: [period: 60, states: [:available, :scheduled]]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"page_id" => page_id} = args}) do
    # we are safe here for retries thanks to uniqueness
    job = Oban.insert!(__MODULE__.new(args, schedule_in: 30))
    # while I am not too happy to do this here, this is the safest
    # in case we lose the job id on the page for any reason
    with page = %ExStatusCheck.Pages.Page{url: url} <- ExStatusCheck.Pages.get_page(page_id),
         {:ok, _} = ExStatusCheck.Pages.update_page_with_oban_job_id(page, job.id),
         {:ok, %Req.Response{status: status}} =
           Req.get(url, retry: false, connect_options: [timeout: 5000]),
         {:ok, _} <-
           ExStatusCheck.Checks.create_check(%{page_id: page_id, success: status == 200}) do
      :ok
    else
      nil ->
        Oban.cancel_job(job)
        {:cancel, "page deleted"}

      err ->
        err
    end
  end

  # constant backoff
  @impl Worker
  def backoff(%Oban.Job{attempt: _attempt}), do: 3
end
