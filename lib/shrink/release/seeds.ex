defmodule Shrink.Release.Seeds do
  @moduledoc """
  Idempotent database seeds to complete application setup.
  """
  def run do
    Ecto.Migrator.with_repo(Shrink.Repo, &users/1)
  end

  @users [
    %{
      id: "ad615e46-0e25-47b1-a727-eab97f5f0ec8",
      email: "user@example.com"
    },
    %{
      id: "c414692c-c190-4687-8cc1-c11914663fe8",
      email: "shane@sveller.dev"
    }
  ]

  def users(repo) do
    users =
      Enum.map(@users, fn user ->
        user
        |> Map.update!(:id, &Ecto.UUID.dump!/1)
        |> Map.merge(%{inserted_at: {:placeholder, :now}, updated_at: {:placeholder, :now}})
      end)

    repo.insert_all("users", users,
      conflict_target: [:id],
      on_conflict: {:replace, [:email]},
      placeholders: %{now: DateTime.utc_now()}
    )
  end
end
