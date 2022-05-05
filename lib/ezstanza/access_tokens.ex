defmodule Ezstanza.AccessTokens do
  @moduledoc """
  The AccessTokens context.
  """

  import Ecto.Query, warn: false
  alias Ezstanza.Repo

  alias Ezstanza.AccessTokens.AccessToken

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
  def create_access_token(attrs \\ %{}) do
    %AccessToken{}
    |> AccessToken.changeset(attrs)
    |> Repo.insert()
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

      iex> delete_access_token(access_token)
      {:ok, %AccessToken{}}

      iex> delete_access_token(access_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_access_token(%AccessToken{} = access_token) do
    Repo.delete(access_token)
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
