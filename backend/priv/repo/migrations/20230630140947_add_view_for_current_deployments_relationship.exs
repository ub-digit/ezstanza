defmodule Ezstanza.Repo.Migrations.AddViewForCurrentDeploymentsRelationship do
  use Ecto.Migration

  def up do
    execute """
    CREATE VIEW stanza_revision_current_deployment AS
      SELECT stanza_revision_id, d.id AS deployment_id FROM stanza_revision sr
        JOIN deployment_stanza_revision d_sr ON sr.id = d_sr.stanza_revision_id
        JOIN deployment d ON d.id = d_sr.deployment_id
        JOIN deploy_target dt ON dt.current_deployment_id = d.id;
    """
  end

  def down do
    execute "DROP VIEW stanza_revision_current_deployment;"
  end
end
