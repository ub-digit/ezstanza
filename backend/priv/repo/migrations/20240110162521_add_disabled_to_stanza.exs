defmodule Ezstanza.Repo.Migrations.AddDeletedAndDisabledToStanza do
  use Ecto.Migration

  def change do
    alter table("stanza") do
      add :disabled, :boolean, default: false, null: false
    end

    create index(:stanza, [:disabled])
  end
end
