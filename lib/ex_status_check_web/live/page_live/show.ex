defmodule ExStatusCheckWeb.PageLive.Show do
  use ExStatusCheckWeb, :live_view

  alias ExStatusCheck.{Checks, Pages}

  @num_of_days 30

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       connected?: connected?(socket),
       num_of_days: @num_of_days,
       locale: get_connect_params(socket)["locale"],
       timezone: get_connect_params(socket)["timezone"]
     )}
  end

  @impl true
  def handle_params(%{"slug" => slug} = params, _, socket) do
    page = Pages.get_page_by!(slug: slug)

    {:noreply, socket |> assign(page_title: page.slug, page: page) |> assign_extras(params)}
  end

  defp assign_extras(socket, %{"datetime" => datetime}) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime)

    checks =
      Checks.get_status_for_date(socket.assigns.page.id, datetime)
      |> IO.inspect()

    assign(socket, checks: checks)
  end

  defp assign_extras(socket, _) do
    checks =
      Checks.get_status_per(socket.assigns.page.id, -@num_of_days, :day)

    assign(socket, checks: checks)
  end

  def format_date_time(input, time_zone) do
    {:ok, datetime, _} = DateTime.from_iso8601(input)

    # maybe localize these too?
    datetime
    |> DateTime.shift_zone!(time_zone)
  end

  def calculate_percentage(%{true: trues, false: falses}),
    do: (trues / (trues + falses) * 100) |> Float.round(3)

  def calculate_percentage(values),
    do: %{true: 0, false: 0} |> Map.merge(values) |> calculate_percentage()
end
