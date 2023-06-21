defmodule EzstanzaWeb.StanzaRevisionView do
  use EzstanzaWeb, :view

  alias EzstanzaWeb.StanzaRevisionView
  alias EzstanzaWeb.UserView


  def render("index.json", %{stanza_revisions: stanza_revisions, pages: pages, total: total}) do
    %{
      data: render_many(stanza_revisions, StanzaRevisionView, "stanza_revision.json"),
      pages: pages,
      total: total
    }
  end

  def render("index.json", %{stanza_revisions: stanza_revisions}) do
    %{data: render_many(stanza_revisions, StanzaRevisionView, "stanza_revision.json")}
  end

  def render("show.json", %{stanza_revision: stanza_revision}) do
    %{data: render_one(stanza_revision, StanzaRevisionView, "stanza_revision.json")}
  end

  def render("stanza_revision.json", %{stanza_revision: stanza_revision}) do
    %{
      id: stanza_revision.id,
      stanza_id: stanza_revision.stanza_id,
      name: stanza_revision.stanza.name,
      body: stanza_revision.body,
      is_current_revision: stanza_revision.is_current_revision,
      log_message: stanza_revision.log_message,
      inserted_at: stanza_revision.inserted_at,
      updated_at: stanza_revision.updated_at,
      user: render_one(stanza_revision.stanza.user, UserView, "user_snippet.json")
      #stanza_user: render_one(stanza.user, UserView, "user_snippet.json"),
    }
  end


  def render("stanza_revision_snippet.json", %{stanza_revision: stanza_revision}) do
    %{
      id: stanza_revision.id,
      name: stanza_revision.stanza.name,
      is_current_revision: stanza_revision.is_current_revision,
      log_message: stanza_revision.log_message,
      updated_at: stanza_revision.updated_at,
      user: render_one(stanza_revision.user, UserView, "user_snippet.json")
    }
  end
end
