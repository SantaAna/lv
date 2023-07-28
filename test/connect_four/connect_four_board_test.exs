defmodule ConnectFourBoardTest do
  use ExUnit.Case
  alias Lv.ConnectFour.Board, as: B

  describe "new/1" do
    test "returns default size when no argument is given" do
      b = B.new()
      assert b.size == 6 and length(b.cols) == 6 and length(List.first(b.cols)) == 6
    end

    test "returns the given size when given a valid argument" do
      b = B.new(2)
      assert b.size == 2 and length(b.cols) == 2 and length(List.first(b.cols)) == 2
    end
  end

  describe "mark/3" do
    test "properly places a marker in an empty row" do
      b = B.new(2)
      {:ok, b} = B.mark(b, 0, :red)
      assert b.cols == [[:blank, :red], [:blank, :blank]]
    end

    test "properly places a marker in a non-empty row" do
      b = B.new(2)
      {:ok, b} = B.mark(b, 0, :red)
      {:ok, b} = B.mark(b, 0, :red)
      assert b.cols == [[:red, :red], [:blank, :blank]]
    end

    test "will not place a marker in a full row" do
      b = B.new(2)
      {:ok, b} = B.mark(b, 0, :red)
      {:ok, b} = B.mark(b, 0, :red)
      assert match?({:error, error_message}, B.mark(b, 0, :red))
    end
  end

  describe "get_cols/1" do
    test "returns correct cols" do
      b = B.new(2)
      assert B.get_cols(b) == [[:blank, :blank], [:blank, :blank]]
    end
  end

  describe "get_rows/1" do
    test "returns correct rows" do
      b = B.new(2)
      {:ok, b} = B.mark(b, 0, :red)
      assert B.get_rows(b) == [[:blank, :blank], [:red, :blank]]
    end
  end

  describe "get_diagonals/1" do
    test "returns correct diagonals" do
      b = B.new(2)
      {:ok,  b} = B.mark(b, 0, :red)
      diag_list = [[:blank], [:red, :blank], [:blank], [:blank], [:blank, :blank], [:red]]
      assert Enum.sort(diag_list) == Enum.sort(B.get_diagonals(b))
    end
  end
end
