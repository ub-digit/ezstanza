defmodule EzstanzaWeb.StanzaView do
  use EzstanzaWeb, :view
  alias EzstanzaWeb.StanzaView
  alias EzstanzaWeb.UserView

  def render("index.json", %{stanzas: stanzas}) do
    %{data: render_many(stanzas, StanzaView, "stanza.json")}
  end

  def render("show.json", %{stanza: stanza}) do
    %{data: render_one(stanza, StanzaView, "stanza.json")}
  end

  def render("stanza.json", %{stanza: stanza}) do
    %{
      id: stanza.id,
      revision_id: stanza.current_revision.id,
      name: stanza.name,
      body: stanza.current_revision.body,
      user: render_one(stanza.user, UserView, "user_snippet.json"),
      revision_user: render_one(stanza.current_revision.user, UserView, "user_snippet.json"),
    }
  end
end
