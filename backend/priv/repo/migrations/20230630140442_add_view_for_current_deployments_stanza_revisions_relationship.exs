defmodule Ezstanza.Repo.Migrations.AddViewForCurrentDeploymentsStanzaRevisions do
  use Ecto.Migration

  def up do
    execute """
    CREATE VIEW stanza_current_deployment_stanza_revision AS
      SELECT DISTINCT stanza_id, stanza_revision_id
      FROM stanza_revision sr
        JOIN deployment_stanza_revision d_sr ON sr.id = d_sr.stanza_revision_id
        JOIN deployment d ON d_sr.deployment_id = d.id
        JOIN deploy_target dt on dt.current_deployment_id = d.id;
    """
  end

  def down do
    execute "DROP VIEW stanza_current_deployment_stanza_revision;"
  end
end
