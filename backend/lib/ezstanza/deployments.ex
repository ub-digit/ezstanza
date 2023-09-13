defmodule Ezstanza.Deployments do
  @moduledoc """
  The Deployments context.
  """

  import Ecto.Query, warn: false
  import Ezstanza.Pagination

  alias Ecto.Changeset
  alias Ecto.Multi

  use Ezstanza.MultiHelpers, :deployment

  alias Ezstanza.Repo
  alias Ezstanza.Stanzas
  alias Ezstanza.Stanzas.StanzaRevision
  alias Ezstanza.Deployments.Deployment
  alias Ezstanza.DeployTargets
  alias Ezstanza.DeployTargets.DeployServer
  alias Ezstanza.DeployTargets.DeployTarget

  defp process_includes(query, includes) when is_list(includes) do
    stanza_revisions_preloader = fn deployment_ids ->
      Repo.all(from s_r in Stanzas.stanza_revision_base_query,
        join: s_r_c_r in assoc(s_r, :deployments),
        where: s_r_c_r.id in ^deployment_ids,
        preload: [deployments: s_r_c_r]
        #select: {s_r_c_r.id, s_r} #TODO: Test this instead of flat_map below
      )
      |> Enum.flat_map(fn stanza_revision -> #TODO: Review this
        Enum.map(stanza_revision.deployments, fn deployment ->
          {deployment.id, stanza_revision}
        end)
      end)
    end

    Enum.reduce(includes, query, fn
      "stanza_revisions", query ->
        query
        |> preload([stanza_revisions: ^Stanzas.stanza_revision_base_query()])
      _, query ->
        query
    end)
  end
  defp process_includes(query, _), do: query

  def base_query(%{} = params) do
    Enum.reduce(params, base_query(), fn
      {"includes", includes}, query ->
        process_includes(query, includes)
      _, query ->
        query
    end)
  end

  def base_query() do
    from d in Deployment,
      join: d_t in assoc(d, :deploy_target), as: :deploy_target,
      join: u in assoc(d, :user), as: :user,
      preload: [
        deploy_target: d_t,
        user: u
      ]
  end

  @doc """
  Returns the list of deployment.

  ## Examples

      iex> list_deployment()
      [%Deployment{}, ...]

  """
  def list_deployments(params \\ %{}) do
    Repo.all list_query(params)
  end

  defp list_query(%{} = params) do
    base_query()
    |> order_by(^dynamic_order_by(params["order_by"]))
    |> where(^dynamic_where(params))
  end

  defp dynamic_order_by("name"), do: [asc: dynamic([s], s.name)]
  defp dynamic_order_by("name_desc"), do: [desc: dynamic([s], s.name)]
  defp dynamic_order_by("user_name"), do: [asc: dynamic([user: u], u.name)]
  defp dynamic_order_by("user_name_desc"), do: [desc: dynamic([user: u], u.name)]
  defp dynamic_order_by("inserted_at"), do: [asc: dynamic([s], s.inserted_at)]
  defp dynamic_order_by("inserted_at_desc"), do: [desc: dynamic([s], s.inserted_at)]
  defp dynamic_order_by("updated_at"), do: [asc: dynamic([s], s.updated_at)]
  defp dynamic_order_by("updated_at_desc"), do: [desc: dynamic([s], s.updated_at)]

  defp dynamic_order_by(_), do: []

  defp dynamic_where(params) do
    filter_like = &(String.replace(&1, ~r"[%_]", ""))
    Enum.reduce(params, dynamic(true), fn
      {"name", value}, dynamic ->
        dynamic([d], ^dynamic and d.name == ^value)
      {"name_like", value}, dynamic ->
        dynamic([d], ^dynamic and ilike(d.name, ^"%#{filter_like.(value)}%"))
      {"deploy_target_id", value}, dynamic ->
        dynamic([d], ^dynamic and d.deploy_target_id == ^value)
      {"user_name", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.name == ^value)
      {"user_name_like", value}, dynamic ->
        dynamic([user: u], ^dynamic and ilike(u.name, ^"%#{filter_like.(value)}%"))
      {"user_id", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.id == ^value)
      {"user_ids", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.id in ^value)
      {_, _}, dynamic ->
        dynamic
    end)
  end

  def paginate_deployments(%{"page" => page, "size" => size} = params) do
    list_query(params)
    |> paginate_entries(params)
  end

  @doc """
  Gets a single deployment.

  ## Examples

      iex> get_deployment(123)
      %Deployment{}

      iex> get_deployment(456)
      ** nil

  """
  def get_deployment(id) do
    Repo.one(from d in base_query(), where: d.id == ^id)
  end

  #validation?
  #better name?
  defp get_stanza_revisions_from_changes(repo, changes) do
    revision_ids = Enum.map(changes, &(&1["id"]))
    repo.all(from s in StanzaRevision, where: s.id in ^revision_ids)
  end

  defp get_stanza_revisions_from_changes(nil), do: []

  defp stanza_revisions_remove_by_stanza_ids(stanza_revisions, stanza_ids) do
    stanza_revisions
    |> Enum.reject(fn revision ->
      Enum.member?(stanza_ids, revision.stanza_id)
    end)
  end

  defp stanza_revisions_remove_by_stanza_ids(stanza_revisions, nil), do: stanza_revisions


  #def create_deployment_multi(%{} = attrs) do
  #  Multi.new()
  #  |> Multi.insert(:persisted_deployment, Deployment.changeset(%Deployment{}, attrs))
  #  |> Multi.run(:deployment, fn repo, %{pesisted_deployment: deployment} ->
  #    deployment
  #    |> repo.preload(:stanza_revisions)
  #  end)
  #end

  @doc """
  Creates a deployment.

  ## Examples

      iex> create_deployment(%{field: value})
      {:ok, %Deployment{}}

      iex> create_deployment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_deployment(%{"deploy_target_id" => deploy_target_id} = attrs) do
    Multi.new()
    |> Multi.run(:deploy_target, fn repo, _changes ->
      case repo.get(DeployTarget, deploy_target_id) do
        nil -> {:error, :deploy_target_not_found}
        deploy_target -> {:ok, deploy_target}
      end
    end)
    |> Multi.run(
      :stanza_revisions,
      fn repo, %{deploy_target: %DeployTarget{current_deployment_id: current_deployment_id}} ->
        if current_deployment_id do
          current_deployment = Repo.one!(
            from d in base_query(),
            where: d.id == ^current_deployment_id,
            preload: [:stanza_revisions] # join?
          )

          stanza_ids_delete =
            Map.get(attrs, "stanza_deletions", []) ++
              Enum.map(Map.get(attrs, "stanza_revision_changes", []), &(&1["stanza_id"]))
        # TODO: Bail out with error if no changes?
          stanza_revisions = stanza_revisions_remove_by_stanza_ids(
            current_deployment.stanza_revisions,
            stanza_ids_delete
          ) ++ get_stanza_revisions_from_changes(repo, attrs["stanza_revision_changes"])
          {:ok, stanza_revisions}
        else
          case attrs do
            %{"stanza_revision_changes" => changes} = attrs when is_list(changes) ->
              {:ok, get_stanza_revisions_from_changes(repo, changes)}
            _ -> {:error, :bad_request_todo}
          end
        end
      end
    )
    |> Multi.insert(:persisted_deployment, Deployment.changeset(%Deployment{}, attrs))
    |> Multi.run(
      :deployment,
      fn repo, %{persisted_deployment: deployment, stanza_revisions: stanza_revisions} ->
        deployment
        |> repo.preload([:stanza_revisions, :deploy_target, :user])
        |> change_deployment()
        |> Changeset.put_assoc(:stanza_revisions, stanza_revisions)
        |> repo.update()
      end
    )
    #|> Multi.run(
    #  :updated_deploy_target,
    #  fn repo, %{deploy_target: deploy_target, persisted_deployment: %Deployment{id: deployment_id}} ->
    #    IO.inspect("WTF IS THIS NOT RUNNING")
    #    DeployTargets.change_deploy_target(deploy_target, %{"current_deployment_id" => deployment_id})
    #    |> repo.update()
    #  end
    #)
    |> Repo.transaction()
    |> handle_entity_multi_transaction_result(:create_deployment_failed)
  end

  #def create_deployment(%{"stanza_revision_changes" => changes} = attrs) when is_list(changes) do
  #end

  #def create_deployment(_attrs) do
  #  {:error, :bad_request_todo}
  #end


  def create_deployment(_attrs) do
    {:error, :todo_bad_request_osv}
  end

  # TODO: Status validation when in "failed" "succeded"?
  def update_deployment_status(%Deployment{} = deployment, status) do
    Repo.transaction(fn ->
      # TODO: Probably should invert order of updates?
      case Changeset.change(deployment, status: status) |> Repo.update() do
        {:ok, %Deployment{status: :completed, deploy_target: deploy_target} = deployment} ->
          deploy_target = Changeset.change(deploy_target, current_deployment_id: deployment.id)
          case Repo.update(deploy_target) do
            {:ok, _} ->
              {:ok, deployment}
            {:error, _changeset} ->
              Repo.rollback(:deploy_target_set_current_deployment_failed)
          end
        {:ok, deployment} ->
          {:ok, deployment}
        {:error, _changeset} ->
          #Log??
          Repo.rollback(:deployment_status_update_failed)
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking deployment changes.

  ## Examples

      iex> change_deployment(deployment)
      %Ecto.Changeset{data: %Deployment{}}

  """
  def change_deployment(%Deployment{} = deployment, attrs \\ %{}) do
    Deployment.changeset(deployment, attrs)
  end


  def deploy(%Deployment{} = deployment) do
    # Ensure stanza_revisions loaded
    DeployServer.deploy(deployment)
  end

end
