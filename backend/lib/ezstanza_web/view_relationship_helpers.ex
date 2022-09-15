defmodule EzstanzaWeb.ViewRelationshipHelpers do
  import Phoenix.View, only: [render_one: 4, render_many: 4]

  def maybe_render_relationship(struct, relationship, view, template, assigns \\ %{}) do
    case Map.get(struct, relationship) do
      %Ecto.Association.NotLoaded{} ->
        %{}
      data ->
        %{relationship => render_relationship(data, view, template, assigns)}
    end
  end

  def render_relationship(relations, view, template, assigns) when is_list(relations) do
    render_many(relations, view, template, assigns)
  end
  def render_relationship(relation, view, template, assigns) do
    render_one(relation, view, template, assigns)
  end
end

