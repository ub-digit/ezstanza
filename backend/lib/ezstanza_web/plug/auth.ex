defmodule EzstanzaWeb.Plug.Auth do
  @moduledoc false

  alias Plug.Conn
  alias Ezstanza.AccessTokens
  # alias Ezstanza.AccessTokens.AccessToken
  # alias Ezstanza.User

  @doc false
  def init(_), do: nil

  def call(conn, _) do
    conn
    |> fetch()
    |> assign_current_user()
  end

  @spec current_user(Conn.t()) :: map | nil
  def current_user(%{assigns: assigns}), do: Map.get(assigns, :current_user)

  def assign_current_user({conn, user}), do: assign_current_user(conn, user)

  @spec assign_current_user(Conn.t(), any()) :: Conn.t()
  def assign_current_user(conn, user) do
    Conn.assign(conn, :current_user, user)
  end

  @doc false
  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, user) do
    token = AccessTokens.generate_token()
    conn
    |> Conn.put_private(:api_access_token, token)
    |> Conn.register_before_send(fn conn ->
      AccessTokens.create_access_token(%{
        token: token,
        valid_to: AccessTokens.token_expiration_date(),
        user_id: user.id
      })
      conn
    end)
  end

  @doc """
  Fetches the user from access token.
  """
  @spec fetch(Conn.t()) :: {Conn.t(), map() | nil}
  def fetch(conn) do
    with {:ok, token} <- extract_access_token(conn),
         user <- AccessTokens.get_access_token_user(token) do
      {conn, user}
    else
      _any -> {conn, nil}
    end
  end


  @doc """
  Creates new tokens from valid access token.
  """
  @spec renew(Conn.t()) :: {Conn.t(), map() | nil}
  def renew(conn) do
    with {:ok, token} <- extract_access_token(conn),
         user when not is_nil(user) <- AccessTokens.get_access_token_user(token) do
      conn = conn
        |> create(user)
        |> Conn.register_before_send(fn conn ->
          AccessTokens.delete_access_token(token)
          conn
        end)
      {conn, user}
    else
      _any -> {conn, nil}
    end
  end

   @doc """
  Delete the access token.
  """
  @spec delete(Conn.t()) :: Conn.t()
  def delete(conn) do
    with {:ok, token} <- extract_access_token(conn) do
      Conn.register_before_send(conn, fn conn ->
        AccessTokens.delete_access_token(token)
        conn
      end)
      conn
    end
  end

  defp extract_access_token(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      # Only one header value should be returned
      # (https://stackoverflow.com/questions/29282578/multiple-http-authorization-headers)
      ["Bearer " <> untrimmed_access_token] ->
        {:ok, String.trim_leading(untrimmed_access_token, " ")}
      _ ->
        {:error, :missing_or_invalid_bearer_token}
    end
  end

end
