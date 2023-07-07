defmodule Ezstanza.Deployments.Deployment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Configs.ConfigRevision
  alias Ezstanza.DeployTargets.DeployTarget
  alias Ezstanza.Accounts.User

  schema "deployment" do
    # TODO: Enums stored in table?,
    field :status, Ecto.Enum, values: [:pending, :deploying, :completed, :failed], default: :pending
    field :is_current_deployment, :boolean, virtual: true
    belongs_to :deploy_target, DeployTarget

    many_to_many :stanza_revisions, StanzaRevision,
      join_through: "deployment_stanza_revision",
      on_replace: :delete

    #has_one :current_deploy_target, DeployTarget,
    #  foreign_key: :current_deployment_id

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(deployment, attrs) do
    deployment
    |> cast(attrs, [:config_revision_id, :deploy_target_id, :user_id])
    |> validate_required([:config_revision_id, :deploy_target_id, :user_id])
  end
end
