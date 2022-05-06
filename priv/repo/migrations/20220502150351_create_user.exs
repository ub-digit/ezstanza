defmodule Ezstanza.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:user) do
      add :name, :string
      add :username, :string
      add :email, :string
      add :password_hash, :string
      add :source, :string
      add :source_id, :string

      timestamps()
    end

    create unique_index(:user, [:name])
    create unique_index(:user, [:username])
    create unique_index(:user, [:email])
    create unique_index(:user, [:source, :source_id])
  end
end
