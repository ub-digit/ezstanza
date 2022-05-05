defmodule Ezstanza.AccessTokensTest do
  use Ezstanza.DataCase

  alias Ezstanza.AccessTokens

  describe "access_tokens" do
    alias Ezstanza.AccessTokens.AccessToken

    import Ezstanza.AccessTokensFixtures

    @invalid_attrs %{valid_to: nil, token: nil}

    test "get_access_token!/1 returns the access_token with given token" do
      access_token = access_token_fixture()
      assert AccessTokens.get_access_token!(access_token.token) == access_token
    end

    test "create_access_token/1 with valid data creates a access_token" do
      valid_attrs = %{valid_to: ~U[2022-05-01 16:16:00Z], token: "some token"}

      assert {:ok, %AccessToken{} = access_token} = AccessTokens.create_access_token(valid_attrs)
      assert access_token.valid_to == ~U[2022-05-01 16:16:00Z]
      assert access_token.token == "some token"
    end

    test "create_access_token/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AccessTokens.create_access_token(@invalid_attrs)
    end

    test "update_access_token/2 with valid data updates the access_token" do
      access_token = access_token_fixture()
      update_attrs = %{valid_to: ~U[2022-05-02 16:16:00Z], token: "some updated token"}

      assert {:ok, %AccessToken{} = access_token} = AccessTokens.update_access_token(access_token, update_attrs)
      assert access_token.valid_to == ~U[2022-05-02 16:16:00Z]
      assert access_token.token == "some updated token"
    end

    test "update_access_token/2 with invalid data returns error changeset" do
      access_token = access_token_fixture()
      assert {:error, %Ecto.Changeset{}} = AccessTokens.update_access_token(access_token, @invalid_attrs)
      assert access_token == AccessTokens.get_access_token!(access_token.id)
    end

    test "delete_access_token/1 deletes the access_token" do
      access_token = access_token_fixture()
      assert {:ok, %AccessToken{}} = AccessTokens.delete_access_token(access_token)
      assert_raise Ecto.NoResultsError, fn -> AccessTokens.get_access_token!(access_token.id) end
    end

    test "change_access_token/1 returns a access_token changeset" do
      access_token = access_token_fixture()
      assert %Ecto.Changeset{} = AccessTokens.change_access_token(access_token)
    end
  end
end
