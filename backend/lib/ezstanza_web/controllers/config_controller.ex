defmodule EzstanzaWeb.ConfigController do
  use EzstanzaWeb, :controller

  alias EzstanzaWeb.Plug.Auth

  alias Ezstanza.Configs
  alias Ezstanza.Configs.Config

  action_fallback EzstanzaWeb.FallbackController

  plug EzstanzaWeb.Plug.GetEntity, %{
    callback: {Ezstanza.Configs, :get_config},
    assigns_key: :config
  } when action in [:show, :update, :delete]

  def index(conn, %{"page" => _page, "size" => _size} = params) do
    result = Configs.paginate_configs(params)
    render(conn, "index.json", configs: result.configs, pages: result.pages, total: result.total)
  end

  def index(conn, params) do
    configs = Configs.list_configs(params)
    render(conn, "index.json", configs: configs)
  end

  def create(conn, %{"config" => config_params}) do
    user = Auth.current_user(conn)
    config_params = Map.merge(config_params, %{"user_id" => user.id})

    with {:ok, %Config{id: config_id}} <- Configs.create_config(config_params) do
      config = Configs.get_config(config_id)
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.config_path(conn, :show, config))
      |> render("show.json", config: config)
    end
  end

  def show(conn, %{"id" => _id}) do
    config = conn.assigns[:config]
    render(conn, "show.json", config: config)
  end

  def update(conn, %{"id" => _id, "config" => config_params}) do
    user = Auth.current_user(conn)
    config_params = Map.merge(config_params, %{"user_id" => user.id})
    config = conn.assigns[:config]

    with {:ok, %Config{id: config_id}} <- Configs.update_config(config, config_params) do
      config = Configs.get_config(config_id)
      render(conn, "show.json", config: config)
    end
  end

  def delete(conn, %{"id" => _id}) do
    config = conn.assigns[:config]

    with {:ok, %Config{}} <- Configs.delete_config(config) do
      send_resp(conn, :no_content, "")
    end
  end
end
