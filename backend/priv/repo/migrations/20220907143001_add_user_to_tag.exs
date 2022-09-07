defmodule Ezstanza.Repo.Migrations.AddUserToTag do
  use Ecto.Migration

  def change do
    alter table(:tag) do
      add :user_id, references(:user, on_delete: :nilify_all) # nilify or nothing?

      # Skipping index since only relevant if querying for user tags, which we probably wont do
      # TODO: Skip this index for stanzas as well?
      # create index(:tags, [:user_id])
    end
  end
end
