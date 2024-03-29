defmodule Ezstanza.Configs do
  @moduledoc """
  The Configs context.
  """

  import Ecto.Query, warn: false
  import Ezstanza.TagsRelationship
  import Ezstanza.Pagination
  use Ezstanza.MultiHelpers, :config

  alias Ecto.Multi
  alias Ecto.Changeset
  alias Ezstanza.Repo

  alias Ezstanza.Configs.Config
  alias Ezstanza.Configs.ConfigRevision

  alias Ezstanza.Stanzas.StanzaRevision

  alias Ezstanza.Stanzas

  defp process_config_includes(query, includes) when is_list(includes) do
    config_revisions_preloader = fn config_ids ->
      Repo.all(from s_r in config_revision_base_query(),
        where: s_r.config_id in ^config_ids
      )
    end

    stanza_revisions_preloader = fn config_revision_ids ->
      Repo.all(from s_r in Stanzas.stanza_revision_base_query,
        join: s_r_c_r in assoc(s_r, :config_revisions),
        where: s_r_c_r.id in ^config_revision_ids,
        preload: [config_revisions: s_r_c_r]
        #select: {s_r_c_r.id, s_r} #TODO: Test this instead of flat_map below
      )
      |> Enum.flat_map(fn stanza_revision -> #TODO: Review this
        Enum.map(stanza_revision.config_revisions, fn config_revision ->
          {config_revision.id, stanza_revision}
        end)
      end)
    end

    Enum.reduce(includes, query, fn
      "revisions", query ->
        # TODO: Replace with Repo.preload
        from c in query,
        preload: [revisions: ^config_revisions_preloader]
      "stanza_revisions", query ->
        query
        |> preload([current_revision: c_r], [current_revision: {c_r, stanza_revisions: ^stanza_revisions_preloader}]) # Bit confused, can first preload be removed???
      _, query ->
        query
    end)
  end
  defp process_config_includes(query, _), do: query

  def config_base_query(%{} = params) do
    Enum.reduce(params, config_base_query(), fn
      {"includes", includes}, query ->
        process_config_includes(query, includes)
      _, query ->
        query
    end)
  end

  def config_base_query() do
    from c in Config,
      join: u in assoc(c, :user), as: :user,
      join: c_r in assoc(c, :current_revision), as: :current_revision,
      join: c_r_u in assoc(c_r, :user), as: :current_revision_user,
      preload: [
        user: u, current_revision: {c_r, user: c_r_u}
      ]
  end

  defp config_list_query(%{} = params) do
    config_base_query(params)
    |> order_by(^dynamic_order_by(params["order_by"]))
    |> where(^dynamic_where(params))
  end

  defp dynamic_order_by("name"), do: [asc: dynamic([s], s.name)]
  defp dynamic_order_by("name_desc"), do: [desc: dynamic([s], s.name)]
  defp dynamic_order_by("user_name"), do: [asc: dynamic([user: u], u.name)]
  defp dynamic_order_by("user_name_desc"), do: [desc: dynamic([user: u], u.name)]
  defp dynamic_order_by("revision_user_name"), do: [asc: dynamic([current_revision_user: u], u.name)]
  defp dynamic_order_by("revision_user_name_desc"), do: [desc: dynamic([current_revision_user: u], u.name)]
  defp dynamic_order_by("inserted_at"), do: [asc: dynamic([s], s.inserted_at)]
  defp dynamic_order_by("inserted_at_desc"), do: [desc: dynamic([s], s.inserted_at)]
  defp dynamic_order_by("updated_at"), do: [asc: dynamic([s], s.updated_at)]
  defp dynamic_order_by("updated_at_desc"), do: [desc: dynamic([s], s.updated_at)]

  defp dynamic_order_by(_), do: []

  defp dynamic_where(params) do
    filter_like = &(String.replace(&1, ~r"[%_]", ""))
    Enum.reduce(params, dynamic(true), fn
      {"name", value}, dynamic ->
        dynamic([s], ^dynamic and s.name == ^value)
      {"name_like", value}, dynamic ->
        dynamic([s], ^dynamic and ilike(s.name, ^"%#{filter_like.(value)}%"))
      {"user_name", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.name == ^value)
      {"user_name_like", value}, dynamic ->
        dynamic([user: u], ^dynamic and ilike(u.name, ^"%#{filter_like.(value)}%"))
      {"user_id", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.id == ^value)
      {"user_ids", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.id in ^value)
      {"revision_user_name", value}, dynamic ->
        dynamic([current_revision_user: u], ^dynamic and u.name == ^value)
      {"revision_user_name_like", value}, dynamic ->
        dynamic([current_revision_user: u], ^dynamic and ilike(u.name, ^"%#{filter_like.(value)}%"))
      {"revision_user_id", value}, dynamic ->
        dynamic([current_revision_user: u], ^dynamic and u.id == ^value)
      {"revision_user_ids", value}, dynamic ->
        dynamic([current_revision_user: u], ^dynamic and u.id in ^value)
      {_, _}, dynamic ->
        dynamic
    end)
  end

  @doc """
  Returns the list of configs.

  ## Examples

      iex> list_config()
      [%Config{}, ...]

  """
  def list_configs(params \\ %{}) do
    Repo.all config_list_query(params)
  end

  # TODO: Generalize, macro?
  def paginate_configs(%{"page" => _page, "size" => _size} = params) do
    paginate_entries(config_list_query(params), params)
  end

  @doc """
  Gets a single config.

  Returns nil if the config does not exist.

  ## Examples

      iex> get_config(123)
      %Config{}

      iex> get_config(456)
      ** nil

  """
  #def get_config(id) do
  #  Repo.one(from s in config_base_query(), where: s.id == ^id)
  #end
  def get_config(id, %{} = params \\ %{}) do
    Repo.one(from s in config_base_query(params), where: s.id == ^id)
  end

  @doc """
  Creates a config.

  Required params: name, body, user_id
  Optional: tags? [%{name: <name, id: <id|nil>}, ...]

  ## Examples

      iex> create_config(%{field: value})
      {:ok, %Config{}}

      iex> create_config(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_config(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:persisted_config, change_config(%Config{}, attrs))
    |> Multi.append(update_persisted_config_multi(attrs))
    |> Repo.transaction()
    |> handle_entity_multi_transaction_result(:create_config_failed)
  end

  defp update_persisted_config_multi(attrs) do
    Multi.new()
    |> Multi.run(:config_revision, fn repo, %{persisted_config: %Config{id: config_id}} ->
      attrs = Map.merge(attrs, %{"config_id" => config_id})
      # TODO: what happens on insertion of invalid changeset?
      change_config_revision(%ConfigRevision{}, attrs)
      |> Changeset.put_assoc(:stanza_revisions, Stanzas.get_stanza_revisions(attrs["stanza_revisions"])) #TODO stanza_revision_ids??
      |> repo.insert()
    end)
    |> Multi.run(:config, fn repo, %{persisted_config: config, config_revision: %ConfigRevision{id: config_revision_id}} ->
      with {:ok, tags} = find_or_create_tags(repo, attrs["tags"], attrs["user_id"]) do # TODO: Remove tags?
        change_config(
          repo.preload(config, :tags),
          Map.merge(attrs, %{
            "current_config_revision_id" => config_revision_id
          })
        ) |> Changeset.put_assoc(:tags, tags)
      end
      |> repo.update()
    end)
  end

  @doc """
  Updates a config.

  ## Examples

      iex> update_config(config, %{field: new_value})
      {:ok, %Config{}}

      iex> update_config(config, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_config(%Config{} = config, attrs) do
    Multi.new()
    |> Multi.put(:persisted_config, config) # TODO: Config not from Multi "repo", problem? Fix same way as for stanzas?
    |> Multi.append(update_persisted_config_multi(attrs))
    |> Repo.transaction()
    |> handle_entity_multi_transaction_result(:update_config_failed)
  end

  @doc """
  Deletes a config.

  ## Examples

      iex> delete_config(config)
      {:ok, %Config{}}

      iex> delete_config(config)
      {:error, %Ecto.Changeset{}}

  """
  def delete_config(%Config{} = config) do
    Repo.delete(config)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking config changes.

  ## Examples

      iex> change_config(config)
      %Ecto.Changeset{data: %Config{}}

  """
  def change_config(%Config{} = config, attrs \\ %{}) do
    Config.changeset(config, attrs)
  end

  def config_revision_base_query() do
    from c_r in ConfigRevision,
      join: c in assoc(c_r, :config), as: :config,
      join: c_u in assoc(c, :user), as: :config_user,
      join: c_r_u in assoc(c_r, :user), as: :user,
      preload: [user: c_r_u, config: {c, user: c_u}],
      #select_merge: %{is_current_revision: fragment("CASE WHEN ? = ? THEN TRUE ELSE FALSE END", c_r.id, c.current_config_revision_id)}
      select_merge: %{is_current_revision: fragment("? = ?", c_r.id, c.current_config_revision_id)}
  end

  @doc """
  Creates a config revision.

  ## Examples

      iex> create_config_revision(%{field: value})
      {:ok, %ConfigRevision{}}

      iex> create_config_revision(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_config_revision(attrs \\ %{}) do
    %ConfigRevision{}
    |> ConfigRevision.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking config revision changes.

  ## Examples

      iex> change_config_revision(config_revision)
      %Ecto.Changeset{data: %ConfigRevision{}}

  """
  def change_config_revision(%ConfigRevision{} = config_revision, attrs \\ %{}) do #TODO: WTF, attrs?
    ConfigRevision.changeset(config_revision, attrs)
  end

  def config_revision_to_string(%ConfigRevision{} = config_revision) do
    # TODO: Better separator between stanzas etc
    # Ensure stanza_revisions loaded
    config_revision
    |> Repo.preload(:stanza_revisions)
    |> Map.fetch!(:stanza_revisions)
    |> Enum.map_join("\n\n", fn stanza_revision ->
        # TODO: Edited by user, date comment?
        stanza_revision.body
    end)
  end

end
