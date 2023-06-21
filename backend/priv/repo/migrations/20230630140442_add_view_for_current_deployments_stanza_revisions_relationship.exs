defmodule Ezstanza.Repo.Migrations.AddViewForCurrentDeploymentsStanzaRevisions do
  use Ecto.Migration

  def up do
    execute """
    CREATE VIEW stanza_current_deployment_stanza_revision AS
      SELECT DISTINCT stanza_id, stanza_revision_id
      FROM stanza_revision sr
        JOIN config_revision_stanza_revision cr_sr ON sr.id = cr_sr.stanza_revision_id
        JOIN config_revision cr ON cr_sr.config_revision_id = cr.id
        JOIN deployment d ON d.config_revision_id = cr.id JOIN deploy_target dt on dt.current_deployment_id = d.id;
    """
  end

  def down do
    execute "DROP VIEW stanza_current_deployment_stanza_revision;"
  end
end
