defmodule ShrinkWeb.Plugs.CurrentUser do
  @moduledoc false
  import Plug.Conn

  alias Shrink.Users

  @fallback_user_id "ad615e46-0e25-47b1-a727-eab97f5f0ec8"

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "user_id", @fallback_user_id) do
      nil ->
        conn

      id ->
        put_private(conn, :current_user, Users.get_user_by_id(id))
    end
  end
end
