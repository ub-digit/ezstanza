defmodule Ezstanza.Configs.ConfigRevision do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Configs.Config
  alias Ezstanza.Accounts.User

  schema "config_revision" do
    belongs_to :config, Config
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(config_revision, attrs) do
    config_revision
    |> cast(attrs, [:config_id, :user_id])
    |> validate_required([:config_id, :user_id])
  end
end
