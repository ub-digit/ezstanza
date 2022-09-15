defmodule EzstanzaWeb.TagController do
  use EzstanzaWeb, :controller

  alias EzstanzaWeb.Plug.Auth

  alias Ezstanza.Tags
  alias Ezstanza.Tags.Tag

  action_fallback EzstanzaWeb.FallbackController

  plug EzstanzaWeb.Plug.GetEntity, %{
    callback: {Ezstanza.Tags, :get_tag},
    assigns_key: :tag
  } when action in [:show, :update, :delete]

  def index(conn, %{"page" => _page, "size" => _size} = params) do
    result = Tags.paginate_tags(params)
    render(conn, "index.json", tags: result.tags, pages: result.pages, total: result.total)
  end

  def index(conn, params) do
    tags = Tags.list_tags(params)
    render(conn, "index.json", tags: tags)
  end

  def create(conn, %{"tag" => tag_params}) do
    user = Auth.current_user(conn)
    tag_params = Map.merge(tag_params, %{"user_id" => user.id})

    with {:ok, %Tag{id: tag_id}} <- Tags.create_tag(tag_params) do
      tag = Tags.get_tag(tag_id)
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.tag_path(conn, :show, tag))
      |> render("show.json", tag: tag)
    end
  end

  def show(conn, %{"id" => _id}) do
    tag = conn.assigns[:tag]
    render(conn, "show.json", tag: tag)
  end

  def update(conn, %{"id" => _id, "tag" => tag_params}) do
    user = Auth.current_user(conn)
    tag_params = Map.merge(tag_params, %{"user_id" => user.id})
    tag = conn.assigns[:tag]

    with {:ok, %Tag{id: tag_id}} <- Tags.update_tag(tag, tag_params) do
      tag = Tags.get_tag(tag_id) # get_tag! ??
      render(conn, "show.json", tag: tag)
    end
  end

  def delete(conn, %{"id" => _id}) do
    tag = conn.assigns[:tag]

    with {:ok, %Tag{}} <- Tags.delete_tag(tag) do
      send_resp(conn, :no_content, "")
    end
  end
end
