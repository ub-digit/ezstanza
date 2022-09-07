defmodule Ezstanza.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Accounts.User

  schema "tag" do
    field :name, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
