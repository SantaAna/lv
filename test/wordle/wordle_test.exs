defmodule Wordle.WordleTest do
  use ExUnit.Case
  alias Lv.Wordle.Game

  describe "play_round/2" do
    test "will find a winner" do
      game =
        Game.new()
        |> Map.put(:winning_word, "dirky")
        |> Game.play_round("dirky")

      assert game.win
    end

    test "will not find winner if guess is wrong" do
      game =
        Game.new()
        |> Map.put(:winning_word, "dirky")
        |> Game.play_round("flora")

      refute game.win
    end

    test "will recognize a loss" do
      game =
        Game.new()
        |> Map.put(:winning_word, "dirky")

      game = Enum.reduce(List.duplicate("flora", 5), game, &Game.play_round(&2, &1))

      assert game.lose
    end
  end
end
