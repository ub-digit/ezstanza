defmodule EzstanzaWeb.ConfigRevisionView do
  use EzstanzaWeb, :view

  alias EzstanzaWeb.ConfigRevisionView
  alias EzstanzaWeb.UserView


  def render("index.json", %{config_revisions: config_revisions, pages: pages, total: total}) do
    %{
      data: render_many(config_revisions, ConfigRevisionView, "config_revision.json"),
      pages: pages,
      total: total
    }
  end

  def render("index.json", %{config_revisions: config_revisions}) do
    %{data: render_many(config_revisions, ConfigRevisionView, "config_revision.json")}
  end

  def render("show.json", %{config_revision: config_revision}) do
    %{data: render_one(config_revision, ConfigRevisionView, "config_revision.json")}
  end

  def render("config_revision.json", %{config_revision: config_revision}) do
    %{
      id: config_revision.id,
      config_id: config_revision.config_id,
      is_current_revision: config_revision.is_current_revision,
      name: config_revision.config.name,
      log_message: config_revision.log_message,
      color: config_revision.config.color,
      inserted_at: config_revision.inserted_at,
      updated_at: config_revision.updated_at,
      user: render_one(config_revision.config.user, UserView, "user_snippet.json"),
      revision_user: render_one(config_revision.user, UserView, "user_snippet.json"),
    }
  end
end
