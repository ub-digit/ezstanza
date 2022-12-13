defmodule Ezstanza.Deployments do
  @moduledoc """
  The Deployments context.
  """

  import Ecto.Query, warn: false
  alias Ezstanza.Repo

  import Ezstanza.Pagination

  alias Ezstanza.Deployments.Deployment

  alias Ezstanza.Configs

  def base_query() do
    config_revisions_preloader = fn config_revision_ids ->
      Repo.all(from s_r in Configs.config_revision_base_query(),
        where: s_r.id in ^config_revision_ids
      )
    end
    # TODO: Possible to join on config_revision_base_query, subquery?
    from d in Deployment,
      #join: c_r in assoc(d, :config_revision), as: :config_revision,
      join: d_t in assoc(d, :deploy_target), as: :deploy_target,
      join: u in assoc(d, :user), as: :user,
      join: c_r in assoc(d, :config_revision), as: :config_revision,
      preload: [config_revision: ^config_revisions_preloader, deploy_target: d_t, user: u]
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
      {"config_id", value}, dynamic ->
        dynamic([config_revision: c_r], ^dynamic and c_r.config_id == ^value)
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

  @doc """
  Updates a deployment.

  ## Examples

      iex> update_deployment(deployment, %{field: new_value})
      {:ok, %Deployment{}}

      iex> update_deployment(deployment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_deployment(%Deployment{} = deployment, attrs) do
    deployment
    |> Deployment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a deployment.

  ## Examples

      iex> delete_deployment(deployment)
      {:ok, %Deployment{}}

      iex> delete_deployment(deployment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_deployment(%Deployment{} = deployment) do
    Repo.delete(deployment)
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
end
