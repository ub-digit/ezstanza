defmodule EzstanzaWeb.TagView do
  use EzstanzaWeb, :view
  alias EzstanzaWeb.TagView
  alias EzstanzaWeb.UserView

  def render("index.json", %{tags: tags, pages: pages, total: total}) do
    %{
      data: render_many(tags, TagView, "tag.json"),
      pages: pages,
      total: total
    }
  end

  def render("index.json", %{tags: tag}) do #tags: ??
    %{data: render_many(tag, TagView, "tag.json")}
  end

  def render("show.json", %{tag: tag}) do
    %{data: render_one(tag, TagView, "tag.json")}
  end

  def render("tag.json", %{tag: tag}) do
    %{
      id: tag.id,
      name: tag.name,
      inserted_at: tag.inserted_at,
      updated_at: tag.updated_at,
      user: render_one(tag.user, UserView, "user_snippet.json"),
    }
  end

  def render("tag_snippet.json", %{tag: tag}) do
    %{
      id: tag.id,
      name: tag.name,
    }
  end
end
