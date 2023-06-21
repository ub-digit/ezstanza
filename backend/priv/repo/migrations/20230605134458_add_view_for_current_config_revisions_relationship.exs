defmodule Ezstanza.Repo.Migrations.AddViewForCurrentConfigRevisionsRelationship do
  use Ecto.Migration

  def up do
    execute """
    CREATE VIEW stanza_current_config_revision_stanza_revision AS
      SELECT DISTINCT sr.stanza_id, cr_sr.stanza_revision_id
      FROM stanza_revision sr
        JOIN config_revision_stanza_revision cr_sr ON sr.id = cr_sr.stanza_revision_id
        JOIN config c ON cr_sr.config_revision_id = c.current_config_revision_id;
    """
  end

  def down do
    execute "DROP VIEW stanza_current_config_revision_stanza_revision;"
  end
end
