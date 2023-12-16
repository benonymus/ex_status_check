defmodule ExStatusCheck.Workers.ClearChecksTest do
  use ExStatusCheck.DataCase
  use Oban.Testing, repo: ExStatusCheck.Repo, prefix: false

  import Ecto.Query, only: [select: 2]
  import ExStatusCheck.ChecksFixtures

  alias ExStatusCheck.Workers.ClearChecks

  test "ClearChecks" do
    page = ExStatusCheck.PagesFixtures.page_fixture()

    _ = check_fixture(page.id, true)
    _ = check_fixture(page.id, false)
    _ = check_fixture(page.id, false)

    assert 3 = check_count()

    # this will delete from +1 day but it is ok for the test
    assert :ok = perform_job(ClearChecks, %{"days_ago" => -1})

    assert 0 = check_count()
  end

  defp check_count, do: ExStatusCheck.Checks.Check |> select(count()) |> ExStatusCheck.Repo.one()
end
