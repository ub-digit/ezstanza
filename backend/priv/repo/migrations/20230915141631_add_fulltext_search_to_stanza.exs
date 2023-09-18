defmodule Ezstanza.Repo.Migrations.AddFulltextSearchToStanza do
  use Ecto.Migration

  def change do
    alter table(:stanza) do
      add :current_stanza_revision_body, :text
    end
    execute(&execute_up/0, &execute_down/0)
  end

  defp execute_up do
    """
    ALTER TABLE stanza
      ADD COLUMN searchable tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', name), 'A') ||
        setweight(to_tsvector('english', coalesce(current_stanza_revision_body, '')), 'B')
      ) STORED;
    """
    |> repo().query!([], [log: :info])
    "CREATE INDEX stanza_searchable_idx ON stanza USING gin(searchable);"
    |> repo().query!([], [log: :info])
  end

  defp execute_down do
    "DROP INDEX stanza_searchable_idx;"
    |> repo().query!([], [log: :info])
    "ALTER TABLE stanza DROP COLUMN searchable;"
    |> repo().query!([], [log: :info])
  end
end
