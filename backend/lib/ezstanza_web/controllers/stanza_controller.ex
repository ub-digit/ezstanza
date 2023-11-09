defmodule EzstanzaWeb.StanzaController do
  use EzstanzaWeb, :controller

  alias EzstanzaWeb.Plug.Auth

  alias Ezstanza.Stanzas
  alias Ezstanza.Stanzas.Stanza

  alias Ezstanza.StanzaParser

  action_fallback EzstanzaWeb.FallbackController

  plug EzstanzaWeb.Plug.GetEntity, %{
    callback: {Ezstanza.Stanzas, :get_stanza},
    assigns_key: :stanza
  } when action in [:update, :delete]

  plug EzstanzaWeb.Plug.GetEntity, %{
    callback: {Ezstanza.Stanzas, :get_stanza},
    params_callback: {__MODULE__, :show_params},
    assigns_key: :stanza
  } when action in [:show]


  # Perhaps should also validate first?
  def normalize_index_params(params) do
    Enum.reduce(params, %{}, fn {key, value}, normalized_params ->
      case {key, value} do
        {"deployment_ids_not_equals", ids} -> # When is_list, validate before?
          Map.put(
            normalized_params,
            key,
            Enum.map(ids, &String.to_integer/1)
          )
        {"deployment_id_not_equals", id} ->
          Map.put(
            normalized_params,
            "deployment_ids_not_equal",
            [String.to_integer(id)])
        _ ->
          Map.put(normalized_params, key, value)
      end
    end)
  end



  def index(conn, %{"page" => _page, "size" => _size} = params) do
    result = params
             |> normalize_index_params()
             |> Stanzas.paginate_stanzas()
    render(conn, "index.json", stanzas: result.entries, pages: result.pages, total: result.total)
  end

  def index(conn, params) do
    stanzas = params
              |> normalize_index_params()
              |> Stanzas.list_stanzas()
    render(conn, "index.json", stanzas: stanzas)
  end

  def create(conn, %{"stanza" => stanza_params}) do
    user = Auth.current_user(conn)
    stanza_params = Map.merge(stanza_params, %{"user_id" => user.id})

    with {:ok, %Stanza{id: stanza_id}} <- Stanzas.create_stanza(stanza_params) do
      stanza = Stanzas.get_stanza(stanza_id)
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.stanza_path(conn, :show, stanza))
      |> render("show.json", stanza: stanza)
    end
  end

  def show(conn, %{"id" => _id}) do
    stanza = conn.assigns[:stanza]
    render(conn, "show.json", stanza: stanza)
  end

  # TODO: REMOVE THIS, include should be sent as array
  def show_params(conn) do
    Enum.reduce(conn.query_params, %{}, fn {key, value}, params ->
      case key do
        "include" -> Map.put(params, key, String.split(value, ","))
        _ -> params
      end
    end)
  end

  def update(conn, %{"id" => _id, "stanza" => stanza_params}) do
    user = Auth.current_user(conn)
    stanza_params = Map.merge(stanza_params, %{"user_id" => user.id})
    stanza = conn.assigns[:stanza]

    with {:ok, %Stanza{id: stanza_id}} <- Stanzas.update_stanza(stanza.id, stanza_params) do
      # Call this in multi instead?
      stanza = Stanzas.get_stanza(stanza_id)
      render(conn, "show.json", stanza: stanza)
    end
  end

  def delete(conn, %{"id" => _id}) do
    stanza = conn.assigns[:stanza]

    with {:ok, %Stanza{}} <- Stanzas.delete_stanza(stanza) do
      send_resp(conn, :no_content, "")
    end
  end

  def validate_lines(conn, %{"stanza" => %{"body" => body}}) do
    errors = body
             |> StanzaParser.parse_string()
             |> StanzaParser.line_errors()
             |> Enum.map(fn {cmd, line} ->
               %{line: line, cmd: cmd}
             end)
    conn
    |> put_status(:ok)
    |> json(%{validation_errors: errors})
  end
end
