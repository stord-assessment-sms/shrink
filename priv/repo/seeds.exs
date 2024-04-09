# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Shrink.Repo.insert!(%Shrink.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

users = [
  %{
    id: "ad615e46-0e25-47b1-a727-eab97f5f0ec8",
    email: "user@example.com"
  },
  %{
    id: "c414692c-c190-4687-8cc1-c11914663fe8",
    email: "shane@sveller.dev"
  }
]

Ecto.Migrator.with_repo(Shrink.Repo, fn repo ->
  users =
    Enum.map(users, fn user ->
      user
      |> Map.update!(:id, &Ecto.UUID.dump!/1)
      |> Map.merge(%{inserted_at: {:placeholder, :now}, updated_at: {:placeholder, :now}})
    end)

  repo.insert_all("users", users,
    conflict_target: [:id],
    on_conflict: {:replace, [:email]},
    placeholders: %{now: DateTime.utc_now()}
  )
end)
