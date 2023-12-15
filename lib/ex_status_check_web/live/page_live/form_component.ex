defmodule ExStatusCheckWeb.PageLive.FormComponent do
  use ExStatusCheckWeb, :live_component

  alias ExStatusCheck.Pages

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="page-form"
        phx-target={@myself}
        phx-change="change"
        phx-submit="save"
      >
        <.input field={@form[:url]} type="text" placeholder="https://google.com/" />
        <:actions>
          <.button phx-disable-with="Saving...">Check page</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{page: page} = assigns, socket) do
    changeset = Pages.change_page(page)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("change", %{"page" => page_params}, socket) do
    changeset =
      Pages.change_page(socket.assigns.page, page_params)

    notify_parent({:filter, String.trim(page_params["url"])})

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"page" => page_params}, socket) do
    save_page(socket, page_params)
  end

  defp save_page(socket, page_params) do
    case Pages.create_page(page_params) |> IO.inspect() do
      {:ok, page} ->
        Phoenix.PubSub.broadcast(ExStatusCheck.PubSub, "homepage", {:new_page, page})

        {:noreply,
         socket
         |> put_flash(:info, "Page added successfully")
         |> push_navigate(to: ~p"/pages/#{page.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
