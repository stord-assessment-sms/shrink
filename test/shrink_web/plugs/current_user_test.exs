defmodule ShrinkWeb.Plugs.CurrentUserTest do
  use Shrink.DataCase, async: true
  use Plug.Test

  alias Shrink.Users
  alias ShrinkWeb.Plugs.CurrentUser

  @fallback_user_id "ad615e46-0e25-47b1-a727-eab97f5f0ec8"

  setup do
    %{conn: :get |> conn("/") |> init_test_session(%{})}
  end

  describe "init/1" do
    test "passes options unmodified" do
      assert CurrentUser.init(foo: :bar) == [foo: :bar]
    end
  end

  describe "call/2 with populated session user_id" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{user_id: user.id})
      %{conn: conn, opts: CurrentUser.init([]), user: user}
    end

    test "sets current_user to corresponding DB row", %{conn: conn, opts: opts, user: user} do
      expected = Users.get_user_by_id(user.id)

      conn = CurrentUser.call(conn, opts)

      assert conn.private[:current_user] == expected
    end
  end

  describe "call/2 with invalid session user_id" do
    setup %{conn: conn} do
      user_id = Ecto.UUID.generate()
      conn = init_test_session(conn, %{user_id: user_id})
      %{conn: conn, opts: CurrentUser.init([]), user_id: user_id}
    end

    test "sets current_user to corresponding DB row", %{conn: conn, opts: opts, user_id: user_id} do
      assert Users.get_user_by_id(user_id) == nil
      conn = CurrentUser.call(conn, opts)
      assert conn.private[:current_user] == nil
    end
  end

  # NOTE: This is an insecure stub to always have an "authenticated" user without a login form
  describe "call/2 with absent session user_id" do
    setup %{conn: conn} do
      fallback_user = insert(:user, id: @fallback_user_id)

      %{conn: conn, opts: CurrentUser.init([]), user: fallback_user}
    end

    test "sets current_user to fallback DB row", %{conn: conn, opts: opts, user: user} do
      expected = Repo.reload(user)
      assert Users.get_user_by_id(@fallback_user_id) == user
      conn = CurrentUser.call(conn, opts)
      assert conn.private[:current_user] == expected
    end
  end
end
