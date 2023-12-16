defmodule ExStatusCheckWeb.PageLiveTest do
  use ExStatusCheckWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExStatusCheck.PagesFixtures

  defp create_page(_) do
    page = page_fixture()
    %{page: page}
  end

  describe "Index" do
    setup [:create_page]

    test "lists all pages", %{conn: conn, page: page} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Check page"
      assert html =~ page.url
    end

    test "saves new page", %{conn: conn} do
      stub_host_check()

      {:ok, index_live, _html} = live(conn, ~p"/")

      assert index_live
             |> form("#page-form", page: %{url: nil})
             |> render_submit() =~ "can&#39;t be blank"

      assert {:error, {:live_redirect, %{to: path}}} =
               index_live
               |> form("#page-form", page: %{url: "https://new_test_url.com/"})
               |> render_submit()

      assert path =~ "/pages/"
    end
  end

  describe "Show" do
    setup [:create_page]

    test "displays page", %{conn: conn, page: page} do
      {:ok, _show_live, html} = live(conn, ~p"/pages/#{page.slug}")

      assert html =~ page.url
    end
  end
end
