defmodule Ezstanza.Authentication do
  alias Ezstanza.Accounts
  def password(username, password) do
    Accounts.authenticate_user(username, password)
  end
end
