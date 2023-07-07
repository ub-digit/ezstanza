defmodule EzstanzaWeb.StanzaView do
  use EzstanzaWeb, :view
  import EzstanzaWeb.ViewRelationshipHelpers

  alias EzstanzaWeb.StanzaView
  alias EzstanzaWeb.StanzaRevisionView
  alias EzstanzaWeb.UserView
  alias EzstanzaWeb.ConfigView
  alias EzstanzaWeb.DeploymentView

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
      log_message: stanza.current_revision.log_message,
      inserted_at: stanza.inserted_at,
      updated_at: stanza.updated_at,
      user: render_one(stanza.user, UserView, "user_snippet.json"),
      revision_user: render_one(stanza.current_revision.user, UserView, "user_snippet.json"),
      current_deployments: stanza_current_deployments(stanza.current_deployments_stanza_revisions)
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

  def stanza_current_deployments(current_deployments_current_revisions) do
    current_deployments_current_revisions
    |> Enum.reduce([], fn stanza_revision, deployments ->
      stanza_revision.current_deployments
      |> Enum.map(fn deployment ->
        %{
          deployment: render_one(deployment, DeploymentView, "deployment.json"), #Snippet
          stanza_revision: render_one(stanza_revision, StanzaRevisionView, "stanza_revision_snippet.json")
        }
      end)
      |> Enum.concat(deployments)
    end)
  end


end
