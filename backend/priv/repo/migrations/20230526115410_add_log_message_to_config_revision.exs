defmodule Ezstanza.Repo.Migrations.AddDescriptionToConfigRevision do
  use Ecto.Migration

  def change do
    alter table("config_revision") do
      add :log_message, :string
    end
  end
end
