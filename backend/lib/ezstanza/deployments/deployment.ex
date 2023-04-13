defmodule Ezstanza.Deployments.Deployment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Configs.ConfigRevision
  alias Ezstanza.DeployTargets.DeployTarget
  alias Ezstanza.Accounts.User

  schema "deployment" do
    # TODO: Enums stored in table?,
    field :status, Ecto.Enum, values: [:pending, :deploying, :completed, :failed], default: :pending
    belongs_to :config_revision, ConfigRevision
    belongs_to :deploy_target, DeployTarget
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
