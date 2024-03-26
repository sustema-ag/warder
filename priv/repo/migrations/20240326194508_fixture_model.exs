defmodule Warder.Repo.Migrations.FixtureModel do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:models) do
      add :range, :int8range
      add :multirange, :int8multirange
    end
  end
end
