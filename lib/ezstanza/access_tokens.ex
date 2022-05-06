defmodule Ezstanza.AccessTokens do
  @moduledoc """
  The AccessTokens context.
  """

  @default_expire_seconds 3600*24

  import Ecto.Query, warn: false
  alias Ezstanza.Repo

  alias Ezstanza.AccessTokens.AccessToken
  alias Ezstanza.Accounts.User

  @doc """
  Gets a single access_token.

  Raises `Ecto.NoResultsError` if the Access token does not exist.

  ## Examples

      iex> get_access_token_user("f3f9211f-0819-4147-973d-dacc06524553")
      %AccessToken{}

      iex> get_access_token_user("b436517a-e294-4211-8312-8576933f2db1")
      ** (Ecto.NoResultsError)

  """
  def get_access_token!(token), do: Repo.get_by!(AccessToken, token: token)


  @doc """
  Gets user for access_token.

  ## Examples

      iex> get_access_token_user("f3f9211f-0819-4147-973d-dacc06524553")
      %AccessToken{}

      iex> get_access_token_user("b436517a-e294-4211-8312-8576933f2db1")
      ** (Ecto.NoResultsError)

  """
  def get_access_token_user(token) do
    # TODO: ensure valid_to
    Repo.one from u in User,
      join: t in assoc(u, :access_tokens),
      where: t.token == ^token
  end

  @doc """
  Creates a access_token.

  ## Examples

  iex> create_access_token(%{field: value})
  {:ok, %AccessToken{}}

  iex> create_access_token(%{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """

  def create_access_token(%User{id: user_id}), do: create_access_token(%{user_id: user_id})
  def create_access_token(attrs) do
    AccessToken.changeset(attrs)
    |> Repo.insert()
  end

  def generate_token(), do: UUID.uuid4(:hex)

  def token_expiration_date() do
    DateTime.utc_now()
    |> Datetime.add(@default_expire_seconds, :second)
  end

  @doc """
  Updates a access_token.

  ## Examples

      iex> update_access_token(access_token, %{field: new_value})
      {:ok, %AccessToken{}}

      iex> update_access_token(access_token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_access_token(%AccessToken{} = access_token, attrs) do
    access_token
    |> AccessToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a access_token.

  ## Examples

      iex> delete_access_token("f3f9211f-0819-4147-973d-dacc06524553")
      :ok

  """

  def delete_access_token(token) do
    with {_deleted, _selected} <- Repo.delete_all from a in AccessToken, where: a.token == ^token do
      :ok
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking access_token changes.

  ## Examples

      iex> change_access_token(access_token)
      %Ecto.Changeset{data: %AccessToken{}}

  """
  def change_access_token(%AccessToken{} = access_token, attrs \\ %{}) do
    AccessToken.changeset(access_token, attrs)
  end
end
