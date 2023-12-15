defmodule ExStatusCheckWeb.PageLive.CheckComponent do
  use ExStatusCheckWeb, :live_component

  alias ExStatusCheck.Checks

  @impl true
  def render(assigns) do
    IO.inspect(assigns)

    ~H"""
    <.parallelogram
      :if={not is_nil(@current_check)}
      live={true}
      percentage={calculate_percentage(@current_check.result)}
      success_count={Map.get(@current_check.result, true, 0)}
      fail_count={Map.get(@current_check.result, false, 0)}
      date={"live - #{format_date_time(@current_check.date, @timezone, @type)}"}
      path={build_next_path(@type, @page.slug, @current_check.date)}
    />
    """
  end

  defp calculate_percentage(%{true: 0, false: 0}), do: 0

  defp calculate_percentage(%{true: trues, false: falses}),
    do: (trues / (trues + falses) * 100) |> Float.round(3)

  defp calculate_percentage(values),
    do: %{true: 0, false: 0} |> Map.merge(values) |> calculate_percentage()
end
