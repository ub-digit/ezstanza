defmodule Ezstanza.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ezstanza.AccessTokens.AccessToken

  schema "user" do
    field :email, :string
    field :name, :string
    field :source, :string
    field :source_id, :string
    field :username, :string
    field :password_confirmation, :string, virtual: true
    field :password, :string, virtual: true
    field :password_hash, :string
    has_many :access_tokens, AccessToken

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username, :email, :source, :source_id, :password])
    # TODO: Set name = username if unset?
    |> validate_required([:name, :username, :email])
    |> validate_email()
    |> unique_constraint(:name)
    |> unique_constraint(:username)
    |> unique_constraint([:source, :source_id])
  end

  @doc false
  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> validate_required(:password)
    |> validate_password()
    |> put_password_hash()
  end

  @doc false
  defp validate_email(changeset) do
    changeset
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email)
  end

  @doc false
  defp maybe_validate_password(
    %Ecto.Changeset{
      changes: %{password: nil}
    } = changeset
  ) do
    changeset
  end
  defp maybe_validate_password(changeset), do: validate_password(changeset)

  @doc false
  def validate_password(changeset) do
    changeset
    |> validate_length(:password, min: 8, max: 255) # TODO: varchar or text in db?
    # @TODO use not_qwerty123
  end

  @doc false
  defp put_password_hash(
    %Ecto.Changeset{
      valid?: true,
      changes: %{password: password}
    } = changeset
  ) do
    change(changeset, Argon2.add_hash(password, hash_key: :password_hash))
  end
  defp put_password_hash(changeset), do: changeset

end
