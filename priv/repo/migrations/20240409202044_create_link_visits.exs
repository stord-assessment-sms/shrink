defmodule Shrink.Repo.Migrations.CreateLinkVisits do
  use Ecto.Migration

  def change do
    create table(:link_visits, primary_key: false) do
      add :link_id, references(:links, on_delete: :delete_all, on_update: :restrict),
        null: false,
        primary_key: true

      add :date, :date, null: false, primary_key: true
      add :hour, :smallint, null: false, primary_key: true
      add :count, :integer, default: 0
    end

    # excellent_migrations:safety-assured-for-this-file check_constraint_added
    create constraint(:link_visits, :positive_count, check: "count >= 0")
    create constraint(:link_visits, :valid_hour, check: "hour >= 0 AND hour <= 23")
    # excellent_migrations:safety-assured-for-next-line index_not_concurrently
    create index(:link_visits, [:link_id, :date])
  end
end
