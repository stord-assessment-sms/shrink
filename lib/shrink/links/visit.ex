defmodule Shrink.Links.Visit do
  @moduledoc """
  A per-day, per-hour record of incoming traffic to a `Shrink.Links.Link`.
  """
  use Shrink.Schema

  @type t :: %__MODULE__{
          link_id: Ecto.UUID.t() | nil,
          date: Date.t() | nil,
          # assumed to be in the range 0-23
          hour: non_neg_integer() | nil,
          count: non_neg_integer() | nil
        }

  @primary_key false
  schema "link_visits" do
    field :link_id, Ecto.UUID, primary_key: true
    field :date, :date, primary_key: true
    field :hour, :integer, primary_key: true
    field :count, :integer
  end
end
