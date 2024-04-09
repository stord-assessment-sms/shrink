defmodule ShrinkWeb.LinkController do
  use ShrinkWeb, :controller

  alias Shrink.Links
  alias Shrink.Links.Link

  plug :require_user when action not in [:show]

  def new(conn, _params) do
    changeset = Links.change_link(%Link{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"link" => %{"original_url" => url}}) do
    user_id = get_in(conn.private, [:current_user, Access.key(:id)])

    case Links.create_link(user_id, url) do
      {:ok, link} ->
        conn
        |> put_flash(:info, "Link '#{link.slug}' created successfully.")
        |> put_status(:created)
        |> new(%{})

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, recent_links: [])
    end
  end

  def show(conn, %{"slug" => slug}) do
    case Links.get_link_by_slug(slug) do
      nil ->
        conn
        |> put_status(:not_found)
        |> text("Not Found")
        |> halt()

      link ->
        conn
        |> put_status(:moved_permanently)
        |> redirect(external: link.original_url)
    end
  end

  defp require_user(conn, _opts) do
    if conn.private[:current_user] == nil do
      conn
      |> put_status(:unauthorized)
      |> text("Unauthorized")
      |> halt()
    else
      conn
    end
  end
end
