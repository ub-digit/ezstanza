defmodule EzstanzaWeb.SessionController do
  use EzstanzaWeb, :controller

  alias EzstanzaWeb.Plug.Auth
  alias Ezstanza.Accounts.User
  alias Ezstanza.Accounts

  import Ecto.Changeset

  action_fallback EzstanzaWeb.FallbackController

  def user(conn, _params) do
    user = Auth.current_user(conn)
    json(conn, %{
      #data: %{
        id: user.id,
        name: user.name,
        username: user.username,
        email: user.email,
      #}
    })
  end

  # TODO: refactor
  def create(conn, %{"provider" => "password"} = params) do
    data = %{}
    types = %{username: :string, password: :string}
    required = Map.keys(types)
    {data, types}
    |> cast(params, required)
    |> validate_required(required)
    |> case do
      %{valid?: false} = changeset ->
        {:error, changeset}
      %{changes: %{username: username, password: password}} = changeset ->
        Accounts.authenticate_user(username, password)
        |> case do
          {:ok, %User{} = user} ->
            conn =
              conn
              |> Auth.create(user)
              |> put_status(:created)
            json(conn, %{data: %{access_token: conn.private.api_access_token}})
          {:error, _reason} ->
            {:error, :unauthorized, add_error(changeset, :password, "is incorrect")}
        end
    end
  end
  #def create(conn, %{"provider" => _}) do
  #  #unkonwn provider
  #end
  #def create(conn, _) do
  #  #missing provider
  #end




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
