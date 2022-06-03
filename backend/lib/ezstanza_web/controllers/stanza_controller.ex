defmodule EzstanzaWeb.StanzaController do
  use EzstanzaWeb, :controller

  alias EzstanzaWeb.Plug.Auth

  alias Ezstanza.Stanzas
  alias Ezstanza.Stanzas.Stanza

  action_fallback EzstanzaWeb.FallbackController

  def index(conn, _params) do
    stanza = Stanzas.list_stanza()
    render(conn, "index.json", stanza: stanza)
  end

  def create(conn, %{"stanza" => stanza_params}) do
    user = Auth.current_user(conn)
    stanza_params = Map.merge(stanza_params, %{"user_id" => user.id})

    with {:ok, %Stanza{} = stanza} <- Stanzas.create_stanza(stanza_params) do
      conn
      |> put_status(:created)
      #|> put_resp_header("location", Routes.stanza_path(conn, :show, stanza))
      |> render("show.json", stanza: stanza)
    end
  end

  def show(conn, %{"id" => id}) do
    stanza = Stanzas.get_stanza!(id)
    render(conn, "show.json", stanza: stanza)
  end

  def update(conn, %{"id" => id, "stanza" => stanza_params}) do
    user = Auth.current_user(conn)
    stanza_params = Map.merge(stanza_params, %{"user_id" => user.id})
    stanza = Stanzas.get_stanza!(id)

    with {:ok, %Stanza{} = stanza} <- Stanzas.update_stanza(stanza, stanza_params) do
      render(conn, "show.json", stanza: stanza)
    end
  end

  def delete(conn, %{"id" => id}) do
    stanza = Stanzas.get_stanza!(id)

    with {:ok, %Stanza{}} <- Stanzas.delete_stanza(stanza) do
      send_resp(conn, :no_content, "")
    end
  end
end
