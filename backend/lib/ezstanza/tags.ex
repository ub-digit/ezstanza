defmodule Ezstanza.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias Ezstanza.Repo

  import Ezstanza.Pagination

  alias Ezstanza.Tags.Tag


  def base_query() do
    from t in Tag,
      join: u in assoc(t, :user), as: :user,
      preload: [user: u]
  end

  defp list_query(%{} = params) do
    base_query()
    |> order_by(^dynamic_order_by(params["order_by"]))
    |> where(^dynamic_where(params))
  end

  defp dynamic_order_by("name"), do: [asc: dynamic([t], t.name)]
  defp dynamic_order_by("name_desc"), do: [desc: dynamic([t], t.name)]
  defp dynamic_order_by("user_name"), do: [asc: dynamic([user: u], u.name)]
  defp dynamic_order_by("user_name_desc"), do: [desc: dynamic([user: u], u.name)]
  defp dynamic_order_by("inserted_at"), do: [asc: dynamic([t], t.inserted_at)]
  defp dynamic_order_by("inserted_at_desc"), do: [desc: dynamic([t], t.inserted_at)]
  defp dynamic_order_by("updated_at"), do: [asc: dynamic([t], t.updated_at)]
  defp dynamic_order_by("updated_at_desc"), do: [desc: dynamic([t], t.updated_at)]

  defp dynamic_order_by(_), do: []

  defp dynamic_where(params) do
    filter_like = &(String.replace(&1, ~r"[%_]", ""))
    Enum.reduce(params, dynamic(true), fn
      {"name", value}, dynamic ->
        dynamic([t], ^dynamic and t.name == ^value)
      {"name_like", value}, dynamic ->
        dynamic([t], ^dynamic and ilike(t.name, ^"%#{filter_like.(value)}%"))
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

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tag()
      [%Tag{}, ...]

  """
  def list_tags(params \\ %{}) do
    Repo.all list_query(params)
  end

  # Default order by
  defp tags_order_by(query, nil) do
    tags_order_by(query, "name")
  end

  defp tags_order_by(query, order_by) do
    case order_by do
      "name" ->
        order_by(query, [t], asc: t.name)
      "user_name" ->
        order_by(query, [user: u], asc: u.name)
      _ ->
        query
    end
  end

  # TODO: Generalize, macro?
  def paginate_tags(%{"page" => page, "size" => size} = params) do
    IO.inspect(params, label: "params")
    list_query(params)
    |> paginate_entries(params)
  end

  @doc """
  Gets a single tag.

  Returns nil if the tag does not exist.

  ## Examples

      iex> get_tag(123)
      %Stanza{}

      iex> get_tag(456)
      ** nil

  """
  def get_tag(id) do
    Repo.one(from t in base_query(), where: t.id == ^id)
  end

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end
end
