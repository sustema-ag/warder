defmodule Warder.QueryTest do
  use Warder.DataCase, async: true

  import Ecto.Query

  alias Warder.Model
  alias Warder.Multirange
  alias Warder.Query
  alias Warder.Range

  require Query

  doctest Query

  setup do
    Repo.insert!(
      Model.changeset(%Model{}, %{
        range: Range.new!(1, 10),
        multirange: Multirange.new([Range.new!(1, 10)])
      })
    )

    :ok
  end

  describe "contains?/2" do
    test "works" do
      assert [%Model{range: %Range{lower: 1, upper: 10}}] =
               Repo.all(from(model in Model, where: Query.contains?(model.range, fragment("?::int8", 5))))
    end
  end

  describe "contained?/2" do
    test "works" do
      assert [%Model{range: %Range{lower: 1, upper: 10}}] =
               Repo.all(from(model in Model, where: Query.contained?(fragment("?::int8", 5), model.range)))
    end
  end

  describe "overlap?/2" do
    test "works" do
      assert [%Model{range: %Range{lower: 1, upper: 10}}] =
               Repo.all(from(model in Model, where: Query.overlap?(model.range, type(^Range.new!(2, 3), model.range))))
    end
  end

  describe "left?/2" do
    test "works" do
      assert [%Model{range: %Range{lower: 1, upper: 10}}] =
               Repo.all(from(model in Model, where: Query.left?(model.range, type(^Range.new!(20, 25), model.range))))
    end
  end

  describe "right?/2" do
    test "works" do
      assert [%Model{range: %Range{lower: 1, upper: 10}}] =
               Repo.all(from(model in Model, where: Query.right?(model.range, type(^Range.new!(-10, 0), model.range))))
    end
  end

  describe "no_extend_right?/2" do
    test "works" do
      assert [%Model{range: %Range{lower: 1, upper: 10}}] =
               Repo.all(
                 from(model in Model, where: Query.no_extend_right?(model.range, type(^Range.new!(-5, 15), model.range)))
               )
    end
  end

  describe "no_extend_left?/2" do
    test "works" do
      assert [%Model{range: %Range{lower: 1, upper: 10}}] =
               Repo.all(
                 from(model in Model, where: Query.no_extend_left?(model.range, type(^Range.new!(-5, 15), model.range)))
               )
    end
  end

  describe "adjacent?/2" do
    test "works" do
      assert [%Model{range: %Range{lower: 1, upper: 10}}] =
               Repo.all(from(model in Model, where: Query.adjacent?(model.range, type(^Range.new!(10, 20), model.range))))
    end
  end

  describe "union/2" do
    test "works" do
      assert [%Range{lower: 1, upper: 20}] =
               Repo.all(from(model in Model, select: type(Query.union(model.range, ^Range.new!(10, 20)), model.range)))
    end
  end

  describe "intersection/2" do
    test "works" do
      assert [%Range{lower: 5, upper: 10}] =
               Repo.all(
                 from(model in Model, select: type(Query.intersection(model.range, ^Range.new!(5, 18)), model.range))
               )
    end
  end

  describe "difference/2" do
    test "works" do
      assert [%Range{lower: 1, upper: 5}] =
               Repo.all(
                 from(model in Model,
                   select: type(Query.difference(model.range, type(^Range.new!(5, 18), model.range)), model.range)
                 )
               )
    end
  end

  describe "lower/1" do
    test "works" do
      assert [1] = Repo.all(from(model in Model, select: Query.lower(model.range)))
    end
  end

  describe "upper/1" do
    test "works" do
      assert [10] = Repo.all(from(model in Model, select: Query.upper(model.range)))
    end
  end

  describe "empty?/1" do
    test "works" do
      assert [false] = Repo.all(from(model in Model, select: Query.empty?(model.range)))
    end
  end

  describe "lower_inclusive?/1" do
    test "works" do
      assert [true] = Repo.all(from(model in Model, select: Query.lower_inclusive?(model.range)))
    end
  end

  describe "upper_inclusive?/1" do
    test "works" do
      assert [false] = Repo.all(from(model in Model, select: Query.upper_inclusive?(model.range)))
    end
  end

  describe "lower_infinite?/1" do
    test "works" do
      assert [false] = Repo.all(from(model in Model, select: Query.lower_infinite?(model.range)))
    end
  end

  describe "upper_infinite?/1" do
    test "works" do
      assert [false] = Repo.all(from(model in Model, select: Query.upper_infinite?(model.range)))
    end
  end

  describe "merge_ranges/2" do
    test "works" do
      assert [%Range{lower: 1, upper: 10}] =
               Repo.all(from(model in Model, select: type(Query.merge_ranges(model.range, model.range), model.range)))
    end
  end

  describe "merge_multirange/1" do
    test "works" do
      assert [%Range{lower: 1, upper: 10}] =
               Repo.all(from(model in Model, select: type(Query.merge_multirange(model.multirange), model.range)))
    end
  end

  describe "multirange/1" do
    test "works" do
      assert [%Multirange{ranges: [%Range{lower: 1, upper: 10}]}] =
               Repo.all(from(model in Model, select: type(Query.multirange(model.range), model.multirange)))
    end
  end

  describe "unnest/1" do
    test "works" do
      assert [%Range{lower: 1, upper: 10}] =
               Repo.all(
                 from(model in Model,
                   cross_join: range in Query.unnest(model.multirange),
                   select: type(fragment("?", range), model.range)
                 )
               )
    end
  end
end
