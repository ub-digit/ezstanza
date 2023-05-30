defmodule Ezstanza.Configs.ConfigRevision do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Configs.Config
  alias Ezstanza.Stanzas.StanzaRevision
  alias Ezstanza.Accounts.User

  schema "config_revision" do
    field :is_current_revision, :boolean, virtual: true
    field :log_message, :string
    belongs_to :config, Config
    belongs_to :user, User
    many_to_many :stanza_revisions, StanzaRevision,
      join_through: "config_revision_stanza_revision",
      on_replace: :delete
    timestamps()
  end

  @doc false
  def changeset(config_revision, attrs) do
    config_revision
    |> cast(attrs, [:log_message, :config_id, :user_id])
    |> validate_required([:config_id, :user_id]) #:log_message?
  end
end
