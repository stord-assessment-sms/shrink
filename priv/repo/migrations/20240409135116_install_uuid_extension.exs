defmodule Shrink.Repo.Migrations.InstallUuidExtension do
  use Ecto.Migration

  def change do
    # excellent_migrations:safety-assured-for-next-line raw_sql_executed
    execute(~s{CREATE EXTENSION "uuid-ossp"}, ~s{DROP EXTENSION "uuid-ossp"})
  end
end
