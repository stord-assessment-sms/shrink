defmodule Shrink.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users,
             comment: "Placeholder table for stubbed authz/authn implementation",
             primary_key: [name: :id, type: :binary_id]
           ) do
      add :email, :string, null: false

      timestamps()
    end

    # excellent_migrations:safety-assured-for-next-line index_not_concurrently
    create unique_index(:users, [:email])
  end
end
