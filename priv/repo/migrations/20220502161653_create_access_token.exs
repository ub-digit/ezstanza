defmodule Ezstanza.Repo.Migrations.CreateAccessToken do
  use Ecto.Migration

  def change do
    create table(:access_token) do
      add :token, :string
      add :valid_to, :utc_datetime
      add :user_id, references(:user, on_delete: :nothing)

      timestamps()
    end

    create index(:access_token, [:user_id])
    create unique_index(:access_token, [:token])
  end
end
