defmodule EzstanzaWeb.DeploymentController do
  use EzstanzaWeb, :controller

  alias EzstanzaWeb.Plug.Auth

  alias Ezstanza.Deployments
  alias Ezstanza.Deployments.Deployment

  action_fallback EzstanzaWeb.FallbackController

  def index(conn, %{"page" => _page, "size" => _size} = params) do
    result = Deployments.paginate_deployments(params)
    render(conn, "index.json", deployments: result.entries, pages: result.pages, total: result.total)
  end

  def index(conn, params) do
    deployments = Deployments.list_deployment(params)
    render(conn, "index.json", deployments: deployments)
  end

  def create(conn, %{"deployment" => deployment_params}) do
    user = Auth.current_user(conn)
    deployment_params = Map.merge(deployment_params, %{"user_id" => user.id})
    with {:ok, %Deployment{id: deployment_id}} <- Deployments.create_deployment(deployment_params) do
      deployment = Deployments.get_deployment(deployment_id)
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.deployment_path(conn, :show, deployment))
      |> render("show.json", deployment: deployment)
    end
  end

  def show(conn, %{"id" => id}) do
    deployment = Deployments.get_deployment!(id)
    render(conn, "show.json", deployment: deployment)
  end

  def update(conn, %{"id" => id, "deployment" => deployment_params}) do
    deployment = Deployments.get_deployment!(id)

    with {:ok, %Deployment{} = deployment} <- Deployments.update_deployment(deployment, deployment_params) do
      render(conn, "show.json", deployment: deployment)
    end
  end

  def delete(conn, %{"id" => id}) do
    deployment = Deployments.get_deployment!(id)

    with {:ok, %Deployment{}} <- Deployments.delete_deployment(deployment) do
      send_resp(conn, :no_content, "")
    end
  end
end
