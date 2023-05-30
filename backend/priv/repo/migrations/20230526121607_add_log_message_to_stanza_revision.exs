defmodule Ezstanza.Repo.Migrations.AddLogMessageToStanzaRevision do
  use Ecto.Migration

  def change do
    alter table("stanza_revision") do
      add :log_message, :string
    end
  end
end
