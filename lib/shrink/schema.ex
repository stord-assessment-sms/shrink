defmodule Shrink.Schema do
  @moduledoc "Supplement for `use Ecto.Schema` to reduce duplication"
  defmacro __using__(opts) do
    quote do
      use Ecto.Schema, unquote(opts)

      @primary_key {:id, :binary_id, [autogenerate: true]}
      @foreign_key_type :binary_id
      @timestamp_opts [type: :utc_datetime]
    end
  end
end
