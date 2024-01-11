defmodule Ezstanza.EntityValidations do
#  defmacro not_stale(entity, revision_prop, revision_value) do
#    quote do
#      case unquote(entity) do
#        %{unquote(revision_prop) => ^unquote(revision_value)} ->
#          :ok
#        _ ->
#          {:error, :stale}
#      end
#    end
#  end
  def not_stale(entity, revision_prop, revision_value) do
    if Map.get(entity, revision_prop) === revision_value do
      :ok
    else
      {:error, :stale}
    end
  end

  def found(nil), do: {:error, :not_found}
  def found(_entity), do: :ok
end
