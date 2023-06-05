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

  alias Ezstanza.Configs
  alias Ezstanza.Configs.Config
  alias Ezstanza.Configs.ConfigRevision

  defp process_stanza_includes(query, includes) when is_list(includes) do
    # TODO: Replace with preloader query?
    stanza_revisions_preloader = fn stanza_ids ->
      Repo.all(from s_r in stanza_revision_base_query(),
        where: s_r.stanza_id in ^stanza_ids
      )
    end
    Enum.reduce(includes, query, fn
      "revisions", query ->
        # TODO: Replace with Repo.preload?
        from s in query,
          preload: [revisions: ^stanza_revisions_preloader]
      _, query ->
        query
    end)
  end
  defp process_stanza_includes(query, _), do: query

  def stanza_base_query(%{} = params) do
    Enum.reduce(params, stanza_base_query(), fn
      {"includes", includes}, query ->
        process_stanza_includes(query, includes)
      _, query ->
        query
    end)
  end

  def stanza_base_query() do
    from s in Stanza,
      join: u in assoc(s, :user), as: :user,
      join: c_r in assoc(s, :current_revision), as: :current_revision, # Preload through base query?
      join: c_r_u in assoc(c_r, :user), as: :current_revision_user,
      preload: [
        #:current_revision_current_configs,
        #:current_configs,
        user: u,
        current_revision: {c_r, user: c_r_u},
        current_configs_stanza_revisions: ^stanza_revision_base_query()
      ]
  end

  # join config_revisions, join current_config_revisions/ current_configs

  defp list_query(%{} = params) do
    stanza_base_query(params)
    |> process_stanza_list_query(params) # Replace with then?
    |> order_by(^dynamic_order_by(params["order_by"]))
    |> where(^dynamic_where(params))
  end

  defp process_stanza_list_query(query, %{} = params) do
    Enum.reduce(params, query, fn
      # TOOD: current_config_ids for consitency/clarity?
      {"config_ids", config_ids}, query ->
        from s in query,
          join: s_c_c in assoc(s, :current_configs),
          where: s_c_c.id in ^config_ids
      {"config_id", config_id}, query ->
        from s in query,
          join: s_c_c in assoc(s, :current_configs),
          where: s_c_c.id == ^config_id
      _, query ->
        query
    end)
  end

  # TOOD: macro for this?
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
      {"user_id", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.id == ^value)
      {"user_ids", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.id in ^value)
      {"revision_user_name", value}, dynamic ->
        dynamic([current_revision_user: u], ^dynamic and u.name == ^value)
      {"revision_user_name_like", value}, dynamic ->
        dynamic([current_revision_user: u], ^dynamic and ilike(u.name, ^"%#{filter_like(value)}%"))
      {"revision_user_id", value}, dynamic ->
        dynamic([current_revision_user: u], ^dynamic and u.id == ^value)
      {"revision_user_ids", value}, dynamic ->
        dynamic([current_revision_user: u], ^dynamic and u.id in ^value)
      {"id_not_in", value}, dynamic ->
        dynamic([s], ^dynamic and s.id not in ^String.split(value, ",")) # TODO use id_not_in[] param instead
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
    list_query(params)
    |> paginate_entries(params)
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

  def get_stanza(id, %{} = params) do
    Repo.one(from s in stanza_base_query(params), where: s.id == ^id)
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
    |> Multi.append(update_persisted_stanza_multi(attrs))
    |> Multi.run(:add_to_config_revisions, fn repo, _ ->
      #TODO: Validation! (Also in update_stanza)
      Map.get(attrs, "configs", [])
      |> Enum.filter(&Map.get(&1, "publish"))
      |> Enum.map(&Map.get(&1, "id"))
      |> get_current_config_revisions_with_stanza_revisions(repo)
    end)
    |> Multi.append(maybe_add_stanza_revision_to_configs_multi(attrs))
    |> Repo.transaction()
    |> handle_entity_multi_transaction_result(:create_stanza_failed)
  end


  # TODO: move this someplace better
  # name is a little bit kludgy
  defp get_current_config_revisions_with_stanza_revisions(config_ids, repo) do
    repo.all(
      from c_r in ConfigRevision,
      join: c_r_c in assoc(c_r, :config),
      join: c_r_s_r in assoc(c_r, :stanza_revisions),
      where: c_r_c.current_config_revision_id == c_r.id and c_r_c.id in ^config_ids,
      preload: [stanza_revisions: c_r_s_r, config: c_r_c]
    )
    |> case do
      # Correct way to handle this? Pass not found config ids?
      config_revisions when length(config_revisions) != length(config_ids) -> {:error, :not_found}
      config_revisions -> {:ok, config_revisions}
    end
  end

  defp maybe_add_stanza_revision_to_configs_multi(attrs) do
    Multi.new()
    |> Multi.merge(
      fn %{
        add_to_config_revisions: add_to_config_revisions,
        stanza_revision: %StanzaRevision{} = current_stanza_revision
      } ->
        Enum.reduce(add_to_config_revisions, Multi.new(), fn %ConfigRevision{config_id: config_id, config: config} = config_revision, multi ->
          config_revision_attrs = %{
            "user_id" => attrs["user_id"],
            "log_message" => attrs["stanza_added_log_message"],
            "config_id" => config_id
          }
          # Add current stanza revision
          config_revision_changeset =
            %ConfigRevision{}
            |> ConfigRevision.changeset(config_revision_attrs)
            |> Changeset.put_assoc(
              :stanza_revisions,
              [current_stanza_revision | config_revision.stanza_revisions]
            )
          config_revision_multi_key = {:added_to_config_revision, config_id}
          multi
          |> Multi.insert(config_revision_multi_key, config_revision_changeset)
          |> Multi.update(
            {:added_to_config, config_id},
            fn %{^config_revision_multi_key => %ConfigRevision{id: id}} ->
              config
              |> Config.changeset(Map.take(attrs, ["user_id"]))
              |> Changeset.put_change(:current_config_revision_id, id)
            end
          )
        end)
      end
    )
  end

  defp update_persisted_stanza_multi(attrs) do

#    get_config_revision = fn (config_id) ->
#      config = Repo.get(Config, config_id)
#      config_revision = Repo.one(
#        from c_r in ConfigRevision,
#        join: c_r_s_r in assoc(c_r, :stanza_revisions),
#        where: c_r.id == ^config.current_config_revision_id,
#        preload: [stanza_revisions: c_r_s_r]
#      )
#      case {config, config_revision} do
#        {config, config_revision} when not(is_nil(config) or is_nil(config_revision)) ->
#            {:ok, config, config_revision}
#        _ ->
#            {:error, :not_found} #?
#      end
#    end

#    get_config = fn id ->
#      case Repo.get(Config, config_id) do
#        nil -> {:error, :not_found}
#        config -> {:ok, config}
#      end
#    end
#
#    get_current_config_revision_with_stanza_revisions = fn config_id ->
#      case Repo.one(
#        from c_r in ConfigRevision,
#        join: c_r_c in Config,
#        join: c_r_s_r in assoc(c_r, :stanza_revisions),
#        where: c_r_c.id == ^config_id and c_r_c.current_config_revision_id == c_r.id
#        preload: [stanza_revisions: c_r_s_r, config: c_r_c]
#      ) do
#        nil -> {:error, :not_found}
#        config_revision -> {:ok, config_revision}
#      end
#    end

    Multi.new()
    |> Multi.run(:stanza_revision, fn
      repo, %{persisted_stanza: %Stanza{id: stanza_id} = stanza} ->
        attrs = Map.merge(attrs, %{"stanza_id" => stanza_id})
        case stanza do
          # No current revision, create new stanza revision
          %Stanza{current_stanza_revision_id: nil} ->
            repo.insert(StanzaRevision.changeset(%StanzaRevision{}, attrs))
          # Has current revision, if no revision level changes has been made
          # re-use current revision, else create new
          %Stanza{current_stanza_revision_id: revision_id} ->
            current_stanza_revision = Repo.get(StanzaRevision, revision_id)
            case StanzaRevision.changeset(current_stanza_revision, attrs) do
              %Changeset{changes: %{body: _}} ->
                # Stanza body has changed, create new revision
                repo.insert(StanzaRevision.changeset(%StanzaRevision{}, attrs))
              _ ->
                # Else return current revision
                {:ok, current_stanza_revision}
            end
        end
    end)
    |> Multi.run(
      :stanza,
      fn repo, %{
        persisted_stanza: stanza,
        stanza_revision: %StanzaRevision{
          id: stanza_revision_id,
        } = stanza_revision
      } ->
        with {:ok, tags} = find_or_create_tags(repo, attrs["tags"]) do
          change_stanza(
            repo.preload(stanza, :tags),
            Map.merge(attrs, %{
              "current_stanza_revision_id" => stanza_revision_id
            })
          )
          |> Changeset.put_assoc(:tags, tags)
        end
        |> repo.update()
      end
    )
  end

  @doc """
  Updates a stanza.

  ## Examples

      iex> update_stanza(stanza, %{field: new_value})
      {:ok, %Stanza{}}

      iex> update_stanza(stanza, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  #def update_stanza(%Stanza{} = stanza, attrs) do
  # TODO: Macro for stale checking
  def update_stanza(id, %{"revision_id" => revision_id} = attrs) do
    # TODO: Validate attrs, user input, might crash?
    configs = Map.get(attrs, "configs", [])
    include_in_config_ids = configs
                            |> Enum.map(&Map.get(&1, "id"))
    publish_in_config_ids = configs
                            |> Enum.filter(&Map.get(&1, "publish"))
                            |> Enum.map(&Map.get(&1, "id"))
    remove_stanza_revision_by_stanza_id = fn stanza_revisions, stanza_id ->
      Enum.reject(stanza_revisions, fn stanza_revision ->
        stanza_revision.stanza_id == stanza_id
      end)
    end

    Multi.new()
    |> Multi.run(:persisted_stanza, fn repo, _changes ->
      case repo.get(Stanza, id) do
        %Stanza{current_stanza_revision_id: ^revision_id} = stanza ->
          {:ok, stanza}
        %Stanza{} = stanza ->
          {:error, :stale}
        nil ->
          {:error, :not_found}
      end
    end)
    |> Multi.run(
      :previous_stanza_with_configs,
      fn repo, %{persisted_stanza: %Stanza{id: id}} ->
        # TODO: Join preloads? Use base query???
        case repo.one(from s in Stanza,
          where: s.id == ^id,
          preload: [:current_configs, :current_revision_current_configs]
        ) do
          nil -> {:error, :not_found}
          stanza ->
            {:ok, stanza}
        end
      end
    )
    |> Multi.append(update_persisted_stanza_multi(attrs))
    # TODO: Add multi run adding attribute for if new revision?
    |> Multi.run(:add_to_config_revisions, fn repo, %{
      stanza_revision: %StanzaRevision{id: stanza_revision_id},
      persisted_stanza: %Stanza{current_stanza_revision_id: previous_stanza_revision_id},
      previous_stanza_with_configs: %Stanza{current_revision_current_configs: current_revision_current_configs}
    } ->
        # Get configs where has been added
        if stanza_revision_id == previous_stanza_revision_id do
          # If stanza revision not changed, only add to configs
          # not already containg current revision
          Enum.reject(publish_in_config_ids, fn id ->
            Enum.any?(current_revision_current_configs, fn current_config ->
              current_config.id == id
            end)
          end)
        else
          publish_in_config_ids
        end
        |> get_current_config_revisions_with_stanza_revisions(repo)
    end)
    |> Multi.append(maybe_add_stanza_revision_to_configs_multi(attrs))
    |> Multi.run(
      :remove_from_current_config_revisions,
      fn repo, %{
        previous_stanza_with_configs: %Stanza{current_configs: current_configs}
      } ->
        # Get configs where has been removed
        Enum.reject(current_configs, fn current_config ->
          Enum.any?(include_in_config_ids, fn id ->
            id == current_config.id
          end)
        end)
        |> Enum.map(fn config -> config.id end)
        |> get_current_config_revisions_with_stanza_revisions(repo)
      end
    )
    # Maybe remove, break out in function?
    |> Multi.merge(
      fn %{
        remove_from_current_config_revisions: remove_from_current_config_revisions,
        stanza_revision: %StanzaRevision{stanza_id: stanza_id}
      } ->
        remove_from_current_config_revisions
        |> Enum.reduce( Multi.new(), fn %ConfigRevision{config_id: config_id, config: config} = config_revision, multi ->
          config_revision_attrs = %{
            "user_id" => attrs["user_id"],
            "log_message" => attrs["stanza_removed_log_message"],
            "config_id" => config_id
          }
          # Remove current stanza revision
          config_revision_changeset =
            %ConfigRevision{}
            |> ConfigRevision.changeset(config_revision_attrs)
            |> Changeset.put_assoc(
              :stanza_revisions,
              remove_stanza_revision_by_stanza_id.(config_revision.stanza_revisions, stanza_id)
            )
          config_revision_multi_key = {:removed_from_config_revision, config_id}
          multi
          |> Multi.insert(config_revision_multi_key, config_revision_changeset)
          |> Multi.update(
            {:removed_from_config, config_id},
            fn %{^config_revision_multi_key => %ConfigRevision{id: id}} ->
              config
              |> Config.changeset(Map.take(attrs, ["user_id"]))
              |> Changeset.put_change(:current_config_revision_id, id)
            end
          )
        end)
      end
    )
    |> Multi.run(:replace_in_config_revisions, fn repo, %{
      stanza_revision: %StanzaRevision{id: stanza_revision_id},
      persisted_stanza: %Stanza{current_stanza_revision_id: previous_stanza_revision_id},
      previous_stanza_with_configs: %Stanza{current_revision_current_configs: current_revision_current_configs}
    } ->
        if stanza_revision_id == previous_stanza_revision_id do
          # Stanza revision has not changed, nothing to replace
          {:ok, []}
        else
          # Get configs which contains a previous revision
          # and thus has not had stanza revision previously added
          # (see :add_to_config_revisions)
          Enum.filter(publish_in_config_ids, fn id ->
            Enum.any?(current_revision_current_configs, fn current_config ->
              current_config.id == id
            end)
          end)
          |> get_current_config_revisions_with_stanza_revisions(repo)
        end
    end)
    |> Multi.merge(fn %{
      replace_in_config_revisions: replace_in_config_revisions, #TODO: remove from_current_config_revisions?
      stanza_revision: %StanzaRevision{stanza_id: stanza_id} = stanza_revision
    } ->
        Enum.reduce(replace_in_config_revisions, Multi.new(), fn %ConfigRevision{config_id: config_id, config: config} = config_revision, multi ->
          config_revision_attrs = %{
            "user_id" => attrs["user_id"],
            "log_message" => attrs["log_message"], ##???
            "config_id" => config_id
          }
          # Replace current stanza revision
          config_revision_changeset =
            %ConfigRevision{}
            |> ConfigRevision.changeset(config_revision_attrs)
            |> Changeset.put_assoc(
              :stanza_revisions, [
                stanza_revision |
                remove_stanza_revision_by_stanza_id.(
                  config_revision.stanza_revisions,
                  stanza_id
                )
              ]
            )
          config_revision_multi_key = {:replaced_in_config_revision, config_id}
          multi
          |> Multi.insert(config_revision_multi_key, config_revision_changeset)
          |> Multi.update(
            {:replaced_in_config, config_id},
            fn %{^config_revision_multi_key => %ConfigRevision{id: id}} ->
              config
              |> Config.changeset(Map.take(attrs, ["user_id"]))
              |> Changeset.put_change(:current_config_revision_id, id)
            end
          )
        end)
    end)
    |> Repo.transaction()
    |> handle_entity_multi_transaction_result(:update_stanza_failed)
  end

  def update_stanza(id, attrs) do
    {:error, :missing_current_stanza_revision_id} #??
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
      preload: [:current_configs, user: s_r_u, stanza: {s, user: s_u}], #TODO: Add current deployments?
      select_merge: %{is_current_revision: fragment("CASE WHEN ? = ? THEN TRUE ELSE FALSE END", s_r.id, s.current_stanza_revision_id)}
      #select_merge: %{is_current_revision: fragment("? = ?", s_r.id, s.current_stanza_revision_id)},
  end

  #defp stanza_revision_list_query(%{"stanza_id" => stanza_id}) do
  defp stanza_revision_list_query(%{} = params) do
    stanza_revision_base_query()
    |> order_by(^stanza_revision_dynamic_order_by(params["order_by"]))
    |> where(^stanza_revision_dynamic_where(params))
  end

  def list_stanza_revisions(%{} = params) do
    Repo.all stanza_revision_list_query(params)
  end

  def paginate_stanza_revisions(%{"page" => page, "size" => size} = params) do
    paginate_entries(stanza_revision_list_query(params), params)
  end

  defp stanza_revision_dynamic_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"name", value}, dynamic ->
        dynamic([stanza: s], ^dynamic and s.name == ^value)
      {"name_like", value}, dynamic ->
        dynamic([stanza: s], ^dynamic and ilike(s.name, ^"%#{filter_like(value)}%"))
      {"user_name", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.name == ^value)
      {"user_name_like", value}, dynamic ->
        dynamic([user: u], ^dynamic and ilike(u.name, ^"%#{filter_like(value)}%"))
      {"stanza_id_not_in", value}, dynamic ->
        dynamic([s_r], ^dynamic and s_r.stanza_id not in ^String.split(value, ","))
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

  defp stanza_revision_dynamic_order_by("id"), do: [asc: dynamic([s_r], s_r.id)]
  defp stanza_revision_dynamic_order_by("id_desc"), do: [desc: dynamic([s_r], s_r.id)]
  defp stanza_revision_dynamic_order_by("name"), do: [asc: dynamic([stanza: s], s.name)]
  defp stanza_revision_dynamic_order_by("name_desc"), do: [desc: dynamic([stanza: s], s.name)]
  defp stanza_revision_dynamic_order_by("user_name"), do: [asc: dynamic([user: u], u.name)]
  defp stanza_revision_dynamic_order_by("user_desc"), do: [desc: dynamic([user: u], u.name)]
  defp stanza_revision_dynamic_order_by("inserted_at"), do: [asc: dynamic([s_r], s_r.inserted_at)]
  defp stanza_revision_dynamic_order_by("inserted_at_desc"), do: [desc: dynamic([s_r], s_r.inserted_at)]
  defp stanza_revision_dynamic_order_by("updated_at"), do: [asc: dynamic([s_r], s_r.updated_at)]
  defp stanza_revision_dynamic_order_by("updated_at_desc"), do: [desc: dynamic([s_r], s_r.updated_at)]
  defp stanza_revision_dynamic_order_by(_), do: []

end
