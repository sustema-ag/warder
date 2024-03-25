defmodule Warder.ELementTest do
  use ExUnit.Case, async: true

  alias Warder.Element
  alias Warder.Range

  doctest Element

  describe "Float" do
    test "comparison correct" do
      assert Enum.member?(Range.new!(1.1, 3.3), 2.2)
      refute Enum.member?(Range.new!(1.1, 3.3), 4.4)
    end
  end

  describe "Decimal" do
    test "comparison correct" do
      assert Enum.member?(Range.new!(Decimal.new("1.1"), Decimal.new("3.3")), Decimal.new("2.2"))
      refute Enum.member?(Range.new!(Decimal.new("1.1"), Decimal.new("3.3")), Decimal.new("4.4"))
    end
  end

  describe "Integer" do
    test "canonicalization correct" do
      assert Range.new!(1, 3) == Range.new!(1, 2, upper_inclusive: true)
    end

    test "comparison correct" do
      assert Enum.member?(Range.new!(1, 3), 2)
      refute Enum.member?(Range.new!(1, 3), 4)
    end
  end

  describe "Date" do
    test "canonicalization correct" do
      assert Range.new!(~D[2024-03-01], ~D[2024-03-26]) ==
               Range.new!(~D[2024-03-01], ~D[2024-03-25], upper_inclusive: true)
    end

    test "comparison correct" do
      assert Enum.member?(Range.new!(~D[2024-03-01], ~D[2024-03-26]), ~D[2024-03-15])
      refute Enum.member?(Range.new!(~D[2024-03-01], ~D[2024-03-26]), ~D[2024-04-01])
    end
  end

  describe "DateTime" do
    test "comparison correct" do
      assert Enum.member?(Range.new!(~U[2024-03-01 00:00:00Z], ~U[2024-03-26 00:00:00Z]), ~U[2024-03-15 00:00:00Z])
      refute Enum.member?(Range.new!(~U[2024-03-01 00:00:00Z], ~U[2024-03-26 00:00:00Z]), ~U[2024-04-01 00:00:00Z])
    end
  end

  describe "NaiveDateTime" do
    test "comparison correct" do
      assert Enum.member?(Range.new!(~N[2024-03-01 00:00:00], ~N[2024-03-26 00:00:00]), ~N[2024-03-15 00:00:00])
      refute Enum.member?(Range.new!(~N[2024-03-01 00:00:00], ~N[2024-03-26 00:00:00]), ~N[2024-04-01 00:00:00])
    end
  end

  describe "Time" do
    test "comparison correct" do
      assert Enum.member?(Range.new!(~T[00:00:00], ~T[12:00:00]), ~T[06:00:00])
      refute Enum.member?(Range.new!(~T[00:00:00], ~T[12:00:00]), ~T[18:00:00])
    end
  end
end
