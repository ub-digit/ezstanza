defmodule Ezconfig.Repo.Migrations.CreateConfig do
  use Ecto.Migration

  def change do
    create table(:config) do
      add :name, :string
      add :user_id, references(:user, on_delete: :nilify_all)
      timestamps()
    end

    create unique_index(:config, [:name])
    create index(:config, [:user_id])

    create table(:config_revision) do
      add :config_id, references(:config, on_delete: :delete_all)
      add :user_id, references(:user, on_delete: :nilify_all)
      timestamps()
    end

    create index(:config_revision, [:user_id])

    alter table(:config) do
      add :current_config_revision_id, references(:config_revision, on_delete: :restrict)
    end

    create unique_index(:config, [:current_config_revision_id])

    create table(:config_tag, primary_key: false) do
      add :config_id, references(:config, on_delete: :delete_all), primary_key: true
      add :tag_id, references(:tag), primary_key: true
    end

    create unique_index(:config_tag, [:config_id, :tag_id])

    create table(:config_revision_stanza_revision, primary_key: false) do
      add :config_revision_id, references(:config_revision, on_delete: :delete_all), primary_key: true
      add :stanza_revision_id, references(:stanza_revision, on_delete: :delete_all), primary_key: true
    end
  end
end
