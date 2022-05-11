defmodule Ezstanza.Repo do
  use Ecto.Repo,
    otp_app: :ezstanza,
    adapter: Ecto.Adapters.Postgres
end
