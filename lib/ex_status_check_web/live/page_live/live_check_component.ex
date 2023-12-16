defmodule ExStatusCheckWeb.PageLive.LiveCheckComponent do
  use ExStatusCheckWeb, :live_component

  alias ExStatusCheck.Checks

  @impl true
  def render(assigns) do
    assigns =
      assign(
        assigns,
        current_check: Checks.get_results_for_current_interval(assigns.page.id, assigns.type)
      )

    ~H"""
    <div id={"#{@id}_live_check"}>
      <.parallelogram
        :if={not is_nil(@current_check)}
        live={true}
        slug={@page.slug}
        result={@current_check.result}
        type={@type}
        date={@current_check.date}
        timezone={@timezone}
        tooltip_position={@tooltip_position}
      />
    </div>
    """
  end

  @impl true
  def update(_assigns, %{assigns: %{render_count: render_count}} = socket) do
    {:ok, assign(socket, render_count: render_count + 1)}
  end

  def update(assigns, socket), do: {:ok, assign(socket, assigns)}
end
