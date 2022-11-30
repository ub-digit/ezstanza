defmodule Ezstanza.DeployTargets do
  @moduledoc """
  The DeployTargets context.
  """

  import Ecto.Query, warn: false
  alias Ezstanza.Repo

  alias Ezstanza.DeployTargets.DeployTarget

  @doc """
  Returns the list of deploy_target.

  ## Examples

      iex> list_deploy_target()
      [%DeployTarget{}, ...]

  """
  def list_deploy_target do
    Repo.all(DeployTarget)
  end

  @doc """
  Gets a single deploy_target.

  Raises `Ecto.NoResultsError` if the Deploy target does not exist.

  ## Examples

      iex> get_deploy_target!(123)
      %DeployTarget{}

      iex> get_deploy_target!(456)
      ** (Ecto.NoResultsError)

  """
  def get_deploy_target!(id), do: Repo.get!(DeployTarget, id)

  @doc """
  Creates a deploy_target.

  ## Examples

      iex> create_deploy_target(%{field: value})
      {:ok, %DeployTarget{}}

      iex> create_deploy_target(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_deploy_target(attrs \\ %{}) do
    %DeployTarget{}
    |> DeployTarget.changeset(attrs)
    |> Repo.insert()
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
