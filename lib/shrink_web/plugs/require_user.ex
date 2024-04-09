defmodule ShrinkWeb.Plugs.RequireUser do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.private[:current_user] == nil do
      conn
      |> put_resp_content_type("text/plain")
      |> resp(:unauthorized, "Unauthorized")
      |> send_resp()
      |> halt()
    else
      conn
    end
  end
end
