defmodule Warder.RangeTest do
  use Warder.DataCase, async: true
  use ExUnitProperties

  import Warder.Generator

  alias Warder.Range
  alias Warder.Range.BoundOrderError
  alias Warder.Range.DisjointRangesError
  alias Warder.Range.NotContiguousError

  doctest Range

  describe inspect(&Range.new/3) do
    test "creates a new range" do
      assert {:ok, %Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false}} =
               Range.new(1, 10)

      assert {:ok, %Range{lower: 2, upper: 11, lower_inclusive: true, upper_inclusive: false}} =
               Range.new(1, 10, lower_inclusive: false, upper_inclusive: true)

      assert {:error, %BoundOrderError{lower: 10, upper: 1}} = Range.new(10, 1)

      assert {:ok, %Range{lower: :empty}} = Range.new(1, 1, upper_inclusive: false)
      assert {:ok, %Range{lower: 1}} = Range.new(1, 1, upper_inclusive: true)

      assert {:ok, %Range{lower: :empty}} =
               Range.new(71, 72, lower_inclusive: false, upper_inclusive: false)
    end
  end

  describe inspect(&Range.new!/3) do
    test "creates a new range" do
      assert %Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false} =
               Range.new!(1, 10)

      assert_raise BoundOrderError,
                   "The range lower bound (10) must be less than or equal to range upper bound (1).",
                   fn ->
                     Range.new!(10, 1)
                   end
    end
  end

  describe inspect(&Range.contains?/2) do
    test "works" do
      assert Range.contains?(Range.new!(1, 101), Range.new!(11, 33))
      refute Range.contains?(Range.new!(11, 33), Range.new!(1, 101))
      assert Range.contains?(Range.new!(1, 101), 33)
      refute Range.contains?(Range.new!(11, 33), 101)
    end
  end

  describe inspect(&Range.overlap?/2) do
    test "works" do
      assert Range.overlap?(Range.new!(1, 10), Range.new!(5, 15))
      refute Range.overlap?(Range.new!(1, 10), Range.new!(15, 20))
    end
  end

  describe inspect(&Range.left?/2) do
    test "works" do
      assert Range.left?(Range.new!(1, 10), Range.new!(11, 15))
      refute Range.left?(Range.new!(1, 10), Range.new!(5, 15))
    end
  end

  describe inspect(&Range.right?/2) do
    test "works" do
      assert Range.right?(Range.new!(11, 15), Range.new!(1, 10))
      refute Range.right?(Range.new!(5, 15), Range.new!(1, 10))
    end
  end

  describe inspect(&Range.no_extend_right?/2) do
    test "works" do
      assert Range.no_extend_right?(Range.new!(1, 10), Range.new!(5, 15))
      refute Range.no_extend_right?(Range.new!(1, 15), Range.new!(5, 10))
    end
  end

  describe inspect(&Range.no_extend_left?/2) do
    test "works" do
      assert Range.no_extend_left?(Range.new!(5, 10), Range.new!(1, 15))
      refute Range.no_extend_left?(Range.new!(1, 15), Range.new!(5, 10))
    end
  end

  describe inspect(&Range.adjacent?/2) do
    test "works" do
      assert Range.adjacent?(Range.new!(0, 10), Range.new!(10, 20))
      refute Range.adjacent?(Range.new!(0, 10), Range.new!(15, 20))
    end
  end

  describe inspect(&Range.union/2) do
    test "works" do
      assert {:ok, %Range{lower: 0, upper: 20}} =
               Range.union(Range.new!(0, 15), Range.new!(15, 20))

      assert {:ok, %Range{lower: 0, upper: 20}} =
               Range.union(Range.new!(0, 10), Range.new!(10, 20))

      assert {:error, %NotContiguousError{first: %Range{lower: 0, upper: 10}, second: %Range{lower: 12, upper: 20}}} =
               Range.union(Range.new!(0, 10), Range.new!(12, 20))
    end
  end

  describe inspect(&Range.union!/2) do
    test "works" do
      assert %Range{lower: 0, upper: 20} = Range.union!(Range.new!(0, 15), Range.new!(15, 20))

      assert %Range{lower: 0, upper: 20} = Range.union!(Range.new!(0, 10), Range.new!(10, 20))

      assert_raise NotContiguousError,
                   """
                   The first range and second range are not contiguous.
                   First: %Warder.Range{lower: 0, upper: 10, lower_inclusive: true, upper_inclusive: false}
                   Second: %Warder.Range{lower: 12, upper: 20, lower_inclusive: true, upper_inclusive: false}\
                   """,
                   fn ->
                     Range.union!(Range.new!(0, 10), Range.new!(12, 20))
                   end
    end
  end

  describe inspect(&Range.intersection/2) do
    test "works" do
      assert %Range{lower: 5, upper: 10} =
               Range.intersection(Range.new!(1, 10), Range.new!(5, 15))

      assert %Range{lower: :empty} = Range.intersection(Range.new!(1, 10), Range.new!(15, 20))
    end
  end

  describe inspect(&Range.difference/2) do
    test "works" do
      assert {:ok, %Range{lower: 1, upper: 5}} =
               Range.difference(Range.new!(1, 10), Range.new!(5, 15))

      assert {:ok, %Range{lower: 1, upper: 10}} =
               Range.difference(Range.new!(1, 10), Range.new!(15, 20))

      assert {:error,
              %DisjointRangesError{
                lower: %Range{lower: 1, upper: 2},
                upper: %Range{lower: 8, upper: 10}
              }} = Range.difference(Range.new!(1, 10), Range.new!(2, 8))
    end
  end

  describe inspect(&Range.difference!/2) do
    test "works" do
      assert %Range{lower: 1, upper: 5} = Range.difference!(Range.new!(1, 10), Range.new!(5, 15))

      assert %Range{lower: 1, upper: 10} =
               Range.difference!(Range.new!(1, 10), Range.new!(15, 20))

      assert_raise DisjointRangesError,
                   """
                   The result of range difference would not be contiguous.
                   Before difference: %Warder.Range{lower: 1, upper: 2, lower_inclusive: true, upper_inclusive: false}
                   After difference: %Warder.Range{lower: 8, upper: 10, lower_inclusive: true, upper_inclusive: false}\
                   """,
                   fn ->
                     Range.difference!(Range.new!(1, 10), Range.new!(2, 8))
                   end
    end
  end

  describe inspect(&Range.merge/2) do
    test "works" do
      assert %Range{lower: 1, upper: 15} = Range.merge(Range.new!(1, 10), Range.new!(5, 15))
      assert %Range{lower: 1, upper: 20} = Range.merge(Range.new!(1, 10), Range.new!(15, 20))
    end
  end

  describe inspect(&Range.compare/2) do
    test "works" do
      assert Range.compare(Range.new!(1, 10), Range.new!(1, 10)) == :eq
      assert Range.compare(Range.new!(1, 10), Range.new!(5, 10)) == :lt
      assert Range.compare(Range.new!(5, 10), Range.new!(1, 10)) == :gt
      assert Range.compare(Range.new!(1, 10), Range.new!(1, 11)) == :lt
      assert Range.compare(Range.new!(1, 10), Range.new!(1, 9)) == :gt

      assert [
               Range.new!(1, 9),
               Range.new!(1, 10),
               Range.new!(1, 11),
               Range.new!(5, 10),
               Range.empty()
             ] ==
               Enum.sort(
                 [
                   Range.new!(1, 10),
                   Range.new!(5, 10),
                   Range.new!(1, 11),
                   Range.new!(1, 9),
                   Range.empty()
                 ],
                 Range
               )
    end
  end

  describe inspect(&Range.dump/3) do
    test "works" do
      assert {:ok, %Postgrex.Range{lower: 1, upper: 10}} =
               Range.dump(Range.new!(1, 10), &Ecto.Type.dump/2, %{inner_type: :integer})
    end
  end

  describe inspect(&Range.load/3) do
    test "works" do
      assert {:ok, %Range{lower: 1, upper: 10}} =
               Range.load(
                 %Postgrex.Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false},
                 &Ecto.Type.load/2,
                 %{inner_type: :integer}
               )
    end
  end

  describe inspect(&Range.cast/3) do
    test "works" do
      assert {:ok, %Range{lower: 1, upper: 10}} =
               Range.cast(%Postgrex.Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false}, %{
                 inner_type: :integer
               })

      assert {:ok, %Range{lower: 1, upper: 10}} =
               Range.cast(Range.new!(1, 10), %{inner_type: :integer})

      assert {:ok, %Range{lower: ~D[2024-03-01], upper: ~D[2024-03-29]}} =
               Range.cast(Date.range(~D[2024-03-01], ~D[2024-03-28]), %{db_type: :daterange})
    end
  end

  describe inspect(&Enumerable.count/1) do
    test "can count elements" do
      assert Enum.count(Range.new!(1, 10)) == 9
    end
  end

  describe inspect(&Enumerable.reduce/1) do
    test "can list elements" do
      assert Enum.to_list(Range.new!(1, 10)) == Enum.to_list(1..9)

      assert_raise RuntimeError, "Operation not supported for indiscrete elements.", fn ->
        Enum.to_list(Range.new!(Decimal.new(1), Decimal.new(10)))
      end

      assert_raise RuntimeError, "Operation not supported for unbound lower.", fn ->
        Enum.to_list(Range.new!(:unbound, Decimal.new(10)))
      end
    end
  end

  describe inspect(&Enumerable.slice/1) do
    test "can slice elements" do
      assert Enum.slice(Range.new!(1, 10), 2..5) == [3, 4, 5, 6]
    end
  end

  describe inspect(&Enumerable.member?/2) do
    test "can detect members" do
      assert Enum.member?(Range.new!(1, 10), 2)
      assert Enum.member?(Range.new!(Decimal.new(1), Decimal.new(10)), Decimal.new("3.5"))
      refute Enum.member?(Range.new!(1, 10), 17)
    end
  end

  describe "sanity checks" do
    for {operator, function} <- [
          {"@>", :contains?},
          {"&&", :overlap?},
          {"<<", :left?},
          {">>", :right?},
          {"&<", :no_extend_right?},
          {"&>", :no_extend_left?},
          {"-|-", :adjacent?}
        ] do
      property "#{operator} for two discrete ranges" do
        integer_gen = fn
          :unbound -> integer(-100..100)
          int -> integer(int..100)
        end

        check all first <- range(integer_gen),
                  second <- range(integer_gen) do
          {:ok, first_postgres} =
            Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

          {:ok, second_postgres} =
            Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :integer})

          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::int8range #{unquote(operator)} $2::int8range", [
              first_postgres,
              second_postgres
            ])

          assert Range.unquote(function)(first, second) == expected_result
        end
      end

      property "#{operator} for two indiscrete ranges" do
        decimal_gen = fn
          :unbound -> decimal(min: Decimal.new(-100), max: Decimal.new(100))
          float -> decimal(min: float, max: Decimal.new(100))
        end

        check all first <- range(decimal_gen),
                  second <- range(decimal_gen) do
          {:ok, first_postgres} = Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :decimal})
          {:ok, second_postgres} = Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :decimal})

          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::numrange #{unquote(operator)} $2::numrange", [
              first_postgres,
              second_postgres
            ])

          assert Range.unquote(function)(first, second) == expected_result
        end
      end
    end

    property "* for two discrete ranges" do
      integer_gen = fn
        :unbound -> integer(-100..100)
        int -> integer(int..100)
      end

      check all first <- range(integer_gen),
                second <- range(integer_gen) do
        {:ok, first_postgres} =
          Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

        {:ok, second_postgres} =
          Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :integer})

        %Postgrex.Result{rows: [[expected_result]]} =
          Repo.query!("SELECT $1::int8range * $2::int8range", [
            first_postgres,
            second_postgres
          ])

        assert {:ok, expected_range} =
                 Range.load(expected_result, &Ecto.Type.load/2, %{inner_type: :integer})

        assert Range.intersection(first, second) == expected_range
      end
    end

    property "* for two indiscrete ranges" do
      decimal_gen = fn
        :unbound -> decimal(min: Decimal.new(-100), max: Decimal.new(100))
        float -> decimal(min: float, max: Decimal.new(100))
      end

      check all first <- range(decimal_gen),
                second <- range(decimal_gen) do
        {:ok, first_postgres} = Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :decimal})
        {:ok, second_postgres} = Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :decimal})

        %Postgrex.Result{rows: [[expected_result]]} =
          Repo.query!("SELECT $1::numrange * $2::numrange", [
            first_postgres,
            second_postgres
          ])

        assert {:ok, expected_range} =
                 Range.load(expected_result, &Ecto.Type.load/2, %{inner_type: :decimal})

        assert Range.intersection(first, second) == expected_range
      end
    end

    property "- for two discrete ranges" do
      integer_gen = fn
        :unbound -> integer(-100..100)
        int -> integer(int..100)
      end

      check all first <- range(integer_gen),
                second <- range(integer_gen) do
        {:ok, first_postgres} =
          Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

        {:ok, second_postgres} =
          Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :integer})

        try do
          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::int8range - $2::int8range", [
              first_postgres,
              second_postgres
            ])

          assert {:ok, expected_range} =
                   Range.load(expected_result, &Ecto.Type.load/2, %{inner_type: :integer})

          assert Range.difference!(first, second) == expected_range
        rescue
          e in Postgrex.Error ->
            if e.postgres.message != "result of range difference would not be contiguous" do
              reraise e, __STACKTRACE__
            end

            assert_raise DisjointRangesError, fn ->
              Range.difference!(first, second)
            end
        end
      end
    end

    property "- for two indiscrete ranges" do
      decimal_gen = fn
        :unbound -> decimal(min: Decimal.new(-100), max: Decimal.new(100))
        float -> decimal(min: float, max: Decimal.new(100))
      end

      check all first <- range(decimal_gen),
                second <- range(decimal_gen) do
        {:ok, first_postgres} = Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :decimal})
        {:ok, second_postgres} = Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :decimal})

        try do
          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::numrange - $2::numrange", [
              first_postgres,
              second_postgres
            ])

          assert {:ok, expected_range} =
                   Range.load(expected_result, &Ecto.Type.load/2, %{inner_type: :decimal})

          assert Range.difference!(first, second) == expected_range
        rescue
          e in Postgrex.Error ->
            if e.postgres.message != "result of range difference would not be contiguous" do
              reraise e, __STACKTRACE__
            end

            assert_raise DisjointRangesError, fn ->
              Range.difference!(first, second)
            end
        end
      end
    end

    property "+ for two discrete ranges" do
      integer_gen = fn
        :unbound -> integer(-100..100)
        int -> integer(int..100)
      end

      check all first <- range(integer_gen),
                second <- range(integer_gen) do
        {:ok, first_postgres} =
          Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

        {:ok, second_postgres} =
          Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :integer})

        try do
          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::int8range + $2::int8range", [first_postgres, second_postgres])

          assert {:ok, expected_range} =
                   Range.load(expected_result, &Ecto.Type.load/2, %{inner_type: :integer})

          assert Range.union!(first, second) == expected_range
        rescue
          e in Postgrex.Error ->
            if e.postgres.message != "result of range union would not be contiguous" do
              reraise e, __STACKTRACE__
            end

            assert_raise NotContiguousError, fn ->
              Range.union!(first, second)
            end
        end
      end
    end

    property "+ for two indiscrete ranges" do
      decimal_gen = fn
        :unbound -> decimal(min: Decimal.new(-100), max: Decimal.new(100))
        float -> decimal(min: float, max: Decimal.new(100))
      end

      check all first <- range(decimal_gen),
                second <- range(decimal_gen) do
        {:ok, first_postgres} = Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :decimal})
        {:ok, second_postgres} = Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :decimal})

        try do
          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::numrange + $2::numrange", [
              first_postgres,
              second_postgres
            ])

          assert {:ok, expected_range} =
                   Range.load(expected_result, &Ecto.Type.load/2, %{inner_type: :decimal})

          assert Range.union!(first, second) == expected_range
        rescue
          e in Postgrex.Error ->
            if e.postgres.message != "result of range union would not be contiguous" do
              reraise e, __STACKTRACE__
            end

            assert_raise NotContiguousError, fn ->
              Range.union!(first, second)
            end
        end
      end
    end

    property "@> for discrete range and element" do
      integer_gen = fn
        :unbound -> integer(-100..100)
        int -> integer(int..100)
      end

      check all range <- range(integer_gen),
                element <- integer(-100..100) do
        {:ok, range_postgres} =
          Range.dump(range, &Ecto.Type.dump/2, %{inner_type: :integer})

        %Postgrex.Result{rows: [[expected_result]]} =
          Repo.query!("SELECT $1::int8range @> $2::int8", [
            range_postgres,
            element
          ])

        assert Range.contains?(range, element) == expected_result
      end
    end

    property "@> for indiscrete range and element" do
      decimal_gen = fn
        :unbound -> decimal(min: Decimal.new(-100), max: Decimal.new(100))
        float -> decimal(min: float, max: Decimal.new(100))
      end

      check all range <- range(decimal_gen),
                element <- decimal(min: Decimal.new(-100), max: Decimal.new(100)) do
        {:ok, range_postgres} = Range.dump(range, &Ecto.Type.dump/2, %{inner_type: :decimal})

        %Postgrex.Result{rows: [[expected_result]]} =
          Repo.query!("SELECT $1::numrange @> $2::numeric", [
            range_postgres,
            element
          ])

        assert Range.contains?(range, element) == expected_result
      end
    end

    property "RANGE_MERGE for two discrete ranges" do
      integer_gen = fn
        :unbound -> integer(-100..100)
        int -> integer(int..100)
      end

      check all first <- range(integer_gen),
                second <- range(integer_gen) do
        {:ok, first_postgres} =
          Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

        {:ok, second_postgres} =
          Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :integer})

        %Postgrex.Result{rows: [[expected_result]]} =
          Repo.query!("SELECT RANGE_MERGE($1::int8range, $2::int8range)", [
            first_postgres,
            second_postgres
          ])

        assert {:ok, expected_range} =
                 Range.load(expected_result, &Ecto.Type.load/2, %{inner_type: :integer})

        assert Range.merge(first, second) == expected_range
      end
    end

    property "RANGE_MERGE for two indiscrete ranges" do
      decimal_gen = fn
        :unbound -> decimal(min: Decimal.new(-100), max: Decimal.new(100))
        float -> decimal(min: float, max: Decimal.new(100))
      end

      check all first <- range(decimal_gen),
                second <- range(decimal_gen) do
        {:ok, first_postgres} = Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :decimal})
        {:ok, second_postgres} = Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :decimal})

        %Postgrex.Result{rows: [[expected_result]]} =
          Repo.query!("SELECT RANGE_MERGE($1::numrange, $2::numrange)", [
            first_postgres,
            second_postgres
          ])

        assert {:ok, expected_range} =
                 Range.load(expected_result, &Ecto.Type.load/2, %{inner_type: :decimal})

        assert Range.merge(first, second) == expected_range
      end
    end
  end
end
