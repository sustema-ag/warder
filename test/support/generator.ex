defmodule Warder.Generator do
  @moduledoc """
  `StreamData` Generator for ranges
  """

  use ExUnitProperties

  alias Warder.Element
  alias Warder.Multirange
  alias Warder.Range

  @type subtype_generator(subtype) :: (:unbound | subtype -> StreamData.t(subtype))

  @spec multirange(inner :: subtype_generator(subtype)) :: StreamData.t(Multirange.t(subtype)) when subtype: Element.t()
  def multirange(inner) do
    gen all ranges <- list_of(range(inner)) do
      Multirange.new(ranges)
    end
  end

  @spec range(inner :: subtype_generator(subtype)) :: StreamData.t(Range.t(subtype)) when subtype: Element.t()
  def range(inner), do: one_of([empty(), specified(inner)])

  @spec empty() :: StreamData.t(Range.empty())
  def empty, do: constant(Range.empty())

  @spec specified(inner :: subtype_generator(subtype)) :: StreamData.t(Range.specified(subtype)) when subtype: Element.t()
  def specified(inner) do
    gen all lower <- one_of([constant(:unbound), inner.(:unbound)]),
            lower_inclusive <- boolean(),
            upper <- one_of([constant(:unbound), inner.(lower)]),
            upper_inclusive <- boolean() do
      Range.new!(lower, upper,
        lower_inclusive: lower_inclusive,
        upper_inclusive: upper_inclusive
      )
    end
  end

  @spec decimal(opts :: [min: Decimal.t(), max: Decimal.t()]) :: StreamData.t(Decimal.t())
  def decimal(opts) do
    opts =
      opts
      |> Keyword.update!(:min, &Decimal.to_float/1)
      |> Keyword.update!(:max, &Decimal.to_float/1)

    gen all float <- float(opts) do
      Decimal.from_float(float)
    end
  end
end
