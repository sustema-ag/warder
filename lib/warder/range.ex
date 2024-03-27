defmodule Warder.Range do
  @moduledoc """
  Range Implementation

  > #### Creation / Manipulation {: .warning}
  >
  > Ranges should not be created or modified manually. Use `new/3`, `new!/3` or
  > `empty/0` to create ranges.

  ## Ecto Type

  If `ecto` and `postgrex` are installed, you can use the `Warder.Range` type:

  ```elixir
  defmodule Model do
    use Ecto.Schema

    alias Warder.Range

    @type t :: %{range: Range.t(integer())}

    schema "models" do
      field :range, Range,
        db_type: :int8range,
        inner_type: :integer
    end
  end
  ```

  ### Options

  * `db_type` - The database type to use for the range column. For example
    `:int8range`.
  * `inner_type` - The ecto type of the elements in the range. For example
    `:integer`.

  """
  @moduledoc since: "0.1.0"

  alias Warder.Element

  @enforce_keys [:lower, :upper]
  defstruct [:lower, :upper, lower_inclusive: true, upper_inclusive: false]

  @typedoc """
  A range of any `subtype`.
  """
  @typedoc since: "0.1.0"
  @type t() :: t(term())

  @typedoc """
  A specified or empty range with the bound type of `subtype`.
  """
  @typedoc since: "0.1.0"
  @type t(subtype) :: specified(subtype) | empty()

  @typedoc """
  Range with specified bounds.

  ## Fields

  * `lower` - The lower bound of the range.
  * `upper` - The upper bound of the range.
  * `lower_inclusive` - Whether the lower bound is inclusive.
  * `upper_inclusive` - Whether the upper bound is inclusive.

  """
  @typedoc since: "0.1.0"
  @type specified(subtype) ::
          %__MODULE__{
            lower: subtype | :unbound,
            lower_inclusive: boolean(),
            upper: subtype | :unbound,
            upper_inclusive: boolean()
          }

  @typedoc """
  An empty range is one that does not contain any values between the lower and
  upper bounds.
  """
  @typedoc since: "0.1.0"
  @type empty() :: %__MODULE__{
          lower: :empty,
          lower_inclusive: nil,
          upper: :empty,
          upper_inclusive: nil
        }

  @typep bound(subtype) :: {:unbound | subtype, boolean(), boolean()}

  defmodule BoundOrderError do
    @moduledoc "Error when the range bounds are not in ascending order."
    @moduledoc since: "0.1.0"

    @type t() :: t(term())
    @type t(subtype) :: %__MODULE__{lower: subtype, upper: subtype}

    defexception [:lower, :upper]

    @doc false
    @impl Exception
    def message(%__MODULE__{lower: lower, upper: upper}),
      do: "The range lower bound (#{inspect(lower)}) must be less than or equal to range upper bound (#{inspect(upper)})."
  end

  defmodule NotContiguousError do
    @moduledoc "Error when the ranges are not contiguous."
    @moduledoc since: "0.1.0"

    alias Warder.Range

    @type t() :: t(term())
    @type t(subtype) :: %__MODULE__{first: Range.t(subtype), second: Range.t(subtype)}

    defexception [:first, :second]

    @doc false
    @impl Exception
    def message(%__MODULE__{first: first, second: second}),
      do: """
      The first range and second range are not contiguous.
      First: #{inspect(first)}
      Second: #{inspect(second)}\
      """
  end

  defmodule DisjointRangesError do
    @moduledoc "Error when the result of range difference would not be contiguous."
    @moduledoc since: "0.1.0"

    alias Warder.Range

    defexception [:lower, :upper]

    @type t() :: t(term())
    @type t(subtype) :: %__MODULE__{lower: Range.t(subtype), upper: Range.t(subtype)}

    @doc false
    @impl Exception
    def message(%__MODULE__{lower: lower, upper: upper}),
      do: """
      The result of range difference would not be contiguous.
      Before difference: #{inspect(lower)}
      After difference: #{inspect(upper)}\
      """
  end

  @doc """
  Create a new range for the given bounds.

  The lower bound must be less than or equal to the upper bound.

  If the bounds are equal, that is, there are no values between the lower and
  upper bound, the resulting range is empty.

  > #### Canonicalization {: .warning}
  >
  > Ranges are canonicalized on creation. Therefore the bounds & inclusion might
  > shift to ensure the range is in a consistent state while keeping the same
  > meaning.

  ## Options

  * `:lower_inclusive` - Whether the lower bound is inclusive. Defaults to `true`.
  * `:upper_inclusive` - Whether the upper bound is inclusive. Defaults to `false`.

  ## Examples

      iex> Warder.Range.new(1, 10)
      {:ok, %Warder.Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false}}

      iex> Warder.Range.new(:unbound, 10)
      {:ok, %Warder.Range{lower: :unbound, upper: 10, lower_inclusive: true, upper_inclusive: false}}

      iex> Warder.Range.new(1, 1, upper_inclusive: false)
      {:ok, %Warder.Range{lower: :empty, upper: :empty, lower_inclusive: nil, upper_inclusive: nil}}

      iex> Warder.Range.new(10, 1)
      {:error, %Warder.Range.BoundOrderError{lower: 10, upper: 1}}

  """
  @doc since: "0.1.0"
  @spec new(
          lower :: subtype | :unbound,
          upper :: subtype | :unbound,
          options :: [lower_inclusive: boolean(), upper_inclusive: boolean()]
        ) :: {:ok, t(subtype)} | {:error, BoundOrderError.t()}
        when subtype: Element.t()
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def new(lower, upper, options \\ []) do
    options = Keyword.validate!(options, lower_inclusive: true, upper_inclusive: false)

    consecutive? =
      case {lower, upper} do
        {:unbound, _upper} -> false
        {_lower, :unbound} -> false
        {lower, upper} -> Element.consecutive?(lower, upper)
      end

    range = %__MODULE__{
      lower: lower,
      upper: upper,
      lower_inclusive: options[:lower_inclusive],
      upper_inclusive: options[:upper_inclusive]
    }

    {lower_bound, upper_bound} = bounds(range)

    bound_comparison = compare_bounds(lower_bound, upper_bound)

    cond do
      bound_comparison == :gt and lower == upper ->
        {:ok, empty()}

      bound_comparison == :gt ->
        {:error, %BoundOrderError{lower: lower, upper: upper}}

      bound_comparison == :eq and options[:lower_inclusive] and options[:upper_inclusive] ->
        {:ok, canonicalize(range)}

      (consecutive? and options[:lower_inclusive]) or options[:upper_inclusive] ->
        {:ok, canonicalize(range)}

      consecutive? ->
        {:ok, empty()}

      true ->
        {:ok, canonicalize(range)}
    end
  end

  @doc """
  Create a new range for the given bounds.

  See `new/3` for details.

  ## Examples

      iex> Warder.Range.new!(1, 10)
      %Warder.Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false}

      iex> Warder.Range.new!(10, 1)
      ** (Warder.Range.BoundOrderError) The range lower bound (10) must be less than or equal to range upper bound (1).

  """
  @doc since: "0.1.0"
  @spec new!(
          lower :: subtype,
          upper :: subtype,
          options :: [lower_inclusive: boolean(), upper_inclusive: boolean()]
        ) :: t(subtype)
        when subtype: Element.t()
  def new!(lower, upper, options \\ []) do
    case new(lower, upper, options) do
      {:ok, range} -> range
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Create a new empty range.

  ## Examples

      iex> Warder.Range.empty()
      %Warder.Range{lower: :empty, lower_inclusive: nil, upper: :empty, upper_inclusive: nil}

  """
  @doc since: "0.1.0"
  @spec empty() :: empty()
  def empty, do: %__MODULE__{lower: :empty, lower_inclusive: nil, upper: :empty, upper_inclusive: nil}

  @doc """
  Guard to detect empty ranges.
  """
  @doc since: "0.1.0"
  defguard is_empty(range) when range.__struct__ == __MODULE__ and range.lower == :empty

  @doc """
  Does `first` contain `second`?

  Both `first` and `second` can either be a range or an element.

  ## Examples

      iex> Warder.Range.contains?(Warder.Range.new!(1, 10), Warder.Range.new!(5, 10))
      true

      iex> Warder.Range.contains?(Warder.Range.new!(1, 10), Warder.Range.new!(15, 20))
      false

      iex> Warder.Range.contains?(Warder.Range.new!(1, 10), 5)
      true

      iex> Warder.Range.contains?(Warder.Range.new!(1, 10), 20)
      false

  """
  @doc since: "0.1.0"
  @spec contains?(first :: t(subtype) | subtype, second :: t(subtype) | subtype) :: boolean()
        when subtype: Element.t()
  def contains?(first, second)
  def contains?(%__MODULE__{} = first, %__MODULE__{} = second), do: _contains?(first, second)

  def contains?(%__MODULE__{} = first, second),
    do: contains?(first, new!(second, second, lower_inclusive: true, upper_inclusive: true))

  def contains?(first, %__MODULE__{} = second),
    do: contains?(new!(first, first, lower_inclusive: true, upper_inclusive: true), second)

  @spec _contains?(first :: t(subtype), second :: t(subtype)) :: boolean()
        when subtype: Element.t()
  defp _contains?(first, second)
  defp _contains?(_first, second) when is_empty(second), do: true
  defp _contains?(first, _second) when is_empty(first), do: false

  defp _contains?(first, second) do
    {first_lower_bound, first_upper_bound} =
      bounds(canonicalize(first))

    {second_lower_bound, second_upper_bound} =
      bounds(canonicalize(second))

    compare_bounds(first_lower_bound, second_lower_bound) in [:lt, :eq] and
      compare_bounds(first_upper_bound, second_upper_bound) in [:gt, :eq]
  end

  @doc """
  Does the first range overlap with the second range, that is, have any elements
  in common?

  ## Examples

      iex> Warder.Range.overlap?(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      true

      iex> Warder.Range.overlap?(Warder.Range.new!(1, 10), Warder.Range.new!(15, 20))
      false

  """
  @doc since: "0.1.0"
  @spec overlap?(first :: t(subtype), second :: t(subtype)) :: boolean()
        when subtype: Element.t()
  def overlap?(first, second)
  def overlap?(first, second) when is_empty(first) or is_empty(second), do: false

  def overlap?(first, second) do
    {first_lower_bound, first_upper_bound} =
      bounds(canonicalize(first))

    {second_lower_bound, second_upper_bound} =
      bounds(canonicalize(second))

    compare_bounds(first_lower_bound, second_upper_bound) in [:lt, :eq] and
      compare_bounds(first_upper_bound, second_lower_bound) in [:gt, :eq]
  end

  @doc """
  Is the first range strictly left of the second?

  ## Examples

      iex> Warder.Range.left?(Warder.Range.new!(1, 10), Warder.Range.new!(11, 20))
      true

      iex> Warder.Range.left?(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      false

  """
  @doc since: "0.1.0"
  @spec left?(first :: t(subtype), second :: t(subtype)) :: boolean()
        when subtype: Element.t()
  def left?(first, second)
  def left?(first, second) when is_empty(first) or is_empty(second), do: false

  def left?(first, second) do
    {_first_lower_bound, first_upper_bound} =
      bounds(canonicalize(first))

    {second_lower_bound, _second_upper_bound} =
      bounds(canonicalize(second))

    compare_bounds(first_upper_bound, second_lower_bound) == :lt
  end

  @doc """
  Is the first range strictly right of the second?

  ## Examples

      iex> Warder.Range.right?(Warder.Range.new!(11, 20), Warder.Range.new!(1, 10))
      true

      iex> Warder.Range.right?(Warder.Range.new!(5, 15), Warder.Range.new!(1, 10))
      false

  """
  @doc since: "0.1.0"
  @spec right?(first :: t(subtype), second :: t(subtype)) :: boolean()
        when subtype: Element.t()
  def right?(first, second), do: left?(second, first)

  @doc """
  Does the first range not extend to the right of the second?

  ## Examples

      iex> Warder.Range.no_extend_right?(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      true

      iex> Warder.Range.no_extend_right?(Warder.Range.new!(1, 15), Warder.Range.new!(5, 10))
      false

  """
  @doc since: "0.1.0"
  @spec no_extend_right?(first :: t(subtype), second :: t(subtype)) :: boolean()
        when subtype: Element.t()
  def no_extend_right?(first, second)
  def no_extend_right?(first, second) when is_empty(first) or is_empty(second), do: false

  def no_extend_right?(first, second) do
    {_first_lower_bound, first_upper_bound} =
      bounds(canonicalize(first))

    {_second_lower_bound, second_upper_bound} =
      bounds(canonicalize(second))

    compare_bounds(first_upper_bound, second_upper_bound) in [:lt, :eq]
  end

  @doc """
  Does the first range not extend to the left of the second?

  ## Examples

      iex> Warder.Range.no_extend_left?(Warder.Range.new!(5, 15), Warder.Range.new!(1, 10))
      true

      iex> Warder.Range.no_extend_left?(Warder.Range.new!(1, 10), Warder.Range.new!(5, 10))
      false

  """
  @doc since: "0.1.0"
  @spec no_extend_left?(first :: t(subtype), second :: t(subtype)) :: boolean()
        when subtype: Element.t()
  def no_extend_left?(first, second)
  def no_extend_left?(first, second) when is_empty(first) or is_empty(second), do: false

  def no_extend_left?(first, second) do
    {first_lower_bound, _first_upper_bound} =
      bounds(canonicalize(first))

    {second_lower_bound, _second_upper_bound} =
      bounds(canonicalize(second))

    compare_bounds(first_lower_bound, second_lower_bound) in [:gt, :eq]
  end

  @doc """
  Are the ranges adjacent?

  ## Examples

      iex> Warder.Range.adjacent?(Warder.Range.new!(1, 10), Warder.Range.new!(10, 20))
      true

      iex> Warder.Range.adjacent?(Warder.Range.new!(1, 10), Warder.Range.new!(15, 20))
      false

  """
  @doc since: "0.1.0"
  @spec adjacent?(first :: t(subtype), second :: t(subtype)) :: boolean()
        when subtype: Element.t()
  def adjacent?(first, second)
  def adjacent?(first, second) when is_empty(first) or is_empty(second), do: false

  def adjacent?(first, second) do
    {first_lower_bound, first_upper_bound} =
      bounds(canonicalize(first))

    {second_lower_bound, second_upper_bound} =
      bounds(canonicalize(second))

    adjacent_bounds(first_upper_bound, second_lower_bound) or
      adjacent_bounds(second_upper_bound, first_lower_bound)
  end

  @spec adjacent_bounds(first_upper :: bound(subtype), second_lower :: bound(subtype)) ::
          boolean()
        when subtype: Element.t()
  defp adjacent_bounds(first_upper, second_lower)
  defp adjacent_bounds({:unbound, _inclusive, _lower}, _second_lower), do: false
  defp adjacent_bounds(_first_upper, {:unbound, _inclusive, _lower}), do: false
  defp adjacent_bounds({value, false, false}, {value, true, true}), do: true
  defp adjacent_bounds({value, true, false}, {value, false, true}), do: true

  defp adjacent_bounds({_value_upper, _first_inclusive, false}, {_value_lower, _second_inclusive, true}), do: false

  @doc """
  Computes the union of the ranges.

  The ranges must overlap or be adjacent, so that the union is a single range.

  ## Examples

      iex> Warder.Range.union(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      {:ok, %Warder.Range{lower: 1, upper: 15, lower_inclusive: true, upper_inclusive: false}}

      iex> Warder.Range.union(Warder.Range.new!(1, 10), Warder.Range.new!(15, 20))
      {:error, %Warder.Range.NotContiguousError{
        first: %Warder.Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false},
        second: %Warder.Range{lower: 15, upper: 20, lower_inclusive: true, upper_inclusive: false}
      }}

  """
  @doc since: "0.1.0"
  @spec union(first :: t(subtype), second :: t(subtype)) ::
          {:ok, t(subtype)} | {:error, NotContiguousError.t()}
        when subtype: Element.t()
  def union(first, second)
  def union(first, second) when is_empty(first) and is_empty(second), do: {:ok, empty()}
  def union(first, second) when is_empty(first), do: {:ok, second}
  def union(first, second) when is_empty(second), do: {:ok, first}

  def union(first, second) do
    if overlap?(first, second) or adjacent?(first, second) do
      {first_lower_bound, first_upper_bound} =
        bounds(canonicalize(first))

      {second_lower_bound, second_upper_bound} =
        bounds(canonicalize(second))

      {lower, lower_inclusive, true} =
        case compare_bounds(first_lower_bound, second_lower_bound) do
          :lt -> first_lower_bound
          :eq -> first_lower_bound
          :gt -> second_lower_bound
        end

      {upper, upper_inclusive, false} =
        case compare_bounds(first_upper_bound, second_upper_bound) do
          :lt -> second_upper_bound
          :eq -> first_upper_bound
          :gt -> first_upper_bound
        end

      new(lower, upper, lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive)
    else
      {:error, %NotContiguousError{first: first, second: second}}
    end
  end

  @doc """
  Computes the union of the ranges.

  See `union/2`.

  ## Examples

      iex> Warder.Range.union!(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      %Warder.Range{lower: 1, upper: 15, lower_inclusive: true, upper_inclusive: false}

      iex> Warder.Range.union!(Warder.Range.new!(1, 10), Warder.Range.new!(15, 20))
      ** (Warder.Range.NotContiguousError) The first range and second range are not contiguous.
      First: %Warder.Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false}
      Second: %Warder.Range{lower: 15, upper: 20, lower_inclusive: true, upper_inclusive: false}

  """
  @doc since: "0.1.0"
  @spec union!(first :: t(subtype), second :: t(subtype)) :: t(subtype)
        when subtype: Element.t()
  def union!(first, second) do
    case union(first, second) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Computes the intersection of the ranges.

  ## Examples

      iex> Warder.Range.intersection(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      %Warder.Range{lower: 5, upper: 10, lower_inclusive: true, upper_inclusive: false}

      iex> Warder.Range.intersection(Warder.Range.new!(1, 10), Warder.Range.new!(15, 20))
      %Warder.Range{lower: :empty, upper: :empty, lower_inclusive: nil, upper_inclusive: nil}

  """
  @doc since: "0.1.0"
  @spec intersection(first :: t(subtype), second :: t(subtype)) :: t(subtype)
        when subtype: Element.t()
  def intersection(first, second)
  def intersection(first, second) when is_empty(first) or is_empty(second), do: empty()

  def intersection(first, second) do
    if overlap?(first, second) do
      {first_lower_bound, first_upper_bound} =
        bounds(canonicalize(first))

      {second_lower_bound, second_upper_bound} =
        bounds(canonicalize(second))

      {lower, lower_inclusive, true} =
        case compare_bounds(first_lower_bound, second_lower_bound) do
          :lt -> second_lower_bound
          :eq -> first_lower_bound
          :gt -> first_lower_bound
        end

      {upper, upper_inclusive, false} =
        case compare_bounds(first_upper_bound, second_upper_bound) do
          :lt -> first_upper_bound
          :eq -> first_upper_bound
          :gt -> second_upper_bound
        end

      new!(lower, upper, lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive)
    else
      empty()
    end
  end

  @doc """
  Computes the difference of the ranges.

  The second range must not be contained in the first in such a way that the
  difference would not be a single range.

  ## Examples

      iex> Warder.Range.difference(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      {:ok, %Warder.Range{lower: 1, upper: 5, lower_inclusive: true, upper_inclusive: false}}

      iex> Warder.Range.difference(Warder.Range.new!(1, 10), Warder.Range.new!(15, 20))
      {:ok, %Warder.Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false}}

      iex> Warder.Range.difference(Warder.Range.new!(1, 10), Warder.Range.new!(2, 8))
      {:error, %Warder.Range.DisjointRangesError{
        lower: %Warder.Range{lower: 1, upper: 2, lower_inclusive: true, upper_inclusive: false},
        upper: %Warder.Range{lower: 8, upper: 10, lower_inclusive: true, upper_inclusive: false}
      }}

  """
  @doc since: "0.1.0"
  @spec difference(first :: t(subtype), second :: t(subtype)) ::
          {:ok, t(subtype)} | {:error, DisjointRangesError.t()}
        when subtype: Element.t()
  def difference(first, second)
  def difference(first, second) when is_empty(first) or is_empty(second), do: {:ok, first}

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def difference(first, second) do
    {first_lower_bound, first_upper_bound} =
      bounds(canonicalize(first))

    {second_lower_bound, second_upper_bound} =
      bounds(canonicalize(second))

    cmp_l_l = compare_bounds(first_lower_bound, second_lower_bound)
    cmp_l_u = compare_bounds(first_lower_bound, second_upper_bound)
    cmp_u_l = compare_bounds(first_upper_bound, second_lower_bound)
    cmp_u_u = compare_bounds(first_upper_bound, second_upper_bound)

    cond do
      cmp_l_l == :lt and cmp_u_u == :gt ->
        {:error,
         %DisjointRangesError{
           lower:
             new!(first.lower, second.lower,
               lower_inclusive: first.lower_inclusive,
               upper_inclusive: not second.lower_inclusive
             ),
           upper:
             new!(second.upper, first.upper,
               lower_inclusive: not second.upper_inclusive,
               upper_inclusive: first.upper_inclusive
             )
         }}

      cmp_l_u == :gt or cmp_u_l == :lt ->
        {:ok, first}

      cmp_l_l in [:eq, :gt] and cmp_u_u in [:lt, :eq] ->
        {:ok, empty()}

      cmp_l_l in [:lt, :eq] and cmp_u_l in [:eq, :gt] and cmp_u_u in [:lt, :eq] ->
        new(first.lower, second.lower,
          lower_inclusive: first.lower_inclusive,
          upper_inclusive: not second.lower_inclusive
        )

      cmp_l_l in [:eq, :gt] and cmp_u_u in [:eq, :gt] and cmp_l_u in [:lt, :eq] ->
        new(second.upper, first.upper,
          lower_inclusive: not second.upper_inclusive,
          upper_inclusive: first.upper_inclusive
        )
    end
  end

  @doc """
  Computes the difference of the ranges.

  See `difference/2` for details.

  ## Examples

      iex> Warder.Range.difference!(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      %Warder.Range{lower: 1, upper: 5, lower_inclusive: true, upper_inclusive: false}

      iex> Warder.Range.difference!(Warder.Range.new!(1, 10), Warder.Range.new!(2, 8))
      ** (Warder.Range.DisjointRangesError) The result of range difference would not be contiguous.
      Before difference: %Warder.Range{lower: 1, upper: 2, lower_inclusive: true, upper_inclusive: false}
      After difference: %Warder.Range{lower: 8, upper: 10, lower_inclusive: true, upper_inclusive: false}

  """
  @doc since: "0.1.0"
  @spec difference!(first :: t(subtype), second :: t(subtype)) :: t(subtype)
        when subtype: Element.t()
  def difference!(first, second) do
    case difference(first, second) do
      {:ok, result} -> result
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Computes the smallest range that includes both of the given ranges.

  ## Examples

      iex> Warder.Range.merge(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      %Warder.Range{lower: 1, upper: 15, lower_inclusive: true, upper_inclusive: false}

      iex> Warder.Range.merge(Warder.Range.new!(1, 10), Warder.Range.new!(15, 20))
      %Warder.Range{lower: 1, upper: 20, lower_inclusive: true, upper_inclusive: false}

  """
  @doc since: "0.1.0"
  @spec merge(first :: t(subtype), second :: t(subtype)) :: t(subtype)
        when subtype: Element.t()
  def merge(first, second)
  def merge(first, second) when is_empty(first), do: second
  def merge(first, second) when is_empty(second), do: first

  def merge(first, second) do
    {first_lower_bound, first_upper_bound} =
      bounds(canonicalize(first))

    {second_lower_bound, second_upper_bound} =
      bounds(canonicalize(second))

    {lower, lower_inclusive, true} =
      case compare_bounds(first_lower_bound, second_lower_bound) do
        :lt -> first_lower_bound
        :eq -> first_lower_bound
        :gt -> second_lower_bound
      end

    {upper, upper_inclusive, false} =
      case compare_bounds(first_upper_bound, second_upper_bound) do
        :lt -> second_upper_bound
        :eq -> first_upper_bound
        :gt -> first_upper_bound
      end

    new!(lower, upper, lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive)
  end

  @doc """
  Compare ranges for ordering

  The module `Warder.Range` can be used as the `sorter` argument for
  `Enum.sort/2` and `Enum.sort_by/3`.

  ## Examples

      iex> Warder.Range.compare(Warder.Range.new!(1, 10), Warder.Range.new!(5, 15))
      :lt

      iex> Warder.Range.compare(Warder.Range.new!(1, 10), Warder.Range.new!(1, 10))
      :eq

      iex> Warder.Range.compare(Warder.Range.new!(1, 10), Warder.Range.new!(0, 5))
      :gt

  """
  @doc since: "0.1.0"
  @spec compare(first :: t(subtype), second :: t(subtype)) :: :lt | :eq | :gt
        when subtype: Element.t()
  def compare(first, second)
  def compare(first, second) when is_empty(first) and is_empty(second), do: :eq
  def compare(first, _second) when is_empty(first), do: :gt
  def compare(_first, second) when is_empty(second), do: :lt

  def compare(first, second) do
    {first_lower_bound, first_upper_bound} =
      bounds(canonicalize(first))

    {second_lower_bound, second_upper_bound} =
      bounds(canonicalize(second))

    case compare_bounds(first_lower_bound, second_lower_bound) do
      :lt ->
        :lt

      :gt ->
        :gt

      :eq ->
        case compare_bounds(first_upper_bound, second_upper_bound) do
          :lt -> :lt
          :gt -> :gt
          :eq -> :eq
        end
    end
  end

  @spec bounds(specified(subtype)) :: {bound(subtype), bound(subtype)} when subtype: Element.t()
  defp bounds(%__MODULE__{lower: lower, upper: upper, lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive}),
    do: {{lower, lower_inclusive, true}, {upper, upper_inclusive, false}}

  @spec compare_bounds(first :: bound(subtype), second :: bound(subtype)) :: :lt | :eq | :gt
        when subtype: Element.t()
  defp compare_bounds(first, second)
  defp compare_bounds({:unbound, _, is_lower}, {:unbound, _, is_lower}), do: :eq
  defp compare_bounds({:unbound, _, true}, {:unbound, _, false}), do: :lt
  defp compare_bounds({:unbound, _, false}, {:unbound, _, true}), do: :gt
  defp compare_bounds({:unbound, _, true}, _second), do: :lt
  defp compare_bounds({:unbound, _, false}, _second), do: :gt
  defp compare_bounds(_first, {:unbound, _, true}), do: :gt
  defp compare_bounds(_first, {:unbound, _, false}), do: :lt

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp compare_bounds({first_value, first_inclusive, first_is_lower}, {second_value, second_inclusive, second_is_lower}) do
    case Element.compare(first_value, second_value) do
      :lt ->
        :lt

      :gt ->
        :gt

      :eq ->
        case {first_inclusive, second_inclusive} do
          {false, false} when first_is_lower == second_is_lower -> :eq
          {false, false} when first_is_lower -> :gt
          {false, false} when not first_is_lower -> :lt
          {false, true} when first_is_lower -> :gt
          {false, true} when not first_is_lower -> :lt
          {true, false} when second_is_lower -> :lt
          {true, false} when not second_is_lower -> :gt
          {true, true} -> :eq
        end
    end
  end

  @spec canonicalize_bound(bound :: bound(subtype)) :: bound(subtype) when subtype: Element.t()
  defp canonicalize_bound({:unbound, _inclusive?, true}), do: {:unbound, true, true}
  defp canonicalize_bound({:unbound, _inclusive?, false}), do: {:unbound, false, false}
  defp canonicalize_bound({_value, true, true} = bound), do: bound
  defp canonicalize_bound({_value, false, false} = bound), do: bound

  defp canonicalize_bound({value, inclusive?, lower?} = bound) do
    case Element.canonicalize(value) do
      {:ok, value} -> {value, not inclusive?, lower?}
      :error -> bound
    end
  end

  @spec canonicalize(specified(subtype)) :: t(subtype) when subtype: Element.t()
  defp canonicalize(range) do
    {lower_bound, upper_bound} = bounds(range)
    {lower, lower_inclusive, true} = canonicalize_bound(lower_bound)
    {upper, upper_inclusive, false} = canonicalize_bound(upper_bound)

    %__MODULE__{
      lower: lower,
      upper: upper,
      lower_inclusive: lower_inclusive,
      upper_inclusive: upper_inclusive
    }
  end

  with {:module, Ecto.ParameterizedType} <- Code.ensure_loaded(Ecto.ParameterizedType),
       {:module, Postgrex.Range} <- Code.ensure_loaded(Postgrex.Range) do
    use Ecto.ParameterizedType

    @impl Ecto.ParameterizedType
    def init(opts), do: Map.new(opts)

    @doc false
    @impl Ecto.ParameterizedType
    def type(%{db_type: db_type}), do: db_type

    @doc false
    @impl Ecto.ParameterizedType
    def cast(%Postgrex.Range{lower: :empty}, _params), do: {:ok, empty()}

    def cast(
          %Postgrex.Range{lower: lower, upper: upper, lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive},
          _params
        ),
        do: new(lower, upper, lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive)

    def cast(%__MODULE__{} = range, _params), do: {:ok, range}

    def cast(%Date.Range{first: first, last: last, step: 1}, %{db_type: :daterange}),
      do: new(first, last, lower_inclusive: true, upper_inclusive: true)

    def cast(_value, _params), do: :error

    @doc false
    @impl Ecto.ParameterizedType
    def dump(nil, _dumper, _params), do: {:ok, nil}

    def dump(
          %__MODULE__{lower: lower, upper: upper, lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive},
          dumper,
          %{inner_type: inner_type}
        ) do
      with {:ok, lower} <- mutate_inner(lower, dumper, inner_type),
           {:ok, upper} <- mutate_inner(upper, dumper, inner_type) do
        {:ok,
         %Postgrex.Range{
           lower: lower,
           upper: upper,
           lower_inclusive: lower_inclusive,
           upper_inclusive: upper_inclusive
         }}
      end
    end

    def dump(_value, _dumper, _params), do: :error

    @doc false
    @impl Ecto.ParameterizedType
    def load(nil, _loader, _params), do: {:ok, nil}

    def load(%Postgrex.Range{lower: :empty}, _loader, _params), do: {:ok, empty()}

    def load(
          %Postgrex.Range{lower: lower, upper: upper, lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive},
          loader,
          %{inner_type: inner_type}
        ) do
      with {:ok, lower} <- mutate_inner(lower, loader, inner_type),
           {:ok, upper} <- mutate_inner(upper, loader, inner_type) do
        new(lower, upper, lower_inclusive: lower_inclusive, upper_inclusive: upper_inclusive)
      end
    end

    def load(_value, _loader, _params), do: :error

    defp mutate_inner(value, mutator, inner_type)
    defp mutate_inner(:empty, _mutator, _inner_type), do: {:ok, :empty}
    defp mutate_inner(:unbound, _mutator, _inner_type), do: {:ok, :unbound}
    defp mutate_inner(value, mutator, inner_type), do: mutator.(inner_type, value)
  end
end

defimpl Enumerable, for: [Warder.Range] do
  import Warder.Range

  alias Warder.Element
  alias Warder.Range

  @impl Enumerable
  def count(%Range{}), do: {:error, __MODULE__}

  @impl Enumerable
  def member?(%Range{} = range, element), do: {:ok, Range.contains?(range, element)}

  @impl Enumerable
  def reduce(range, acc, fun)
  def reduce(%Range{} = range, _acc, _fun) when is_empty(range), do: {:done, []}
  def reduce(%Range{lower: :unbound} = _range, _acc, _fun), do: raise("Operation not supported for unbound lower.")

  def reduce(%Range{lower: lower, lower_inclusive: inclusive?} = range, acc, fun) do
    case Element.canonicalize(lower) do
      {:ok, one_up} ->
        start_value = if inclusive?, do: lower, else: one_up

        reduce(range, start_value, acc, fun)

      :error ->
        raise "Operation not supported for indiscrete elements."
    end
  end

  @impl Enumerable
  def slice(%Range{}), do: {:error, __MODULE__}

  defp reduce(range, current, acc, fun)
  defp reduce(_range, _current, {:halt, acc}, _fun), do: {:halted, acc}
  defp reduce(range, current, {:suspended, acc}, fun), do: {:suspended, acc, &reduce(range, current, &1, fun)}

  defp reduce(range, current, {:cont, acc}, fun) do
    if Range.contains?(range, current) do
      {:ok, one_up} = Element.canonicalize(current)

      reduce(range, one_up, fun.(current, acc), fun)
    else
      {:done, acc}
    end
  end
end
