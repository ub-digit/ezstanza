defmodule EzstanzaWeb.SessionController do
  use EzstanzaWeb, :controller

  alias EzstanzaWeb.Plug.Auth
  alias Ezstanza.Accounts.User

  action_fallback EzstanzaWeb.FallbackController

  # TODO: refactor
  def create(conn, %{"provider" => "password", "username" => username_or_email, "password" => password}) do
    conn
    |> Auth.authenticate_user(username_or_email, password)
    |> case do
      {:ok, %User{} = user} ->
        conn
        |> Auth.create(user)
        |> put_status(:created)
        |> json(%{data: %{access_token: conn.private.api_acces_token}})
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
        json(conn, %{data: %{access_token: conn.private.api_acces_token}})
    end
  end

  # TODO: Behaviour of fallback controllen when {:error, ..}?
  def delete(conn, _params) do
    with conn = Auth.delete(conn) do
      send_resp(conn, :no_content, "")
    end
  end
end
