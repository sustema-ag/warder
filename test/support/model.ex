defmodule Warder.Model do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  alias Warder.Multirange
  alias Warder.Range

  @type t :: %{
          range: Range.t(integer()),
          multirange: Multirange.t(integer())
        }

  schema "models" do
    field :range, Range, db_type: :int8range, inner_type: :integer
    field :multirange, Multirange, db_type: :int8multirange, inner_type: :integer
  end

  @doc false
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(model, params \\ %{}),
    do: model |> cast(params, [:range, :multirange]) |> validate_required([:range, :multirange])
end
