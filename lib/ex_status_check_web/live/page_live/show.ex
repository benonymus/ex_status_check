defmodule ExStatusCheckWeb.PageLive.Show do
  use ExStatusCheckWeb, :live_view

  alias ExStatusCheck.{Checks, Pages}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       connected?: connected?(socket),
       locale: get_connect_params(socket)["locale"],
       timezone: get_connect_params(socket)["timezone"],
       checks: [],
       current_check: nil,
       type: :day,
       datetime_string: nil
     )}
  end

  @impl true
  def handle_params(%{"slug" => slug} = params, _, socket) do
    page = Pages.get_page_by!(slug: slug)

    if socket.assigns.connected?,
      do: Phoenix.PubSub.subscribe(ExStatusCheck.PubSub, "page:#{page.id}")

    {:noreply, socket |> assign(page_title: page.slug, page: page) |> assign_extras(params)}
  end

  @impl true
  def handle_info(
        :new_check,
        %{assigns: %{type: type, datetime_string: datetime_string}} = socket
      ) do
    {:noreply,
     assign_extras(socket, %{"type" => Atom.to_string(type), "datetime" => datetime_string})}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp assign_extras(socket, %{"datetime" => datetime_string, "type" => "minute"}) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime_string)
    now = DateTime.utc_now()

    checks =
      Checks.get_status_for(socket.assigns.page.id, datetime, :minute)

    current_check =
      if Date.compare(datetime, now) == :eq and datetime.hour == now.hour,
        do: Checks.get_status_for_current_interval(socket.assigns.page.id, :minute)

    assign(socket,
      type: :minute,
      datetime_string: datetime_string,
      checks: checks,
      current_check: current_check
    )
  end

  defp assign_extras(socket, %{"datetime" => datetime_string, "type" => "hour"}) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime_string)

    checks =
      Checks.get_status_for(socket.assigns.page.id, datetime, :hour)

    current_check =
      if Date.compare(datetime, Date.utc_today()) == :eq,
        do: Checks.get_status_for_current_interval(socket.assigns.page.id, :hour)

    assign(socket,
      type: :hour,
      datetime_string: datetime_string,
      checks: checks,
      current_check: current_check
    )
  end

  defp assign_extras(socket, _) do
    checks =
      Checks.get_status_for(socket.assigns.page.id, DateTime.utc_now(), :day, -30)

    current_check = Checks.get_status_for_current_interval(socket.assigns.page.id, :day)

    assign(socket, type: :day, datetime_string: nil, checks: checks, current_check: current_check)
  end

  def build_next_path(type, slug, datetime) do
    type = next_type(type)

    unless is_nil(type), do: ~p"/pages/#{slug}?datetime=#{datetime}&type=#{type}"
  end

  defp next_type(:day), do: :hour
  defp next_type(:hour), do: :minute
  defp next_type(:minute), do: nil

  # maybe localize these too and proper format depending on type
  def format_date_time(input, time_zone, type) do
    {:ok, datetime, _} = DateTime.from_iso8601(input)

    datetime
    |> Timex.Timezone.convert(time_zone)
    |> Timex.format!(datetime_formatter(type))
  end

  defp datetime_formatter(:day), do: "{YYYY}-{0M}-{D}"
  defp datetime_formatter(:hour), do: "{YYYY}-{0M}-{D} {h24}:{m}"
  defp datetime_formatter(:minute), do: "{YYYY}-{0M}-{D} {h24}:{m}"

  def back_button_text(:day), do: "Home"
  def back_button_text(:hour), do: "Day"
  def back_button_text(:minute), do: "Hour"

  def back_button_path(:day, _, _), do: ~p"/"

  def back_button_path(:hour, slug, _),
    do: ~p"/pages/#{slug}"

  def back_button_path(:minute, slug, datetime),
    do: ~p"/pages/#{slug}?datetime=#{datetime}&type=#{:hour}"

  def calculate_percentage(%{true: 0, false: 0}), do: 0

  def calculate_percentage(%{true: trues, false: falses}),
    do: (trues / (trues + falses) * 100) |> Float.round(3)

  def calculate_percentage(values),
    do: %{true: 0, false: 0} |> Map.merge(values) |> calculate_percentage()
end
