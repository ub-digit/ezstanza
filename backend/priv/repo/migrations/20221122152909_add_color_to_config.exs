defmodule Ezstanza.Repo.Migrations.AddColorToConfig do
  use Ecto.Migration

  def change do
    alter table(:config) do
      add :color, :string, size: 6
    end
  end
end
