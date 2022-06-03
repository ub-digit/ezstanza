defmodule EzstanzaWeb.TagView do
  use EzstanzaWeb, :view
  alias EzstanzaWeb.TagView

  def render("index.json", %{tag: tag}) do
    %{data: render_many(tag, TagView, "tag.json")}
  end

  def render("show.json", %{tag: tag}) do
    %{data: render_one(tag, TagView, "tag.json")}
  end

  def render("tag.json", %{tag: tag}) do
    %{
      id: tag.id,
      name: tag.name
    }
  end
end
