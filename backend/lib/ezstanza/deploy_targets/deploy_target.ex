defmodule Ezstanza.DeployTargets.DeployTarget do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Configs.Config

  schema "deploy_target" do
    field :name, :string
    belongs_to :default_config, Config,
      foreign_key: :default_config_id # can remove?
    embeds_one :options, Application.fetch_env!(:ezstanza, :deployment_provider)
    timestamps()
  end

  @doc false
  def changeset(deploy_target, attrs) do
    deploy_target
    |> cast(attrs, [:name, :default_config_id])
    |> validate_required([:name, :default_config_id])
    |> cast_embed(:options)
  end
end
