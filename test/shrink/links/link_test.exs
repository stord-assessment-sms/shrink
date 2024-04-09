defmodule Shrink.Links.LinkTest do
  use Shrink.DataCase, async: true

  alias Shrink.Links.Link

  describe "changeset/2" do
    setup do
      %{user: insert(:user)}
    end

    test "validates required fields", %{user: user} do
      for required <- ~w(original_url user_id)a do
        attrs = :link |> params_for(user: user) |> Map.delete(required)

        changeset = Link.changeset(%Link{}, attrs)
        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset)[required]
      end
    end

    test "populates missing defaultable fields", %{user: user} do
      for defaultable <- ~w(slug)a do
        attrs = :link |> params_for(user: user) |> Map.delete(defaultable)

        changeset = Link.changeset(%Link{}, attrs)
        assert changeset.valid?
        Repo.insert!(changeset)
      end
    end

    test "validates original_url with http/https scheme", %{user: user} do
      attrs = params_for(:link, user: user)

      for invalid_scheme <- ~w(htt file mailto) do
        attrs =
          Map.update!(attrs, :original_url, fn url ->
            url
            |> URI.parse()
            |> Map.put(:scheme, invalid_scheme)
            |> URI.to_string()
          end)

        changeset = Link.changeset(%Link{}, attrs)
        refute changeset.valid?
        assert "must be a valid HTTP or HTTPS URL" in errors_on(changeset)[:original_url]
      end
    end

    test "validates user FK", %{user: user} do
      attrs = params_for(:link, user: user)
      Repo.delete!(user)

      changeset = Link.changeset(%Link{}, attrs)
      assert changeset.valid?

      assert {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset)[:user]
    end
  end
end
