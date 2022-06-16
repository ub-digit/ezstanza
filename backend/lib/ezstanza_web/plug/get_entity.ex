defmodule EzstanzaWeb.Plug.GetEntity do
  @moduledoc false

  alias EzstanzaWeb.FallbackController

  @doc false
  def init(opts) do
    opts
  end

  @doc false
  @spec call(Conn.t(), Plug.opts()) :: Conn.t()
  def call(conn, %{assigns_key: assigns_key, callback: {module, get_fun}} = opts) do
    # TODO: custom id source?
    case conn.path_params do
      %{"id" => id} ->
        case apply(module, get_fun, [id]) do
          nil -> FallbackController.call(conn, {:error, :not_found})
          entity ->
            #conn.assign(assigns_key, entity)
            Plug.Conn.assign(conn, assigns_key, entity)
        end
      _ ->
        FallbackController.call(conn, {:error, :missing_id_path_param})
    end
  end

end
