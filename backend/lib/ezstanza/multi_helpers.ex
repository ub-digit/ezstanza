defmodule Ezstanza.MultiHelpers do
  alias Ecto.Changeset

  defmacro __using__(multi_key) do
    quote do
      # TODO: do:
      defp handle_entity_multi_transaction_result(
        {:ok, %{unquote(multi_key) => entity}},
        _fallback_error
      ) do
        {:ok, entity}
      end

      defp handle_entity_multi_transaction_result(
        {:error, failed_operation, failed_value, changes_so_far},
        fallback_error
      ) do
        IO.puts("Multi error")
        IO.inspect([failed_operation, failed_value, changes_so_far])
        # TODO: this can probably be improved, or might not be such a good idea?
        case failed_value do
          %Changeset{valid?: false} -> {:error, failed_value}
          _ -> {:error, fallback_error}
        end
      end
    end
  end
end
