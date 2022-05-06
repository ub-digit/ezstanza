# @TODO API namespace?
defmodule EzstanzaWeb.UserRegistrationController do
  use EzstanzaWeb, :controller

  alias Ezstanza.Accounts
  alias Ezstanza.Accounts.User

  action_fallback EzstanzaWeb.FallbackController

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.register_user(user_params) do
      conn
      |> put_status(:created)
      |> render("show.json", user: user)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

end
