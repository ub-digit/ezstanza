defmodule Ezstanza.Stanzas do
  @moduledoc """
  The Stanzas context.
  """

  import Ecto.Query, warn: false
  import Ezstanza.TagsRelationship
  import Ezstanza.Pagination
  use Ezstanza.MultiHelpers, :stanza

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Ezstanza.Repo

  alias Ezstanza.Stanzas.Stanza
  alias Ezstanza.Stanzas.StanzaRevision

  def stanza_base_query() do
    from s in Stanza,
      join: u in assoc(s, :user), as: :user,
      join: c_r in assoc(s, :current_revision), as: :current_revision,
      join: c_r_u in assoc(c_r, :user), as: :current_revision_user,
      preload: [user: u, current_revision: {c_r, user: c_r_u}]
  end

  defp list_query(%{} = params) do
    stanza_base_query()
    |> order_by(^dynamic_order_by(params["order_by"]))
    |> where(^dynamic_where(params))
  end

  # TOOD: macro for this?
  defp dynamic_order_by("name"), do: [asc: dynamic([s], s.name)]
  defp dynamic_order_by("name_desc"), do: [desc: dynamic([s], s.name)]
  defp dynamic_order_by("user_name"), do: [asc: dynamic([user: u], u.name)]
  defp dynamic_order_by("user_desc"), do: [desc: dynamic([user: u], u.name)]
  defp dynamic_order_by("inserted_at"), do: [asc: dynamic([s], s.inserted_at)]
  defp dynamic_order_by("inserted_at_desc"), do: [desc: dynamic([s], s.inserted_at)]
  defp dynamic_order_by("updated_at"), do: [asc: dynamic([s], s.updated_at)]
  defp dynamic_order_by("updated_at_desc"), do: [desc: dynamic([s], s.updated_at)]

  defp dynamic_order_by(_), do: []

  # TODO: put in helper module
  defp filter_like(string), do: String.replace(string, ~r"[%_]", "")

  defp dynamic_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"name", value}, dynamic ->
        dynamic([s], ^dynamic and s.name == ^value)
      {"name_like", value}, dynamic ->
        dynamic([s], ^dynamic and ilike(s.name, ^"%#{filter_like(value)}%"))
      {"user_name", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.name == ^value)
      {"user_name_like", value}, dynamic ->
        dynamic([user: u], ^dynamic and ilike(u.name, ^"%#{filter_like(value)}%"))
      {"id_not_in", value}, dynamic ->
        dynamic([s], ^dynamic and s.id not in ^String.split(value, ","))
      {_, _}, dynamic ->
        dynamic
    end)
  end

  @doc """
  Returns the list of stanzas.

  ## Examples

      iex> list_stanza()
      [%Stanza{}, ...]

  """
  # TODO: forgotten to add deleted flag on schema
  def list_stanzas(params \\ %{}) do
    Repo.all list_query(params)
  end

  def paginate_stanzas(%{"page" => page, "size" => size} = params) do
    paginate_entries(list_query(params), params)
  end

  @doc """
  Gets a single stanza.

  Returns nil if the stanza does not exist.

  ## Examples

      iex> get_stanza(123)
      %Stanza{}

      iex> get_stanza(456)
      ** nil

  """
  def get_stanza(id) do
    Repo.one(from s in stanza_base_query(), where: s.id == ^id)
  end

  #def get_stanza(id, %{"include" => includes} = params) do
  def get_stanza(id, %{} = params) do
    includes = Map.get(params, "includes", [])
    query = Enum.reduce(includes, stanza_base_query(), fn
      "revisions", query ->
        from s in query,
        join: s_r in assoc(s, :revisions), as: :stanza_revisions,
        join: s_r_u in assoc(s_r, :user), as: :stanza_revision_user,
        join: s_r_s in assoc(s_r, :stanza), as: :stanza_revision_stanza,
        join: s_r_s_u in assoc(s_r_s, :user), as: :stanza_user,
        preload: [revisions: {s_r, user: s_r_u, stanza: {s_r_s, user: s_r_s_u}}]
      _, query ->
        query
    end)
    Repo.one(from s in query, where: s.id == ^id)
  end

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
    |> Map.fetch(:stanza)
    |> handle_entity_multi_transaction_result(:create_stanza_failed)
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
    |> handle_entity_multi_transaction_result(:update_stanza_failed)
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


  # Used for put_assoc in configs context, put in configs.ex or rename for clarity?
  @doc """
  Gets multiple stanza revisions.

  ## Examples

      iex> get_stanza_revisions([123])
      [%Stanza{}]

      iex> get_stanza_revisions([456])
      ** []

  """
  def get_stanza_revisions(revision_ids) do
    Repo.all(from s in StanzaRevision, where: s.id in ^revision_ids)
  end

  def stanza_revision_base_query() do
    from s_r in StanzaRevision,
      join: s in assoc(s_r, :stanza), as: :stanza,
      join: s_u in assoc(s, :user), as: :stanza_user,
      join: s_r_u in assoc(s_r, :user), as: :user,
      preload: [user: s_r_u, stanza: {s, user: s_u}],
      select_merge: %{is_current_revision: fragment("CASE WHEN ? = ? THEN TRUE ELSE FALSE END", s_r.id, s.current_stanza_revision_id)},
      #select_merge: %{is_current_revision: fragment("? = ?", s_r.id, s.current_stanza_revision_id)},
      order_by: [desc: s_r.id] #TODO: remove this!
  end

  #defp stanza_revision_list_query(%{"stanza_id" => stanza_id}) do
  defp stanza_revision_list_query(%{} = params) do
    stanza_revision_base_query()
    |> where(^stanza_revisions_dynamic_where(params))
  end

  def list_stanza_revisions(%{} = params) do
    Repo.all stanza_revision_list_query(params)
  end

  def paginate_stanza_revisions(%{"page" => page, "size" => size} = params) do
    paginate_entries(stanza_revision_list_query(params), params)
  end

  defp stanza_revisions_dynamic_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"name", value}, dynamic ->
        dynamic([stanza: s], ^dynamic and s.name == ^value)
      {"name_like", value}, dynamic ->
        dynamic([stanza: s], ^dynamic and ilike(s.name, ^"%#{filter_like(value)}%"))
      {"user_name", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.name == ^value)
      {"user_name_like", value}, dynamic ->
        dynamic([user: u], ^dynamic and ilike(u.name, ^"%#{filter_like(value)}%"))
      {"id_not_in", value}, dynamic ->
        dynamic([s_r], ^dynamic and s_r.id not in ^String.split(value, ","))
      {"stanza_id", value}, dynamic ->
        dynamic([s_r], ^dynamic and s_r.stanza_id == ^value)
      {"is_current_revision", true}, dynamic ->
        dynamic([s_r, s], ^dynamic and s_r.id == s.current_stanza_revision_id)
      {"is_current_revision", false}, dynamic ->
        dynamic([s_r, s], ^dynamic and s_r.id != s.current_stanza_revision_id)
      {_, _}, dynamic ->
        dynamic
    end)
  end

  defp stanza_revisions_dynamic_order_by("id"), do: [asc: dynamic([s_r], s_r.id)]
  defp stanza_revisions_dynamic_order_by("id_desc"), do: [desc: dynamic([s_r], s_r.id)]
  defp stanza_revisions_dynamic_order_by("name"), do: [asc: dynamic([stanza: s], s.name)]
  defp stanza_revisions_dynamic_order_by("name_desc"), do: [desc: dynamic([stanza: s], s.name)]
  defp stanza_revisions_dynamic_order_by("user_name"), do: [asc: dynamic([user: u], u.name)]
  defp stanza_revisions_dynamic_order_by("user_desc"), do: [desc: dynamic([user: u], u.name)]
  defp stanza_revisions_dynamic_order_by("inserted_at"), do: [asc: dynamic([s_r], s_r.inserted_at)]
  defp stanza_revisions_dynamic_order_by("inserted_at_desc"), do: [desc: dynamic([s_r], s_r.inserted_at)]
  defp stanza_revisions_dynamic_order_by("updated_at"), do: [asc: dynamic([s_r], s_r.updated_at)]
  defp stanza_revisions_dynamic_order_by("updated_at_desc"), do: [desc: dynamic([s_r], s_r.updated_at)]
  defp stanza_revisions_dynamic_order_by(_), do: []

end
