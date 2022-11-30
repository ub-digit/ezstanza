defmodule EzstanzaWeb.DeployTargetView do
  use EzstanzaWeb, :view
  alias EzstanzaWeb.DeployTargetView

  def render("index.json", %{deploy_target: deploy_target}) do
    %{data: render_many(deploy_target, DeployTargetView, "deploy_target.json")}
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
  end
end
