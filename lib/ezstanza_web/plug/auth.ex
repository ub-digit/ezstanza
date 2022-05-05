defmodule EzstanzaWeb.Plug.Auth do
  @moduledoc false

  alias Plug.Conn
  alias Ezstanza.AccessTokens

  def call(conn, _) do
    conn
    |> fetch()
    |> assign_current_user()
  end

  def assign_current_user({conn, user}), do: assign_current_user(conn, user)

  @spec assign_current_user(Conn.t(), any()) :: Conn.t()
  def assign_current_user(conn, user) do
    Conn.assign(conn, :current_user, user)
  end

  @doc """
  Fetches the user from access token.
  """
  @spec fetch(Conn.t()) :: {Conn.t(), map() | nil}
  def fetch(conn) do
    with {:ok, token} <- extract_access_token(conn),
         access_token <- AccessTokens.get_access_token_user(token) do
      {conn, access_token}
    else
      _any -> {conn, nil}
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
