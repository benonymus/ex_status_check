defmodule ExStatusCheck.ChecksTest do
  use ExStatusCheck.DataCase

  alias ExStatusCheck.Checks

  describe "checks" do
    import ExStatusCheck.ChecksFixtures

    alias ExStatusCheck.Checks.Check

    setup do
      page = ExStatusCheck.PagesFixtures.page_fixture()
      {:ok, %{page: page}}
    end

    test "create_check/1 with valid data creates a check", %{page: page} do
      valid_attrs = %{page_id: page.id, success: true}

      assert {:ok, %Check{} = check} = Checks.create_check(valid_attrs)
      assert check.page_id == page.id
      assert check.success == true
    end

    test "create_check/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Checks.create_check(%{page_id: nil})
    end

    for interval <- [:day, :hour, :minute] do
      @tag interval: interval
      test "get_results_for_current_interval/2 returns correct results for #{interval}", %{
        page: page,
        interval: interval
      } do
        _ = check_fixture(page.id, true)
        _ = check_fixture(page.id, false)
        _ = check_fixture(page.id, false)

        assert %{date: _, result: %{false: 2, true: 1}} =
                 Checks.get_results_for_current_interval(page.id, interval)
      end
    end

    for {interval, amount} <- [{:day, -5}, {:hour, nil}, {:minute, nil}],
        skip_last <- [true, false] do
      @tag interval: interval
      @tag amount: amount
      @tag skip_last: skip_last
      test "get_status_for/2 returns correct results for #{interval} with skip_last=#{skip_last}",
           %{page: page, interval: interval, amount: amount, skip_last: skip_last} do
        _ = check_fixture(page.id, true)
        _ = check_fixture(page.id, false)
        _ = check_fixture(page.id, false)

        ExStatusCheck.Cache.delete_all(nil)

        {_, _, checks} =
          Checks.get_results_for(page.id, DateTime.utc_now(), skip_last, interval, amount)

        if skip_last do
          assert [] == checks
        else
          assert [{_, %{false: 2, true: 1}}] = checks
        end
      end
    end
  end
end
