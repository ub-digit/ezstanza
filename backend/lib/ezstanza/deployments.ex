defmodule Ezstanza.Deployments do
  @moduledoc """
  The Deployments context.
  """

  import Ecto.Query, warn: false
  alias Ezstanza.Repo

  import Ezstanza.Pagination


  alias Ezstanza.Stanzas

  alias Ezstanza.Deployments.Deployment
  alias Ezstanza.DeployTargets.DeployServer


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
    Repo.one(from s in base_query(), where: s.id == ^id)
  end

  @doc """
  Creates a deployment.

  ## Examples

      iex> create_deployment(%{field: value})
      {:ok, %Deployment{}}

      iex> create_deployment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_deployment(attrs \\ %{}) do
    %Deployment{}
    |> Deployment.changeset(attrs)
    |> Repo.insert()
  end

  # TODO: Status validation when in "failed" "succeded"?
  def update_deployment_status(%Deployment{} = deployment, status) do
    Repo.transaction(fn ->
      # TODO: Probably should invert order of updates?
      case Ecto.Changeset.change(deployment, status: status) |> Repo.update() do
        {:ok, deployment} ->
          deploy_target = Ecto.Changeset.change(deployment.deploy_target, current_deployment_id: deployment.id)
          case Repo.update(deploy_target) do
            {:ok, _} -> {:ok, deployment}
            {:error, _changeset} ->
              Repo.rollback(:deploy_target_set_current_deployment_failed)
          end
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
