defmodule Ezstanza.Authentication do
  alias Ezstanza.Accounts
  def authenticate_password(username, password) do
    Accounts.authenticate_user(username, password)
  end
end
