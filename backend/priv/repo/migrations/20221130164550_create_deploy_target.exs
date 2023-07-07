defmodule Ezstanza.Repo.Migrations.CreateDeployTarget do
  use Ecto.Migration

  def change do
    create table(:deploy_target) do
      add :name, :string
      add :color, :string, size: 6
      add :options, :map

      timestamps()
    end

  end
end
