defmodule Shrink.Users.User do
  @moduledoc """
  Placeholder `Ecto.Schema` for a `users` table with at least `email`, and `id` fields.

  Never written to outside of seeds, so no changeset/validations provided.
  """
  use Shrink.Schema

  @type id :: Ecto.UUID.t()
  @type t :: %__MODULE__{
          id: id | nil,
          email: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "users" do
    field :email, :string
    timestamps()
  end
end
