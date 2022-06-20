defmodule EzstanzaWeb.Plug.RequireAuthenticated do
  @moduledoc false

  use Phoenix.Controller, namespace: EzstanzaWeb # for json, refactor to use fallback/error-controller?
  #use EzstanzaWeb, :controller

  alias Plug.Conn
  alias EzstanzaWeb.Plug.Auth

  @doc false
  def init(_), do: nil

  @doc false
  @spec call(Conn.t(), Plug.opts()) :: Conn.t()
  def call(conn, _) do
    conn
    |> Auth.current_user()
    |> maybe_halt(conn)
  end

  defp maybe_halt(nil, conn) do
    conn
    |> Conn.put_status(:unauthorized)
    |> json(%{error: %{code: 401, message: "Not authenticated"}})
    |> Conn.halt()
  end
  defp maybe_halt(_user, conn), do: conn

end
