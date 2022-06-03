defmodule Ezstanza.Repo.Migrations.Tag do
  use Ecto.Migration

  def change do
    create table(:tag) do
      add :name, :string
      timestamps()
    end

    create unique_index(:tag, [:name])
  end

end
