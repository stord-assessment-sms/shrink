defmodule Shrink.Links.Query do
  @moduledoc """
  Query helpers for `Shrink.Links.Link` rows to keep database logic out of
  controllers and better composable.
  """
  import Ecto.Query

  alias Shrink.Links.Link

  @doc "Look up a single `Link` by its `slug`"
  @spec link_by_slug(Ecto.Queryable.t(), Link.slug()) :: Ecto.Queryable.t()
  def link_by_slug(queryable \\ Link, slug) do
    from(l in queryable, where: [slug: ^slug])
  end
end
