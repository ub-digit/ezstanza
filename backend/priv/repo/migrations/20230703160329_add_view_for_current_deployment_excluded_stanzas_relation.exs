defmodule Ezstanza.Repo.Migrations.AddViewForCurrentDeploymentExcludedStanzasRelation do
  use Ecto.Migration

  def up do
    execute """
    CREATE VIEW deploy_target_current_deployment_excluded_stanza AS
      SELECT dt.id AS deploy_target_id, s.id AS stanza_id FROM deploy_target dt CROSS JOIN stanza s
      WHERE s.id NOT IN (
        SELECT stanza_id FROM deployment_stanza_revision
          JOIN stanza_revision ON stanza_revision_id = id
          WHERE deployment_id = dt.current_deployment_id
      );
    """
  end

  def down do
    execute "DROP VIEW deploy_target_current_deployment_excluded_stanza;"
  end

end
