defmodule Shrink.Stats do
  @moduledoc false
  import Ecto.Query

  alias Shrink.Links.Link
  alias Shrink.Links.Visit

  @type granularity :: :total | :daily

  @spec link_stats_by_user_id(Shrink.Users.User.id(), granularity, Ecto.Queryable.t()) :: Ecto.Queryable.t()
  def link_stats_by_user_id(user_id, granularity \\ :total, queryable \\ Link)

  def link_stats_by_user_id(user_id, :total, queryable) do
    from(l in queryable,
      left_join: v in Visit,
      on: v.link_id == l.id,
      where: l.user_id == ^user_id,
      select: %{slug: l.slug, original_url: l.original_url, visits: coalesce(sum(v.count), 0)},
      group_by: [l.slug, l.original_url],
      order_by: [asc: l.original_url, asc: l.slug]
    )
  end

  def link_stats_by_user_id(user_id, :daily, queryable) do
    from(l in queryable,
      left_join: v in Visit,
      on: v.link_id == l.id,
      where: l.user_id == ^user_id,
      select: %{
        slug: l.slug,
        original_url: l.original_url,
        date: coalesce(v.date, fragment("current_date")),
        visits: coalesce(sum(v.count), 0)
      },
      group_by: [l.slug, l.original_url, v.date],
      order_by: [asc: l.slug, desc: v.date]
    )
  end

  def link_stats_by_user_id(user_id, :hourly, queryable) do
    from(l in queryable,
      left_join: v in Visit,
      on: v.link_id == l.id,
      where: l.user_id == ^user_id,
      select: %{
        slug: l.slug,
        original_url: l.original_url,
        date: coalesce(v.date, fragment("current_date")),
        hour: coalesce(v.hour, fragment("date_part('hour', now())::smallint")),
        visits: coalesce(sum(v.count), 0)
      },
      group_by: [l.slug, l.original_url, v.date, v.hour],
      order_by: [asc: l.slug, desc: v.date, desc: v.hour]
    )
  end
end
