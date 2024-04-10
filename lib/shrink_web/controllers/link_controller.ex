defmodule ShrinkWeb.LinkController do
  use ShrinkWeb, :controller

  alias Shrink.Links
  alias Shrink.Links.Link

  plug ShrinkWeb.Plugs.RequireUser when action not in [:show]

  def new(conn, _params) do
    changeset = Links.change_link(%Link{})
    user_id = get_in(conn.private, [:current_user, Access.key(:id)])
    links = Links.list_recent_links_by_user_id(user_id)
    render(conn, :new, changeset: changeset, page_title: "New Link", recent_links: links)
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
        render(conn, :new, changeset: changeset, page_title: "New Link", recent_links: [])
    end
  end

  def show(conn, %{"slug" => slug}) do
    case Links.visit_link_by_slug(slug) do
      nil ->
        conn
        |> put_status(:not_found)
        |> text("Not Found")
        |> halt()

      link ->
        conn
        |> put_status(:moved_permanently)
        |> redirect(external: link)
    end
  end
end
