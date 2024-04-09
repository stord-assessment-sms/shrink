defmodule ShrinkWeb.LinkHTML do
  use ShrinkWeb, :html

  embed_templates "link_html/*"

  @doc """
  Renders a link form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def link_form(assigns)

  attr :conn, :map, required: true
  attr :links, :list, required: true
  def recent_links_table(assigns)

  defp short_url(conn, link) do
    URI.to_string(%URI{scheme: to_string(conn.scheme), host: conn.host, port: conn.port, path: "/" <> link.slug})
  end
end
