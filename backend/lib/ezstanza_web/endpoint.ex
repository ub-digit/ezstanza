defmodule EzstanzaWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :ezstanza

  socket "/socket", EzstanzaWeb.UserSocket, websocket: true, longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :ezstanza,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :ezstanza
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()


  # Since plugs evaluated at compile time we cannot
  # immediately get origin from runtime configuration
  def check_corsica_origins(origin) do
    case Application.get_env(:ezstanza, :origins) do
      "*" -> true
      origins -> Enum.any?(List.wrap(origins), &matching_origin?(&1, origin))
    end
  end

  defp matching_origin?(origin, origin), do: true
  defp matching_origin?(allowed, _actual) when is_binary(allowed), do: false
  defp matching_origin?(%Regex{} = allowed, actual), do: Regex.match?(allowed, actual)

  plug Corsica,
    origins: {__MODULE__, :check_corsica_origins},
    log: [rejected: :warn, invalid: :debug, accepted: :debug],
    allow_methods: :all,
    allow_headers: :all,
    allow_credentials: true
    #allow_headers: ["content-type", "accept"]

  plug Plug.MethodOverride
  plug Plug.Head
  plug EzstanzaWeb.Router
end
