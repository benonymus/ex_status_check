defmodule ExStatusCheck.PagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExStatusCheck.Pages` context.
  """

  import Mimic

  @doc """
  Generate a page.
  """
  def page_fixture(attrs \\ %{}) do
    stub_host_check()

    {:ok, page} =
      attrs
      |> Enum.into(%{
        url: "https://test_url.com"
      })
      |> ExStatusCheck.Pages.create_page()

    page
  end

  def stub_host_check do
    stub(ExStatusCheck.Utils, :validate_host, fn _ ->
      {:ok, nil}
    end)
  end
end
