defmodule ExStatusCheckWeb.PageLive.Show do
  use ExStatusCheckWeb, :live_view

  alias ExStatusCheck.{Checks, Pages}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       connected?: connected?(socket),
       # locale: get_connect_params(socket)["locale"],
       timezone: get_connect_params(socket)["timezone"],
       # can't stream checks due to design,
       # can't show current check as last in line nicely,
       # it gets dropped to new line
       # or if it is in one div things get out of order due to appending
       # reset: true did not help on stream
       # if it would be the first item or separately shown then yes
       checks: [],
       type: :day,
       datetime_string: nil,
       skip_last: false
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
        %{assigns: %{type: type, datetime_string: datetime_string, page: page}} = socket
      ) do
    send_update(ExStatusCheckWeb.PageLive.LiveCheckComponent,
      id: "page_#{page.id}_#{type}_show"
    )

    {:noreply,
     assign_extras(socket, %{"type" => Atom.to_string(type), "datetime" => datetime_string})}
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp assign_extras(socket, %{"datetime" => datetime_string, "type" => "minute"}) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime_string)

    now = DateTime.utc_now()

    skip_last = Date.compare(datetime, now) == :eq and datetime.hour == now.hour

    checks =
      Checks.get_status_for(socket.assigns.page.id, datetime, skip_last, :minute)

    assign(socket,
      type: :minute,
      datetime_string: datetime_string,
      checks: checks,
      skip_last: skip_last
    )
  end

  defp assign_extras(socket, %{"datetime" => datetime_string, "type" => "hour"}) do
    {:ok, datetime, _} = DateTime.from_iso8601(datetime_string)

    skip_last = Date.compare(datetime, Date.utc_today()) == :eq

    checks =
      Checks.get_status_for(socket.assigns.page.id, datetime, skip_last, :hour)

    assign(socket,
      type: :hour,
      datetime_string: datetime_string,
      checks: checks,
      skip_last: skip_last
    )
  end

  defp assign_extras(socket, _) do
    checks =
      Checks.get_status_for(socket.assigns.page.id, DateTime.utc_now(), true, :day, -29)

    assign(socket, type: :day, datetime_string: nil, checks: checks, skip_last: false)
  end

  def back_button_text(:day), do: "Home"
  def back_button_text(:hour), do: "Day"
  def back_button_text(:minute), do: "Hour"

  def back_button_path(:day, _, _), do: ~p"/"

  def back_button_path(:hour, slug, _),
    do: ~p"/pages/#{slug}"

  def back_button_path(:minute, slug, datetime),
    do: ~p"/pages/#{slug}?datetime=#{datetime}&type=#{:hour}"
end
