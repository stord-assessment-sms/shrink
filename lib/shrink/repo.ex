defmodule Shrink.Repo do
  use Ecto.Repo,
    otp_app: :shrink,
    adapter: Ecto.Adapters.Postgres
end
