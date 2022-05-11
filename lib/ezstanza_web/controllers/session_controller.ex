defmodule EzstanzaWeb.SessionController do
  use EzstanzaWeb, :controller

  alias EzstanzaWeb.Plug.Auth
  alias Ezstanza.Accounts.User
  alias Ezstanza.Accounts

  action_fallback EzstanzaWeb.FallbackController

  # TODO: refactor
  def create(conn, %{"provider" => "password", "username" => username_or_email, "password" => password}) do
    Accounts.authenticate_user(username_or_email, password)
    |> case do
      {:ok, %User{} = user} ->
        conn =
          conn
          |> Auth.create(user)
          |> put_status(:created)
        json(conn, %{data: %{access_token: conn.private.api_access_token}})
      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: %{status: 401, message: "Invalid email or password"}})
    end
  end

  @spec renew(Conn.t(), map()) :: Conn.t()
  def renew(conn, _params) do
    conn
    |> Auth.renew()
    |> case do
      {conn, nil} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: %{status: 401, message: "Invalid token"}})
      {conn, _user} ->
        json(conn, %{data: %{access_token: conn.private.api_access_token}})
    end
  end

  # TODO: Behaviour of fallback controllen when {:error, ..}?
  def delete(conn, _params) do
    with conn = Auth.delete(conn) do
      send_resp(conn, :no_content, "")
    end
  end
end
