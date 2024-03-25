Warder.Repo.start_link()

ExUnit.start(capture_log: true)

Ecto.Adapters.SQL.Sandbox.mode(Warder.Repo, :manual)
