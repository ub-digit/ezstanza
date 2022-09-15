defmodule EzstanzaWeb.ConfigView do
  use EzstanzaWeb, :view
  alias EzstanzaWeb.ConfigView

  alias EzstanzaWeb.UserView

  def render("index.json", %{configs: configs, pages: pages, total: total}) do
    %{
      data: render_many(configs, ConfigView, "config.json"),
      pages: pages,
      total: total
    }
  end

  def render("index.json", %{configs: configs}) do
    %{data: render_many(configs, ConfigView, "config.json")}
  end

  def render("show.json", %{config: config}) do
    %{data: render_one(config, ConfigView, "config.json")}
  end

  def render("config.json", %{config: config}) do
    %{
      id: config.id,
      revision_id: config.current_revision.id,
      name: config.name,
      inserted_at: config.inserted_at,
      updated_at: config.updated_at,
      user: render_one(config.user, UserView, "user_snippet.json"),
      revision_user: render_one(config.current_revision.user, UserView, "user_snippet.json"),
    }
  end
end
