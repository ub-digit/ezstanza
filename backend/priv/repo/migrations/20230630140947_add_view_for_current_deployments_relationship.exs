defmodule Ezstanza.Repo.Migrations.AddViewForCurrentDeploymentsRelationship do
  use Ecto.Migration

  def up do
    execute """
    CREATE VIEW stanza_revision_current_deployment AS
      SELECT stanza_revision_id, d.id AS deployment_id FROM stanza_revision sr
        JOIN config_revision_stanza_revision cr_sr ON sr.id = cr_sr.stanza_revision_id
        JOIN config_revision cr ON cr.id = cr_sr.config_revision_id
        JOIN deployment d ON cr.id = d.config_revision_id
        JOIN deploy_target dt ON dt.current_deployment_id = d.id;
    """
  end

  def down do
    execute "DROP VIEW stanza_revision_current_deployment;"
  end
end
