defmodule Shrink.Stats.VisitDebouncerTest do
  use Shrink.DataCase, async: true

  alias Shrink.Links
  alias Shrink.Links.Visit
  alias Shrink.Repo
  alias Shrink.Stats.VisitDebouncer

  describe "init/1" do
    test "sets empty state" do
      assert VisitDebouncer.init(nil) == {:ok, %{}}
    end
  end

  describe "handle_cast/2 with visit tuple" do
    setup do
      user = insert(:user)

      {:ok, link} = Links.create_link(user.id, Faker.Internet.url())

      %{link: link, user: user}
    end

    test "records first visit for new link_id", %{link: link} do
      assert {:noreply, state, _timeout} = VisitDebouncer.handle_cast({:visit, link.slug}, %{"other_slug" => 1})
      assert state[link.slug] == 1
    end

    test "increments visit for existing link_id", %{link: link} do
      assert {:noreply, state, _timeout} = VisitDebouncer.handle_cast({:visit, link.slug}, %{link.slug => 1})
      assert state[link.slug] == 2
    end

    test "sets timeout", %{link: link} do
      assert {:noreply, _new_state, timeout} = VisitDebouncer.handle_cast({:visit, link.slug}, %{})

      if timeout != :infinity do
        assert timeout > 0
        assert timeout < 5000
      end
    end

    @tag :skip
    test "always flushes every minute"
  end

  describe "handle_info/2 with timeout atom" do
    setup do
      user = insert(:user)

      links =
        for _n <- 1..3 do
          {:ok, link} = Links.create_link(user.id, Faker.Internet.url())
          link
        end

      %{links: links, user: user}
    end

    test "flushes counts to database", %{links: links} do
      date = Date.utc_today()
      now = Time.utc_now().hour

      state =
        Map.new(links, fn link ->
          {link.slug, Enum.random(1..100)}
        end)

      assert Repo.aggregate(Visit, :count) == 0
      assert {:noreply, new_state} = VisitDebouncer.handle_info(:timeout, state)
      assert new_state == %{}

      for link <- links do
        assert record = Repo.get_by(Visit, link_id: link.id, date: date, hour: now)

        assert record.count == state[link.slug]
      end
    end

    test "merges counts to database with existing rows", %{links: [link | _] = links} do
      date = Date.utc_today()
      now = Time.utc_now().hour
      existing = Enum.random(3..5)

      Repo.insert!(%Visit{link_id: link.id, date: date, hour: now, count: existing})

      state =
        Map.new(links, fn link ->
          {link.slug, Enum.random(1..100)}
        end)

      assert {:noreply, _new_state} = VisitDebouncer.handle_info(:timeout, state)

      assert record = Repo.get_by(Visit, link_id: link.id, date: date, hour: now)
      assert record.count == state[link.slug] + existing
    end

    test "no-ops with empty state" do
      assert Repo.aggregate(Visit, :count) == 0
      assert {:noreply, _state} = VisitDebouncer.handle_info(:timeout, %{})
      assert Repo.aggregate(Visit, :count) == 0
    end
  end
end
