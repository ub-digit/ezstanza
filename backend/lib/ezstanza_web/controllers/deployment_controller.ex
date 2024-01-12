defmodule EzstanzaWeb.DeploymentController do
  use EzstanzaWeb, :controller

  alias EzstanzaWeb.Plug.Auth

  alias Ezstanza.Deployments
  alias Ezstanza.Deployments.Deployment

  alias EzstanzaWeb.Endpoint

  action_fallback EzstanzaWeb.FallbackController

  def normalize_index_params(params) do
    Enum.reduce(params, %{}, fn {key, value}, normalized_params ->
      case {key, value} do
        {"is_current_deployment", "true"} ->
          Map.put(normalized_params, key, true)
        {"is_current_deployment", "false"} ->
          Map.put(normalized_params, key, false)
        {"is_current_deployment", _} ->
          normalized_params
        _ ->
          Map.put(normalized_params, key, value)
      end
    end)
  end

  def index(conn, %{"page" => _page, "size" => _size} = params) do
    result = params
             |> normalize_index_params()
             |> Deployments.paginate_deployments()
    render(conn, "index.json", deployments: result.entries, pages: result.pages, total: result.total)
  end

  def index(conn, params) do
    deployments = params
                  |> normalize_index_params()
                  |> Deployments.list_deployments()
    render(conn, "index.json", deployments: deployments)
  end

  def create(conn, %{"deployment" => deployment_params}) do
    user = Auth.current_user(conn)
    deployment_params = Map.merge(deployment_params, %{"user_id" => user.id})
    with {:ok, %Deployment{id: deployment_id}} <- Deployments.create_deployment(deployment_params) do
      # Testing broadcast
      Endpoint.broadcast("deployment", "deployment_status_change", %{id: deployment_id, status: "pending"})
      deployment = Deployments.get_deployment(deployment_id)
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.deployment_path(conn, :show, deployment))
      |> render("show.json", deployment: deployment)
    end
  end

  def show(conn, %{"id" => id}) do
    deployment = Deployments.get_deployment(id)
    render(conn, "show.json", deployment: deployment)
  end

end
