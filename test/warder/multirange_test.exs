defmodule Warder.MultirangeTest do
  use Warder.DataCase, async: true
  use ExUnitProperties

  import Warder.Generator

  alias Warder.Multirange
  alias Warder.Range

  doctest Multirange

  describe inspect(&Multirange.new/1) do
    test "works" do
      assert %Multirange{
               ranges: [
                 %Range{lower: 1, upper: 15},
                 %Range{lower: 20, upper: 30}
               ]
             } =
               Multirange.new([
                 Range.new!(1, 10),
                 Range.new!(5, 15),
                 Range.new!(20, 30)
               ])
    end
  end

  describe inspect(&Multirange.empty/0) do
    test "works" do
      assert %Multirange{ranges: []} = Multirange.empty()
    end
  end

  describe inspect(&Multirange.contains?/2) do
    test "works" do
      assert Multirange.contains?(Multirange.new([Range.new!(1, 10)]), Multirange.new([Range.new!(1, 5)]))
      assert Multirange.contains?(Multirange.new([Range.new!(1, 10)]), Range.new!(1, 10))
      assert Multirange.contains?(Multirange.new([Range.new!(1, 10)]), 5)
      refute Multirange.contains?(Multirange.new([Range.new!(1, 10)]), 20)
    end
  end

  describe inspect(&Multirange.overlap?/2) do
    test "works" do
      assert Multirange.overlap?(Multirange.new([Range.new!(1, 10)]), Multirange.new([Range.new!(5, 15)]))
      assert Multirange.overlap?(Multirange.new([Range.new!(1, 10)]), Range.new!(5, 15))
      refute Multirange.overlap?(Multirange.new([Range.new!(1, 10)]), Range.new!(20, 30))
    end
  end

  describe inspect(&Multirange.left?/2) do
    test "works" do
      assert Multirange.left?(Multirange.new([Range.new!(1, 10)]), Multirange.new([Range.new!(20, 30)]))
      assert Multirange.left?(Multirange.new([Range.new!(1, 10)]), Range.new!(20, 30))
      refute Multirange.left?(Multirange.new([Range.new!(1, 10)]), Range.new!(5, 15))
    end
  end

  describe inspect(&Multirange.right?/2) do
    test "works" do
      assert Multirange.right?(Multirange.new([Range.new!(20, 30)]), Multirange.new([Range.new!(1, 10)]))
      assert Multirange.right?(Range.new!(20, 30), Multirange.new([Range.new!(1, 10)]))
      refute Multirange.right?(Range.new!(5, 15), Multirange.new([Range.new!(1, 10)]))
    end
  end

  describe inspect(&Multirange.no_extend_right?/2) do
    test "works" do
      assert Multirange.no_extend_right?(Multirange.new([Range.new!(1, 10)]), Multirange.new([Range.new!(20, 30)]))
      assert Multirange.no_extend_right?(Multirange.new([Range.new!(1, 10)]), Range.new!(20, 30))
      refute Multirange.no_extend_right?(Multirange.new([Range.new!(1, 10)]), Range.new!(1, 5))
    end
  end

  describe inspect(&Multirange.no_extend_left?/2) do
    test "works" do
      assert Multirange.no_extend_left?(Multirange.new([Range.new!(20, 30)]), Multirange.new([Range.new!(1, 10)]))
      assert Multirange.no_extend_left?(Range.new!(20, 30), Multirange.new([Range.new!(1, 10)]))
      refute Multirange.no_extend_left?(Range.new!(1, 10), Multirange.new([Range.new!(5, 10)]))
    end
  end

  describe inspect(&Multirange.adjacent?/2) do
    test "works" do
      refute Multirange.adjacent?(Multirange.new([Range.new!(1, 10)]), Multirange.new([Range.new!(20, 30)]))
      refute Multirange.adjacent?(Multirange.new([Range.new!(1, 10)]), Range.new!(20, 30))
      assert Multirange.adjacent?(Multirange.new([Range.new!(1, 10)]), Range.new!(10, 20))
    end
  end

  describe inspect(&Multirange.union/2) do
    test "works" do
      assert %Multirange{ranges: [%Range{lower: 1, upper: 15}]} =
               Multirange.union(
                 Multirange.new([Range.new!(1, 10)]),
                 Multirange.new([Range.new!(5, 15)])
               )
    end
  end

  describe inspect(&Multirange.intersection/2) do
    test "works" do
      assert %Multirange{ranges: [%Range{lower: 10, upper: 15}]} =
               Multirange.intersection(
                 Multirange.new([Range.new!(5, 15)]),
                 Multirange.new([Range.new!(10, 20)])
               )
    end
  end

  describe inspect(&Multirange.difference/2) do
    test "works" do
      assert %Multirange{
               ranges: [
                 %Range{lower: 5, upper: 10},
                 %Range{lower: 15, upper: 20}
               ]
             } =
               Multirange.difference(
                 Multirange.new([Range.new!(5, 20)]),
                 Multirange.new([Range.new!(10, 15)])
               )
    end
  end

  describe inspect(&Multirange.merge/1) do
    test "works" do
      assert %Range{lower: 1, upper: 30} =
               Multirange.merge(Multirange.new([Range.new!(1, 10), Range.new!(20, 30)]))
    end
  end

  describe inspect(&Multirange.dump/3) do
    test "works" do
      assert {:ok, %Postgrex.Multirange{ranges: [%Postgrex.Range{lower: 1, upper: 10}]}} =
               Multirange.dump(Multirange.new([Range.new!(1, 10)]), &Ecto.Type.dump/2, %{inner_type: :integer})
    end
  end

  describe inspect(&Multirange.load/3) do
    test "works" do
      assert {:ok, %Multirange{ranges: [%Range{lower: 1, upper: 10}]}} =
               Multirange.load(
                 %Postgrex.Multirange{
                   ranges: [%Postgrex.Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false}]
                 },
                 &Ecto.Type.load/2,
                 %{inner_type: :integer}
               )
    end
  end

  describe inspect(&Multirange.cast/3) do
    test "works" do
      assert {:ok, %Multirange{ranges: [%Range{lower: 1, upper: 10}]}} =
               Multirange.cast(
                 %Postgrex.Multirange{
                   ranges: [%Postgrex.Range{lower: 1, upper: 10, lower_inclusive: true, upper_inclusive: false}]
                 },
                 %{
                   inner_type: :integer
                 }
               )

      assert {:ok, %Multirange{ranges: [%Range{lower: 1, upper: 10}]}} =
               Multirange.cast(Multirange.new([Range.new!(1, 10)]), %{inner_type: :integer})
    end
  end

  describe inspect(Collectable) do
    test "collects items" do
      assert Multirange.new([Range.new!(1, 10), Range.new!(20, 30)]) ==
               Enum.into([Range.new!(1, 10), Range.new!(20, 30)], Multirange.empty())
    end
  end

  describe inspect(Enumerable) do
    test "enumerates items" do
      assert Enum.to_list(Multirange.new([Range.new!(1, 10), Range.new!(20, 30)])) == [
               Range.new!(1, 10),
               Range.new!(20, 30)
             ]
    end
  end

  describe "sanity checks" do
    property "RANGE_MERGE(multi)" do
      integer_gen = fn
        :unbound -> integer(-100..100)
        int -> integer(int..100)
      end

      check all multi <- multirange(integer_gen) do
        {:ok, multi_postgres} =
          Multirange.dump(multi, &Ecto.Type.dump/2, %{inner_type: :integer})

        %Postgrex.Result{rows: [[expected_result]]} =
          Repo.query!("SELECT RANGE_MERGE($1::int8multirange)", [multi_postgres])

        assert {:ok, expected_range} =
                 Range.load(expected_result, &Ecto.Type.load/2, %{inner_type: :integer})

        assert Multirange.merge(multi) == expected_range
      end
    end

    for {operator, function} <- [
          {"+", :union},
          {"-", :difference},
          {"*", :intersection}
        ] do
      property "multi #{operator} multi" do
        integer_gen = fn
          :unbound -> integer(-100..100)
          int -> integer(int..100)
        end

        check all first <- multirange(integer_gen),
                  second <- multirange(integer_gen) do
          {:ok, first_postgres} =
            Multirange.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

          {:ok, second_postgres} =
            Multirange.dump(second, &Ecto.Type.dump/2, %{inner_type: :integer})

          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::int8multirange #{unquote(operator)} $2::int8multirange", [
              first_postgres,
              second_postgres
            ])

          assert {:ok, expected_range} =
                   Multirange.load(expected_result, &Ecto.Type.load/2, %{inner_type: :integer})

          assert Multirange.unquote(function)(first, second) == expected_range
        end
      end
    end

    for {operator, function} <- [
          {"@>", :contains?},
          {"&&", :overlap?},
          {"<<", :left?},
          {">>", :right?},
          {"&<", :no_extend_right?},
          {"&>", :no_extend_left?},
          {"-|-", :adjacent?}
        ] do
      property "multi #{operator} multi" do
        integer_gen = fn
          :unbound -> integer(-100..100)
          int -> integer(int..100)
        end

        check all first <- multirange(integer_gen),
                  second <- multirange(integer_gen) do
          {:ok, first_postgres} =
            Multirange.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

          {:ok, second_postgres} =
            Multirange.dump(second, &Ecto.Type.dump/2, %{inner_type: :integer})

          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::int8multirange #{unquote(operator)} $2::int8multirange", [
              first_postgres,
              second_postgres
            ])

          assert Multirange.unquote(function)(first, second) == expected_result
        end
      end
    end

    for {operator, function} <- [
          {"@>", :contains?},
          {"&&", :overlap?},
          {"<<", :left?},
          {">>", :right?},
          {"&<", :no_extend_right?},
          {"&>", :no_extend_left?},
          {"-|-", :adjacent?}
        ] do
      property "multi #{operator} range" do
        integer_gen = fn
          :unbound -> integer(-100..100)
          int -> integer(int..100)
        end

        check all first <- multirange(integer_gen),
                  second <- range(integer_gen) do
          {:ok, first_postgres} =
            Multirange.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

          {:ok, second_postgres} =
            Range.dump(second, &Ecto.Type.dump/2, %{inner_type: :integer})

          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::int8multirange #{unquote(operator)} $2::int8range", [
              first_postgres,
              second_postgres
            ])

          assert Multirange.unquote(function)(first, second) == expected_result
        end
      end
    end

    for {operator, function} <- [
          {"@>", :contains?}
        ] do
      property "multi #{operator} element" do
        integer_gen = fn
          :unbound -> integer(-100..100)
          int -> integer(int..100)
        end

        check all first <- multirange(integer_gen),
                  second <- integer(-100..100) do
          {:ok, first_postgres} =
            Multirange.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::int8multirange #{unquote(operator)} $2::int8", [
              first_postgres,
              second
            ])

          assert Multirange.unquote(function)(first, second) == expected_result
        end
      end
    end

    # range multi
    for {operator, function} <- [
          {"@>", :contains?},
          {"&&", :overlap?},
          {"<<", :left?},
          {">>", :right?},
          {"&<", :no_extend_right?},
          {"&>", :no_extend_left?},
          {"-|-", :adjacent?}
        ] do
      property "range #{operator} multi" do
        integer_gen = fn
          :unbound -> integer(-100..100)
          int -> integer(int..100)
        end

        check all first <- range(integer_gen),
                  second <- multirange(integer_gen) do
          {:ok, first_postgres} =
            Range.dump(first, &Ecto.Type.dump/2, %{inner_type: :integer})

          {:ok, second_postgres} =
            Multirange.dump(second, &Ecto.Type.dump/2, %{inner_type: :integer})

          %Postgrex.Result{rows: [[expected_result]]} =
            Repo.query!("SELECT $1::int8range #{unquote(operator)} $2::int8multirange", [
              first_postgres,
              second_postgres
            ])

          assert Multirange.unquote(function)(first, second) == expected_result
        end
      end
    end
  end
end
