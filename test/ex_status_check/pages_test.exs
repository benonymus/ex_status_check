defmodule ExStatusCheck.PagesTest do
  use ExStatusCheck.DataCase
  use Oban.Testing, repo: ExStatusCheck.Repo, prefix: false

  alias ExStatusCheck.Pages

  describe "pages" do
    import ExStatusCheck.PagesFixtures

    alias ExStatusCheck.Pages.Page

    @invalid_attrs %{url: nil}

    test "list_pages/0 returns all pages" do
      page = page_fixture()
      assert Pages.list_pages() == [%Page{page | slug_base: nil}]
    end

    test "get_page/1 returns the page with given id" do
      page = page_fixture()
      assert Pages.get_page!(page.id) == %Page{page | slug_base: nil}
    end

    test "get_page!/1 returns the page with given id" do
      page = page_fixture()
      assert Pages.get_page!(page.id) == %Page{page | slug_base: nil}
    end

    test "create_page/1 with valid data creates a page" do
      stub_host_check()
      valid_attrs = %{url: "https://test_url.com/"}

      assert {:ok, %Page{} = page} = Pages.create_page(valid_attrs)
      assert page.url == "https://test_url.com/"

      refute is_nil(page.oban_job_id)
      assert_enqueued(worker: ExStatusCheck.Workers.MakeCheck, args: %{page_id: page.id})
    end

    test "create_page/1 with invalid data returns error changeset" do
      stub_host_check()
      assert {:error, %Ecto.Changeset{}} = Pages.create_page(@invalid_attrs)
    end

    test "delete_page/1 deletes the page" do
      page = page_fixture()
      assert {:ok, %Page{}} = Pages.delete_page(page)
      assert_raise Ecto.NoResultsError, fn -> Pages.get_page!(page.id) end
    end

    test "change_page/1 returns a page changeset" do
      page = page_fixture()
      assert %Ecto.Changeset{} = Pages.change_page(page)
    end

    test "topic_name/1 returns pubsbu topic name for page" do
      page = page_fixture()
      assert "page:#{page.id}" == Pages.topic_name(page)
    end
  end
end
