defmodule ExStatusCheck.PagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExStatusCheck.Pages` context.
  """

  @doc """
  Generate a page.
  """
  def page_fixture(attrs \\ %{}) do
    {:ok, page} =
      attrs
      |> Enum.into(%{
        url: "some url"
      })
      |> ExStatusCheck.Pages.create_page()

    page
  end
end
