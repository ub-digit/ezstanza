defmodule Ezstanza.DeployTargets.DeployServer do
  use GenServer

  alias EzstanzaWeb.Endpoint # Should not use web context here, not good
  alias Ezstanza.DeployTargets.DeployTarget
  alias Ezstanza.Accounts.User
  alias Ezstanza.Deployments.Deployment
  alias Ezstanza.Deployments
  alias Ezstanza.Configs

  @impl true
  def init(state) do
    {:ok, state}
  end

  defp process_name(%DeployTarget{id: id}) do
    {:via, Registry, {:deploy_server_registry, id}}
  end

  def start_link(%DeployTarget{name: name} = deploy_target) do
    init_arg = %{name: name} #???
    GenServer.start_link(__MODULE__, init_arg, name: process_name(deploy_target))
  end

  def child_spec(%DeployTarget{} = deploy_target) do
    %{
      id: __MODULE__,
      #id: deploy_target.id,
      start: {__MODULE__, :start_link, [deploy_target]},
      restart: :transient
    }
  end

  # Client
  # type check?
  # TODO: GenServer.cast, wlways return :ok regardles wether server exists or not
  # where catch error if does not?
  def deploy(%Deployment{} = deployment) do
    GenServer.cast(process_name(deployment.deploy_target), {:deploy, deployment})
  end

  # Server callbacks
  @impl true
  def handle_cast({
    :deploy,
    %Deployment{
      id: deployment_id,
      deploy_target: deploy_target,
      user: user,
      stanza_revisions: stanza_revisions
    } = deployment
  }, state) do
    provider = Application.fetch_env!(:ezstanza, :deployment_provider)
    config = Stanzas.stanza_revisions_to_string(stanza_revisions)
    broadcast_status_change(deployment_id, :deploying)
    case provider.deploy(
      deploy_target.name,
      user.username,
      config,
      deploy_target.options
    ) do
      :ok ->
        # TODO: module attributes for statuses?
        broadcast_status_change(deployment_id, :completed)
        Deployments.update_deployment_status(deployment, :completed)
      {:error, _reason} ->
        # TODO: Log reason?
        broadcast_status_change(deployment_id, :failed)
        Deployments.update_deployment_status(deployment, :failed)
    end
    {:noreply, state}
  end

  defp broadcast_status_change(deployment_id, status) do
    # TODO: Replace with sending message back to deploy context?
    Endpoint.broadcast(
      "deployment",
      "deployment_status_change",
      %{id: deployment_id, status: Atom.to_string(status)}
    )
  end

end
