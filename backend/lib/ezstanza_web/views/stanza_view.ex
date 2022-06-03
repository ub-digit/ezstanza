defmodule EzstanzaWeb.StanzaView do
  use EzstanzaWeb, :view
  alias EzstanzaWeb.StanzaView

  def render("index.json", %{stanza: stanza}) do
    %{data: render_many(stanza, StanzaView, "stanza.json")}
  end

  def render("show.json", %{stanza: stanza}) do
    %{data: render_one(stanza, StanzaView, "stanza.json")}
  end

  def render("stanza.json", %{stanza: stanza}) do
    %{
      id: stanza.id,
      name: stanza.name
    }
  end
end
