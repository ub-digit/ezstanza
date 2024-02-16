defmodule Ezstanza.DeployTargets do
  @moduledoc """
  The DeployTargets context.
  """

  import Ecto.Query, warn: false
  alias Ezstanza.Repo

  alias Ezstanza.DeployTargets.DeployTarget
  alias Ezstanza.Deployments
  #alias Ezstanza.Stanzas

  alias Ecto.Multi

#  defp process_includes(query, includes) when is_list(includes) do
#    stanza_revisions_preloader = fn deployment_ids ->
#      Repo.all(from s_r in Stanzas.stanza_revision_base_query,
#        join: s_r_c_r in assoc(s_r, :deployments),
#        where: s_r_c_r.id in ^deployment_ids,
#        preload: [deployments: s_r_c_r]
#        #select: {s_r_c_r.id, s_r} #TODO: Test this instead of flat_map below
#      )
#      |> Enum.flat_map(fn stanza_revision -> #TODO: Review this
#        Enum.map(stanza_revision.deployments, fn deployment ->
#          {deployment.id, stanza_revision}
#        end)
#      end)
#    end
#
#    Enum.reduce(includes, query, fn
#      "stanza_revisions", query ->
#        query
#        |> preload([current_revision: c_r], [current_revision: {c_r, stanza_revisions: ^stanza_revisions_preloader}]) # Bit confused, can first preload be removed???
#      _, query ->
#        query
#    end)
#  end
#  defp process_includes(query, _), do: query
#
#  def base_query(%{} = params) do
#    Enum.reduce(params, base_query(), fn
#      {"includes", includes}, query ->
#        process_includes(query, includes)
#      _, query ->
#        query
#    end)
#  end

  def base_query() do
    from s in DeployTarget,
      preload: [
        #TODO: Review this! Try removing includes
        current_deployment: ^Deployments.base_query(%{"includes" => ["stanza_revisions"]}) #TODO: Why stanza revisions loaded here?
        #current_deployment_excluded_stanzas: ^Stanzas.stanza_base_query()
      ]
  end

  @doc """
  Returns the list of deploy_target.

  ## Examples

      iex> list_deploy_targets()
      [%DeployTarget{}, ...]

  """
  def list_deploy_targets do
    Repo.all base_query()
  end

  @doc """
  Gets a single deploy_target.

  Raises `Ecto.NoResultsError` if the Deploy target does not exist.

  ## Examples

      iex> get_deploy_target(123)
      %DeployTarget{}

      iex> get_deploy_target(456)
      nil

  """
  def get_deploy_target(id) do
    Repo.one(from d_t in base_query(), where: d_t.id == ^id)
  end

  @doc """
  Creates a deploy_target.

  ## Examples

      iex> create_deploy_target(%{field: value})
      {:ok, %DeployTarget{}}

      iex> create_deploy_target(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_deploy_target(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:deploy_target, DeployTarget.changeset(%DeployTarget{}, attrs))
    |> Multi.run(:deploy_server, fn _repo, %{deploy_target: deploy_target} ->
      case Ezstanza.DeployTargets.DeployServer.Supervisor.start_child(deploy_target) do
        {:ok, child} -> {:ok, child}
        _ -> {:error, :failed_to_start_deploy_server}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{deploy_target: deploy_target}} -> {:ok, deploy_target}
      {:error, :deploy_target, changeset, _changes_so_far} -> {:error, changeset}
      {:error, :deploy_server, error, _changes_so_far} -> {:error, error}
      _ -> {:error, :unknown_error} # TODO: This should never happen?
    end
  end

  @doc """
  Updates a deploy_target.

  ## Examples

      iex> update_deploy_target(deploy_target, %{field: new_value})
      {:ok, %DeployTarget{}}

      iex> update_deploy_target(deploy_target, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_deploy_target(%DeployTarget{} = deploy_target, attrs) do
    deploy_target
    |> DeployTarget.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a deploy_target.

  ## Examples

      iex> delete_deploy_target(deploy_target)
      {:ok, %DeployTarget{}}

      iex> delete_deploy_target(deploy_target)
      {:error, %Ecto.Changeset{}}

  """
  def delete_deploy_target(%DeployTarget{} = deploy_target) do
    # TODO: Should perhaps put inside of multi, as in create_deploy_target
    #Ezstanza.DeployTargets.DeployServer.Supervisor.terminate_child(deploy_target)
    Repo.delete(deploy_target)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking deploy_target changes.

  ## Examples

      iex> change_deploy_target(deploy_target)
      %Ecto.Changeset{data: %DeployTarget{}}

  """
  def change_deploy_target(%DeployTarget{} = deploy_target, attrs \\ %{}) do
    DeployTarget.changeset(deploy_target, attrs)
  end
end
