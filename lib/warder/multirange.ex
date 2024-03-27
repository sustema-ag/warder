defmodule Warder.Multirange do
  @moduledoc """
  Multirange Implementation

  > #### Creation / Manipulation {: .warning}
  >
  > Multiranges should not be created or modified manually. Use `new/1`, or
  > `empty/0` to create multiranges.

  ## Ecto Type

  If `ecto` and `postgrex` are installed, you can use the `Warder.Multirange`
  type:

  ```elixir
  defmodule Model do
    use Ecto.Schema

    alias Warder.Multirange

    @type t :: %{multirange: Multirange.t(integer())}

    schema "models" do
      field :multirange, Multirange,
        db_type: :int8multirange,
        inner_type: :integer
    end
  end
  ```

  ### Options

  * `db_type` - The database type to use for the range column. For example
    `:int8multirange`.
  * `inner_type` - The ecto type of the elements in the range. For example
    `:integer`.

  """
  @moduledoc since: "0.1.0"

  alias Warder.Range
  alias Warder.Range.DisjointRangesError

  require Warder.Range

  @typedoc since: "0.1.0"
  @type t() :: t(term())

  @typedoc since: "0.1.0"
  @type t(subtype) :: %__MODULE__{ranges: [Range.t(subtype)]}

  defstruct ranges: []

  @doc """
  Create a new Multirange for the given ranges

  ## Examples

      iex> Warder.Multirange.new([
      ...>   Warder.Range.new!(1, 10),
      ...>   Warder.Range.new!(5, 15),
      ...>   Warder.Range.new!(20, 30)
      ...>])
      %Warder.Multirange{ranges: [
        %Warder.Range{lower: 1, upper: 15, lower_inclusive: true, upper_inclusive: false},
        %Warder.Range{lower: 20, upper: 30, lower_inclusive: true, upper_inclusive: false}
      ]}

  """
  @doc since: "0.1.0"
  @spec new(ranges :: [Range.t(subtype)]) :: t(subtype) when subtype: Warder.Element.t()
  def new(ranges) do
    canonicalized =
      ranges
      |> Enum.sort(Range)
      |> Enum.reject(&Range.is_empty/1)
      |> Enum.reduce([], fn
        range, [] ->
          [range]

        range, [last | rest] = acc ->
          if Range.overlap?(range, last) or Range.adjacent?(range, last) do
            [Range.union!(range, last) | rest]
          else
            [range | acc]
          end
      end)
      |> Enum.reverse()

    %__MODULE__{ranges: canonicalized}
  end

  @doc """
  Create new empty multirange

  ## Examples

      iex> Warder.Multirange.empty()
      %Warder.Multirange{ranges: []}

  """
  @doc since: "0.1.0"
  @spec empty() :: t(subtype) when subtype: Warder.Element.t()
  def empty, do: new([])

  @doc """
  Check if `first` contains `second`.

  Both `first` and `second` can either be a multirange, range or an element.

  Does the first multirange contain the second multirange or range?

  ## Examples

      iex> Warder.Multirange.contains?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 5)])
      ...> )
      true

      iex> Warder.Multirange.contains?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Range.new!(1, 10)
      ...> )
      true

      iex> Warder.Multirange.contains?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   5
      ...> )
      true

      iex> Warder.Multirange.contains?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   20
      ...> )
      false

  """
  @doc since: "0.1.0"
  @spec contains?(first :: t(subtype) | Range.t(subtype) | subtype, second :: t(subtype) | Range.t(subtype) | subtype) ::
          boolean()
        when subtype: Warder.Element.t()
  def contains?(first, second)

  def contains?(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}) do
    Enum.all?(last_ranges, fn last_range ->
      Enum.any?(first_ranges, &Range.contains?(&1, last_range))
    end)
  end

  def contains?(first, second), do: contains?(upcast(first), upcast(second))

  @doc """
  Does `first` overlap with `second`, that is, do they have any common elements?

  Both `first` and `second` can either be a multirange or a range.

  ## Examples

      iex> Warder.Multirange.overlap?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Multirange.new([Warder.Range.new!(5, 15)])
      ...> )
      true

      iex> Warder.Multirange.overlap?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Range.new!(5, 15)
      ...> )
      true

      iex> Warder.Multirange.overlap?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Range.new!(20, 30)
      ...> )
      false

  """
  @doc since: "0.1.0"
  @spec overlap?(first :: t(subtype) | Range.t(subtype), second :: t(subtype) | Range.t(subtype)) :: boolean()
        when subtype: Warder.Element.t()
  def overlap?(first, second)

  def overlap?(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}) do
    Enum.any?(last_ranges, fn last_range ->
      Enum.any?(first_ranges, &Range.overlap?(&1, last_range))
    end)
  end

  def overlap?(first, second), do: overlap?(upcast(first), upcast(second))

  @doc """
  Is first strictly left of second?

  Both `first` and `second` can either be a multirange or a range.

  ## Examples

      iex> Warder.Multirange.left?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Multirange.new([Warder.Range.new!(20, 30)])
      ...> )
      true

      iex> Warder.Multirange.left?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Range.new!(20, 30)
      ...> )
      true

      iex> Warder.Multirange.left?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Range.new!(5, 15)
      ...> )
      false

  """
  @doc since: "0.1.0"
  @spec left?(first :: t(subtype) | Range.t(subtype), second :: t(subtype) | Range.t(subtype)) :: boolean()
        when subtype: Warder.Element.t()
  def left?(first, second)

  def left?(%__MODULE__{ranges: []}, _second), do: false
  def left?(_first, %__MODULE__{ranges: []}), do: false

  def left?(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}),
    do: Range.left?(List.last(first_ranges), List.first(last_ranges))

  def left?(first, second), do: left?(upcast(first), upcast(second))

  @doc """
  Is first strictly right of second?

  Both `first` and `second` can either be a multirange or a range.

  ## Examples

      iex> Warder.Multirange.right?(
      ...>   Warder.Multirange.new([Warder.Range.new!(20, 30)]),
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)])
      ...> )
      true

      iex> Warder.Multirange.right?(
      ...>   Warder.Range.new!(20, 30),
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)])
      ...> )
      true

      iex> Warder.Multirange.right?(
      ...>   Warder.Range.new!(5, 15),
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)])
      ...> )
      false

  """
  @doc since: "0.1.0"
  @spec right?(first :: t(subtype) | Range.t(subtype), second :: t(subtype) | Range.t(subtype)) :: boolean()
        when subtype: Warder.Element.t()
  @spec right?(first :: t(subtype) | Range.t(subtype), second :: t(subtype) | Range.t(subtype)) :: boolean()
        when subtype: Warder.Element.t()
  def right?(first, second)

  def right?(%__MODULE__{ranges: []}, _second), do: false
  def right?(_first, %__MODULE__{ranges: []}), do: false

  def right?(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}),
    do: Range.right?(List.first(first_ranges), List.last(last_ranges))

  def right?(first, second), do: right?(upcast(first), upcast(second))

  @doc """
  Does first not extend to the right of second?

  Both `first` and `second` can either be a multirange or a range.

  ## Examples

      iex> Warder.Multirange.no_extend_right?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Multirange.new([Warder.Range.new!(20, 30)])
      ...> )
      true

      iex> Warder.Multirange.no_extend_right?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Range.new!(20, 30)
      ...> )
      true

      iex> Warder.Multirange.no_extend_right?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Range.new!(1, 5)
      ...> )
      false

  """
  @doc since: "0.1.0"
  @spec no_extend_right?(first :: t(subtype) | Range.t(subtype), second :: t(subtype) | Range.t(subtype)) :: boolean()
        when subtype: Warder.Element.t()
  def no_extend_right?(first, second)

  def no_extend_right?(%__MODULE__{ranges: []}, _second), do: false
  def no_extend_right?(_first, %__MODULE__{ranges: []}), do: false

  def no_extend_right?(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}),
    do: Range.no_extend_right?(List.last(first_ranges), List.last(last_ranges))

  def no_extend_right?(first, second), do: no_extend_right?(upcast(first), upcast(second))

  @doc """
  Does first not extend to the left of second?

  Both `first` and `second` can either be a multirange or a range.

  ## Examples

      iex> Warder.Multirange.no_extend_left?(
      ...>   Warder.Multirange.new([Warder.Range.new!(20, 30)]),
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)])
      ...> )
      true

      iex> Warder.Multirange.no_extend_left?(
      ...>   Warder.Range.new!(20, 30),
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)])
      ...> )
      true

      iex> Warder.Multirange.no_extend_left?(
      ...>   Warder.Range.new!(1, 10),
      ...>   Warder.Multirange.new([Warder.Range.new!(5, 10)])
      ...> )
      false

  """
  @doc since: "0.1.0"
  @spec no_extend_left?(first :: t(subtype) | Range.t(subtype), second :: t(subtype) | Range.t(subtype)) :: boolean()
        when subtype: Warder.Element.t()
  def no_extend_left?(first, second)

  def no_extend_left?(%__MODULE__{ranges: []}, _second), do: false
  def no_extend_left?(_first, %__MODULE__{ranges: []}), do: false

  def no_extend_left?(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}),
    do: Range.no_extend_left?(List.first(first_ranges), List.first(last_ranges))

  def no_extend_left?(first, second), do: no_extend_left?(upcast(first), upcast(second))

  @doc """
  Is first adjacent to second?

  Both `first` and `second` can either be a multirange or a range.

  ## Examples

      iex> Warder.Multirange.adjacent?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...>   Warder.Multirange.new([Warder.Range.new!(20, 30)]
      ...> ))
      false

      iex> Warder.Multirange.adjacent?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]), Warder.Range.new!(20, 30)
      ...> )
      false

      iex> Warder.Multirange.adjacent?(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]), Warder.Range.new!(10, 20)
      ...> )
      true

  """
  @doc since: "0.1.0"
  @spec adjacent?(first :: t(subtype) | Range.t(subtype), second :: t(subtype) | Range.t(subtype)) :: boolean()
        when subtype: Warder.Element.t()
  def adjacent?(first, second)

  def adjacent?(%__MODULE__{ranges: []}, _second), do: false
  def adjacent?(_first, %__MODULE__{ranges: []}), do: false

  def adjacent?(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}),
    do:
      Range.adjacent?(List.first(first_ranges), List.last(last_ranges)) or
        Range.adjacent?(List.last(first_ranges), List.first(last_ranges))

  def adjacent?(first, second), do: adjacent?(upcast(first), upcast(second))

  @doc """
  Computes the union of the multiranges.

  ## Examples

      iex> Warder.Multirange.union(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10)]),
      ...> Warder.Multirange.new([Warder.Range.new!(5, 15)])
      ...> )
      %Warder.Multirange{ranges: [
        %Warder.Range{lower: 1, upper: 15, lower_inclusive: true, upper_inclusive: false}
      ]}

  """
  @doc since: "0.1.0"
  @spec union(first :: t(subtype), second :: t(subtype)) :: t(subtype)
        when subtype: Warder.Element.t()
  def union(first, second)

  def union(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}), do: new(first_ranges ++ last_ranges)

  @doc """
  Computes the intersection of the multiranges.

  ## Examples

      iex> Warder.Multirange.intersection(
      ...>   Warder.Multirange.new([Warder.Range.new!(5, 15)]),
      ...>   Warder.Multirange.new([Warder.Range.new!(10, 20)])
      ...> )
      %Warder.Multirange{ranges: [
        %Warder.Range{lower: 10, upper: 15, lower_inclusive: true, upper_inclusive: false}
      ]}

  """
  @doc since: "0.1.0"
  @spec intersection(first :: t(subtype), second :: t(subtype)) :: t(subtype)
        when subtype: Warder.Element.t()
  def intersection(first, second)

  def intersection(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}) do
    for first_range <- first_ranges,
        last_range <- last_ranges,
        intersection = Range.intersection(first_range, last_range),
        not Range.is_empty(intersection),
        do: intersection,
        into: empty()
  end

  @doc """
  Computes the difference of the multiranges.

  ## Examples

      iex> Warder.Multirange.difference(
      ...>   Warder.Multirange.new([Warder.Range.new!(5, 20)]),
      ...>   Warder.Multirange.new([Warder.Range.new!(10, 15)])
      ...> )
      %Warder.Multirange{ranges: [
        %Warder.Range{lower: 5, upper: 10, lower_inclusive: true, upper_inclusive: false},
        %Warder.Range{lower: 15, upper: 20, lower_inclusive: true, upper_inclusive: false}
      ]}
  """
  @doc since: "0.1.0"
  @spec difference(first :: t(subtype), second :: t(subtype)) :: t(subtype)
        when subtype: Warder.Element.t()
  def difference(first, second)
  def difference(%__MODULE__{ranges: []} = first, _second), do: first
  def difference(first, %__MODULE__{ranges: []}), do: first

  def difference(%__MODULE__{ranges: first_ranges}, %__MODULE__{ranges: last_ranges}) do
    last_ranges
    |> Enum.reduce(first_ranges, &range_difference/2)
    |> new()
  end

  defp range_difference(last_range, acc) do
    Enum.flat_map(acc, fn first_range ->
      case Range.difference(first_range, last_range) do
        {:ok, diff} -> [diff]
        {:error, %DisjointRangesError{lower: lower, upper: upper}} -> [lower, upper]
      end
    end)
  end

  @doc """
  Computes the smallest range that all parts of the multirange.

  ## Examples

      iex> Warder.Multirange.merge(
      ...>   Warder.Multirange.new([Warder.Range.new!(1, 10), Warder.Range.new!(20, 30)])
      ...> )
      %Warder.Range{lower: 1, upper: 30, lower_inclusive: true, upper_inclusive: false}

  """
  @doc since: "0.1.0"
  @spec merge(multirange :: t(subtype)) :: Range.t(subtype)
        when subtype: Warder.Element.t()
  def merge(multirange)
  def merge(%__MODULE__{ranges: []}), do: Range.empty()
  def merge(%__MODULE__{ranges: ranges}), do: Range.merge(List.first(ranges), List.last(ranges))

  @spec upcast(value :: t(subtype)) :: t(subtype) when subtype: Warder.Element.t()
  @spec upcast(value :: Range.t(subtype)) :: t(subtype) when subtype: Warder.Element.t()
  @spec upcast(value :: subtype) :: t(subtype) when subtype: Warder.Element.t()
  defp upcast(value)
  defp upcast(%__MODULE__{} = value), do: value
  defp upcast(%Range{} = value), do: upcast(new([value]))
  defp upcast(value), do: upcast(Range.new!(value, value, lower_inclusive: true, upper_inclusive: true))

  defimpl Enumerable do
    @impl Enumerable
    def count(%{ranges: ranges}), do: Enumerable.count(ranges)

    @impl Enumerable
    def member?(%{ranges: ranges}, element), do: Enumerable.member?(ranges, element)

    @impl Enumerable
    def reduce(%{ranges: ranges}, acc, fun), do: Enumerable.reduce(ranges, acc, fun)

    @impl Enumerable
    def slice(%{ranges: ranges}), do: Enumerable.slice(ranges)
  end

  defimpl Collectable do
    @impl Collectable
    def into(%{ranges: ranges} = acc) do
      {list_acc, list_collector} = Collectable.into(ranges)

      collector_fun = fn
        {list_acc, acc}, {:cont, %Range{} = element} ->
          {list_collector.(list_acc, {:cont, element}), acc}

        {list_acc, acc}, :done ->
          %{acc | ranges: list_collector.(list_acc, :done)}

        {list_acc, _acc}, :halt ->
          list_collector.(list_acc, :halt)
      end

      {{list_acc, acc}, collector_fun}
    end
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
    def cast(%Postgrex.Multirange{ranges: ranges}, _params) do
      case Enum.reduce_while(ranges, {:ok, []}, &cast_range/2) do
        {:ok, ranges} -> {:ok, new(ranges)}
        :error -> :error
      end
    end

    def cast(%__MODULE__{} = multirange, _params), do: {:ok, multirange}

    def cast(_value, _params), do: :error

    defp cast_range(range, {:ok, acc}) do
      case Range.cast(range, %{db_type: :integer}) do
        {:ok, range} -> {:cont, {:ok, [range | acc]}}
        :error -> {:halt, :error}
      end
    end

    @doc false
    @impl Ecto.ParameterizedType
    def dump(nil, _dumper, _params), do: {:ok, nil}

    def dump(%__MODULE__{ranges: ranges}, dumper, params) do
      case Enum.reduce_while(ranges, {:ok, []}, &dump_range(&1, &2, dumper, params)) do
        {:ok, ranges} -> {:ok, %Postgrex.Multirange{ranges: ranges}}
        :error -> :error
      end
    end

    def dump(_value, _dumper, _params), do: :error

    defp dump_range(range, {:ok, acc}, dumper, params) do
      case dumper.({:parameterized, Range, params}, range) do
        {:ok, range} -> {:cont, {:ok, [range | acc]}}
        :error -> {:halt, :error}
      end
    end

    @doc false
    @impl Ecto.ParameterizedType
    def load(nil, _loader, _params), do: {:ok, nil}

    def load(%Postgrex.Multirange{ranges: ranges}, loader, params) do
      case Enum.reduce_while(ranges, {:ok, []}, &load_range(&1, &2, loader, params)) do
        {:ok, ranges} -> {:ok, new(ranges)}
        :error -> :error
      end
    end

    def load(_value, _loader, _params), do: :error

    defp load_range(range, {:ok, acc}, loader, params) do
      case loader.({:parameterized, Range, params}, range) do
        {:ok, range} -> {:cont, {:ok, [range | acc]}}
        :error -> {:halt, :error}
      end
    end
  end
end
