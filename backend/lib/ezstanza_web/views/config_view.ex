defmodule EzstanzaWeb.ConfigView do
  use EzstanzaWeb, :view
  alias EzstanzaWeb.ConfigView

  alias EzstanzaWeb.UserView
  alias EzstanzaWeb.StanzaRevisionView

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

  # TODO: Remove, currently not used?
  def render("config_snippet.json", %{config: config}) do
    %{
      id: config.id,
      revision_id: config.current_config_revision_id,
      name: config.name,
    }
  end

  def render("config.json", %{config: config}) do
    %{
      id: config.id,
      revision_id: config.current_config_revision_id,
      name: config.name,
      color: config.color,
      inserted_at: config.inserted_at,
      updated_at: config.updated_at,
      user: render_one(config.user, UserView, "user_snippet.json"),
      revision_user: render_one(config.current_revision.user, UserView, "user_snippet.json"),
      stanza_revisions: render_many(config.current_revision.stanza_revisions, StanzaRevisionView, "stanza_revision.json"),
    }
  end
end
