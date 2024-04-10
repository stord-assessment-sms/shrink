defmodule ShrinkWeb.LinkControllerTest do
  use ShrinkWeb.ConnCase, async: false

  import Shrink.HtmlHelpers

  alias Shrink.Links

  describe "new with authentication" do
    @describetag :authenticated

    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/")
      resp = html_response(conn, 200)

      doc = EasyHTML.parse!(resp)
      form = doc["form[action='/links']"]

      assert form["input[name='link[original_url]']"] != nil
    end

    test "renders recent links table", %{conn: conn, user: user} do
      for _n <- 1..3 do
        {:ok, link} = Links.create_link(user.id, Faker.Internet.url())
        link
      end

      conn = get(conn, ~p"/")
      resp = html_response(conn, 200)

      assert {:ok, doc} = Floki.parse_document(resp)
      assert table = Floki.find(doc, "tbody#recent-links")

      for link <- Links.list_recent_links_by_user_id(user.id) do
        assert [anchor] = Floki.find(table, "a[href='#{link.original_url}']")
        assert Floki.text(anchor) == link.original_url

        assert [anchor] = Floki.find(table, "a[href$='#{link.slug}']")
        assert Floki.text(anchor) == link.slug
        expected = "#{conn.scheme}://#{conn.host}/#{link.slug}"
        assert Floki.attribute(anchor, "href") == [expected]
      end
    end
  end

  describe "new without authentication" do
    test "responds 401", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert text_response(conn, 401) == "Unauthorized"
    end
  end

  describe "create with authentication and valid params" do
    @describetag :authenticated

    test "creates new link", %{conn: conn} do
      url = params_for(:link).original_url
      conn = post(conn, ~p"/links", %{"link" => %{"original_url" => url}})

      assert _resp = html_response(conn, 201)
      # assert resp =~ url
      # assert {:ok, doc} = Floki.parse_document(resp)
      # assert Floki.find(doc, "a[href='#{url}']") != []
    end

    test "sets flash message", %{conn: conn} do
      url = params_for(:link).original_url
      conn = post(conn, ~p"/links", %{"link" => %{"original_url" => url}})

      assert resp = html_response(conn, 201)
      doc = EasyHTML.parse!(resp)
      assert flashes = get_in(doc, ["#flash-info", "p", html_all(), html_trimmed_text()])

      assert Enum.find(flashes, fn text ->
               text =~ ~r/Link \S+ created successfully./
             end)
    end

    test "renders recent links table", %{conn: conn} do
      url = params_for(:link).original_url
      conn = post(conn, ~p"/links", %{"link" => %{"original_url" => url}})
      resp = html_response(conn, 201)

      assert {:ok, doc} = Floki.parse_document(resp)
      assert table = Floki.find(doc, "tbody#recent-links")
      assert Floki.find(table, "a[href='#{url}']") != []
    end
  end

  describe "create with authentication but invalid params" do
    @describetag :authenticated

    test "rerenders form with details", %{conn: conn} do
      conn = post(conn, ~p"/links", %{"link" => %{"original_url" => ""}})
      assert html_response(conn, 200) =~ "URL"
    end
  end

  describe "create without authentication" do
    test "responds 401", %{conn: conn} do
      url = params_for(:link).original_url
      conn = post(conn, ~p"/links", %{"link" => %{"original_url" => url}})
      assert text_response(conn, 401) == "Unauthorized"
    end
  end

  describe "visit with authentication and valid slug" do
    @describetag :authenticated

    test "redirects to original_url", %{conn: conn, user: user} do
      {:ok, link} = Links.create_link(user.id, Faker.Internet.url())
      conn = get(conn, "/" <> link.slug)
      assert redirected_to(conn, 301) == link.original_url
    end
  end

  describe "visit without authentication and valid slug" do
    test "redirects to original_url", %{conn: conn} do
      user = insert(:user)
      {:ok, link} = Links.create_link(user.id, Faker.Internet.url())
      conn = get(init_test_session(conn, %{}), "/" <> link.slug)
      assert redirected_to(conn, 301) == link.original_url
    end
  end

  describe "visit with authentication and invalid slug" do
    @describetag :authenticated

    test "responds 404", %{conn: conn} do
      assert Links.get_link_by_slug("foobar") == nil
      conn = get(conn, "/foobar")
      assert text_response(conn, 404) == "Not Found"
    end
  end

  describe "visit without authentication and invalid slug" do
    @describetag :authenticated

    test "responds 404", %{conn: conn} do
      assert Links.get_link_by_slug("foobar") == nil
      conn = get(init_test_session(conn, %{}), "/foobar")
      assert text_response(conn, 404) == "Not Found"
    end
  end
end
