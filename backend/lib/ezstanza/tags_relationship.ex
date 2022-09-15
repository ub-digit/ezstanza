defmodule Ezstanza.TagsRelationship do
  alias Ezstanza.Tags.Tag
  import Ecto.Query, warn: false

  def find_or_create_tags(_repo, nil), do: {:ok, []}
  def find_or_create_tags(_repo, []), do: {:ok, []}
  def find_or_create_tags(_repo, tags) when not is_list(tags) do
    {:error, :tags_is_not_a_list}
  end

  def find_or_create_tags(repo, tags) do
    with {:ok, {tag_ids, tag_names}} = attr_tags_split_ids_names(tags) do
      #query = from t in Tag, where: t.id in ^tag_ids
      #tags = repo.all(query)
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
end
