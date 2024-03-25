import Config

if config_env() == :test do
  config :warder, ecto_repos: [Warder.Repo]

  config :warder, Warder.Repo,
    pool_size: 10,
    pool: Ecto.Adapters.SQL.Sandbox

  config :logger, level: :warning
end
