defmodule Shrink.Users do
  @moduledoc """
  Read-only Context for interacting with `Shrink.Users.User`.
  """

  import Ecto.Query, only: [from: 2]

  alias Shrink.Repo
  alias Shrink.Users.User

  @doc "Look up a single `User` by its UUID"
  @spec get_user_by_id(User.id()) :: User.t() | nil
  def get_user_by_id(id) do
    Repo.one(from(u in User, where: [id: ^id]))
  end
end
