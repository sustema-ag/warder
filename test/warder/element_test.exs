defmodule Warder.ELementTest do
  use ExUnit.Case, async: true

  alias Warder.Element
  alias Warder.Range

  doctest Element

  describe "Float" do
    test "comparison correct" do
      assert 2.2 in Range.new!(1.1, 3.3)
      refute 4.4 in Range.new!(1.1, 3.3)
    end
  end

  describe "Decimal" do
    test "comparison correct" do
      assert Decimal.new("2.2") in Range.new!(Decimal.new("1.1"), Decimal.new("3.3"))
      refute Decimal.new("4.4") in Range.new!(Decimal.new("1.1"), Decimal.new("3.3"))
    end
  end

  describe "Integer" do
    test "canonicalization correct" do
      assert Range.new!(1, 3) == Range.new!(1, 2, upper_inclusive: true)
    end

    test "comparison correct" do
      assert 2 in Range.new!(1, 3)
      refute 4 in Range.new!(1, 3)
    end
  end

  describe "Date" do
    test "canonicalization correct" do
      assert Range.new!(~D[2024-03-01], ~D[2024-03-26]) ==
               Range.new!(~D[2024-03-01], ~D[2024-03-25], upper_inclusive: true)
    end

    test "comparison correct" do
      assert ~D[2024-03-15] in Range.new!(~D[2024-03-01], ~D[2024-03-26])
      refute ~D[2024-04-01] in Range.new!(~D[2024-03-01], ~D[2024-03-26])
    end
  end

  describe "DateTime" do
    test "comparison correct" do
      assert ~U[2024-03-15 00:00:00Z] in Range.new!(~U[2024-03-01 00:00:00Z], ~U[2024-03-26 00:00:00Z])
      refute ~U[2024-04-01 00:00:00Z] in Range.new!(~U[2024-03-01 00:00:00Z], ~U[2024-03-26 00:00:00Z])
    end
  end

  describe "NaiveDateTime" do
    test "comparison correct" do
      assert ~N[2024-03-15 00:00:00] in Range.new!(~N[2024-03-01 00:00:00], ~N[2024-03-26 00:00:00])
      refute ~N[2024-04-01 00:00:00] in Range.new!(~N[2024-03-01 00:00:00], ~N[2024-03-26 00:00:00])
    end
  end

  describe "Time" do
    test "comparison correct" do
      assert ~T[06:00:00] in Range.new!(~T[00:00:00], ~T[12:00:00])
      refute ~T[18:00:00] in Range.new!(~T[00:00:00], ~T[12:00:00])
    end
  end
end
