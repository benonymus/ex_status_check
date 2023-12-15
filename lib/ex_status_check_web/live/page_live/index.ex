defmodule ExStatusCheckWeb.PageLive.Index do
  use ExStatusCheckWeb, :live_view

  alias ExStatusCheck.Pages
  alias ExStatusCheck.Pages.Page

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(connected?: connected?(socket), page: %Page{})
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

  # this has room for optimization
  def handle_info({ExStatusCheckWeb.PageLive.FormComponent, {:filter, filter}}, socket) do
    {:noreply, stream(socket, :pages, Pages.list_filtered_pages(filter), reset: true)}
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
