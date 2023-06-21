defmodule Ezstanza.Repo.Migrations.AddCurrentDeploymentIdToDeployTarget do
  use Ecto.Migration

  def change do
    alter table("deploy_target") do
      add :current_deployment_id, references(:deployment, on_delete: :restrict)
    end
  end
end
