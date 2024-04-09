defmodule Shrink.Links.Query do
  @moduledoc """
  Query helpers for `Shrink.Links.Link` rows to keep database logic out of
  controllers and better composable.
  """
  import Ecto.Query

  alias Shrink.Links.Link
  alias Shrink.Users.User

  @doc "Look up a single `Link` by its `slug`"
  @spec link_by_slug(Ecto.Queryable.t(), Link.slug()) :: Ecto.Queryable.t()
  def link_by_slug(queryable \\ Link, slug) do
    from(l in queryable, where: [slug: ^slug])
  end

  @doc "Look up recently-recreated `Link` owned by a given `User` ID"
  @spec recent_links_by_user_id(Ecto.Queryable.t(), User.id()) :: Ecto.Queryable.t()
  def recent_links_by_user_id(queryable \\ Link, user_id) do
    from(l in queryable, where: [user_id: ^user_id], order_by: [desc: :inserted_at], limit: 10)
  end
end
