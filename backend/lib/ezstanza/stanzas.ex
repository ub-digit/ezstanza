defmodule Ezstanza.Stanzas do
  @moduledoc """
  The Stanzas context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Ezstanza.Repo

  alias Ezstanza.Stanzas.Stanza
  alias Ezstanza.Stanzas.StanzaRevision
  alias Ezstanza.Tags.Tag

  @doc """
  Returns the list of stanza.

  ## Examples

      iex> list_stanza()
      [%Stanza{}, ...]

  """
  def list_stanza do
    Repo.all(Stanza)
  end

  @doc """
  Gets a single stanza.

  Raises `Ecto.NoResultsError` if the Stanza does not exist.

  ## Examples

      iex> get_stanza!(123)
      %Stanza{}

      iex> get_stanza!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stanza!(id), do: Repo.get!(Stanza, id)


  @doc """
  Creates a stanza.

  Required params: name, body, user_id
  Optional: tags? [%{name: <name, id: <id|nil>}, ...]

  ## Examples

      iex> create_stanza(%{field: value})
      {:ok, %Stanza{}}

      iex> create_stanza(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stanza(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:persisted_stanza, Stanza.changeset(%Stanza{}, attrs))
    |> Multi.append(update_persisted_stanza_multi(attrs, :insert))
    |> Repo.transaction()
    |> case do
      {:ok, %{stanza: stanza}} -> {:ok, stanza}
      {:error, failed_operation, failed_value, changes_so_far} ->
        IO.puts("Multi error")
        IO.inspect([failed_operation, failed_value, changes_so_far])
        {:error, :create_stanza_failed}
    end
  end

  defp find_or_create_tags(_repo, nil), do: {:ok, []}
  defp find_or_create_tags(_repo, []), do: {:ok, []}
  defp find_or_create_tags(_repo, tags) when not is_list(tags) do
    {:error, :tags_is_not_a_list}
  end

  defp find_or_create_tags(repo, tags) do
    with {:ok, {tag_ids, tag_names}} = attr_tags_split_ids_names(tags) do
      tags = repo.all from t in Tag, where: t.id in ^tag_ids
      # Tag could have been created elsewere before frontend submission
      tags = tags ++ Enum.map(tag_names, fn tag_name ->
        repo.insert!(
          %Tag{name: tag_name},
          on_conflict: [set: [name: tag_name]],
          conflict_target: :name
        )
      end)
      {:ok, tags}
    end
  end

  defp attr_tags_split_ids_names(tags) do
    attr_tags_split_ids_names(tags, {[], []})
  end
  defp attr_tags_split_ids_names([], result) do
    {:ok, result}
  end
  defp attr_tags_split_ids_names([tag | tags], {ids, names}) do
    case tag do
      %{"id" => id} when is_integer(id) ->
        attr_tags_split_ids_names(tags, {[id | ids], names})
      %{"id" => _id} ->
        {:error, :invalid_tag_id}
      %{"name" => name} ->
        attr_tags_split_ids_names(tags, {ids, [name | names]})
      _ ->
        {:error, :invalid_tag}
    end
  end

  defp update_persisted_stanza_multi(attrs, _operation) do
    Multi.new()
    |> Multi.run(:stanza_revision, fn repo, %{persisted_stanza: %Stanza{id: stanza_id}} ->
      attrs = Map.merge(attrs, %{"stanza_id" => stanza_id})
      # TODO: what happens on insertion of invalid changeset?
      repo.insert(StanzaRevision.changeset(%StanzaRevision{}, attrs))
    end)
    |> Multi.run(:stanza, fn repo, %{persisted_stanza: stanza, stanza_revision: %StanzaRevision{id: stanza_revision_id}} ->
      with {:ok, tags} = find_or_create_tags(repo, attrs["tags"]) do
        change_stanza(
          repo.preload(stanza, :tags),
          %{
            "name" => attrs["name"],
            "current_stanza_revision_id" => stanza_revision_id
          }
        ) |> Changeset.put_assoc(:tags, tags)
      end
      |> repo.update()
    end)
  end

  @doc """
  Updates a stanza.

  ## Examples

      iex> update_stanza(stanza, %{field: new_value})
      {:ok, %Stanza{}}

      iex> update_stanza(stanza, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stanza(%Stanza{} = stanza, attrs) do
    Multi.new()
    |> Multi.put(:persisted_stanza, stanza) # TODO: Stanza not from Multi "repo", problem?
    |> Multi.append(update_persisted_stanza_multi(attrs, :update))
    |> Repo.transaction()
    |> case do
      {:ok, %{stanza: stanza}} -> {:ok, stanza}
      {:error, failed_operation, failed_value, changes_so_far} ->
        IO.puts("Multi error")
        IO.inspect([failed_operation, failed_value, changes_so_far])
        {:error, :update_stanza_failed}
    end
  end

  @doc """
  Deletes a stanza.

  ## Examples

      iex> delete_stanza(stanza)
      {:ok, %Stanza{}}

      iex> delete_stanza(stanza)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stanza(%Stanza{} = stanza) do
    Repo.delete(stanza)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stanza changes.

  ## Examples

      iex> change_stanza(stanza)
      %Ecto.Changeset{data: %Stanza{}}

  """
  def change_stanza(%Stanza{} = stanza, attrs \\ %{}) do
    Stanza.changeset(stanza, attrs)
  end

  alias Ezstanza.Stanzas.StanzaRevision

  @doc """
  Returns the list of stanza_revision.

  ## Examples

      iex> list_stanza_revision()
      [%StanzaRevision{}, ...]

  """
  def list_stanza_revision do
    Repo.all(StanzaRevision)
  end

  @doc """
  Gets a single stanza_revision.

  Raises `Ecto.NoResultsError` if the Stanza revision does not exist.

  ## Examples

      iex> get_stanza_revision!(123)
      %StanzaRevision{}

      iex> get_stanza_revision!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stanza_revision!(id), do: Repo.get!(StanzaRevision, id)

  @doc """
  Creates a stanza_revision.

  ## Examples

      iex> create_stanza_revision(%{field: value})
      {:ok, %StanzaRevision{}}

      iex> create_stanza_revision(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stanza_revision(attrs \\ %{}) do
    %StanzaRevision{}
    |> StanzaRevision.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stanza_revision.

  ## Examples

      iex> update_stanza_revision(stanza_revision, %{field: new_value})
      {:ok, %StanzaRevision{}}

      iex> update_stanza_revision(stanza_revision, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stanza_revision(%StanzaRevision{} = stanza_revision, attrs) do
    stanza_revision
    |> StanzaRevision.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stanza_revision.

  ## Examples

      iex> delete_stanza_revision(stanza_revision)
      {:ok, %StanzaRevision{}}

      iex> delete_stanza_revision(stanza_revision)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stanza_revision(%StanzaRevision{} = stanza_revision) do
    Repo.delete(stanza_revision)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stanza_revision changes.

  ## Examples

      iex> change_stanza_revision(stanza_revision)
      %Ecto.Changeset{data: %StanzaRevision{}}

  """
  def change_stanza_revision(%StanzaRevision{} = stanza_revision, attrs \\ %{}) do
    StanzaRevision.changeset(stanza_revision, attrs)
  end
end
