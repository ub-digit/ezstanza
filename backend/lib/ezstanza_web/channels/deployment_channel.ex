defmodule EzstanzaWeb.DeploymentChannel do
  use EzstanzaWeb, :channel

  alias Ezstanza.Deployments
  alias Ezstanza.Deployments.Deployment

  @impl true
  def join("deployment", _payload, socket) do
    {:ok, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("create_deployment", deployment_params, socket) do
    deployment_params = Map.merge(deployment_params, %{"user_id" => socket.assigns[:user_id]})
    with {:ok, %Deployment{id: deployment_id}} <- Deployments.create_deployment(deployment_params) do
      # Testing broadcast
      deployment = Deployments.get_deployment(deployment_id)
      deployment_data = Phoenix.View.render(
        EzstanzaWeb.DeploymentView,
        "deployment.json",
        %{deployment: deployment}
      )
      Deployments.deploy(deployment)
      # Possible race condition of message broadcast in deploy reached client
      # before the reply below
      {:reply, {:ok, deployment_data}, socket}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        changeset_errors = Phoenix.View.render(
          EzstanzaWeb.ChangesetView,
          "error.json",
          %{changeset: changeset}
        )
        {:reply, {:error, changeset_errors}, socket}
      err ->
        # TODO: log error
        IO.inspect(err)
        # TODO: Proper response?
        {:reply, {:error, "unknown error"}, socket}
    end
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (deployment:lobby).
  #@impl true
  #def handle_in("shout", payload, socket) do
  #  broadcast(socket, "shout", payload)
  #  {:noreply, socket}
  #end

  # Add authorization logic here as required.
  #defp authorized?(_payload) do
  #  true
  #end
end
