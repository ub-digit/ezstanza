defmodule Ezstanza.DeployTargets.DeployServer.Supervisor do
  use DynamicSupervisor
  alias Ezstanza.DeployTargets.DeployTarget
  alias Ezstanza.DeployTargets.DeployServer

  def start_link(init_args) do
    DynamicSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def start_child(%DeployTarget{} = deploy_target) do
    child_spec = {DeployServer, deploy_target}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def terminate_child(%DeployTarget{id: id}) do
    [{pid, _}] = Registry.lookup(:deploy_server_registry, id)
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  # TODO: Provide in start_link instead?
  @impl true
  def init(_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
