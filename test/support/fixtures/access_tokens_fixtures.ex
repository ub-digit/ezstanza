defmodule Ezstanza.AccessTokensFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ezstanza.AccessTokens` context.
  """

  @doc """
  Generate a access_token.
  """
  def access_token_fixture(attrs \\ %{}) do
    {:ok, access_token} =
      attrs
      |> Enum.into(%{
        valid_to: ~U[2022-05-01 16:16:00Z],
        token: "some token"
      })
      |> Ezstanza.AccessTokens.create_access_token()

    access_token
  end
end
