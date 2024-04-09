defmodule Shrink.LinksTest do
  use Shrink.DataCase, async: true

  alias Shrink.Links

  describe "create_link/1" do
    setup do
      %{user: insert(:user)}
    end

    test "creates link given valid attrs map", %{user: user} do
      attrs = params_for(:link, user: user)

      assert {:ok, link} = Links.create_link(attrs)
      assert Repo.reload!(link)
      assert Map.take(link, Map.keys(attrs)) == attrs
    end

    test "returns error tuple on invalid input", %{user: user} do
      attrs = params_for(:link, original_url: nil, user: user)

      assert {:error, changeset} = Links.create_link(attrs)
      assert errors_on(changeset)[:original_url] != []
    end
  end

  describe "create_link/2" do
    setup do
      %{user: insert(:user)}
    end

    test "creates link given user_id and url", %{user: user} do
      url = params_for(:link).original_url

      assert {:ok, link} = Links.create_link(user.id, url)
      assert Repo.reload!(link)
    end

    test "returns error tuple on invalid input", %{user: user} do
      url = String.replace(Faker.Internet.url(), ~r/https?/, "ftp")

      assert {:error, changeset} = Links.create_link(user.id, url)
      assert errors_on(changeset)[:original_url] != []
    end
  end

  describe "get_link_by_slug/1" do
    test "returns link if match exists" do
      user = insert(:user)
      assert {:ok, link} = :link |> params_for(user: user) |> Links.create_link()

      assert Links.get_link_by_slug(link.slug) == link
    end

    test "returns nil if link not found" do
      slug = "abcDEF"
      assert Links.get_link_by_slug(slug) == nil
    end
  end
end
