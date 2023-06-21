defmodule EzstanzaWeb.DeployTargetView do
  use EzstanzaWeb, :view
  import EzstanzaWeb.ViewRelationshipHelpers

  alias EzstanzaWeb.DeployTargetView
  alias EzstanzaWeb.ConfigView
  alias EzstanzaWeb.DeploymentView

  def render("index.json", %{deploy_targets: deploy_targets}) do
    %{data: render_many(deploy_targets, DeployTargetView, "deploy_target.json")}
  end

  def render("show.json", %{deploy_target: deploy_target}) do
    %{data: render_one(deploy_target, DeployTargetView, "deploy_target.json")}
  end

  def render("deploy_target.json", %{deploy_target: deploy_target}) do
    %{
      id: deploy_target.id,
      name: deploy_target.name,
      default_config_id: deploy_target.default_config_id,
      inserted_at: deploy_target.inserted_at,
      updated_at: deploy_target.updated_at,
      options: deploy_target.options
    }
    |> Map.merge(maybe_render_relationship(deploy_target, :current_deployment, DeploymentView, "deployment.json"))
  end

  def render("deploy_target_snippet.json", %{deploy_target: deploy_target}) do
    %{
      id: deploy_target.id,
      name: deploy_target.name,
      default_config_id: deploy_target.default_config_id
    }
  end

end
