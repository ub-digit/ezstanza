defmodule Ezstanza.Repo.Migrations.CreateDeployment do
  use Ecto.Migration

  def change do
    create table(:deployment) do
      add :status, :string
      add :config_revision_id, references(:config_revision, on_delete: :nothing)
      add :deploy_target_id, references(:deploy_target, on_delete: :nothing)
      add :user_id, references(:user, on_delete: :nothing)

      timestamps()
    end

    create index(:deployment, [:config_revision_id])
    create index(:deployment, [:deploy_target_id])
    create index(:deployment, [:user_id])
  end
end
