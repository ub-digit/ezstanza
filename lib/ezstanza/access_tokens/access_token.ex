defmodule Ezstanza.AccessTokens.AccessToken do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Accounts.User

  schema "access_token" do
    field :token, :string
    field :valid_to, :utc_datetime
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(access_token, attrs) do
    access_token
    |> cast(attrs, [:token, :valid_to, :user_id])
    |> validate_required([:token, :valid_to, :user_id])
    |> unique_constraint(:token)
  end
end
