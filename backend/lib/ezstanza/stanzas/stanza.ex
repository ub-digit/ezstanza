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
    has_many :stanza_revisions, StanzaRevision
    belongs_to :current_stanza_revision, StanzaRevision
    belongs_to :user, User
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
