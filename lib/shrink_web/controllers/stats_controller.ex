defmodule ShrinkWeb.StatsController do
  use ShrinkWeb, :controller

  alias Shrink.Repo
  alias Shrink.Stats

  plug ShrinkWeb.Plugs.RequireUser

  def download(conn, params) do
    granularity = granularity_for(params)
    fields = fields_for(granularity)
    headers = fields |> Enum.map(&to_string/1) |> Enum.intersperse(~c",")
    user_id = get_in(conn.private, [:current_user, Access.key(:id)])

    # This could still exhaust system memory with system volume as written, but
    # I've taken basic measures to not allocate enormous single binaries by
    # targeting iolists.
    #
    # A slightly more scalable solution may be to stream directly to a temporary
    # file, then Plug.Conn.send_file/5 that.
    #
    # A more robust solution would be similarily publish it into a cloud storage
    # destination such as S3, then provide the user a signed URL to that file,
    # and set up a lifecycle rule or background job to later expire it from storage.
    # If sufficient data volume is expected, this could be deferred via Oban
    # and later delivered via an email or on-screen notification via Phoenix
    # PubSub, etc..
    query = Stats.link_stats_by_user_id(user_id, granularity)

    {:ok, visits} =
      Repo.transaction(fn repo ->
        query
        |> repo.stream()
        |> Stream.map(fn row -> Enum.map(fields, &row[&1]) end)
        |> NimbleCSV.RFC4180.dump_to_iodata()
      end)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", "attachment; filename=stats-#{granularity}.csv")
    |> resp(200, [headers, "\r\n", visits])
    |> send_resp()
    |> halt()
  end

  def index(conn, params) do
    granularity = granularity_for(params)
    user_id = get_in(conn.private, [:current_user, Access.key(:id)])
    links = user_id |> Stats.link_stats_by_user_id(granularity) |> Repo.all()
    render(conn, :index, granularity: granularity, links: links, page_title: "Link Statistics")
  end

  for kind <- ~w(total daily hourly)a do
    defp granularity_for(%{"granularity" => unquote(to_string(kind))}), do: unquote(kind)
  end

  defp granularity_for(_params), do: :total

  defp fields_for(granularity) do
    case granularity do
      :total -> [:slug, :original_url, :visits]
      :daily -> [:slug, :original_url, :visits, :date]
      :hourly -> [:slug, :original_url, :visits, :date, :hour]
    end
  end
end
