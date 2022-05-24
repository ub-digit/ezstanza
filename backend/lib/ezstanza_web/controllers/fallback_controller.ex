defmodule EzstanzaWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use EzstanzaWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    call(conn, {:error, :unprocessable_entity, changeset})
  end

  # TODO: @spec
  # The clause handles changeset validations with a custom http status
  def call(conn, {:error, status, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(status)
    |> put_view(EzstanzaWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end


  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(EzstanzaWeb.ErrorView)
    |> render(:"404")
  end
end
