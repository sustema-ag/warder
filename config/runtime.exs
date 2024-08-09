import Config

if config_env() == :test do
  max_runs =
    case System.fetch_env("CI") do
      :error -> 100
      {:ok, _} -> 1_000
    end

  config :stream_data, max_runs: max_runs

  config :warder, Warder.Repo,
    port: System.get_env("DATABASE_PORT", "5432"),
    username: System.get_env("DATABASE_USER", "warder"),
    password: System.get_env("DATABASE_PASSWORD", ""),
    database: System.get_env("DATABASE_NAME", "warder_#{config_env()}"),
    hostname: System.get_env("DATABASE_HOST", "localhost")
end
