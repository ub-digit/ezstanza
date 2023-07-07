defmodule Ezstanza.DeployTargets.DeployTarget do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Configs.Config
  alias Ezstanza.Deployments.Deployment
  alias Ezstanza.Stanzas.Stanza

  schema "deploy_target" do
    field :name, :string
    field :color, :string
    belongs_to :current_deployment, Deployment

    many_to_many :current_deployment_excluded_stanzas, Stanza,
      join_through: "deploy_target_current_deployment_excluded_stanza"

    #  foreign_key: :current_deployment_id # can remove?
    embeds_one :options, Application.fetch_env!(:ezstanza, :deployment_provider)
    timestamps()
  end

  @doc false
  def changeset(deploy_target, attrs) do
    deploy_target
    # TODO: unique constraint for name
    |> cast(attrs, [:name, :color]) # Why does color validation fail if embed validation fails?
    |> validate_required([:name, :color])
    |> cast_embed(:options)
  end
end
