defmodule Shrink.Links.CacheWarmer do
  @moduledoc false
  use Cachex.Warmer

  import Ecto.Query

  alias Shrink.Links.Link
  alias Shrink.Links.Visit

  @hot_count 30
  @recent_count 30

  def interval, do: :timer.minutes(15)

  def execute(repo) do
    recent_query = from(l in Link, order_by: [desc: l.inserted_at], limit: @recent_count, select: l.id)

    hot_query =
      from(v in Visit,
        order_by: [desc: sum(v.count)],
        group_by: v.link_id,
        where: v.date > ago(1, "week"),
        limit: @hot_count,
        select: v.link_id
      )

    query =
      from(l in Link, where: l.id in subquery(recent_query), or_where: l.id in subquery(hot_query))

    {:ok, query |> repo.all() |> Enum.map(fn link -> {link.slug, link} end)}
  end
end
