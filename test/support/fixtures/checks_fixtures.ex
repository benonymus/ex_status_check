defmodule ExStatusCheck.ChecksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExStatusCheck.Checks` context.
  """

  @doc """
  Generate a check.
  """
  def check_fixture(page_id, success) do
    {:ok, check} = ExStatusCheck.Checks.create_check(%{page_id: page_id, success: success})

    check
  end
end
