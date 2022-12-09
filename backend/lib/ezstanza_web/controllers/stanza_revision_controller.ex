defmodule EzstanzaWeb.StanzaRevisionController do
  use EzstanzaWeb, :controller

  alias Ezstanza.Stanzas
  alias Ezstanza.Stanzas.StanzaRevision

  action_fallback EzstanzaWeb.FallbackController

  plug EzstanzaWeb.Plug.GetEntity, %{
    callback: {Ezstanza.Stanzas, :get_stanza_revision},
    assigns_key: :stanza_revision
  } when action in [:show, :delete]


  # TODO: split ids, convert string to integers etc?
  def normalize_index_params(params) do
    Enum.reduce(params, %{}, fn {key, value}, normalized_params ->
      case {key, value} do
        {"is_current_revision", "true"} ->
          Map.put(normalized_params, key, true)
        {"is_current_revision", "false"} ->
          Map.put(normalized_params, key, false)
        {"is_current_revision", _} ->
          normalized_params
        _ ->
          Map.put(normalized_params, key, value)
      end
    end)
  end

  def index(conn, %{"page" => _page, "size" => _size} = params) do
    result = params
             |> normalize_index_params()
             |>Stanzas.paginate_stanza_revisions()
    render(conn, "index.json", stanza_revisions: result.entries, pages: result.pages, total: result.total)
  end

  def index(conn, %{"stanza_id" => _stanza_id} = params) do
    stanza_revisions = params
                       |> normalize_index_params()
                       |> Stanzas.list_stanza_revisions()
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
