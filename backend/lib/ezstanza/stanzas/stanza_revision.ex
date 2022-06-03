defmodule Ezstanza.Stanzas.StanzaRevision do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Stanzas.Stanza
  alias Ezstanza.Accounts.User

  schema "stanza_revision" do
    field :body, :string
    belongs_to :stanza, Stanza
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(stanza_revision, attrs) do
    stanza_revision
    |> cast(attrs, [:body, :stanza_id, :user_id])
    |> validate_required([:body, :stanza_id, :user_id])
  end
end
