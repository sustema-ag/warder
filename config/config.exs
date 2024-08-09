import Config

if config_env() == :test do
  config :logger, level: :warning

  config :warder, Warder.Repo,
    pool_size: 10,
    pool: Ecto.Adapters.SQL.Sandbox

  config :warder, ecto_repos: [Warder.Repo]
end
