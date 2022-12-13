defmodule EzstanzaWeb.DeployTargetController do
  use EzstanzaWeb, :controller

  alias Ezstanza.DeployTargets
  alias Ezstanza.DeployTargets.DeployTarget

  action_fallback EzstanzaWeb.FallbackController

  def index(conn, _params) do
    deploy_targets = DeployTargets.list_deploy_targets()
    render(conn, "index.json", deploy_targets: deploy_targets)
  end

  def create(conn, %{"deploy_target" => deploy_target_params}) do
    with {:ok, %DeployTarget{} = deploy_target} <- DeployTargets.create_deploy_target(deploy_target_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.deploy_target_path(conn, :show, deploy_target))
      |> render("show.json", deploy_target: deploy_target)
    end
  end

  def show(conn, %{"id" => id}) do
    deploy_target = DeployTargets.get_deploy_target(id)
    render(conn, "show.json", deploy_target: deploy_target)
  end

  def update(conn, %{"id" => id, "deploy_target" => deploy_target_params}) do
    deploy_target = DeployTargets.get_deploy_target(id)

    with {:ok, %DeployTarget{} = deploy_target} <- DeployTargets.update_deploy_target(deploy_target, deploy_target_params) do
      render(conn, "show.json", deploy_target: deploy_target)
    end
  end

  def delete(conn, %{"id" => id}) do
    deploy_target = DeployTargets.get_deploy_target(id)

    with {:ok, %DeployTarget{}} <- DeployTargets.delete_deploy_target(deploy_target) do
      send_resp(conn, :no_content, "")
    end
  end

  def frontend_options_form_schema(conn, _) do
    #Helper in context with get_env and default value?
    provider = Application.fetch_env!(:ezstanza, :deployment_provider)
    conn
    |> put_status(:ok)
    |> json(provider.frontend_form_schema) # TODO: inconsistent naming
  end
end
