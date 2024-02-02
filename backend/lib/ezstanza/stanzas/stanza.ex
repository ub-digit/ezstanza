defmodule Ezstanza.Stanzas.Stanza do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Stanzas.StanzaRevision
  alias Ezstanza.Accounts.User
  alias Ezstanza.Tags.Tag

  schema "stanza" do
    field :name, :string
    field :disabled, :boolean
    field :current_stanza_revision_body, :string
    many_to_many :tags, Tag,
      join_through: "stanza_tag",
      on_replace: :delete
    has_many :revisions, StanzaRevision

    # Rename relationshiop to current_stanza_revision
    # and remove foreigh key?
    belongs_to :current_revision, StanzaRevision,
      foreign_key: :current_stanza_revision_id
    belongs_to :user, User

    has_many :deployments, through: [:revisions, :deployments] #Remove?

    has_many :current_deployments, through: [:revisions, :current_deployments]

    many_to_many :current_deployments_stanza_revisions, StanzaRevision,
      join_through: "stanza_current_deployment_stanza_revision"

    timestamps()
  end

  @doc false
  def changeset(stanza, attrs) do
    stanza
    |> cast(attrs, [:name, :user_id, :disabled, :current_stanza_revision_id, :current_stanza_revision_body])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name)
  end
end
