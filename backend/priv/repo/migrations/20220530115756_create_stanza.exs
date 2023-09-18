defmodule Ezstanza.Repo.Migrations.Stanza do
  use Ecto.Migration

  def change do
    create table(:stanza) do
      add :name, :string, null: false
      add :user_id, references(:user, on_delete: :nilify_all) # nilify or nothing?
      timestamps()
    end

    create unique_index(:stanza, [:name])
    create index(:stanza, [:user_id]) #??

    create table(:stanza_revision) do
      add :body, :text, null: false
      add :stanza_id, references(:stanza, on_delete: :delete_all)
      add :user_id, references(:user, on_delete: :nilify_all)
      timestamps()
    end

    create index(:stanza_revision, [:user_id])

    alter table(:stanza) do
      add :current_stanza_revision_id, references(:stanza_revision, on_delete: :restrict)
    end

    create unique_index(:stanza, [:current_stanza_revision_id])

    # TODO: Define composite primary key and indices
    create table(:stanza_tag, primary_key: false) do
      add :stanza_id, references(:stanza, on_delete: :delete_all), primary_key: true
      add :tag_id, references(:tag), primary_key: true
    end

    create unique_index(:config_tag, [:config_id, :tag_id])
  end

end
