# Used by "mix format"
[
  plugins: [Styler],
  import_deps: [:ecto, :ecto_sql, :stream_data],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}", "priv/repo/migrations/*.exs"]
]
