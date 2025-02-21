defmodule Warder.MixProject do
  use Mix.Project

  def project do
    [
      app: :warder,
      version: "0.1.2",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      docs: &docs/0,
      deps: deps(),
      source_url: "https://github.com/sustema-ag/warder",
      description: "Library for handling ranges. Includes Ecto Types for PostgreSQL.",
      package: package(),
      test_coverage: [tool: ExCoveralls],
      aliases: aliases(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test,
        "coveralls.multiple": :test,
        ecto: :test,
        "ecto.create": :test,
        "ecto.drop": :test,
        "ecto.dump": :test,
        "ecto.gen.migration": :test,
        "ecto.gen.repo": :test,
        "ecto.load": :test,
        "ecto.migrate": :test,
        "ecto.migrations": :test,
        "ecto.rollback": :test,
        "ecto.setup": :test
      ]
    ]
  end

  defp elixirc_paths(env)
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Jonatan Männchen"],
      files: [
        "lib",
        "LICENSE*",
        "mix.exs",
        "README*"
      ],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/sustema-ag/warder"}
    ]
  end

  defp docs do
    {ref, 0} = System.cmd("git", ["rev-parse", "--verify", "--quiet", "HEAD"])

    [
      source_ref: ref,
      main: "readme",
      extras: ["README.md"],
      logo: "assets/logo-optim.png",
      assets: "assets"
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:decimal, "~> 2.1", optional: true},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:ecto, "~> 3.11", optional: true},
      {:ecto_sql, "~> 3.11", optional: true},
      {:excoveralls, "~> 0.18", only: :test},
      {:ex_doc, "~> 0.37.0", only: :dev, runtime: false},
      {:postgrex, "~> 0.20.0", optional: true},
      {:stream_data, "~> 1.1.0", only: [:dev, :test]},
      {:styler, "~> 1.4.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
