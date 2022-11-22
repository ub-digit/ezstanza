defmodule EzstanzaWeb.StanzaView do
  use EzstanzaWeb, :view
  import EzstanzaWeb.ViewRelationshipHelpers

  alias EzstanzaWeb.StanzaView
  alias EzstanzaWeb.StanzaRevisionView
  alias EzstanzaWeb.UserView
  alias EzstanzaWeb.ConfigView

  alias Ezstanza.Stanzas.Stanza
  alias Ezstanza.Stanzas.StanzaRevision

  def render("index.json", %{stanzas: stanzas, pages: pages, total: total}) do
    %{
      data: render_many(stanzas, StanzaView, "stanza.json"),
      pages: pages,
      total: total
    }
  end

  def render("index.json", %{stanzas: stanzas}) do
    %{data: render_many(stanzas, StanzaView, "stanza.json")}
  end

  def render("show.json", %{stanza: stanza}) do
    %{data: render_one(stanza, StanzaView, "stanza.json")}
  end

  def render("stanza.json", %{stanza: stanza}) do
    %{
      id: stanza.id,
      revision_id: stanza.current_stanza_revision_id,
      name: stanza.name,
      body: stanza.current_revision.body,
      inserted_at: stanza.inserted_at,
      updated_at: stanza.updated_at,
      user: render_one(stanza.user, UserView, "user_snippet.json"),
      revision_user: render_one(stanza.current_revision.user, UserView, "user_snippet.json"),
      current_configs: stanza_current_configs(stanza.current_configs, stanza.current_revision_current_configs)
      #current_configs: render_many(stanza.current_configs, ConfigView, "config_snippet.json"),
      #current_revision_current_configs: render_many(stanza.current_revision_current_configs, ConfigView, "config_snippet.json")
    }
    |> then(fn struct ->
      case stanza do
        # Ensure stanza revisions association is loaded and revisions have stanza association loaded.
        # Its enough to check only the first one.
        %Stanza{revisions: [%StanzaRevision{stanza: %Stanza{}} | _rest]} ->
          Map.put(struct, :revisions, render_many(stanza.revisions, StanzaRevisionView, "stanza_revision.json"))
        _ ->
          struct
      end
    end)
    #|> Map.merge(maybe_render_relationship(stanza, :revisions, StanzaRevisionView, "stanza_revision.json"))
  end

  def stanza_current_configs(current_configs, current_revision_current_configs) do
    Enum.map(current_configs, fn config ->
      %{
        id: config.id,
        name: config.name,
        color: config.color,
        revision_id: config.current_config_revision_id,
        has_current_stanza_revision: Enum.any?(current_revision_current_configs, fn c -> c.id == config.id end)
      }
    end)
  end

end
