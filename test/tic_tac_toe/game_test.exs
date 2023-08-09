defmodule TicTacToe.GameTest do
  use ExUnit.Case
  alias Lv.TicTacToe.{Game, Board}

  describe "new/0" do
    test "returns an empty board" do
      assert %Game{
               board: Board.new(),
               winner: nil,
               draw: false,
               winning_coords: []
             } ==
               Game.new([])
    end
  end

  describe "mark/3" do
    test "will mark a game with an empty board" do
      game = Game.new([]) |> Game.mark([1, 1], :x)
      assert {:ok, game.board} == Board.new() |> Board.mark([1, 1], :x)
    end
  end

  describe "free_spaces/1" do
    test "will return all spaces for a fresh game" do
      assert length(Game.free_spaces(Game.new([]))) == 9
    end

    test "will return smaller number for partially marked game" do
      game = Game.new([]) |> Game.mark([1, 1], :x)
      assert length(Game.free_spaces(game)) == 8
      assert {[1, 1], :blank} not in Game.free_spaces(game)
    end

    test "will return empty list for a full board" do
      full_game =
        for x <- 1..3, y <- 1..3, reduce: Game.new([]) do
          acc ->
            Game.mark(acc, [x, y], :x)
        end

      assert length(Game.free_spaces(full_game)) == 0
      assert Game.free_spaces(full_game) == []
    end
  end

  describe "winner/1" do
    test "will find a row winner" do
      assert Enum.map(1..3, fn row ->
               for col <- 1..3, reduce: Game.new([]) do
                 acc -> Game.mark(acc, [row, col], :x)
               end
             end)
             |> Enum.map(&Game.winner/1)
             |> Enum.all?(& &1.winner)

      assert Enum.map(1..3, fn row ->
               for col <- 1..3, reduce: Game.new([]) do
                 acc -> Game.mark(acc, [row, col], :o)
               end
             end)
             |> Enum.map(&Game.winner/1)
             |> Enum.all?(& &1.winner)
    end

    test "will find a col winner" do
      assert Enum.map(1..3, fn col ->
               for row <- 1..3, reduce: Game.new([]) do
                 acc -> Game.mark(acc, [row, col], :x)
               end
             end)
             |> Enum.map(&Game.winner/1)
             |> Enum.all?(& &1.winner)

      assert Enum.map(1..3, fn col ->
               for row <- 1..3, reduce: Game.new([]) do
                 acc -> Game.mark(acc, [row, col], :o)
               end
             end)
             |> Enum.map(&Game.winner/1)
             |> Enum.all?(& &1.winner)
    end

    test "will find a diagonal winner" do
      diag1 = [[1, 1], [2, 2], [3, 3]]
      diag2 = [[1, 3], [2, 2], [3, 1]]

      assert Enum.map([diag1, diag2], fn diag ->
               for s <- diag, reduce: Game.new([]) do
                 acc -> Game.mark(acc, s, :o)
               end
             end)
             |> Enum.map(&Game.winner/1)
             |> Enum.all?(& &1.winner)

      assert Enum.map([diag1, diag2], fn diag ->
               for s <- diag, reduce: Game.new([]) do
                 acc -> Game.mark(acc, s, :x)
               end
             end)
             |> Enum.map(&Game.winner/1)
             |> Enum.all?(& &1.winner)
    end
  end
end
