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
    case conn.path_params do
      %{"id" => id} ->
        # TODO: alternatively skip hard coded id handling and let params_callback fetch all arguments
        # (and also rename to arguments_callback in that case)
        args = case Map.get(opts, :params_callback) do
          nil ->
            case map_size(conn.query_params) do
              0 -> [id]
              _ -> [id, conn.query_params]
            end
          {module, params_fun} -> [id, apply(module, params_fun, [conn])]
        end
        case apply(module, get_fun, args) do
          nil -> FallbackController.call(conn, {:error, :not_found})
          entity ->
            Plug.Conn.assign(conn, assigns_key, entity)
        end
      _ ->
        # TODO: This should never occur as currently used as router
        # will produce 404 if missing id in path
        FallbackController.call(conn, {:error, :missing_id_path_param})
    end
  end
end
