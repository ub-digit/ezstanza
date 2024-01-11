defmodule Ezstanza.Stanzas do
  @moduledoc """
  The Stanzas context.
  """

  require Logger

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

  alias Ezstanza.Deployments

  alias Ezstanza.StanzaParser

  alias Ezstanza.EntityValidations

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
          preload: [revisions: ^stanza_revisions_preloader] # ^stanza_revisions_base_query() instead?
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
      left_join: t in assoc(s, :tags), as: :tags,
      join: u in assoc(s, :user), as: :user,
      join: c_r in assoc(s, :current_revision), as: :current_revision, # Preload through base query?
      join: c_r_u in assoc(c_r, :user), as: :current_revision_user,
      preload: [
        #:current_revision_current_configs,
        #:current_configs,
        tags: t,
        user: u,
        current_revision: {c_r, user: c_r_u},
        current_deployments_stanza_revisions: ^stanza_revision_base_query()
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
      {"search_query", search_query}, query ->
        from s in query,
          where: fragment(
            "searchable @@ websearch_to_tsquery(?)",
            ^search_query
          )
          or ilike(s.name, ^"%#{filter_like(search_query)}%")
          or ilike(s.current_stanza_revision_body, ^"%#{filter_like(search_query)}%"),
          order_by: {
            :desc,
            fragment(
              "ts_rank_cd(searchable, websearch_to_tsquery(?), 1)",
              ^search_query
            )
          }
      {"tag_ids", tag_ids}, query ->
        # Hack because of frontend reaons
        # (AutoCompleteCompoennt quirks)
        tag_ids = if is_list(tag_ids), do: tag_ids, else: [tag_ids]
        from s in query,
          join: s_t in assoc(s, :tags),
          where: s_t.id in ^tag_ids
      {"deployment_ids", deployment_ids}, query -> #Remove?
        from s in query,
          join: s_c_c in assoc(s, :deployments),
          where: s_c_c.id in ^deployment_ids
      {"deployment_id", deployment_id}, query ->
        from s in query,
          join: s_c_c in assoc(s, :deployments),
          where: s_c_c.id == ^deployment_id
      {"deployment_ids_not_equals", deployment_ids}, query ->
        Enum.reduce(deployment_ids, query, fn deployment_id, query ->
          # @FIXME: Code duplication, worth breaking out?
          stanza_ids_in_deployment = from sr in StanzaRevision,
            join: d_sr in "deployment_stanza_revision",
            on: sr.id == d_sr.stanza_revision_id,
            where: d_sr.deployment_id == ^deployment_id,
            select: %{
              stanza_id: sr.stanza_id
            }
          from s in query,
            where: s.id not in subquery(stanza_ids_in_deployment)
        end)
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
  # why do we filter out _?
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
    #|> Multi.run(:add_to_config_revisions, fn repo, _ ->
    #  #TODO: Validation! (Also in update_stanza)
    #  Map.get(attrs, "configs", [])
    #  |> Enum.filter(&Map.get(&1, "publish"))
    #  |> Enum.map(&Map.get(&1, "id"))
    #  |> get_current_config_revisions_with_stanza_revisions(repo)
    #end)
    # |> Multi.append(maybe_add_stanza_revision_to_configs_multi(attrs))
    #|> Multi.append(maybe_deploy_stanza_revision__multi(attrs))#??
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
            # Normalize stanza, or leave as is, option?
            attrs = Map.update(attrs, "body", "", &StanzaParser.normalize_string/1)
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
          body: stanza_revision_body
        } = stanza_revision
      } ->
        with {:ok, tags} = find_or_create_tags(repo, attrs["tags"], attrs["user_id"]) do
          stanza = repo.preload(stanza, :tags)
          change_stanza(
            stanza,
            Map.merge(attrs, %{
              "current_stanza_revision_id" => stanza_revision_id,
              # Set field used for search index
              "current_stanza_revision_body" => stanza_revision_body,
            })
          )
          |> then(fn changeset ->
            # Superhack, force update if tags changed
            current_tag_ids = Enum.map(stanza.tags, &(&1.id)) |> Enum.sort()
            new_tag_ids = Enum.map(tags, &(&1.id)) |> Enum.sort()
            if current_tag_ids != new_tag_ids do
              # TODO: How get ecto type default value?
              Changeset.change(
                changeset,
                updated_at: %{NaiveDateTime.utc_now() | microsecond: {0, 0}}
              )
            else
              changeset
            end
          end)
          |> Changeset.put_assoc(:tags, tags)
          |> repo.update()
        end
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
  # TODO: Macro for stale checking
  def update_stanza(id, %{"revision_id" => revision_id} = attrs) do
    # TODO: Validate attrs, user input, might crash?
    with {:ok, stanza} <-
      Multi.new()
      |> Multi.run(:persisted_stanza, fn repo, _changes ->
        validate_disabled = fn
          %Stanza{disabled: true} = stanza ->
            case stanza |> repo.preload(:current_deployments) do
              %Stanza{current_deployments: []} ->
                :ok
              _ ->
                {:error, :disabled_with_current_deployments}
            end
          _ -> :ok
        end

        stanza = repo.get(Stanza, id)
        with :ok <- EntityValidations.found(stanza),
             :ok <- EntityValidations.not_stale(stanza, :current_stanza_revision_id, revision_id),
             :ok <- validate_disabled.(stanza)
        do
          {:ok, stanza}
        end

        #case repo.get(Stanza, id) do
        #  %Stanza{current_stanza_revision_id: ^revision_id} = stanza ->
        #    {:ok, stanza}
        #  %Stanza{} = stanza ->
        #    {:error, :stale}
        #  nil ->
        #    {:error, :not_found}
        #end
      end)
      |> Multi.append(update_persisted_stanza_multi(attrs))
      |> Repo.transaction()
      |> handle_entity_multi_transaction_result(:update_stanza_failed)
    do
        maybe_deploy_stanza(stanza, attrs)
        {:ok, stanza}
    end
  end

  def update_stanza(id, attrs) do
    {:error, :missing_current_stanza_revision_id} #??
  end

  def maybe_deploy_stanza(
    %Stanza{current_stanza_revision_id: stanza_revision_id, id: stanza_id},
    %{"deploy_to_deploy_targets" => deploy_targets, "user_id" => user_id} # rename param to deploy_targets/deploy_target_ids only?
  ) when is_list(deploy_targets) and length(deploy_targets) > 0 do # only allow one deploy target??
    Enum.each(deploy_targets, fn deploy_target_id ->
      attrs = %{
        "user_id" => user_id,
        "deploy_target_id" => deploy_target_id,
        "stanza_revision_changes" => [
          %{"id" => stanza_revision_id, "stanza_id" => stanza_id}
        ]
      }
      case Deployments.create_deployment(attrs) do
        {:ok, deployment} -> Deployments.deploy(deployment)
        {:error, %Changeset{} = changeset} ->
          errors = IO.inspect(changeset.errors)
          Logger.error(
            "Failed to deploy stanza revision #{stanza_revision_id}, changeset errors: #{errors}"
          )
        {:error, error} ->
          Logger.error(
            "Failed to deploy stanza revision #{stanza_revision_id}, error: #{error}"
          )
      end
    end)

  end
  def maybe_deploy_stanza(_stanza, _attrs) do
    IO.inspect("WTF")
    :ok
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
  # Overload with non list argument?
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
      preload: [current_deployments: ^Deployments.base_query(), user: s_r_u, stanza: {s, user: s_u}],
      select_merge: %{is_current_revision: fragment("? = ?", s_r.id, s.current_stanza_revision_id)}
  end

  #defp stanza_revision_list_query(%{"stanza_id" => stanza_id}) do
  defp stanza_revision_list_query(%{} = params) do
    stanza_revision_base_query()
    |> process_stanza_revision_list_query(params)
    |> order_by(^stanza_revision_dynamic_order_by(params["order_by"]))
    |> where(^stanza_revision_dynamic_where(params))
  end

  def list_stanza_revisions(%{} = params) do
    Repo.all stanza_revision_list_query(params)
  end

  def paginate_stanza_revisions(%{"page" => page, "size" => size} = params) do
    paginate_entries(stanza_revision_list_query(params), params)
  end

  defp process_stanza_revision_list_query(query, %{} = params) do
    Enum.reduce(params, query, fn
      {"deployment_id", deployment_id}, query ->
        from s in query,
          join: s_c_c in assoc(s, :deployments),
          where: s_c_c.id == ^deployment_id
      {"deployment_id_not_equal", deployment_id}, query ->
        stanza_ids_in_deployment = from sr in StanzaRevision,
          join: d_sr in "deployment_stanza_revision",
          on: sr.id == d_sr.stanza_revision_id,
          where: d_sr.deployment_id == ^deployment_id,
          select: %{
            stanza_id: sr.stanza_id
          }
        from sr in query,
          where: sr.stanza_id not in subquery(stanza_ids_in_deployment)
      _, query ->
        query
    end)
  end


  defp stanza_revision_dynamic_where(params) do
    Enum.reduce(params, dynamic(true), fn
      {"name", value}, dynamic ->
        dynamic([stanza: s], ^dynamic and s.name == ^value)
      {"name_like", value}, dynamic ->
        dynamic([stanza: s], ^dynamic and ilike(s.name, ^"%#{filter_like(value)}%"))
      {"body", value}, dynamic ->
        dynamic([s_r], ^dynamic and s_r.body == ^value)
      {"user_name", value}, dynamic ->
        dynamic([user: u], ^dynamic and u.name == ^value)
      {"user_name_like", value}, dynamic ->
        dynamic([user: u], ^dynamic and ilike(u.name, ^"%#{filter_like(value)}%"))
      {"id_not_in", value}, dynamic ->
        dynamic([s_r], ^dynamic and s_r.id not in ^String.split(value, ","))
      {"stanza_id_not_in", value}, dynamic ->
        dynamic([s_r], ^dynamic and s_r.stanza_id not in ^String.split(value, ","))
      {"stanza_id", value}, dynamic ->
        dynamic([s_r], ^dynamic and s_r.stanza_id == ^value)
      {"is_current_revision", true}, dynamic ->
        dynamic([s_r, s], ^dynamic and s_r.id == s.current_stanza_revision_id)
      {"is_current_revision", false}, dynamic ->
        dynamic([s_r, s], ^dynamic and s_r.id != s.current_stanza_revision_id)
      {"disabled", value}, dynamic ->
        dynamic([stanza: s], ^dynamic and s.disabled == ^value)
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

  def stanza_revisions_to_string(stanza_revisions) do
    # TODO: Better separator between stanzas etc
    Enum.map_join(stanza_revisions, "\n\n", fn stanza_revision ->
        # TODO: Edited by user, date comment?
        stanza_revision.body
    end)
  end

end
