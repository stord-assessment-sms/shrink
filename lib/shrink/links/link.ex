defmodule Shrink.Links.Link do
  @moduledoc """
  A single shortened URL.

  # Important Fields

  - `slug` - a short string segment specific to this app and guaranteed unique,
           used as a public-faking lookup value
  - `original_url` - the unmodified (but validated) HTTP/S URL submitted by the user
  """
  use Shrink.Schema

  import Ecto.Changeset

  alias Shrink.Users.User

  @required_fields ~w(original_url slug user_id)a
  @allowed_fields @required_fields -- [:slug]

  @type slug :: String.t()
  @type t :: %__MODULE__{
          original_url: String.t() | URI.t() | nil,
          slug: slug | nil,
          user: User.t() | Ecto.Association.NotLoaded.t() | nil,
          user_id: Ecto.UUID.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }
  @type url :: URI.t() | String.t()

  schema "links" do
    field :original_url, :string
    field :slug, :string

    belongs_to :user, User

    timestamps()
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = link, attrs) do
    link
    |> cast(attrs, @allowed_fields)
    |> cast_assoc(:user)
    |> maybe_set_id()
    |> maybe_set_slug()
    |> validate_required(@required_fields)
    |> validate_url()
    |> unique_constraint(:slug)
    |> assoc_constraint(:user)
  end

  defp maybe_set_id(changeset) do
    case fetch_field(changeset, :id) do
      {_source, nil} ->
        put_change(changeset, :id, Ecto.UUID.generate())

      :error ->
        put_change(changeset, :id, Ecto.UUID.generate())

      _ ->
        changeset
    end
  end

  defp maybe_set_slug(changeset) do
    case fetch_change(changeset, :id) do
      {:ok, id} ->
        slug = id |> Base.encode32(case: :lower, padding: false) |> String.slice(0..5)
        put_change(changeset, :slug, slug)

      :error ->
        changeset
    end
  end

  defp validate_url(changeset) do
    case fetch_field(changeset, :original_url) do
      # validate_required will detect total absence
      {_source, nil} ->
        changeset

      {_source, url} ->
        %URI{host: host, scheme: scheme} = URI.parse(url)

        if scheme in ~w(http https) and host not in [nil, ""] do
          changeset
        else
          add_error(changeset, :original_url, "must be a valid HTTP or HTTPS URL")
        end

      # validate_required will detect total absence
      :error ->
        changeset
    end
  end
end
