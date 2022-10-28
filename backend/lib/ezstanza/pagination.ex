defmodule Ezstanza.Pagination do
  import Ecto.Query, warn: false
  alias Ezstanza.Repo

  def paginate_entries(query, %{"page" => page, "size" => size} = params) do
    {page, _} = Integer.parse(page)
    {size, _} = Integer.parse(size)
    extra = Map.get(params, "extra", "0")
    {extra, _} = Integer.parse(extra)

    offset = (page - 1) * size
    limit = size + extra

    query = query
            |> offset(^offset)
            |> limit(^limit)

    count_query = query
                  |> exclude(:select)
                  |> exclude(:preload)
                  |> exclude(:order_by)
                  |> exclude(:limit)
                  |> exclude(:offset)

    count = Repo.one(from t in count_query, select: count("*"))
    entries = Repo.all query
    %{
      pages: div(count, size) + 1,
      total: count,
      entries: entries
    }
  end
end
