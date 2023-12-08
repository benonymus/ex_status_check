defmodule ExStatusCheckWeb.PageLive.Show do
  use ExStatusCheckWeb, :live_view

  alias ExStatusCheck.Pages

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Show Page")
     |> assign(:page, Pages.get_page_by!(slug: slug))}
  end
end
