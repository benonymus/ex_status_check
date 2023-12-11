defmodule ExStatusCheckWeb.PageLive.Index do
  use ExStatusCheckWeb, :live_view

  alias ExStatusCheck.Pages
  alias ExStatusCheck.Pages.Page

  @impl true
  def mount(_params, _session, socket) do
    # locale and timezone are here
    IO.inspect(get_connect_params(socket))
    {:ok, stream(socket, :pages, Pages.list_pages())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Page")
    |> assign(:page, %Page{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Pages")
    |> assign(:page, nil)
  end

  @impl true
  def handle_info({ExStatusCheckWeb.PageLive.FormComponent, {:saved, page}}, socket) do
    {:noreply, stream_insert(socket, :pages, page)}
  end
end
