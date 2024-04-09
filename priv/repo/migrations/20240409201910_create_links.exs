defmodule Shrink.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  # excellent_migrations:safety-assured-for-this-file index_not_concurrently

  def change do
    create table(:links, primary_key: [name: :id, type: :binary_id]) do
      add :slug, :string, size: 16, null: false
      add :original_url, :string, null: false

      add :user_id,
          references(:users,
            on_delete: :delete_all,
            on_update: :restrict,
            name: "links_user_id_fkey"
          ),
          null: false

      timestamps()
    end

    create unique_index(:links, [:slug])
    create index(:links, [:inserted_at])
    create index(:links, [:original_url])
  end
end
