defmodule ExStatusCheckWeb.PageLive.Index do
  use ExStatusCheckWeb, :live_view

  import Phoenix.UI.Components.{Card, Typography}

  alias ExStatusCheck.Pages
  alias ExStatusCheck.Pages.Page

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       connected?: connected?(socket),
       timezone: get_connect_params(socket)["timezone"],
       page: %Page{}
     )
     |> stream(:pages, Pages.list_pages())}
  end

  @impl true
  def handle_params(_params, _, socket) do
    if socket.assigns.connected?,
      do: Phoenix.PubSub.subscribe(ExStatusCheck.PubSub, "homepage")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_page, page}, socket) do
    {:noreply, stream_insert(socket, :pages, page)}
  end

  def handle_info(
        {:new_check, page_id},
        socket
      ) do
    for type <- [:day, :hour, :minute] do
      send_update(ExStatusCheckWeb.PageLive.LiveCheckComponent,
        id: "page_#{page_id}_#{type}"
      )
    end

    {:noreply, socket}
  end

  # this has room for further optimization
  def handle_info({ExStatusCheckWeb.PageLive.FormComponent, {:filter, filter}}, socket) do
    pages = Enum.filter(Pages.list_pages(), fn %Page{url: url} -> url =~ filter end)

    {:noreply, stream(socket, :pages, pages, reset: true)}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
