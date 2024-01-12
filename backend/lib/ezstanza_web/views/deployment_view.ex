defmodule EzstanzaWeb.DeploymentView do
  use EzstanzaWeb, :view

  import EzstanzaWeb.ViewRelationshipHelpers

  alias EzstanzaWeb.DeploymentView
  alias EzstanzaWeb.DeployTargetView
  alias EzstanzaWeb.StanzaRevisionView
  alias EzstanzaWeb.UserView

  def render("index.json", %{deployments: tags, pages: pages, total: total}) do
    %{
      data: render_many(tags, DeploymentView, "deployment.json"),
      pages: pages,
      total: total
    }
  end

  def render("index.json", %{deployments: deployment}) do
    %{data: render_many(deployment, DeploymentView, "deployment.json")}
  end

  def render("show.json", %{deployment: deployment}) do
    %{data: render_one(deployment, DeploymentView, "deployment.json")}
  end

  def render("deployment.json", %{deployment: deployment}) do
    %{
      id: deployment.id,
      deploy_target: render_one(deployment.deploy_target, DeployTargetView, "deploy_target_snippet.json"),
      user: render_one(deployment.user, UserView, "user_snippet.json"),
      inserted_at: deployment.inserted_at,
      status: deployment.status,
      is_current_deployment: deployment.is_current_deployment
    }
    # |> Map.merge(maybe_render_relationship(deployment, :stanza_revisions, StanzaRevisionView, "stanza_revision.json"))
  end
end
