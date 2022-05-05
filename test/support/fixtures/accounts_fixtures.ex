defmodule Ezstanza.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ezstanza.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: "some email",
        name: "some name",
        source: "some source",
        source_id: "some source_id",
        username: "some username"
      })
      |> Ezstanza.Accounts.create_user()

    user
  end
end
