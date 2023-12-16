defmodule ExStatusCheck.Workers.MakeCheckTest do
  use ExStatusCheck.DataCase
  use Oban.Testing, repo: ExStatusCheck.Repo, prefix: false
  use Mimic

  alias ExStatusCheck.Workers.MakeCheck

  test "MakeCheck" do
    expect(Req, :get, fn _, _ ->
      {:ok, %Req.Response{status: 200}}
    end)

    page = ExStatusCheck.PagesFixtures.page_fixture()

    assert :ok = perform_job(MakeCheck, %{"page_id" => page.id})
    assert_enqueued(worker: MakeCheck, args: %{page_id: page.id})
  end
end
