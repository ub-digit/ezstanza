defmodule Ezstanza.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Ezstanza.DeployTargets

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Ezstanza.Repo,
      # Start the Telemetry supervisor
      EzstanzaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ezstanza.PubSub},
      # Start the Endpoint (http/https)
      EzstanzaWeb.Endpoint,
      Ezstanza.DeployTargets.Supervisor
      # Start a worker by calling: Ezstanza.Worker.start_link(arg)
      # {Ezstanza.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ezstanza.Supervisor]
    start_link_result = Supervisor.start_link(children, opts)

    # Hack, is there a more proper way?
    deploy_targets = DeployTargets.list_deploy_targets()
    Enum.each(
      deploy_targets,
      fn deploy_target ->
        DeployTargets.DeployServer.Supervisor.start_child(deploy_target)
      end
    )

    start_link_result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EzstanzaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
