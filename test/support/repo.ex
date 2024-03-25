defmodule Warder.Repo do
  use Ecto.Repo,
    otp_app: :warder,
    adapter: Ecto.Adapters.Postgres
end
