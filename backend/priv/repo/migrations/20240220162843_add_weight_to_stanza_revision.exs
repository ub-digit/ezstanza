defmodule Ezstanza.Repo.Migrations.AddWeightToStanza do
  use Ecto.Migration

  def change do
    alter table("stanza_revision") do
      add :weight, :integer, default: 0, null: false
    end
    create index(:stanza_revision, [:weight])
  end
end
