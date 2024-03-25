defprotocol Warder.Element do
  @moduledoc """
  Protocol for Element Implementations.

  Any data type that can be used as an element in a range must implement this
  protocol.

  ## Discrete Ranges

  Discrete ranges are ranges where the elements are not continuous. For example,
  a range of integers from 1 to 10 is a discrete range. There is no elements
  between 1 and 2, 2 and 3, and so on. The elements are separated by a step of
  1.

  In discrete ranges, the `consecutive?/2` function must return `true` if the
  two elements are consecutive. For example, in a range of integers, 1 and 2 are
  consecutive, but 1 and 3 are not.

  The `canonicalize/1` function must return the next element in the range. For
  example, if the range is from 1 to 10, and the element is 1, the
  `canonicalize/1` function must return 2.

  Indiscrete ranges are ranges where the elements are continuous. For example, a
  range of floats from 1.0 to 10.0 is an indiscrete range. There are infinite
  elements between 1.0 and 2.0, 2.0 and 3.0, and so on.

  In indiscrete ranges, the `consecutive?/2` function must return `false` for
  any two elements. The `canonicalize/1` function must return `:error`.

  ## Example

      defimpl Warder.Element, for: Date do
        def compare(left, right), do: Date.compare(left, right)

        def consecutive?(left, right), do: Date.diff(left, right) == 1

        def canonicalize(value), do: {:ok, Date.add(value, 1)}
      end

  ## Implementations

  The protocol is defined for the following types:

  * `Float`
  * `Integer`
  * `DateTime`
  * `NaiveDateTime`
  * `Time`
  * `Decimal`

  """

  @type t() :: term()

  @doc """
  Compare two elements.

  Returns `:lt` if the left element is less than the right element, `:eq` if
  they are equal, and `:gt` if the left element is greater than the right
  element.
  """
  @spec compare(left :: element, right :: element) :: :lt | :eq | :gt when element: t()
  def compare(left, right)

  @doc """
  Are those two elements consecutive?

  That means that no other elements can be between left and right.

  Always returns `false` for indiscrete ranges.
  """
  @spec consecutive?(left :: element, right :: element) :: boolean() when element: t()
  def consecutive?(left, right)

  @doc """
  Canonicalize value a step up.

  Always returns `:error` for indiscrete ranges.
  """
  @spec canonicalize(value :: element) :: {:ok, element} | :error when element: t()
  def canonicalize(value)
end

defimpl Warder.Element, for: Float do
  def compare(element, element), do: :eq
  def compare(left, right) when left > right, do: :gt
  def compare(left, right) when left < right, do: :lt

  def consecutive?(_left, _right), do: false

  def canonicalize(_value), do: :error
end

defimpl Warder.Element, for: Integer do
  def compare(element, element), do: :eq
  def compare(left, right) when left > right, do: :gt
  def compare(left, right) when left < right, do: :lt

  def consecutive?(left, right), do: abs(left - right) == 1

  def canonicalize(value), do: {:ok, value + 1}
end

for type <- [DateTime, NaiveDateTime, Time, Decimal],
    Code.ensure_loaded?(type) do
  defimpl Warder.Element, for: type do
    def compare(left, right), do: unquote(type).compare(left, right)

    def consecutive?(_left, _right), do: false

    def canonicalize(_value), do: :error
  end
end

defimpl Warder.Element, for: Date do
  def compare(left, right), do: Date.compare(left, right)

  def consecutive?(left, right), do: Date.diff(left, right) == 1

  def canonicalize(value), do: {:ok, Date.add(value, 1)}
end
