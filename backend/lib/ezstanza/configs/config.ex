defmodule Ezstanza.Configs.Config do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Configs.ConfigRevision
  alias Ezstanza.Accounts.User
  alias Ezstanza.Tags.Tag

  schema "config" do
    field :name, :string
    field :color, :string
    many_to_many :tags, Tag,
      join_through: "config_tag",
      on_replace: :delete
    has_many :revisions, ConfigRevision
    belongs_to :current_revision, ConfigRevision,
      foreign_key: :current_config_revision_id # rename to current_revision_id, same for stanzas etc?
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(attrs, [:name, :color, :user_id, :current_config_revision_id])
    |> validate_required([:name, :color, :user_id])
    |> unique_constraint(:name)
  end
end
