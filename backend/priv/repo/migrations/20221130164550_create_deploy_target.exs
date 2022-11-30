defmodule Ezstanza.Repo.Migrations.CreateDeployTarget do
  use Ecto.Migration

  def change do
    create table(:deploy_target) do
      add :name, :string
      add :options, :map
      add :default_config_id, references(:config, on_delete: :nothing)

      timestamps()
    end

    create index(:deploy_target, [:default_config_id])
  end
end
