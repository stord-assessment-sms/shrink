defmodule Shrink.LinksTest do
  use Shrink.DataCase, async: true

  alias Shrink.Links
  alias Shrink.Links.Visit

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

  describe "visit_link_by_slug/1" do
    setup do
      user = insert(:user)
      {:ok, link} = Links.create_link(user.id, Faker.Internet.url())
      %{link: link, user: user}
    end

    test "returns link if match exists", %{link: link} do
      assert Links.visit_link_by_slug(link.slug) == link.original_url
    end

    test "returns nil if no match exists", %{link: link} do
      Repo.delete!(link)
      assert Links.visit_link_by_slug(link.slug) == nil
    end

    test "records initial count if match exists", %{link: link} do
      id = link.id
      query = from(v in Visit, where: [link_id: ^id])
      refute Repo.exists?(query)
      assert Links.visit_link_by_slug(link.slug) == link.original_url
      assert %{count: 1} = Repo.get_by(Visit, link_id: link.id, date: Date.utc_today(), hour: Time.utc_now().hour)
    end

    test "increments existing count if match exists", %{link: link} do
      count = Enum.random(3..10)
      id = link.id
      Repo.insert!(%Visit{link_id: id, hour: Time.utc_now().hour, date: Date.utc_today(), count: count - 1})
      assert Links.visit_link_by_slug(link.slug) == link.original_url
      assert %{count: ^count} = Repo.get_by(Visit, link_id: link.id, date: Date.utc_today(), hour: Time.utc_now().hour)
    end

    test "does not insert count if no match exists", %{link: link} do
      Repo.delete!(link)
      assert Links.visit_link_by_slug(link.slug) == nil
      id = link.id
      query = from(v in Visit, where: [link_id: ^id])
      refute Repo.exists?(query)
    end
  end
end
