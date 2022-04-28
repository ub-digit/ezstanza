defmodule Ezstanza.Repo.Migrations.AddTables do
  use Ecto.Migration

  def change do
    create table("user") do

    end


    create table("stanza") do
      add :name,  :string, size: 128
      add :revision_id, :integer
      timestamps()
  end
end
