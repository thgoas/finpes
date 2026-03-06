defmodule Finpes.Repo do
  use Ecto.Repo,
    otp_app: :finpes,
    adapter: Ecto.Adapters.Postgres
end
