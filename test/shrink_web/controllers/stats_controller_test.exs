defmodule ShrinkWeb.StatsControllerTest do
  use ShrinkWeb.ConnCase, async: true

  import Shrink.HtmlHelpers

  alias Shrink.Links
  alias Shrink.Links.Visit
  alias Shrink.Repo
  alias Shrink.Stats

  describe "index with authentication" do
    @describetag :authenticated
    setup :generate_visits

    test "supports default granularity", %{conn: conn} do
      conn = get(conn, ~p"/stats")
      assert html_response(conn, 200)
    end

    for granularity <- ~w(total daily hourly)a do
      test "shows statistical table of user's links with #{granularity} aggegrated visits", %{conn: conn, user: user} do
        granularity = unquote(granularity)
        expected = user.id |> Stats.link_stats_by_user_id(granularity) |> Repo.all()

        query = %{"granularity" => granularity}
        conn = get(conn, ~p"/stats?#{query}")
        assert resp = html_response(conn, 200)

        doc = EasyHTML.parse!(resp)
        table = doc["tbody#link-stats"]

        # for all trs within, take the first 3 td children, and give back String.trim'd HTML text, grouped by the tr
        # example: [slug, url, count] -> ["grtgez", "http://towne.info", "98"]
        trimmed_rows =
          get_in(table, ["tr", html_all(), "td", html_children_slice(0..2), html_all(), html_trimmed_text()])

        assert length(trimmed_rows) == length(expected)

        for target <- expected do
          text_target = [target.slug, target.original_url, to_string(target.visits)]

          assert text_target in trimmed_rows
        end
      end

      test "displays download link with #{granularity} granularity", %{conn: conn} do
        granularity = unquote(granularity)
        query = %{"granularity" => granularity}
        conn = get(conn, ~p"/stats?#{query}")
        assert resp = html_response(conn, 200)
        doc = EasyHTML.parse!(resp)

        links = get_in(doc, ["a[href^='/stats/download']", html_attribute("href")])
        assert links not in [nil, []]

        assert links == ["/stats/download?granularity=#{granularity}"]
      end
    end

    @tag :skip
    test "does not display another user's links"
  end

  describe "index without authentication" do
    test "responds 401", %{conn: conn} do
      conn = get(conn, ~p"/stats")
      assert text_response(conn, 401) == "Unauthorized"
    end
  end

  describe "download with authentication" do
    @describetag :authenticated
    setup :generate_visits

    for granularity <- ~w(total daily hourly)a do
      test "provides a CSV with #{granularity} granularity", %{conn: conn, user: user} do
        granularity = unquote(granularity)
        conn = get(conn, ~p"/stats/download?granularity=#{granularity}")
        assert response_content_type(conn, :csv)
        assert [header] = get_resp_header(conn, "content-disposition")
        assert header =~ ~r/^attachment; filename=.+\.csv$/
        assert resp = response(conn, 200)

        expected = user.id |> Stats.link_stats_by_user_id(granularity) |> Repo.all()

        parsed =
          resp
          |> NimbleCSV.RFC4180.parse_string()
          |> Enum.map(fn
            [slug, url, visits] ->
              %{slug: slug, original_url: url, visits: String.to_integer(visits)}

            [slug, url, visits, date] ->
              %{slug: slug, original_url: url, visits: String.to_integer(visits), date: Date.from_iso8601!(date)}

            [slug, url, visits, date, hour] ->
              %{
                slug: slug,
                original_url: url,
                visits: String.to_integer(visits),
                date: Date.from_iso8601!(date),
                hour: String.to_integer(hour)
              }
          end)

        assert length(expected) == length(parsed)

        for row <- expected do
          assert row in parsed
        end
      end
    end
  end

  describe "download without authentication" do
    test "responds 401", %{conn: conn} do
      conn = get(conn, ~p"/stats/download")
      assert text_response(conn, 401) == "Unauthorized"
    end
  end

  defp generate_visits(%{user: user}) do
    links =
      for _n <- 1..3 do
        {:ok, link} = Links.create_link(user.id, Faker.Internet.url())
        link
      end

    today = Date.utc_today()

    for link <- links, date <- [-2, -1, 0], hour <- 0..23 do
      count = Enum.random(0..100)
      Repo.insert!(%Visit{link_id: link.id, date: Date.add(today, date), hour: hour, count: count})
    end

    %{links: links}
  end
end
