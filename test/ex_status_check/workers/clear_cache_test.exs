defmodule ExStatusCheck.Workers.ClearCacheTest do
  use ExStatusCheck.DataCase
  use Oban.Testing, repo: ExStatusCheck.Repo, prefix: false

  alias ExStatusCheck.Workers.ClearCache
  alias ExStatusCheck.Cache

  test "ClearCache" do
    key = {nil, :day, nil, nil}
    value = "test"

    Cache.put(
      key,
      value
    )

    assert value == Cache.get(key)

    assert :ok = perform_job(ClearCache, %{"interval" => :day})

    assert key |> Cache.get() |> is_nil
  end
end
