defmodule Ezstanza.Stanzas.Stanza do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Stanzas.StanzaRevision
  alias Ezstanza.Accounts.User
  alias Ezstanza.Tags.Tag

  schema "stanza" do
    field :name, :string
    many_to_many :tags, Tag,
      join_through: "stanza_tag",
      on_replace: :delete
    has_many :revisions, StanzaRevision
    belongs_to :current_revision, StanzaRevision,
      foreign_key: :current_stanza_revision_id
    belongs_to :user, User

    many_to_many :current_configs_stanza_revisions, StanzaRevision,
      join_through: "stanza_current_config_revision_stanza_revision"

    has_many :configs, through: [:revisions, :config_revisions, :config] # Remove?
    has_many :current_configs, through: [:revisions, :current_configs]
    has_many :current_revision_current_configs, through: [:current_revision, :current_configs]

    timestamps()
  end

  @doc false
  def changeset(stanza, attrs) do
    stanza
    |> cast(attrs, [:name, :user_id, :current_stanza_revision_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name)
  end
end
