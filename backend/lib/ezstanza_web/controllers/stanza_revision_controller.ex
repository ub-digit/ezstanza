defmodule EzstanzaWeb.StanzaRevisionController do
  use EzstanzaWeb, :controller

  alias Ezstanza.Stanzas
  alias Ezstanza.Stanzas.StanzaRevision

  action_fallback EzstanzaWeb.FallbackController

  plug EzstanzaWeb.Plug.GetEntity, %{
    callback: {Ezstanza.Stanzas, :get_stanza_revision},
    assigns_key: :stanza_revision
  } when action in [:show, :delete]

  def index(conn, %{"stanza_id" => _stanza_id} = params) do
    stanza_revisions = Stanzas.list_stanza_revisions(params)
    render(conn, "index.json", stanza_revisions: stanza_revisions)
  end

  def show(conn, %{"id" => _id}) do
    stanza_revision = conn.assigns[:stanza_revision]
    render(conn, "show.json", stanza_revision: stanza_revision)
  end

  def delete(conn, %{"id" => _id}) do
    stanza_revision = conn.assigns[:stanza_revision]
    with {:ok, %StanzaRevision{}} <- Stanzas.delete_stanza_revision(stanza_revision) do
      send_resp(conn, :no_content, "")
    end
  end
end
