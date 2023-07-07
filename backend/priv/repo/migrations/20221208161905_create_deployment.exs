defmodule Ezstanza.Repo.Migrations.CreateDeployment do
  use Ecto.Migration

  def change do
    create table(:deployment) do
      add :status, :string
      add :deploy_target_id, references(:deploy_target, on_delete: :delete_all)
      add :user_id, references(:user, on_delete: :nothing)

      timestamps()
    end

    create index(:deployment, [:deploy_target_id])
    create index(:deployment, [:user_id])

    create table(:deployment_stanza_revision, primary_key: false) do
      add :deployment_id, references(:deployment, on_delete: :delete_all), primary_key: true
      add :stanza_revision_id, references(:stanza_revision, on_delete: :delete_all), primary_key: true
    end

  end
end
