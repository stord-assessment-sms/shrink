defmodule Shrink.Links do
  @moduledoc """
  Read/write Context for `Shrink.Links.Links`. Central to this app's purpose.
  """

  alias Shrink.Links.Link
  alias Shrink.Links.Query
  alias Shrink.Links.Visit
  alias Shrink.Repo
  alias Shrink.Users.User

  require Logger

  @doc "Create a changeset for a `Link`, defaulting to no attributes"
  @spec change_link(Link.t(), map()) :: Ecto.Changeset.t()
  def change_link(link, attrs \\ %{}) do
    Link.changeset(link, attrs)
  end

  @doc "Create a `Link` given a `User` ID and raw URL, belonging to that `User`"
  @spec create_link(User.id(), Link.url()) :: {:ok, Link.t()} | {:error, Ecto.Changeset.t()}
  def create_link(user_id, original_url) when is_binary(original_url) do
    %Link{}
    |> Link.changeset(%{original_url: original_url, user_id: user_id})
    |> Repo.insert()
  end

  @doc "Create a `Link` given raw changeset attributes"
  @spec create_link(map()) :: {:ok, Link.t()} | {:error, Ecto.Changeset.t()}
  def create_link(attrs) when is_map(attrs) do
    %Link{}
    |> Link.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Look up a single `Link` by its slug"
  @spec get_link_by_slug(Link.slug()) :: Link.t() | nil
  def get_link_by_slug(slug) do
    Repo.one(Query.link_by_slug(slug))
  end

  @doc "List `Link`s recently created by the given `User`"
  @spec list_recent_links_by_user_id(User.id()) :: list(Link.t())
  def list_recent_links_by_user_id(user_id) do
    Repo.all(Query.recent_links_by_user_id(user_id))
  end

  @doc "Record a visit to a `Link` by its slug, if that Link exists"
  @spec visit_link_by_slug(Link.slug()) :: Link.url() | nil
  def visit_link_by_slug(slug) do
    fn repo ->
      case repo.one(Query.link_by_slug(slug)) do
        nil ->
          nil

        link ->
          repo.insert(%Visit{link_id: link.id, date: Date.utc_today(), hour: Time.utc_now().hour, count: 1},
            conflict_target: [:link_id, :date, :hour],
            on_conflict: [inc: [count: 1]]
          )

          link.original_url
      end
    end
    |> Repo.transaction()
    |> case do
      {:ok, maybe_url} ->
        maybe_url

      {:error, _changeset} ->
        Logger.error("Could not record visit for slug #{slug}")
        nil
    end
  end
end
