defmodule Ezstanza.DeployTargets.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # TODO: move to start_link?
  @impl true
  def init(_init_arg) do
    children = [
      Ezstanza.DeployTargets.DeployServer.Supervisor,
      {Registry, [keys: :unique, name: :deploy_server_registry]}
    ]
    # TODO: See what happens if kill registry
    Supervisor.init(children, strategy: :one_for_one, name: __MODULE__)
  end

end
